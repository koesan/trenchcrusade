extends RefCounted

## P0-3 regresyon kilidi: Retreat sonrası bedava Melee Strike, saldıranın son UI-seçili silahı
## (Ranged olabilir, alakasız bir Melee silahı olabilir) DEĞİL, deliberate bir Melee silahı
## kullanmalı. MechanicsResolver.first_melee_attack unit.gd::execute_free_melee_strike tarafından
## tüketilir (bkz. scenes/unit/unit.gd).

const MechanicsResolver = preload("res://scripts/rules/mechanics_resolver.gd")
const UnitData = preload("res://scripts/data/unit_data.gd")
const AttackData = preload("res://scripts/data/attack_data.gd")

func _atk(atk_type: String, name: String) -> AttackData:
	var a := AttackData.new()
	a.attack_type = atk_type
	a.attack_name = name
	return a

func run(t) -> void:
	t.eq(MechanicsResolver.first_melee_attack(null), null, "null unit_data → null (güvenli)")

	var no_attacks := UnitData.new()
	t.eq(MechanicsResolver.first_melee_attack(no_attacks), null, "Silahsız birim → null")

	var ranged_only := UnitData.new()
	ranged_only.attacks = [_atk("RANGED", "pistol")]
	t.eq(MechanicsResolver.first_melee_attack(ranged_only), null,
		"Yalnız Ranged silahı olan birim → null (Ranged asla free strike silahı olarak seçilmez)")

	var mixed := UnitData.new()
	var pistol := _atk("RANGED", "pistol")
	var sword := _atk("MELEE", "sword")
	mixed.attacks = [pistol, sword]
	t.eq(MechanicsResolver.first_melee_attack(mixed), sword,
		"Ranged+Melee karışık silahlı birim → Melee silahı seçilir (Ranged değil)")

	var two_melee := UnitData.new()
	var dagger := _atk("MELEE", "dagger")
	var mace := _atk("MELEE", "mace")
	two_melee.attacks = [dagger, mace]
	t.eq(MechanicsResolver.first_melee_attack(two_melee), dagger,
		"Birden fazla Melee silahı → attacks[] sırasındaki ilki deterministik seçilir")
