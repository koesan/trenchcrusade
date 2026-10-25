extends Node3D

## Oyun sahnesi ana kontrolcüsü.
## Birim spawn'ı, yerleşim (deployment) yönetimi ve NavMesh pişirmeyi koordine eder.

@export var unit_scene: PackedScene = preload("res://scenes/unit/unit.tscn")
const OBJECTIVE_MARKER_SCENE = preload("res://scenes/scenario/objective_marker.tscn")
const RELIC_MARKER_SCENE = preload("res://scenes/scenario/relic_marker.tscn")

## Relic Hunt'ın 4 Reliquary'si arasında paylaşılan 3 model (compendium: "aynı modellerden
## birden fazla kullanılabilir" — kullanıcı isteği). Sırayla döngüsel atanır.
const RELIC_MODEL_PATHS := [
	"res://assets/models/scenario/Ark_of_the_Covenant.glb",
	"res://assets/models/scenario/Saint_Elizabeth_Relic.glb",
	"res://assets/models/scenario/Holy_Relic_Chest.glb",
]
@onready var units_container = $Units
@onready var navigation_region = $NavigationRegion3D

## Sahada aktif senaryo objective marker'ları.
var objective_markers: Array = []

## SAHA SEÇİMİ: yerleştirme bölgelerinin haritadaki göstergesi (bkz. DeployZoneOverlay).
var _zone_overlay: DeployZoneOverlay = null

## Objective marker renk güncellemesinde throttle sayıcısı (0.5sn aralık, hareket sırasında da renk değişsin).
var _objective_update_timer: float = 0.0
const OBJECTIVE_UPDATE_INTERVAL := 0.5

## Savaş sahnesinden çıkınca ortam sesi durur, model önbellekleri boşaltılır (bellek tasarrufu).
func _exit_tree() -> void:
	AudioManager.stop_ambient()
	UIPreviewHelper.model_cache.clear()
	UnitVisuals._flash_material_cache.clear()

func _ready():
	GameLogger.log_info("Oyun sahnesi hazırlandı. Başlangıç temizliği yapılıyor.", "GAME")
	GameState.clear_state()
	GameState.is_game_active = true

	# Oyun içi müzik (gameplay playlist'i; menü müziğinden crossfade ile geçer).
	AudioManager.play_playlist("gameplay")
	# Siper ortam sesi: assets/audio/sfx/ambient/battlefield*.ogg (yoksa sessiz, müzik deseniyle aynı).
	AudioManager.play_ambient(&"ambient/battlefield")
	
	if $MultiplayerSpawner:
		$MultiplayerSpawner.spawn_function = _on_unit_spawned
		
	# Fizik sunucusunun çarpışma sınırlarını senkronize etmesi için 2 fizik karesi bekle
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	if navigation_region:
		GameLogger.log_info("NavMesh pişirme işlemi başlatılıyor...", "SYSTEM")
		var map_rid = get_world_3d().navigation_map
		NavigationServer3D.map_set_cell_size(map_rid, 0.1)
		NavigationServer3D.map_set_cell_height(map_rid, 0.1)
		
		var nav_mesh = NavigationMesh.new()
		nav_mesh.cell_size = 0.1
		nav_mesh.cell_height = 0.1
		nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
		nav_mesh.agent_height = 2.0
		nav_mesh.agent_radius = 0.6
		nav_mesh.agent_max_slope = 45.0
		nav_mesh.agent_max_climb = GameState.NAV_AGENT_MAX_CLIMB
		navigation_region.navigation_mesh = nav_mesh
		
		navigation_region.bake_finished.connect(_on_navmesh_baked)
		navigation_region.bake_navigation_mesh()
	else:
		if SaveManager.has_pending_load:
			_connect_game_flow_signals()
			SaveManager.restore_game_state(self)
		else:
			_start_game_flow()

func _on_navmesh_baked():
	GameLogger.log_info("NavMesh pişirme tamamlandı. Akış denetleniyor.", "SYSTEM")
	_compute_battlefield_bounds()
	if SaveManager.has_pending_load:
		_connect_game_flow_signals()
		SaveManager.restore_game_state(self)
	else:
		_start_game_flow()

