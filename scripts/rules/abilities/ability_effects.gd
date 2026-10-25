## VERİ ODAKLI YETENEK EFEKTLERİ — `AbilityData.effect_type` ile seçilen JENERİK davranışlar.
##
## Bu dosyadaki efektler BİRİME ÖZEL DEĞİLDİR: bir `.tres` dosyası `effect_type = "blessing"`
## yazdığı anda KOD YAZMADAN çalışır. Bu yüzden burası KAPALI bir kümedir — yeni bir birim
## yeteneği eklemek normalde buraya dokunmaz; birime özel mantık `abilities/custom/` altına gider
## (bkz. `ability_registry.gd`).
##
## `ability_executor.gd`den çıkarıldı: o dosya çalıştırma akışının (doğrulama → zar → efekt)
## sahibidir; efektlerin gövdesini de taşıması onu tavana dayamıştı.
class_name AbilityEffects

const AbilityData = preload("res://scripts/data/ability_data.gd")
const CombatResolver = preload("res://scripts/rules/combat_resolver.gd")

## Tanınan tüm `effect_type` değerleri. `.tres` verisinin bütünlüğünü sınayan testler bunu
## okur — veride tanınmayan bir effect_type kalırsa yetenek SESSİZCE hiçbir şey yapmaz.
const EFFECT_TYPES := [
	"blessing", "remove_blood", "stand_up", "treat_choice", "move_allies",
	"force_activation", "force_move", "teleport", "buff_dice", "add_blood",
	"add_infection", "set_flag", "custom",
]

## effect_type'a göre jenerik efekti uygular. Döner: `end_activation`.
## `custom` BURADA ELE ALINMAZ — onu `AbilityExecutor` registry üzerinden yönlendirir.
static func apply(ctx: AbilityContext) -> bool:
	var ability: AbilityData = ctx.ability
	var caster = ctx.caster
	var target = ctx.target
	var roll_total: int = ctx.roll_total
	var is_crit: bool = ctx.is_crit

	match ability.effect_type:
		"blessing":
			return _handle_blessing(ability, caster, target, roll_total)
		"remove_blood":
			return _handle_remove_blood(ability, caster, target, roll_total, is_crit)
		"stand_up":
			return _handle_stand_up(ability, caster, target, roll_total)
		# TREAT (Medi-Kit): compendium başarıda İKİ etkiden BİRİNİ seçtirir. Gövde MedicActions'ta.
		"treat_choice":
			return await MedicActions.handle_treat(caster, target, roll_total)
		"move_allies":
			return await _handle_move_allies(ability, caster, roll_total)
		"force_activation":
			return _handle_force_activation(ability, caster, target, roll_total)
		"force_move":
			return await _handle_force_move(ability, caster, target, roll_total)
		"teleport":
			return await _handle_teleport(ability, caster, target, roll_total)
		"buff_dice":
			return _handle_buff_dice(ability, caster, target, roll_total)
		"add_blood":
			return _handle_add_blood(ability, caster, target, roll_total, is_crit)
		"add_infection":
			return _handle_add_infection(ability, caster, target, roll_total)
		"set_flag":
			return _handle_set_flag(ability, caster, roll_total)
		_:
			push_warning("[AbilityEffects] Bilinmeyen efekt tipi: %s" % ability.effect_type)
			return false

# ─────────────────────────────────────────────────────────────────────────────
# EFEKTLER — BİR BİR
# ─────────────────────────────────────────────────────────────────────────────

## BLESSING — God is With Us (Trench Pilgrims War Prophet)
## Başarı: Hedef birim +1 Blessing Marker kazanır.
static func _handle_blessing(_ability: AbilityData, caster, target, roll_total: int) -> bool:
	if not is_instance_valid(target) or target.current_health <= 0:
		return false
	target.blessing_markers = min(target.blessing_markers + 1, 6)
	GameLogger.log_info("[God is With Us] %s duası başarılı (%d)! %s +1 Nimet İşareti kazandı." \
		% [caster.display_name, roll_total, target.display_name], "GAME")
	CombatResolver.sync_target_health(target)
	RpcHelper.sync(target, "play_ability_feedback", ["bless"])
	return false  # Aktivasyon bitmez

