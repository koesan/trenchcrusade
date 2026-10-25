extends Node

## Oyun aşamalarını temsil eden sabit değerler.
## SCENARIO_SELECT: faction seçiminden önce senaryo seçimi (host/aktif oyuncu seçer).
## SCENARIO_SELECT -> DEPLOYMENT -> ARMOURY -> BATTLE.
## ARMOURY: yerleştirme bittikten sonra, savaş başlamadan önce oyuncular sahadaki modellerine
## Battlekit satın alır (compendium'daki Quartermaster adımının çatışma modu karşılığı).
enum GamePhase { SCENARIO_SELECT, DEPLOYMENT, ARMOURY, BATTLE }

## ── BOARD ÖLÇEĞİ (P3-10, çözüldü): 1 Godot dünya birimi ≈ 1 inç. ─────────────────
## Kanıt: Charge tavanı min(speed+6, 12.0) = compendium 12"; CLIMB_FREE_MAX=3.0 = trench wall 3".
## DIVING_CHARGE_MIN_HEIGHT=3.0 = compendium "Jumps Down at least 3\"". Mesafe sabitleri ölçeğe göre; taban
## yarıçapı payı için ENGAGE_RANGE/tolerans değerleri 1.0'dan biraz büyüktür (aşağıdaki not).
## "1 inç" angaje/yakınlık mesafesi (dünya birimi). Tüm engagement, retreat, dost-ateşi,
## CLEAVE ve "1 inç içinde" kontrolleri bu sabiti kullanır (compendium "within 1 inch").
## TABANDAN TABANA ÖLÇÜM (compendium: mesafeler modellerin bazları arasında ölçülür): model taban
## yarıçapı 0.6 → bazlar arası 1" = merkezler arası 1.0 + 2×0.6 = 2.2 (önceki 1.3, bazlar arasında
## yalnız 0.1" bırakıyordu — angajman fiilen temas gerektiriyordu).
## Ölçek ayarı gerekirse merkezi config'ten (game_config.json → balance) değiştirin.
## NOT: Bu değerler artık GameConfig'ten (tek kaynak) okunur; buradaki sayı yalnızca GÜVENLİ
## VARSAYILAN'dır (JSON eksik/bozuksa). GameConfig autoload'ı GameState'ten ÖNCE hazır olduğundan
## bu member-init okumaları güvenlidir.
var ENGAGE_RANGE: float = GameConfig.f("balance/engage_range", 2.2)

## İKİ TABAN YARIÇAPI (2×0.6): merkezden ölçülen model-model mesafesine eklenen pay — silah/yetenek
## menzili ve "X\" içindeki modeller" (UnitQuery.enemies_within/allies_within) tabandan tabana ölçülür.
var ATTACK_RANGE_TOLERANCE: float = GameConfig.f("balance/attack_range_tolerance", 1.2)

## Hücum mesafesi bazların temas ettiği noktaya ölçülür → merkez mesafesinden 2×0.6 düşülür.
var CHARGE_REACH_TOLERANCE: float = GameConfig.f("balance/charge_reach_tolerance", 1.2)

# ── DİKEY HAREKET (Climbing / Jumping Down / Falling) — compendium ──────────────
## NavMesh'in serbest bağladığı azami basamak yüksekliği (game.gd bake `agent_max_climb`).
## VERTICAL_STEP_MAX bunu AŞMAMALI: "flat" sayılan her yükseklik navmesh tarafından gerçekten
## geçilebilir olmalı; aksi halde kodda flat ama navmesh geçemez → birim hareket etmez (eski
## 0.6/0.8 ölü bölgesi). Tek kaynak: game.gd bu sabiti kullanır.
var NAV_AGENT_MAX_CLIMB: float = GameConfig.f("balance/nav_agent_max_climb", 0.8)
## Bu yükseklik farkının altı düz sayılır (NavMesh zaten hallediyor; obstacle ≤1").
## NAV_AGENT_MAX_CLIMB'i aşmamalı (yukarıdaki nota bkz.).
var VERTICAL_STEP_MAX: float = GameConfig.f("balance/vertical_step_max", 0.8)
## Yukarı bu yüksekliğe kadar serbest geçilir (compendium: trench walls ≤3" = Open).
## Üstü "sheer surface" sayılır → Risky Success (tırmanma) gerekir.
var CLIMB_FREE_MAX: float = GameConfig.f("balance/climb_free_max", 3.0)
## Bu yükseklik ve üzeri düşüşlerde Falling Injury Roll yapılır (her 3" için +1 Injury Dice).
## Bu haritaya göre kalibre: 4.8"'e kadar iniş güvenli (siper duvarı) sayılır; fazlası düşme.
## DIVING CHARGE eşiği — compendium (melee-attacks.md): "You can convert a charge for a friendly
## model into a diving charge **if it Jumps Down AT LEAST 3"** and lands within 1" of a target."
##
## KURAL SAPMASI DÜZELTMESİ (2026-07-29): eskiden `fall_injury_height = 4.8` idi — o değer
## GÖNÜLLÜ düşme ölümleri içindi, ama o mekanik kaldırıldı ve sabit yalnız Diving Charge eşiği
## olarak kaldı. 4.8 ile 3.0-4.8 arasından yapılan hücumlar Diving Charge SAYILMIYORDU.
var DIVING_CHARGE_MIN_HEIGHT: float = GameConfig.f("balance/diving_charge_min_height", 3.0)
## Hareket hedefinin NavMesh'e hizalanma toleransı (dünya birimi). Ham tıklama en yakın
## navigasyon noktasından bu kadar uzaksa "geçerli zemin dışı" sayılıp reddedilir; böylece
## yüzey altı boşluğa tıklama yanlışlıkla ölümcül "aşağı atlama"ya dönüşmez. Yerleşim
## doğrulamasıyla (game.gd) aynı değer.
var NAV_MOVE_TOLERANCE: float = GameConfig.f("balance/nav_move_tolerance", 2.5)

