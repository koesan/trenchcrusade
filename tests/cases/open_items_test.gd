extends RefCounted

## Compendium denetimi — açık kalan maddeler: Headgear, Tormentor Chain, senaryo Glory bütçesi,
## Infiltrator sırası, Faithful Followers'ın aktivasyon başı mesafesi.

class FakeUnit extends Node3D:
	var owner_id: int = 1
	var current_health: int = 1
	var has_moved: bool = false
	var unit_data: Resource = null
	var fireteam_partner = null
	var joint_partner = null
	var activation_start_pos = null

func run(t) -> void:
	# ── Headgear: "A model cannot have more than one piece of Headgear" ──────
	var na: Resource = load("res://assets/data/factions/new_antioch.tres")
	var yeoman: Resource = load("res://assets/data/units/new_antioch_yeoman.tres")
	var helmet: Resource = load("res://assets/data/armoury/combat_helmet.tres")
	var mask: Resource = load("res://assets/data/armoury/gas_mask.tres")
	t.ok(helmet.is_headgear and mask.is_headgear, "Miğfer ve gaz maskesi Headgear")
	t.eq(ArmouryRules.check(mask, yeoman, na, {}, [], 999, 0), "", "Başlığı olmayan model gaz maskesi alabilir")
	t.eq(ArmouryRules.check(mask, yeoman, na, {}, [&"combat_helmet"], 999, 0), ArmouryRules.REASON_HEADGEAR,
		"Miğferli model ikinci Headgear (gaz maskesi) alamaz")
	t.ok(not load("res://assets/data/armoury/binoculars.tres").is_headgear, "Dürbün Headgear değil")

	# ── Tormentor Chain yalnız Exploration ile bulunur (normal cephanelikte yok — doğru) ──
	var hl: Resource = load("res://assets/data/factions/heretic_legion.tres")
	t.ok(not ArmouryRules.table_for(hl).any(func(it): return it != null and String(it.item_id).contains("tormentor")),
		"Tormentor Chain HL cephaneliğinde yok (compendium: 'Exploration Only')")

	# ── Her senaryoda mercenary'ler için Glory bütçesi ──────────────────────
	var cnml: Resource = load("res://assets/data/scenarios/claim_no_mans_land.tres")
	t.eq(cnml.glory_budget, 10, "Claim No Man's Land da diğer senaryolar gibi 10 Glory verir")

	# ── Faithful Followers: mesafe aktivasyon başındaki konumdan ───────────
	var monk := FakeUnit.new()
	monk.unit_data = UnitData.new()
	monk.unit_data.keywords[&"faithful_followers"] = 1
	var pilgrim := FakeUnit.new()
	pilgrim.unit_data = UnitData.new()
	t.add_child(monk)
	t.add_child(pilgrim)
	monk.global_position = Vector3(0, 0, 0)
	pilgrim.global_position = Vector3(8, 0, 0)
	pilgrim.activation_start_pos = Vector3(1.5, 0, 0)
	t.eq(ActivationRules.joint_kind(pilgrim, monk, [monk, pilgrim]), ActivationRules.JOINT_FOLLOWERS,
		"Aktivasyonu Monk'un 1\" içinde başlayan model sonra uzaklaşsa da Monk katılabilir")
	pilgrim.activation_start_pos = Vector3(8, 0, 0)
	t.eq(ActivationRules.joint_kind(pilgrim, monk, [monk, pilgrim]), ActivationRules.JOINT_NONE,
		"Aktivasyonu 1\" dışında başlayan modele Monk katılamaz")
	monk.queue_free()
	pilgrim.queue_free()

	# ── Infiltrator sırası ──────────────────────────────────────────────────
	var saved_ready: Dictionary = GameState.infiltration_ready.duplicate()
	var saved_finished: Dictionary = GameState.player_deployment_finished.duplicate()
	var saved_active: int = GameState.active_deployer_id
	GameState.infiltration_ready = {1: false, 2: false}
	GameState.player_deployment_finished = {1: false, 2: true}
	t.ok(InfiltrationOrder.may_infiltrate_now(1), "Rakibin yerleşimi bittiyse Sızıcı serbest yerleşir")
	GameState.player_deployment_finished = {1: false, 2: false}
	var opp_has_budget: bool = GameState._has_deploy_budget(2)
	if opp_has_budget:
		t.ok(not InfiltrationOrder.may_infiltrate_now(1), "Rakip hâlâ normal model yerleştiriyorsa Sızıcı bekler")
	GameState.infiltration_ready = {1: true, 2: false}
	t.ok(InfiltrationOrder.is_waiting(1), "Hazır işaretlenen oyuncu rakibin normal modellerini bekler")
	t.ok(InfiltrationOrder.may_infiltrate_now(2), "Bekleyen rakibe karşı Sızıcı yerleşebilir")
	GameState.infiltration_ready = {1: true, 2: true}
	t.ok(not InfiltrationOrder.is_waiting(1) and not InfiltrationOrder.is_waiting(2),
		"İki taraf da Sızıcı aşamasında → normal sırayla yerleşir")
	GameState.infiltration_ready = saved_ready
	GameState.player_deployment_finished = saved_finished
	GameState.active_deployer_id = saved_active
	var gs := FileAccess.get_file_as_string("res://scripts/game_state/game_state.gd")
	t.ok(gs.contains("and not InfiltrationOrder.is_waiting(opponent_id):"),
		"Bekleyen oyuncuya sıra geçmez — rakip kalan modellerini art arda yerleştirir")
	t.ok(DeployValidator.ALL_REASONS.has(DeployValidator.REASON_INFILTRATOR_ORDER), "Sıra ret sebebi kayıtlı")
