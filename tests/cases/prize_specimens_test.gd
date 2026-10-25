extends RefCounted

## MechanicsResolver.prize_specimens_gains_blessing — Combat Biologist "Prize Specimens":
## Demonic VEYA Black Grail bir düşmanı MELEE ile Out of Action edince +1 Blessing (yalnız o durumda).

const MechanicsResolver = preload("res://scripts/rules/mechanics_resolver.gd")
const UnitData = preload("res://scripts/data/unit_data.gd")

func _ud(kw: Dictionary) -> UnitData:
	var u := UnitData.new()
	u.keywords = kw
	return u

func run(t) -> void:
	var bio := _ud({&"prize_specimens": 1})
	var demon := _ud({&"demonic": 1})
	var grail := _ud({&"black_grail": 1})
	var heretic := _ud({&"heretic": 1})
	var plain := _ud({})

	t.ok(MechanicsResolver.prize_specimens_gains_blessing(bio, demon, true, true),
		"Demonic'i melee ile OOA → +Blessing")
	t.ok(MechanicsResolver.prize_specimens_gains_blessing(bio, grail, true, true),
		"Black Grail'i melee ile OOA → +Blessing")
	t.ok(not MechanicsResolver.prize_specimens_gains_blessing(bio, heretic, true, true),
		"Heretic (Demonic/BG değil) → yok")
	t.ok(not MechanicsResolver.prize_specimens_gains_blessing(bio, demon, false, true),
		"Menzilli (melee değil) → yok")
	t.ok(not MechanicsResolver.prize_specimens_gains_blessing(bio, demon, true, false),
		"OOA değil → yok")
	t.ok(not MechanicsResolver.prize_specimens_gains_blessing(plain, demon, true, true),
		"prize_specimens yok → yok")