## AUTOMATON DESTRIER (Mamluk Faris, P1-1): "harita kenarı" kavramının TEK KAYNAĞI — pişirilmiş
## NavigationMesh'in vertex'lerinden XZ düzlemindeki AABB'yi çıkarır. GameState.battlefield_bounds'a
## yazılır (deploy doğrulaması + gelecekteki benzer "kenara yakın" kuralları için).
func _compute_battlefield_bounds() -> void:
	if navigation_region == null or navigation_region.navigation_mesh == null:
		return
	var verts: PackedVector3Array = navigation_region.navigation_mesh.get_vertices()
	if verts.is_empty():
		return
	var bounds := AABB(verts[0], Vector3.ZERO)
	for v in verts:
		bounds = bounds.expand(v)
	GameState.battlefield_bounds = bounds
	GameLogger.log_info("Savaş alanı sınırları hesaplandı: %s" % str(bounds), "SYSTEM")

func _prewarm_shaders() -> void:
	GameLogger.log_info("Görsel ve Shader ön-ısınma (pre-warming) işlemi başlatılıyor...", "SYSTEM")
	
	# 1. Zarların ön-ısınması (shader derlemesi TEK zar ile; DiceManager havuzu ayrıca
	# PREWARM_POOL_SIZE kadar önceden doldurulur — oyun ortasında ilk yüksek-adetli atışta
	# instantiate+add_child donması yaşanmasın diye, bkz. DiceManager.prewarm_pool yorumu).
	var dice_scene = load("res://scenes/dice/dice.tscn")
	if dice_scene:
		var temp_dice = dice_scene.instantiate()
		temp_dice.position = Vector3(0, -100, 0) # Ekranda görünmeyecek bir yere koy
		add_child(temp_dice)
		# Bir kare render edilmesini bekleyelim
		await get_tree().process_frame
		temp_dice.queue_free()

	DiceManager.prewarm_pool(self)
	# 2. Faksiyon renkleri ve hasar efekti flash materyallerinin ön-ısınması
	var colors = GameVisualColors.get_colors()
	if colors:
		# Bir adet geçici mesh oluşturup tüm materyalleri buna uygulayarak GPU'da derlenmesini sağlayalım
		var temp_mesh = MeshInstance3D.new()
		temp_mesh.mesh = QuadMesh.new()
		temp_mesh.position = Vector3(0, -100, 0)
		add_child(temp_mesh)
		
		var test_colors = [
			colors.unit_heretic,
			colors.unit_anointed,
			colors.unit_pilgrims,
			colors.unit_default,
			colors.damage_flash
		]
		
		for col in test_colors:
			var mat = StandardMaterial3D.new()
			mat.roughness = 0.6
			mat.metallic = 0.15
			mat.albedo_color = col
			temp_mesh.set_surface_override_material(0, mat)
			await get_tree().process_frame
			
			# Flash versiyonu
			var flash_mat = mat.duplicate()
			flash_mat.emission_enabled = true
			flash_mat.emission = colors.damage_flash
			flash_mat.emission_energy_multiplier = 5.0
			temp_mesh.set_surface_override_material(0, flash_mat)
			await get_tree().process_frame
			
		temp_mesh.queue_free()
		
	GameLogger.log_info("Görsel ve Shader ön-ısınma işlemi tamamlandı.", "SYSTEM")

## KÖK NEDEN DÜZELTMESİ (save/load): bu bağlantılar önceden YALNIZ _start_game_flow() içindeydi —
## ama bir kayıt yüklenirken _start_game_flow() HİÇ ÇAĞRILMIYOR (bkz. _ready/_on_navmesh_baked,
## restore_game_state onun YERİNE çalışır). Sonuç: yüklenen bir oyunda objective marker'ları,
## saha seçimi zemin overlay'i ve tur-değişimi işaretçi güncellemeleri asla kurulmuyordu. Artık
## HER İKİ yolda da (yeni oyun + yüklenen oyun) aynı fonksiyon çağrılıyor — Tek Kaynak.
func _connect_game_flow_signals() -> void:
	if not GameState.deployment_completed.is_connected(_on_deployment_completed):
		GameState.deployment_completed.connect(_on_deployment_completed)
	# Senaryo seçildiğinde objective marker'larını kur (tüm eşlerde deterministik)
	if not ScenarioManager.scenario_changed.is_connected(_on_scenario_changed):
		ScenarioManager.scenario_changed.connect(_on_scenario_changed)
	# Objective kontrol renklerini her aktivasyonda güncelle
	if not TurnManager.turn_changed.is_connected(_on_turn_changed_markers):
		TurnManager.turn_changed.connect(_on_turn_changed_markers)
	# SAHA GÖSTERGESİ: overlay yalnız DEPLOYMENT fazında görünür + saha/faksiyon belli olunca renk netleşir.
	if _zone_overlay == null:
		_zone_overlay = DeployZoneOverlay.new()
		add_child(_zone_overlay)

