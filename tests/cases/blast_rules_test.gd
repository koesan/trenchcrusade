extends RefCounted

## BLAST (X) — compendium `comprehensive-rules/keyword.md`.
##
## RAW: "every model that has a Line of Sight to the target and which is within the Weapon's
## blast radius is hit. **In addition, friendly models that are within 1\" of an enemy model that
## was hit by the blast radius are also hit.**" ve "If you roll a Critical Success, **only add the
## extra Injury Dice to the roll for a model IF IT WAS CHOSEN AS THE TARGET of the attack.**"
##
## 2026-07-29 denetiminde iki sapma bulundu:
##   1. Yarıçaptaki HERKES vuruluyordu — saldıranın dostları, hiçbir düşmanın yakınında
##      olmasalar bile. Blast silahlarının kendi ordusuna verdiği zarar RAW'ın çok üstündeydi.
##   2. Kritik bonusu patlamadaki HERKESE veriliyordu (RAW: yalnız hedeflenen modele).

class FakeUnit extends Node3D:
	var owner_id: int = 1
	var current_health: int = 1
	var is_down: bool = false
	var unit_data: Resource = null
	var display_name: String = "Sahte"

var _host: Node = null

func _u(pos: Vector3, owner_id: int) -> FakeUnit:
	var n := FakeUnit.new()
	_host.add_child(n)
	n.global_position = pos
	n.owner_id = owner_id
	return n

func run(t) -> void:
	_host = t
	var attacker := _u(Vector3(0, 0, 0), 1)

	# Patlama merkezi (10,0,0). Yarıçap 3".
	var center := Vector3(10, 0, 0)
	var enemy_near := _u(Vector3(10, 0, 0), 2)      # merkezde — vurulur
	var enemy_edge := _u(Vector3(12.5, 0, 0), 2)    # 2.5" — vurulur
	var enemy_out := _u(Vector3(20, 0, 0), 2)       # yarıçap dışı — vurulmaz
	var ally_near_enemy := _u(Vector3(10.8, 0, 0), 1)  # düşmana 0.8" → vurulur
	var ally_far := _u(Vector3(7.5, 0, 0), 1)       # yarıçapta AMA düşmana tabandan tabana 1"+ → vurulmaz

	var src := {
		"a": attacker, "e1": enemy_near, "e2": enemy_edge, "e3": enemy_out,
		"f1": ally_near_enemy, "f2": ally_far,
	}
	# `blast_victims` GameState.units'i okur — test için geçici olarak doldur.
	var backup: Dictionary = GameState.units.duplicate()
	GameState.units = src

	var victims: Array = MechanicsResolver.blast_victims(attacker, center, 3.0)

	t.ok(victims.has(enemy_near), "Merkezdeki düşman vurulur")
	t.ok(victims.has(enemy_edge), "Yarıçap içindeki düşman vurulur")
	t.ok(not victims.has(enemy_out), "Yarıçap dışındaki düşman vurulmaz")
	t.ok(not victims.has(attacker), "Saldıranın kendisi vurulmaz")
	t.ok(victims.has(ally_near_enemy),
		"Vurulan düşmanın 1\" içindeki DOST vurulur (RAW'ın açık istisnası)")
	t.ok(not victims.has(ally_far),
		"Yarıçapta olsa da hiçbir vurulan düşmana yakın OLMAYAN dost vurulmaz")
	t.eq(victims.size(), 3, "Toplam 3 kurban (2 düşman + 1 yakın dost)")

	# Hiç düşman yoksa hiçbir dost vurulmaz (dostlar yalnız düşman üzerinden kapsanır).
	GameState.units = {"a": attacker, "f1": ally_near_enemy, "f2": ally_far}
	var only_allies: Array = MechanicsResolver.blast_victims(attacker, center, 3.0)
	t.eq(only_allies.size(), 0,
		"Yarıçapta hiç düşman yoksa dostlar da vurulmaz (dost kapsamı düşmana bağlıdır)")

	GameState.units = backup

	# ── Kritik bonusu yalnız hedefe ──────────────────────────────────────
	var msrc := FileAccess.open("res://scripts/rules/mechanics_resolver.gd", FileAccess.READ)
	t.ok(msrc != null, "mechanics_resolver.gd okunabildi")
	if msrc != null:
		var mtxt := msrc.get_as_text()
		msrc.close()
		t.ok(mtxt.contains("is_critical and u == primary_target"),
			"execute_blast: Kritik bonusu YALNIZ hedeflenen modele")
		t.ok(mtxt.contains("is_critical and is_primary"),
			"execute_infernal_bomb_blast: Kritik bonusu YALNIZ hedeflenen modele")

	for u in [attacker, enemy_near, enemy_edge, enemy_out, ally_near_enemy, ally_far]:
		if is_instance_valid(u):
			u.free()
