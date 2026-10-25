extends CharacterBody3D

## Birim ana kontrolcüsü.
## UnitData Resource'undan istatistik ve model bilgilerini okur.
## Hareket, savaş, eylemler ve ağ senkronizasyonunu yönetir.

const MechanicsResolver = preload("res://scripts/rules/mechanics_resolver.gd")
const DicePoolBuilder = preload("res://scripts/rules/dice_pool_builder.gd")
const InjuryResolver = preload("res://scripts/rules/injury_resolver.gd")
const AbilityExecutor = preload("res://scripts/rules/ability_executor.gd")
const CombatResolver = preload("res://scripts/rules/combat_resolver.gd")
const AbilityData = preload("res://scripts/data/ability_data.gd")

# Alt modüller (Composition)
var model_loader: UnitModelLoader
var visuals_manager: UnitVisuals
var movement_manager: UnitMovement
var actions_manager: UnitActions
var combat_manager: UnitCombat

@export var unit_data: Resource
## FAZ 5 (P1-1): bu birim deploy edilirken seçilen Battlekit/loadout index'i (-1 = seçenek yok/
## seçilmedi). GameState.deployed_count_of_loadout_group warband-limit sayımı için kullanır.
var chosen_loadout_index: int = -1
@export var id: String = ""
@export var owner_id: int = 1
@export var display_name: String = "Minyatür"
@export var movement_range: float = 12.0
@export var max_health: int = 10
@export var current_health: int = 10

# Wargame İstatistikleri ve Durumlar
var speed: float = 6.0
var armour: int = 3
var melee_dice_modifier: int = 0
var ranged_dice_modifier: int = 0
## AMMUNITION SACRAMENT (Mendelist Ammo Monk, P1-1) — "Echo of His Word": bir sonraki Ranged
## saldırının Injury Roll'una +1 Dice. reset_turn_actions'ta sıfırlanır (ranged_dice_modifier ile
## AYNI ömür — "geçerli olduğu aktivasyon" yaklaşımı, bkz. o alandaki yorum).
var temp_ranged_injury_bonus: int = 0
## AMMUNITION SACRAMENT — "Cartridge of His Wrath": bir sonraki Ranged saldırı (Blast/Flamethrower
## TAŞIMIYORSA) Blast 2"+Shrapnel kazanır. reset_turn_actions'ta sıfırlanır.
var temp_cartridge_of_wrath: bool = false

## GOETIC SPELLS (Court of the Seven-Headed Serpent, P1-1): "A model cannot cast the same spell
## more than once per Activation." — ability_id StringName listesi, reset_turn_actions'ta
## sıfırlanır (projenin "aktivasyon-kapsamlı state raund başında temizlenir" kuralına uygun,
## bkz. has_moved/actions_taken ile AYNI ömür).
var goetic_spells_cast_this_activation: Array[StringName] = []

var blood_markers: int = 0
var blessing_markers: int = 0
var infection_markers: int = 0
var is_down: bool = false
var stood_up_this_activation: bool = false
## Aktivasyon-başı etkileri bu round çalıştı mı (bkz. ActivationRules — tekrar seçim yeniden tetiklemez).
var activation_started: bool = false
var has_moved: bool = false
var is_selected: bool = false
var is_targeted: bool = false
## attack/charge seçiliyken menzil+LoS uygun düşman hedef mi (sade vurgu için).
var is_valid_target: bool = false
## P2-5: bu birim, seçili menzilli saldıran için geçerli hedef VE siperdeyse true → halka amber.
## (Görsel bayrak — is_target_in_cover() metoduyla karışmasın diye ayrı ad.)
var is_cover_highlighted: bool = false

# Faksiyon Özel Durum Bayrakları
var has_memento_mori_used: bool = false
var has_tough_used: bool = false
## BROKEN ON THE WHEEL (Anchorite Shrine, P1-1): "Broken on the Wheel" loadout'u seçilirse init_
## unit'te true'ya set edilir (armour_override=0 zaten LoadoutOption ile uygulanır; has_tough/
## negate_shrapnel bu birime özgü unit_data kopyasından geçici olarak çıkarılır — bkz. init_unit).
## İlk Out of Action'da injury_resolver.gd tarafından false'a çevrilip normal duruma dönülür.
var broken_on_wheel_active: bool = false
## Birimin kurulduğu .tres yolu. `unit_data` loadout/zırhane yüzünden bir KOPYA olabilir
## (resource_path boş) — kayıt dosyası temel veriyi bu yoldan yeniden kurar.
var unit_data_path: String = ""

# Eylem Takip Sistemi
var actions_taken: Array = []
var is_dash_pending: bool = false
var is_charge_pending: bool = false
var charge_bonus: float = 0.0
## Compendium: bu aktivasyonda Assault OLMAYAN bir Shoot yapıldıysa Charge/Fight kilitlenir
## (Assault olmayan Shoot ile Charge/Fight birlikte olamaz — bkz. CombatResolver).
var has_non_assault_shot: bool = false
## HEAVY (compendium keyword.md): kısıt SİMETRİKTİR — bir HEAVY Ranged/Grenade saldırısı bu
## aktivasyonda yapıldıysa, Move/Charge/Retreat/Dash de bu aktivasyonda ARTIK yapılamaz (P0-5;
## önceden yalnız ters yön — Move sonrası Heavy Shoot — engelleniyordu).
var has_heavy_shot: bool = false
## Diving Charge başarılıysa (3"+ yükseklikten hücum + Risky Success): SONRAKİ Melee Success
## Roll'una +1 DICE. Melee saldırısı bunu tüketir; reset_turn_actions'ta sıfırlanır (compendium).
var diving_charge_bonus_pending: bool = false

# ── YETENEK DURUM BAYRAKLARI (aktif yetenekler tarafından kurulur) ──────────────
## HIDE (Death Commando): model saklandı — hareket/saldırı/geri çekilme yapana ya da düşman 1.5"
## içine girene kadar menzilli saldırı ve hücumla HEDEFLENEMEZ. Turlar arası kalıcıdır.
var is_hidden: bool = false
## FORTIFY (Sapper/Engineer): model hareket edene kadar Cover (−1 DICE savunma) kazanır.
var has_fortify_cover: bool = false
## SHADOW WALKER (Court Hunter): bu aktivasyonda yapılacak Retreat sırasında düşmanlar serbest
## yakın dövüş saldırısı YAPAMAZ. Retreat'te tüketilir; aktivasyon başında sıfırlanır.
var shadow_walker_active: bool = false
## SLASHING ATTACK (Assassin's Dagger, Battlekit özel kuralı): bu aktivasyonda saldırı hedefe en
## az 1 Kan İşareti koyduysa, bu birim angaje olsa bile Dash'i Retreat gibi kullanabilir VE o
## Retreat'te (Dash veya normal Retreat ile) düşmanlar serbest yakın dövüş YAPAMAZ. Aktivasyon
## başında sıfırlanır (bkz. resolve_injury_roll, unit_actions.gd::can_perform_action, server_request_retreat).
var slashing_attack_active: bool = false
## DANGEROUS TERRAIN Risky Success'i bu aktivasyonda atıldı mı? (Aktivasyon başına BİR kez —
## RAW'ın iki tetikleyicisi tek zarı paylaşır; bkz. `TerrainRules.check_activation_start`.)
var activation_terrain_checked: bool = false
## BOUNTY TARGET (Marked for Death senaryosu, MarkedForDeathLogic): bu birim şu an kendi warband'ının
## en değerli (Cost'u en yüksek) sahadaki modeli — düşman onu vurursa +VP alır. Senaryo mantığı
## tarafından (unit'in KENDİ aksiyonu değil, dışarıdan) kurulur/güncellenir, bkz. set_bounty_target.
var is_bounty_target: bool = false
## ELEMENTAL CHANGE / MASTERY OF THE ELEMENTS (Jabirean Alchemist): silaha atanan dinamik element
## (&"fire"/&"gas"/&"shrapnel"; &"" = yok). Paylaşılan AttackData mutasyona uğratılmaz — per-unit state.
var current_element: StringName = &""

## DEVOUR THE GUILTY (Sin Eater, P1-1): bu birim yutulduysa, onu yutan Sin Eater node'u (yoksa
## null). Yutulmuşken görünmez/hedeflenemez, yalnız "fight_devourer" aksiyonu yapabilir, Morale
## Check sayımında Down sayılır (bkz. init_unit/reset_turn_actions'taki has_devoured-adjacent
## kullanım YOK — bu iki alan doğrudan resolve_injury_roll/ability_executor'da yönetilir).
var devoured_by = null
## DEVOUR THE GUILTY: bu birim bir Sin Eater'sa VE birini yuttuysa, yutulan model node'u (yoksa null).
var devoured_unit = null

## FIRETEAM / FAITHFUL FOLLOWERS — ortak aktivasyon (kural mantığı ActivationRules'ta). Bağlar
## düğüm referansı değil AD olarak tutulur: kayıt/yükleme ve ağ senkronu adla yeniden bağlanır.
## `fireteam_partner` kalıcı Fireteam eşi (oyuncu ilk ortak aktivasyonda seçer); `joint_partner`
## bu round'daki ortak aktivasyonun eşi (Fireteam veya Faithful Followers).
var fireteam_partner_name: String = ""
var fireteam_sworn: bool = false  ## Sworn Brethren (Mamluk + [Elite]) — NA'nın 2 Fireteam sınırına sayılmaz
var joint_partner_name: String = ""
var activation_start_pos = null  ## aktivasyon başındaki konum (Faithful Followers 1" şartı)
var fireteam_partner:
	get: return GameState.units.get(fireteam_partner_name) if fireteam_partner_name != "" else null
	set(v): fireteam_partner_name = String(v.name) if is_instance_valid(v) else ""
var joint_partner:
	get: return GameState.units.get(joint_partner_name) if joint_partner_name != "" else null
	set(v): joint_partner_name = String(v.name) if is_instance_valid(v) else ""
## Bu birimin bu round'da (Fireteam'in ortak aktivasyon penceresi) isabet ettirdiği hedefler —
## CONCENTRATED ATTACK kontrolü için ("partner earlier in the same joint Activation hit this
## target"). reset_turn_actions'ta sıfırlanır (round başı, goetic_spells ile AYNI ömür — her
## birim raund başına bir kez aktive olduğundan "joint Activation" ile "round" örtüşüyor).
var fireteam_hit_targets_this_activation: Array = []

## INFLICT PAIN (Combat Biologist'in Vivisector'ı, P1-1) zincirleme durum bayrağı: dıştaki
## _apply_inflict_pain çağrısı aktif olduğu sürece true — bkz. _apply_inflict_pain yorumu.
var _inflict_pain_resolving: bool = false
## Zincirleme bir Inflict Pain (ek Melee Attack sırasında tetiklenen ikinci bir kritik) bu
## itmeye eklediği D3" mesafe toplamı.
var _inflict_pain_extra_dist: int = 0

var target_position: Vector3
var is_moving: bool = false
var move_speed: float = 8.0

@onready var selection_ring = $SelectionRing
@onready var mesh_instance = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var range_indicator = $RangeIndicator
@onready var attack_range_indicator = $AttackRangeIndicator

# Yol izleme hareket sistemi
var current_path: Array = []
var path_index: int = 0

# Saldırı sistemi
var selected_attack_index: int = 0

var model_node = null

const BASE_MODEL_SCENE := preload("res://assets/models/base.glb")
static var _base_mesh_cache: Mesh = null

func _ready():
	if not Engine.is_editor_hint():
		if has_node("EditorPlaceholder"):
			get_node("EditorPlaceholder").queue_free()

	model_loader = UnitModelLoader.new(self)
	visuals_manager = UnitVisuals.new(self)
	movement_manager = UnitMovement.new(self)
	actions_manager = UnitActions.new(self)
	combat_manager = UnitCombat.new(self)

	add_to_group("units")
	GameState.register_unit(self)
	target_position = global_position
	
	if unit_data:
		apply_unit_data()
	
	if range_indicator and range_indicator.has_method("hide_visuals"):
		range_indicator.hide_visuals()
		
	if attack_range_indicator and attack_range_indicator.has_method("hide_visuals"):
		attack_range_indicator.hide_visuals()
		
	set_selected(false)
	_setup_base_mesh()
	_apply_owner_color()
	_load_model()
	
	# Default spawn rotation: Player 1 faces right (+X), Player 2 faces left (-X)
	if owner_id == 1:
		rotation.y = -PI / 2
	else:
		rotation.y = PI / 2

