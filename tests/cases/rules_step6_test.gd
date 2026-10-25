extends RefCounted

## Compendium denetimi, Adım 6: tabandan tabana ölçüm, Infiltrator görüş hattı + bölge yedeği,
## isteğe bağlı Skirmisher kaçışı, hücumda tırmanma Risky'si, kenardan düşme, yakın dövüşte görüş
## hattı, Tough/Golem'in zaten Down modelde 2 Kan İşareti vermesi.

class FakeUnit extends Node3D:
	var unit_data: Resource = null
	var is_down: bool = false
	var blood_markers: int = 0
	var current_health: int = 1
	var has_tough_used: bool = false
	var display_name: String = "Sahte"

func run(t) -> void:
	# ── Tabandan tabana ölçüm ───────────────────────────────────────────────
	t.approx(GameState.ENGAGE_RANGE, 2.2, "Angajman 1\" bazlar arası = merkezler arası 1 + 2×0.6")
	t.approx(GameState.CHARGE_REACH_TOLERANCE, 1.2, "Hücum mesafesi bazların temas noktasına ölçülür")
	t.approx(GameState.ENGAGE_RANGE, 1.0 + GameState.ATTACK_RANGE_TOLERANCE,
		"Yakın dövüş erişimi (1\" + taban payı) angajman mesafesiyle aynı")
	var dir := DirAccess.open("res://assets/data/attacks")
	var wrong: Array = []
	for f in dir.get_files():
		if not f.ends_with(".tres"):
			continue
		var a: AttackData = load("res://assets/data/attacks/" + f) as AttackData
		if a != null and a.attack_type == "MELEE" and not is_equal_approx(a.attack_range, 1.0):
			wrong.append(f)
	t.eq(wrong, [], "Tüm yakın dövüş silahları 1\" menzilli")
	var uq := FileAccess.get_file_as_string("res://scripts/rules/unit_query.gd")
	t.ok(uq.contains("unit.global_position, radius + GameState.ATTACK_RANGE_TOLERANCE)"),
		"enemies_within/allies_within model-model mesafesini tabandan tabana ölçer")

	# ── Infiltrator ─────────────────────────────────────────────────────────
	var df := FileAccess.get_file_as_string("res://scripts/rules/deploy/deploy_flow.gd")
	t.ok(df.contains("return DeployValidator.REASON_INFILTRATOR_LOS"),
		"Infiltrator düşman görüş hattına yerleşemez")
	t.ok(df.contains("static func _placement_infiltrator(req: DeployRequest) -> String:\n\tif ScenarioManager.is_valid_deploy_position"),
		"Infiltrator her zaman kendi bölgesine normal yerleşebilir")
	t.ok(DeployValidator.ALL_REASONS.has(DeployValidator.REASON_INFILTRATOR_LOS), "Yeni ret sebebi kayıtlı")

	# ── Skirmisher ──────────────────────────────────────────────────────────
	var u := FileAccess.get_file_as_string("res://scenes/unit/unit.gd")
	t.ok(u.contains("enemy = await SkirmisherEvade.resolve(self, enemy)"), "Skirmisher kaçışı SkirmisherEvade'den")
	var sk := FileAccess.get_file_as_string("res://scripts/rules/skirmisher_evade.gd")
	t.ok(sk.contains("CombatChoice.request_skirmisher_evade"), "Kaçış isteğe bağlı — hedefin sahibine sorulur")
	t.ok(sk.contains("request_position_pick(enemy, float(d3)"), "Kaçış yönünü oyuncu seçer")
	t.ok(sk.contains("charge_interposing_enemy(charger, enemy)"), "Kaçış sonrası araya giren model hücumun hedefi olur")
	var p: Vector3 = SkirmisherEvade.default_evade_point(Vector3.ZERO, Vector3(4, 0, 0), 2)
	t.ok(p.is_equal_approx(Vector3(6, 0, 0)), "Varsayılan kaçış: hücum edenden uzağa D3\"")
	var ov := FileAccess.get_file_as_string("res://scenes/ui/combat_choice/marker_spend_overlay.gd")
	t.ok(ov.contains("\"skirmisher_evade\""), "Kaçış sorusu evet/hayır kartında")

	# ── Hücumda tırmanma ────────────────────────────────────────────────────
	t.ok(u.contains("enemy.global_position.y - global_position.y > GameState.CLIMB_FREE_MAX"),
		"Hücum >3\" yüzeyi tırmanıyorsa Risky Success gerekir")

	# ── Yakın dövüşte görüş hattı ───────────────────────────────────────────
	var cr := FileAccess.get_file_as_string("res://scripts/rules/combat_resolver.gd")
	t.ok(cr.contains("elif attacker.get_line_of_sight_status(enemy).get(\"is_blocked\", false):"),
		"Görüş hattı her saldırıda (yakın dövüş dâhil) gerekir")

	# ── Kenardan düşme ──────────────────────────────────────────────────────
	var ledge: GDScript = load("res://scripts/rules/injury/triggers/ledge_fall.gd")
	t.ok(InjuryTriggers.POST_OUTCOME.has(ledge), "Kenardan düşme tetikleyicisi kayıtlı")

	# ── Tough / Golem: zaten Down modelde 2 Kan İşareti ─────────────────────
	var tough := FakeUnit.new()
	tough.unit_data = UnitData.new()
	tough.unit_data.has_tough = true
	tough.is_down = true
	var out = InjuryResolver._resolve_out_of_action(tough)
	t.eq(out, InjuryResolver.Outcome.NEGATED_TOUGH, "Tough: OOA → Down")
	t.eq(tough.blood_markers, 2, "Tough: zaten Down iken Down sonucu 2 Kan İşareti verir")
	var fresh := FakeUnit.new()
	fresh.unit_data = UnitData.new()
	fresh.unit_data.has_tough = true
	InjuryResolver._resolve_out_of_action(fresh)
	t.eq(fresh.blood_markers, 1, "Tough: ayaktaki model 1 Kan İşareti alır")
	var golem := FakeUnit.new()
	golem.unit_data = UnitData.new()
	golem.unit_data.keywords[&"golem"] = 1
	golem.is_down = true
	InjuryResolver._resolve_out_of_action(golem)
	t.eq(golem.blood_markers, 2, "Golem: zaten Down iken 2 Kan İşareti")
	for n in [tough, fresh, golem]:
		n.free()