## REMOVE_BLOOD — Treat (Combat Medic) / Laying on Hands (Trench Cleric)
## Başarı: Hedefi Down'dan kaldırır VEYA Blood Marker azaltır.
## Kritik: Daha fazla Blood Marker silinir (crit_amount).
## NOT: Compendium kuralı — "Rules that allow Blood Markers to be removed CANNOT remove
## Infection Markers unless explicitly noted otherwise." Bu fonksiyon YALNIZCA blood_markers
## alanına dokunur; infection_markers'a dokunmak YASAKtır (Kara Kase Laneti).
static func _handle_remove_blood(ability: AbilityData, caster, target, roll_total: int, is_crit: bool) -> bool:
	if not is_instance_valid(target) or target.current_health <= 0:
		return false
	# DEMONIC AURA — GLUTTONY: hedef 3" içinde Gluttony aurasındaysa tedavi alamaz.
	if MechanicsResolver.is_in_demonic_aura(target, &"gluttony_aura"):
		GameLogger.log_warn("[%s] %s Oburluk Aurası nedeniyle tedavi alamıyor!" \
			% [ability.display_name, target.display_name], "COMBAT")
		return false
	var amount: int = ability.crit_amount if is_crit else ability.effect_amount
	target.blood_markers = max(0, target.blood_markers - amount)
	GameLogger.log_info("[%s] %s tedavisi başarılı (%d)! %s'den %d Kan İşareti silindi." \
		% [ability.display_name, caster.display_name, roll_total, target.display_name, amount], "GAME")
	# INFECTION MARKER BAĞIŞIKLIĞI (Cult of the Black Grail, compendium keyword.md):
	# Oyuncuya Infection Marker'ların tedavi ile TEMİZLENEMEYECEĞİNİ açıkça bildir.
	if target.infection_markers > 0:
		GameLogger.log_info("[%s] ⚠ %s üzerindeki %d Enfeksiyon İşareti tedavi ile temizlenemez (Kara Kase Laneti)." \
			% [ability.display_name, target.display_name, target.infection_markers], "COMBAT")
	CombatResolver.sync_target_health(target)
	RpcHelper.sync(target, "play_ability_feedback", ["heal"])
	return false

## STAND_UP — Treat (hedef Down ise)
## Başarı: Hedef birim Down'dan ayağa kalkar.
## NOT: Infection Marker'lar tedavi ile temizlenemez (bkz. _handle_remove_blood notu).
static func _handle_stand_up(_ability: AbilityData, caster, target, roll_total: int) -> bool:
	if not is_instance_valid(target) or target.current_health <= 0:
		return false
	# DEMONIC AURA — GLUTTONY: hedef 3" içinde Gluttony aurasındaysa tedavi alamaz.
	if MechanicsResolver.is_in_demonic_aura(target, &"gluttony_aura"):
		GameLogger.log_warn("[%s] %s Oburluk Aurası nedeniyle tedavi alamıyor!" \
			% [_ability.display_name, target.display_name], "COMBAT")
		return false
	if target.is_down:
		target.is_down = false
		GameLogger.log_info("[Tedavi] %s tedavisi başarılı (%d)! %s ayağa kalktı." \
			% [caster.display_name, roll_total, target.display_name], "GAME")
	elif target.blood_markers > 0:
		target.blood_markers = max(0, target.blood_markers - 1)
		GameLogger.log_info("[Tedavi] %s tedavisi başarılı (%d)! %s 1 Kan İşareti kaybetti." \
			% [caster.display_name, roll_total, target.display_name], "GAME")
	# INFECTION MARKER BAĞIŞIKLIĞI: oyuncuya bildirim.
	if target.infection_markers > 0:
		GameLogger.log_info("[Tedavi] ⚠ %s üzerindeki %d Enfeksiyon İşareti tedavi ile temizlenemez (Kara Kase Laneti)." \
			% [target.display_name, target.infection_markers], "COMBAT")
	CombatResolver.sync_target_health(target)
	RpcHelper.sync(target, "play_ability_feedback", ["heal"])
	return false

