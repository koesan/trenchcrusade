extends RefCounted

## InjuryResolver.resolve_table — Yara Tablosu sınır değerleri (compendium injuries.md).
##   ≤1 → NO_EFFECT | 2-6 → SCRATCH | 7-8 → DOWN | 9+ → OUT_OF_ACTION

const InjuryResolver = preload("res://scripts/rules/injury_resolver.gd")

func run(t) -> void:
	var O = InjuryResolver.Outcome

	# Alt sınır / No Effect
	t.eq(InjuryResolver.resolve_table(-3), O.NO_EFFECT, "≤1 → No Effect (-3)")
	t.eq(InjuryResolver.resolve_table(0), O.NO_EFFECT, "0 → No Effect")
	t.eq(InjuryResolver.resolve_table(1), O.NO_EFFECT, "1 → No Effect")

	# Scratch 2-6
	t.eq(InjuryResolver.resolve_table(2), O.SCRATCH, "2 → Scratch (alt sınır)")
	t.eq(InjuryResolver.resolve_table(6), O.SCRATCH, "6 → Scratch (üst sınır)")

	# Down 7-8
	t.eq(InjuryResolver.resolve_table(7), O.DOWN, "7 → Down (alt sınır)")
	t.eq(InjuryResolver.resolve_table(8), O.DOWN, "8 → Down (üst sınır)")

	# Out of Action 9+
	t.eq(InjuryResolver.resolve_table(9), O.OUT_OF_ACTION, "9 → Out of Action (alt sınır)")
	t.eq(InjuryResolver.resolve_table(20), O.OUT_OF_ACTION, "20 → Out of Action")
