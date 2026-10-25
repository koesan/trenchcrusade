extends Node

## SaveManager
## Oyunu kaydetme, yükleme ve çok oyunculu senkronizasyon işlemlerini yönetir.

## Testler gerçek oyuncu kaydına dokunmasın diye değiştirilebilir (bkz. tests/save_load_e2e.gd).
var save_path: String = "user://save_game.json"

var has_pending_load: bool = false
var is_waiting_for_reconnect: bool = false
var saved_role: String = "local" # "host", "client", "local"
var saved_ip: String = "127.0.0.1"
var saved_port: int = 10567
var saved_player_name: String = ""

# Bu sinyal sunucuya istemci bağlandığında ve sahneyi yüklediğinde tetiklenir
signal client_ready_to_sync_signal(peer_id: int)

func _ready() -> void:
	# NetworkManager sinyallerini dinle
	NetworkManager.connection_status_changed.connect(_on_connection_status_changed)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func has_save_game() -> bool:
	return FileAccess.file_exists(save_path)

func delete_save() -> void:
	if has_save_game():
		DirAccess.remove_absolute(save_path)
		GameLogger.log_info("Kayıt dosyası silindi.", "SYSTEM")

func save_game() -> bool:
	var data = {}
	
	var is_mp = multiplayer.has_multiplayer_peer()
	data["is_multiplayer"] = is_mp
	
	if is_mp:
		if multiplayer.is_server():
			data["role"] = "host"
			data["port"] = NetworkManager.last_connected_port if "last_connected_port" in NetworkManager else NetworkManager.DEFAULT_PORT
			data["player_name"] = NetworkManager.local_player_name
			data["password"] = NetworkManager.lobby_password
		else:
			data["role"] = "client"
			data["host_ip"] = NetworkManager.last_connected_ip if "last_connected_ip" in NetworkManager else NetworkManager.DEFAULT_IP
			data["port"] = NetworkManager.last_connected_port if "last_connected_port" in NetworkManager else NetworkManager.DEFAULT_PORT
			data["player_name"] = NetworkManager.local_player_name
			data["password"] = NetworkManager.lobby_password
			
			# İstemci sadece bağlantı bilgisini kaydeder, state kaydetmez (sunucu otoritesi)
			var file = FileAccess.open(save_path, FileAccess.WRITE)
			if file:
				file.store_string(JSON.stringify(data, "  "))
				file.close()
				GameLogger.log_info("İstemci bağlantı bilgisi kaydedildi.", "SYSTEM")
				return true
			return false
	else:
		data["role"] = "local"
		data["player_name"] = "Player"

	# GameState state'i
	var gs_data = {
		"game_phase": int(GameState.game_phase),
		"player_factions": {},
		"player_deploy_pool": GameState.player_deploy_pool.duplicate(),
		"player_deployment_finished": GameState.player_deployment_finished.duplicate(),
		"player_glory_pool": GameState.player_glory_pool.duplicate(),
		"player_deployed_count": GameState.player_deployed_count.duplicate(),
		"active_deployer_id": GameState.active_deployer_id,
		"zone_a_owner_id": GameState.zone_a_owner_id
	}
	for pid in GameState.player_factions:
		var faction = GameState.player_factions[pid]
		gs_data["player_factions"][str(pid)] = faction.resource_path if faction else ""
	data["game_state"] = gs_data

	# KÖK NEDEN DÜZELTMESİ: senaryo (aktif senaryo kimliği, VP, round-kazanma sayacı, Glorious
	# Deeds, objective sahipliği ve her senaryonun kendi ek durumu — ör. Marked for Death'in Bounty
	# Target'ı, Relic Hunt'ın Reliquary sahipliği) önceden HİÇ kaydedilmiyordu — bir kayıt
	# yüklendiğinde VP sıfırlanıyor, hangi senaryonun oynandığı unutuluyordu.
	var scenario_data_out := {}
	if ScenarioManager.active_scenario != null:
		scenario_data_out["scenario_id"] = String(ScenarioManager.active_scenario.scenario_id)
		if ScenarioManager.logic != null:
			scenario_data_out["logic_state"] = ScenarioManager.logic.save_state()
	data["scenario"] = scenario_data_out

	# TurnManager state'i
	var tm_data = {
		"current_turn_player_id": TurnManager.current_turn_player_id,
		"current_round": TurnManager.current_round,
		"activated_units": TurnManager.activated_units.duplicate(),
		"initiative_winner_id": TurnManager.initiative_winner_id,
		"player_starting_unit_counts": TurnManager.player_starting_unit_counts.duplicate(),
		"player_consecutive_morale_failures": TurnManager.player_consecutive_morale_failures.duplicate(),
		"player_shaken_state": TurnManager.player_shaken_state.duplicate(),
		"forced_next_activator": TurnManager.forced_next_activator,
		"current_phase": TurnManager.current_phase,
		"pending_morale_bonus_dice": TurnManager.pending_morale_bonus_dice.duplicate(),
	}
	data["turn_manager"] = tm_data

	# Birimlerin listesi. Durum alanları `UnitSerializer.FIELDS` TEK KAYNAĞINDAN gelir —
	# buraya elle alan eklenmez (eklenirse geri yükleme tarafı sessizce atlar, bkz. o dosya).
	# Burada yalnız YAPISAL alanlar var: kimlik, hangi .tres, hangi Battlekit, konum/rotasyon.
	var units_data = []
	for u in UnitQuery.alive():
		var u_data := {
			"name": u.name,
			"owner_id": u.owner_id,
			# `unit_data` loadout/zırhane yüzünden bir KOPYA olabilir (resource_path boş) — temel
			# .tres yolu birimde ayrıca tutulur; yüklemede loadout ve eşyalar bunun üstüne kurulur.
			"unit_data_path": u.unit_data_path if u.unit_data_path != "" \
				else (u.unit_data.resource_path if u.unit_data else ""),
			# KAYIP VERİ DÜZELTMESİ: eskiden kaydedilmiyordu → yüklenen oyunda her birim
			# VARSAYILAN Battlekit ile geri geliyor, seçilen silahlar sessizce kayboluyordu.
			"loadout_index": u.chosen_loadout_index,
			"pos": {"x": u.global_position.x, "y": u.global_position.y, "z": u.global_position.z},
			"rot": {"x": u.global_rotation.x, "y": u.global_rotation.y, "z": u.global_rotation.z},
		}
		u_data.merge(UnitSerializer.capture(u))
		units_data.append(u_data)
	data["units"] = units_data
	data["armoury"] = {"unit_items": ArmouryManager.unit_items.duplicate(true),
		"warband_items": ArmouryManager.warband_items.duplicate(true)}
	data["terrain"] = _capture_terrain()

	# Oyuncu adları
	var players_data = {}
	for pid in NetworkManager.players:
		players_data[str(pid)] = NetworkManager.players[pid].duplicate()
	data["players"] = players_data

	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "  "))
		file.close()
		GameLogger.log_info("Oyun durumu başarıyla kaydedildi.", "SYSTEM")
		return true
	
	GameLogger.log_error("Oyun durumu kaydedilemedi! Dosya açılamadı.", "SYSTEM")
	return false

