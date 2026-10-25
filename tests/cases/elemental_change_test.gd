extends RefCounted

## Elemental Change (Jabirean Alchemist): silahın elementi Fire/Gas/Shrapnel arasında değişir.
## Fire/Gas/Shrapnel MEKANİK OLARAK ÖZDEŞ (No Effect'e bile +1 Blood Marker); fark hedefin negate_*.
## (1) MechanicsResolver.next_element — element döngüsü. (2) apply_outcome attacker_element param'ı.

const MechanicsResolver = preload("res://scripts/rules/mechanics_resolver.gd")
const InjuryResolver = preload("res://scripts/rules/injury_resolver.gd")
const UnitData = preload("res://scripts/data/unit_data.gd")

class _Target:
	var unit_data
	var blood_markers: int = 0
	var is_down: bool = false
	var display_name: String = "Hedef"

func _ud(kw: Dictionary) -> UnitData:
	var u := UnitData.new()
	u.keywords = kw
	return u

func run(t) -> void:
	# ── Element döngüsü ──
	t.eq(MechanicsResolver.next_element(&""), &"fire", "boş → fire")
	t.eq(MechanicsResolver.next_element(&"fire"), &"gas", "fire → gas")
	t.eq(MechanicsResolver.next_element(&"gas"), &"shrapnel", "gas → shrapnel")
	t.eq(MechanicsResolver.next_element(&"shrapnel"), &"fire", "shrapnel → fire")

	# ── attacker_element: No Effect sonucuna bile +1 Kan (hedef negate etmiyorsa) ──
	var tgt := _Target.new()
	tgt.unit_data = _ud({})
	InjuryResolver.apply_outcome(InjuryResolver.Outcome.NO_EFFECT, tgt, null, false, &"fire")
	t.eq(tgt.blood_markers, 1, "fire element → No Effect'e +1 Kan İşareti")

	# ── negate_fire hedef → element etkisiz ──
	var tgt2 := _Target.new()
	tgt2.unit_data = _ud({&"negate_fire": 1})
	InjuryResolver.apply_outcome(InjuryResolver.Outcome.NO_EFFECT, tgt2, null, false, &"fire")
	t.eq(tgt2.blood_markers, 0, "negate_fire hedefe fire elementi etkisiz")

	# ── gas elementi, gas negate etmeyen hedef → +1 ──
	var tgt3 := _Target.new()
	tgt3.unit_data = _ud({})
	InjuryResolver.apply_outcome(InjuryResolver.Outcome.NO_EFFECT, tgt3, null, false, &"gas")
	t.eq(tgt3.blood_markers, 1, "gas element → +1 Kan")