## P1-1 (Sultanate Assassin — Time Slip): kaçırılan bir saldırı sonrası opsiyonel yeniden
## konuşlanma yarıçapı (compendium: "redeploy anywhere within 6\", base-center to base-center").
var TIME_SLIP_RADIUS: float = GameConfig.f("balance/time_slip_radius", 6.0)

## Compendium: Charge toplam hareketi (Movement + Charge Bonus zar sonucu) en fazla 12" olabilir.
## TEK KAYNAK — önceden unit.gd (x3) ve ability_executor.gd (x2) ve unit_movement.gd'nin görsel
## menzil ÖNİZLEMESİNDE ayrı ayrı 12.0 literal'i olarak tekrarlanıyordu (config denetimi bulgusu):
## biri değişip diğerleri unutulursa önizleme ile gerçek hücum menzili SESSİZCE birbirinden
## sapardı (oyuncuya yanlış bilgi gösterirdi).
var CHARGE_DISTANCE_CAP: float = GameConfig.f("balance/charge_distance_cap", 12.0)

## Savaş alanının XZ düzlemindeki sınırları — game.gd navmesh pişirmesi bitince
## NavigationMesh.get_vertices()'ten hesaplar (bkz. game.gd::_compute_battlefield_bounds).
## AUTOMATON DESTRIER (Mamluk Faris) gibi "harita kenarına yakın" kurallarının TEK KAYNAĞI.
## size==ZERO ise henüz hesaplanmadı (o kurala bağlı yerleşim istekleri reddedilir).
var battlefield_bounds: AABB = AABB()

signal unit_selected(unit_node)
signal unit_deselected
signal deployment_completed
signal faction_selected(player_id, faction)
signal unit_deployed(player_id, unit_node)
signal active_deployer_changed(new_deployer_id: int)
## Oyun aşaması (GamePhase) her değiştiğinde yayılır (SCENARIO_SELECT/DEPLOYMENT/BATTLE).
signal game_phase_changed(phase_idx: int)

## Faksiyon kataloğu — TEK KAYNAK. Liste + sıra + logolar burada DEĞİL; hepsi manifest'te.
const FACTIONS_MANIFEST := preload("res://assets/data/factions/factions_manifest.tres")

## Oyunda kullanılabilir faksiyonlar. Yeni faksiyon eklemek için `factions_manifest.tres`'e
## yeni FactionData .tres ekle (editörden sürükle-bırak) — burada KOD DEĞİŞMEZ.
## (.duplicate(): _notification temizliği manifest'in paylaşılan dizisini bozmasın diye.)
var available_factions: Array = FACTIONS_MANIFEST.factions.duplicate()

## Oyun aşaması: DEPLOYMENT (yerleştirme) veya BATTLE (savaş)
var game_phase: GamePhase = GamePhase.DEPLOYMENT

## SAHA SEÇİMİ: yerleştirme sırasını kazanan oyuncu (active_deployer_id, roll-off) haritada bir
## bölgeye tıklayarak "Zone A"yı (ScenarioData.p1_deploy_zone) kendine seçer; rakip otomatik
## "Zone B"yi (p2_deploy_zone) alır. 0 = henüz seçilmedi (o ana kadar hiçbir yerleştirme kabul
## edilmez — bkz. DeployValidator.REASON_NO_SIDE). scenario_logic.gd::is_valid_deploy_position
## artık sabit "player_id==1" yerine bunu okur.
var zone_a_owner_id: int = 0
signal deploy_side_chosen(zone_a_owner: int)