func _setup_base_mesh():
	if _base_mesh_cache == null:
		var temp_instance = BASE_MODEL_SCENE.instantiate()
		var m_node = _find_base_mesh_instance(temp_instance)
		if m_node and m_node.mesh:
			_base_mesh_cache = m_node.mesh
		temp_instance.free()

	if _base_mesh_cache and is_instance_valid(mesh_instance):
		mesh_instance.mesh = _base_mesh_cache
		var default_scale = 0.9 / 1.958358
		mesh_instance.scale = Vector3(default_scale, default_scale, default_scale)
		mesh_instance.position = Vector3(0, 0.362545 * default_scale, 0)

func _find_base_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found = _find_base_mesh_instance(child)
		if found:
			return found
	return null

func _exit_tree():
	GameState.unregister_unit(self)

func is_unit() -> bool:
	return true

## UnitData Resource'undan istatistikleri birimin özelliklerine uygular.
func apply_unit_data():
	if unit_data == null:
		return
	unit_data = LoadoutResolver.with_unarmed(unit_data)
	display_name = LocalizationManager.tr_t(unit_data.unit_name.to_upper().replace(" ", "_").replace("-", "_"))
	# G5: Gercek Trench Crusade'de HP YOKTUR. current_health artik yalnizca ikili "alive"
	# bayragidir (1 = sahada, 0 = Savas Disi). Scratch/Down HP dusurmez -- modeli oyundan
	# yalnizca Injury tablosunun Out of Action sonucu cikarir. max_health kavrami kaldirildi.
	max_health = 1
	current_health = 1

	# BLESSED (X): model ilk konuşlandığında X Blessing Marker ile başlar (compendium keyword.md).
	blessing_markers = KeywordSystem.value(unit_data, &"blessed", 0)

	# Wargame İstatistikleri — artık doğrudan okunuyor, guard kontrolü yok
	speed = unit_data.speed
	armour = unit_data.armour
	melee_dice_modifier = unit_data.melee_dice_modifier
	ranged_dice_modifier = unit_data.ranged_dice_modifier
	
	movement_range = speed
	
	# Menzil göstergelerini yeniden ölçeklendir
	if range_indicator and range_indicator.has_method("update_visuals"):
		range_indicator.update_visuals()
	if attack_range_indicator and attack_range_indicator.has_method("update_visuals"):
		attack_range_indicator.update_visuals()

## Sunucu ve istemci tarafında birimi başlatır. loadout_index: FAZ 5 (P1-1) — seçilen Battlekit
## varyantı (-1 = yok/seçilmedi, mevcut sabit unit_data.attacks[] davranışı DEĞİŞMEZ).
@rpc("authority", "call_local", "reliable")
func init_unit(p_owner_id: int, p_unit_data_path: String, loadout_index: int = -1,
		restoring: bool = false):
	owner_id = p_owner_id
	unit_data_path = p_unit_data_path
	var loaded_data = load(p_unit_data_path)
	if loaded_data:
		unit_data = LoadoutResolver.resolve_loadout(loaded_data, loadout_index)
		chosen_loadout_index = loadout_index
		apply_unit_data()
		UnitDeployHooks.apply_loadout_side_effects(self)
		# Kayıttan yüklenirken "ilk konuşlanma" kancaları ÇALIŞMAZ: element seçimi ve Dug In
		# durumu kayıttan gelir; yeniden çalışsalar oyuncuya tekrar sorar / siperi yeniden kurardı.
		if not restoring:
			UnitDeployHooks.run_first_deploy(self)
	_apply_owner_color()
	_load_model()
	GameLogger.log_info("Birim başlatıldı: %s (Sahibi: Oyuncu %d, Veri: %s)" % [display_name, owner_id, p_unit_data_path], "GAME")


## Seçili saldırıyı döndürür. Güvenli erişim.
func _get_selected_attack():
	if unit_data == null or unit_data.attacks.is_empty():
		return null
	var idx = clampi(selected_attack_index, 0, unit_data.attacks.size() - 1)
	return unit_data.attacks[idx]

func _load_model():
	model_loader.load_model()

func _apply_owner_color():
	visuals_manager.apply_owner_color()

func set_selected(selected: bool):
	is_selected = selected
	if is_selected and owner_id == TurnManager.current_turn_player_id and not has_moved and not activation_started:
		activation_started = true
		activation_start_pos = global_position
		# Auto stand up if down
		if is_down:
			# PIN (Lions of Jabir): 1" içinde düşman bir Pin taşıyıcısı varsa ayağa kalkamaz.
			# (Basitleştirme: compendium "40mm veya altı baz" şartını taşımıyoruz — proje baz
			# boyutu modellemiyor; tüm Down birimlere aynı şekilde uygulanır.)
			var pinned_by = UnitQuery.nearest(
				UnitQuery.with_keyword(UnitQuery.engaged_enemies(self), &"pin"), global_position)
			if pinned_by != null:
				GameLogger.log_info("%s Pin altında (%s), ayağa kalkamıyor." % [display_name, pinned_by.display_name], "TURN")
			else:
				is_down = false
				stood_up_this_activation = true
				GameLogger.log_info("%s otomatik olarak ayağa kalktı. Bu tur hareket hızı yarıya indi." % display_name, "TURN")
			
		# REGENERATE(X) — saf hesap MechanicsResolver.compute_regeneration'da (test edilebilir).
		var removed_markers := MechanicsResolver.compute_regeneration(unit_data, blood_markers)
		if removed_markers > 0:
			blood_markers -= removed_markers
			GameLogger.log_info("%s aktivasyon başında %d Kan İşareti temizledi." % [display_name, removed_markers], "COMBAT")
			# BLESSED STIGMATA (Stigmatic Nun): her temizlenen Kan İşareti için +1 Blessing Marker
			if KeywordSystem.has(unit_data, &"blessed_stigmata"):
				blessing_markers = min(blessing_markers + removed_markers, 6)
				GameLogger.log_info("%s Blessed Stigmata: +%d Nimet İşareti kazandı." % [display_name, removed_markers], "COMBAT")


		# P0-8: INFECTION MARKER keyword'ünün çekirdek büyüme kuralı (comprehensive-rules/keyword.md):
		# "If a model activates with one or more Infection Markers, it gains +1 Infection Marker to
		# the maximum of 6." Disease Carrier'dan BAĞIMSIZ, yalnız bu aktivasyondan ÖNCE zaten sahip
		# olduğu miktara bakar (bu aktivasyonda Disease Carrier'dan yeni kazanılanı SAYMAZ).
		var had_infection_before_activation: bool = infection_markers > 0
		if had_infection_before_activation:
			infection_markers = min(infection_markers + 1, 6)
			GameLogger.log_info("%s zaten taşıdığı Enfeksiyon İşareti aktivasyonda büyüdü: %d." % [display_name, infection_markers], "COMBAT")

		# DISEASE CARRIER keyword — artık unit_data flag'i ile kontrol ediliyor
		var near_disease_carrier: bool = UnitQuery.any(UnitQuery.where(
			UnitQuery.engaged_enemies(self),
			func(u): return u.unit_data != null and u.unit_data.is_disease_carrier))
		if near_disease_carrier:
			infection_markers = min(infection_markers + 1, 6)
			GameLogger.log_info("%s veba taşıyıcısının yakınında aktive olduğu için 1 Veba İşareti aldı!" % display_name, "COMBAT")

		# DEVOUR THE GUILTY (Sin Eater, P1-1): "Each time the Sin Eater is Activated, place 1
		# Blood Marker next to the devoured model. As soon as a devoured model has 6 Blood
		# Markers, it is immediately taken Out of Action (ignoring any rules that would prevent
		# this) and is no longer considered to be inside the Sin Eater."
		if is_instance_valid(devoured_unit) and devoured_unit.current_health > 0:
			devoured_unit.blood_markers = min(devoured_unit.blood_markers + 1, 6)
			GameLogger.log_info("[Devour the Guilty] %s aktive oldu — yuttuğu %s +1 Kan İşareti aldı (%d/6)." \
				% [display_name, devoured_unit.display_name, devoured_unit.blood_markers], "COMBAT")
			if devoured_unit.blood_markers >= 6:
				GameLogger.log_warn("[Devour the Guilty] %s 6 Kan İşaretine ulaştı — anında Savaş Dışı!" \
					% devoured_unit.display_name, "COMBAT")
				var swallowed = devoured_unit
				devoured_unit = null
				swallowed.devoured_by = null
				RpcHelper.sync(swallowed, "sync_devoured_state", [""])
				RpcHelper.sync(swallowed, "sync_health_states",
					[0, swallowed.is_down, swallowed.blood_markers, swallowed.blessing_markers,
					swallowed.infection_markers, false])
			else:
				CombatResolver.sync_target_health(devoured_unit)

		# FACTION RULES — army-wide pasif kuralların aktivasyon-başı tetikleyicisi
		FactionRules.on_activation_start(self)

		# ── SHAKEN ──────────────────────────────────────────────────────────
		# Compendium: Shaken orduda -1 DICE cezası YOKTUR; bunun yerine tüm Success
		# Roll'lar RISKY sayılır (ıska/başarısızlık → aktivasyon biter). Bu, saldırı ve
		# yetenek çözümleme noktalarında TurnManager.is_shaken() ile uygulanır.

		RpcHelper.sync(self, "sync_health_states", [current_health, is_down, blood_markers, blessing_markers, infection_markers])

		# HATEFUL (Yoke Fiend): aktivasyonda uygun bir düşman varsa zorunlu Charge (compendium).
		_maybe_hateful_charge()
	update_selection_ring()
	update_indicators()

## BLOCK (Polearm, P1-1): target'ın attacks[]'inde BLOCK keyword'lü bir silah var mı? (Ekipman
## PRESENCE kontrolü — hangi silahla savunduğu değil, taşıdığı hangi silahta olduğu önemli değil.)
static func _target_wields_block_weapon(target) -> bool:
	if target == null or target.unit_data == null:
		return false
	for atk_res in target.unit_data.attacks:
		if atk_res != null and KeywordSystem.has(atk_res, &"block"):
			return true
	return false

## HATEFUL zorunlu charge tetikleyicisi (yalnız aktivasyon başında, koşullar sağlanırsa).
func _maybe_hateful_charge() -> void:
	if unit_data == null or not KeywordSystem.has(unit_data, &"hateful"):
		return
	if not can_perform_action("charge"):
		return
	var enemies: Array = []
	var enemy_nodes: Array = UnitQuery.enemies_of(self)
	for u in enemy_nodes:
		var exempt: bool = u.unit_data != null and \
			(KeywordSystem.has(u.unit_data, &"demonic") or KeywordSystem.has(u.unit_data, &"black_grail"))
		var los: bool = not get_line_of_sight_status(u).is_blocked
		enemies.append({"pos": u.global_position, "exempt": exempt, "los": los})
	var idx: int = MechanicsResolver.hateful_target_index(global_position, enemies)
	if idx >= 0:
		GameLogger.log_info("%s [Hateful] öfkeyle en yakın düşmana zorunlu hücum: %s" \
			% [display_name, enemy_nodes[idx].display_name], "GAME")
		request_charge_action(enemy_nodes[idx])




func update_indicators():
	movement_manager.update_indicators()
	visuals_manager.refresh_team_ring()

