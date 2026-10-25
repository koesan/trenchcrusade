extends Node

## Harita girdi yöneticisi.
## Sol fare tıklamasıyla raycast yaparak birim seçimi, hareket ve yerleşim komutlarını yönetir.

@export var camera_path: NodePath
@onready var camera = get_node(camera_path) if camera_path else null

## Atış Breakdown Kartı için üzerine gelinen (hover) birim.
var _hovered_unit = null

func _unhandled_input(event):
	if not GameState.is_game_active:
		return

	# P1-1: reaktif harita-seçim modu (Time Slip yeniden konuşlanma / Temporal Assassin 2. hedef)
	# aktifken Esc ile iptal edilebilir (harcanmaz, hiçbir şey olmaz — güvenli varsayılan).
	if GameState.pick_mode != "" and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		GameState.cancel_pick()
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_left_click(event.position)
	elif event is InputEventMouseMotion:
		_update_hover(event.position)

## Kamera 3D düğümünü döndürür (tüm raycast'ler için ortak).
func _get_camera_3d() -> Camera3D:
	var cam_node = camera
	if camera and camera.has_method("get_camera_3d"):
		cam_node = camera.get_camera_3d()
	elif not cam_node or cam_node is not Camera3D:
		cam_node = get_viewport().get_camera_3d()
	return cam_node

## Fare konumundan raycast ile bir birim (unit) döndürür (yoksa null).
func _raycast_unit(mouse_pos: Vector2):
	var cam_node = _get_camera_3d()
	if not cam_node:
		return null
	var from = cam_node.project_ray_origin(mouse_pos)
	var to = from + cam_node.project_ray_normal(mouse_pos) * 1000.0
	var space_state = cam_node.get_world_3d().direct_space_state
	var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	if result:
		return _find_unit_parent(result.collider)
	return null

## Atış eylemi seçiliyken düşman üzerine gelince Atış Breakdown Kartını gösterir/gizler.
## (Birim bilgi kartı, alttaki unit kartlarının hover'ında gösterilir — unit_cards_container.)
##
## Kullanıcı bildirimi: "unitler çok iç içe geçince saldırı yapacağım hangi unite saldıracağı
## belli değil... rastgele saldırıyor gibiyim, kimi seçtiğim/kime saldırdığım belli olsun."
## unit.gd zaten "targeted" (parlak, ayırt edici) bir seçim halkası taşıyordu (set_targeted/
## is_targeted, update_selection_ring'de EN YÜKSEK öncelikli renk) ama hiçbir yerden ÇAĞRILMIYORDU
## — fare imlecinin altındaki birim görsel olarak hiç ayırt edilmiyordu. Artık bir eylem seçiliyken
## (attack/charge/yetenek) imlecin altındaki GEÇERLİ hedef (zaten dim halkalı is_valid_target'lardan
## biri) parlak "targeted" halkasını alır — oyuncu tıklamadan ÖNCE tam olarak neyi vuracağını görür.
func _update_hover(mouse_pos: Vector2):
	var attacker = GameState.selected_unit
	var hit = _raycast_unit(mouse_pos)

	if GameState.pick_mode == "enemy_unit":
		var cand = _pick_candidate_at(mouse_pos, hit)
		if cand != _hovered_unit:
			_clear_hover_highlight()
			_hovered_unit = cand
			if cand != null:
				cand.set_targeted(true)
		return

	if attacker == null or GameState.selected_action == "":
		if _hovered_unit != null:
			_clear_hover_highlight()
			_hud_call("hide_shot_breakdown")
		_hovered_unit = hit
		return

	if hit == _hovered_unit:
		return

	_clear_hover_highlight()
	_hovered_unit = hit

	var action: String = GameState.selected_action
	if action == "attack":
		if hit != null and hit != attacker and hit.owner_id != attacker.owner_id and hit.current_health > 0:
			_hud_call("show_shot_breakdown", [attacker, hit])
		else:
			_hud_call("hide_shot_breakdown")
	elif action == "charge":
		if hit != null and hit != attacker and hit.owner_id != attacker.owner_id and hit.current_health > 0:
			_hud_call("show_charge_breakdown", [attacker, hit])
		else:
			_hud_call("hide_shot_breakdown")
	elif action != "":
		# Kullanıcı isteği: "yetenek seçince unit üstüne gelen popup'ta da aynı şekilde gerekli
		# bilgiler olsun." is_valid_ability_target ile AYNI kaynak (hedef vurgusuyla tutarlı).
		var ability: AbilityData = _find_ability_by_key(attacker, action)
		if is_instance_valid(hit) and AbilityExecutor.is_valid_ability_target(ability, attacker, hit):
			_hud_call("show_ability_breakdown", [attacker, hit, ability, "ACTION_" + action.to_upper()])
		else:
			_hud_call("hide_shot_breakdown")

	# Parlak "targeted" vurgu: yalnız zaten geçerli-hedef (dim halkalı) bir birimse — imlecin
	# rastgele geçtiği alakasız bir birime yanlışlıkla parlak halka takılmaz.
	if is_instance_valid(hit) and hit.has_method("set_targeted") and "is_valid_target" in hit and hit.is_valid_target:
		hit.set_targeted(true)

