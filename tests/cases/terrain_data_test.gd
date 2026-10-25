extends RefCounted

## Arazi parçası tanımları (Mayın, Siper) ve model varlıkları.
##
## KAYNAKLAR:
##  - iron-sultanate.md (Sultanate Sapper): Set Mine / Defuse Mine / Detonating Mines / [Negate Mined]
##  - new-antioch.md (Combat Engineer): aynı kural metni
##  - comprehensive-rules/terrain.md: [Cover] — "-1 Dice to Ranged Attacks targeting the model"

func run(t) -> void:
	# Kullanıcının sağladığı modeller proje yapısındaki doğru yerde olmalı
	t.ok(ResourceLoader.exists("res://assets/models/scenario/mine.glb"),
		"mine.glb → assets/models/scenario/ altında")
	t.ok(ResourceLoader.exists("res://assets/models/scenario/trench.glb"),
		"trench.glb → assets/models/scenario/ altında")
	# Proje kökünde artık durmamalı
	t.ok(not ResourceLoader.exists("res://mine_model.glb"), "mine_model.glb kökten taşındı")
	t.ok(not ResourceLoader.exists("res://trench_model.glb"), "trench_model.glb kökten taşındı")

	var mine: Resource = load("res://assets/data/terrain/mine.tres")
	t.ok(mine != null, "mine.tres yüklendi")
	if mine != null:
		t.eq(mine.feature_id, &"mine", "mine → feature_id")
		t.ok(KeywordSystem.has(mine, &"mined"), "Mayın → [Mined] keyword'ü")
		t.ok(not KeywordSystem.has(mine, &"cover"), "Mayın → [Cover] VERMEZ")
		t.eq(mine.model_path, "res://assets/models/scenario/mine.glb", "mine → model yolu")
		t.approx(mine.radius, 1.0, "Mayın yarıçapı 1\" (temas mesafesi)")
		t.eq(mine.is_consumed_on_trigger, true, "Mayın patlayınca sahadan kalkar")
		t.ok(LocalizationManager.has_key(mine.display_name_key), "mine → ad anahtarı localization'da")
		t.ok(LocalizationManager.has_key(mine.desc_key), "mine → açıklama anahtarı localization'da")

	var trench: Resource = load("res://assets/data/terrain/trench.tres")
	t.ok(trench != null, "trench.tres yüklendi")
	if trench != null:
		t.eq(trench.feature_id, &"trench", "trench → feature_id")
		t.ok(KeywordSystem.has(trench, &"cover"), "Siper → [Cover] keyword'ü")
		t.ok(not KeywordSystem.has(trench, &"mined"), "Siper → [Mined] DEĞİL")
		t.eq(trench.model_path, "res://assets/models/scenario/trench.glb", "trench → model yolu")
		t.ok(trench.radius >= 1.0, "Siper yarıçapı >= 1\"")
		t.eq(trench.is_consumed_on_trigger, false, "Siper kalıcı (tüketilmez)")
		t.ok(LocalizationManager.has_key(trench.display_name_key), "trench → ad anahtarı localization'da")
		t.ok(LocalizationManager.has_key(trench.desc_key), "trench → açıklama anahtarı localization'da")

	# TerrainPlacement şeması (senaryolara önceden yerleştirme için)
	var tp := TerrainPlacement.new()
	t.ok("feature" in tp, "TerrainPlacement → feature alanı")
	t.ok("position" in tp, "TerrainPlacement → position alanı")
	t.ok("rotation_y" in tp, "TerrainPlacement → rotation_y alanı")
