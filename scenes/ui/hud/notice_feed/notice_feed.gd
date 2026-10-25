class_name NoticeFeed
extends VBoxContainer

## BİLDİRİM ŞERİDİ — oyuncuya o an gereken kısa yönlendirme: "neden olmadı, ne yapmalı"
## (sıralı aktivasyon, lider eksik, hedef seçimi). Hata raporu DEĞİLDİR: ton yönlendiricidir,
## kırmızı/uyarı dili yalnız gerçekten kural engeli olan durumlarda kullanılır.
##
## Yer: ekranın orta-üst şeridi — üst barın ve zar barının ALTINDA, alt komuta panelinin ve
## seçim ipucu kartının ÜSTÜNDE; sol kadro listesi ve sağ ikon sütunuyla çakışmaz. Kart yukarıdan
## süzülerek girer, metnin okunma süresi kadar kalır ve solar. En fazla MAX_CARDS kart görünür;
## aynı metin yeniden gelirse yeni kart açılmaz, mevcut kartın süresi yenilenir. Tıklamayı
## engellemez — altındaki haritayla etkileşim sürer.
##
## Başlık yalnız anahtarın "<KEY>_TITLE" karşılığı varsa yazılır (ör. "Lider eksik"); yoksa kart
## tek satırlık sade bir yönlendirmedir — "Yapılamaz" gibi genel hata başlıkları kullanılmaz.

const CARD_SCENE := preload("res://scenes/ui/hud/notice_feed/notice_card.tscn")
const ICON_DIR := "res://assets/ui/icons/"
const MAX_CARDS := 3
const SLIDE_PX := 10.0
## Tür → ikon + vurgu rengi. "hint": yönlendirme (varsayılan), "rule": kural engeli (amber),
## "info": genel bilgi. ("warn" eski adıdır, "rule" ile aynı.)
const KINDS := {
	"hint": {"icon": "info", "color": "color_gold_bright"},
	"rule": {"icon": "warning", "color": "color_status_caution"},
	"info": {"icon": "info", "color": "color_parchment"},
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Lokalizasyon anahtarıyla bildirim (ret sebepleri bu yoldan gelir).
func post_key(key: String, kind: String = "hint") -> void:
	var title_key := key + "_TITLE"
	var title: String = LocalizationManager.tr_t(title_key) if LocalizationManager.has_key(title_key) else ""
	post(LocalizationManager.tr_t(key), kind, title)

func post(text: String, kind: String = "hint", title: String = "") -> void:
	if text.strip_edges() == "":
		return
	for c in get_children():
		if c.get_meta("text", "") == text:
			_hold(c, text)
			return
	while get_child_count() >= MAX_CARDS:
		var oldest := get_child(0)
		remove_child(oldest)
		oldest.queue_free()
	var spec: Dictionary = KINDS.get("rule" if kind == "warn" else kind, KINDS["hint"])
	var col: Color = GothicThemeHelper.color(spec["color"])
	var card: Control = CARD_SCENE.instantiate()
	card.set_meta("text", text)
	add_child(card)
	card.get_node("%Stripe").color = col
	var icon: TextureRect = card.get_node("%Icon")
	icon.texture = load(ICON_DIR + spec["icon"] + ".svg")
	icon.modulate = col
	var title_lbl: Label = card.get_node("%Title")
	title_lbl.visible = title != ""
	title_lbl.text = title
	title_lbl.add_theme_color_override("font_color", col)
	card.get_node("%Body").text = text
	_enter(card)
	_hold(card, text)

## Tüm kartları beklemeden kapatır (aşama değişiminde — eski uyarı yeni ekranda asılı kalmasın).
func clear() -> void:
	for c in get_children():
		c.queue_free()

func _enter(card: Control) -> void:
	var panel: Control = card.get_node("%Panel")
	card.modulate.a = 0.0
	var tw := card.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate:a", 1.0, 0.2)
	tw.tween_method(func(y: float): panel.position.y = y, -SLIDE_PX, 0.0, 0.24)

## Okuma süresi: kısa yönlendirme ~3 sn, uzun metin en çok 7 sn. Yenilenen kart yeniden sayar.
func _hold(card: Control, text: String) -> void:
	var gen: int = int(card.get_meta("gen", 0)) + 1
	card.set_meta("gen", gen)
	card.modulate.a = 1.0
	var secs: float = clampf(2.4 + 0.045 * text.length(), 3.0, 7.0)
	# Kart bu arada silinmiş olabilir (clear / taşma) — zayıf referansla tutulur.
	var ref: WeakRef = weakref(card)
	get_tree().create_timer(secs).timeout.connect(func():
		var live: Control = ref.get_ref()
		if live != null and int(live.get_meta("gen", 0)) == gen:
			var tw := live.create_tween()
			tw.tween_property(live, "modulate:a", 0.0, 0.35)
			tw.tween_callback(live.queue_free))
