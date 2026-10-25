extends SceneTree

## KAYIT/YÜKLEME UÇTAN UCA TESTİ — `godot --headless --path . -s res://tests/save_load_e2e.gd`
##
## NEDEN AYRI: kayıt/yükleme yalnız GERÇEK oyun sahnesiyle (navmesh pişirme → restore_game_state)
## doğrulanabilir; ana süit senkron çalıştığı için bunu yapamaz.
##
## Akış: savaşın ortasına kadar oyna (loadout'lu birim, zırhane eşyası, kurulmuş mayın, işaretler,
## aktive edilmiş birim, VP, tur) → kaydet → sahneyi ve autoload durumunu sıfırla → kaydı yükle →
## her şeyin AYNEN döndüğünü denetle. Test AYRI bir kayıt dosyası kullanır — oyuncunun gerçek
## kaydına (test yarıda çökse bile) asla dokunulmaz.
##
## Çıkış kodu 0 = geçti.

const GAME_SCENE := "res://scenes/game/game.tscn"
const MINE := "res://assets/data/terrain/mine.tres"

var _gs: Node
var _tm: Node
var _game: Node
var _fails: Array[String] = []

func _initialize() -> void:
	_run()

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _check(cond: bool, msg: String) -> void:
	if not cond:
		_fails.append(msg)

func _run() -> void:
	_gs = root.get_node("GameState")
	_tm = root.get_node("TurnManager")
	var save_mgr: Node = root.get_node("SaveManager")
	var real_path: String = save_mgr.save_path
	save_mgr.save_path = "user://save_load_e2e_test.json"

	await _frames(2)
	root.multiplayer.multiplayer_peer = null
	await _boot_game()
	_game.request_select_scenario("claim_no_mans_land")
	await _frames(5)
	var first: int = _gs.active_deployer_id
	_game.request_select_faction(&"new_antioch")
	_gs.select_faction(2 if first == 1 else 1, _gs.get_faction_by_id(&"iron_sultanate"))
	if first != 1:
		# select_faction sırası oyuncu numarasından bağımsız; faksiyonları sabitle
		_gs.player_factions[1] = _gs.get_faction_by_id(&"new_antioch")
		_gs.player_factions[2] = _gs.get_faction_by_id(&"iron_sultanate")
	await _deploy_fixture()
	_gs.finish_player_deployment(1)
	_gs.finish_player_deployment(2)
	await _frames(10)

	# Zırhane: bir birime saldırı veren bir eşya (ödeme/limit denetimi test dışı)
	var am: Node = root.get_node("ArmouryManager")
	var buyer: Node = _unit_with(func(u): return u.owner_id == 1)
	var item: Resource = load("res://assets/data/armoury/bayonet.tres")
	am._apply(1, String(buyer.name), item)
	var buyer_attacks: int = buyer.unit_data.attacks.size()
	var buyer_name := String(buyer.name)
	am.finish_player(1)
	am.finish_player(2)
	await _frames(120)
	_tm.request_initiative_order(true)
	await _frames(60)

	# Savaş ortası durum
	var marked: Node = _unit_with(func(u): return u.owner_id == 2)
	marked.blood_markers = 2
	marked.blessing_markers = 1
	_tm.activated_units.append(String(marked.name))
	_tm.current_round = 2
	_tm.pending_morale_bonus_dice[2] = 1
	var tmgr: Node = root.get_node("TerrainManager")
	var mine_pos: Vector3 = buyer.global_position + Vector3(3, 0, 0)
	tmgr.spawn_feature(load(MINE), mine_pos, String(buyer.name))
	var sm: Node = root.get_node("ScenarioManager")
	sm.logic.player_vp[1] = 3
	_gs.player_glory_pool[1] = 7

	var expected := _snapshot()
	_check(expected.units.size() >= 3, "fixture: en az 3 birim konuşlanmalıydı (%d)" % expected.units.size())
	_check(expected.loadout_units > 0, "fixture: loadout'lu birim yok")
	var dug_in_name: String = expected.get("dug_in_unit", "")

	_check(save_mgr.save_game(), "save_game() başarısız")

	# ── Her şeyi sıfırla: yükleme gerçekten kayıttan kurmalı
	_game.queue_free()
	await _frames(3)
	_gs.clear_state()
	tmgr.clear_all()
	_tm.current_round = 1
	_tm.activated_units = []
	_tm.pending_morale_bonus_dice = {1: 0, 2: 0}
	var cc: Node = root.get_node("CombatChoice")
	var prompts_before: int = cc._next_id

	save_mgr.has_pending_load = true
	save_mgr.saved_role = "local"
	await _boot_game()
	for i in 600:
		await process_frame
		if not save_mgr.has_pending_load:
			break
	await _frames(10)
	_check(not save_mgr.has_pending_load, "restore_game_state hiç tamamlanmadı")

	var got := _snapshot()
	for n in expected.units:
		if not got.units.has(n):
			_check(false, "birim kayboldu: %s" % n)
			continue
		var e: Dictionary = expected.units[n]
		var g: Dictionary = got.units[n]
		if not g.has("pos"):
			_check(false, "%s: %s" % [n, g.owner])
			continue
		for k in e:
			if k == "pos":
				_check((e[k] as Vector3).distance_to(g[k]) < 0.05, "%s konumu: %s ≠ %s" % [n, e[k], g[k]])
			else:
				_check(g.has(k) and str(e[k]) == str(g[k]), "%s.%s: beklenen %s, gelen %s" % [n, k, e[k], g.get(k, g.get("owner"))])
	_check(got.units.size() == expected.units.size(), "birim sayısı %d ≠ %d" % [got.units.size(), expected.units.size()])
	for k in ["round", "activated", "vp", "glory", "morale_bonus", "phase", "turn_phase", "terrain", "armoury"]:
		_check(str(expected[k]) == str(got[k]), "%s: beklenen %s, gelen %s" % [k, expected[k], got[k]])
	var restored_buyer: Node = _gs.units.get(buyer_name)
	_check(restored_buyer != null and restored_buyer.unit_data != null and restored_buyer.unit_data.attacks.size() == buyer_attacks,
		"zırhane eşyasının verdiği saldırı yüklemede kayboldu")
	_check(cc._next_id == prompts_before, "yükleme 'ilk konuşlanma' seçimini (Mastery) yeniden sordu")
	if dug_in_name != "":
		_check(got.units[dug_in_name].fortify == expected.units[dug_in_name].fortify, "Dug In yüklemede yeniden uygulandı")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_mgr.save_path))
	save_mgr.save_path = real_path

	if _fails.is_empty():
		print("\n==== KAYIT/YÜKLEME E2E: GEÇTİ (%d birim) ====" % expected.units.size())
		quit(0)
	else:
		print("\n==== KAYIT/YÜKLEME E2E: %d SORUN ====" % _fails.size())
		for f in _fails:
			print("   ✗ " + f)
		quit(1)

