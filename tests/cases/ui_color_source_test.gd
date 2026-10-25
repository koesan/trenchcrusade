extends RefCounted

## TASARIM DİLİ BEKÇİSİ — UI renkleri TEK KAYNAKTAN (`gothic_theme.tres`) gelir.
##
## SORUN: aynı anlam için kod tabanında ÜÇ ayrı kırmızı ve ÜÇ ayrı turuncu dolaşıyordu.
## `unit_status_panel.gd` beş rengi kendi `const`ları olarak yeniden tanımlıyordu — biri
## `color_gold_bright`in BİREBİR kopyası, ikisi mevcut tema renklerinin bir tık farklı
## varyantıydı; `dice_bar.gd` ise tema aramalarıyla çıplak `Color()`ları karıştırıyordu.
## Sonuç: aynı durumu (ör. "Down") gösteren iki panel farklı tonda turuncu kullanıyordu ve
## bir tonu değiştirmek için kaç dosyaya dokunulacağı belirsizdi.
##
## Tema üreticisi (`gothic_theme_builder.gd`) TEK KAYNAKTIR ve `.tres` ondan üretilir; bu test
## kaynağın atlanmadığını doğrular.

const UI_DIRS := ["res://scenes/ui", "res://scripts/ui"]

## Çıplak `Color()` kullanmasına İZİN VERİLEN dosyalar (yol → gerekçe).
const EXEMPT := {
	"res://scripts/ui/theme/gothic_theme_builder.gd":
		"tema ÜRETİCİSİ — renklerin tanımlandığı yer burası",
	"res://scripts/ui/ui_preview_helper.gd":
		"3B önizleme ortam ışığı — arayüz paleti değil, sahne aydınlatması",
	"res://scenes/ui/armoury/armoury_panel.gd":
		"yalnız modulate ALFA (soluklaştırma), renk tonu değil",
	"res://scenes/ui/hud/deploy/deploy_unit_card.gd":
		"yalnız modulate ALFA sıfırlaması Color(1,1,1,1), renk tonu değil",
}

## Temada BULUNMASI gereken anlamsal durum renkleri.
const REQUIRED_COLORS := [
	"color_status_danger", "color_status_warn", "color_status_caution", "color_status_good",
	"color_gold_bright", "color_dim_text", "color_muted", "color_parchment",
]

func _scan(dir_path: String, out: Array) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		var full := dir_path.path_join(f)
		if d.current_is_dir():
			if not f.begins_with("."):
				_scan(full, out)
		elif f.ends_with(".gd"):
			out.append(full)
		f = d.get_next()
	d.list_dir_end()

func run(t) -> void:
	# ── Anlamsal renkler temada var mı? ───────────────────────────────────
	var theme: Theme = load("res://assets/themes/gothic_theme.tres")
	t.ok(theme != null, "gothic_theme.tres yüklendi")
	for c in REQUIRED_COLORS:
		t.ok(theme.has_color(c, "Constants"), "Tema rengi tanımlı: %s" % c)

	# Paylaşılan erişim noktası çalışıyor mu?
	t.eq(GothicThemeHelper.color("color_status_warn"),
		theme.get_color("color_status_warn", "Constants"),
		"GothicThemeHelper.color() tema ile aynı değeri döndürüyor")

	# ── Çıplak Color() kalmadı mı? ────────────────────────────────────────
	var files: Array = []
	for dir in UI_DIRS:
		_scan(dir, files)
	t.ok(files.size() > 20, "%d UI script'i tarandı" % files.size())

	var offenders: Array = []
	for path in files:
		if EXEMPT.has(path):
			continue
		var fa := FileAccess.open(path, FileAccess.READ)
		if fa == null:
			continue
		var txt := fa.get_as_text()
		fa.close()
		for line in txt.split("\n"):
			var stripped := line.strip_edges()
			if stripped.begins_with("#"):
				continue
			if stripped.contains("Color("):
				offenders.append("%s → %s" % [path.get_file(), stripped])

	t.eq(offenders.size(), 0,
		"UI'da çıplak Color() yok (GothicThemeHelper.color kullan): %s" % str(offenders))

	# ── Her dosya temayı KENDİ preload'uyla okumamalı ─────────────────────
	# Altı script bu iki satırı (preload + get_color) yerel yardımcı olarak tekrarlıyordu.
	var local_theme_loaders: Array = []
	for path in files:
		# theme_helper: paylaşılan erişim noktasının KENDİSİ.
		# theme_builder: .tres'i ÜRETEN araç — okumak değil, yazmak için referans veriyor.
		if path == "res://scripts/ui/theme/theme_helper.gd" \
				or path == "res://scripts/ui/theme/gothic_theme_builder.gd":
			continue
		var fa2 := FileAccess.open(path, FileAccess.READ)
		if fa2 == null:
			continue
		var txt2 := fa2.get_as_text()
		fa2.close()
		if txt2.contains("assets/themes/gothic_theme.tres"):
			local_theme_loaders.append(path.get_file())
	t.eq(local_theme_loaders.size(), 0,
		"Tema yalnız GothicThemeHelper üzerinden okunuyor: %s" % str(local_theme_loaders))
