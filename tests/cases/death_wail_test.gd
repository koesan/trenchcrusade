extends RefCounted

## FAZ 6 (Heretic Legion, Trench Ghosts): Barbed Wire Banshee "Death Wail" — Unholy Hymns ile aynı
## aura deseni (_enemy_aura_nearby) ama Success yerine Injury Dice'a uygulanır.

const DicePoolBuilder = preload("res://scripts/rules/dice_pool_builder.gd")
const UnitData = preload("res://scripts/data/unit_data.gd")
const AttackData = preload("res://scripts/data/attack_data.gd")

class FakeUnit:
	extends RefCounted
	var owner_id: int = 1
	var current_health: int = 10
	var unit_data = null
	var global_position: Vector3 = Vector3.ZERO
	var is_down: bool = false
	var armour: int = 0
	var blood_markers: int = 0
	var blessing_markers: int = 0
	var infection_markers: int = 0

func _ud(kw: Dictionary) -> UnitData:
	var u := UnitData.new()
	u.keywords = kw
	return u

func run(t) -> void:
	var attacker := FakeUnit.new()
	attacker.owner_id = 1
	attacker.unit_data = _ud({})
	var target := FakeUnit.new()
	target.owner_id = 2
	target.unit_data = _ud({})
	target.global_position = Vector3(1, 0, 0)

	var atk := AttackData.new()

	var banshee := FakeUnit.new()
	banshee.owner_id = 1
	banshee.unit_data = _ud({&"death_wail": 1})
	banshee.global_position = Vector3(2, 0, 0)  # target'a ~1m, aura menzili içinde

	GameState.units[&"__test_attacker__"] = attacker
	GameState.units[&"__test_target__"] = target
	GameState.units[&"__test_banshee__"] = banshee

	var ctx_no_banshee: Dictionary = DicePoolBuilder.build_injury_context(attacker, atk, target, false, false)
	GameState.units.erase(&"__test_banshee__")
	t.eq(DicePoolBuilder.compute_injury_modifier(ctx_no_banshee), 0, "Banshee yokken Death Wail tetiklenmez")

	GameState.units[&"__test_banshee__"] = banshee
	var ctx_with_banshee: Dictionary = DicePoolBuilder.build_injury_context(attacker, atk, target, false, false)
	t.eq(DicePoolBuilder.compute_injury_modifier(ctx_with_banshee), 1,
		"8\" içinde düşman Banshee → Death Wail +1 Injury Dice")

	# Banshee dostsa (target'ın DÜŞMANI değil, kendi tarafındaysa) tetiklenmemeli.
	banshee.owner_id = target.owner_id
	var ctx_friendly_banshee: Dictionary = DicePoolBuilder.build_injury_context(attacker, atk, target, false, false)
	t.eq(DicePoolBuilder.compute_injury_modifier(ctx_friendly_banshee), 0,
		"Banshee hedefle AYNI tarafta ise (dost) tetiklenmez")

	GameState.units.erase(&"__test_attacker__")
	GameState.units.erase(&"__test_target__")
	GameState.units.erase(&"__test_banshee__")