func load_game() -> void:
	if not has_save_game():
		GameLogger.log_warn("Yüklenecek kayıt dosyası bulunamadı.", "SYSTEM")
		return
		
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		GameLogger.log_error("Kayıt dosyası okunamadı.", "SYSTEM")
		return
		
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var err = json.parse(content)
	if err != OK:
		GameLogger.log_error("Kayıt dosyası JSON ayrıştırma hatası!", "SYSTEM")
		return
		
	var data = json.data as Dictionary
	var is_mp = data.get("is_multiplayer", false)
	saved_role = data.get("role", "local")
	saved_port = int(data.get("port", NetworkManager.DEFAULT_PORT))
	saved_player_name = data.get("player_name", "Player")
	var saved_password = data.get("password", "")
	
	if is_mp:
		if saved_role == "client":
			saved_ip = data.get("host_ip", NetworkManager.DEFAULT_IP)
			GameLogger.log_info("Çok oyunculu istemci olarak bağlanılıyor: %s:%d" % [saved_ip, saved_port], "SYSTEM")
			# İstemci olarak bağlan
			has_pending_load = true
			NetworkManager.join_game(saved_ip, saved_port, saved_player_name, saved_password)
		else:
			GameLogger.log_info("Çok oyunculu sunucu olarak kurun: Port %d" % saved_port, "SYSTEM")
			has_pending_load = true
			is_waiting_for_reconnect = true
			
			# Sunucu olarak kur
			var host_err = NetworkManager.host_game(saved_port, saved_player_name, saved_password)
			if host_err == OK:
				# Restored match is in progress
				NetworkManager.is_in_lobby = false
				NetworkManager.is_in_match = true
				
				var root = Engine.get_main_loop().root
				if root.has_node("LoadingManager"):
					root.get_node("LoadingManager").load_scene("res://scenes/game/game.tscn")
				else:
					Engine.get_main_loop().current_scene.get_tree().change_scene_to_file("res://scenes/game/game.tscn")
			else:
				has_pending_load = false
				is_waiting_for_reconnect = false
				GameLogger.log_error("Sunucu kurma hatası: %d" % host_err, "SYSTEM")
	else:
		GameLogger.log_info("Tek oyunculu yerel maç yükleniyor.", "SYSTEM")
		has_pending_load = true
		NetworkManager.leave_game() # Çevrimdışı moda geç
		
		var root = Engine.get_main_loop().root
		if root.has_node("LoadingManager"):
			root.get_node("LoadingManager").load_scene("res://scenes/game/game.tscn")
		else:
			Engine.get_main_loop().current_scene.get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func restore_game_state(game_node: Node3D) -> void:
	if not has_pending_load:
		return
		
	GameLogger.log_info("Kaydedilen oyun durumu geri yükleniyor...", "SYSTEM")
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		has_pending_load = false
		return
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	json.parse(content)
	var data = json.data as Dictionary
	
	# İstemci ise, durumu sunucudan alacağı için yerel geri yüklemeyi yapmaz, sunucuyu bekler!
	if data.get("is_multiplayer", false) and saved_role == "client":
		GameLogger.log_info("İstemci modunda yerel veri yüklenmiyor, sunucudan senkronizasyon bekleniyor.", "SYSTEM")
		# Sunucuya hazır olduğumuzu bildir
		rpc_id(1, "server_client_ready_to_sync")
		has_pending_load = false
		
		# Yükleme tamamlandı, yükleme ekranını kapat
		var root = Engine.get_main_loop().root
		if root.has_node("LoadingManager"):
			root.get_node("LoadingManager").hide_loading()
		return

	# Sunucu/Yerel modunda durumu geri yükle
	var gs_data = data.get("game_state", {})
	GameState.game_phase = gs_data.get("game_phase", 0) as GameState.GamePhase
	GameState.active_deployer_id = int(gs_data.get("active_deployer_id", 1))
	GameState.zone_a_owner_id = int(gs_data.get("zone_a_owner_id", 0))

	# Senaryo durumu — ScenarioManager.select_scenario() taze bir ScenarioLogic kurar (setup()),
	# hemen ardından logic.load_state() kaydedilen VP/round-win/deed/objective/senaryo-özel
	# durumunu üstüne yazar. select_scenario zaten scenario_changed sinyalini yayar — game.gd
	# (artık _connect_game_flow_signals ile HER İKİ yolda da bağlı) objective marker'larını VE
	# saha seçimi zemin overlay'ini bu sinyalden otomatik yeniden kurar.
	var scenario_saved: Dictionary = data.get("scenario", {})
	var saved_scenario_id: String = scenario_saved.get("scenario_id", "")
	if saved_scenario_id != "":
		ScenarioManager.select_scenario(StringName(saved_scenario_id))
		if ScenarioManager.logic != null:
			ScenarioManager.logic.load_state(scenario_saved.get("logic_state", {}))
			# UI aynası (VP/round-win top bar göstergeleri) — bir sonraki tur sonunu beklemeden
			# hemen doğru değerleri göstersin.
			RpcHelper.sync(ScenarioManager, "sync_vp", [
				ScenarioManager.logic.player_vp.duplicate(),
				ScenarioManager.logic.player_round_wins.duplicate()
			])

	# Faksiyonları yükle
	var p_factions = gs_data.get("player_factions", {})
	for pid_str in p_factions:
		var pid = int(pid_str)
		var f_path = p_factions[pid_str]
		if f_path != "":
			GameState.player_factions[pid] = load(f_path)
			GameState.faction_selected.emit(pid, GameState.player_factions[pid])
		else:
			GameState.player_factions[pid] = null
			
	# Deploy havuzları
	var p_deploy = gs_data.get("player_deploy_pool", {})
	for pid_str in p_deploy:
		GameState.player_deploy_pool[int(pid_str)] = int(p_deploy[pid_str])
		
	# Deploy bitiş durumları
	var p_finished = gs_data.get("player_deployment_finished", {})
	for pid_str in p_finished:
		GameState.player_deployment_finished[int(pid_str)] = bool(p_finished[pid_str])
	var p_glory: Dictionary = gs_data.get("player_glory_pool", {})
	for pid_str in p_glory:
		GameState.player_glory_pool[int(pid_str)] = int(p_glory[pid_str])
	var p_count: Dictionary = gs_data.get("player_deployed_count", {})
	for pid_str in p_count:
		GameState.player_deployed_count[int(pid_str)] = int(p_count[pid_str])

	# TurnManager durumu
	var tm_data = data.get("turn_manager", {})
	TurnManager.current_turn_player_id = int(tm_data.get("current_turn_player_id", 1))
	TurnManager.current_round = int(tm_data.get("current_round", 1))
	TurnManager.activated_units = tm_data.get("activated_units", [])
	TurnManager.initiative_winner_id = int(tm_data.get("initiative_winner_id", 1))
	
	var starting_counts = tm_data.get("player_starting_unit_counts", {})
	for pid_str in starting_counts:
		TurnManager.player_starting_unit_counts[int(pid_str)] = int(starting_counts[pid_str])
		
	var morale_failures = tm_data.get("player_consecutive_morale_failures", {})
	for pid_str in morale_failures:
		TurnManager.player_consecutive_morale_failures[int(pid_str)] = int(morale_failures[pid_str])
		
	var shaken_state = tm_data.get("player_shaken_state", {})
	for pid_str in shaken_state:
		TurnManager.player_shaken_state[int(pid_str)] = bool(shaken_state[pid_str])
		
	TurnManager.forced_next_activator = tm_data.get("forced_next_activator", "")
	TurnManager.current_phase = int(tm_data.get("current_phase", TurnManager.current_phase))
	var morale_bonus: Dictionary = tm_data.get("pending_morale_bonus_dice", {})
	for pid_str in morale_bonus:
		TurnManager.pending_morale_bonus_dice[int(pid_str)] = int(morale_bonus[pid_str])
	
	# TurnManager sinyallerini tetikle (HUD güncellensin)
	TurnManager.turn_changed.emit(TurnManager.current_turn_player_id)
	TurnManager.round_started.emit(TurnManager.current_round)

	# Oyuncu verilerini yükle (Host ise)
	if data.get("is_multiplayer", false):
		var saved_players = data.get("players", {})
		for pid_str in saved_players:
			var pid = int(pid_str)
			NetworkManager.players[pid] = saved_players[pid_str]
		NetworkManager.players_updated.emit()

	# Mevcut tüm birimleri temizle (varsa)
	for u in UnitQuery.all():
		u.queue_free()
	GameState.units.clear()

	# Birimleri spawn et
	var units_list = data.get("units", [])
	var units_container = game_node.get_node("Units")
	var unit_scene = game_node.unit_scene
	var restored: Array = []
	
	for u_data in units_list:
		var owner_id = int(u_data.get("owner_id", 1))
		var u_name = u_data.get("name", "")
		var unit_data_path = u_data.get("unit_data_path", "")
		var pos_dict = u_data.get("pos", {"x": 0.0, "y": 0.0, "z": 0.0})
		var rot_dict = u_data.get("rot", {"x": 0.0, "y": 0.0, "z": 0.0})
		var pos = Vector3(pos_dict.x, pos_dict.y, pos_dict.z)
		var rot = Vector3(rot_dict.x, rot_dict.y, rot_dict.z)
		
		# Sadece ismi u_name formatında tut
		var raw_name = u_name.replace("Unit_%d_" % owner_id, "")
		# Eski kayıtlarda bu alan YOKTU → -1 (varsayılan Battlekit), yeni kayıtlarda seçim korunur.
		var loadout_index := int(u_data.get("loadout_index", -1))

		var unit = null
		if data.get("is_multiplayer", false):
			var spawn_data = {
				"owner_id": owner_id,
				"u_name": raw_name,
				"pos": pos,
				"unit_data_path": unit_data_path,
				"loadout_index": loadout_index,
			}
			unit = game_node.get_node("MultiplayerSpawner").spawn(spawn_data)
		else:
			unit = unit_scene.instantiate()
			unit.name = u_name
			units_container.add_child(unit, true)
			unit.global_position = pos
			unit.init_unit(owner_id, unit_data_path, loadout_index, true)
		unit.global_rotation = rot
		GameState.register_unit(unit)
		restored.append([unit, u_data])

	# Zırhane eşyaları birimler kurulduktan SONRA, kayıtlı durum uygulanmadan ÖNCE yeniden takılır:
	# eşya uygulaması unit_data'yı tazeler, ardından UnitSerializer kaydedilen değerleri yazar.
	var armoury_saved: Dictionary = data.get("armoury", {})
	ArmouryManager.restore_state(armoury_saved.get("unit_items", {}), armoury_saved.get("warband_items", {}))

	for pair in restored:
		var unit = pair[0]
		var u_data: Dictionary = pair[1]

		# Durum alanlarının TAMAMI tek kaynaktan (UnitSerializer.FIELDS) uygulanır — kaydetme
		# tarafıyla sapması imkânsız. Eksik anahtarlar tablodaki varsayılana düşer (eski kayıtlar
		# bozulmaz).
		UnitSerializer.apply(unit, u_data)
		# Broken on the Wheel bir kez tükendiyse birim normal profiline dönmüştü (bkz. injury_resolver).
		if KeywordSystem.has(unit.unit_data, &"broken_on_wheel_chosen") and not unit.broken_on_wheel_active:
			unit.unit_data.has_tough = true
			unit.unit_data.keywords[&"negate_shrapnel"] = 1
		
		# Görsel durumları güncelle
		unit.update_indicators()
		
		# Down durumunda model rotasyonunu ayarla
		var target_node = unit.model_node if is_instance_valid(unit.model_node) else unit.mesh_instance
		if is_instance_valid(target_node) and unit.is_down:
			target_node.rotation.x = -PI / 2

	_restore_terrain(data.get("terrain", []), game_node)

	# Yerel/Sunucu tarafında HUD güncellemesi tetikle
	var hud = game_node.get_node_or_null("GameHUD")
	if hud:
		hud._update_hud_visibility()
		hud._update_locale()
		
	# Çok oyunculu sunucu ise, rakibin bağlanmasını bekle ekranını aç
	if data.get("is_multiplayer", false):
		is_waiting_for_reconnect = true
		if hud:
			hud.show_reconnect_overlay()
	
	has_pending_load = false
	GameLogger.log_info("Oyun durumu başarıyla geri yüklendi.", "SYSTEM")
	
	# Yükleme tamamlandı, yükleme ekranını kapat
	var root = Engine.get_main_loop().root
	if root.has_node("LoadingManager"):
		root.get_node("LoadingManager").hide_loading()