func reset_turn_actions():
	has_moved = false
	stood_up_this_activation = false
	activation_started = false
	actions_taken.clear()
	is_dash_pending = false
	is_charge_pending = false
	charge_bonus = 0.0
	has_non_assault_shot = false
	has_heavy_shot = false
	diving_charge_bonus_pending = false
	shadow_walker_active = false  # aktivasyon-kapsamlı (is_hidden/has_fortify_cover harekette temizlenir)
	slashing_attack_active = false
	activation_terrain_checked = false

	# Revert temporary buffs
	if unit_data:
		melee_dice_modifier = unit_data.melee_dice_modifier if "melee_dice_modifier" in unit_data else 0
		ranged_dice_modifier = unit_data.ranged_dice_modifier if "ranged_dice_modifier" in unit_data else 0
	temp_ranged_injury_bonus = 0
	temp_cartridge_of_wrath = false
	goetic_spells_cast_this_activation.clear()
	fireteam_hit_targets_this_activation.clear()
	joint_partner_name = ""
	activation_start_pos = null

	if is_selected:
		set_selected(true)

func _physics_process(delta):
	movement_manager.physics_process(delta)


# ==================== EYLEM KONTROL SİSTEMİ ====================

## FAZ 3: can_perform_action() artık UnitData.abilities[] dizisini dinamik okur.
## Temel hareketler (move, charge, retreat, dash, aim, melee, shoot) sabit.
## Faksiyon yetenekleri (loudspeakers, treat, vb.) artık UnitData.abilities[] içindeki
## AbilityData resource'larının action_key'lerinden oluşturulan bir set ile kontrol edilir.
func can_perform_action(action_name: String) -> bool:
	return actions_manager.can_perform_action(action_name)

func is_engaged() -> bool:
	return UnitQuery.any(UnitQuery.engaged_enemies(self))

## Bu birim yerel aktif oyuncu tarafından ŞU AN aktive edilip eylem yaptırılabilir mi?
## (P0-C: "seçili ama eylem yapamaz" durumunu görsel olarak ayırmak için — seçim halkası buna
## göre parlak/aktif ya da sönük/inceleme gösterilir.)
func is_activatable() -> bool:
	# Down birim de AKTİVE EDİLEBİLİR: seçilince otomatik ayağa kalkar (set_selected — yarım hız).
	# Bu yüzden is_down burada diskalifiye ETMEZ; aksi halde tur başında Down birim sönük halkayla
	# "yenilenmemiş/hazır değil" görünüyordu (get_ready_unit_count zaten hazır sayıyor — tutarlılık).
	if has_moved or current_health <= 0:
		return false
	if owner_id != TurnManager.current_turn_player_id:
		return false
	if multiplayer.has_multiplayer_peer() and owner_id != NetworkManager.get_local_canonical_id():
		return false
	return true

## HIDE (Death Commando): bu birim, verilen saldırgan tarafından menzilli saldırı/hücumla
## hedeflenemez mi? Saklıysa ve saldırgan 1.5" içinde DEĞİLSE korunur (1.5" içindeki düşman
## saklanmayı bozar — compendium HIDE_DESC).
func is_untargetable_by(attacker) -> bool:
	if not is_hidden:
		return false
	if not is_instance_valid(attacker):
		return true
	return attacker.global_position.distance_to(global_position) > 1.5

## Birim kendi bir eylemini yaptığında saklanma (Hide) ve —hareketse— Fortify (Cover) durumunu bozar.
func break_stealth_on_own_action(is_move: bool) -> void:
	var changed := false
	if is_hidden:
		is_hidden = false
		changed = true
		GameLogger.log_info("%s saklanması bozuldu (kendi eylemi)." % display_name, "COMBAT")
	if is_move and has_fortify_cover:
		has_fortify_cover = false
		changed = true
		GameLogger.log_info("%s hareket etti — Fortify (Cover) sona erdi." % display_name, "COMBAT")
	if changed:
		RpcHelper.sync(self, "sync_ability_flags",
			[is_hidden, has_fortify_cover, shadow_walker_active, slashing_attack_active])

@rpc("authority", "call_local", "reliable")
func sync_ability_flags(p_hidden: bool, p_fortify: bool, p_shadow: bool, p_slashing: bool = false):
	is_hidden = p_hidden
	has_fortify_cover = p_fortify
	shadow_walker_active = p_shadow
	slashing_attack_active = p_slashing
	update_indicators()

## ELEMENTAL CHANGE: seçili silah elementini tüm istemcilerde günceller.
@rpc("authority", "call_local", "reliable")
func sync_current_element(p_element: StringName):
	current_element = p_element

## DEVOUR THE GUILTY (Sin Eater, P1-1): yutulan model "Place the model to one side... it is
## inside the Sin Eater and cannot be affected in any way" — görünmez + hedeflenemez (collision
## kapatılır) yapılır. devourer_name boşsa (serbest bırakma/Purge) tekrar görünür/hedeflenebilir olur.
@rpc("authority", "call_local", "reliable")
func sync_devoured_state(devourer_name: String):
	devoured_by = GameState.units.get(devourer_name) if devourer_name != "" else null
	visible = devoured_by == null
	if is_instance_valid(collision_shape):
		collision_shape.disabled = devoured_by != null

## Bu saldırı (silah) şu an kullanılabilir mi?
## can_perform_action (angaje/tekrar/tur) + CombatResolver Assault etkileşim kuralı (hücum
## sonrası Fight her zaman serbest; Shoot yalnız Assault ile). Panel + sunucu ortak kaynağı.
func can_use_attack(atk) -> bool:
	if atk == null:
		return false
	var is_melee: bool = atk.attack_type == "MELEE"
	var action_key := "melee" if is_melee else "shoot"
	if not can_perform_action(action_key):
		return false
	var is_assault: bool = atk.is_assault if "is_assault" in atk else false
	return CombatResolver.attack_interaction_allowed(
		is_melee, is_assault,
		actions_taken.has("charge"), actions_taken.has("melee"), has_non_assault_shot)

# ==================== DETAYLI TACTICAL EYLEMLER ====================

## Ayağa Kalk (Morale/Rally)
# Rally action removed - auto recovery implemented at start of activation

## NOT: "Aim/Nişan Al" eylemi kaldırıldı — Trench Crusade'de böyle bir ortak eylem yoktur
## (compendium ortak eylemler: Move/Charge/Retreat, Dash, Shoot, Fight). Birebir kural sadakati.

## Koş (Dash)
func request_dash_action():
	if not can_perform_action("dash"):
		return
	if multiplayer.has_multiplayer_peer():
		rpc_id(1, "server_request_dash")
	else:
		server_request_dash()

@rpc("any_peer", "reliable")
func server_request_dash():
	if not RpcHelper.validate_rpc_request(self, owner_id):
		return
	# SUNUCU-OTORİTER YENİDEN DOĞRULAMA: istemcinin ÖN kontrolü (request_dash_action'daki
	# can_perform_action) yalnız İSTEMCİNİN o anki (belki bayat) actions_taken'ına güvenir. Hızlı
	# çift-tıklama/ağ gecikmesi aynı aksiyon için İKİ RPC gönderebilir ("yetenek/aksiyon kullanıyorum
	# sonra tekrar kullanabiliyorum" bildirimi) — sunucu burada KENDİ güncel durumuna göre tekrar kontrol eder.
	if not can_perform_action("dash"):
		return
	if await TerrainRules.check_activation_start(self):
		return   # DANGEROUS TERRAIN: aktivasyon başı Risky başarısız → akış biter

	# Dash Zarı (Başarı: 7+) — bazı birimlerin (Mad Dash, Agile) Dash'e özgü DICE bonusu olabilir
	var dash_bonus: int = KeywordSystem.value(unit_data, &"dash_dice_bonus", 0) if unit_data else 0
	# FRENZIED FOLLOWERS (Matagot Hag): 8" içindeki dost Dash Risky Roll'una +1 Dice.
	if unit_data != null and DicePoolBuilder._friendly_aura_nearby(self, &"frenzied_followers", DicePoolBuilder.aura_range()):
		dash_bonus += 1
	var roll_res = await perform_unit_success_roll(dash_bonus)
	var total = roll_res[0]
	
	if total >= 7:
		is_dash_pending = true
		actions_taken.append("dash")
		RpcHelper.sync(self, "sync_dash_state", [true, actions_taken])
		GameLogger.log_info("%s Dash zarı başarılı (%d). Hareket edebilir." % [display_name, total], "MOVEMENT")
	else:
		GameLogger.log_warn("%s Dash zarı başarısız (%d). Aktivasyon anında bitiyor." % [display_name, total], "MOVEMENT")
		TurnManager.end_unit_activation(self)

@rpc("authority", "call_local", "reliable")
func sync_dash_state(p_pending: bool, p_actions: Array):
	is_dash_pending = p_pending
	actions_taken = p_actions
	update_indicators()
	if not multiplayer.has_multiplayer_peer() or is_multiplayer_authority():
		check_activation_complete()


## Standart Hareket (Move)
func request_move_action(target_pos: Vector3):
	var is_dash = is_dash_pending
	if not is_dash and not can_perform_action("move"):
		return
	if multiplayer.has_multiplayer_peer():
		rpc_id(1, "server_request_move_action", target_pos, is_dash)
	else:
		server_request_move_action(target_pos, is_dash)

