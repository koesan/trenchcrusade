extends RefCounted

## Siper (Trench) arazi parçası `[Cover]` verir; Sultanate Sapper Forward Positions ile
## yerleşim bölgesinin 6" ötesine konuşlanabilir.
##
## KAYNAKLAR:
##  - comprehensive-rules/terrain.md: [Cover] → menzilli saldırılara -1 Dice
##  - iron-sultanate.md (Sultanate Sapper): "you can deploy them up to 6" away from your
##    deployment zone and in contact with a terrain piece that is at least ½" high"

func run(t) -> void:
	# ── SİPER → [Cover] ────────────────────────────────────────────────────
	TerrainManager.clear_all()
	var trench: Resource = load("res://assets/data/terrain/trench.tres")
	TerrainManager.spawn_feature(trench, Vector3(0, 0, 0), "")

	t.eq(TerrainManager.has_keyword_at(Vector3(0, 0, 0), &"cover"), true,
		"Siper üzerinde [Cover]")
	t.eq(TerrainManager.has_keyword_at(Vector3(1.5, 0, 0), &"cover"), true,
		"Siper yarıçapı içinde [Cover]")
	t.eq(TerrainManager.has_keyword_at(Vector3(20, 0, 0), &"cover"), false,
		"Siperden uzakta [Cover] yok")
	t.eq(TerrainManager.has_keyword_at(Vector3(0, 0, 0), &"mined"), false,
		"Siper [Mined] DEĞİL")

	# ── FORWARD POSITIONS ──────────────────────────────────────────────────
	var sapper: Resource = load("res://assets/data/units/sultanate_sapper.tres")
	t.ok(KeywordSystem.has(sapper, &"forward_positions"),
		"Sultanate Sapper → [forward_positions] keyword'ü")
	t.eq(DeployRules.has_forward_positions(sapper), true, "Sapper → Forward Positions var")

	t.eq(DeployRules.forward_position_allowed(sapper, 6.0, true), true,
		"Sapper: 6\" ileri + arazi teması → İZİNLİ")
	t.eq(DeployRules.forward_position_allowed(sapper, 3.0, true), true,
		"Sapper: 3\" ileri + arazi teması → izinli")
	t.eq(DeployRules.forward_position_allowed(sapper, 6.0, false), false,
		"Sapper: arazi teması YOK → reddedilir")
	t.eq(DeployRules.forward_position_allowed(sapper, 9.0, true), false,
		"Sapper: 9\" > 6\" → reddedilir")

	var azeb: Resource = load("res://assets/data/units/azebs.tres")
	t.eq(DeployRules.has_forward_positions(azeb), false, "Azeb → Forward Positions yok")
	t.eq(DeployRules.forward_position_allowed(azeb, 6.0, true), false,
		"Forward Positions yeteneği olmayan birim → reddedilir")
	t.eq(DeployRules.forward_position_allowed(null, 1.0, true), false, "null birim → reddedilir")
	t.eq(DeployRules.FORWARD_POSITION_RANGE, 6.0, "Forward Positions menzili 6\" (compendium)")

	# ── SENARYOLARDA OTOMATİK SİPER OLMAMALI ──────────────────────────────
	# Compendium'da "bu senaryoda siper vardır" diye bir kural YOKTUR; siper Fortify/Dug In
	# ile OYUNCU tarafından kurulur (bkz. fortify_terrain_test.gd). Alan şeması korunuyor —
	# ileride gerçekten arazi tanımlayan bir senaryo eklenebilir.
	for sc_name in ["great_war", "fields_of_glory", "marked_for_death", "relic_hunt",
			"the_high_ground", "claim_no_mans_land"]:
		var path := "res://assets/data/scenarios/%s.tres" % sc_name
		if not ResourceLoader.exists(path):
			continue
		var sc: Resource = load(path)
		t.ok("terrain_placements" in sc, "%s → terrain_placements şeması var" % sc_name)
		t.eq(sc.terrain_placements.size(), 0, "%s → otomatik siper yok" % sc_name)

	TerrainManager.clear_all()
