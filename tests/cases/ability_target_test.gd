extends RefCounted

## AbilityExecutor.is_valid_ability_target — dost/düşman hedefli yeteneğin geçerli hedef predikatı.
## Tek kaynak: _validate (yürütme), _compute_is_valid_target (vurgu) ve map_input (tıklama) bunu
## kullanır. Böylece dost/düşman yetenek seçilince geçerli hedefler VURGULANABİLİR (affordance).

const AbilityExecutor = preload("res://scripts/rules/ability_executor.gd")
const AbilityData = preload("res://scripts/data/ability_data.gd")

class _Stub:
	var owner_id: int = 1
	var current_health: int = 10
	var global_position: Vector3 = Vector3.ZERO

func _ab(ttype: String, same_faction: bool, rng: float = 0.0, must_alive: bool = true) -> AbilityData:
	var a := AbilityData.new()
	a.target_type = ttype
	a.target_same_faction = same_faction
	a.range_meters = rng
	a.target_must_be_alive = must_alive
	return a

func run(t) -> void:
	var caster := _Stub.new()
	caster.owner_id = 1

	var ally := _Stub.new()
	ally.owner_id = 1
	var enemy := _Stub.new()
	enemy.owner_id = 2

	# Dost hedefli yetenek: dost geçerli, düşman değil.
	var friendly := _ab("friendly", true)
	t.ok(AbilityExecutor.is_valid_ability_target(friendly, caster, ally),
		"Dost yetenek → dost hedef geçerli")
	t.ok(not AbilityExecutor.is_valid_ability_target(friendly, caster, enemy),
		"Dost yetenek → düşman hedef geçersiz")

	# Düşman hedefli yetenek: düşman geçerli, dost değil.
	var enemy_ab := _ab("enemy", false)
	t.ok(AbilityExecutor.is_valid_ability_target(enemy_ab, caster, enemy),
		"Düşman yetenek → düşman hedef geçerli")
	t.ok(not AbilityExecutor.is_valid_ability_target(enemy_ab, caster, ally),
		"Düşman yetenek → dost hedef geçersiz")

	# Ölü/Down hedef (target_must_be_alive) → geçersiz.
	var dead := _Stub.new()
	dead.owner_id = 1
	dead.current_health = 0
	t.ok(not AbilityExecutor.is_valid_ability_target(friendly, caster, dead),
		"Ölü dost hedef geçersiz (target_must_be_alive)")

	# Menzil: menzil içi geçerli, dışı geçersiz.
	var ranged := _ab("friendly", true, 5.0)
	ally.global_position = Vector3(3, 0, 0)
	t.ok(AbilityExecutor.is_valid_ability_target(ranged, caster, ally),
		"Menzil içi dost geçerli (3 ≤ 5)")
	ally.global_position = Vector3(9, 0, 0)
	t.ok(not AbilityExecutor.is_valid_ability_target(ranged, caster, ally),
		"Menzil dışı dost geçersiz (9 > 5)")

	# Birim-hedefi olmayan türler (self/none/position) → predikat false (tıklanacak birim yok).
	t.ok(not AbilityExecutor.is_valid_ability_target(_ab("self", true), caster, ally),
		"self türü birim vurgusu üretmez")
	t.ok(not AbilityExecutor.is_valid_ability_target(_ab("none", true), caster, ally),
		"none türü birim vurgusu üretmez")

	# Geçersiz/null hedef → false.
	t.ok(not AbilityExecutor.is_valid_ability_target(friendly, caster, null),
		"null hedef geçersiz")