@rpc("any_peer", "reliable")
func server_request_move_action(target_pos: Vector3, is_dash: bool):
	if not RpcHelper.validate_rpc_request(self, owner_id):
		return
	# SUNUCU-OTORİTER YENİDEN DOĞRULAMA (bkz. server_request_dash'teki AYNI not). is_dash=true ise
	# hareket zaten başarılı bir Dash zarının SONUCUdur (request_move_action'daki istemci kontrolüyle
	# AYNI istisna); değilse normal "move" aksiyonu sunucuda tekrar doğrulanır.
	if not is_dash and not can_perform_action("move"):
		return
	if await TerrainRules.check_activation_start(self):
		return   # DANGEROUS TERRAIN: aktivasyon başı Risky başarısız → akış biter

	var map_rid = get_world_3d().navigation_map
	var max_dist = speed
	# DEMONIC AURA — SLOTH (Court, Desecrated Saint): "Düşman modeller 3\" içinde Movement yarıya iner."
	if MechanicsResolver.is_in_demonic_aura(self, &"sloth_aura"):
		max_dist *= 0.5
		GameLogger.log_info("[Demonic Aura — Sloth] %s Tembellik Aurasının etkisinde: hareket yarıya indi." % display_name, "MOVEMENT")
	# FRIGHTENING SPEED (ignore_standup_penalty): ayağa kalkınca hareket YARIYA İNMEZ.
	if stood_up_this_activation and not (unit_data and KeywordSystem.has(unit_data, &"ignore_standup_penalty")):
		max_dist *= 0.5
	# SLOW (Scripture Guardian): "Treat this model as having a Movement of 3\"/Infantry when
	# taking a Dash Action" — yalnız DASH kaynaklı harekette geçerli, normal Move etkilenmez.
	if is_dash and unit_data != null and KeywordSystem.has(unit_data, &"slow_dash"):
		max_dist = min(max_dist, 3.0)
	# DIFFICULT TERRAIN (keyword.md): "Every 1" a model is moved across terrain with this
	# Keyword counts as 2"" → etkin menzil yarıya iner. [Negate Difficult Terrain] muaftır.
	max_dist = TerrainRules.effective_move_distance(unit_data, target_pos, max_dist)

	# ── HEDEFİ NAVMESH'E HİZALA / DOĞRULA ──
	# Ham raycast tıklaması yüzey altı boşluğa (harita eteği/çukur) denk gelirse en yakın
	# navigasyon noktası ondan uzak olur → reddet. Aksi halde geçersiz Y "aşağı atlama"
	# sanılıp ölümcül Falling Injury tetiklenir ("birim haritadan düştü" bug'ı).
	var nav: Dictionary = MovementHelper.resolve_nav_target(
		NavigationServer3D.map_get_closest_point(map_rid, target_pos), target_pos, GameState.NAV_MOVE_TOLERANCE)
	if not nav.valid:
		GameLogger.log_warn("%s oraya hareket edemez: geçerli zemin dışı." % display_name, "MOVEMENT")
		GameEvents.move_rejected.emit("MOVE_FAIL_OFF_GROUND")
		return
	target_pos = nav.target

	# ── DİKEY HAREKET DEĞERLENDİRMESİ (Climbing / Jumping Down — compendium) ──
	# FLYING: dikey hareket havadan ölçülür (tırmanma Risky'si yok, düşme yok).
	# LEVITATE (Artillery Witch): FLYING ile AYNI tırmanma/düşme muafiyeti, ama hareket TİPİ
	# Flying'e dönüşmez (yalnız Risky roll + Falling Injury atlanır).
	var is_flying: bool = unit_data != null \
		and (KeywordSystem.has(unit_data, &"flying") or KeywordSystem.has(unit_data, &"levitate"))
	var vres: Dictionary = ClimbingResolver.evaluate(self, target_pos, max_dist, is_flying)
	var vtype: String = vres.get("type", "flat")

	if vtype == "invalid":
		GameLogger.log_warn("%s: %s" % [display_name, vres.get("reason", "dikey hareket geçersiz")], "MOVEMENT")
		GameEvents.move_rejected.emit(vres.get("reason_key", "MOVE_FAIL_GENERIC"))
		return

	if vtype == "flat":
		# Düz hareket (NavMesh clamp — en kısa yol + ulaşılamıyorsa en yakın nokta)
		var verified_target = MovementHelper.keep_base_clearance(self, map_rid,
			MovementHelper.get_clamped_target(map_rid, global_position, target_pos, max_dist))
		if not UnitQuery.within_exclusive(UnitQuery.enemies_of(self), verified_target,
				GameState.ENGAGE_RANGE).is_empty():
			GameLogger.log_warn("%s standart hareketle düşmanın 1 inç yakınına giremez (Charge gerekir)!" % display_name, "MOVEMENT")
			return
		_consume_move_action(is_dash)
		RpcHelper.sync(self, "client_update_move", [verified_target])
		return

	# ── DİKEY: climb / walkover_up / climb_down / walkover_down ──
	var path: PackedVector3Array = vres.get("path", PackedVector3Array())
	var final_pt: Vector3 = MovementHelper.keep_base_clearance(self, map_rid, target_pos)
	# Varış noktası düşmanın 1 inç yakınına giremez (yakın dövüş için Charge gerekir)
	if not UnitQuery.within_exclusive(UnitQuery.enemies_of(self), final_pt,
			GameState.ENGAGE_RANGE).is_empty():
		GameLogger.log_warn("%s dikey hareketle düşmanın 1 inç yakınına giremez." % display_name, "MOVEMENT")
		return

	# CLIMB / CLIMB_DOWN (sheer surface >3", yukarı VEYA aşağı): kontrollü tırmanma —
	# Risky Success gerekir; başarısız → hareket yok, aktivasyon biter (düşme YARASI YOK).
	if vres.get("needs_risky", false):
		var going_down: bool = (vtype == "climb_down")
		# AGILE: Climb/Jump Risky Success'e +1 DICE.
		var agile_b: int = KeywordSystem.value(unit_data, &"agile", 0) if unit_data else 0
		var roll = await perform_unit_success_roll(agile_b)
		if roll[0] < 7:
			GameLogger.log_warn("%s %s (Risky) BAŞARISIZ (%d) — aktivasyon sona eriyor." \
				% [display_name, "inme" if going_down else "tırmanma", roll[0]], "MOVEMENT")
			_consume_move_action(is_dash)
			TurnManager.end_unit_activation(self)
			return
		GameLogger.log_info("%s duvardan %s (Risky %d)." \
			% [display_name, "indi" if going_down else "tırmandı", roll[0]], "MOVEMENT")

	_consume_move_action(is_dash)

	RpcHelper.sync(self, "client_move_along_path", [path])

## Move/Dash aksiyonunu tüketip senkronize eder (düz ve dikey hareket ortak yardımcısı).
func _consume_move_action(is_dash: bool):
	break_stealth_on_own_action(true)  # hareket → Hide + Fortify(Cover) sona erer
	if is_dash:
		is_dash_pending = false
		RpcHelper.sync(self, "sync_dash_state", [false, actions_taken])
	else:
		actions_taken.append("move")
		RpcHelper.sync(self, "sync_actions_taken", [actions_taken])

## Verilen (dikey segmentler içeren) L-yolu boyunca birimi hareket ettirir.
@rpc("authority", "call_local", "reliable")
func client_move_along_path(path: PackedVector3Array):
	if path.size() < 2:
		return
	var arr: Array = []
	for pt in path:
		arr.append(pt)
	current_path = arr
	path_index = 1
	is_moving = true
	if range_indicator and range_indicator.has_method("hide_visuals"):
		range_indicator.hide_visuals()

## Falling Injury Roll — düşen birime uygulanır (attacker/silah yok; zırh -injury modifier uygulanır).
func resolve_falling_injury(fall_height: float):
	# FLYING / LEVITATE (compendium): kanatlı/uçan/havada süzülen model düşerse Injury Roll yapılmaz.
	if unit_data != null and (KeywordSystem.has(unit_data, &"flying") or KeywordSystem.has(unit_data, &"levitate")):
		GameLogger.log_info("%s FLYING/LEVITATE — düşüşten yara almaz (Injury Roll atlanır)." % display_name, "COMBAT")
		return
	var extra_dice: int = int(fall_height / 3.0)  # her 3" için +1 Injury Dice
	GameLogger.log_warn("%s %.1f\" düştü! Falling Injury Roll (+%d Injury Dice)." % [display_name, fall_height, extra_dice], "COMBAT")
	var flat: int = -clampi(armour, 0, 3)
	var roll_res = await perform_trench_roll(extra_dice, flat, "injury", 2)
	var total: int = roll_res[0]
	var raw: InjuryResolver.Outcome = InjuryResolver.resolve_table(total)
	var blood_before: int = blood_markers
	var final_outcome: InjuryResolver.Outcome = InjuryResolver.apply_outcome(raw, self, null, false)
	BattleEvents.injury(self, final_outcome, blood_markers - blood_before)
	InjuryResolver.maybe_end_activation(final_outcome, self)
	CombatResolver.sync_target_health(self, true)

## DIVING CHARGE riskli sıçrama zarı (compendium melee-attacks.md).
## Birim 3"+ yükseklikten atlayıp hedefin 1" içine indi → Risky Success Roll (7+):
##   Başarı → Falling Injury YOK + sonraki Melee Success Roll'una +1 DICE (diving_charge_bonus_pending).
##   Başarısız → model Down + Falling Injury Roll.
## server_request_charge (başarılı diving hücum) içinden çağrılır.
func resolve_diving_charge(fall_height: float):
	GameLogger.log_info("%s Diving Charge! %.1f\" yükseklikten iniş — Risky Success Roll." % [display_name, fall_height], "COMBAT")
	# AGILE: Diving Charge Risky Success'e +1 DICE.
	var agile_b: int = KeywordSystem.value(unit_data, &"agile", 0) if unit_data else 0
	var roll = await perform_unit_success_roll(agile_b)
	if roll[0] >= 7:
		diving_charge_bonus_pending = true
		RpcHelper.sync(self, "sync_diving_charge_pending", [true])
		GameLogger.log_info("%s Diving Charge BAŞARILI (%d) — sonraki Melee'ye +1 DICE, düşme yarası yok." % [display_name, roll[0]], "COMBAT")
	else:
		GameLogger.log_warn("%s Diving Charge BAŞARISIZ (%d) — Down + Falling Injury." % [display_name, roll[0]], "COMBAT")
		await resolve_falling_injury(fall_height)
		# Kural: başarısız diving charge modeli DOWN yapar (falling injury OOA yapmadıysa garanti).
		if current_health > 0 and not is_down:
			is_down = true
			CombatResolver.sync_target_health(self, true)
	# Hareket + zar çözüldü: nihai durumla aktivasyon-bitişini denetle (Down ise biter, değilse Fight açık).
	check_activation_complete()

@rpc("authority", "call_local", "reliable")
func sync_diving_charge_pending(p_pending: bool):
	diving_charge_bonus_pending = p_pending
	update_indicators()

## Hücum (Charge)
func request_charge_action(target_enemy):
	if not can_perform_action("charge"):
		return
	if not is_instance_valid(target_enemy) or target_enemy.owner_id == owner_id:
		return
		
	var dist = global_position.distance_to(target_enemy.global_position)
	if dist > GameState.CHARGE_DISTANCE_CAP:
		GameLogger.log_warn("Hücum menzili en fazla 12 metredir!", "MOVEMENT")
		return

	# Compendium: hücum hedefi görüş hattında olmalı (istemci ön-kontrolü; sunucu da doğrular)
	var los_pre = get_line_of_sight_status(target_enemy)
	if los_pre.is_blocked:
		GameLogger.log_warn("Hücum edilemez: hedef görüş hattında değil.", "MOVEMENT")
		return

	# HIDE: saklanan hedefe hücum edilemez (saldıran 1.5" içinde değilse).
	if target_enemy.has_method("is_untargetable_by") and target_enemy.is_untargetable_by(self):
		GameLogger.log_warn("Hücum edilemez: hedef saklanıyor (Hide).", "MOVEMENT")
		return

	if multiplayer.has_multiplayer_peer():
		rpc_id(1, "server_request_charge", target_enemy.name)
	else:
		server_request_charge(target_enemy.name)