# İstemci sahneyi yüklediğinde sunucuyu bilgilendirir
@rpc("any_peer", "reliable")
func server_client_ready_to_sync():
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	GameLogger.log_info("İstemci %d sahne yüklemesini bitirdi, senkronizasyona hazır." % sender_id, "SYSTEM")
	client_ready_to_sync_signal.emit(sender_id)

func _on_peer_connected(id: int) -> void:
	if not multiplayer.is_server():
		return
		
	if is_waiting_for_reconnect:
		GameLogger.log_info("İstemci bağlandı: %d. Sahneyi yüklemesi tetikleniyor." % id, "SYSTEM")
		# NOT: GameState/TurnManager sözlüklerini yeniden eşlemeye artık gerek YOK — bunlar hep
		# kanonik {1,2} ile anahtarlanıyor (bkz. NetworkManager.canonical_of_peer). Gerçek peer id
		# değişse bile (reconnect'te olağan) kanonik numara sabit kalır; eşleme register_player'da
		# (NetworkManager) otomatik güncellenir.

		# İstemciyi maçı başlatmaya yönlendir
		NetworkManager.rpc_id(id, "start_game")
		
		# İstemcinin hazır olmasını bekle
		if not client_ready_to_sync_signal.is_connected(_sync_restored_state_to_client):
			client_ready_to_sync_signal.connect(_sync_restored_state_to_client, CONNECT_ONE_SHOT)