## Önceki hover hedefinin parlak halkasını söndürür (yeni hover'a geçerken ya da eylem/seçim
## değiştiğinde çağrılır — birden fazla birimde AYNI ANDA parlak halka kalmaz).
func _clear_hover_highlight() -> void:
	if is_instance_valid(_hovered_unit) and _hovered_unit.has_method("set_targeted"):
		_hovered_unit.set_targeted(false)

func _hud_call(method: String, args: Array = []):
	var game_node = get_tree().current_scene
	if game_node:
		var hud = game_node.get_node_or_null("GameHUD")
		if hud and hud.has_method(method):
			hud.callv(method, args)

func _handle_left_click(mouse_pos: Vector2):
	var cam_node = camera
	if camera and camera.has_method("get_camera_3d"):
		cam_node = camera.get_camera_3d()
	elif not cam_node or cam_node is not Camera3D:
		cam_node = get_viewport().get_camera_3d()
		
	if not cam_node:
		return
			
	var from = cam_node.project_ray_origin(mouse_pos)
	var to = from + cam_node.project_ray_normal(mouse_pos) * 1000.0
	
	var space_state = cam_node.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	# P1-1: reaktif harita-seçim modu aktifken tıklama normal akışın YERİNE bu isteği çözer
	# (Time Slip yeniden konuşlanma noktası / Temporal Assassin 2. hedef seçimi).
	if GameState.pick_mode != "":
		_resolve_active_pick(result, mouse_pos)
		return

	if result:
		var hit_collider = result.collider
		var hit_point = result.position
		
		var clicked_unit = _find_unit_parent(hit_collider)
		
		if clicked_unit:
			var active_player = TurnManager.current_turn_player_id
			
			if GameState.game_phase == GameState.GamePhase.DEPLOYMENT:
				# Yerleşim aşamasında birim seçilemez
				return
				
			var my_unit = GameState.selected_unit
			if my_unit != null and my_unit.owner_id == active_player:
				var action: String = GameState.selected_action
				var is_enemy_target: bool = clicked_unit.owner_id != active_player

				if action == "attack":
					# WHIP OF GOD (Castigator) gibi keyword'ler dost hedefe saldırıya izin verebilir;
					# CombatResolver.validate_attack() nihai kararı verir, burada sadece izin veriyoruz.
					var allow_friendly: bool = my_unit.unit_data != null \
						and KeywordSystem.has(my_unit.unit_data, &"whip_of_god")
					if is_enemy_target or allow_friendly:
						my_unit.request_attack_action(clicked_unit, my_unit.selected_attack_index)
						GameState.selected_action = ""
						_refresh_hud(my_unit)
						return
				elif action == "charge" and is_enemy_target:
					my_unit.request_charge_action(clicked_unit)
					GameState.selected_action = ""
					_refresh_hud(my_unit)
					return
				elif action == "move" or my_unit.is_dash_pending:
					# Kullanıcı isteği: "Hareket'e basıyorum, bir düşmana/dosta tıklarsam o yöne
					# doğru gitsin, menzil bitince dursun" — beyaz alan içinde ayrıca boş bir nokta
					# seçmeye ZORLANMASIN. request_move_action zaten mesafeyi kendi menziline göre
					# clamp'liyor (MovementHelper.get_clamped_target); DÜŞMAN hedefte ayrıca
					# ENGAGE_RANGE kadar geride durdurulur — aksi halde standart Move, "düşmanın 1
					# inç yakınına giremez (Charge gerekir)" kuralına takılıp TAMAMEN reddedilirdi.
					my_unit.request_move_action(_move_click_target(my_unit, clicked_unit, is_enemy_target))
					GameState.selected_action = ""
					_refresh_hud(my_unit)
					return
				elif action == "retreat":
					my_unit.request_retreat_action(_move_click_target(my_unit, clicked_unit, is_enemy_target))
					GameState.selected_action = ""
					_refresh_hud(my_unit)
					return
				elif action != "":
					# Data-driven ability targeting: seçili action'ın AbilityData'sını bul,
					# geçerli dost/düşman hedef mi (allegiance + menzil + hayatta) — vurgu ile
					# TEK KAYNAK (AbilityExecutor.is_valid_ability_target).
					var ability: AbilityData = _find_ability_by_key(my_unit, action)
					if AbilityExecutor.is_valid_ability_target(ability, my_unit, clicked_unit):
						# AMMUNITION SACRAMENT (Mendelist Ammo Monk, P1-1): hedef seçildikten SONRA,
						# RPC gönderilmeden ÖNCE 3 seçenekli yerel bir overlay gösterilir (loadout_
						# picker ile aynı desen); seçim ability isteğine ekstra parametre olarak eklenir.
						if action == "ammunition_sacrament":
							var picked_unit = clicked_unit
							var picking_unit = my_unit
							_hud_call("show_ammunition_sacrament_picker", [picked_unit.display_name,
								func(choice: String):
									if choice != "":
										picking_unit.request_ability_action(action, picked_unit, choice)
							])
						elif action == "slavemaster":
							# SLAVEMASTER (Court of the Seven-Headed Serpent, P1-1): hedef Yoke Fiend
							# seçildikten SONRA, RPC gönderilmeden ÖNCE 4 komutluk yerel bir overlay
							# gösterilir (Ammunition Sacrament ile AYNI desen).
							var picked_yoke = clicked_unit
							var casting_unit = my_unit
							_hud_call("show_slavemaster_command_picker", [picked_yoke.display_name,
								func(choice: String):
									if choice != "":
										casting_unit.request_ability_action(action, picked_yoke, choice)
							])
						else:
							my_unit.request_ability_action(action, clicked_unit)
						GameState.selected_action = ""
						_refresh_hud(my_unit)
						return

			# Eylem seçili değilse veya kendi birimimizse seç
			_explain_selection(clicked_unit)
			GameState.select_unit(clicked_unit)
		else:
			# Haritaya tıklandıysa
			if GameState.game_phase == GameState.GamePhase.DEPLOYMENT:
				if GameState.selected_deploy_unit_type != "":
					var game_node = get_tree().current_scene
					if game_node and game_node.has_method("request_deploy_unit"):
						game_node.request_deploy_unit(GameState.selected_deploy_unit_type, hit_point,
							GameState.selected_loadout_index)
			else:
				# Savaş aşamasındaysak ve seçili birimimiz varsa hareket et
				var unit = GameState.selected_unit
				if unit != null:
					var can_act = (not multiplayer.has_multiplayer_peer() or unit.owner_id == NetworkManager.get_local_canonical_id()) and TurnManager.is_my_turn()
					if can_act:
						if GameState.selected_action == "move" or unit.is_dash_pending:
							unit.request_move_action(hit_point)
							GameState.selected_action = ""
							_refresh_hud(unit)
						elif GameState.selected_action == "retreat":
							unit.request_retreat_action(hit_point)
							GameState.selected_action = ""
							_refresh_hud(unit)
						else:
							# Data-driven: "position" hedefli ability'ler (örn. shadow_step)
							var ability: AbilityData = _find_ability_by_key(unit, GameState.selected_action)
							if ability != null and ability.target_type == "position":
								unit.request_ability_action(GameState.selected_action, hit_point)
								GameState.selected_action = ""
								_refresh_hud(unit)
							else:
								GameState.deselect_unit()
					else:
						GameState.deselect_unit()
				else:
					GameState.deselect_unit()