@rpc("any_peer", "reliable")
func server_request_charge(enemy_name: String):
	if not RpcHelper.validate_rpc_request(self, owner_id):
		return
	
	if not GameState.units.has(enemy_name):
		return
	var enemy = GameState.units[enemy_name]
	if not is_instance_valid(enemy) or enemy.current_health <= 0:
		return

	# Compendium: hücum hedefi görüş hattında olmalı (sunucu doğrulaması)
	var los = get_line_of_sight_status(enemy)
	if los.is_blocked:
		GameLogger.log_warn("[Charge] %s: hedef görüş hattında değil, hücum iptal." % display_name, "MOVEMENT")
		return

	# HIDE: saklanan hedefe hücum edilemez (sunucu doğrulaması)
	if enemy.has_method("is_untargetable_by") and enemy.is_untargetable_by(self):
		GameLogger.log_warn("[Charge] %s: hedef saklanıyor (Hide), hücum iptal." % display_name, "MOVEMENT")
		return

	# Compendium: araya giren düşman varsa orijinal hedefe hücum geçersizdir (o hedef seçilmeli)
	var interposer = MechanicsResolver.charge_interposing_enemy(self, enemy)
	if interposer != null:
		GameLogger.log_warn("[Charge] %s: %s araya giriyor; önce ona hücum edilmeli. Hücum iptal." \
			% [display_name, interposer.display_name], "MOVEMENT")
		return

	# SKIRMISHER (Azeb): hedef hücumdan önce kaçmayı seçebilir; kaçış araya bir model sokarsa
	# hücum ona yönelir (SkirmisherEvade).
	enemy = await SkirmisherEvade.resolve(self, enemy)

	# Hücum bir harekettir → saklanma (Hide) ve Fortify(Cover) sona erer.
	break_stealth_on_own_action(true)

	# Hücum zarını at (D6 bonus mesafe). HEAVY: "does not receive a Charge Bonus" — bonus YOK.
	var bonus_dist = 0
	if not MechanicsResolver.has_unnegated_heavy_loadout(unit_data):
		# SHOCK CHARGE (Highland Shocktrooper): "roll 1 extra D6 and use the single highest die."
		var use_shock_charge: bool = unit_data != null and KeywordSystem.has(unit_data, &"shock_charge")
		# roll_id FİLTRESİ (DiceRoller.perform_trench_roll ile AYNI desen): filtresiz bir await,
		# bu sırada başlayan BAŞKA bir atışın (ör. eşzamanlı bir yeteneğin d6'sı) sonucunu yanlışlıkla
		# kabul edebilir — "zar düşüyor, animasyon yarıda kesiliyor" bug sınıfının kök nedenlerinden.
		var is_roll_owner: bool = not multiplayer.has_multiplayer_peer() or multiplayer.is_server()
		if is_roll_owner:
			DiceManager.roll_dice(2 if use_shock_charge else 1)
		var expected_roll_id: int = DiceManager.current_roll_id if is_roll_owner else -1
		var d6_res = await DiceManager.dice_roll_completed
		while is_roll_owner and d6_res[2] != expected_roll_id:
			d6_res = await DiceManager.dice_roll_completed
		if use_shock_charge:
			var individual: Array = d6_res[1]
			bonus_dist = int(max(individual[0], individual[1]))
			# UI: bu çıplak D6 atışı önceden zar-sonuç barı göstermiyordu — 2 zar atılır,
			# yalnız en yükseği tutulur (Shock Charge), bu ikisi de barda görünsün.
			# roll_type="d6" KULLANMA — o etiket dice_bar.gd'de yalnız combat_resolver'ın
			# "dost ateşi" kontrolüne özel (≤3 → yanlış "Dost Ateşi" metni basardı).
			DiceManager.show_dice_bar_ui.emit(individual, 1, true, 0, bonus_dist, "bonus_roll")
		else:
			bonus_dist = d6_res[0]
			DiceManager.show_dice_bar_ui.emit(d6_res[1], 1, true, 0, bonus_dist, "bonus_roll")

		# BULKY (Machine Armour, battlekit/armour.md): "has a Charge Bonus of D3" instead of D6"."
		# Görsel zar atışı AYNEN kalır (proje D3 model içermiyor); dönüşüm MechanicsResolver'da.
		bonus_dist = MechanicsResolver.apply_charge_bonus_d3(unit_data, bonus_dist)

	# Compendium: Charge toplam hareketi en fazla 12" (Movement + D6, cap 12).
	var max_charge_speed = speed
	# DEMONIC AURA — SLOTH (Court, Desecrated Saint): "Düşman modeller 3\" içinde Movement yarıya iner."
	if MechanicsResolver.is_in_demonic_aura(self, &"sloth_aura"):
		max_charge_speed *= 0.5
		GameLogger.log_info("[Demonic Aura — Sloth] %s Tembellik Aurasının etkisinde: hareket yarıya indi." % display_name, "MOVEMENT")
	# injuries.md: "its Movement Characteristic is halved for the rest of the Activation (including
	# the bonus for charging)" — Charge bonusu da yarıya iner; Frightening Speed muaftır.
	if stood_up_this_activation and not (unit_data and KeywordSystem.has(unit_data, &"ignore_standup_penalty")):
		max_charge_speed *= 0.5
		bonus_dist *= 0.5
	var max_charge_dist = min(max_charge_speed + bonus_dist, GameState.CHARGE_DISTANCE_CAP)
		
	if await TerrainRules.check_activation_start(self):
		return   # DANGEROUS TERRAIN: aktivasyon başı Risky başarısız → akış biter
	var dist = global_position.distance_to(enemy.global_position)
	var map_rid = get_world_3d().navigation_map
	
	var verified_target = global_position
	# DIVING CHARGE tespiti: hücum, hedefin 3"+ ÜSTÜNDEN atlayıp inen BAŞARILI bir hücumsa
	# riskli sıçrama zarı gerekir. Yükseklik CHARGE ANINDA (birim henüz taşınmadan) ölçülür.
	var diving_fall: float = 0.0
	if dist <= max_charge_dist + GameState.CHARGE_REACH_TOLERANCE:
		# CLIMBING (movement.md): hücum rotası >3" bir yüzeyi TIRMANIYORSA Move'daki gibi Risky Success
		# gerekir; başarısız → hareket yok, aktivasyon biter. (Aşağı atlama Diving Charge'da.)
		if enemy.global_position.y - global_position.y > GameState.CLIMB_FREE_MAX and not (unit_data != null \
				and (KeywordSystem.has(unit_data, &"flying") or KeywordSystem.has(unit_data, &"levitate"))):
			var climb_roll = await perform_unit_success_roll(KeywordSystem.value(unit_data, &"agile", 0) if unit_data else 0)
			if climb_roll[0] < 7:
				GameLogger.log_warn("%s hücumda tırmanma (Risky) BAŞARISIZ (%d) — aktivasyon sona eriyor." % [display_name, climb_roll[0]], "MOVEMENT")
				actions_taken.append("charge")
				RpcHelper.sync(self, "sync_actions_taken", [actions_taken])
				TurnManager.end_unit_activation(self)
				return
		# Hücum başarılı! Düşmanla taban temasına gir (bazlar iç içe girmez)
		var path = NavigationServer3D.map_get_path(map_rid, global_position, enemy.global_position, true)
		var from: Vector3 = path[path.size()-2] if path.size() >= 2 else global_position
		verified_target = MovementHelper.keep_base_clearance(self, map_rid,
			enemy.global_position - (enemy.global_position - from).normalized() * MovementHelper.BASE_CONTACT)
		actions_taken.append("charge")
			# Compendium: charge tamamlanınca OTOMATİK Fight yapılmaz — Fight ayrı aksiyondur.
		if MechanicsResolver.is_diving_charge_height(global_position.y, enemy.global_position.y):
			diving_fall = global_position.y - enemy.global_position.y
		GameLogger.log_info("%s Hücumu Başarılı! D6 zarı: +%d. Toplam menzil: %.1f" % [display_name, bonus_dist, max_charge_dist], "MOVEMENT")

		# GLORIOUS DEEDS (P1-5, Suicidal Bravery): varış konumunda kaç düşmanla angaje olundu?
		if ScenarioManager.logic != null:
			var engaged_count: int = UnitQuery.within(
				UnitQuery.enemies_of(self), verified_target, GameState.ENGAGE_RANGE).size()
			ScenarioManager.logic.on_successful_charge(self, engaged_count)
	else:
		# Hücum başarısız! Maksimum düz koşar
		verified_target = MovementHelper.keep_base_clearance(self, map_rid,
			MovementHelper.get_clamped_target(map_rid, global_position, enemy.global_position, max_charge_dist))
		actions_taken.append("charge")
		GameLogger.log_warn("%s Hücumu Başarısız! D6 zarı: +%d. Gidilen: %.1f, Gerekli: %.1f" % [display_name, bonus_dist, max_charge_dist, dist], "MOVEMENT")

	# Hareketi ÖNCE başlat (is_moving=true), aksiyon senkronunu SONRA yap: böylece
	# sync_actions_taken içindeki check_activation_complete, birim hareket halindeyken
	# ertelenir ve aktivasyon Charge varışından önce yanlışlıkla bitmez (Dash→Charge→Fight).
	RpcHelper.sync(self, "client_update_move", [verified_target])
	RpcHelper.sync(self, "sync_actions_taken", [actions_taken])

	# DIVING CHARGE riskli sıçrama zarı (compendium): birim yükseklikten atlayıp indi.
	if diving_fall >= GameState.DIVING_CHARGE_MIN_HEIGHT:
		await resolve_diving_charge(diving_fall)

## Geri Çekilme (Retreat)
func request_retreat_action(target_pos: Vector3):
	if not can_perform_action("retreat"):
		return
	if multiplayer.has_multiplayer_peer():
		rpc_id(1, "server_request_retreat", target_pos)
	else:
		server_request_retreat(target_pos)

@rpc("any_peer", "reliable")
func server_request_retreat(target_pos: Vector3):
	if not RpcHelper.validate_rpc_request(self, owner_id):
		return
	# SUNUCU-OTORİTER YENİDEN DOĞRULAMA (bkz. server_request_dash'teki AYNI not).
	if not can_perform_action("retreat"):
		return
	if await TerrainRules.check_activation_start(self):
		return   # DANGEROUS TERRAIN: aktivasyon başı Risky başarısız → akış biter

	# Angaje düşmanları bul
	var engaged_enemies: Array = UnitQuery.engaged_enemies(self)

	actions_taken.append("retreat")
	RpcHelper.sync(self, "sync_actions_taken", [actions_taken])

	# Retreat bir harekettir → saklanma (Hide) ve Fortify(Cover) sona erer.
	break_stealth_on_own_action(true)

	# UNSTOPPABLE (Amalgam, P1-1): "Enemy models... are not allowed to make a Melee Attack when
	# an Amalgam that is within 1" of them retreats." Shadow Walker ile AYNI etki, ama harcanan
	# bir büyü DEĞİL — Amalgam'ın kalıcı bir yeteneği (basitleştirme: taban-boyutu [32mm] filtresi
	# taşınmıyor, koşulsuz uygulanır — bkz. can_perform_action'daki AYNI istisna).
	var is_unstoppable_retreat: bool = unit_data != null and KeywordSystem.has(unit_data, &"unstoppable")
	# SHADOW WALKER (Court Hunter): bu Retreat sırasında düşmanlar serbest yakın dövüş YAPAMAZ.
	# SLASHING ATTACK (Assassin's Dagger): AYNI etki, ama harcanan bir büyü değil — bu Aktivasyonda
	# saldırı hedefe Kan İşareti koyduğu için kazanılan tek-seferlik bir Battlekit bonusu.
	if shadow_walker_active or is_unstoppable_retreat or slashing_attack_active:
		if shadow_walker_active:
			GameLogger.log_info("[Shadow Walker] %s gölgeye çekildi — serbest yakın dövüş yok." % display_name, "COMBAT")
			shadow_walker_active = false
			RpcHelper.sync(self, "sync_ability_flags",
				[is_hidden, has_fortify_cover, shadow_walker_active, slashing_attack_active])
		elif slashing_attack_active:
			GameLogger.log_info("[Slashing Attack] %s Kan İşareti koyduğu için geri çekildi — serbest yakın dövüş yok." % display_name, "COMBAT")
			slashing_attack_active = false
			RpcHelper.sync(self, "sync_ability_flags",
				[is_hidden, has_fortify_cover, shadow_walker_active, slashing_attack_active])
		else:
			GameLogger.log_info("[Unstoppable] %s geri çekildi — düşmanlar serbest yakın dövüş yapamaz." % display_name, "COMBAT")
	else:
		# Compendium: rakip, model HAREKET ETMEDEN ONCE 1 serbest Melee saldirisi yapar.
		# Model Down/OOA olursa geri cekilme hareketi GERCEKLESMEZ.
		GameLogger.log_info("[Action] %s geri cekilmeye calisiyor! Dusmanlar serbest yakin dovus hakki kazaniyor." % display_name, "COMBAT")
		for enemy in engaged_enemies:
			if is_instance_valid(enemy) and enemy.current_health > 0:
				var time_slipped: bool = await enemy.execute_free_melee_strike(self)
				if time_slipped:
					# P1-1 Time Slip: yeniden konuşlanma sonrası retreat hareketi biter (compendium).
					GameLogger.log_info("[Retreat] %s Time Slip ile kaçtı — geri çekilme hareketi tamamlandı." % display_name, "COMBAT")
					return
				if current_health <= 0 or is_down:
					GameLogger.log_info("[Retreat] %s serbest saldiriyla durduruldu (Down/OOA) - hareket iptal." % display_name, "COMBAT")
					return

	# Hareketi gerceklestir
	var map_rid = get_world_3d().navigation_map
	var max_dist = speed
	# DEMONIC AURA — SLOTH (Court, Desecrated Saint): "Düşman modeller 3\" içinde Movement yarıya iner."
	if MechanicsResolver.is_in_demonic_aura(self, &"sloth_aura"):
		max_dist *= 0.5
		GameLogger.log_info("[Demonic Aura — Sloth] %s Tembellik Aurasının etkisinde: hareket yarıya indi." % display_name, "MOVEMENT")
	# FRIGHTENING SPEED (ignore_standup_penalty): ayağa kalkınca hareket YARIYA İNMEZ.
	if stood_up_this_activation and not (unit_data and KeywordSystem.has(unit_data, &"ignore_standup_penalty")):
		max_dist *= 0.5
	# DIFFICULT TERRAIN — Retreat de bir harekettir, aynı ceza geçerlidir.
	max_dist = TerrainRules.effective_move_distance(unit_data, target_pos, max_dist)

	var verified_target = MovementHelper.keep_base_clearance(self, map_rid,
		MovementHelper.get_clamped_target(map_rid, global_position, target_pos, max_dist))

	# Compendium (movement.md, Retreating): "A retreating model must end its retreat move MORE
	# THAN 1" AWAY FROM ALL ENEMY MODELS. **If this is impossible, it cannot move at all.**"
	verified_target = MovementHelper.enforce_retreat_clearance(self, map_rid, verified_target, max_dist)

	# KURAL DÜZELTMESİ (2026-07-29 denetimi): `enforce_retreat_clearance` EN İYİ ÇABA'dır (en çok
	# 4 itme denemesi). Başaramazsa eski kod modeli YİNE DE taşıyordu — hâlâ angaje bir noktaya.
	# Bu hem RAW'a aykırıydı hem oyun mantığını bozuyordu ("geri çekildi" ama hâlâ angaje).
	# Artık: temiz bir nokta bulunamadıysa model YERİNDE KALIR (aksiyon yine harcanmış sayılır —
	# RAW da Action'ı iade etmez).
	if not UnitQuery.within(UnitQuery.enemies_of(self), verified_target,
			GameState.ENGAGE_RANGE).is_empty():
		GameLogger.log_warn("[Retreat] %s tüm düşmanlardan 1\" uzağa çekilemiyor — hareket etmiyor (compendium)." \
			% display_name, "MOVEMENT")
		GameEvents.move_rejected.emit("MOVE_FAIL_RETREAT_BLOCKED")
		return

	RpcHelper.sync(self, "client_update_move", [verified_target])

	# DEMONIC AURA — GREED (Court, Desecrated Saint): "Düşman modeller 3\" içinde Retreat yaptığında +1 Kan İşareti."
	if MechanicsResolver.is_in_demonic_aura(self, &"greed_aura"):
		blood_markers = min(blood_markers + 1, 6)
		GameLogger.log_info("[Demonic Aura — Greed] %s Açgözlük Aurasının etkisinde: Retreat yaparak +1 Kan İşareti aldı (%d)." % [display_name, blood_markers], "COMBAT")
		RpcHelper.sync(self, "sync_health_states", [current_health, is_down, blood_markers, blessing_markers, infection_markers, false])