func _sync_restored_state_to_client(client_id: int):
	GameLogger.log_info("İstemci %d için senkronizasyon başlatılıyor..." % client_id, "SYSTEM")
	
	# GameState verilerini istemciye gönder
	var gs_factions = {}
	for pid in GameState.player_factions:
		var faction = GameState.player_factions[pid]
		gs_factions[str(pid)] = faction.resource_path if faction else ""
		
	rpc_id(client_id, "client_restore_gamestate_data",
		int(GameState.game_phase),
		gs_factions,
		GameState.player_deploy_pool,
		GameState.active_deployer_id,
		GameState.player_deployment_finished,
		GameState.zone_a_owner_id
	)
	
	# Senaryo/VP/round-win/deed durumunu istemciye gönder (bkz. scenario_manager.gd::client_catch_up_scenario)
	if ScenarioManager.active_scenario != null and ScenarioManager.logic != null:
		ScenarioManager.rpc_id(client_id, "client_catch_up_scenario",
			String(ScenarioManager.active_scenario.scenario_id), ScenarioManager.logic.save_state())

	# TurnManager verilerini istemciye gönder
	TurnManager.rpc_id(client_id, "sync_round_state", TurnManager.current_round, TurnManager.activated_units, TurnManager.current_turn_player_id, TurnManager.initiative_winner_id)
	TurnManager.rpc_id(client_id, "sync_shaken_states", TurnManager.player_shaken_state)
	TurnManager.rpc_id(client_id, "sync_forced_activator", TurnManager.forced_next_activator)
	
	# Zırhane eşyaları ÖNCE (apply_unit_data işaretleri sıfırlar), birim durumları SONRA
	ArmouryManager.rpc_id(client_id, "restore_state", ArmouryManager.unit_items, ArmouryManager.warband_items)
	# Birimlerin değişkenlerini istemciye gönder
	for u in UnitQuery.all():
		u.rpc_id(client_id, "sync_health_states", u.current_health, u.is_down, u.blood_markers, u.blessing_markers, u.infection_markers, false)
		u.rpc_id(client_id, "sync_actions_taken", u.actions_taken)
		u.rpc_id(client_id, "sync_action_state", u.has_moved)
			
	# Reconnect ekranlarını kapat
	rpc("hide_reconnect_overlays")
	is_waiting_for_reconnect = false

