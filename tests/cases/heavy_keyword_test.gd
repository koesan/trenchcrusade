extends RefCounted

## HEAVY (comprehensive-rules/keyword.md): "A model cannot be equipped with more than one piece
## of Battlekit with this Keyword and it does not receive a Charge Bonus when it makes a charge
## move." STRONG "Negate Heavy" verir (KeywordSystem.negates) — bu durumda kısıtlar uygulanmaz.
## Kapsam: MechanicsResolver.has_unnegated_heavy_loadout (Charge Bonus iptali için) +
## LoadoutResolver.validate_loadout (>1 HEAVY silah reddi).

const MechanicsResolver = preload("res://scripts/rules/mechanics_resolver.gd")
const LoadoutResolver = preload("res://scripts/rules/loadout_resolver.gd")
const UnitData = preload("res://scripts/data/unit_data.gd")
const AttackData = preload("res://scripts/data/attack_data.gd")

func _atk(hands: String, atk_type: String, kw: Dictionary = {}) -> AttackData:
	var a := AttackData.new()
	a.hands = hands
	a.attack_type = atk_type
	a.keywords = kw
	return a

func _ud(attacks: Array[Resource], unit_kw: Dictionary = {}) -> UnitData:
	var u := UnitData.new()
	u.attacks = attacks
	u.keywords = unit_kw
	return u

func run(t) -> void:
	var heavy_rifle := _atk("2H", "RANGED", {&"heavy": 1})
	var normal_rifle := _atk("1H", "RANGED", {})
	# El limitini (azami 2) AŞMAMASI için iki HEAVY silah da 1H (toplam 2 el) — yalnız
	# HEAVY'nin kendi ">1 HEAVY" kısıtını izole test eder, genel el-limitine karışmaz.
	var heavy_1h_a := _atk("1H", "RANGED", {&"heavy": 1})
	var heavy_1h_b := _atk("1H", "RANGED", {&"heavy": 1})

	# has_unnegated_heavy_loadout
	t.ok(MechanicsResolver.has_unnegated_heavy_loadout(_ud([heavy_rifle])),
		"HEAVY silah taşıyan birim → Charge Bonus iptal")
	t.ok(not MechanicsResolver.has_unnegated_heavy_loadout(_ud([normal_rifle])),
		"HEAVY olmayan silah → Charge Bonus normal")
	t.ok(not MechanicsResolver.has_unnegated_heavy_loadout(_ud([heavy_rifle], {&"strong": 1})),
		"STRONG (Negate Heavy) → HEAVY kısıtı uygulanmaz")
	t.ok(not MechanicsResolver.has_unnegated_heavy_loadout(_ud([])),
		"Silahsız birim → HEAVY yok")
	t.ok(not MechanicsResolver.has_unnegated_heavy_loadout(null),
		"null unit_data → güvenli false")

	# LoadoutResolver.validate_loadout — birden fazla HEAVY reddi
	t.eq(LoadoutResolver.validate_loadout(_ud([heavy_rifle])), "",
		"Tek HEAVY silah → geçerli")
	t.ok(LoadoutResolver.validate_loadout(_ud([heavy_1h_a, heavy_1h_b])) != "",
		"İki HEAVY silah (el limiti içinde) → yine de reddedilir")
	t.eq(LoadoutResolver.validate_loadout(_ud([heavy_1h_a, heavy_1h_b], {&"strong": 1})), "",
		"STRONG (Negate Heavy) → çoklu HEAVY serbest")