const ATK_DEVOURED_BARE_HANDS := preload("res://assets/data/attacks/devoured_bare_hands.tres")

## DEVOUR THE GUILTY (Sin Eater, P1-1): yutulmuş bir model Aktive edildiğinde "it can take a
## Fight Action and must target the Sin Eater. Add -3 Dice to the roll for the Melee Attack, and
## do not use any of the model's abilities or any of the special rules for its weapons." — silahsız
## saf bir saldırı (ATK_DEVOURED_BARE_HANDS, hiçbir keyword taşımaz) kullanılır.
func request_fight_devourer_action() -> void:
	if not can_perform_action("fight_devourer"):
		return
	if multiplayer.has_multiplayer_peer():
		rpc_id(1, "server_request_fight_devourer_action")
	else:
		server_request_fight_devourer_action()

@rpc("any_peer", "reliable")
func server_request_fight_devourer_action() -> void:
	if not RpcHelper.validate_rpc_request(self, owner_id):
		return
	if not can_perform_action("fight_devourer"):
		return
	var sin_eater = devoured_by
	actions_taken.append("fight_devourer")
	RpcHelper.sync(self, "sync_actions_taken", [actions_taken])
	var dist: float = global_position.distance_to(sin_eater.global_position)
	var ctx: Dictionary = DicePoolBuilder.build_attack_context(self, ATK_DEVOURED_BARE_HANDS, sin_eater, dist)
	var modifier: int = DicePoolBuilder.compute_success_modifier(ctx) - 3
	var roll_res: Array = await perform_unit_success_roll(modifier)
	var total: int = roll_res[0]
	if total >= 7:
		var is_crit: bool = total >= 12
		await sin_eater.resolve_injury_roll(self, is_crit, true, 0, 0, ATK_DEVOURED_BARE_HANDS)
	else:
		GameLogger.log_info("[Devour the Guilty] %s Sin Eater'a saldırdı ama ıskaladı (%d)." % [display_name, total], "COMBAT")
		# Sarsılmış ordu / Maddening Buzzing altında bu da Risky bir Success Roll'dur.
		if RiskyRolls.apply_failure(self, total, false, "Sin Eater'a saldırı"):
			return
	check_activation_complete()

## CLAIM RELIQUARY (Relic Hunt senaryosu): "A model that is within 1" of a Reliquary, can take a
## Claim Reliquary Action. If it does so, take a Success Roll for the model. If the roll is a
## Failure, nothing happens. If the roll is a Success or Critical Success, the Reliquary is
## claimed by the model." Modifikatörsüz düz Success Roll (compendium ek bonus/ceza belirtmiyor).
func request_claim_reliquary_action() -> void:
	if not can_perform_action("claim_reliquary"):
		return
	if multiplayer.has_multiplayer_peer():
		rpc_id(1, "server_request_claim_reliquary_action")
	else:
		server_request_claim_reliquary_action()

@rpc("any_peer", "reliable")
func server_request_claim_reliquary_action() -> void:
	if not RpcHelper.validate_rpc_request(self, owner_id):
		return
	if not can_perform_action("claim_reliquary"):
		return
	var reliquary_id: StringName = ScenarioManager.logic.find_claimable_reliquary(global_position)
	if reliquary_id == &"":
		return
	actions_taken.append("claim_reliquary")
	RpcHelper.sync(self, "sync_actions_taken", [actions_taken])
	var roll_res: Array = await perform_unit_success_roll(0)
	var total: int = roll_res[0]
	if total >= 7:
		ScenarioManager.logic.claim_reliquary(reliquary_id, owner_id, display_name)
		GameLogger.log_info("[Relic Hunt] %s Reliquary'yi başarıyla claim etti (%d)." % [display_name, total], "SCENARIO")
	else:
		GameLogger.log_info("[Relic Hunt] %s Reliquary'yi claim edemedi (%d)." % [display_name, total], "SCENARIO")
		if RiskyRolls.apply_failure(self, total, false, "Kutsal Emanet Alma"):
			return
	check_activation_complete()

## Serbest Saldırı (Disengagement Strike). Dönüş: hedef Time Slip ile yeniden konuşlandıysa true
## (P1-1) — çağıran taraf (server_request_retreat) bunu "retreat move biter" sinyali olarak kullanır.
## Retreat eden düşmana verilen SERBEST melee vuruşu. Gövde `UnitAttackChains`te (çoklu-saldırı
## ailesi): Cleave(X) burada da geçerlidir ve orada zaten aynı aileden mekanikler duruyor.
## Dönüş: Time Slip ile yeniden konuşlanma oldu mu (retreat akışı buna göre erken biter).
func execute_free_melee_strike(target) -> bool:
	return await UnitAttackChains.execute_free_strike(self, target)

## TIME SLIP (Sultanate Assassin, P1-1). Bu birim hedef alan bir saldırının Success Roll'u
## IRAKLADIĞINDA çağrılır (AttackFlow/UnitAttackChains.execute_offhand/
## execute_free_melee_strike'ın miss dallarından). Sahibine önce Evet/Hayır sorulur; kabul
## edilirse HARİTADA TIKLAYARAK yeni konum seçmesi istenir (menzil halkası + bilgi kartı,
## bkz. GameState.start_position_pick / interaction_hint_card.gd). Ham tıklama sunucuda ASLA
## doğrudan güvenilmez: MovementHelper.enforce_retreat_clearance ile hem GameState.TIME_SLIP_RADIUS
## (6") sınırına hem düşman-mesafesi kuralına (ENGAGE_RANGE, >1") clamp'lenir — tıpkı Skirmisher
## evade'in aynı yardımcıyı kullanması gibi (compendium "redeploy anywhere within 6\", more than
## 1\" away from enemies", ölçüm burada navmesh YOL mesafesiyle yapılır — kuş uçuşu değil, projenin
## mevcut hareket/evade yaklaşımıyla tutarlı bilinçli basitleştirme).
## Dönüş: yeniden konuşlanma gerçekleştiyse true (retreat bağlamında "hareket bitti" sinyali).
func _maybe_time_slip(is_retreat_context: bool = false) -> bool:
	if unit_data == null or not KeywordSystem.has(unit_data, &"time_slip"):
		return false
	var accepted: bool = await CombatChoice.request_time_slip(self)
	if not accepted:
		return false

	var origin: Vector3 = global_position
	var raw_click = await CombatChoice.request_position_pick(self, GameState.TIME_SLIP_RADIUS, "TIME_SLIP_PICK")
	if raw_click == null:
		GameLogger.log_info("[Time Slip] %s seçimi iptal etti — tetiklenmedi." % display_name, "COMBAT")
		return false

	var map_rid: RID = get_world_3d().navigation_map
	var snapped: Vector3 = NavigationServer3D.map_get_closest_point(map_rid, raw_click)
	var new_pos: Vector3 = MovementHelper.enforce_retreat_clearance(self, map_rid, snapped, GameState.TIME_SLIP_RADIUS)

	global_position = new_pos
	RpcHelper.sync(self, "client_update_move", [new_pos])
	GameLogger.log_info("[Time Slip] %s geleceğe kaydı — yeni konum: %s%s" \
		% [display_name, str(new_pos), " (Retreat sona erdi)" if is_retreat_context else ""], "COMBAT")
	return true

## PILGRIM BODYGUARD (Communicant, P1-1): bu birim (self, [Pilgrim] hedef) bir saldırıya
## HEDEF ALINDI ve isabet etti (Success Roll geçti) — Injury Roll'dan HEMEN ÖNCE çağrılır.
## 1" içinde `pilgrim_bodyguard` taşıyan dost bir Communicant varsa, sahibine "hasarı üstlensin
## mi?" sorulur; kabul edilirse Injury Roll'un asıl hedefi Communicant olur. Compendium: Blast
## saldırılarına uygulanmaz — bu fonksiyon yalnız TEK-hedef saldırı akışlarından çağrılır
## (execute_blast kendi resolve_injury_roll'unu doğrudan çağırır, bu fonksiyonu hiç görmez).
## (hedef_tag, muhafız_keyword'ü) çiftleri — Pilgrim Bodyguard (Communicant) ve Black Grail
## Bodyguard (Corpse Guard) AYNI mekanizmanın iki faction'a uyarlanmış hali (compendium metinleri
## neredeyse birebir aynı: "1" içindeki dost [tag] modele isabet eden saldırıyı üstlenebilir").
const _BODYGUARD_PAIRS := [
	[&"pilgrim", &"pilgrim_bodyguard"],
	[&"black_grail", &"black_grail_bodyguard"],
]

func _maybe_redirect_to_bodyguard():
	if unit_data == null:
		return self
	for pair in _BODYGUARD_PAIRS:
		var target_tag: StringName = pair[0]
		var guardian_kw: StringName = pair[1]
		if not KeywordSystem.has(unit_data, target_tag):
			continue
		var guardian = UnitQuery.nearest(
			UnitQuery.with_keyword(
				UnitQuery.allies_within(self, 1.0), guardian_kw),
			global_position)
		if guardian == null:
			continue
		var accepted: bool = await CombatChoice.request_pilgrim_bodyguard(self, guardian.display_name)
		if accepted:
			GameLogger.log_info("[Bodyguard] %s'e gelen darbeyi %s üstlendi." % [display_name, guardian.display_name], "COMBAT")
			return guardian
	return self

# ==================== SAVAŞ SİSTEMİ VE HASAR ====================

func request_attack_action(enemy, attack_idx: int):
	var is_melee = false
	var atk = null
	if unit_data and attack_idx < unit_data.attacks.size():
		atk = unit_data.attacks[attack_idx]
		is_melee = atk.attack_type == "MELEE"
		
	# can_use_attack: can_perform_action + Assault etkileşim kuralı (hücumdan sonra Fight serbest).
	if not can_use_attack(atk):
		return
	if not is_instance_valid(enemy) or enemy.owner_id == owner_id:
		return

	if not is_melee:
		var los_status = get_line_of_sight_status(enemy)
		if los_status.is_blocked:
			GameLogger.log_warn("Görüş hattı kapalı! Hedef katı engellerin arkasında.", "COMBAT")
			return
		# HIDE: saklanan hedefe menzilli saldırı yapılamaz (saldıran 1.5" içinde değilse).
		if enemy.has_method("is_untargetable_by") and enemy.is_untargetable_by(self):
			GameLogger.log_warn("Hedef saklanıyor (Hide) — menzilli saldırı yapılamaz.", "COMBAT")
			return

	if multiplayer.has_multiplayer_peer():
		rpc_id(1, "server_request_attack_action", enemy.name, attack_idx)
	else:
		server_request_attack_action(enemy.name, attack_idx)