## Oyuncuların seçtiği faksiyonlar (1: Host/Mavi, 2: Client/Kırmızı)
var player_factions: Dictionary = {
	1: null,
	2: null
}

## Her oyuncunun warband bütçesi (Cost toplamı bu değeri aşamaz).
## Compendium (warbands/starting-a-warband.md): "Usually you will have 700 Ducats to spend."
@export var points_budget: int = 700

## Glory Point bütçesi. Compendium (recruit-your-warband.md): "Generally, Warbands don't have
## access to when they are first created" (kampanya varsayımı). Oyunda kampanya olmadığından
## değer senaryodan gelir (ScenarioData.glory_budget, her senaryoda 10 — mercenary erişimi).
@export var glory_budget: int = 0

## Bir oyuncunun toplam bütçesi 0 olsa bile (ör. tüm unit'ler cost=0) sonsuz yerleşimi
## engelleyen güvenlik sınırı — compendium'daki tipik warband büyüklüğü (6-20 model).
@export var max_units_per_player: int = 20

## Oyuncuların kalan yerleşim PUANI (unit sayısı değil — Cost bazlı).
var player_deploy_pool = {
	1: points_budget,
	2: points_budget
}

## Oyuncuların kalan GLORY POINT havuzu — mercenary'ler yalnız buradan alınır (EconomyRules).
## Ducat havuzuyla BİRBİRİNİN YERİNE GEÇMEZ (compendium: "Mercenaries cannot be purchased with ").
var player_glory_pool = { 1: glory_budget, 2: glory_budget }

## Oyuncuların konuşlandırmayı manuel olarak bitirip bitirmediği bilgisi.
var player_deployment_finished = { 1: false, 2: false }
## Sızıcı yerleştirmek için normal modellerini bitirmiş oyuncular — kural: InfiltrationOrder.
var infiltration_ready = { 1: false, 2: false }

## Oyuncuların şimdiye kadar yerleştirdiği unit sayısı (max_units_per_player kontrolü + isim üretimi için).
var player_deployed_count = { 1: 0, 2: 0 }

## Şu an yerleştirme yapan oyuncunun ID'si (Çevrimdışı/yerel modda sıra takibi için)
var active_deployer_id: int = 1:
	set(val):
		if active_deployer_id != val:
			active_deployer_id = val
			active_deployer_changed.emit(val)

## Yerleşim aşamasında seçili olan piyon türü (resource path)
var selected_deploy_unit_type: String = ""

## FAZ 5 (P1-1): seçili piyon türü birden fazla Battlekit/loadout seçeneği taşıyorsa, oyuncunun
## seçtiği index (-1 = seçilmedi/yok). map_input.gd request_deploy_unit'e bunu da geçirir.
var selected_loadout_index: int = -1

var is_game_active: bool = false
var selected_unit = null
## Seçili eylem ("move"/"charge"/"retreat"/"attack"/yetenek/""). Değiştiğinde tüm birim
## göstergeleri tazelenir — böylece hareket/menzil alanı ve hedef vurgusu anında güncellenir.
var selected_action: String = "":
	set(val):
		if selected_action != val:
			selected_action = val
			update_all_unit_indicators()


## Sahnedeki aktif tüm birimlerin listesi
## Key: String (birim adı), Value: Birim düğümü (Node3D)
var units = {}

func register_unit(unit):
	units[unit.name] = unit
	GameLogger.log_info("Birim sisteme kaydedildi: %s (Sahibi: Oyuncu %d)" % [unit.name, unit.owner_id], "SYSTEM")

func unregister_unit(unit):
	if units.has(unit.name):
		units.erase(unit.name)
		GameLogger.log_info("Birim sistemden silindi: %s" % unit.name, "SYSTEM")
		if TurnManager.forced_next_activator == unit.name:
			TurnManager.forced_next_activator = ""
			if multiplayer.has_multiplayer_peer():
				TurnManager.rpc("sync_forced_activator", "")
		check_game_over_conditions()

