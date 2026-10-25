extends RefCounted

## FAZ 4: Yeni senaryo mantıkları — Great War, Fields of Glory, The High Ground.

const MechanicsResolver = preload("res://scripts/rules/mechanics_resolver.gd")
const GreatWarLogic = preload("res://scripts/rules/scenarios/great_war.gd")
const FieldsOfGloryLogic = preload("res://scripts/rules/scenarios/fields_of_glory.gd")
const TheHighGroundLogic = preload("res://scripts/rules/scenarios/the_high_ground.gd")
const UnitData = preload("res://scripts/data/unit_data.gd")
const ScenarioObjective = preload("res://scripts/data/scenario_objective.gd")
const ScenarioData = preload("res://scripts/data/scenario_data.gd")

class FakeUnit:
	extends RefCounted
	var owner_id: int = 1
	var name: String = "u1"
	var current_health: int = 10
	var unit_data = null
	var global_position: Vector3 = Vector3.ZERO

func _ud(kw: Dictionary, cost: int = 0) -> UnitData:
	var u := UnitData.new()
	u.keywords = kw
	u.cost = cost
	return u

func _obj(id: StringName, pos: Vector3) -> ScenarioObjective:
	var o := ScenarioObjective.new()
	o.objective_id = id
	o.position = pos
	o.control_radius = 1.0
	o.vp_per_turn = 2
	return o

func run(t) -> void:
	# ── GREAT WAR VP formülü ────────────────────────────────────────────────
	t.eq(MechanicsResolver.great_war_vp_for_cost(100), 10, "Cost 100 → 10 VP")
	t.eq(MechanicsResolver.great_war_vp_for_cost(5), 1, "Cost 5 → 1 VP (yukarı yuvarla)")
	t.eq(MechanicsResolver.great_war_vp_for_cost(0), 0, "Cost 0 → 0 VP")

	var gw := GreatWarLogic.new()
	gw.setup(null)
	var attacker := FakeUnit.new(); attacker.owner_id = 1
	var target := FakeUnit.new(); target.unit_data = _ud({}, 45)
	gw.on_unit_out_of_action(attacker, target, true, {"is_ooa": true})
	t.eq(gw.player_vp[1], 5, "Great War: Cost 45 OOA → +5 VP (45/10 yukarı yuvarla)")
	gw.on_unit_out_of_action(attacker, target, true, {"is_ooa": false})
	t.eq(gw.player_vp[1], 5, "Great War: OOA değilse VP eklenmez")

	# ── FIELDS OF GLORY ─────────────────────────────────────────────────────
	var fog := FieldsOfGloryLogic.new()
	fog.setup(null)
	var a1 := FakeUnit.new(); a1.owner_id = 1; a1.name = "a1"
	var enemy_elite := FakeUnit.new(); enemy_elite.name = "e_elite"; enemy_elite.unit_data = _ud({&"elite": 1})
	var enemy_plain := FakeUnit.new(); enemy_plain.name = "e_plain"; enemy_plain.unit_data = _ud({})

	# DEATH FROM ABOVE
	fog.on_unit_out_of_action(a1, enemy_plain, true, {"is_ooa": true, "is_diving_charge": true})
	t.ok(fog.glorious_deeds[1].has(&"death_from_above"), "Fields of Glory: Diving Charge melee OOA → Death From Above")

	# ELITE HUNTER (2. Elite OOA gerekir)
	fog.on_unit_out_of_action(a1, enemy_elite, true, {"is_ooa": true})
	t.ok(not fog.glorious_deeds[1].has(&"elite_hunter"), "Fields of Glory: 1. Elite OOA yeterli değil")
	fog.on_unit_out_of_action(a1, enemy_elite, true, {"is_ooa": true})
	t.ok(fog.glorious_deeds[1].has(&"elite_hunter"), "Fields of Glory: 2. Elite OOA → Elite Hunter")

	# REAPER (3 toplam OOA gerekir) — şu ana kadar a1: plain(1)+elite(2)+elite(3) = 3
	t.ok(fog.glorious_deeds[1].has(&"reaper"), "Fields of Glory: 3. toplam OOA → Reaper")

	# PERSONAL REVENGE: enemy_plain daha önce (varsayımsal) birini öldürmüş olsun, sonra Bloodbath ile OOA edilsin.
	var fog2 := FieldsOfGloryLogic.new()
	fog2.setup(null)
	var victim := FakeUnit.new(); victim.name = "victim"
	fog2.on_unit_out_of_action(enemy_plain, victim, true, {"is_ooa": true})  # enemy_plain artık "öldürmüş" sayılır
	var a2 := FakeUnit.new(); a2.owner_id = 1; a2.name = "a2"
	fog2.on_unit_out_of_action(a2, enemy_plain, true, {"is_ooa": true, "is_bloodbath": true})
	t.ok(fog2.glorious_deeds[1].has(&"personal_revenge"), "Fields of Glory: Bloodbath ile daha önce öldürmüş düşmanı OOA → Personal Revenge")

	var fog_end := fog.evaluate_end_of_game()
	t.eq(fog_end["vp"][1], 4, "Fields of Glory VP: 3 deed × 1 VP (death_from_above+reaper+elite_hunter) + elite_hunter bonus +1 = 4")

	# ── THE HIGH GROUND ─────────────────────────────────────────────────────
	var hg_data := ScenarioData.new()
	hg_data.objectives = [_obj(&"hg_1", Vector3(0,0,-8)), _obj(&"hg_2", Vector3(0,0,-4)),
		_obj(&"hg_3", Vector3(0,0,0)), _obj(&"hg_4", Vector3(0,0,4)), _obj(&"hg_5", Vector3(0,0,8))]
	var hg := TheHighGroundLogic.new()
	hg.setup(hg_data)

	# Diving Charge VP + Death From Above deed (anlık VP, tekrar edebilir)
	var hg_attacker := FakeUnit.new(); hg_attacker.owner_id = 1
	hg.on_unit_out_of_action(hg_attacker, enemy_plain, true, {"is_ooa": true, "is_diving_charge": true})
	t.eq(hg.player_vp[1], 1, "The High Ground: Diving Charge OOA → +1 VP")
	t.ok(hg.glorious_deeds[1].has(&"death_from_above"), "The High Ground: Death From Above verildi")
	hg.on_unit_out_of_action(hg_attacker, enemy_plain, true, {"is_ooa": true, "is_diving_charge": true})
	t.eq(hg.player_vp[1], 2, "The High Ground: 2. Diving Charge OOA → +1 VP daha (Deed tekrar verilmez ama VP birikir)")

	# KING OF THE HILL: bir model tüm 5 objective'i sırayla ziyaret etsin (her turda 1 tanesinde).
	var wanderer := FakeUnit.new(); wanderer.owner_id = 2; wanderer.name = "wanderer"
	GameState.units[&"wanderer"] = wanderer
	for i in range(5):
		wanderer.global_position = hg_data.objectives[i].position
		hg.on_turn_end(i + 1)
	t.ok(hg.glorious_deeds[2].has(&"king_of_the_hill"), "The High Ground: 5 objective'in hepsini ziyaret → King of the Hill")
	GameState.units.erase(&"wanderer")