@rpc("any_peer", "reliable")
func server_request_attack_action(enemy_name: String, attack_idx: int):
	if not RpcHelper.validate_rpc_request(self, owner_id):
		return
	# Çözümlemenin TAMAMI `AttackFlow`da: doğrulama → hazırlık → modifikatör → aksiyon kaydı →
	# çoklu-saldırı zinciri → zar → isabet/ıska → bitiş. Bu fonksiyon 231 satırdı ve her yeni
	# silah kuralı onu büyütüyordu; artık kural ilgili FAZA eklenir (bkz. attack_flow.gd).
	await AttackFlow.execute(self, enemy_name, attack_idx)

# ── ÇOKLU SALDIRI ZİNCİRLERİ ────────────────────────────────────────────────
# Swinging Blow / Cleave(X) / Automatic(X) / Off-Hand orkestrasyonu `UnitAttackChains`te;
# hangi zincirin çalışacağı `UnitAttackChains.select_chain()`te; çağrı `AttackFlow`da.
# Buradaki altı ince sarmalayıcı (`_execute_swinging_blow` vb.) artık ÇAĞRILMIYOR — silindi.


## Yara Zarı (Injury Roll) — çözümlemenin TAMAMI `InjuryPipeline`de.
##
## Bu fonksiyon 306 satırdı; gövdesinin çoğu ardışık, birbirinden bağımsız özel kural bloğuydu
## (Slashing Attack, Inflict Pain, Whip of God, Prize Specimens, Dark Blessing, Beelzebub's
## Touch, Parasite Host, Law of Hell, Glorious Deeds…). Artık her biri kendi dosyasında
## (`scripts/rules/injury/triggers/`) ve izole test edilebiliyor. Burada YALNIZ imza kalır —
## çağıranlar (`unit.gd`, `mechanics_resolver.gd`, `unit_attack_chains.gd`) değişmedi.
##
## forced_keep_count: 0 = normal (2, ya da Bloodbath eşiği aşıldıysa 3/4). >0 ise Bloodbath
##   tespiti atlanıp doğrudan bu kadar zar tutulur (örn. Martyrdom Device'ın kendi 4D6'sı).
## extra_dice_mod: ek +/- Injury DICE (örn. Martyrdom Device'ın 1" içindeki modeller için +1).
## override_attack: saldıranın seçili silahı yerine kullanılacak AttackData.
## deed_*: yalnız Glorious Deed değerlendirmesi için (Sniper / Death From Above); ana saldırı
##   akışından geçirilir, off-hand/blast çağrılarında varsayılan false.
## extra_flat_mod: ek +/- Injury MODIFIER (dice DEĞİL — örn. Vengeful Scripture'ın +1'i).
func resolve_injury_roll(attacker_unit, critical_hit: bool, is_melee: bool, forced_keep_count: int = 0,
		extra_dice_mod: int = 0, override_attack: Resource = null,
		deed_is_long_range: bool = false, deed_in_cover: bool = false, deed_is_diving_charge: bool = false,
		extra_flat_mod: int = 0):
	var ctx := InjuryContext.new()
	ctx.attacker = attacker_unit
	ctx.target = self
	ctx.atk = override_attack
	ctx.critical_hit = critical_hit
	ctx.is_melee = is_melee
	ctx.forced_keep_count = forced_keep_count
	ctx.dice_mod = extra_dice_mod
	ctx.flat_mod = extra_flat_mod
	ctx.deed_is_long_range = deed_is_long_range
	ctx.deed_in_cover = deed_in_cover
	ctx.deed_is_diving_charge = deed_is_diving_charge
	await InjuryPipeline.resolve(ctx)

## INFLICT PAIN (Combat Biologist'in Vivisector'ı, P1-1): saldırgandan doğrudan uzağa D3" savurma.
## RAW: "If the target model would finish the move more than 1" from the attacking model, then
## the attacking model and any other models within 1" of the target model can make an additional
## Melee Attack on it before it is moved, as if the target were carrying out a retreat move. If
## this causes the model to move a second time, add D3" to the distance it is moved but do not
## attack it again." — ek saldırılar mevcut retreat-serbest-saldırı mekanizmasıyla AYNI
## (execute_free_melee_strike). Zincirleme ikinci bir Inflict Pain tetiklenirse (_inflict_pain_
## resolving true iken çağrılırsa) yeni bir saldırı turu AÇILMAZ — yalnız mesafe eklenir
## (_inflict_pain_extra_dist), dıştaki çağrı bunu TEK bir itmeye toplar.
## Bilinçli basitleştirme: taban-boyutu şartı (proje modellemiyor) ve impassable-terrain/climb
## istisnaları (navmesh clamp'e bırakıldı, arazi sistemi yok).
func _apply_inflict_pain(attacker) -> void:
	if not is_instance_valid(attacker):
		return
	var push_dist: int = randi_range(1, 3)
	if _inflict_pain_resolving:
		_inflict_pain_extra_dist += push_dist
		return

	_inflict_pain_resolving = true
	_inflict_pain_extra_dist = 0

	var dir: Vector3 = global_position - attacker.global_position
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3(1, 0, 0)
	var origin: Vector3 = global_position
	var raw_target: Vector3 = origin + dir * float(push_dist)

	if raw_target.distance_to(attacker.global_position) > GameState.ENGAGE_RANGE:
		var strikers: Array = [attacker]
		for u in UnitQuery.where(UnitQuery.within(UnitQuery.allies_of(attacker), origin, GameState.ENGAGE_RANGE),
				func(a): return a != self):
			strikers.append(u)
		for striker in strikers:
			if not is_instance_valid(self) or current_health <= 0 or is_down:
				break
			if is_instance_valid(striker) and striker.current_health > 0:
				await striker.execute_free_melee_strike(self)

	_inflict_pain_resolving = false
	if not is_instance_valid(self) or current_health <= 0 or is_down:
		return

	var total_dist: int = push_dist + _inflict_pain_extra_dist
	_inflict_pain_extra_dist = 0
	var final_target: Vector3 = origin + dir * float(total_dist)
	var map_rid: RID = get_world_3d().navigation_map
	var clamped: Vector3 = MovementHelper.get_clamped_target(map_rid, global_position, final_target, float(total_dist))

	# İtilen nokta başka bir modelin angaje mesafesindeyse savrulma iptal (saldıran hariç).
	if UnitQuery.any(UnitQuery.where(
			UnitQuery.within(UnitQuery.alive(), clamped, GameState.ENGAGE_RANGE),
			func(u): return u != self and u != attacker)):
		clamped = global_position

	if clamped != global_position:
		global_position = clamped
		RpcHelper.sync(self, "client_update_move", [clamped])
		GameLogger.log_info("[Inflict Pain] %s acıyla %d\" savruldu." % [display_name, total_dist], "COMBAT")

