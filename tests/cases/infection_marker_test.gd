extends RefCounted

## P0-8: [Infection Markers] keyword'lü silahlar Blood Marker YERİNE Infection Marker basmalı
## (cult-of-the-black-grail.md: "cause Infection Markers instead of Blood Markers to be placed").
## Herald of Beelzebub'un Infected Proboscis'i (assets/data/attacks/infected_proboscis.tres) bu
## keyword'ü zaten taşıyordu ama apply_outcome hep target.blood_markers'a yazıyordu.

const InjuryResolver = preload("res://scripts/rules/injury_resolver.gd")
const AttackData = preload("res://scripts/data/attack_data.gd")
const UnitData = preload("res://scripts/data/unit_data.gd")

class _Target:
	var unit_data
	var blood_markers: int = 0
	var infection_markers: int = 0
	var is_down: bool = false
	var display_name: String = "Hedef"

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
	var infection_atk := _atk({&"infection_markers": 1})
	var normal_atk := _atk({})

	# ── Scratch: infection silahı → infection havuzuna, blood'a DOKUNMAZ ──
	var t1 := _Target.new()
	t1.unit_data = _ud({})
	InjuryResolver.apply_outcome(O.SCRATCH, t1, infection_atk)
	t.eq(t1.infection_markers, 1, "[Infection Markers] silahı Scratch → +1 Enfeksiyon")
	t.eq(t1.blood_markers, 0, "[Infection Markers] silahı Scratch → Kan İşareti değişmez")

	# ── Aynı silah/sonuç normal silahla → blood havuzuna (regresyon kontrolü) ──
	var t2 := _Target.new()
	t2.unit_data = _ud({})
	InjuryResolver.apply_outcome(O.SCRATCH, t2, normal_atk)
	t.eq(t2.blood_markers, 1, "Normal silah Scratch → +1 Kan İşareti (değişmedi)")
	t.eq(t2.infection_markers, 0, "Normal silah Scratch → Enfeksiyon İşareti değişmez")

	# ── Down üstüne Down: +2 → infection havuzuna ──
	var t3 := _Target.new()
	t3.unit_data = _ud({})
	t3.is_down = true
	InjuryResolver.apply_outcome(O.DOWN, t3, infection_atk)
	t.eq(t3.infection_markers, 2, "[Infection Markers] silahı Down-üstüne-Down → +2 Enfeksiyon")

	# ── 6 tavanı infection için de geçerli ──
	var t4 := _Target.new()
	t4.unit_data = _ud({})
	t4.infection_markers = 5
	InjuryResolver.apply_outcome(O.SCRATCH, t4, infection_atk)
	t.eq(t4.infection_markers, 6, "Enfeksiyon İşareti 6'da tavanlanır (5+1=6)")
	InjuryResolver.apply_outcome(O.SCRATCH, t4, infection_atk)
	t.eq(t4.infection_markers, 6, "Enfeksiyon İşareti 6'yı aşmaz")