@rpc("authority", "reliable")
func client_restore_gamestate_data(phase_idx: int, factions_dict: Dictionary, deploy_pool: Dictionary, active_deployer: int, deployment_finished: Dictionary, zone_a_owner: int = 0):
	GameLogger.log_info("İstemci: GameState verileri geri yükleniyor...", "SYSTEM")
	GameState.game_phase = phase_idx as GameState.GamePhase
	GameState.active_deployer_id = active_deployer
	GameState.zone_a_owner_id = zone_a_owner

	for pid_str in factions_dict:
		var pid = int(pid_str)
		var f_path = factions_dict[pid_str]
		if f_path != "":
			GameState.player_factions[pid] = load(f_path)
			GameState.faction_selected.emit(pid, GameState.player_factions[pid])
		else:
			GameState.player_factions[pid] = null
			
	for pid_str in deploy_pool:
		GameState.player_deploy_pool[int(pid_str)] = int(deploy_pool[pid_str])
		
	for pid_str in deployment_finished:
		GameState.player_deployment_finished[int(pid_str)] = bool(deployment_finished[pid_str])
		
	# İstemci tarafında HUD güncellemesi tetikle
	var root = Engine.get_main_loop().root
	var hud = root.find_child("GameHUD", true, false)
	if hud:
		if hud.has_method("_update_hud_visibility"):
			hud._update_hud_visibility()
		if hud.has_method("_update_locale"):
			hud._update_locale()