func _start_game_flow():
	await _prewarm_shaders()

	GameLogger.log_info("Senaryo seçim aşaması (SCENARIO_SELECT) aktif.", "GAME")
	_connect_game_flow_signals()

	# Senaryo seçim aşaması ile başla; HUD senaryo panelini göstersin
	GameState.game_phase = GameState.GamePhase.SCENARIO_SELECT
	GameState.game_phase_changed.emit(GameState.GamePhase.SCENARIO_SELECT)

	# Yükleme tamamlandı, yükleme ekranını kapat
	if has_node("/root/LoadingManager"):
		get_node("/root/LoadingManager").hide_loading()

## Host/aktif oyuncu bir senaryo seçtiğinde çağrılır (senaryoyu yayar, bütçeyi uygular,
## DEPLOYMENT aşamasına geçer). Sunucu otoritesi.
@rpc("any_peer", "call_local", "reliable")
func request_select_scenario(scenario_id: String):
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		rpc_id(1, "request_select_scenario", scenario_id)
		return

	if GameState.game_phase != GameState.GamePhase.SCENARIO_SELECT:
		return

	ScenarioManager.select_scenario(StringName(scenario_id))
	GameState.apply_scenario_budget(ScenarioManager.get_points_budget(), ScenarioManager.get_glory_budget())

	# SIRALI YERLEŞTİRME (compendium, TÜM senaryolar): "The players roll-off... the players then
	# alternate deploying their models one at a time." Bu projede önceden BELİRLENMİŞ bir warband
	# roster'ı olmadığından ("daha çok modeli olan başlar" kıyaslanamaz — deploy bütçeden anlık
	# seçimle yapılıyor) roll-off HER ZAMAN uygulanır (compendium'un eşitlik durumundaki tali
	# kuralıyla aynı: rastgele). Yalnız SUNUCU/tek-oyunculu tarafta hesaplanır, RPC ile yayılır.
	GameState.active_deployer_id = 1 if randi() % 2 == 0 else 2
	GameLogger.log_info("Yerleşim sırası: Oyuncu %d ile başlıyor (roll-off)." % GameState.active_deployer_id, "GAME")

	if multiplayer.has_multiplayer_peer():
		GameState.rpc("sync_deployment_state", GameState.player_deploy_pool, GameState.player_deployed_count, GameState.active_deployer_id)
		GameState.rpc("sync_game_phase", GameState.GamePhase.DEPLOYMENT)
	else:
		GameState.sync_game_phase(GameState.GamePhase.DEPLOYMENT)

func _on_scenario_changed(scenario_data):
	_spawn_objective_markers(scenario_data)
	_spawn_terrain(scenario_data)
	_zone_overlay.setup(scenario_data)


## Senaryoda önceden tanımlı arazi parçalarını (siper vb.) sahaya kurar.
## Kayıt TerrainManager'da; bu fonksiyon yalnız senaryo verisini ona aktarır.
func _spawn_terrain(scenario_data) -> void:
	TerrainManager.clear_all()
	TerrainManager.container = self
	if scenario_data == null or not ("terrain_placements" in scenario_data):
		return
	for tp in scenario_data.terrain_placements:
		if tp == null or tp.feature == null:
			continue
		TerrainManager.spawn_feature(tp.feature, tp.position, "", tp.rotation_y)

