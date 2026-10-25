## UnitCombat
## Birimin görüş hattı (LOS), siper durumu ve yakın chorister kontrollerini yöneten alt sınıf.
class_name UnitCombat
extends RefCounted

var unit: CharacterBody3D

func _init(p_unit: CharacterBody3D):
	unit = p_unit

func get_line_of_sight_status(target_unit) -> Dictionary:
	# P2-11: exclude listesi 5 ışın için AYNI (tüm birimler + kendisi + hedef). Ölü birimler de
	# dâhil TÜM birimler dışlanır — LoS'u yalnız STATİK arazi engellemeli.
	var excludes: Array = [unit.get_rid(), target_unit.get_rid()]
	for u in UnitQuery.all():
		excludes.append(u.get_rid())
	var blocked_count: int = blocked_samples(unit.get_world_3d().direct_space_state,
		unit.global_position, target_unit.global_position, excludes)
	return {
		"is_blocked": blocked_count == SAMPLE_COUNT,
		"in_cover": blocked_count > 0 and blocked_count < SAMPLE_COUNT
	}

const SAMPLE_COUNT := 5

## `from_base`teki bir modelin gözünden `to_base`teki model siluetinin 5 örnek noktasından (merkez,
## üst, alt, sol, sağ) kaçının statik araziyle engellendiği. Birim düğümü gerektirmez — yerleşim
## (Infiltrator: "out of line of sight of all enemies") de aynı ölçümü kullanır.
static func blocked_samples(space_state, from_base: Vector3, to_base: Vector3, excludes: Array) -> int:
	var from = from_base + Vector3(0, 1.4, 0)
	var dir = (to_base - from_base).normalized()
	var perp = Vector3(-dir.z, 0, dir.x).normalized()
	var targets = [
		to_base + Vector3(0, 1.0, 0), # Center
		to_base + Vector3(0, 1.7, 0), # Top
		to_base + Vector3(0, 0.3, 0), # Bottom
		to_base + Vector3(0, 1.0, 0) + perp * 0.45, # Left
		to_base + Vector3(0, 1.0, 0) - perp * 0.45  # Right
	]
	var blocked_count := 0
	for to_pos in targets:
		var query = PhysicsRayQueryParameters3D.create(from, to_pos)
		query.exclude = excludes
		if space_state.intersect_ray(query):
			blocked_count += 1
	return blocked_count

func is_target_in_cover(target_unit) -> bool:
	var status = get_line_of_sight_status(target_unit)
	return status.in_cover or status.is_blocked