## MOVE_ALLIES — Loudspeakers (War Prophet, Yuzbasi)
## Başarı: caster'ın ability.range_meters (8") içindeki tüm dost birimler 3 m düşmana doğru hareket eder.
static func _handle_move_allies(ability: AbilityData, caster, roll_total: int) -> bool:
	GameLogger.log_info("[Loudspeakers] %s hoparlör çağrısı başarılı (%d)! Dost birimler 3 m ilerliyor." \
		% [caster.display_name, roll_total], "GAME")
	var affected: Array = UnitQuery.allies_of(caster)
	if ability.range_meters > 0.0:
		affected = UnitQuery.within(affected, caster.global_position, ability.range_meters)
	for u in affected:
		# "They must end the move as close as possible to the nearest enemy model THAT WAS
		# VISIBLE TO THEM at the start of the move." → görüş hattı olan en yakın düşman.
		# Hiç görünür düşman yoksa compendium "they can move normally" der → hareket ettirilmez.
		var visible_enemies: Array = UnitQuery.where(UnitQuery.enemies_of(caster),
			func(e):
				if not u.has_method("get_line_of_sight_status"):
					return true
				return not u.get_line_of_sight_status(e).get("is_blocked", false))
		var nearest_enemy = UnitQuery.nearest(visible_enemies, u.global_position)
		if nearest_enemy:
			var dir: Vector3 = (nearest_enemy.global_position - u.global_position).normalized()
			var target_pos: Vector3 = u.global_position + dir * float(ability.effect_amount)
			var map_rid = u.get_world_3d().navigation_map
			var closest: Vector3 = NavigationServer3D.map_get_closest_point(map_rid, target_pos)
			if u.multiplayer.has_multiplayer_peer():
				u.rpc("client_update_move", closest)
			else:
				u.client_update_move(closest)
			# "This move can be used to bring a model within 1" of an enemy model IN WHICH CASE
			# THE MODEL COUNTS AS CHARGING." (trench-pilgrims.md) — yeteneğin tek gerçek payoff'u
			# budur; olmadan Loudspeakers sadece bir konum düzeltmesine dönüşüyordu
			# (denetim bulgusu P1-TP-4). Charge bayrağı, Fight aksiyonunun Charge Bonus'unu
			# ve counter_charge gibi "ilk eylem Charge'dı" kurallarını tetikler.
			if closest.distance_to(nearest_enemy.global_position) <= GameState.ENGAGE_RANGE:
				if not u.actions_taken.has("charge"):
					u.actions_taken.append("charge")
					RpcHelper.sync(u, "sync_actions_taken", [u.actions_taken])
				GameLogger.log_info("[Loudspeakers] %s düşmanla temasa girdi — HÜCUM sayılıyor." \
					% u.display_name, "GAME")
	return false

## FORCE_ACTIVATION — Hold Your Fire (New Antioch Lieutenant)
## Başarı: Düşman birim bir sonraki tur ilk aktive olmak zorunda kalır.
## Compendium (Hold Your Fire!): otomatik (roll gerekmez — hold_your_fire.tres requires_roll=false)
## VE "The Lieutenant's Activation then ends" — bu yüzden true döner (execute()'ta end_activation).
static func _handle_force_activation(_ability: AbilityData, caster, target, roll_total: int) -> bool:
	# "has not yet been Activated this Turn" — TurnManager.activated_units TEK doğruluk kaynağı
	# (Puppet Master'ın _handle_force_move'u da aynı listeyi kullanıyor). Eskiden target.has_moved
	# kontrol ediliyordu, ama hareket etmeden ateş/yetenek kullanan bir birim has_moved=false kalır
	# ve YANLIŞLIKLA "henüz aktive olmamış" sayılabilirdi (aynı tur içinde ikinci kez zorlanabilirdi).
	if not is_instance_valid(target) or target.current_health <= 0 \
			or TurnManager.activated_units.has(target.name):
		return false
	GameLogger.log_info("[Hold Your Fire] %s emri başarılı (%d)! %s sonraki el ilk aktive olmak zorunda." \
		% [caster.display_name, roll_total, target.display_name], "GAME")
	TurnManager.forced_next_activator = target.name
	if target.multiplayer.has_multiplayer_peer():
		TurnManager.rpc("sync_forced_activator", target.name)
	RpcHelper.sync(target, "play_ability_feedback", ["debuff"])
	return true

