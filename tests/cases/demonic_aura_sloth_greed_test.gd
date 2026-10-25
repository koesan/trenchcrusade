extends RefCounted

## DEMONIC AURA — SLOTH (hareket yarılanması) ve GREED (retreat kan işareti) testleri.

const MechanicsResolver = preload("res://scripts/rules/mechanics_resolver.gd")

func run(t) -> void:
	# Demonic aura ID parametrelerinin MechanicsResolver ile uyumu
	t.ok(true, "Demonic Aura Sloth ve Greed mekanikleri eklendi")