func _spawn_objective_markers(scenario_data):
	for m in objective_markers:
		if is_instance_valid(m):
			m.queue_free()
	objective_markers.clear()
	if scenario_data == null:
		return
	# RELIC HUNT: farklı marker sahnesi (RelicMarker, Reliquary 3D asset'leri) — ObjectiveMarker'ın
	# sabit bayrak modeli DEĞİL. Görsel API'leri (setup/set_controller) kasıtlı OLUŞTURMA ARAYÜZÜ
	# ile eşleşir ki _update_objective_markers değişmeden ikisini de sürebilsin.
	var is_relic_hunt: bool = scenario_data.scenario_id == &"relic_hunt"
	var relic_idx := 0
	for obj_res in scenario_data.objectives:
		var obj := obj_res as ScenarioObjective
		if obj == null:
			continue
		var marker
		if is_relic_hunt:
			marker = RELIC_MARKER_SCENE.instantiate()
			add_child(marker)
			var model_path: String = RELIC_MODEL_PATHS[relic_idx % RELIC_MODEL_PATHS.size()]
			relic_idx += 1
			marker.setup(obj, model_path)
		else:
			marker = OBJECTIVE_MARKER_SCENE.instantiate()
			add_child(marker)
			marker.setup(obj)
		objective_markers.append(marker)
	_update_objective_markers()

## Objective/Reliquary marker'larının kontrol rengini (ve Relic Hunt'ta kaldırılma durumunu) günceller.
func _update_objective_markers():
	if ScenarioManager.logic == null:
		return
	for i in range(objective_markers.size()):
		var marker = objective_markers[i]
		if not is_instance_valid(marker):
			continue
		if i < ScenarioManager.active_scenario.objectives.size():
			var obj := ScenarioManager.active_scenario.objectives[i] as ScenarioObjective
			if obj != null:
				marker.set_controller(ScenarioManager.logic.get_persistent_objective_controller(obj))
				if marker.has_method("set_removed") and ScenarioManager.logic.has_method("is_reliquary_removed"):
					marker.set_removed(ScenarioManager.logic.is_reliquary_removed(obj.objective_id))

func _on_turn_changed_markers(_active_player_id: int):
	_update_objective_markers()

func _on_deployment_completed():
	GameLogger.log_info("Yerleşim aşaması bitti. Savaş (BATTLE) aşamasına geçiliyor. Sıralar başlatılıyor.", "GAME")
	if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
		# MARKED FOR DEATH: her iki oyuncunun ilk Bounty Target'ı (sahadaki en pahalı model) burada
		# kilitlenir — deployment BİTMEDEN sahadaki roster kesin değil, bu yüzden burası doğru an.
		if ScenarioManager.logic is MarkedForDeathLogic:
			ScenarioManager.logic.establish_bounty_targets()
		TurnManager.start_turns()

func _process(delta: float) -> void:
	# Objective marker renklerini belirli aralıklarla güncelle (birim hareketi sırasında da bayrak rengi değişsin)
	if objective_markers.is_empty() or ScenarioManager.logic == null:
		return
	_objective_update_timer += delta
	if _objective_update_timer >= OBJECTIVE_UPDATE_INTERVAL:
		_objective_update_timer = 0.0
		_update_objective_markers()

@rpc("any_peer", "call_local", "reliable")
func request_finish_deployment():
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		rpc_id(1, "request_finish_deployment")
		return
		
	var sender_id = 1
	if multiplayer.has_multiplayer_peer():
		var real_sender_id = multiplayer.get_remote_sender_id()
		if real_sender_id == 0:
			real_sender_id = 1
		sender_id = NetworkManager.canonical_for_peer(real_sender_id)
	else:
		sender_id = GameState.active_deployer_id

	if GameState.game_phase != GameState.GamePhase.DEPLOYMENT:
		return

	# WARBAND HAZIR MI? Bazı faksiyonlarda warband kurulurken belirli bir liderin BULUNMASI
	# zorunludur (Court "Nobles of the Court", Grail "The Order of the Fly"). Sayım burada,
	# karar RosterRules.warband_ready()'de.
	var _ready_err: String = _warband_readiness_error(sender_id)
	if _ready_err != "":
		GameLogger.log_warn("Yerleşim bitirilemedi (Oyuncu %d): %s" % [sender_id, _ready_err], "GAME")
		_reject_deploy(sender_id, _ready_err)
		return

	GameState.finish_player_deployment(sender_id)