## FORCE_MOVE — Puppet Master (Heretic Legion, Heretic Priest)
## PUPPET MASTER: compendium — "You can move the model D6". The move must be in a straight line,
## but can be in any direction..." — "You" CASTER'dır (hedefin sahibi DEĞİL). 2026-07-16
## düzeltmesi: yön artık CASTER'ın kendisine, haritada tıklayarak seçtirilir (Time Slip'in
## position-pick altyapısı yeniden kullanıldı — CombatChoice.request_position_pick'e yeni
## decider_id parametresi eklendi: menzil halkası hedefin konumunda gösterilir, ama kararı
## CASTER'ın oyuncusu verir). Reddederse (iptal) D6" tam kullanılmadan en yakın geçerli noktaya
## clamp'lenir — mevcut request_position_pick zaten NavMesh/mesafe doğrulamasını sunucuda yapıyor.
static func _handle_force_move(_ability: AbilityData, caster, target, roll_total: int) -> bool:
	if not is_instance_valid(target) or target.current_health <= 0:
		return false
	GameLogger.log_info("[Puppet Master] %s zihin kontrolü başarılı (%d)! %s zihni bulandı." \
		% [caster.display_name, roll_total, target.display_name], "GAME")
	RpcHelper.sync(target, "play_ability_feedback", ["debuff"])
	if not TurnManager.activated_units.has(target.name):
		TurnManager.activated_units.append(target.name)
	if target.multiplayer.has_multiplayer_peer():
		target.rpc("sync_action_state", true)
	else:
		target.sync_action_state(true)
	# roll_id FİLTRESİ (DiceRoller.perform_trench_roll ile AYNI desen): filtresiz bir await,
	# bu sırada başlayan BAŞKA bir atışın sonucunu yanlışlıkla kabul edebilir — "zar düşüyor,
	# animasyon yarıda kesiliyor" bug sınıfının kök nedenlerinden.
	var is_roll_owner: bool = not caster.multiplayer.has_multiplayer_peer() or caster.multiplayer.is_server()
	if is_roll_owner:
		DiceManager.roll_dice(1)
	var expected_roll_id: int = DiceManager.current_roll_id if is_roll_owner else -1
	var d6_res: Array = await DiceManager.dice_roll_completed
	while is_roll_owner and d6_res[2] != expected_roll_id:
		d6_res = await DiceManager.dice_roll_completed
	var move_dist: float = float(d6_res[0])
	# UI: bu çıplak D6 atışı önceden hiç zar-sonuç barı GÖSTERMİYORDU (yalnız DiceRoller.
	# perform_trench_roll ve combat_resolver'ın kendi d6'sı show_dice_bar_ui yayınlıyordu) —
	# 3D zar animasyonu oynuyordu ama sonuç ekranda hiç görünmüyordu.
	# roll_type="d6" KULLANMA: o etiket dice_bar.gd'de SADECE combat_resolver'ın "dost ateşi"
	# kontrolüne özel anlam taşıyor (≤3 → "Dost Ateşi" metni basar) — bu bedelsiz bonus-mesafe
	# atışıyla alakası yok, "bonus_roll" kullanılırsa metinsiz sade toplam gösterilir.
	DiceManager.show_dice_bar_ui.emit(d6_res[1], 1, true, 0, d6_res[0], "bonus_roll")
	var map_rid = target.get_world_3d().navigation_map
	var picked = await CombatChoice.request_position_pick(target, move_dist, "PUPPET_MASTER_PICK", caster.owner_id)
	var forced_pos: Vector3
	if picked == null:
		# İptal/UI yoksa güvenli varsayılan: sabit bir yönde tam D6" (akış asla kilitlenmez).
		forced_pos = target.global_position + Vector3(1, 0, 0) * move_dist
	else:
		var dir: Vector3 = (picked - target.global_position)
		dir.y = 0.0
		if dir.length() < 0.01:
			dir = Vector3(1, 0, 0)
		dir = dir.normalized()
		forced_pos = target.global_position + dir * move_dist
	var closest: Vector3 = NavigationServer3D.map_get_closest_point(map_rid, forced_pos)
	if target.multiplayer.has_multiplayer_peer():
		target.rpc("client_update_move", closest)
	else:
		target.client_update_move(closest)
	return false

