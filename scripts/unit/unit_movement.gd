## UnitMovement
## Birimin hareket, yol izleme ve alan göstergelerini yöneten alt sınıf.
class_name UnitMovement
extends RefCounted

var unit: CharacterBody3D

func _init(p_unit: CharacterBody3D):
	unit = p_unit

## Göstergeleri günceller. Kural: aynı anda YALNIZCA ilgili alan gösterilir —
## birim seçili & eylem yok/move/retreat → hareket alanı; attack → silah menzili;
## charge → hücum erişim menzili. Ayrıca her düşman için "geçerli hedef" vurgusu hesaplanır.
func update_indicators():
	if unit.range_indicator and unit.range_indicator.has_method("hide_visuals"):
		unit.range_indicator.hide_visuals()
	if unit.attack_range_indicator and unit.attack_range_indicator.has_method("hide_visuals"):
		unit.attack_range_indicator.hide_visuals()

	if GameState.selected_unit == unit:
		var is_my_turn_unit = unit.owner_id == TurnManager.current_turn_player_id
		var is_local_valid = not unit.multiplayer.has_multiplayer_peer() or unit.owner_id == NetworkManager.get_local_canonical_id()
		if is_my_turn_unit and is_local_valid and not unit.has_moved:
			var action: String = GameState.selected_action
			if action == "attack":
				var atk = unit._get_selected_attack()
				if atk and unit.attack_range_indicator and unit.attack_range_indicator.has_method("show_visuals"):
					unit.attack_range_indicator.show_visuals(unit, atk.attack_range)
			elif action == "charge":
				# Hücum erişimi = Movement + azami D6, tavan 12" (compendium)
				var charge_r: float = min(unit.speed + 6.0, GameState.CHARGE_DISTANCE_CAP)
				if unit.attack_range_indicator and unit.attack_range_indicator.has_method("show_visuals"):
					unit.attack_range_indicator.show_visuals(unit, charge_r)
			elif action != "" and _find_selected_ability(unit, action) != null:
				# YETENEK menzili: dost/düşman hedefli yetenek seçiliyken menzil halkasını göster
				# (range_meters>0). Böylece oyuncu "nereye kadar hedefleyebilirim"i görür.
				var ab: AbilityData = _find_selected_ability(unit, action)
				if ab.range_meters > 0.0 and unit.attack_range_indicator \
						and unit.attack_range_indicator.has_method("show_visuals"):
					unit.attack_range_indicator.show_visuals(unit, ab.range_meters)
			else:
				# move / retreat / seçim yok → hareket alanı (yalnız hâlâ hareket edilebiliyorsa)
				if (unit.can_perform_action("move") or unit.is_dash_pending) \
						and unit.range_indicator and unit.range_indicator.has_method("show_visuals"):
					unit.range_indicator.show_visuals(unit)

	_update_target_highlight()

## Bu birim, seçili birimin mevcut attack/charge eylemi için geçerli bir hedef mi? Vurguyu günceller.
func _update_target_highlight():
	var new_val: bool = _compute_is_valid_target()
	var new_cover: bool = new_val and _compute_target_in_cover()
	if new_val != unit.is_valid_target or new_cover != unit.is_cover_highlighted:
		unit.is_valid_target = new_val
		unit.is_cover_highlighted = new_cover
		unit.update_selection_ring()

## P2-5: bu birim (geçerli menzilli hedef) siperde mi? DicePoolBuilder Cover mantığını yansıtır
## (LoS kısmi engel VEYA hedef Fortify/Cover aktif; ignore_cover silahlarda gösterilmez). Melee'de
## Cover görseli yok (Defended Obstacle ayrı). Yalnız saha-üstü şeffaflık; mekaniği DEĞİŞTİRMEZ.
func _compute_target_in_cover() -> bool:
	var sel = GameState.selected_unit
	if sel == null or not is_instance_valid(sel) or GameState.selected_action != "attack":
		return false
	var atk = sel._get_selected_attack()
	if atk == null or atk.attack_type == "MELEE" or atk.ignore_cover:
		return false
	var los = sel.get_line_of_sight_status(unit)
	if los.get("in_cover", false):
		return true
	if "has_fortify_cover" in unit and unit.has_fortify_cover:
		return true
	# Arazi kaynaklı Cover (siper) — DicePoolBuilder ile AYNI kaynağı okur ki
	# saha görseli mekanikle çelişmesin.
	return TerrainManager.has_keyword_at(unit.global_position, &"cover")