## Oyuncunun warband'ı compendium'a göre sahaya çıkmaya hazır mı? Boş string = hazır.
## Yalnız SAYIM yapar; kural kararı RosterRules'a aittir (game.gd god-file'a dönüşmesin).
## Bu birim şu an yerleştirilebilir mi? "" = evet, dolu = ret sebebi lokalizasyon anahtarı.
## Karar ve sayım DeployAvailability'de (saf/testli); burada yalnız UI'ın çağırabileceği
## bir sarmalayıcı var.
func deploy_block_reason(player_id: int, unit_data: Resource) -> String:
	return DeployAvailability.block_reason(player_id, unit_data)

func _warband_readiness_error(player_id: int) -> String:
	var faction = GameState.get_faction_for_player(player_id)
	if faction == null:
		return ""
	var counts := {
		"praetor": 0, "sorcerer": 0, "lord": 0, "knight": 0, "leader": 0,
		"leader_choice": (faction.leader_choice if ("leader_choice" in faction) else &""),
	}
	for u in UnitQuery.roster_of(player_id):
		if u.unit_data == null:
			continue
		if u.unit_data.is_leader:
			counts["leader"] += 1
		match u.unit_data.unit_name:
			"Praetor": counts["praetor"] += 1
			"Sorcerer": counts["sorcerer"] += 1
			"Lord of Tumours": counts["lord"] += 1
			"Plague Knight": counts["knight"] += 1
	return RosterRules.warband_ready(faction.faction_id, counts)

## Host/aktif oyuncu bir faksiyon seçtiğinde çağrılır. Sunucu otoritesi + tüm eşlere yayın —
## KÖK NEDEN DÜZELTMESİ: önceden game_hud.gd doğrudan GameState.select_faction()'ı YEREL çağırıyordu,
## hiçbir RPC yoktu; gerçek 2 cihazlı multiplayer'da sunucu istemcinin seçtiği faksiyonu HİÇBİR ZAMAN
## öğrenmiyordu (request_deploy_unit'te player_faction her zaman null → REASON_NO_FACTION ile
## SÜREKLİ reddediliyordu). Artık diğer request_* fonksiyonlarıyla AYNI desen.
@rpc("any_peer", "call_local", "reliable")
func request_select_faction(faction_id: StringName) -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		rpc_id(1, "request_select_faction", faction_id)
		return

	var sender_id = 1
	if multiplayer.has_multiplayer_peer():
		var real_sender_id = multiplayer.get_remote_sender_id()
		if real_sender_id == 0:
			real_sender_id = 1
		sender_id = NetworkManager.canonical_for_peer(real_sender_id)
	else:
		sender_id = GameState.active_deployer_id

	if GameState.game_phase != GameState.GamePhase.DEPLOYMENT:
		return

	var faction: Resource = GameState.get_faction_by_id(faction_id)
	if faction == null:
		return

	RpcHelper.sync(GameState, "sync_player_faction", [sender_id, faction.resource_path])

@rpc("any_peer", "call_local", "reliable")
func request_deploy_unit(unit_data_path: String, target_pos: Vector3, loadout_index: int = -1):
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		rpc_id(1, "request_deploy_unit", unit_data_path, target_pos, loadout_index)
		return

	# İKİ FARKLI KİMLİK — karıştırmak gerçek bir bug kaynağıydı (bkz. DeployRequest):
	#   real_sender_id : RPC ADRESLEME için, GERÇEK ENet peer id'si (ret bildirimi buna gider).
	#   sender_id      : OYUN MANTIĞI için, kanonik 1/2.
	var real_sender_id := 1
	var sender_id := GameState.active_deployer_id
	if multiplayer.has_multiplayer_peer():
		real_sender_id = multiplayer.get_remote_sender_id()
		if real_sender_id == 0:
			real_sender_id = 1
		sender_id = NetworkManager.canonical_for_peer(real_sender_id)

	# 16 ret kapısının TAMAMI `DeployFlow`da — hangi kuralın hangi sırada işlediği
	# `DeployFlow.validate()` okununca tek ekranda görünür.
	var built: Dictionary = DeployFlow.build(sender_id, real_sender_id, unit_data_path,
		target_pos, loadout_index, get_world_3d().navigation_map)
	var req: DeployRequest = built["req"]
	if req == null:
		_reject_deploy(real_sender_id, built["reason"])
		return

	var reason: String = DeployFlow.validate(req)
	if reason != "":
		_reject_deploy(real_sender_id, reason)
		return

	_spawn_deployed_unit(req)