@rpc("authority", "reliable")
func hide_reconnect_overlays():
	is_waiting_for_reconnect = false
	var root = Engine.get_main_loop().root
	var hud = root.find_child("GameHUD", true, false)
	if hud and hud.has_method("hide_reconnect_overlay"):
		hud.hide_reconnect_overlay()
	GameLogger.log_info("Çok oyunculu maç başarıyla yeniden kuruldu ve devam ediyor.", "SYSTEM")

func _on_peer_disconnected(id: int) -> void:
	# Eğer maç sırasında istemci koparsa, sunucu tekrar bekleme moduna geçebilir
	if multiplayer.is_server() and NetworkManager.is_in_match:
		GameLogger.log_warn("Oyuncu bağlantıyı kesti (ID: %d). Bekleme modu aktif." % id, "SYSTEM")
		is_waiting_for_reconnect = true
		var root = Engine.get_main_loop().root
		var hud = root.find_child("GameHUD", true, false)
		if hud and hud.has_method("show_reconnect_overlay"):
			hud.show_reconnect_overlay()

func _on_connection_status_changed(message: String) -> void:
	# Bağlantı koptuğunda durumu temizle
	if not multiplayer.has_multiplayer_peer():
		is_waiting_for_reconnect = false


## Sahadaki arazi parçaları: senaryo yerleşimleri + oyun içinde kurulan mayın/siperler.
## Tüketilmiş (patlamış) parçalar listede yoktur — yüklemede geri gelmezler.
func _capture_terrain() -> Array:
	var out: Array = []
	for f in TerrainManager.features:
		if not is_instance_valid(f) or not f.is_active or f.feature_data == null:
			continue
		out.append({"path": f.feature_data.resource_path, "setter": f.setter_unit_name,
			"pos": {"x": f.global_position.x, "y": f.global_position.y, "z": f.global_position.z},
			"rot_y": f.rotation.y})
	return out

## Senaryo seçimi senaryonun varsayılan parçalarını kurdu; kayıt GERÇEK durumu taşır → onu yaz.
## Eski kayıtlarda alan yoksa senaryo yerleşimi olduğu gibi kalır.
func _restore_terrain(saved: Array, game_node: Node) -> void:
	if saved.is_empty():
		return
	TerrainManager.clear_all()
	TerrainManager.container = game_node
	for t in saved:
		var feature: Resource = load(t.get("path", "")) if t.get("path", "") != "" else null
		if feature == null:
			continue
		var p: Dictionary = t.get("pos", {})
		var pos := Vector3(p.get("x", 0.0), p.get("y", 0.0), p.get("z", 0.0))
		var node: Node3D = TerrainManager.spawn_feature(feature, pos, t.get("setter", ""), float(t.get("rot_y", 0.0)))
		# Kayıttaki konum zaten zemine oturtulmuştu; navmesh pişer pişmez sorgulanan "en yakın
		# nokta" harita senkronlanana dek (0,0,0) dönebildiğinden kaydı olduğu gibi uygula.
		if node:
			node.global_position = pos
