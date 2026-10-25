extends Node

## Senaryo Yöneticisi (Autoload).
## Aktif senaryoyu (ScenarioData) ve davranışını (ScenarioLogic) tutar, ağ üzerinde senkronize
## eder ve deployment/tur-sonu/zafer kararlarını ilgili ScenarioLogic'e delege eder.
## Sunucu otoritesi: VP puanlaması yalnız sunucuda hesaplanır, istemcilere senkronlanır.

signal scenario_changed(scenario_data)
signal vp_updated(player_vp)
signal round_wins_updated(player_round_wins)

const SCENARIO_DIR := "res://assets/data/scenarios/"

## Kullanılabilir senaryolar. P1-8: klasör otomatik taranır — yeni senaryo eklemek için
## SADECE assets/data/scenarios/ altına yeni bir ScenarioData .tres koymak yeterli, script
## değişikliği GEREKMEZ (önceki hardcoded dizi bu iddiayı karşılamıyordu, düzeltildi).
var available_scenarios: Array = []

var active_scenario: ScenarioData = null
var logic: ScenarioLogic = null

## UI için VP aynası (sunucudan senkronlanır). { player_id -> vp }
var player_vp: Dictionary = {1: 0, 2: 0}

## UI için round-kazanma aynası (sunucudan senkronlanır). { player_id -> kazanılan round sayısı }
var player_round_wins: Dictionary = {1: 0, 2: 0}

func _ready() -> void:
	_scan_available_scenarios()

func _scan_available_scenarios() -> void:
	available_scenarios.clear()
	var dir := DirAccess.open(SCENARIO_DIR)
	if dir == null:
		GameLogger.log_error("[Scenario] Senaryo klasörü açılamadı: " + SCENARIO_DIR, "SCENARIO")
		return
	var files := dir.get_files()
	files.sort()
	for file in files:
		# Export edilmiş build'lerde DirAccess.get_files() dosyaları ".remap" sonekiyle
		# döndürür (ör. "foo.tres" -> "foo.tres.remap"); editörde/debug run'da sonek yoktur.
		# İkisini de kapsamak için önce soneği soyup öyle kontrol ediyoruz.
		var base_name := file
		if base_name.ends_with(".remap"):
			base_name = base_name.substr(0, base_name.length() - ".remap".length())
		if not base_name.ends_with(".tres"):
			continue
		var res = load(SCENARIO_DIR + base_name)
		if res is ScenarioData:
			available_scenarios.append(res)
		else:
			GameLogger.log_warn("[Scenario] ScenarioData değil, atlandı: " + file, "SCENARIO")
	GameLogger.log_info("[Scenario] %d senaryo yüklendi." % available_scenarios.size(), "SCENARIO")

func _is_authority() -> bool:
	return not multiplayer.has_multiplayer_peer() or multiplayer.is_server()

func get_scenario_by_id(id: StringName) -> ScenarioData:
	for s in available_scenarios:
		if s != null and s.scenario_id == id:
			return s
	return null

## Host/çevrimdışı oyuncu tarafından çağrılır — seçilen senaryoyu tüm eşlere yayar.
func select_scenario(scenario_id: StringName) -> void:
	if not _is_authority():
		return
	RpcHelper.sync(self, "sync_scenario", [String(scenario_id)])

@rpc("authority", "call_local", "reliable")
func sync_scenario(scenario_id: String) -> void:
	active_scenario = get_scenario_by_id(StringName(scenario_id))
	if active_scenario == null and available_scenarios.size() > 0:
		active_scenario = available_scenarios[0]
	logic = _build_logic(active_scenario)
	player_vp = {1: 0, 2: 0}
	player_round_wins = {1: 0, 2: 0}
	GameLogger.log_info("[Scenario] Aktif senaryo: %s" % (active_scenario.scenario_id if active_scenario else "YOK"), "SCENARIO")
	scenario_changed.emit(active_scenario)