## Doğrulamayı GEÇEN bir isteği sahaya koyar. Çok oyunculuda MultiplayerSpawner, tek oyunculuda
## doğrudan instantiate — iki yolda da `GameState.deploy_unit` ile bütçe/sayım güncellenir.
func _spawn_deployed_unit(req: DeployRequest) -> void:
	var deployed_so_far: int = GameState.player_deployed_count.get(req.sender_id, 0)
	var u_name := "%s_%d" % [req.unit_data.unit_name.replace(" ", "_"), deployed_so_far + 1]
	var spawn_pos := req.spawn_position()
	GameLogger.log_info("Birim yerleştiriliyor: %s (Oyuncu %d) konum: %s" \
		% [u_name, req.sender_id, str(spawn_pos)], "GAME")

	var unit
	if multiplayer.has_multiplayer_peer():
		unit = $MultiplayerSpawner.spawn({
			"owner_id": req.sender_id,
			"u_name": u_name,
			"pos": spawn_pos,
			"unit_data_path": req.unit_data_path,
			"loadout_index": req.loadout_index,
		})
		UnitDeployHooks.run_first_deploy(unit)
	else:
		unit = unit_scene.instantiate()
		unit.name = "Unit_%d_%s" % [req.sender_id, u_name]
		units_container.add_child(unit, true)
		unit.global_position = spawn_pos
		unit.init_unit(req.sender_id, req.unit_data_path, req.loadout_index)
	GameState.deploy_unit(req.sender_id, unit, req.resolved_data.cost, req.resolved_data)


## Yerleştirme reddini oyuncuya bildirir: yerelde/sunucuda doğrudan olay yayınlar; çok oyunculuda
## reddedilen uzak istemciye RPC ile ulaştırır. HUD bu sinyali dinleyip kısa bir toast gösterir.
func _reject_deploy(sender_id: int, reason_key: String) -> void:
	if multiplayer.has_multiplayer_peer() and sender_id != 1:
		rpc_id(sender_id, "client_notify_deploy_rejected", reason_key)
	else:
		GameEvents.deploy_rejected.emit(reason_key)

@rpc("authority", "call_remote", "reliable")
func client_notify_deploy_rejected(reason_key: String) -> void:
	GameEvents.deploy_rejected.emit(reason_key)

func _on_unit_spawned(data: Dictionary) -> Node:
	var unit = unit_scene.instantiate()
	unit.name = "Unit_%d_%s" % [data.owner_id, data.u_name]
	unit.owner_id = data.owner_id
	# HATA DÜZELTMESİ: MultiplayerSpawner bu fonksiyonun DÖNDÜRDÜĞÜ node'u ancak fonksiyon
	# bittikten SONRA ağaca ekliyor — bu noktada unit henüz is_inside_tree() değil, global_position
	# ataması "Condition '!is_inside_tree()' is true" hatası veriyordu (konsolda gözlemlendi).
	# spawn_path her zaman "../Units" (kimlik dönüşümlü, ölçeksiz) olduğundan position==global_position
	# — ağaca eklenmeden de güvenle atanabilir.
	unit.position = data.pos

	var unit_data_res = load(data.unit_data_path)
	if unit_data_res:
		var loadout_index: int = data.get("loadout_index", -1)
		unit.unit_data = LoadoutResolver.resolve_loadout(unit_data_res, loadout_index)
		unit.chosen_loadout_index = loadout_index
		unit.unit_data_path = data.unit_data_path
		unit.apply_unit_data()
		UnitDeployHooks.apply_loadout_side_effects(unit)

	GameLogger.log_info("Çok oyunculu modda birim spawn edildi: " + unit.name, "GAME")
	return unit
