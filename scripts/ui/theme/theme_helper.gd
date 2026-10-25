class_name GothicThemeHelper
extends Node

## ÇERÇEVE SÜSÜ: eskiden her panel/butonun köşesine kodla 3x3 px'lik "perçin" kareleri
## ekleniyordu (rivets.tscn). Çerçeve dokuları (tools/ui_assets/build_ui_svgs.py) köşe süsünü
## kendi içinde taşıdığı için perçin katmanı kaldırıldı — iki ayrı süs dili üst üste biniyordu.

## Gothic tema kaynağı — TEK erişim noktası.
const THEME := preload("res://assets/themes/gothic_theme.tres")

## Tema "Constants" tipindeki adlandırılmış rengi döndürür.
##
## NEDEN BURADA: altı ayrı UI script'i bu iki satırı (preload + get_color) kendi yerel
## `_get_theme_color()` yardımcısı olarak TEKRARLIYORDU. Renk erişimi tek yerde durursa
## renk adı değişikliği tek yerde takip edilir; ayrıca "hangi dosya temayı okuyor" sorusunun
## cevabı tek bir grep'e iner.
## Bilinmeyen bir ad için Godot şeffaf siyah döndürür — bu gözle FARK EDİLİR, sessizce
## "makul" bir renge düşmez (kasıtlı: yazım hatası görünür olsun).
static func color(color_name: String) -> Color:
	return THEME.get_color(color_name, "Constants")

## Tema fontları (Garamond/Blackletter) rozet/işaret olarak kullanılan ▼ ⚠ ☠ ⚑ ⚔ ● gibi
## Unicode sembollerini İÇERMİYOR. `allow_system_fallback=true` olduğu için bu semboller
## işletim sistemi fontlarından tamamlanıyordu — bu da platforma göre farklı sonuç veriyordu
## (Linux'ta görünüp Windows'ta görünmemesi gibi). Projeye gömülü DejaVu Sans'ı açık fallback
## olarak atayarak bu sembollerin HER platformda aynı şekilde (proje içinden) render edilmesini
## garantiliyoruz.
static var _fallback_symbol_font := preload("res://assets/fonts/DejaVuSans-FallbackSymbols.ttf")
static var _garamond_font := preload("res://assets/fonts/GaramondTrenchCrusade-Regular-aeQsMOXa.woff2")
static var _blackletter_font := preload("res://assets/fonts/TCBlackletter-TR.ttf")

static var _font_fallbacks_wired := false

static func _ensure_font_fallbacks() -> void:
	if _font_fallbacks_wired:
		return
	_font_fallbacks_wired = true
	_garamond_font.fallbacks = [_fallback_symbol_font]
	_blackletter_font.fallbacks = [_fallback_symbol_font]

## Projenin görsel temasını dinamik/statik kontrol düğümlerine bağlar.
static func init_ui(root: Node) -> void:
	_ensure_font_fallbacks()
	# EKRAN ÖLÇEĞİ: arayüz pencere çözünürlüğüne uyum sağlamalı (bkz. display_scale.gd).
	# Her UI sahnesi buradan geçtiği için, oyun hangi sahneden başlarsa başlasın ölçek doğrudur;
	# ayrıca pencere yeniden boyutlandığında kendini yenilemek üzere BİR KEZ bağlanır.
	if root.is_inside_tree():
		DisplayScale.ensure_applied(root.get_window())
	var theme_res := THEME

	# CanvasLayer altındaki Control düğümlerine temayı zorla ata (Godot 4 CanvasLayer tema aktarımı yapmaz)
	if root is CanvasLayer:
		for child in root.get_children():
			if child is Control and child.theme == null:
				child.theme = theme_res
				
	# Belirtilen kök düğümden başlayarak tüm hiyerarşiye temayı bağla
	_apply_theme_recursive(root, theme_res)

static func _apply_theme_recursive(node: Node, theme_res: Theme) -> void:
	if node is Control:
		# Teması atanmamışsa ata
		if node.theme == null:
			node.theme = theme_res

	for child in node.get_children():
		_apply_theme_recursive(child, theme_res)
