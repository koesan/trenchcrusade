extends RefCounted

## ARAZİ TİPİ KURALLARI — compendium `keyword.md` (DIFFICULT / DANGEROUS TERRAIN).
##
## 2026-07-29 denetimi: `suffers_difficult_terrain` YAZILMIŞ ve TEST EDİLMİŞTİ ama hareket
## akışından HİÇ ÇAĞRILMIYORDU — Difficult Terrain'in oyunda hiçbir etkisi yoktu. Dangerous
## Terrain ise hiç uygulanmamıştı (yalnız özel hâli olan Mined vardı).

func _ud(kws: Array[StringName] = []) -> UnitData:
	var u := UnitData.new()
	for kw in kws:
		u.keywords[kw] = true
	return u

func run(t) -> void:
	TerrainManager.clear_all()

	# ── DIFFICULT TERRAIN: 1" = 2" → etkin menzil YARIYA iner ────────────
	t.approx(TerrainRules.DIFFICULT_TERRAIN_FACTOR, 0.5,
		"Difficult Terrain çarpanı 0.5 (RAW: 1\" = 2\")")

	var plain := _ud()
	var open_pos := Vector3(50, 0, 50)
	t.approx(TerrainRules.effective_move_distance(plain, open_pos, 6.0), 6.0,
		"Açık arazide menzil değişmez")

	# Zorlu arazi parçası koy.
	var difficult := TerrainFeatureData.new()
	difficult.keywords = {&"difficult": 1}
	difficult.radius = 2.0
	TerrainManager.spawn_feature(difficult, open_pos, "")

	t.approx(TerrainRules.effective_move_distance(plain, open_pos, 6.0), 3.0,
		"Zorlu arazide menzil yarıya iner")

	# [Negate Difficult Terrain] (War Wolf) muaftır.
	var wolf := _ud([&"negate_difficult_terrain"])
	t.approx(TerrainRules.effective_move_distance(wolf, open_pos, 6.0), 6.0,
		"[Negate Difficult Terrain] taşıyan model cezadan MUAF")

	# ── DANGEROUS TERRAIN tespiti ────────────────────────────────────────
	t.ok(not TerrainRules.is_dangerous(open_pos),
		"Zorlu arazi tehlikeli DEĞİLDİR (ayrı keyword'ler)")

	var danger_pos := Vector3(-50, 0, -50)
	var dangerous := TerrainFeatureData.new()
	dangerous.keywords = {&"dangerous_terrain": 1, &"fire": 1}
	dangerous.radius = 2.0
	TerrainManager.spawn_feature(dangerous, danger_pos, "")
	t.ok(TerrainRules.is_dangerous(danger_pos), "Tehlikeli arazi tespit ediliyor")
	t.ok(not TerrainRules.is_dangerous(Vector3(200, 0, 200)),
		"Uzak nokta tehlikeli değil")

	# Arazinin element keyword'ü Injury Roll'a taşınmalı (RAW: "any Injury Rolls caused by the
	# DANGEROUS TERRAIN rule have those Keywords").
	var src: Resource = TerrainRules._terrain_injury_source(danger_pos)
	t.ok(src != null, "Elementli tehlikeli arazi → Injury Roll kaynağı üretiliyor")
	if src != null:
		t.ok(KeywordSystem.has(src, &"fire"), "Arazi elementi (Fire) Injury Roll'a taşınıyor")
	t.eq(TerrainRules._terrain_injury_source(Vector3(200, 0, 200)), null,
		"Elementsiz/arazisiz nokta → düz Injury Roll (null kaynak)")

	TerrainManager.clear_all()

	# ── KURALLAR HAREKET AKIŞINA BAĞLI MI? ───────────────────────────────
	# (Asıl bulgu buydu: helper vardı, çağrı yoktu.)
	var usrc := FileAccess.open("res://scenes/unit/unit.gd", FileAccess.READ)
	t.ok(usrc != null, "unit.gd okunabildi")
	if usrc != null:
		var utxt := usrc.get_as_text()
		usrc.close()
		t.eq(utxt.count("TerrainRules.effective_move_distance"), 2,
			"Difficult Terrain HEM Move HEM Retreat akışına bağlı")

	var msrc := FileAccess.open("res://scripts/unit/unit_movement.gd", FileAccess.READ)
	t.ok(msrc != null, "unit_movement.gd okunabildi")
	if msrc != null:
		var mtxt := msrc.get_as_text()
		msrc.close()
		t.ok(mtxt.contains("TerrainRules.check_dangerous_terrain"),
			"Dangerous Terrain hareket VARIŞINA bağlı (mayınla aynı kanca)")