func _compute_is_valid_target() -> bool:
	# Harita seçimi (ikinci el / Cleave / komut hedefi): yalnız tıklanabilir adaylar vurgulanır.
	if GameState.pick_mode == "enemy_unit":
		return UnitQuery.is_pick_candidate(unit)
	var sel = GameState.selected_unit
	if sel == null or sel == unit or not is_instance_valid(sel):
		return false
	if unit.current_health <= 0:
		return false
	# Yalnız aktif oyuncunun birimi seçiliyken vurgula
	if sel.owner_id != TurnManager.current_turn_player_id:
		return false
	var action: String = GameState.selected_action
	if action == "attack":
		var atk = sel._get_selected_attack()
		if atk == null:
			return false
		# WHIP OF GOD / TORTURER: melee'de dost hedef seçilebilir (CombatResolver ile tek kaynak).
		var allow_friendly: bool = atk.attack_type == "MELEE" \
			and CombatResolver.allows_friendly_melee_target(sel.unit_data, unit.unit_data)
		if unit.owner_id == sel.owner_id and not allow_friendly:
			return false
		var dist: float = sel.global_position.distance_to(unit.global_position)
		if dist > atk.attack_range + GameState.ATTACK_RANGE_TOLERANCE:
			return false
		# Görüş hattı her saldırıda gerekir (yakın dövüş dâhil — CombatResolver ile aynı).
		if sel.get_line_of_sight_status(unit).get("is_blocked", false):
			return false
		if atk.attack_type != "MELEE":
			# HIDE: saklanan hedef menzilli saldırıyla vurgulanmaz.
			if unit.has_method("is_untargetable_by") and unit.is_untargetable_by(sel):
				return false
		return true
	elif action == "charge":
		if unit.owner_id == sel.owner_id:
			return false
		var dist: float = sel.global_position.distance_to(unit.global_position)
		if dist > GameState.CHARGE_DISTANCE_CAP:
			return false
		var los = sel.get_line_of_sight_status(unit)
		if los.is_blocked:
			return false
		# HIDE: saklanan hedefe hücum vurgusu yapılmaz.
		if unit.has_method("is_untargetable_by") and unit.is_untargetable_by(sel):
			return false
		return true
	elif action != "":
		# YETENEK hedefleme affordance'ı: seçili aksiyon dost/düşman hedefli bir yetenekse,
		# geçerli hedefler (dost VEYA düşman, yeteneğe göre) vurgulanır. "Buton basınca bir şey
		# olmuyor" sorununun görsel çözümü — oyuncu hangi birime tıklayacağını görür.
		var ab: AbilityData = _find_selected_ability(sel, action)
		return AbilityExecutor.is_valid_ability_target(ab, sel, unit)
	return false

## sel biriminin seçili action_key'e karşılık gelen yeteneğini bulur (yoksa null).
func _find_selected_ability(sel, action_key: String) -> AbilityData:
	if sel.unit_data == null:
		return null
	for ability_res in sel.unit_data.abilities:
		var ab: AbilityData = ability_res as AbilityData
		if ab != null and ab.action_key == action_key:
			return ab
	return null

func physics_process(delta: float):
	if unit.is_selected and unit.selection_ring:
		unit.selection_ring.rotate_y(delta * 2.0)
		var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.08
		unit.selection_ring.scale = Vector3(pulse, 1.0, pulse)

	if unit.is_moving:
		AudioManager.start_move_loop()  # idempotent: hareket boyunca tok sürükleme sesi
		if unit.path_index < unit.current_path.size():
			var next_point = unit.current_path[unit.path_index]
			unit.global_position = unit.global_position.move_toward(next_point, unit.move_speed * delta)

			var dir = (next_point - unit.global_position).normalized()
			dir.y = 0.0
			if dir.length_squared() > 0.001:
				var look_target = unit.global_position + dir
				if not unit.global_position.is_equal_approx(look_target):
					unit.look_at(look_target, Vector3.UP)

			if unit.global_position.is_equal_approx(next_point):
				unit.path_index += 1
		else:
			GameLogger.log_info("%s hareketini tamamladı. Yeni konum: %s" % [unit.display_name, str(unit.global_position)], "MOVEMENT")
			unit.is_moving = false
			unit.current_path.clear()
			AudioManager.stop_move_loop()  # hareket bitti → sürükleme sesini kes

			update_indicators()

			# DETONATING MINES (iron-sultanate.md / new-antioch.md): "When a model moves into
			# contact with a Mined terrain piece, the mine will detonate unless the model is the
			# one that set the mine, or has the Defuse Mine ability." Karar MineResolver'da,
			# yürütme MineActions'ta — burada yalnız kanca var.
			MineActions.check_step_on_mine(unit)
			# DANGEROUS TERRAIN (keyword.md): "if you move a model into terrain with this Keyword
			# during a move, you must take a [Risky Success] Roll... If the roll is a Failure, you
			# must make an Injury Roll for the model and its Activation ends." Mayın bunun ÖZEL bir
			# hâlidir; genel kural artık her `[Dangerous Terrain]` parçası için işliyor.
			TerrainRules.check_dangerous_terrain(unit)

			# FORTIFY / DUG IN: "the model has [Cover] UNTIL THEY MOVE AWAY FROM THEIR CURRENT
			# POSITION." Mevzi terk edildi → yalnız [Cover] AVANTAJI düşer. Kazılan siper bir
			# arazi parçasıdır ve sahada KALIR (birimin peşinden taşınmaz).
			if unit.has_fortify_cover:
				unit.has_fortify_cover = false
				if unit.multiplayer.has_multiplayer_peer():
					unit.rpc("sync_ability_flags", unit.is_hidden, unit.has_fortify_cover,
						unit.shadow_walker_active, unit.slashing_attack_active)

			# Compendium: Charge SONRASI Fight AYRI bir aksiyondur (otomatik saldırı YOK).
			# Hareket sonrası angaje durumu değişmiş olabilir → aksiyon panelini tazele ki
			# Fight/Shoot uygunluğu doğru gösterilsin.
			if GameState.selected_unit == unit:
				GameState.unit_selected.emit(unit)
			unit.check_activation_complete()
