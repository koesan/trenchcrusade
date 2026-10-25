extends Button
class_name HUDActionButton

## Komuta panelindeki eylem butonu: üstte ikon, altta kısa ad, sol üstte kısayol tuşu.
##
## SEÇİM: seçili eylem (ör. hedef bekleyen saldırı) toggle'ın BASILI hâliyle gösterilir — tema
## onu vitray kırmızı çerçeveyle çizer. Eskiden yazı rengi geçersiz kılınıyordu; her yeniden
## kurulumda override yazmak yerleşimi yeniden hesaplatıyor ve butonlar kıpırdıyordu.
##
## İKON: eylem anahtarından seçilir (ICON_FOR). Bilinmeyen anahtar → genel "yetenek" ikonu.

const ICON_DIR := "res://assets/ui/icons/"
const ICON_FOR := {
	"ACTION_MARCH": "march",
	"ACTION_ONSLAUGHT_CHARGE": "charge",
	"ACTION_RETREAT": "retreat",
	"ACTION_HASTE_RISKY": "dash",
	"ACTION_CLAIM_RELIQUARY": "claim",
	"ACTION_FIGHT_DEVOURER": "melee",
}

var tooltip_key: String = ""
## Doluysa bilgi kartı bu sözlükten çizilir (birim yetenekleri — bkz. InfoSpec.for_ability);
## boşsa `tooltip_key` üzerinden genel eylem açıklaması kullanılır.
var tooltip_spec: Dictionary = {}

@onready var _hotkey: Label = $Hotkey

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)

## `icon_name`: assets/ui/icons altındaki ikon adı; boşsa anahtardan çıkarılır.
## `hotkey`: 1-9 kısayol numarası (0 = yok).
func setup_action(action_text: String, is_highlighted: bool, pressed_callable: Callable,
		p_tooltip_key: String = "", icon_name: String = "", hotkey: int = 0) -> void:
	_full_text = action_text
	_fitted_for = ""
	text = action_text
	_fit_words()
	tooltip_key = p_tooltip_key
	var key := icon_name if icon_name != "" else String(ICON_FOR.get(p_tooltip_key, "ability"))
	icon = load(ICON_DIR + key + ".svg")
	set_pressed_no_signal(is_highlighted)
	if is_instance_valid(_hotkey):
		_hotkey.text = str(hotkey) if hotkey > 0 else ""

	for conn in pressed.get_connections():
		if conn.callable != Callable(self, "_on_pressed"):
			pressed.disconnect(conn.callable)
	pressed.connect(pressed_callable)

## SABİT BOYUT: yazı uzun diye buton (ve onunla birlikte bütün eylem satırı) uzamasın. Yazı
## en fazla İKİ satıra ve buton genişliğine sığana kadar küçülür (11 → en az 9); kelime asla
## ortadan bölünmez. 9 puntoda bile sığmıyorsa son kelimeler "…" ile kısaltılır — tam ad bilgi
## kartında ve araç ipucunda durur.
## ZAMANLAMA: buton ağaca yeni eklendiğinde tema henüz çözülmemiştir (varsayılan, dar font döner
## ve yazı "sığıyor" sanılır). Bu yüzden ölçüm tema hazır olduğunda (THEME_CHANGED) tekrarlanır.
const _FONT_MAX := 11
const _FONT_MIN := 9
const _MAX_LINES := 2
## Butonun iki yan iç boşluğu (tema ButtonAction: 6+6) + çerçeve payı
const _SIDE_PAD := 16.0

var _full_text := ""
var _fitted_for := ""

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and _full_text != "" and _fitted_for != _full_text:
		_fit_words()

func _fit_words() -> void:
	if _full_text == "":
		_full_text = text
	var font: Font = get_theme_font("font")
	var avail: float = custom_minimum_size.x - _SIDE_PAD
	var fs := _FONT_MAX
	while fs > _FONT_MIN and not _fits(font, _full_text, fs, avail):
		fs -= 1
	var shown := _full_text
	var words := _full_text.split(" ")
	while not _fits(font, shown, fs, avail) and words.size() > 1:
		words.remove_at(words.size() - 1)
		shown = " ".join(words) + "…"
	_fitted_for = _full_text if is_inside_tree() else ""
	tooltip_text = _full_text if shown != _full_text else ""
	add_theme_font_size_override("font_size", fs)
	text = shown
	autowrap_mode = TextServer.AUTOWRAP_WORD

func _fits(font: Font, t: String, fs: int, avail: float) -> bool:
	for w in t.split(" "):
		if font.get_string_size(w, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > avail:
			return false
	var h: float = font.get_multiline_string_size(t, HORIZONTAL_ALIGNMENT_CENTER, avail, fs, -1,
		TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND).y
	return h <= font.get_height(fs) * _MAX_LINES + 0.5

func _get_hud() -> Node:
	var p = get_parent()
	while p:
		if p.has_method("show_tooltip"):
			return p
		p = p.get_parent()
	return null

func _on_mouse_entered() -> void:
	var hud = _get_hud()
	if hud == null:
		return
	if not tooltip_spec.is_empty():
		hud.show_info(self, tooltip_spec)
	elif tooltip_key != "":
		hud.show_tooltip(self, tooltip_key)

func _on_mouse_exited() -> void:
	var hud = _get_hud()
	if hud:
		hud.hide_tooltip()

func _on_pressed() -> void:
	var hud = _get_hud()
	if hud:
		hud.hide_tooltip()
