extends RefCounted

## EKRAN ÖLÇEĞİ — arayüz çözünürlüğe uyum sağlamalı.
##
## SORUN (kullanıcı bildirimi): "görüntü alanı sabit olmasın, ayarlardaki çözünürlüğe göre
## otomatik ayarlansın, tüm UI sadece 1280x720 olmasın". Proje `stretch/mode = canvas_items` +
## sabit 1280x720 tabanla kurulmuştu ve `stretch/aspect` ayarlanmamıştı → 1920x1080'de her şey
## 1.5 kat BÜYÜTÜLÜYOR, mantıksal alan hâlâ 1280x720 kalıyordu. Daha büyük ekran daha fazla YER
## kazandırmıyor, sadece kabalaştırıyordu.
##
## ⚠ İLK DENEMEDE `content_scale_factor` kullanıldı ve alan TERS yönde değişti (1080p'de
## 1024x576'ya DÜŞTÜ, paneller sığmaz oldu). Doğrusu `content_scale_size`. Bu test o hatanın
## geri gelmesini engeller: mantıksal alan taban çözünürlükten KÜÇÜK olamaz.

func run(t) -> void:
	# ── Büyütme oranı: çözünürlükle artmalı, ama ondan YAVAŞ ──────────────
	t.approx(DisplayScale.factor_for_height(720.0), 1.00, "720p → büyütme 1.0 (taban)")
	t.approx(DisplayScale.factor_for_height(1080.0), 1.25, "1080p → büyütme 1.25")
	t.approx(DisplayScale.factor_for_height(1440.0), 1.60, "1440p → büyütme 1.60")
	t.approx(DisplayScale.factor_for_height(2160.0), 2.40, "4K → büyütme 2.40")
	t.approx(DisplayScale.factor_for_height(900.0), 1.10, "900p → büyütme 1.10")
	# Kırılma noktaları arasında enterpolasyon (ara çözünürlükler de düzgün ölçeklenmeli).
	var mid: float = DisplayScale.factor_for_height(990.0)
	t.ok(mid > 1.10 and mid < 1.25, "Ara çözünürlük (990p) enterpole ediliyor: %.3f" % mid)
	# Taban altı ve 4K üstü uçlar.
	t.approx(DisplayScale.factor_for_height(600.0), 1.00, "720p altı → tabana sabitlenir")
	t.ok(DisplayScale.factor_for_height(4320.0) > 2.40, "4K üstü → büyütme artmaya devam eder")

	# ── ASIL GÜVENCE: mantıksal alan taban çözünürlükten KÜÇÜLMEZ ────────
	var base := Vector2i(1280, 720)
	for res in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080),
			Vector2i(2560, 1440), Vector2i(3840, 2160)]:
		var logical: Vector2i = DisplayScale.logical_size_for(res)
		t.ok(logical.x >= base.x and logical.y >= base.y,
			"%dx%d → mantıksal %dx%d, tabandan küçük DEĞİL" % [res.x, res.y, logical.x, logical.y])

	# Yüksek çözünürlük GERÇEKTEN daha fazla alan vermeli (sadece büyütmemeli).
	var l720: Vector2i = DisplayScale.logical_size_for(Vector2i(1280, 720))
	var l1080: Vector2i = DisplayScale.logical_size_for(Vector2i(1920, 1080))
	t.ok(l1080.x > l720.x and l1080.y > l720.y,
		"1080p, 720p'den DAHA FAZLA mantıksal alan verir (%dx%d > %dx%d)" \
			% [l1080.x, l1080.y, l720.x, l720.y])

	# Ultra-wide: fazladan genişlik mantıksal alana eklenmeli (siyah bant değil).
	var ultra: Vector2i = DisplayScale.logical_size_for(Vector2i(3440, 1440))
	t.ok(ultra.x > DisplayScale.logical_size_for(Vector2i(2560, 1440)).x,
		"Ultra-wide ekranda fazladan genişlik mantıksal alana ekleniyor")

	# ── project.godot sözleşmesi ─────────────────────────────────────────
	# `aspect = expand` olmadan farklı en-boy oranlarında siyah bant oluşur.
	t.eq(ProjectSettings.get_setting("display/window/stretch/aspect", ""), "expand",
		"stretch/aspect = expand (en-boy oranı farkı siyah bant üretmez)")
	t.eq(ProjectSettings.get_setting("display/window/stretch/mode", ""), "canvas_items",
		"stretch/mode = canvas_items")
	t.eq(int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)),
		int(DisplayScale.BASE_HEIGHT),
		"Taban yükseklik project.godot ile aynı")
	t.ok(bool(ProjectSettings.get_setting("display/window/size/resizable", false)),
		"Pencere yeniden boyutlandırılabilir (ölçek buna göre yenilenir)")