func check_game_over_conditions():
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
		
	if game_phase != GamePhase.BATTLE or not is_game_active:
		return
		
	var p1_units = 0
	var p2_units = 0
	
	for u_name in units:
		var u = units[u_name]
		if is_instance_valid(u) and u.current_health > 0:
			if u.owner_id == 1:
				p1_units += 1
			elif u.owner_id == 2:
				p2_units += 1
				
	GameLogger.log_info("Oyun bitiş koşulları denetleniyor... Kalan birimler: %s" % str(units.keys()), "SYSTEM")
	GameLogger.log_info("Aktif birim sayıları -> Oyuncu 1: %d, Oyuncu 2: %d" % [p1_units, p2_units], "SYSTEM")
				
	if p1_units == 0 and p2_units > 0:
		RpcHelper.sync(self, "sync_game_over", [2])
	elif p2_units == 0 and p1_units > 0:
		RpcHelper.sync(self, "sync_game_over", [1])
	elif p1_units == 0 and p2_units == 0:
		RpcHelper.sync(self, "sync_game_over", [0])


## Senaryo bütçesini uygular — senaryo seçildiğinde çağrılır (sunucu otoritesi + senkron).
func apply_scenario_budget(budget: int, glory: int = 0):
	points_budget = budget
	glory_budget = glory
	player_deploy_pool = { 1: budget, 2: budget }
	player_glory_pool = { 1: glory, 2: glory }

func clear_state():
	units.clear()
	deselect_unit()
	is_game_active = false
	game_phase = GamePhase.SCENARIO_SELECT
	ScenarioManager.clear()
	player_factions = { 1: null, 2: null }
	player_deploy_pool = { 1: points_budget, 2: points_budget }
	player_glory_pool = { 1: glory_budget, 2: glory_budget }
	player_deployed_count = { 1: 0, 2: 0 }
	player_deployment_finished = { 1: false, 2: false }
	infiltration_ready = { 1: false, 2: false }
	active_deployer_id = 1
	selected_deploy_unit_type = ""
	zone_a_owner_id = 0
	# KÖK NEDEN DÜZELTMESİ: `ArmouryManager.reset()` HİÇBİR YERDEN çağrılmıyordu → `finished`
	# oyunlar arasında yaşıyor, ikinci oyunda "Alışverişi Bitir" ilk basışta erken dönüp
	# ekranı kilitliyordu (bkz. armoury_manager.gd::finish_player).
	ArmouryManager.reset()
	
	# Model önbelleği burada TEMİZLENMEZ: clear_state savaş sahnesi AÇILIRKEN çağrılır ve
	# LoadingManager'ın az önce ön-yüklediği modelleri siliyordu. Bkz. game.gd::_exit_tree.

	# Zarları temizle
	DiceManager.clear_dice()

func select_unit(unit):
	# Hold Your Fire / Fireteam zorunlu aktivasyonu ve aktivasyon taahhüdü (ActivationRules).
	if is_instance_valid(unit) and unit.owner_id == TurnManager.current_turn_player_id and not unit.has_moved:
		var block := ActivationRules.selection_block_reason(units, unit, TurnManager.forced_next_activator)
		if block != "":
			GameEvents.notice_posted.emit(block, "warn", "")
			return
		TurnManager.link_joint_if_needed(unit)
	if selected_unit != null:
		deselect_unit()
	selected_unit = unit
	if is_instance_valid(unit):
		unit.set_selected(true)
		unit_selected.emit(unit)
	update_all_unit_indicators()

func deselect_unit():
	if selected_unit != null:
		if is_instance_valid(selected_unit):
			selected_unit.set_selected(false)
		selected_unit = null
		unit_deselected.emit()
	update_all_unit_indicators()

func update_all_unit_indicators():
	for unit_name in units:
		var u = units[unit_name]
		if is_instance_valid(u) and u.has_method("update_indicators"):
			u.update_indicators()

# ── REAKTİF HARİTA-SEÇİM MODU (P1-1 Time Slip'in yeniden konuşlanma noktası, Temporal Assassin'in
# 2. hedef seçimi gibi async-yetenek-ortası oyuncu girdisi gerektiren mekanikler için ORTAK altyapı) ─
## "" | "position" | "enemy_unit". map_input.gd bir sonraki harita tıklamasını bu moda yönlendirir;
## CombatChoice RPC ile senkronlar — yerel oyuncu SADECE kendi biriminin isteği için bu moda girer.
var pick_mode: String = ""
var pick_unit = null          ## isteğin SAHİBİ birim (menzil halkası bunun etrafında gösterilir)
var pick_radius: float = 0.0  ## yalnız "position" modunda anlamlı
var pick_candidates: Array = []  ## "enemy_unit": tıklanabilir hedefler (boş = her canlı düşman)
var _pick_callback: Callable = Callable()