## KAYIT/YÜKLEME + RECONNECT: bir kayıt yüklendikten SONRA bağlanan (reconnect) istemciye senaryo +
## VP/round-win/deed/objective/senaryo-özel durumu yakalar. sync_scenario'nun AKSİNE call_local
## YOK — sunucu bu RPC'yi yalnız reconnect eden istemciye rpc_id ile gönderir; call_local olsaydı
## sunucunun kendi zaten-doğru `logic`'ini SIFIRLARDI (bkz. save_manager.gd::_sync_restored_state_to_client).
@rpc("authority", "reliable")
func client_catch_up_scenario(scenario_id: String, logic_state: Dictionary) -> void:
	active_scenario = get_scenario_by_id(StringName(scenario_id))
	logic = _build_logic(active_scenario)
	if logic != null:
		logic.load_state(logic_state)
		player_vp = logic.player_vp.duplicate()
		player_round_wins = logic.player_round_wins.duplicate()
	scenario_changed.emit(active_scenario)
	vp_updated.emit(player_vp)
	round_wins_updated.emit(player_round_wins)

func _build_logic(sdata: ScenarioData) -> ScenarioLogic:
	if sdata == null:
		return null
	var l: ScenarioLogic
	if sdata.logic_script != null:
		l = sdata.logic_script.new()
	else:
		l = ScenarioLogic.new()
	l.setup(sdata)
	return l

# ── DELEGASYON ───────────────────────────────────────────────────────────────

func is_valid_deploy_position(player_id: int, pos: Vector3) -> bool:
	if logic == null:
		return true
	return logic.is_valid_deploy_position(player_id, pos)

## Tur sonu (Morale fazından sonra) — sunucuda VP hesapla ve senkronize et.
func process_turn_end(round_number: int) -> void:
	if not _is_authority() or logic == null:
		return
	logic.on_turn_end(round_number)
	var vp: Dictionary = logic.player_vp.duplicate()
	var round_wins: Dictionary = logic.player_round_wins.duplicate()
	RpcHelper.sync(self, "sync_vp", [vp, round_wins])

@rpc("authority", "call_local", "reliable")
func sync_vp(vp: Dictionary, round_wins: Dictionary = {}) -> void:
	player_vp = vp.duplicate()
	if logic != null:
		logic.player_vp = vp.duplicate()
	vp_updated.emit(player_vp)
	if not round_wins.is_empty():
		player_round_wins = round_wins.duplicate()
		if logic != null:
			logic.player_round_wins = round_wins.duplicate()
		round_wins_updated.emit(player_round_wins)

func is_final_turn_reached(round_number: int) -> bool:
	return logic != null and logic.is_final_turn_reached(round_number)

## Oyun sonu kazananı: { winner, reason, (vp) }.
func evaluate_end_of_game() -> Dictionary:
	if logic == null:
		return {"winner": 0, "reason": "elimination"}
	return logic.evaluate_end_of_game()

func get_objectives_state() -> Array:
	return logic.get_objectives_state() if logic != null else []

func get_turn_limit() -> int:
	return active_scenario.turn_limit if active_scenario != null else 0

func get_points_budget() -> int:
	return active_scenario.points_budget if active_scenario != null else 500

## Senaryonun Glory Point bütçesi. Compendium yeni warband'a Glory vermez (kampanya varsayımı);
## oyunda kampanya yok, bu yüzden her senaryo mercenary'lere erişim için küçük bir bütçe verir.
func get_glory_budget() -> int:
	return active_scenario.glory_budget if active_scenario != null else 0

func uses_vp_victory() -> bool:
	return active_scenario != null and active_scenario.victory_type == ScenarioData.VictoryType.OBJECTIVE_VP

func clear() -> void:
	active_scenario = null
	logic = null
	player_vp = {1: 0, 2: 0}
	player_round_wins = {1: 0, 2: 0}