@rpc("authority", "call_local", "reliable")
func sync_health_states(new_hp: int, new_down: bool, new_blood: int, new_blessing: int = 0, new_infection: int = 0, play_shake: bool = false):
	var taken_damage = play_shake or (new_blood > blood_markers) or (new_down and not is_down) or (new_hp < current_health)
	
	current_health = new_hp
	is_down = new_down
	blood_markers = new_blood
	blessing_markers = new_blessing
	infection_markers = new_infection
	GameLogger.log_info("%s durum güncellemesi: Hayatta=%s, Down=%s, Kan=%d, Nimet=%d, Enfeksiyon=%d" % [display_name, str(current_health > 0), str(is_down), blood_markers, blessing_markers, infection_markers], "COMBAT")
	
	if taken_damage:
		GameLogger.log_info("%s hasar aldı, hasar efekti tetikleniyor." % display_name, "COMBAT")
		play_damage_effect()
	
	# Modeli devirme/kaldırma görselleştirmesi (Down durumunda piyonu yatırma)
	var target_node = model_node if is_instance_valid(model_node) else mesh_instance
	if is_instance_valid(target_node):
		var target_rot_x = -PI/2 if is_down else 0.0
		var tween = create_tween()
		tween.tween_property(target_node, "rotation:x", target_rot_x, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	if current_health <= 0:
		GameLogger.log_info("%s yok edildi (Savaş Dışı)!" % display_name, "COMBAT")
		GameState.unregister_unit(self)
		if GameState.selected_unit == self:
			GameState.deselect_unit()
		queue_free()
	else:
		update_indicators()

@rpc("authority", "call_local", "reliable")
func sync_actions_taken(p_actions: Array):
	actions_taken = p_actions
	update_indicators()
	if not multiplayer.has_multiplayer_peer() or is_multiplayer_authority():
		check_activation_complete()


@rpc("authority", "call_local", "reliable")
func sync_action_state(p_has_moved: bool):
	has_moved = p_has_moved
	update_indicators()

@rpc("authority", "call_local", "reliable")
func client_update_move(target_pos: Vector3):
	var map_rid = get_world_3d().navigation_map
	var path = NavigationServer3D.map_get_path(map_rid, global_position, target_pos, true)
	
	GameLogger.log_info("%s hareket ediyor. Mevcut konum: %s, Hedef konum: %s, Yol noktası: %d" % [display_name, str(global_position), str(target_pos), path.size()], "MOVEMENT")
	
	if path.size() > 0:
		current_path = path
		path_index = 1
		is_moving = true
	else:
		current_path = [global_position, target_pos]
		path_index = 1
		is_moving = true
		
	if range_indicator and range_indicator.has_method("hide_visuals"):
		range_indicator.hide_visuals()


@rpc("authority", "call_local", "reliable")
func play_attack_effect(target_pos: Vector3):
	var target_node = model_node if is_instance_valid(model_node) else mesh_instance
	if not is_instance_valid(target_node):
		return

	AudioManager.play_sfx_event(&"weapons/melee_hit")  # hamle animasyonuyla eş: yakın vuruş sesi

	var dir = (target_pos - global_position).normalized()
	dir.y = 0.0
	
	# Hedefe dön
	var look_target = global_position + dir
	if not global_position.is_equal_approx(look_target):
		look_at(look_target, Vector3.UP)
		
	var original_local_pos = target_node.position
	var forward_local_pos = original_local_pos + Vector3.FORWARD * 0.6
	
	var tween = create_tween()
	# İleriye hamle yap
	tween.tween_property(target_node, "position", forward_local_pos, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Geriye çekil
	tween.tween_property(target_node, "position", original_local_pos, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


## Trench Roll Zar Havuzu Hesaplama. Dönüş: [total, is_crit, rolled_values] — 3. eleman EYE OF GOD
## (P1-1) gibi tekil zar değerine ihtiyaç duyan mekanikler için (bkz. perform_unit_success_roll).
func perform_trench_roll(dice_modifier: int, flat_modifier: int = 0, roll_type: String = "success", keep_count: int = 2) -> Array:
	var res = await DiceRoller.perform_trench_roll(self, dice_modifier, flat_modifier, roll_type, keep_count)
	return [res[0], res[1], res[2]]

## Başarı Zarı atışı (P0-1). Compendium (blood-markers.md/blessing-markers.md):
## - RAKİP oyuncu, bu modelin Blood Marker'larını harcayıp Success Roll'a -1 Dice/marker ekleyebilir.
## - Bu modelin SAHİBİ, kendi Blessing Marker'larını harcayıp Success Roll'a +1 Dice/marker ekleyebilir.
## Bloodbath eşdeğeri yok (o yalnız Injury Roll'a özgü). Harcama oyuncu tercihidir; UI/overlay yoksa
## güvenli varsayılan (harcama yok) döner (bkz. CombatChoice._present).
## allow_blood_spend=false: ABSOLUTE FAITH (Sniper Priest, P1-1) gibi hedef-özel istisnalar için —
## çağıran taraf (server_request_attack_action) yalnız Ranged Attack'ta ve keyword varsa false geçer.
func perform_unit_success_roll(dice_modifier: int, allow_blood_spend: bool = true) -> Array:
	# Blood / Infection / Blessing harcaması TEK yerde (bkz. scripts/rules/marker_spend.gd):
	# üçü de "rakip/sahip kaç tane harcayacağını seçer, işaretler SİLİNİR" desenini paylaşır.
	var spend: Dictionary = await MarkerSpend.apply_to_success_roll(self, dice_modifier, allow_blood_spend)
	var mod: int = spend["modifier"]
	if spend["spent"]:
		CombatResolver.sync_target_health(self)

	var result: Array = await perform_trench_roll(mod, 0)

	# EYE OF GOD (Observer, P1-1): başarısız bir Success/Risky Roll'u reroll etme opsiyonu — ama
	# rerolled zarlardan biri 1 gösterirse Down + aktivasyon biter (compendium). Basitleştirme:
	# "başarısız" burada bu projenin genel eşiği olan 7'nin altı sayılır (tüm Success Roll çağıranları
	# zaten bu sabiti kullanıyor); Down iken tekrar tetiklenmez (zaten Down bir birim reroll edemez).
	if result[0] < 7 and not is_down and unit_data != null and KeywordSystem.has(unit_data, &"eye_of_god"):
		var reroll: bool = await CombatChoice.request_eye_of_god_reroll(self)
		if reroll:
			var rerolled: Array = await perform_trench_roll(mod, 0)
			var any_one: bool = false
			if rerolled.size() > 2:
				for d in rerolled[2]:
					if d == 1:
						any_one = true
						break
			if any_one:
				is_down = true
				GameLogger.log_warn("[Eye of God] %s reroll'de 1 gördü — Yere Serildi, aktivasyon bitti." % display_name, "COMBAT")
				CombatResolver.sync_target_health(self, true)
				TurnManager.end_unit_activation(self)
				result = [0, false, rerolled[2]]
			else:
				result = rerolled

	return result

## P0-1: Aktivasyon artık atış/retreat sonrası OTOMATİK bitmez. Compendium (Actions): aksiyonlar
## herhangi sırada alınır, her tür bir kez. Aktivasyon YALNIZCA yapılabilecek geçerli hiçbir
## aksiyon kalmadığında otomatik biter; aksi halde oyuncu "Aktivasyonu Bitir" ile açıkça bitirir.
## (Down/OOA, Dash fail, Risky fail, Shaken-ıska gibi kural-gereği bitişler ilgili yerlerde ayrıca
## yapılır ve check_activation_complete'ten bağımsızdır.)
## MASTERY OF THE ELEMENTS: yerleşimden sonra sahibine element seçtirir (Fire/Gas/Shrapnel).
## Yalnız birimin SAHİBİNE sorulur; UI yoksa varsayılan (fire) korunur.
func _request_mastery_element_choice() -> void:
	if unit_data == null or not KeywordSystem.has(unit_data, &"mastery_of_elements"):
		return
	var idx: int = await CombatChoice.request_element_choice(self)
	var choices: Array = MechanicsResolver.mastery_element_choices()
	if idx >= 0 and idx < choices.size():
		current_element = choices[idx]
		GameLogger.log_info("[Mastery of the Elements] %s silahlarına '%s' elementini verdi." \
			% [display_name, String(current_element)], "GAME")

func check_activation_complete():
	if multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		return
	# Birim HAREKET HALİNDEYKEN aktivasyon-bitiş kontrolü YAPILMAZ: aksiyon uygunluğu
	# konuma/angaje durumuna bağlıdır ve hareket bitene kadar bunlar geçiştedir. Örn. Charge
	# sırasında birim düşmana varmadan kontrol edilirse melee henüz "engaged değil" diye
	# uygun görünmez ve aktivasyon erken biter (oyuncu Fight yapamaz). Hareket tamamlanınca
	# (unit_movement._process) bu fonksiyon nihai konumla yeniden çağrılır.
	if is_moving:
		return
	# İDEMPOTENTLİK: aktivasyon zaten bitmişse (has_moved) tekrar TETİKLENMEZ. has_any_remaining_
	# action() zaten has_moved=true iken false döner, bu yüzden bu kontrol olmadan bir saldırının
	# birden çok aşamasında (doğrulama → zar → yara) her aşamada "aktivasyon sona eriyor" log'u
	# TEKRAR basılıyordu — işlevsel bir bug değil (server_end_unit_activation zaten idempotent),
	# ama kullanıcıya "aynı şey iki kez mi oldu?" izlenimi veren kafa karıştırıcı log gürültüsüydü.
	if has_moved:
		return
	if not has_any_remaining_action():
		GameLogger.log_info("%s: yapılabilecek başka aksiyon kalmadı, aktivasyon sona eriyor." % display_name, "TURN")
		TurnManager.end_unit_activation(self, true)

## Bu birimin şu an kurallara uygun yapabileceği en az bir aksiyonu var mı?
## Panel butonlarıyla aynı filtreleri kullanır (temel eylemler + uygulanmış yetenekler + kullanılabilir
## saldırılar) — böylece "buton var ama otomatik bitiyor" ya da tersi çelişki oluşmaz.
func has_any_remaining_action() -> bool:
	if has_moved:
		return false
	for act in ["move", "charge", "retreat", "dash"]:
		if can_perform_action(act):
			return true
	# Yetenekler — panel ile TEK kaynak filtre (AbilityExecutor.is_actionable_ability).
	if unit_data and unit_data.abilities:
		for ability_res in unit_data.abilities:
			var ab: AbilityData = ability_res as AbilityData
			if AbilityExecutor.is_actionable_ability(ab) and can_perform_action(ab.action_key):
				return true
	# Saldırılar (Assault etkileşim kuralı dahil — can_use_attack).
	if unit_data:
		for atk in unit_data.attacks:
			if can_use_attack(atk):
				return true
	return false


func get_fighter_state() -> StringName:
	if current_health <= 0:
		return &"STATE_OUT_OF_ACTION"
	elif is_down:
		return &"STATE_DOWN"
	else:
		return &"STATE_ACTIVE"

# ==================== GÖRSEL GERİ BİLDİRİM VE SEÇİM ====================

@rpc("authority", "call_local", "reliable")
func set_targeted(targeted: bool):
	is_targeted = targeted
	update_selection_ring()

## BOUNTY TARGET rozeti (Marked for Death senaryosu) — MarkedForDeathLogic tarafından, birimin
## KENDİ aksiyonu OLMADAN dışarıdan RpcHelper.sync ile set edilir (set_targeted ile aynı desen).
@rpc("authority", "call_local", "reliable")
func set_bounty_target(is_target: bool):
	is_bounty_target = is_target

func update_selection_ring():
	visuals_manager.update_selection_ring()

func play_damage_effect():
	visuals_manager.play_damage_effect()
	AudioManager.play_sfx_event(&"weapons/impact_metal")  # hasar görsel flash'ıyla eş: darbe sesi

## Yetenek/efekt görsel geri bildirimi — bir yetenek etkisi hedefe uygulandığında görünür işaret.
## RENK YOK (kullanıcı isteği): dost/pozitif etki → hafif yukarı "bob"; düşman/negatif → titreme.
## kind: "bless"/"heal"/"buff" (dost bob) | "debuff"/"curse" (düşman titreme).
## RpcHelper.sync(target, "play_ability_feedback", [kind]) ile tüm istemcilerde oynatılır.
@rpc("authority", "call_local", "reliable")
func play_ability_feedback(kind: String):
	match kind:
		"debuff", "curse":
			visuals_manager.play_effect_shake()
			AudioManager.play_sfx_event(&"abilities/cast")
		_:
			visuals_manager.play_effect_bob()
			AudioManager.play_sfx_event(&"abilities/buff")

# NOT: eski `is_near_enemy_chorister()` KALDIRILDI (2026-07-28). Hiçbir yerden çağrılmıyordu
# ve Chorister'ın gerçek kuralı zaten uygulanmış durumda: Unholy Hymns, `unholy_hymns` keyword'ü
# üzerinden DicePoolBuilder'da 8" aura olarak işliyor (düşman Success Roll'larına -1 Dice).
# `UnitData.is_chorister` alanı da bu yüzden silindi.

# ==================== FAKSİYON/BİRİM ÖZEL EYLEMLERİ ====================
# FAZ 3: Tüm yetenek mantığı AbilityExecutor'a delege edildi.
# Bu fonksiyonlar RPC shell olarak korunuyor (multiplayer uyumluluğu için).
# Yeni yetenek eklemek için: AbilityData .tres oluştur + UnitData.abilities[]'e ekle.

## Yetenekleri action_key üzerinden bulur ve AbilityExecutor'a iletir.
## target: unit node veya Vector3 (shadow_step için)
## extra_param: bazı yeteneklerin (örn. Ammunition Sacrament) yerel bir ön-seçim (sacrament türü
## gibi) taşıması için — çoğu yetenek için boş string, dokunmadan AbilityExecutor'a geçer.
func _execute_ability(action_key: String, target = null, extra_param: String = "") -> void:
	if unit_data == null:
		return
	for ability_res in unit_data.abilities:
		var ab: AbilityData = ability_res as AbilityData
		if ab == null or ab.action_key != action_key:
			continue
		var result: Dictionary = await AbilityExecutor.execute(ab, self, target, extra_param)
		if result.get("end_activation", false):
			TurnManager.end_unit_activation(self)
			return
		check_activation_complete()
		return
	push_warning("[Unit] %s: '%s' action_key ile eşleşen AbilityData bulunamadı." \
		% [display_name, action_key])

# ── GENERIC ABILITY SYSTEM (Faksiyon Yetenekleri) ─────────────────────────────
func request_ability_action(action_key: String, target = null, extra_param: String = "") -> void:
	if not can_perform_action(action_key):
		return

	var serialized_target = null
	if target is Node3D and target.has_method("is_unit"):
		serialized_target = target.name
	else:
		serialized_target = target

	if multiplayer.has_multiplayer_peer():
		rpc_id(1, "server_request_ability", action_key, serialized_target, extra_param)
	else:
		server_request_ability(action_key, serialized_target, extra_param)

@rpc("any_peer", "reliable")
func server_request_ability(action_key: String, serialized_target, extra_param: String = "") -> void:
	if not RpcHelper.validate_rpc_request(self, owner_id):
		return
	# SUNUCU-OTORİTER YENİDEN DOĞRULAMA: istemcinin ÖN kontrolü (request_ability_action'daki
	# can_perform_action) yalnız İSTEMCİNİN o anki (belki bayat) actions_taken'ına güvenir —
	# AbilityExecutor.execute() actions_taken'a KOŞULSUZ ekler (zaten kullanılmış mı diye tekrar
	# bakmaz). Hızlı çift-tıklama/ağ gecikmesi iki RPC'yi de sunucuya ulaştırabilirse, ikinci RPC
	# etkiyi (zar/hasar/buff) İKİNCİ KEZ uygulardı ("yetenek kullanıyorum sonra tekrar
	# kullanabiliyorum" bildirimi). Sunucu burada KENDİ güncel actions_taken'ına göre tekrar kontrol eder.
	if not can_perform_action(action_key):
		return

	# KRİTİK: Node.name StringName'dir; eski `is String` kontrolü yerel oyunda birim adını
	# çözemiyordu → hedef düşüyordu ("Geçerli hedef yok"). AbilityExecutor.resolve_target
	# StringName + String + Vector3/null'u doğru çözer (regresyon testi: ability_target_resolve_test).
	var target = AbilityExecutor.resolve_target(serialized_target)
	await _execute_ability(action_key, target, extra_param)




func get_line_of_sight_status(target_unit) -> Dictionary:
	return combat_manager.get_line_of_sight_status(target_unit)

func is_target_in_cover(target_unit) -> bool:
	return combat_manager.is_target_in_cover(target_unit)