## Tıklanan model şu an neden oynatılamıyor? Oyuncu "seçiyorum ama hareket etmiyor" diye
## kalmasın: sıralı aktivasyon (oyuncular birer model aktive eder) sıra el değiştirdikçe bir kez,
## bu tur zaten aktive olmuş model her tıklamada bildirim akışında açıklanır.
var _turn_hint_key: String = ""
func _explain_selection(u) -> void:
	if GameState.game_phase != GameState.GamePhase.BATTLE or u.current_health <= 0:
		return
	if multiplayer.has_multiplayer_peer() and u.owner_id != NetworkManager.get_local_canonical_id():
		return
	var current: int = TurnManager.current_turn_player_id
	if u.owner_id == current:
		if u.has_moved:
			GameEvents.notice_posted.emit(LocalizationManager.tr_t("NOTICE_ALREADY_ACTIVATED") % u.display_name,
				"hint", LocalizationManager.tr_t("NOTICE_ALREADY_ACTIVATED_TITLE"))
		return
	var key: String = "%d:%d" % [TurnManager.current_round, current]
	if key == _turn_hint_key or u.has_moved:
		return
	_turn_hint_key = key
	GameEvents.notice_posted.emit(LocalizationManager.tr_t("NOTICE_TURN_ORDER") % PlayerLabel.name_of(current),
		"info", LocalizationManager.tr_t("NOTICE_TURN_ORDER_TITLE"))

