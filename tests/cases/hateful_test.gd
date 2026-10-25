extends RefCounted

## MechanicsResolver.hateful_target_index — Yoke Fiend "Hateful": aktivasyonda TÜM düşmanlardan
## >1" uzaktaysa ve 12" içinde LoS'ta, Black Grail/Demonic OLMAYAN bir düşman varsa, en yakınına
## zorunlu Charge. Dönüş: hedef indexi (yoksa -1). SAF geometri (LoS/exempt çağıran tarafından verilir).

const MechanicsResolver = preload("res://scripts/rules/mechanics_resolver.gd")

func _e(pos: Vector3, exempt: bool, los: bool) -> Dictionary:
	return {"pos": pos, "exempt": exempt, "los": los}

func run(t) -> void:
	var fiend := Vector3.ZERO

	# Tek geçerli düşman 5" mesafede, LoS var, exempt değil → hedef 0.
	t.eq(MechanicsResolver.hateful_target_index(fiend, [_e(Vector3(5, 0, 0), false, true)]), 0,
		"12\" içi geçerli düşman → zorunlu hedef")

	# En yakın geçerli seçilir (index 1 daha yakın).
	t.eq(MechanicsResolver.hateful_target_index(fiend,
		[_e(Vector3(8, 0, 0), false, true), _e(Vector3(3, 0, 0), false, true)]), 1,
		"En yakın geçerli düşman seçilir")

	# Fiend zaten bir düşmanın 1\" yakınında (angaje) → zorunlu charge YOK (-1).
	t.eq(MechanicsResolver.hateful_target_index(fiend,
		[_e(Vector3(1.0, 0, 0), false, true), _e(Vector3(4, 0, 0), false, true)]), -1,
		"1\" içinde düşman varsa zorunlu charge yok")

	# Yalnız exempt (Demonic/Black Grail) düşman → -1.
	t.eq(MechanicsResolver.hateful_target_index(fiend, [_e(Vector3(5, 0, 0), true, true)]), -1,
		"Sadece exempt düşman → hedef yok")

	# LoS yok → atlanır.
	t.eq(MechanicsResolver.hateful_target_index(fiend, [_e(Vector3(5, 0, 0), false, false)]), -1,
		"LoS yok → hedef yok")

	# 12\" dışı → atlanır.
	t.eq(MechanicsResolver.hateful_target_index(fiend, [_e(Vector3(15, 0, 0), false, true)]), -1,
		"12\" dışı → hedef yok")

	# ── INFILTRATOR yerleşim geçerliliği: en yakın düşmandan >= 8" olmalı ──
	t.ok(MechanicsResolver.infiltrator_placement_valid(Vector3.ZERO, [Vector3(10, 0, 0)], 8.0),
		"Düşmandan 10\" uzak → geçerli")
	t.ok(not MechanicsResolver.infiltrator_placement_valid(Vector3.ZERO, [Vector3(5, 0, 0)], 8.0),
		"Düşmandan 5\" (<8) → geçersiz")
	t.ok(MechanicsResolver.infiltrator_placement_valid(Vector3.ZERO, [], 8.0),
		"Sahada düşman yok → geçerli")
	t.ok(not MechanicsResolver.infiltrator_placement_valid(Vector3.ZERO, [Vector3(20, 0, 0), Vector3(4, 0, 0)], 8.0),
		"Düşmanlardan biri 4\" → geçersiz")