## GOETIC SPELL Blood Marker ödemesi (P1-1) — "blood_drain" pick modu yalnız bunlar için anlamlı.
## Hiçbir gerçek blood_markers değeri TIKLAMA ANINDA değişmez (marker-spend'in "harcanmaz, olduğu
## yerde kalır" iptal felsefesiyle tutarlı) — yalnız needed'e ulaşınca resolve_pick(sources) ile
## AbilityExecutor.pay_goetic_cost tek seferde gerçek düşüşü uygular.
var pick_blood_drain_needed: int = 0
var pick_blood_drain_collected: int = 0
var pick_blood_drain_sources: Dictionary = {}  ## unit_name(String) -> alınan marker sayısı

signal pick_mode_started(kind: String, hint_key: String)
signal pick_mode_ended()
signal blood_drain_progress(collected: int, needed: int)

func start_position_pick(unit, radius: float, hint_key: String, callback: Callable) -> void:
	# GÜVENLİK (marker_spend_overlay/_present ile aynı desen): kartı dinleyen kimse yoksa
	# (interaction_hint_card henüz sahneye eklenmediyse — örn. game_hud._ready() tamamlanmadan
	# bu çağrılırsa) await asla kilitlenmesin diye anında iptal (null) ile döner.
	if not pick_mode_started.has_connections():
		# call_deferred: _ask/_present'teki AYNI sebep — çağıran taraf henüz `await _pick_response`
		# satırına ulaşmadı, senkron emit sinyali kaçırır (kilitlenme). Deferred, await'ten sonraya bırakır.
		callback.call_deferred(null)
		return
	pick_mode = "position"
	pick_unit = unit
	pick_radius = radius
	_pick_callback = callback
	pick_mode_started.emit("position", hint_key)

func start_enemy_unit_pick(unit, hint_key: String, callback: Callable, candidates: Array = []) -> void:
	if not pick_mode_started.has_connections():
		callback.call_deferred(null)  # (yukarıdaki ile aynı sebep)
		return
	pick_mode = "enemy_unit"
	pick_unit = unit
	pick_candidates = candidates
	_pick_callback = callback
	pick_mode_started.emit("enemy_unit", hint_key)

## GOETIC SPELL ödemesi (P1-1): caster'ın maliyeti karşılayana kadar haritada dost/düşman
## (Demonic/Black Grail HARİÇ) modellere tıklayarak Blood Marker toplaması. cost<=0 ise anında
## boş sözlükle biter (ödenecek bir şey yok).
func start_blood_drain_pick(caster, cost: int, hint_key: String, callback: Callable) -> void:
	if cost <= 0:
		callback.call_deferred({})
		return
	if not pick_mode_started.has_connections():
		callback.call_deferred(null)
		return
	pick_mode = "blood_drain"
	pick_unit = caster
	pick_blood_drain_needed = cost
	pick_blood_drain_collected = 0
	pick_blood_drain_sources = {}
	_pick_callback = callback
	pick_mode_started.emit("blood_drain", hint_key)

## map_input.gd, blood_drain modundayken bir Unit'e tıklandığında çağırır. Geçersiz/uygunsuz
## tıklamalar sessizce yok sayılır (oyuncu başka bir model dener) — akış bozulmaz.
func resolve_blood_drain_click(clicked_unit) -> void:
	if pick_mode != "blood_drain" or not is_instance_valid(clicked_unit):
		return
	if clicked_unit.blood_markers <= 0:
		return
	if clicked_unit.unit_data != null and not MechanicsResolver.is_goetic_blood_source(clicked_unit.unit_data):
		return
	var already: int = pick_blood_drain_sources.get(clicked_unit.name, 0)
	if already >= clicked_unit.blood_markers:
		return
	pick_blood_drain_sources[clicked_unit.name] = already + 1
	pick_blood_drain_collected += 1
	blood_drain_progress.emit(pick_blood_drain_collected, pick_blood_drain_needed)
	if pick_blood_drain_collected >= pick_blood_drain_needed:
		resolve_pick(pick_blood_drain_sources.duplicate())

## map_input.gd bir seçim yapınca çağırır (Vector3 veya unit Node).
func resolve_pick(value) -> void:
	var cb: Callable = _pick_callback
	_end_pick()
	if cb.is_valid():
		cb.call(value)

## Oyuncu iptal ederse (Cancel butonu/Esc) — callback'e null gönderilir (harcanmaz, olduğu yerde kalır).
func cancel_pick() -> void:
	var cb: Callable = _pick_callback
	_end_pick()
	if cb.is_valid():
		cb.call(null)

