extends RefCounted

## TerrainManager sahadaki arazi parçalarının TEK kaydıdır — GameState.units deseninin
## arazi karşılığı, ama AYRI dosyada (GameState god-file'a dönüşmesin).

func run(t) -> void:
	TerrainManager.clear_all()
	t.eq(TerrainManager.feature_count(), 0, "Başlangıçta arazi parçası yok")

	var mine_data: Resource = load("res://assets/data/terrain/mine.tres")
	var trench_data: Resource = load("res://assets/data/terrain/trench.tres")

	# ── MAYIN ──────────────────────────────────────────────────────────────
	var n = TerrainManager.spawn_feature(mine_data, Vector3(5, 0, 5), "Sapper1")
	t.ok(n != null, "Mayın oluşturuldu")
	t.eq(TerrainManager.feature_count(), 1, "Kayıtta 1 arazi parçası")

	t.eq(TerrainManager.has_keyword_at(Vector3(5, 0, 5), &"mined"), true,
		"Mayın konumunda [Mined] var")
	t.eq(TerrainManager.has_keyword_at(Vector3(5.5, 0, 5.0), &"mined"), true,
		"Yarıçap içinde (0.5\") [Mined] var")
	t.eq(TerrainManager.has_keyword_at(Vector3(50, 0, 50), &"mined"), false,
		"Uzak konumda [Mined] yok")
	t.eq(TerrainManager.has_keyword_at(Vector3(5, 0, 5), &"cover"), false,
		"Mayın [Cover] VERMEZ")
	t.eq(TerrainManager.setter_of(Vector3(5, 0, 5)), "Sapper1",
		"Mayını kuran model kaydedildi (otomatik etkisizleştirme için gerekli)")
	t.eq(TerrainManager.features_at(Vector3(5, 0, 5)).size(), 1, "features_at → 1 parça")

	# ── SİPER (ayrı konumda, karışmamalı) ──────────────────────────────────
	TerrainManager.spawn_feature(trench_data, Vector3(-10, 0, 0), "")
	t.eq(TerrainManager.feature_count(), 2, "Kayıtta 2 arazi parçası")
	t.eq(TerrainManager.has_keyword_at(Vector3(-10, 0, 0), &"cover"), true,
		"Siper konumunda [Cover] var")
	t.eq(TerrainManager.has_keyword_at(Vector3(-9, 0, 0), &"cover"), true,
		"Siper yarıçapı (2\") içinde [Cover] var")
	t.eq(TerrainManager.has_keyword_at(Vector3(-10, 0, 0), &"mined"), false,
		"Siper [Mined] DEĞİL")
	t.eq(TerrainManager.setter_of(Vector3(-10, 0, 0)), "",
		"Senaryo yerleşiminin kurucusu yok")

	# ── TÜKETME (mayın patlaması) ──────────────────────────────────────────
	TerrainManager.consume_at(Vector3(5, 0, 5))
	t.eq(TerrainManager.has_keyword_at(Vector3(5, 0, 5), &"mined"), false,
		"Patlayan mayın kayıttan düşer")
	t.eq(TerrainManager.feature_count(), 1, "Geriye yalnız siper kalır")

	# Siper `is_consumed_on_trigger = false` → tüketilmemeli
	TerrainManager.consume_at(Vector3(-10, 0, 0))
	t.eq(TerrainManager.has_keyword_at(Vector3(-10, 0, 0), &"cover"), true,
		"Siper KALICI — consume_at onu kaldırmaz")

	# ── DEFUSE (yalnız [Mined] parçayı kaldırır) ───────────────────────────
	TerrainManager.spawn_feature(mine_data, Vector3(20, 0, 0), "Engineer1")
	t.eq(TerrainManager.defuse_at(Vector3(20, 0, 0)), true, "Mayın etkisizleştirildi")
	t.eq(TerrainManager.has_keyword_at(Vector3(20, 0, 0), &"mined"), false,
		"Etkisizleştirilen mayın artık [Mined] değil")
	t.eq(TerrainManager.defuse_at(Vector3(-10, 0, 0)), false,
		"Siperde etkisizleştirilecek mayın yok")

	TerrainManager.clear_all()
	t.eq(TerrainManager.feature_count(), 0, "clear_all tümünü temizler")
