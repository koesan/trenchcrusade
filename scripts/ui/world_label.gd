class_name WorldLabel
extends RefCounted

## Harita üstündeki işaret etiketleri (hedef, kutsal emanet) için ortak Label3D kurulumu.
##
## SABİT EKRAN BOYUTU: etiket kamera uzaklığından bağımsız okunur. Eski dünya-birimi boyutu
## (pixel_size 0.011 × 18pt) genel görünümde birkaç piksele düşüp okunamıyordu.
## Oyunun gövde fontu (Garamond) + koyu kontur — açık/koyu arazinin üstünde okunur.

const FONT := preload("res://assets/fonts/GaramondTrenchCrusade-Regular-aeQsMOXa.woff2")
## Nötr etiket rengi (tema parşömeni). İşaretler ele geçirilince faksiyon rengine boyanır.
static func text_color() -> Color:
	return GothicThemeHelper.color("color_parchment")

## `size`: yazı boyutu (sabit ekran boyutunda). Hedef/emanet 16, arazi notu 13.
static func make(height: float, size: int = 16) -> Label3D:
	var l := Label3D.new()
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.001
	l.font = FONT
	l.font_size = size
	l.modulate = text_color()
	l.outline_modulate = GothicThemeHelper.color("color_bg_deep")
	l.outline_size = 8
	l.position.y = height
	return l
