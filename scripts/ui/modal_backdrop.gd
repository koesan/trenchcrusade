class_name ModalBackdrop
extends RefCounted

## Modal ekranların arkasındaki karartma — TEK KAYNAK.
##
## Overlay'ler (OverlayPanel) ve savaş öncesi seçim ekranları (senaryo, faksiyon) tam ekran
## köklerinin `_draw()`ında bunu çağırır. Arkadaki savaş alanı ve haritadaki 3B etiketler
## (hedef adları) kararır; panel öne çıkar, kenarından taşan dünya etiketleri karışıklık yaratmaz.

const ALPHA := 0.62

static func paint(item: Control) -> void:
	var c: Color = GothicThemeHelper.color("color_bg_deep")
	c.a = ALPHA
	item.draw_rect(Rect2(Vector2.ZERO, item.size), c)