func _end_pick() -> void:
	pick_mode = ""
	pick_unit = null
	pick_candidates = []
	_pick_callback = Callable()
	pick_blood_drain_needed = 0
	pick_blood_drain_collected = 0
	pick_blood_drain_sources = {}
	pick_mode_ended.emit()

## Belirtilen oyuncu için faksiyon seçer.
## Kullanıcı bildirimi: "sıralı faction seçiminde sorunlar var, ben Iron Sultanate ve New Antioch
## seçiyorum ama Heretic gibi otomatik atama durumları oluyor." Önceden çevrimdışı (hotseat) modda
## Oyuncu 1 seçer seçmez Oyuncu 2'ye available_factions'taki İLK eşleşmeyen faksiyon OTOMATİK
## atanıyordu — Oyuncu 2'nin kendi seçimi hiç sorulmadan/beklenmeden. Bu proje AI/bot rakip
## içermiyor (her iki taraf da her zaman insan) — bu yüzden otomatik atamanın hiçbir geçerli
## kullanım senaryosu yok, kaldırıldı. game_hud.gd::_update_hud_visibility zaten DEPLOYMENT
## fazında "faction==null ise faction_panel'i göster" akışını GameState.active_deployer_id'ye
## (sırayla yerleştirme mekanizması) göre doğal olarak uyguluyor — Oyuncu 2'nin sırası gelince
## panel otomatik olarak ONA gösterilir, ayrı bir yeni UI adımı GEREKMEDİ.
func select_faction(player_id: int, faction: Resource):
	player_factions[player_id] = faction
	faction_selected.emit(player_id, faction)

## KÖK NEDEN DÜZELTMESİ: game.gd::request_select_faction'ın sunucu-otoriteli, tüm eşlere
## RpcHelper.sync ile yayılan hedefi — select_faction'ın kendisi artık DOĞRUDAN UI'dan çağrılmıyor
## (bkz. game_hud.gd::_on_faction_selected_new), çünkü önceden hiç ağa yayılmıyordu ve sunucu
## istemcinin faksiyonunu asla öğrenemiyordu.
@rpc("authority", "call_local", "reliable")
func sync_player_faction(player_id: int, faction_path: String) -> void:
	var faction: Resource = load(faction_path) if faction_path != "" else null
	select_faction(player_id, faction)

## SAHA SEÇİMİ: game.gd::request_select_side'ın sunucu-otoriteli, tüm eşlere yayılan hedefi.
@rpc("authority", "call_local", "reliable")
func sync_deploy_side(zone_a_owner: int) -> void:
	zone_a_owner_id = zone_a_owner
	deploy_side_chosen.emit(zone_a_owner)

## Belirtilen oyuncunun seçtiği faksiyonu döndürür.
func get_faction_for_player(player_id: int) -> Resource:
	return player_factions.get(player_id, null)

## Faksiyon kimliğine göre FactionData kaynağını bulur ve döndürür.
## Önce canonical faction_id eşleşmesine bakar; bulunamazsa FactionData.aliases'a düşer
## (ör. &"heretic" → heretic_legion, &"anointed" → iron_sultanate). Böylece eski/kısa
## kimliklerin "normalizasyonu" TEK YERDE (veri-odaklı) yapılır; UI'da dağınık if/elif kalmaz.
func get_faction_by_id(faction_id: StringName) -> Resource:
	for f in available_factions:
		if f.faction_id == faction_id:
			return f
	for f in available_factions:
		if "aliases" in f and faction_id in f.aliases:
			return f
	return null

## Bir oyuncunun daha fazla unit yerleştirip yerleştiremeyeceğini kontrol eder
## (hem puan bütçesi hem de max_units_per_player güvenlik sınırı — cost=0 unit'lerde
## bütçe hiç tükenmeyebileceği için sonsuz yerleşimi bu sınır engeller).
## G4.2: Bu birim tipinden (unit_name) oyuncunun sahada kaç adedi olduğunu sayar.
func deployed_count_of_type(player_id: int, type_name: String) -> int:
	var c := 0
	for u_name in units:
		var u = units[u_name]
		if is_instance_valid(u) and u.owner_id == player_id and u.unit_data != null and u.unit_data.unit_name == type_name:
			c += 1
	return c

## G4.2: Availability limiti — bu tipten bir tane daha yerleştirilebilir mi? (compendium)
func can_deploy_unit_type(player_id: int, ud: Resource) -> bool:
	if ud == null:
		return true
	var maxv: int = ud.availability_max if "availability_max" in ud else 999
	return deployed_count_of_type(player_id, ud.unit_name) < maxv

