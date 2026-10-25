extends RefCounted

## CombatResolver.attack_interaction_allowed — Shoot ↔ Charge/Fight etkileşimi (compendium).
## P0-A regresyon kilidi: hücum sonrası Fight HER ZAMAN serbest olmalı.

const CombatResolver = preload("res://scripts/rules/combat_resolver.gd")

func run(t) -> void:
	# is_melee, is_assault, charged, fought, did_non_assault_shot
	var F = CombatResolver.attack_interaction_allowed

	# ── Fight (melee) ──
	t.ok(F.call(true, false, false, false, false), "Fight (taze) serbest")
	t.ok(F.call(true, false, true, false, false), "Fight HÜCUM sonrası serbest (P0-A düzeltmesi)")
	t.ok(not F.call(true, false, false, false, true), "Fight: Assault olmayan Shoot sonrası YASAK")
	t.ok(F.call(true, false, true, false, false), "Fight: Assault silahlı hücum sonrası da serbest")

	# ── Shoot (ranged) ──
	t.ok(F.call(false, false, false, false, false), "Shoot (taze) serbest")
	t.ok(not F.call(false, false, true, false, false), "Shoot: hücum sonrası Assault olmayan YASAK")
	t.ok(F.call(false, true, true, false, false), "Shoot: hücum sonrası Assault silahla serbest")
	t.ok(not F.call(false, false, false, true, false), "Shoot: Fight sonrası Assault olmayan YASAK")
	t.ok(F.call(false, true, false, true, false), "Shoot: Fight sonrası Assault silahla serbest")
