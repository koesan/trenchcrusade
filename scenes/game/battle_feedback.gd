class_name BattleFeedback
extends Node3D

## BİRİM ÜSTÜ YÜZEN YAZILAR — savaş olaylarını (GameEvents.battle_event) ilgili birimin üstünde
## kısa süre yükselip sönen bir yazıyla gösterir: "Iska", "İsabet", "Kritik!", "Sıyrık +1",
## "Yere Serildi", "Savaş Dışı", yetenek adı. Oyuncu sonucu zar şeridine bakmadan, olduğu yerde görür.
##
## Aynı birimde art arda gelen yazılar üst üste binmez: her yeni yazı bir öncekinin biraz
## üstünden başlar (birim başına kısa ömürlü yığın).

## Yükselme ve yığın aralığı EKRAN PİKSELİYLE (Label3D.offset; etiketler sabit ekran boyutlu) —
## dünya biriminde yapılınca yakın planda yazılar ekranın dışına taşıyordu.
const RISE_PX := 46.0
const LIFETIME := 1.8
const STACK_PX := 34.0
const HEAD_HEIGHT := 2.3

## Birim adı → o an havada olan yazı sayısı
var _stack := {}

func _ready() -> void:
	GameEvents.battle_event.connect(_on_event)

func _on_event(kind: StringName, data: Dictionary) -> void:
	match kind:
		&"miss":
			_say(data.get("a", ""), LocalizationManager.tr_t("FLOAT_MISS"), "color_dim_text")
		&"hit":
			if data.get("crit", false):
				_say(data.get("a", ""), LocalizationManager.tr_t("FLOAT_CRIT"), "color_gold_bright")
			else:
				_say(data.get("a", ""), LocalizationManager.tr_t("FLOAT_HIT"), "color_parchment")
		&"injury":
			var o: String = data.get("o", "no_effect")
			var m: int = int(data.get("m", 0))
			var text: String = LocalizationManager.tr_t("FLOAT_INJURY_" + o.to_upper())
			if m > 0 and o != "out":
				text += "  +%d" % m
			var col: String = {"no_effect": "color_dim_text", "scratch": "color_status_caution",
				"down": "color_status_warn", "out": "color_status_danger"}.get(o, "color_parchment")
			_say(data.get("t", ""), text, col, o == "out")
		&"ability":
			var key := "color_gold_bright" if data.get("ok", true) else "color_dim_text"
			var t: String = LocalizationManager.tr_t(data.get("k", ""))
			if not data.get("ok", true):
				t = LocalizationManager.tr_t("FLOAT_ABILITY_FAILED") % t
			_say(data.get("a", ""), t, key)

func _say(unit_name: String, text: String, color_name: String, big: bool = false) -> void:
	var unit = GameState.units.get(unit_name)
	if not is_instance_valid(unit) or text == "":
		return
	var n: int = _stack.get(unit_name, 0)
	_stack[unit_name] = n + 1
	var l := WorldLabel.make(0.0, 34 if big else 28)
	l.text = text
	l.modulate = GothicThemeHelper.color(color_name)
	l.outline_size = 10
	add_child(l)
	l.global_position = unit.global_position + Vector3(0, HEAD_HEIGHT, 0)
	l.offset = Vector2(0, n * STACK_PX)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "offset:y", l.offset.y + RISE_PX, LIFETIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, LIFETIME * 0.45).set_delay(LIFETIME * 0.55)
	tw.chain().tween_callback(func():
		l.queue_free()
		_stack[unit_name] = maxi(0, int(_stack.get(unit_name, 1)) - 1))
