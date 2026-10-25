## SÜRÜKLEYEREK KAYDIRMA — bir `ScrollContainer`a "fareyle tutup kaydır" yeteneği ekler.
##
## NEDEN VAR (kullanıcı bildirimi: "popuplardaki kaydırma işe yaramıyor, aşağı kaydıramıyorum;
## farenin ORTA tuşuyla ve SOL tuşla tutup kaydırabilmem lazım"): Godot'un `ScrollContainer`ı
## yalnız tekerleği ve kaydırma çubuğunu bilir. Tutup sürükleme, uzun bir bilgi kartında en
## doğal hareket olmasına rağmen elle yazılmak zorunda.
##
## NEDEN AYRI BİR BİLEŞEN: aynı sürükleme mantığı `deploy_panel.gd` içinde zaten elle yazılmıştı.
## Üç ayrı hover kartının başına gelen tam olarak buydu — aynı davranış birden çok yerde ayrı
## yazılınca biri düzeltilirken diğerleri geride kalıyor. Tek yerde durur, her kaydırıcı takar.
##
## `_input` KULLANIR, `gui_input` DEĞİL: kaydırıcının İÇİNDE buton varsa (eylem paneli, birim
## kartı şeridi) butonlar olayı yutar ve kaydırıcının `gui_input`i hiç ateşlenmez. `_input`
## olayı butonlardan ÖNCE görür.
##
## TIKLAMAYI BOZMAZ: `DRAG_THRESHOLD` pikselden az hareket eden bir basış normal tıklamadır;
## eşiği aşan bir sürüklemenin bitişinde tıklama olayı YUTULUR, böylece "kaydırdım ama kart da
## seçildi" olmaz.
class_name DragScroll
extends Node

## Sürükleme sayılması için gereken en küçük hareket (piksel). Bunun altındaki basışlar tıklamadır.
const DRAG_THRESHOLD := 8.0

var _scroll: ScrollContainer = null
var _dragging := false
var _moved := false
var _press_at := Vector2.ZERO
var _start_h := 0
var _start_v := 0

## `scroll`a sürüklemeyle kaydırma ekler ve yardımcı düğümü döndürür.
## Aynı kaydırıcıya iki kez takılmaz.
static func attach(scroll: ScrollContainer) -> DragScroll:
	if not is_instance_valid(scroll):
		return null
	for c in scroll.get_children():
		if c is DragScroll:
			return c as DragScroll
	var helper := DragScroll.new()
	helper.name = "DragScroll"
	helper._scroll = scroll
	scroll.add_child(helper)
	return helper

func _input(event: InputEvent) -> void:
	if not is_instance_valid(_scroll) or not _scroll.is_visible_in_tree():
		_dragging = false
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT and mb.button_index != MOUSE_BUTTON_MIDDLE:
			return
		if mb.pressed:
			if _scroll.get_global_rect().has_point(mb.global_position) and _can_scroll():
				_dragging = true
				_moved = false
				_press_at = mb.global_position
				_start_h = _scroll.scroll_horizontal
				_start_v = _scroll.scroll_vertical
		elif _dragging:
			var was_drag := _moved
			_dragging = false
			_moved = false
			# Gerçek bir sürüklemeydiyse bırakma olayını YUT — altındaki kart/buton tıklanmasın.
			if was_drag:
				get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and _dragging:
		var delta: Vector2 = (event as InputEventMouseMotion).global_position - _press_at
		if not _moved and delta.length() < DRAG_THRESHOLD:
			return
		_moved = true
		# Sürükleme yönü içeriğin hareket yönüdür: aşağı çekmek içeriği aşağı kaydırır.
		if _scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			_scroll.scroll_vertical = _start_v - int(delta.y)
		if _scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			_scroll.scroll_horizontal = _start_h - int(delta.x)

## Kaydırılacak bir şey var mı? (Kapalı kaydırıcıda sürükleme başlatmak, altındaki tıklamayı
## gereksiz yere yutardı.)
func _can_scroll() -> bool:
	return _scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED \
		or _scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED
