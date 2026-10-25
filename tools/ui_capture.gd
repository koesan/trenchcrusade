extends SceneTree

## UI GÖRSEL KONTROL ARACI — oyun akışını otomatik oynatıp her aşamanın ekran görüntüsünü alır.
##
## KULLANIM (pencereli çalışmalı, `--headless` İLE DEĞİL — görüntü GPU'dan okunur):
##   godot --path . -s res://tools/ui_capture.gd -- <çıkış_klasörü> [senaryo] [faksiyon1] [faksiyon2]
## Örnek:
##   godot --path . -s res://tools/ui_capture.gd -- /tmp/shots claim_no_mans_land new_antioch heretic_legion
##
## NEDEN VAR: UI değişikliklerinin "önce/sonra" karşılaştırması için. `tests/ui_layout_check`
## erişilebilirliği ölçer ama "güzel/okunur mu" sorusuna cevap veremez; bu araç ekranı gösterir.
##
## Akış: ana menü → senaryo seçimi → faksiyon → yerleştirme (iki oyuncu sırayla birim koyar) →
## armoury → inisiyatif → birim seçili savaş ekranı → birime yakın kamera → her overlay.
## Yalnız oyunun kendi `request_*` giriş noktalarını çağırır; oyun mantığını taklit etmez.

var _out := ""
var _game: Node
var _gs: Node

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("ui_capture: çıkış klasörü verilmedi")
		quit(1)
		return
	_out = args[0]
	DirAccess.make_dir_recursive_absolute(_out)
	var scenario: String = args[1] if args.size() > 1 else "claim_no_mans_land"
	var f1: String = args[2] if args.size() > 2 else "new_antioch"
	var f2: String = args[3] if args.size() > 3 else "heretic_legion"
	# İsteğe bağlı 5. argüman: pencere boyutu ("1280x720") — küçük ekranda çakışma denetimi için
	if args.size() > 4 and "x" in args[4]:
		var wh := args[4].split("x")
		root.size = Vector2i(int(wh[0]), int(wh[1]))
	_run(scenario, f1, f2)

func _shot(shot_name: String, settle_frames: int = 30) -> void:
	for i in settle_frames:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_out.path_join(shot_name + ".png"))
	print("ui_capture: ", shot_name)

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _run(scenario: String, f1: String, f2: String) -> void:
	_gs = root.get_node("GameState")

	# 1. Ana menü
	var menu: Node = load("res://scenes/ui/main_menu/main_menu.tscn").instantiate()
	root.add_child(menu)
	await _shot("00_main_menu", 90)
	menu._on_settings_pressed()
	await _shot("00_main_menu_settings")
	menu._on_multiplayer_pressed()
	await _shot("00_main_menu_lobby")
	menu.queue_free()
	# Yükleme ekranı (LoadingManager autoload'unun katmanı) — yarı dolu çubukla
	var lm: Node = root.get_node("LoadingManager")
	lm._overlay.visible = true
	lm._overlay.set_progress_value(0.45)
	await _shot("00_loading", 40)
	lm._overlay.visible = false
	await _frames(2)

	# Yerel (aynı makine) oyun: Godot 4'te varsayılan peer OfflineMultiplayerPeer'dır ve
	# has_multiplayer_peer() TRUE döner — ana menünün "yerel oyun" yolu gibi peer'ı kaldır.
	root.multiplayer.multiplayer_peer = null

	_game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(_game)
	current_scene = _game   # gerçek oyundaki change_scene ile aynı: current_scene'e bakan kodlar için
	for i in 900:
		await process_frame
		if i > 120 and _gs.game_phase == _gs.GamePhase.SCENARIO_SELECT:
			break
	await _shot("01_scenario_select")

	_game.request_select_scenario(scenario)
	await _shot("02_faction_select")

	var first: int = _gs.active_deployer_id
	var second: int = 2 if first == 1 else 1
	_game.request_select_faction(StringName(f1))
	await _shot("03_deploy")
	_gs.select_faction(second, _gs.get_faction_by_id(StringName(f2)))

	await _deploy_some(8)
	await _shot("04_deployed")

	_gs.finish_player_deployment(1)
	_gs.finish_player_deployment(2)
	await _shot("05_armoury")

	var am: Node = root.get_node("ArmouryManager")
	am.finish_player(1)
	am.finish_player(2)
	await _frames(240)
	await _shot("06_initiative")

	var tm: Node = root.get_node("TurnManager")
	tm.request_initiative_order(true)
	await _shot("06b_turn_banner", 12)
	await _frames(60)
	var unit := _first_unit_of(tm.current_turn_player_id)
	if unit:
		_gs.select_unit(unit)
	await _shot("07_battle_selected")
	_report_overlaps()
	if unit:
		var enemy: Node3D = _first_unit_of(2 if unit.owner_id == 1 else 1)
		var hudb: Node = _game.get_node_or_null("GameHUD")
		if enemy and hudb and unit.unit_data.attacks.size() > 0:
			unit.selected_attack_index = unit.unit_data.attacks.size() - 1
			_gs.selected_action = "attack"
			hudb.show_shot_breakdown(unit, enemy)
			await _shot("07d_shot_preview", 10)
			hudb.hide_shot_breakdown()
			_gs.selected_action = "move"
			hudb.get_node("%CommandBar").actions.action_selected.emit("move")
			await _shot("07e_move_hint", 10)
			_gs.selected_action = ""
	var hud0: Node = _game.get_node_or_null("GameHUD")
	if hud0:
		hud0._on_objectives_toggle_pressed()
		await _shot("07b_objectives")
		hud0._on_resources_toggle_pressed()
		await _shot("07c_resources")
		hud0._on_resources_toggle_pressed()

	if unit:
		var cam: Node3D = _game.get_node("TacticalCamera")
		cam.global_position = unit.global_position
		cam.set("_target_zoom", 7.0)
	await _shot("08_unit_close", 60)
	if unit:
		# Savaş olayı geri bildirimi (yüzen yazılar + günlük)
		var be = load("res://scripts/rules/battle_events.gd")
		be.hit(unit, unit, "ATTACK_MACHINE_GUN", 9, false)
		await _frames(8)
		be.injury(unit, 2, 1)  # InjuryResolver.Outcome.DOWN
		await _frames(8)
		be.ability(unit, "FORTIFY", true)
		await _shot("08b_feedback", 20)
		be.miss(unit, unit, "ATTACK_MACHINE_GUN", 5)
		be.injury(unit, 4, 0)  # OUT_OF_ACTION
		var hud_l: Node = _game.get_node_or_null("GameHUD")
		if hud_l:
			hud_l._on_log_toggle_pressed()
			await _shot("08c_battle_log", 20)
			hud_l._on_log_toggle_pressed()
	await _check_size_stability()

	var hud: Node = _game.get_node_or_null("GameHUD")
	if hud and hud.get("overlay_manager"):
		var om = hud.overlay_manager
		for key in om.overlays.keys():
			om.open_overlay(key)
			await _shot("ov_" + str(key))
			om.close_current_overlay()
		# Kadrodan birim seçimi → o birimin profili
		var picked_u: Node3D = _first_unit_of(1)
		if picked_u:
			om.open_overlay("roster")
			om.overlays["roster"].unit_picked.emit(picked_u)
			await _shot("ov_profile_from_roster")
			om.close_current_overlay()
	quit()

## Her oyuncu sırayla faksiyon listesindeki birimleri kendi bölgesinin ortasına yakın koyar.
## Reddedilen istek (bütçe, yer, Glory) önemli değil — amaç ekranı doldurmak.
func _deploy_some(steps: int) -> void:
	var sc = root.get_node("ScenarioManager").active_scenario
	var idx := {1: 0, 2: 0}
	for step in steps:
		var pid: int = _gs.active_deployer_id
		var faction = _gs.get_faction_for_player(pid)
		if faction == null:
			break
		var units: Array = faction.available_units
		var ud = units[idx[pid] % units.size()]
		idx[pid] += 1
		var zone: Rect2 = sc.p1_deploy_zone if pid == 1 else sc.p2_deploy_zone
		if _gs.zone_a_owner_id != 0 and _gs.zone_a_owner_id != 1:
			zone = sc.p2_deploy_zone if pid == 1 else sc.p1_deploy_zone
		var c := zone.get_center()
		var pos := Vector3(c.x + (randf() - 0.5) * zone.size.x * 0.4, 0.0, c.y + (step - steps / 2) * 2.5)
		_game.request_deploy_unit(ud.resource_path, pos, -1)
		await _frames(10)

func _first_unit_of(player_id: int) -> Node3D:
	for n in _game.get_node("Units").get_children():
		if n.get("owner_id") == player_id:
			return n
	return null

## ÇAKIŞMA RAPORU: savaş ekranının ana bölgeleri birbirinin üstüne biniyor mu? Görünür olanların
## ekran dikdörtgenleri karşılaştırılır; kesişen her çift "ÇAKIŞMA" olarak yazılır.
func _report_overlaps() -> void:
	var hud: Node = _game.get_node_or_null("GameHUD")
	if hud == null:
		return
	var tb: Node = hud.get_node("MarginContainer/VBoxContainer/TopBar")
	var regions := {
		"Rozet-sol": tb.get_node("RoundWinBadgeLeft"), "Rozet-sağ": tb.get_node("RoundWinBadgeRight"),
		"Madalyon": tb.get_node("RoundMedallion"), "Durum": tb.get_node("StatusLabel"),
		"Menü": tb.get_node("MenuButton"), "Kayıtlar": tb.get_node("ChroniclesButton"),
		"Hedefler": tb.get_node("ObjectivesButton"), "Kaynaklar": tb.get_node("ResourcesButton"),
		"Kadro": hud.get_node("%UnitCards"), "KomutaPaneli": hud.get_node("%CommandBar"),
		"Bitir": hud.get_node("MarginContainer/VBoxContainer/BottomPanel/EndTurnButton"),
	}
	for c in hud.get_node("%Notices").get_children():
		if c is Control and c.visible:
			regions["Duyuru:" + String(c.name)] = c
	var names := regions.keys()
	var found := 0
	for i in names.size():
		for j in range(i + 1, names.size()):
			var a: Control = regions[names[i]]
			var b: Control = regions[names[j]]
			if not (a.is_visible_in_tree() and b.is_visible_in_tree()):
				continue
			if a.get_global_rect().grow(-1).intersects(b.get_global_rect().grow(-1)):
				print("ÇAKIŞMA: %s %s × %s %s" % [names[i], a.get_global_rect(), names[j], b.get_global_rect()])
				found += 1
	print("ui_capture: çakışma denetimi — %d çakışma" % found)

## BOYUT KARARLILIĞI: her birimi sırayla seçip (ve seçimi kaldırıp) komuta panelinin boyutunu ölçer.
## Panelin boyutu içeriğe göre değişirse ("butonlar kıpırdıyor") "BOYUT DEĞİŞTİ" yazılır.
func _check_size_stability() -> void:
	var hud: Node = _game.get_node_or_null("GameHUD")
	if hud == null:
		return
	var bar: Control = hud.get_node("%CommandBar")
	var sizes := {}
	var units: Array = []
	for n in _game.get_node("Units").get_children():
		units.append(n)
	units.append(null)  # seçim yok (yönerge hâli)
	for u in units:
		if u == null:
			_gs.deselect_unit()
		else:
			# Ölçüm için sıra birimin sahibine geçer (eylemler yalnız sırası gelen oyuncuda kurulur)
			root.get_node("TurnManager").current_turn_player_id = u.owner_id
			_gs.select_unit(u)
		await _frames(6)
		sizes[str(bar.size)] = (str(u.name) if u else "(seçim yok)")
		if u != null:
			var widths := []
			for b in bar.actions.get_children():
				widths.append(int(b.size.x))
			print("eylem butonları %s: %s" % [u.name, str(widths)])
			if widths.size() >= 6:
				await _shot("09_many_actions_" + str(u.name), 4)
	if sizes.size() > 1:
		print("BOYUT DEĞİŞTİ: komuta paneli %d farklı boyut aldı: %s" % [sizes.size(), str(sizes)])
	else:
		print("ui_capture: boyut kararlılığı — komuta paneli sabit %s" % sizes.keys()[0])