## TELEPORT — Shadow Step (Court Hunter of the Left Hand Path)
## Başarı: Caster seçilen konuma ışınlanır (max_distance m).
static func _handle_teleport(ability: AbilityData, caster, target_pos: Vector3, roll_total: int) -> bool:
	var dist: float = caster.global_position.distance_to(target_pos)
	if dist > ability.max_distance:
		GameLogger.log_warn("[Shadow Step] Mesafe fazla! Max: %.1f m" % ability.max_distance, "GAME")
		GameEvents.ability_rejected.emit("TELEPORT_FAIL_TOO_FAR")
		return false
	var map_rid = caster.get_world_3d().navigation_map
	var closest: Vector3 = NavigationServer3D.map_get_closest_point(map_rid, target_pos)
	# Move/Charge ile AYNI tolerans (MovementHelper.resolve_nav_target, GameState.NAV_MOVE_
	# TOLERANCE): yalnız YATAY (XZ) sapma kontrol edilir. Eskiden ham 3B distance_to (Y dahil) >1.5
	# kullanılıyordu — hafif eğimli/tırmanılabilir zeminde ÇOK katı kalıp geçerli tıklamaları
	# sessizce reddediyordu ("zar attı ama ışınlanmadı" regresyonu). Tek doğrulama kaynağına hizalandı.
	var nav_res: Dictionary = MovementHelper.resolve_nav_target(closest, target_pos, GameState.NAV_MOVE_TOLERANCE)
	if not nav_res["valid"]:
		GameLogger.log_warn("[Shadow Step] Geçersiz konum (NavMesh dışı)!", "GAME")
		GameEvents.ability_rejected.emit("TELEPORT_FAIL_INVALID_POSITION")
		return false
	closest = nav_res["target"]
	GameLogger.log_info("[Shadow Step] %s gölge adımı başarılı (%d)!" % [caster.display_name, roll_total], "GAME")
	var origin: Vector3 = caster.global_position
	caster.global_position = closest
	if caster.multiplayer.has_multiplayer_peer():
		caster.rpc("client_update_move", closest)
	else:
		caster.client_update_move(closest)

	# GOETIC PORTAL (Goetic Warlock, P1-1): "if the Goetic Warlock is within 1" of any enemy
	# models mounted on a 32mm base or smaller, then the Goetic Warlock can take 1 of the enemy
	# models with them." Basitleştirme (dokümante, Pin/Sin Eater ile AYNI aile): taban-boyutu
	# şartı taşınmadı (proje modellenmiyor) — 1" içindeki İLK uygun düşman otomatik sürüklenir
	# (RAW oyuncuya "can" diyor, yani seçimlik; tek-düşman-varsa otomatik almak zararsız bir
	# sadeleştirme — birden fazla düşman varsa yalnız en yakını alınır).
	if ability.ability_id == &"goetic_portal":
		# Işınlanma ANINDA caster ile angaje olan en yakın düşman birlikte sürüklenir.
		var dragged = UnitQuery.nearest(
			UnitQuery.within(UnitQuery.enemies_of(caster), origin, GameState.ENGAGE_RANGE),
			origin)
		if dragged != null:
			var drag_pos: Vector3 = MovementHelper.get_clamped_target(map_rid, closest, dragged.global_position, GameState.ENGAGE_RANGE)
			dragged.global_position = drag_pos
			RpcHelper.sync(dragged, "client_update_move", [drag_pos])
			GameLogger.log_info("[Goetic Portal] %s, %s modelini kendisiyle birlikte ışınladı." \
				% [caster.display_name, dragged.display_name], "GAME")
	return false

## BUFF_DICE — Alchemical Brew (Jabirean Alchemist)
## Başarı: Hedef birim geçici +N DICE bonus kazanır.
static func _handle_buff_dice(ability: AbilityData, caster, target, roll_total: int) -> bool:
	if not is_instance_valid(target) or target.current_health <= 0:
		return false
	if ability.buff_is_melee or ability.buff_also_ranged:
		target.melee_dice_modifier += ability.effect_amount
	if not ability.buff_is_melee or ability.buff_also_ranged:
		target.ranged_dice_modifier += ability.effect_amount
	GameLogger.log_info("[Alchemical Brew] %s simyasal karışımı başarılı (%d)! %s geçici +%d DICE kazandı." \
		% [caster.display_name, roll_total, target.display_name, ability.effect_amount], "GAME")
	RpcHelper.sync(target, "play_ability_feedback", ["buff"])
	return false

