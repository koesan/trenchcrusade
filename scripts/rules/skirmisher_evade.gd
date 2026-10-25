## SKIRMISHER (comprehensive-rules/keyword.md): "If an enemy selects a model with this Keyword as the
## target of a Charge, you CAN CHOOSE to evade with your model before the Charge is made, as long as
## your model is not within 1" of an enemy. When a model evades, roll a D3 and move the model that
## many inches. It must finish this move more than 1" away from all enemy models. If this move
## results in there being an interposing model between the evading model and the model that is
## making the charge, then the charging model must choose the interposing model as the target."
##
## Önceki uygulama kaçışı OTOMATİK yapıyor ve yönü hücum edenden uzağa sabitliyordu; araya giren
## model kontrolü kaçıştan ÖNCE yapıldığı için kaçışın yarattığı araya girme yok sayılıyordu.
## Artık kaçış hedefin sahibine sorulur, yönü (D3 dairesinde) o seçer; hücum, kaçıştan sonra araya
## giren modele yönlendirilir.
class_name SkirmisherEvade
extends RefCounted


## Kaçış uygunsa sorar ve uygular. Döner: hücumun yeni hedefi (araya giren model) ya da `enemy`.
static func resolve(charger, enemy):
	if enemy.unit_data == null or not KeywordSystem.has(enemy.unit_data, &"skirmisher") or enemy.is_engaged():
		return enemy
	if not await CombatChoice.request_skirmisher_evade(enemy, charger.display_name):
		return enemy
	var d3: int = randi_range(1, 3)
	var map_rid = charger.get_world_3d().navigation_map
	var picked = await CombatChoice.request_position_pick(enemy, float(d3), "SKIRMISHER_EVADE_PICK")
	var raw: Vector3 = picked if picked is Vector3 else default_evade_point(charger.global_position, enemy.global_position, d3)
	# Tıklama D3 dairesinin dışına taşabilir — yol boyunca en çok D3" (NavMesh).
	raw = MovementHelper.keep_base_clearance(enemy, map_rid, MovementHelper.get_clamped_target(map_rid, enemy.global_position, raw, float(d3)))
	var evade_final: Vector3 = MovementHelper.enforce_retreat_clearance(enemy, map_rid, raw, float(d3))
	enemy.global_position = evade_final
	RpcHelper.sync(enemy, "client_update_move", [evade_final])
	GameLogger.log_info("[Skirmisher] %s hücumdan kaçtı (D3=%d)." % [enemy.display_name, d3], "MOVEMENT")
	var interposer = MechanicsResolver.charge_interposing_enemy(charger, enemy)
	if interposer != null:
		GameLogger.log_info("[Skirmisher] Kaçış sonrası %s araya girdi — hücum ona yöneltildi." \
			% interposer.display_name, "MOVEMENT")
		return interposer
	return enemy


## Seçim yapılamadığında (arayüz yok / iptal) varsayılan kaçış noktası: hücum edenden uzağa düz D3".
static func default_evade_point(charger_pos: Vector3, enemy_pos: Vector3, d3: int) -> Vector3:
	var away: Vector3 = enemy_pos - charger_pos
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3(1, 0, 0)
	return enemy_pos + away * float(d3)
