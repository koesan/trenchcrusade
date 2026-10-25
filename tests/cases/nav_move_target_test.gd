extends RefCounted

## MovementHelper.resolve_nav_target — hareket hedefinin NavMesh'e hizalanması.
## Kural: hedef HER ZAMAN en yakın navigasyon noktasına (snapped) hizalanır — birim duvarın
## ortasına konmaz, en yakın geçerli zemine (üst kenar / siper tabanı) gider. Ham tıklama YATAYDA
## çok uzaksa (harita dışı / boşluk) hareket reddedilir.

const MovementHelper = preload("res://scripts/utils/movement_helper.gd")

func run(t) -> void:
	var tol := 2.5

	# Yüzey üzeri tıklama: snapped'e hizalanır (aynı nokta).
	var on_surface := Vector3(3, -1.5, 2)
	var r1 = MovementHelper.resolve_nav_target(on_surface, on_surface, tol)
	t.ok(r1.valid, "Yüzey üzeri tıklama geçerli")
	t.approx(r1.target.y, -1.5, "Hedef navigasyon noktasına hizalı")

	# Duvar YÜZÜNE tıklama (aynı x/z, farklı yükseklik): yatayda yakın → geçerli, hedef = snapped
	# (üst kenar ya da siper tabanı). Birim duvarın ortasına GİTMEZ.
	var raw_wall := Vector3(3, -3.0, 2)          # duvar yüzü, tabandan yukarı
	var snapped_floor := Vector3(3, -5.0, 2)     # en yakın nav noktası (siper tabanı), aynı x/z
	var r2 = MovementHelper.resolve_nav_target(snapped_floor, raw_wall, tol)
	t.ok(r2.valid, "Duvar yüzü tıklaması geçerli (yatayda yakın)")
	t.approx(r2.target.y, -5.0, "Hedef duvar ortası DEĞİL, navigasyon tabanına hizalanır")

	# Harita dışı / boşluk: en yakın nav noktası YATAYDA çok uzak → reddedilir.
	var raw_void := Vector3(20, -1.5, 20)
	var snapped_edge := Vector3(3, -1.5, 2)      # yatay mesafe ~24 > 2.5
	t.ok(not MovementHelper.resolve_nav_target(snapped_edge, raw_void, tol).valid,
		"Harita dışı (yatayda uzak) tıklama REDDEDİLİR")

	# Sınır: tam tolerans kadar yatay uzaklıkta geçerli (<=).
	var raw_edge := Vector3(3 + 2.5, -1.5, 2)
	t.ok(MovementHelper.resolve_nav_target(Vector3(3, -1.5, 2), raw_edge, tol).valid,
		"Tam tolerans yatay mesafe geçerli (sınır dahil)")
