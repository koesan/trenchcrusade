extends Node

## UI YERLEŞİM ÖLÇÜMÜ (dördüncü kapı) — `godot --headless res://tests/ui_layout_check.tscn`
##
## NEDEN AYRI BİR SAHNE: gerçek yerleşim ancak düğüm ağaca eklenip container'lar bir-iki kare
## boyunca çözüldükten SONRA ölçülebilir. Ana süit senkron çalıştığı için bunu yapamıyor
## (bkz. `hud_smoke.gd`deki aynı gerekçe).
##
## NE YAPAR: her UI sahnesini hedef çözünürlükte (1280x720 — project.godot'taki viewport)
## kurar (ayarlardaki TÜM çözünürlükler için ayrı ayrı) ve şunları ölçer:
##   1. Panelin kendisi görüntü alanına sığıyor mu?
##   2. TIKLANABİLİR öğeler (Button/Slider/OptionButton/LineEdit) tamamen ekranın içinde mi?
##      Ekran dışına taşan bir buton = oyuncunun ERİŞEMEDİĞİ bir buton.
##
## Bu, ekran görüntüsü alamadan yapılabilen en somut UI doğrulamasıdır: "görsel olarak güzel mi"
## sorusuna cevap VERMEZ, ama "kullanılabilir mi" sorusuna kesin cevap verir.

## Denetlenen çözünürlükler — ayarlardaki seçeneklerin TAMAMI.
## Arayüz artık sabit 1280x720 tasarımının ölçeklenmiş kopyası DEĞİL (bkz. display_scale.gd):
## her çözünürlükte farklı MANTIKSAL alan oluşur, dolayısıyla her biri ayrı doğrulanmalı.
const RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

var VIEWPORT := Vector2(1280, 720)

## Denetlenen sahneler. Tam-ekran overlay'ler (CenterContainer kökü) ve HUD panelleri.
const SCENES := [
	"res://scenes/ui/overlays/pause/pause_overlay.tscn",
	"res://scenes/ui/overlays/settings/settings_overlay.tscn",
	"res://scenes/ui/overlays/chronicles/chronicles_overlay.tscn",
	"res://scenes/ui/overlays/roster/roster_overlay.tscn",
	"res://scenes/ui/overlays/blessings/blessings_overlay.tscn",
	"res://scenes/ui/overlays/keywords/keywords_overlay.tscn",
	"res://scenes/ui/overlays/profile/profile_overlay.tscn",
	"res://scenes/ui/overlays/game_end/game_end_overlay.tscn",
	"res://scenes/ui/overlays/guide/guide_overlay.tscn",
	"res://scenes/ui/faction_select/faction_selection_panel.tscn",
	"res://scenes/ui/scenario_select/scenario_selection_panel.tscn",
	"res://scenes/ui/main_menu/main_menu.tscn",
	"res://scenes/ui/armoury/armoury_panel.tscn",
]

## Kenar payı: 1-2 piksellik yuvarlama farkları uyarı üretmesin.
const EDGE_TOLERANCE := 2.0

func _ready() -> void:
	var problems: Array[String] = []
	for res in RESOLUTIONS:
		var win := get_window()
		win.size = res
		# Ölçek, gerçek oyundaki gibi pencere boyutundan türetilir — böylece test, oyuncunun
		# göreceği MANTIKSAL alanı ölçer (piksel boyutunu değil).
		DisplayScale.apply(win)
		await get_tree().process_frame
		await get_tree().process_frame
		VIEWPORT = get_viewport().get_visible_rect().size
		print("— %dx%d (ölçek %.2f → mantıksal %.0fx%.0f)" % [
			res.x, res.y, DisplayScale.factor_for_height(float(res.y)), VIEWPORT.x, VIEWPORT.y])
		for path in SCENES:
			for issue in await _check_scene(path):
				problems.append("[%dx%d] %s" % [res.x, res.y, issue])

	if problems.is_empty():
		print("\n==== UI YERLEŞİM: GEÇTİ (%d sahne × %d çözünürlük) ====" \
			% [SCENES.size(), RESOLUTIONS.size()])
		get_tree().quit(0)
	else:
		print("\n==== UI YERLEŞİM: %d SORUN ====" % problems.size())
		for p in problems:
			print("   ✗ " + p)
		get_tree().quit(1)

func _check_scene(path: String) -> Array[String]:
	var out: Array[String] = []
	var packed: PackedScene = load(path)
	if packed == null:
		out.append("%s yüklenemedi" % path)
		return out

	var root = packed.instantiate()
	if not (root is Control):
		root.free()
		return out

	var holder := Control.new()
	holder.size = VIEWPORT
	add_child(holder)
	holder.add_child(root)
	# Container yerleşimi birkaç kare sürebilir (iç içe container'lar sırayla çözülür).
	for _i in 4:
		await get_tree().process_frame

	var file := path.get_file()
	var r: Rect2 = root.get_global_rect()
	if r.size.x > VIEWPORT.x + EDGE_TOLERANCE:
		out.append("%s: panel genişliği %.0f > %.0f" % [file, r.size.x, VIEWPORT.x])
	if r.size.y > VIEWPORT.y + EDGE_TOLERANCE:
		out.append("%s: panel yüksekliği %.0f > %.0f" % [file, r.size.y, VIEWPORT.y])

	out.append_array(_check_interactives(root, file))

	holder.queue_free()
	await get_tree().process_frame
	return out

## Ekran dışına taşan TIKLANABİLİR öğe = oyuncunun erişemediği kontrol.
##
## ÖNEMLİ İSTİSNA: bir `ScrollContainer`ın İÇİNDEKİ öğeler görünür alanın dışında olabilir —
## kaydırma tam olarak bunun içindir, erişilebilirler. Bu ayrım yapılmazsa test yanlış alarm
## üretir (ilk çalıştırmada Codex'in birim ızgarası tam olarak böyle işaretlenmişti).
func _check_interactives(node: Node, file: String, inside_scroll: bool = false) -> Array[String]:
	var out: Array[String] = []
	var scrolled: bool = inside_scroll or node is ScrollContainer
	for child in node.get_children():
		out.append_array(_check_interactives(child, file, scrolled))
	if inside_scroll:
		return out
	if not (node is Control):
		return out
	var c := node as Control
	if not (c is Button or c is Slider or c is OptionButton or c is LineEdit):
		return out
	if not c.is_visible_in_tree() or c.size == Vector2.ZERO:
		return out
	var gr: Rect2 = c.get_global_rect()
	if gr.position.x < -EDGE_TOLERANCE or gr.position.y < -EDGE_TOLERANCE \
			or gr.end.x > VIEWPORT.x + EDGE_TOLERANCE or gr.end.y > VIEWPORT.y + EDGE_TOLERANCE:
		out.append("%s: '%s' ekran dışında → tıklanamaz (%s)" % [file, c.name, str(gr)])
	return out
