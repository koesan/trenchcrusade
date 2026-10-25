extends RefCounted

## Dikey erişim göstergesi DÖRT sınıfa ayrılmalı ve sınıflandırma `ClimbingResolver` ile
## AYNI eşikleri kullanmalı — aksi hâlde oyuncuya gösterilen renk, hareket ettiğinde
## karşılaşacağı kuraldan farklı olur (görsel ile mekanik çelişir).
##
## KURAL (ClimbingResolver):
##   |dy| <= VERTICAL_STEP_MAX  → düz zemin, işaret YOK
##   yukarı, dy <= CLIMB_FREE_MAX (3")  → walkover_up   : serbest, zar YOK
##   yukarı, dy >  CLIMB_FREE_MAX       → climb         : Risky Success
##   aşağı,  |dy| <= CLIMB_FREE_MAX     → walkover_down : serbest, zar YOK
##   aşağı,  |dy| >  CLIMB_FREE_MAX     → climb_down    : Risky Success
## Hareket bütçesi yetmiyorsa hiç gösterilmez (yukarı: yatay+yükseklik, aşağı: yalnız yatay).

const PathRangeVisualizer = preload("res://scenes/unit/path_range_visualizer.gd")

func run(t) -> void:
	var free_max: float = GameState.CLIMB_FREE_MAX
	var step_max: float = GameState.VERTICAL_STEP_MAX

	# ── Düz zemin ──────────────────────────────────────────────────────────
	t.eq(PathRangeVisualizer.classify_vertical(0.0, 2.0, 6.0), "", "Düz zemin → işaret yok")
	t.eq(PathRangeVisualizer.classify_vertical(step_max * 0.5, 2.0, 6.0), "",
		"Küçük basamak (VERTICAL_STEP_MAX altı) → işaret yok")

	# ── Yukarı ─────────────────────────────────────────────────────────────
	t.eq(PathRangeVisualizer.classify_vertical(free_max - 0.5, 2.0, 12.0), "walkover_up",
		"Alçak duvar (<=3\") → serbest çıkış, zar yok")
	t.eq(PathRangeVisualizer.classify_vertical(free_max + 1.0, 2.0, 12.0), "climb",
		"Yüksek duvar (>3\") → Risky tırmanış")

	# ── Aşağı ──────────────────────────────────────────────────────────────
	t.eq(PathRangeVisualizer.classify_vertical(-(free_max - 0.5), 2.0, 12.0), "walkover_down",
		"Alçak iniş (<=3\") → serbest")
	t.eq(PathRangeVisualizer.classify_vertical(-(free_max + 1.0), 2.0, 12.0), "climb_down",
		"Yüksek iniş (>3\") → Risky")

	# ── Hareket bütçesi ────────────────────────────────────────────────────
	# Yukarı: yatay + yükseklik birlikte sayılır
	t.eq(PathRangeVisualizer.classify_vertical(free_max + 1.0, 20.0, 6.0), "",
		"Yukarı: bütçe yetmiyor → gösterilmez")
	t.eq(PathRangeVisualizer.classify_vertical(2.0, 3.0, 6.0), "walkover_up",
		"Yukarı: 3+2=5 <= 6 → gösterilir")
	# Aşağı: yalnız yatay sayılır (dikey serbest)
	t.eq(PathRangeVisualizer.classify_vertical(-10.0, 3.0, 6.0), "climb_down",
		"Aşağı: dikey mesafe bütçeye SAYILMAZ, 3 <= 6 → gösterilir")
	t.eq(PathRangeVisualizer.classify_vertical(-10.0, 20.0, 6.0), "",
		"Aşağı: yatay bütçe yetmiyor → gösterilmez")

	# ── Renk sözleşmesi: dört sınıfın da AYRI rengi olmalı ────────────────
	var colors: Dictionary = PathRangeVisualizer.VERTICAL_COLORS
	t.eq(colors.size(), 4, "Dört dikey erişim sınıfı tanımlı")
	for key in ["walkover_up", "climb", "walkover_down", "climb_down"]:
		t.ok(colors.has(key), "VERTICAL_COLORS → %s" % key)
	var seen: Array = []
	for key in colors.keys():
		var c: Color = colors[key]
		var rgb := "%.2f,%.2f,%.2f" % [c.r, c.g, c.b]
		t.ok(not seen.has(rgb), "%s rengi benzersiz (eskiden iki soluk gri aynıydı)" % key)
		seen.append(rgb)
		t.ok(c.a >= 0.8, "%s yeterince opak (uzaktan görünsün)" % key)

	# Ok işaretçileri yerine kenar boyunca renkli bölge (kullanıcı: "tuhaf oklar")
	t.ok(PathRangeVisualizer.ZONE_DEPTH > PathRangeVisualizer.ZONE_EDGE and PathRangeVisualizer.ZONE_EDGE > 0.0,
		"Dikey erişim bölgesi: parlak kenar + sönen gövde")
	var src := FileAccess.get_file_as_string("res://scenes/unit/path_range_visualizer.gd")
	t.ok(not src.contains("_add_arrow_marker"), "Eski ok işaretçileri kaldırıldı")
