extends RefCounted

## P1-1 (New Antioch fork denetimi, 2026-07-16): STEADFAST (Mechanized Heavy Infantry'nin Machine
## Armour'ı) ve DESPATCH (Combat Medic'in Misericordia'sı) saf/testli parçaları. Reaktif/async
## parçalar (Eye of God reroll, Absolute Faith blood-spend istisnası, Hold Your Fire aktivasyon
## bitişi) CombatChoice/TurnManager'a bağlı, headless test edilemez — canlı doğrulanmalı.

const InjuryResolver = preload("res://scripts/rules/injury_resolver.gd")
const DicePoolBuilder = preload("res://scripts/rules/dice_pool_builder.gd")
const UnitData = preload("res://scripts/data/unit_data.gd")
const AttackData = preload("res://scripts/data/attack_data.gd")
const MechanicsResolver = preload("res://scripts/rules/mechanics_resolver.gd")
const LoadoutResolver = preload("res://scripts/rules/loadout_resolver.gd")

class _Target:
	var unit_data
	var blood_markers: int = 0
	var blessing_markers: int = 0
	var infection_markers: int = 0
	var is_down: bool = false
	var display_name: String = "Hedef"
	var armour: int = 0

func _ud(kw: Dictionary) -> UnitData:
	var u := UnitData.new()
	u.keywords = kw
	return u

func _atk(kw: Dictionary) -> AttackData:
	var a := AttackData.new()
	a.keywords = kw
	return a

func run(t) -> void:
	var O = InjuryResolver.Outcome

	# ── STEADFAST: Down → Scratch'e düşürülür ──
	var t1 := _Target.new()
	t1.unit_data = _ud({&"steadfast": 1})
	var outcome1 := InjuryResolver.apply_outcome(O.DOWN, t1, null)
	t.eq(outcome1, O.SCRATCH, "Steadfast: Down sonucu Scratch'e düşürülür")
	t.ok(not t1.is_down, "Steadfast: is_down TRUE olmaz")
	t.eq(t1.blood_markers, 1, "Steadfast: yine de +1 Kan İşareti (Scratch gibi)")

	# ── Steadfast YOKSA normal Down davranışı korunur (regresyon) ──
	var t2 := _Target.new()
	t2.unit_data = _ud({})
	var outcome2 := InjuryResolver.apply_outcome(O.DOWN, t2, null)
	t.eq(outcome2, O.DOWN, "Steadfast yok → normal Down")
	t.ok(t2.is_down, "Steadfast yok → is_down TRUE olur")

	# ── Steadfast, zaten Down olan birimde devreye girmez (Down-üstüne-Down kuralı öncelikli) ──
	var t3 := _Target.new()
	t3.unit_data = _ud({&"steadfast": 1})
	t3.is_down = true
	var outcome3 := InjuryResolver.apply_outcome(O.DOWN, t3, null)
	t.eq(outcome3, O.DOWN_ON_DOWN, "Zaten Down + Steadfast → yine Down-üstüne-Down (istisna yok)")

	# ── DESPATCH: hedef Down ise Ignore Armour, değilse değil ──
	var despatch_atk := _atk({&"despatch": 1})
	var normal_atk := _atk({})
	var down_target := _Target.new()
	down_target.is_down = true
	var standing_target := _Target.new()
	standing_target.is_down = false

	var ctx_down: Dictionary = DicePoolBuilder.build_injury_context(null, despatch_atk, down_target, false, true)
	t.ok(ctx_down["attack_ignore_armour"], "Despatch + Down hedef → Ignore Armour")

	var ctx_standing: Dictionary = DicePoolBuilder.build_injury_context(null, despatch_atk, standing_target, false, true)
	t.ok(not ctx_standing["attack_ignore_armour"], "Despatch + AYAKTA hedef → Ignore Armour YOK")

	var ctx_normal_down: Dictionary = DicePoolBuilder.build_injury_context(null, normal_atk, down_target, false, true)
	t.ok(not ctx_normal_down["attack_ignore_armour"], "Despatch yoksa Down hedefe bile Ignore Armour yok")

	# ── negate_heavy_effect (Assault Drill/Battlefield Demolition, QA denetimi 2026-07-16):
	# STRONG'un blanket negate_heavy'sinden FARKLI olarak yalnız Charge Bonus reddi + Move+Shoot
	# kilidini yok sayar, "en fazla 1 Heavy silah" SAYIM kısıtını DEĞİL. ──
	var heavy_atk := _atk({&"heavy": 1})
	var heavy_atk2 := _atk({&"heavy": 1})

	# has_unnegated_heavy_loadout: negate_heavy_effect de (blanket negate_heavy gibi) Charge
	# Bonus reddini iptal eder.
	var u_effect_only := UnitData.new()
	u_effect_only.keywords = {&"negate_heavy_effect": 1}
	u_effect_only.attacks = [heavy_atk]
	t.ok(not MechanicsResolver.has_unnegated_heavy_loadout(u_effect_only),
		"negate_heavy_effect → Charge Bonus reddi de iptal olur (tek Heavy silah)")

	var u_no_negate := UnitData.new()
	u_no_negate.keywords = {}
	u_no_negate.attacks = [heavy_atk]
	t.ok(MechanicsResolver.has_unnegated_heavy_loadout(u_no_negate),
		"negate yoksa → Heavy silah hâlâ Charge Bonus'u reddeder (regresyon)")

	# validate_loadout: negate_heavy_effect, blanket negate_heavy'nin AKSİNE, 2 Heavy silahı
	# olan bir birimi GEÇİRMEMELİ (compendium: "still cannot have more than 1 Weapon... Heavy").
	var u_two_heavy_effect_only := UnitData.new()
	u_two_heavy_effect_only.keywords = {&"negate_heavy_effect": 1}
	u_two_heavy_effect_only.attacks = [heavy_atk, heavy_atk2]
	t.ok(LoadoutResolver.validate_loadout(u_two_heavy_effect_only) != "",
		"negate_heavy_effect → 2 Heavy silah YİNE reddedilir (max-1 kısıtı hâlâ geçerli)")

	var u_two_heavy_strong := UnitData.new()
	u_two_heavy_strong.keywords = {&"strong": 1}
	u_two_heavy_strong.attacks = [heavy_atk, heavy_atk2]
	t.eq(LoadoutResolver.validate_loadout(u_two_heavy_strong), "",
		"STRONG (blanket negate_heavy) → 2 Heavy silah geçerli kalır (regresyon, farklı istisna)")