## FAZ 5 (P1-1): bu unit tipinde, verilen loadout_index'in ait olduğu grubu (limit_group varsa
## grup, yoksa yalnız aynı index) zaten kaç kez seçilmiş?
func deployed_count_of_loadout_group(player_id: int, type_name: String, group: StringName, exact_index: int) -> int:
	var c := 0
	for u_name in units:
		var u = units[u_name]
		if not is_instance_valid(u) or u.owner_id != player_id or u.unit_data == null:
			continue
		if u.unit_data.unit_name != type_name:
			continue
		var idx: int = u.chosen_loadout_index if "chosen_loadout_index" in u else -1
		if idx < 0 or idx >= u.unit_data.loadout_options.size():
			continue
		var opt = u.unit_data.loadout_options[idx]
		if opt == null:
			continue
		if group != &"":
			if opt.limit_group == group:
				c += 1
		elif idx == exact_index:
			c += 1
	return c

## FAZ 5 (P1-1): seçilen loadout, warband-genelinde limitini (LoadoutOption.max_per_warband) aştı mı?
func can_deploy_loadout(player_id: int, ud: Resource, loadout_index: int) -> bool:
	if ud == null or ud.loadout_options == null or loadout_index < 0 \
			or loadout_index >= ud.loadout_options.size():
		return true
	var opt = ud.loadout_options[loadout_index]
	if opt == null:
		return true
	var count := deployed_count_of_loadout_group(player_id, ud.unit_name, opt.limit_group, loadout_index)
	return count < opt.max_per_warband

## SAF bütçe/limit kontrolü — SIRA farkı gözetmez (bkz. can_player_deploy_more). Bir oyuncunun
## kendi bütçesi/limitine göre HİÇ yerleştirme hakkı kalmamışsa (sıradan bağımsız) false döner —
## alternating-deployment mantığının "rakip tükendiyse serbest devam et" istisnası bunu kullanır.
func _has_deploy_budget(player_id: int) -> bool:
	if player_deployment_finished.get(player_id, false):
		return false

	if player_deployed_count.get(player_id, 0) >= max_units_per_player:
		return false

	# İKİ HAVUZ birden gözetilir (EconomyRules): ducat'ı biten bir oyuncu, Glory havuzu da
	# boşsa gerçekten tükenmiştir. Tek havuzlu eski mantık, 2 Glory'lik bir mercenary yüzünden
	# oyuncuyu "hâlâ yerleştirebilir" sayıp yerleştirme fazını hiç bitirmiyordu.
	var ducat: int = player_deploy_pool.get(player_id, 0)
	var glory: int = player_glory_pool.get(player_id, 0)
	if ducat <= 0 and glory <= 0:
		return false

	var faction = get_faction_for_player(player_id)
	if faction != null and faction.available_units.size() > 0:
		if not EconomyRules.can_afford_any(faction, ducat, glory):
			return false

	return true

## SIRALI YERLEŞTİRME (compendium, TÜM senaryolar: "The players then alternate deploying their
## models one at a time... If a player runs out of models to set up, the other player sets up
## all their remaining models, one after another, until they have none left."). Bir oyuncu
## bütçe/limit bakımından yerleştirebilir DURUMDA olsa bile, sıra kendisinde DEĞİLSE ve rakip
## HÂLÂ yerleştirebiliyorsa beklemesi gerekir — deploy_panel.gd bu false'u zaten
## "WAITING_OTHER_SQUAD" ekranına çeviriyor (P1-8'den beri var olan UI, yeni kod gerekmedi).
func can_player_deploy_more(player_id: int) -> bool:
	if not _has_deploy_budget(player_id):
		return false
	var opponent_id: int = 2 if player_id == 1 else 1
	if active_deployer_id != player_id and _has_deploy_budget(opponent_id):
		return false
	return true