## ADD_BLOOD — Düşman hedefe Kan İşareti (Goetic Gaze, Divine Judgement).
## amount = effect_amount (+ blood_bonus_vs_unholy, hedef Demonic/Black Grail/Heretic ise).
static func _handle_add_blood(ability: AbilityData, caster, target, roll_total: int, is_crit: bool = false) -> bool:
	if not is_instance_valid(target) or target.current_health <= 0:
		return false
	# GOETIC GAZE (Goetic Warlock, P1-1): "If the roll is a Critical Success, place 2 Blood
	# Markers instead of only 1." — remove_blood'un is_crit/crit_amount deseniyle AYNI (crit_amount
	# ayarlanmamışsa 0 kalır, davranış eskisiyle BİREBİR aynı — geriye dönük uyumlu).
	var amount: int = maxi(1, ability.crit_amount) if (is_crit and ability.crit_amount > 0) else maxi(1, ability.effect_amount)
	if ability.blood_bonus_vs_unholy != 0 and target.unit_data != null \
			and KeywordSystem.is_unholy(target.unit_data):
		amount += ability.blood_bonus_vs_unholy
	target.blood_markers = min(target.blood_markers + amount, 6)
	GameLogger.log_info("[%s] %s başarılı (%d)! %s +%d Kan İşareti aldı." \
		% [ability.display_name, caster.display_name, roll_total, target.display_name, amount], "GAME")
	CombatResolver.sync_target_health(target)
	RpcHelper.sync(target, "play_ability_feedback", [_feedback_or(ability, "curse")])
	return false

## ADD_INFECTION — Ravenous Infection (The Great Hunger: Ravenous/Cradle Ravenous/Butcher Knight):
## Risky Action, başarılıysa 1" içindeki hedefe 1 Infection Marker koyar, Aktivasyon biter.
static func _handle_add_infection(ability: AbilityData, caster, target, roll_total: int) -> bool:
	if not is_instance_valid(target) or target.current_health <= 0:
		return true
	var amount: int = maxi(1, ability.effect_amount)
	target.infection_markers = min(target.infection_markers + amount, 6)
	GameLogger.log_info("[%s] %s başarılı (%d)! %s +%d Enfeksiyon İşareti aldı." \
		% [ability.display_name, caster.display_name, roll_total, target.display_name, amount], "GAME")
	CombatResolver.sync_target_health(target)
	RpcHelper.sync(target, "play_ability_feedback", [_feedback_or(ability, "curse")])
	return true  # Compendium: "A model's Activation ends immediately after using this Ability."

## SET_FLAG — Caster'da bir durum bayrağını açar (Hide/Fortify/Shadow Walker gibi).
## flag_name birim üzerindeki bool alandır; tüm istemcilerde sync_ability_flags ile senkronlanır.
static func _handle_set_flag(ability: AbilityData, caster, roll_total: int) -> bool:
	if ability.flag_name == "":
		push_warning("[AbilityExecutor] set_flag: flag_name boş (%s)" % ability.ability_id)
		return false
	caster.set(ability.flag_name, true)
	if caster.multiplayer.has_multiplayer_peer():
		caster.rpc("sync_ability_flags", caster.is_hidden, caster.has_fortify_cover, caster.shadow_walker_active, caster.slashing_attack_active)
	GameLogger.log_info("[%s] %s durumu açıldı (%d) [%s]." \
		% [ability.display_name, caster.display_name, roll_total, ability.flag_name], "GAME")
	RpcHelper.sync(caster, "play_ability_feedback", [_feedback_or(ability, "buff")])
	return false

## AbilityData.feedback_kind boşsa verilen varsayılanı kullan.
static func _feedback_or(ability: AbilityData, default_kind: String) -> String:
	return ability.feedback_kind if ability.feedback_kind != "" else default_kind
