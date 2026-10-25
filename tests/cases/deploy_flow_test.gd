extends RefCounted

## YERLEŞTİRME ZİNCİRİ — kapı sözleşmesi, sıra görünürlüğü ve sabitler.
##
## `game.gd::request_deploy_unit` 292 satırlık tek bir prosedürdü; hangi kuralın hangi sırada
## işlediğini görmek için tamamını okumak gerekiyordu. Artık `DeployFlow.validate()` okununca
## tüm kural listesi ve SIRASI tek ekranda görünüyor — bu test o listenin eksiksiz kaldığını
## ve `game.gd`nin gerçekten delege ettiğini doğrular.

const FLOW_PATH := "res://scripts/rules/deploy/deploy_flow.gd"

## `validate()` içinde bu SIRAYLA görünmesi gereken kapılar. Sıra ANLAMLIDIR: ucuz/kesin
## kontroller önce, konum çözümlemesi ortada (sonrakiler hizalanmış konumu okur), oranlar sonda.
const EXPECTED_ORDER := [
	"_gate_phase",
	"_gate_deploy_budget_remaining",
	"_gate_faction_selected",
	"_gate_roster_membership",
	"_gate_loadout_availability",
	"_gate_resolve_loadout",
	"_gate_affordable",
	"_gate_loadout_valid",
	"_gate_nav_snap",
	"_gate_assign_deploy_side",
	"_gate_placement",
	"_gate_unit_spacing",
	"_gate_court_wretched_ratio",
	"_gate_legionnaire_ratio",
	"_gate_elite_cap",
	"_gate_order_of_the_fly",
	"_gate_availability_max",
]

func run(t) -> void:
	var flow: GDScript = load(FLOW_PATH)
	t.ok(flow != null, "deploy_flow.gd yüklenebiliyor")

	# ── Her kapı gerçekten var mı? ────────────────────────────────────────
	for gate in EXPECTED_ORDER:
		t.ok(flow.has_method(gate), "DeployFlow.%s() var" % gate)
	t.ok(flow.has_method("build"), "DeployFlow.build() var")
	t.ok(flow.has_method("validate"), "DeployFlow.validate() var")

	# ── Sıra korunuyor mu? ────────────────────────────────────────────────
	var src := FileAccess.open(FLOW_PATH, FileAccess.READ)
	t.ok(src != null, "deploy_flow.gd okunabildi")
	if src != null:
		var txt := src.get_as_text()
		src.close()
		var last_pos := -1
		var order_ok := true
		var broke_at := ""
		for gate in EXPECTED_ORDER:
			# `validate()` içindeki dizi girdisi — tanım satırı (`static func`) değil.
			var pos := txt.find("\t\t%s," % gate)
			if pos < 0 or pos < last_pos:
				order_ok = false
				broke_at = gate
				break
			last_pos = pos
		t.ok(order_ok, "Kapı sırası validate() içinde beklendiği gibi (kırıldığı yer: '%s')" % broke_at)

	# ── Sabitler compendium değerleriyle uyumlu mu? ───────────────────────
	t.eq(DeployFlow.FREE_DEPLOY_MIN_ENEMY_DIST, 8.0,
		"Infiltrator/Automaton Destrier düşman mesafesi 8\"")
	t.eq(DeployFlow.EDGE_TOLERANCE, 1.0, "Automaton Destrier kenar şeridi 1\"")
	t.eq(DeployFlow.MIN_UNIT_SPACING, 2.0, "Modeller arası asgari yerleşim mesafesi 2\"")
	t.ok(DeployFlow.EDGE_SNAP_RADIUS > DeployFlow.EDGE_TOLERANCE,
		"Kenar hizalama yarıçapı şeritten GENİŞ (kullanılabilirlik toleransı)")

	# ── DeployRequest yardımcıları ────────────────────────────────────────
	var req := DeployRequest.new()
	req.closest_pos = Vector3(3, 1, 4)
	var sp := req.spawn_position()
	t.approx(sp.y, 1.02, "spawn_position() küçük bir yükseklik payı ekler")
	t.approx(sp.x, 3.0, "spawn_position() yatayda konumu değiştirmez")
	t.eq(req.sender_id, 1, "DeployRequest varsayılan sender_id")
	t.eq(req.loadout_index, -1, "DeployRequest varsayılan loadout_index (varsayılan Battlekit)")

	# ── game.gd artık YALNIZ yönlendirici ────────────────────────────────
	var gs := FileAccess.open("res://scenes/game/game.gd", FileAccess.READ)
	t.ok(gs != null, "game.gd okunabildi")
	if gs != null:
		var gtxt := gs.get_as_text()
		gs.close()
		t.ok(gtxt.contains("DeployFlow.validate(req)"),
			"game.gd doğrulamayı DeployFlow'a delege ediyor")
		t.ok(gtxt.contains("DeployFlow.build("),
			"game.gd bağlamı DeployFlow.build ile kuruyor")
		# Kural gövdeleri geri sızmamalı — bunlar artık YALNIZ deploy_flow.gd'de.
		for leaked in ["REASON_LEGIONNAIRE_RATIO", "REASON_ELITE_CAP", "REASON_ORDER_OF_FLY",
				"REASON_AUTOMATON_DESTRIER", "REASON_INFILTRATOR"]:
			t.ok(not gtxt.contains(leaked),
				"game.gd'de kural gövdesi kalmadı: %s" % leaked)