## Birimi sahaya yerleştirir ve tüm birimler konuşlandıysa savaş aşamasına geçer.
## cost: yerleştirilen unit'in UnitData.cost'u — bütçeden düşülür.
## unit_data: ödemenin HANGİ havuzdan yapılacağını belirler (EconomyRules). Geriye dönük
## uyum için null geçilebilir — o durumda eski davranış (ducat) uygulanır.
func deploy_unit(player_id: int, unit_node: Node3D, cost: int = 0, unit_data: Resource = null):
	if unit_data != null and EconomyRules.is_glory(unit_data):
		player_glory_pool[player_id] = max(0, player_glory_pool.get(player_id, 0) - cost)
	else:
		player_deploy_pool[player_id] = max(0, player_deploy_pool[player_id] - cost)
	player_deployed_count[player_id] = player_deployed_count.get(player_id, 0) + 1

	# Bütçe/limit bakımından GERÇEKTEN yerleştirme hakkı kalmadıysa (sıradan bağımsız) otomatik bitir.
	if not _has_deploy_budget(player_id):
		player_deployment_finished[player_id] = true
		if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
			rpc("sync_player_deployment_finished", player_id, true)

	# SIRALI YERLEŞTİRME (compendium, TÜM senaryolar): sırayı rakibe geçir — rakip hâlâ
	# yerleştirebiliyorsa. Rakip tükendiyse (_has_deploy_budget false) sıra bu oyuncuda KALIR,
	# "bir oyuncu tükenirse diğeri kalanları art arda yerleştirir" kuralı doğal olarak sağlanır.
	var opponent_id: int = 2 if player_id == 1 else 1
	if _has_deploy_budget(opponent_id) and not InfiltrationOrder.is_waiting(opponent_id):
		active_deployer_id = opponent_id

	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("sync_deployment_state", player_deploy_pool, player_deployed_count, active_deployer_id, player_glory_pool)

	unit_deployed.emit(player_id, unit_node)

	# Tüm oyuncuların piyon yerleşimi bitti mi kontrol et (SAF bütçe kontrolü — sıradan bağımsız,
	# aksi halde "sırası gelmeyen oyuncu" yanlışlıkla "bitti" sayılıp faz erken kapanırdı).
	var all_deployed = true
	for pid in player_deploy_pool:
		if _has_deploy_budget(pid):
			all_deployed = false
			break

	if all_deployed:
		RpcHelper.sync(self, "sync_game_phase", [GamePhase.ARMOURY])

func finish_player_deployment(player_id: int):
	if player_deployment_finished.get(player_id, false):
		return

	player_deployment_finished[player_id] = true
	GameLogger.log_info("Oyuncu %d konuşlandırmayı manuel olarak bitirdi." % player_id, "GAME")

	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("sync_player_deployment_finished", player_id, true)

	# SIRALI YERLEŞTİRME: bu oyuncu manuel bitirdiyse sırayı rakibe geçir (hâlâ yerleştirebiliyorsa).
	var opponent_id: int = 2 if player_id == 1 else 1
	if _has_deploy_budget(opponent_id):
		active_deployer_id = opponent_id
		if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
			rpc("sync_deployment_state", player_deploy_pool, player_deployed_count, active_deployer_id)

	# Tüm oyuncuların piyon yerleşimi bitti mi kontrol et
	var all_deployed = true
	for pid in player_deploy_pool:
		if _has_deploy_budget(pid):
			all_deployed = false
			break

	if all_deployed:
		RpcHelper.sync(self, "sync_game_phase", [GamePhase.ARMOURY])

@rpc("authority", "call_local", "reliable")
func sync_infiltration_ready(p_ready: Dictionary, p_active: int):
	for k in p_ready:
		infiltration_ready[int(k)] = bool(p_ready[k])
	active_deployer_id = p_active

@rpc("authority", "call_local", "reliable")
func sync_player_deployment_finished(player_id: int, finished: bool):
	player_deployment_finished[player_id] = finished

@rpc("authority", "call_local", "reliable")
func sync_deployment_state(pool_data: Dictionary, count_data: Dictionary, p_active_deployer_id: int = 0, glory_data: Dictionary = {}):
	for k in pool_data:
		player_deploy_pool[int(k)] = int(pool_data[k])
	for k in glory_data:
		player_glory_pool[int(k)] = int(glory_data[k])
	for k in count_data:
		player_deployed_count[int(k)] = int(count_data[k])
	# 0 = "değişmedi" (geriye dönük uyumlu varsayılan) — yalnız gerçek bir sıra değeri (1/2) geldiğinde uygula.
	if p_active_deployer_id != 0:
		active_deployer_id = p_active_deployer_id

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# Oyun kapanırken tüm statik önbellekleri ve preloaded kaynakları temizle
		# Bu sayede GPU/RID kaynakları RenderingServer kapanmadan önce serbest bırakılır.
		UIPreviewHelper.model_cache.clear()
		UnitVisuals._material_cache.clear()
		UnitVisuals._flash_material_cache.clear()
		available_factions.clear()

@rpc("authority", "call_local", "reliable")
func sync_game_phase(phase_idx: int):
	game_phase = phase_idx as GamePhase
	game_phase_changed.emit(phase_idx)
	if game_phase == GamePhase.BATTLE:
		deployment_completed.emit()

@rpc("authority", "call_local", "reliable")
func sync_game_over(winner_id: int):
	is_game_active = false
	GameEvents.game_over.emit(winner_id)