func _boot_game() -> void:
	_game = load(GAME_SCENE).instantiate()
	root.add_child(_game)
	current_scene = _game
	for i in 900:
		await process_frame
		if i > 60 and (_gs.game_phase == _gs.GamePhase.SCENARIO_SELECT or not root.get_node("SaveManager").has_pending_load):
			break

## Her iki taraftan sırayla birim koyar. P1'in ilk birimi loadout seçeneği olan bir birim,
## sonra Dug In (Combat Engineer); P2'de Mastery of the Elements (Alchemist) varsa o da konur.
func _deploy_fixture() -> void:
	var sc = root.get_node("ScenarioManager").active_scenario
	var picks := {1: _picks_for(1), 2: _picks_for(2)}
	var idx := {1: 0, 2: 0}
	for step in 6:
		var pid: int = _gs.active_deployer_id
		var list: Array = picks[pid]
		if idx[pid] >= list.size():
			break
		var p: Array = list[idx[pid]]
		var zone: Rect2 = sc.p1_deploy_zone if pid == 1 else sc.p2_deploy_zone
		if _gs.zone_a_owner_id != 0 and _gs.zone_a_owner_id != 1:
			zone = sc.p2_deploy_zone if pid == 1 else sc.p1_deploy_zone
		var c := zone.get_center()
		_game.request_deploy_unit(p[0], Vector3(c.x, 0.0, c.y + (idx[pid] - 1) * 2.5), p[1])
		idx[pid] += 1
		await _frames(10)

func _picks_for(pid: int) -> Array:
	var faction = _gs.player_factions[pid]
	var out: Array = []
	var loadout_done := false
	for ud in faction.available_units:
		if not loadout_done and ud.loadout_options != null and ud.loadout_options.size() > 0 and ud.cost <= 150:
			out.append([ud.resource_path, 0])
			loadout_done = true
	for ud in faction.available_units:
		var kws: Dictionary = ud.keywords
		if kws.has(&"dug_in") or kws.has(&"mastery_of_elements"):
			out.append([ud.resource_path, -1])
	for ud in faction.available_units:
		if out.size() >= 3:
			break
		if ud.cost <= 60:
			out.append([ud.resource_path, -1])
	return out

func _unit_with(pred: Callable) -> Node:
	for n in _game.get_node("Units").get_children():
		if n.get("owner_id") != null and pred.call(n):
			return n
	return null

func _snapshot() -> Dictionary:
	var units := {}
	var loadout_units := 0
	var dug_in_unit := ""
	for u in _game.get_node("Units").get_children():
		if u.get("owner_id") == null or u.is_queued_for_deletion():
			continue
		if u.unit_data == null:
			units[String(u.name)] = {"owner": "BOZUK: unit_data yok"}
			continue
		units[String(u.name)] = {
			"owner": u.owner_id, "loadout": u.chosen_loadout_index,
			"attacks": u.unit_data.attacks.size(), "armour": u.armour,
			"blood": u.blood_markers, "blessing": u.blessing_markers,
			"element": String(u.current_element), "fortify": u.has_fortify_cover,
			"tough": bool(u.unit_data.has_tough), "pos": u.global_position,
		}
		if u.chosen_loadout_index >= 0:
			loadout_units += 1
		if u.unit_data.keywords.has(&"dug_in"):
			dug_in_unit = String(u.name)
	var terrain: Array = []
	for f in root.get_node("TerrainManager").features:
		if is_instance_valid(f) and not f.is_queued_for_deletion():
			terrain.append("%s@%s by %s active=%s" % [f.feature_data.feature_id, f.global_position.snapped(Vector3.ONE * 0.1), f.setter_unit_name, f.is_active])
	terrain.sort()
	var am: Node = root.get_node("ArmouryManager")
	return {
		"units": units, "loadout_units": loadout_units, "dug_in_unit": dug_in_unit,
		"round": _tm.current_round, "activated": _tm.activated_units,
		"vp": root.get_node("ScenarioManager").logic.player_vp,
		"glory": _gs.player_glory_pool, "morale_bonus": _tm.pending_morale_bonus_dice,
		"phase": int(_gs.game_phase), "turn_phase": _tm.current_phase,
		"terrain": terrain, "armoury": [am.unit_items, am.warband_items],
	}