## Seçim modunda imlecin altındaki aday. Işın bir çite/duvara takılsa da modelin ekrandaki
## tabanına, gövdesine ya da başına PICK_SNAP_PX yakın tıklama kabul edilir — kısmen örtülü hedef
## de seçilebilir (eskiden tıklama siperin çitine gidip "hiçbir şey olmuyordu").
const PICK_SNAP_PX := 48.0
func _pick_candidate_at(mouse_pos: Vector2, hit):
	if UnitQuery.is_pick_candidate(hit):
		return hit
	var cam: Camera3D = _get_camera_3d()
	if cam == null:
		return null
	var best = null
	var best_d: float = PICK_SNAP_PX
	for u in UnitQuery.alive():
		if not UnitQuery.is_pick_candidate(u) or cam.is_position_behind(u.global_position):
			continue
		for h in [0.2, 0.9, 1.6]:
			var d: float = cam.unproject_position(u.global_position + Vector3.UP * h).distance_to(mouse_pos)
			if d < best_d:
				best_d = d
				best = u
	return best

## P1-1: aktif harita-seçim modunu (GameState.pick_mode) çözer. "position" → herhangi bir raycast
## isabeti (zemin/duvar) yeterli, ham nokta GameState.resolve_pick'e geçirilir (sunucu tarafında
## MechanicsResolver.time_slip_position_valid ile ayrıca doğrulanır/clamp'lenir — istemciye
## güvenilmez). "enemy_unit" → yalnız CANLI bir düşman birime tıklama kabul edilir.
func _resolve_active_pick(result: Dictionary, mouse_pos: Vector2) -> void:
	if GameState.pick_mode == "enemy_unit":
		var hit: Node = _find_unit_parent(result.collider) if not result.is_empty() else null
		var picked = _pick_candidate_at(mouse_pos, hit)
		if picked != null:
			GameState.resolve_pick(picked)
		elif hit != null:
			GameEvents.ability_rejected.emit("PICK_FAIL_NOT_CANDIDATE")
		return
	if result.is_empty():
		return
	match GameState.pick_mode:
		"position":
			GameState.resolve_pick(result.position)
		"blood_drain":
			# GOETIC SPELL ödemesi (P1-1): dost VEYA düşman, canlı, uygun herhangi bir model kabul
			# edilir (eligibility/mükerrer-tıklama kontrolü GameState.resolve_blood_drain_click'te).
			var clicked_any: Node = _find_unit_parent(result.collider)
			if clicked_any == null or clicked_any.current_health <= 0:
				return
			GameState.resolve_blood_drain_click(clicked_any)

func _refresh_hud(unit):
	# Eylem tamamlandı (GameState.selected_action zaten "" yapıldı) — parlak hover halkası VE
	# atış/yetenek/hücum breakdown kartı bir sonraki fare hareketini beklemeden hemen söndürülür
	# (bkz. _update_hover notu). Aksi halde kart, eylem bitmiş olsa bile ekranda TAKILI kalırdı.
	_clear_hover_highlight()
	_hovered_unit = null
	_hud_call("hide_shot_breakdown")
	var game_node = get_tree().current_scene
	if game_node:
		var hud = game_node.get_node_or_null("GameHUD")
		if hud and hud.has_method("_rebuild_action_buttons"):
			hud._rebuild_action_buttons(unit)

## Move/Retreat sırasında bir UNITE tıklanınca gidilecek nokta. Düşman hedefte, standart hareketin
## "düşmanın 1 inç yakınına giremez" kuralına (server_request_move_action) takılmaması için hedefin
## TAM konumu değil, ENGAGE_RANGE'in biraz ötesinde (ondan önce duracak) bir nokta hedeflenir —
## gerçek mesafe zaten request_move_action/server tarafında kendi menziline göre ayrıca clamp'lenir.
## Dost hedefte bu kısıt yok, doğrudan konumuna doğru hareket edilir (server tarafı zaten güvenli).
func _move_click_target(mover: Node3D, clicked_unit: Node3D, is_enemy_target: bool) -> Vector3:
	if not is_enemy_target:
		return clicked_unit.global_position
	var dir: Vector3 = (clicked_unit.global_position - mover.global_position)
	if dir.length() < 0.001:
		return clicked_unit.global_position
	dir = dir.normalized()
	var stop_short: float = GameState.ENGAGE_RANGE + 0.2
	return clicked_unit.global_position - dir * stop_short

## unit_actions.gd::can_perform_action ile aynı desen: action_key eşleşen AbilityData'yı bulur.
func _find_ability_by_key(unit, action_key: String) -> AbilityData:
	if unit.unit_data == null:
		return null
	for ability_res in unit.unit_data.abilities:
		var ab: AbilityData = ability_res as AbilityData
		if ab != null and ab.action_key == action_key:
			return ab
	return null

func _find_unit_parent(node: Node) -> Node:
	var current = node
	while current != null:
		if current.has_method("is_unit") or current.is_in_group("units"):
			return current
		current = current.get_parent()
	return null
