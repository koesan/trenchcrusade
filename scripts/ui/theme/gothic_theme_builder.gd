## Gothic Theme Builder — GÖRSEL KAYNAK ÜRETİCİSİ (dev-tool, SceneTree scripti).
##
## Bu araç projedeki iki görsel kaynağı ÜRETİR (tek kaynak = buradaki renk sabitleri):
##   • res://assets/themes/gothic_theme.tres        (Control temaları + "Constants" renkleri)
##   • res://assets/data/game_visual_colors.tres    (3D/oynanış renkleri, GameVisualColors)
##
## KULLANIM (renk/tema değiştirmek için):
##   godot --headless --path . -s res://scripts/ui/theme/gothic_theme_builder.gd
## → aşağıdaki sabitleri düzenle, çalıştır; .tres'ler yeniden üretilir.
## .tres'leri ELLE düzenleme — bir sonraki çalıştırmada üzerine yazılır (drift önlenir).
##
## GÖRSEL DİL (2026-10-24 yeniden tasarım): karanlık ilahi gotik — katedral taşı + kutsal emanet.
##   • Çerçeve/buton/kart dokuları: res://assets/ui/** (SVG) — üreticisi
##     tools/ui_assets/build_ui_svgs.py. Palet oradakiyle AYNI tutulur.
##   • Varak altın çizgiler, is siyahı zemin, kemik beyazı metin, TEK vurgu: vitray kan kırmızısı.
##   • Blackletter (Türkçe glifleri tamamlanmış TCBlackletter-TR) yalnız başlıklarda; metin ve
##     SAYILAR Garamond (blackletter rakamlar küçük boyutta okunmuyordu).
##
## TİP ÖLÇEĞİ (mantıksal px, DisplayScale ile büyür — 1080p'de x1.25):
##   Ekran başlığı 26 · Başlık 20 · Kart başlığı 17 · Ara başlık 14 · Gövde 14 · Küçük 13 · Not 12
## (2026-10-24 orantı turu: önceki 32/24/16/15 ölçeği 1080p'de iri kalıyordu — kullanıcı bildirimi)
##
## Runtime'da hiçbir sahne bu scripti çağırmaz; yalnız üretim aşamasında kullanılır.
extends SceneTree

# ── PALET ────────────────────────────────────────────────────────────────────────
const INK := Color("#0b0908")
const STONE := Color("#17130f")
const GILT := Color("#b0915a")
const GILT_DIM := Color("#6b5636")
const GILT_LIT := Color("#e2c68c")
const BONE := Color("#e8dfcc")
const BONE_BRIGHT := Color("#f4eee2")
const BONE_DIM := Color("#bdb19a")
const ASH := Color("#998e7e")
const ASH_DARK := Color("#6f6658")
const BLOOD := Color("#7c1a13")
const BLOOD_DEEP := Color("#5e140f")
const BLOOD_LIT := Color("#c03a2c")

# Durum anlamları (ROL'e göre adlandırılır — bir tonu değiştirmek tüm kullanım yerlerini günceller)
const STATUS_DANGER := Color("#d0473b")   # ölümcül/kritik — Savaş Dışı, Sarsılmış, hedef
const STATUS_WARN := Color("#e07a3c")     # ciddi — Yere Serilmiş
const STATUS_CAUTION := Color("#d6a35a")  # hafif — Sıyrık
const STATUS_GOOD := Color("#8fb07a")     # olumlu — hazır, Gölge Yürüyüşü
const STATUS_HP := Color("#d0584a")

# ── DOKULAR ──────────────────────────────────────────────────────────────────────
const UI := "res://assets/ui/frames/"

var theme := Theme.new()
var FONT_BODY: Font
var FONT_TITLE: Font
var FONT_ENGRAVED: FontVariation

func _init() -> void:
	print("--- Gothic Theme Builder Starting ---")
	_fonts()
	_constants()
	_buttons()
	_panels()
	_labels()
	_inputs()
	_lists_and_tabs()
	_bars_and_separators()
	_scrollbars()
	_popups_and_tooltips()
	_save()
	quit()

# ── YARDIMCILAR ──────────────────────────────────────────────────────────────────

## 9-dilim doku kutusu. `margin` = doku kenar payı (çerçeve kalınlığı), `content` = iç boşluk.
func tex_box(file: String, margin: int, content: Vector4 = Vector4(-1, -1, -1, -1),
		modulate := Color.WHITE) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(UI + file)
	sb.texture_margin_left = margin
	sb.texture_margin_right = margin
	sb.texture_margin_top = margin
	sb.texture_margin_bottom = margin
	if content.x >= 0.0:
		sb.content_margin_left = content.x
		sb.content_margin_top = content.y
		sb.content_margin_right = content.z
		sb.content_margin_bottom = content.w
	sb.modulate_color = modulate
	return sb

func pad(h: float, v: float) -> Vector4:
	return Vector4(h, v, h, v)

func flat(bg: Color, border := Color(0, 0, 0, 0), bw := 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	if bw > 0:
		sb.set_border_width_all(bw)
		sb.border_color = border
	return sb

func variation(name: String, base: String) -> void:
	theme.add_type(name)
	theme.set_type_variation(name, base)

func label_style(name: String, font: Font, size: int, color: Color) -> void:
	if name != "Label":
		variation(name, "Label")
	theme.set_font("font", name, font)
	theme.set_font_size("font_size", name, size)
	theme.set_color("font_color", name, color)

# ── BÖLÜMLER ─────────────────────────────────────────────────────────────────────

func _fonts() -> void:
	FONT_BODY = load("res://assets/fonts/GaramondTrenchCrusade-Regular-aeQsMOXa.woff2")
	FONT_TITLE = load("res://assets/fonts/TCBlackletter-TR.ttf")
	# Etkileşimli öğeler (buton/sekme) ve ara başlıklar: Garamond "oyma harf" — hafif kalın,
	# açık harf aralığı. Gotik havayı bozmadan küçük boyutta okunur.
	FONT_ENGRAVED = FontVariation.new()
	FONT_ENGRAVED.base_font = FONT_BODY
	FONT_ENGRAVED.variation_embolden = 0.45
	FONT_ENGRAVED.spacing_glyph = 1
	theme.default_font = FONT_BODY
	theme.default_font_size = 14

## Kod tarafından ada göre okunan renkler (GothicThemeHelper.color). Adlar geriye dönük
## uyumludur; değerler yeni palettendir.
func _constants() -> void:
	theme.add_type("Constants")
	var c := {
		"color_blood_crimson": BLOOD, "color_blood_vivid": BLOOD_LIT, "color_rust_crimson": BLOOD_DEEP,
		"color_parchment": BONE, "color_text_bright": BONE_BRIGHT, "color_brass": GILT,
		"color_border": GILT_DIM, "color_bg_dark": STONE, "color_bg_deep": INK,
		"color_muted": ASH_DARK, "color_gold_accent": GILT, "color_gold_bright": GILT_LIT,
		"color_tan_parchment": BONE_DIM, "color_dark_gold": GILT_DIM, "color_muted_brown": Color("#5c4d3c"),
		"color_status_hp": STATUS_HP, "color_highlight_gold": GILT_LIT, "color_alert_red": BLOOD_LIT,
		"color_dim_text": ASH, "color_status_danger": STATUS_DANGER, "color_status_warn": STATUS_WARN,
		"color_status_caution": STATUS_CAUTION, "color_status_good": STATUS_GOOD,
		# Eskiden TANIMSIZDI (deploy_unit_card "Yere Serilmiş" yazısı saydam görünüyordu)
		"color_status_down": STATUS_WARN,
	}
	for k in c:
		theme.set_color(k, "Constants", c[k])

func _buttons() -> void:
	var p := pad(14, 7)
	var normal := tex_box("btn_normal.svg", 10, p)
	var hover := tex_box("btn_hover.svg", 10, p)
	var pressed := tex_box("btn_pressed.svg", 10, p)
	# "pressed" toggle butonların SEÇİLİ hâlidir (sekme, model listesi) — vitray kırmızı.
	var selected := tex_box("btn_selected.svg", 10, p)
	var disabled := tex_box("btn_disabled.svg", 10, p)
	var empty := StyleBoxEmpty.new()

	for t in ["Button", "ButtonSecondary"]:
		if t != "Button":
			variation(t, "Button")
		theme.set_stylebox("normal", t, normal)
		theme.set_stylebox("hover", t, hover)
		theme.set_stylebox("pressed", t, selected)
		theme.set_stylebox("hover_pressed", t, selected)
		theme.set_stylebox("disabled", t, disabled)
		theme.set_stylebox("focus", t, empty)
		# GOTİK BUTONLAR (kullanıcı isteği: "gotik yazı her yerde olsun, düz font sıkıcı"):
		# blackletter yalnız BÜYÜK-KÜÇÜK harf karışık ve 16+ boyutta okunur — tümü büyük harf
		# ve küçük boyut okunmuyordu. Küçük etiketli butonlar (eylem ikonları) Garamond kalır.
		theme.set_font("font", t, FONT_TITLE)
		theme.set_font_size("font_size", t, 17)
		theme.set_color("font_color", t, BONE)
		theme.set_color("font_hover_color", t, BONE_BRIGHT)
		theme.set_color("font_pressed_color", t, BONE_BRIGHT)
		theme.set_color("font_hover_pressed_color", t, BONE_BRIGHT)
		theme.set_color("font_focus_color", t, BONE)
		theme.set_color("font_disabled_color", t, ASH_DARK)
		# İkonlar kendi varak altın rengini taşır (assets/ui/icons) — tema BOYAMAZ, yalnız
		# hover'da hafif aydınlatır, pasifte söndürür.
		theme.set_color("icon_normal_color", t, Color(0.92, 0.92, 0.92))
		theme.set_color("icon_hover_color", t, Color(1.12, 1.1, 1.05))
		theme.set_color("icon_pressed_color", t, Color.WHITE)
		theme.set_color("icon_hover_pressed_color", t, Color(1.12, 1.1, 1.05))
		theme.set_color("icon_disabled_color", t, Color(0.4, 0.38, 0.36))
		theme.set_constant("h_separation", t, 8)

	# Birincil eylem (ekranda EN FAZLA BİR tane): kan kırmızısı
	for t in ["ButtonPrimary", "ButtonDanger"]:
		variation(t, "Button")
		theme.set_stylebox("normal", t, tex_box("btn_primary.svg", 10, p))
		theme.set_stylebox("hover", t, tex_box("btn_primary_hover.svg", 10, p))
		theme.set_stylebox("pressed", t, tex_box("btn_primary.svg", 10, p, Color(0.8, 0.8, 0.8)))
		theme.set_stylebox("hover_pressed", t, tex_box("btn_primary_hover.svg", 10, p))
		theme.set_stylebox("disabled", t, disabled)
		theme.set_stylebox("focus", t, empty)
		theme.set_color("font_color", t, BONE_BRIGHT)
		theme.set_color("font_hover_color", t, Color.WHITE)
		theme.set_color("font_pressed_color", t, BONE)
		theme.set_color("font_disabled_color", t, ASH_DARK)

	# Hayalet: çerçevesiz metin butonu (Geri, ikincil bağlantılar)
	variation("ButtonGhost", "Button")
	for st in ["normal", "disabled", "focus"]:
		theme.set_stylebox(st, "ButtonGhost", flat(Color(0, 0, 0, 0)))
	var ghost_hover := StyleBoxFlat.new()
	ghost_hover.bg_color = Color(GILT.r, GILT.g, GILT.b, 0.08)
	ghost_hover.border_width_bottom = 1
	ghost_hover.border_color = GILT
	ghost_hover.content_margin_left = 10
	ghost_hover.content_margin_right = 10
	theme.set_stylebox("hover", "ButtonGhost", ghost_hover)
	theme.set_stylebox("pressed", "ButtonGhost", ghost_hover)
	theme.set_color("font_color", "ButtonGhost", BONE_DIM)
	theme.set_color("font_hover_color", "ButtonGhost", GILT_LIT)
	theme.set_color("font_pressed_color", "ButtonGhost", GILT_LIT)
	theme.set_color("font_disabled_color", "ButtonGhost", ASH_DARK)

	# Kare ikon butonu (eylem çubuğu, sistem butonları) — metin yok, ikon ortada
	variation("ButtonIcon", "Button")
	# İkon butonlarının altındaki küçük ad: Garamond (11 pt blackletter okunmaz)
	theme.set_font("font", "ButtonIcon", FONT_BODY)
	theme.set_font_size("font_size", "ButtonIcon", 12)
	var ip := pad(8, 8)
	theme.set_stylebox("normal", "ButtonIcon", tex_box("btn_normal.svg", 10, ip))
	theme.set_stylebox("hover", "ButtonIcon", tex_box("btn_hover.svg", 10, ip))
	theme.set_stylebox("pressed", "ButtonIcon", tex_box("btn_selected.svg", 10, ip))
	theme.set_stylebox("hover_pressed", "ButtonIcon", tex_box("btn_selected.svg", 10, ip))
	theme.set_stylebox("disabled", "ButtonIcon", tex_box("btn_disabled.svg", 10, ip))
	theme.set_stylebox("focus", "ButtonIcon", empty)
	theme.set_color("icon_normal_color", "ButtonIcon", Color(0.92, 0.92, 0.92))
	theme.set_color("icon_hover_color", "ButtonIcon", Color(1.12, 1.1, 1.05))
	theme.set_color("icon_pressed_color", "ButtonIcon", Color.WHITE)
	theme.set_color("icon_disabled_color", "ButtonIcon", Color(0.4, 0.38, 0.36))

	# Komuta panelindeki eylem butonu: ButtonIcon'un aynısı, dikey payı ince — ikon + İKİ satır ad
	# sabit 64 px yüksekliğe sığsın (yazı uzunluğu buton boyunu değiştirmesin).
	variation("ButtonAction", "ButtonIcon")
	var ap := pad(6, 4)
	theme.set_stylebox("normal", "ButtonAction", tex_box("btn_normal.svg", 10, ap))
	theme.set_stylebox("hover", "ButtonAction", tex_box("btn_hover.svg", 10, ap))
	theme.set_stylebox("pressed", "ButtonAction", tex_box("btn_selected.svg", 10, ap))
	theme.set_stylebox("hover_pressed", "ButtonAction", tex_box("btn_selected.svg", 10, ap))
	theme.set_stylebox("disabled", "ButtonAction", tex_box("btn_disabled.svg", 10, ap))
	theme.set_constant("h_separation", "ButtonAction", 2)

	# Birim kartı: sivri kemerli niş. Üst pay = kemer; genişlik sabit (120) olduğundan esnemez.
	variation("ButtonNiche", "Button")
	var niche := func(f: String) -> StyleBoxTexture:
		var sb := tex_box(f, 10, Vector4(6, 26, 6, 6))
		sb.texture_margin_top = 40
		return sb
	theme.set_stylebox("normal", "ButtonNiche", niche.call("niche_normal.svg"))
	theme.set_stylebox("hover", "ButtonNiche", niche.call("niche_hover.svg"))
	theme.set_stylebox("pressed", "ButtonNiche", niche.call("niche_selected.svg"))
	theme.set_stylebox("hover_pressed", "ButtonNiche", niche.call("niche_selected.svg"))
	theme.set_stylebox("disabled", "ButtonNiche", niche.call("niche_spent.svg"))
	theme.set_stylebox("focus", "ButtonNiche", empty)

	# Faksiyon sancağı (faksiyon seçimi): asılı heraldik bayrak, kırlangıç kuyruklu alt kenar.
	variation("ButtonBanner", "Button")
	var banner := func(f: String) -> StyleBoxTexture:
		var sb := tex_box(f, 12, Vector4(12, 18, 12, 40))
		sb.texture_margin_top = 18
		sb.texture_margin_bottom = 40
		return sb
	theme.set_stylebox("normal", "ButtonBanner", banner.call("banner_normal.svg"))
	theme.set_stylebox("hover", "ButtonBanner", banner.call("banner_hover.svg"))
	theme.set_stylebox("pressed", "ButtonBanner", banner.call("banner_selected.svg"))
	theme.set_stylebox("hover_pressed", "ButtonBanner", banner.call("banner_selected.svg"))
	theme.set_stylebox("disabled", "ButtonBanner", banner.call("banner_normal.svg"))
	theme.set_stylebox("focus", "ButtonBanner", empty)

	# Onay kutuları: kutu işaretinin kendisi yeter, buton çerçevesi miras alınmasın
	for t in ["CheckBox", "CheckButton"]:
		for st in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
			theme.set_stylebox(st, t, empty)
		theme.set_font("font", t, FONT_BODY)
		theme.set_color("font_color", t, BONE)
		theme.set_color("font_hover_color", t, BONE_BRIGHT)
		theme.set_color("font_pressed_color", t, BONE)
		theme.set_constant("h_separation", t, 8)
	# Kendi kutu ikonlarımız — Godot'nun varsayılan boş kutusu koyu zeminde görünmüyordu
	var off: Texture2D = load(UI + "check_off.svg")
	var on: Texture2D = load(UI + "check_on.svg")
	theme.set_icon("unchecked", "CheckBox", off)
	theme.set_icon("checked", "CheckBox", on)
	theme.set_icon("unchecked_disabled", "CheckBox", off)
	theme.set_icon("checked_disabled", "CheckBox", on)

	# OptionButton (açılır seçim) — buton gibi, ok ikonu altın
	theme.set_color("font_color", "OptionButton", BONE)

func _panels() -> void:
	var panel := tex_box("panel.svg", 22, pad(26, 22))
	var emphasis := tex_box("panel_emphasis.svg", 22, pad(26, 22))
	var inset := tex_box("panel_inset.svg", 9, pad(12, 10))
	var tip := tex_box("tooltip.svg", 9, pad(14, 12))

	theme.set_stylebox("panel", "Panel", panel)
	theme.set_stylebox("panel", "PanelContainer", panel)
	# Komuta paneli: aynı çerçeve, daha ince iç boşluk (sabit yükseklikte daha çok içerik)
	variation("PanelCommand", "PanelContainer")
	theme.set_stylebox("panel", "PanelCommand", tex_box("panel.svg", 22, Vector4(18, 16, 18, 14)))
	variation("PanelNotice", "PanelContainer")
	theme.set_stylebox("panel", "PanelNotice", tex_box("tooltip.svg", 9, Vector4(12, 9, 16, 10)))
	for v in ["PanelIron", "PanelGold", "PanelCrimson", "PanelTopPanel", "PanelDiceBar",
			"PanelTransparent", "PanelInset", "PanelTooltip", "PanelRoundMedallion", "PanelCornerBadge"]:
		variation(v, "PanelContainer")
	theme.set_stylebox("panel", "PanelIron", panel)
	theme.set_stylebox("panel", "PanelGold", emphasis)
	theme.set_stylebox("panel", "PanelCrimson", emphasis)
	theme.set_stylebox("panel", "PanelInset", inset)
	theme.set_stylebox("panel", "PanelTooltip", tip)
	theme.set_stylebox("panel", "PanelDiceBar", tip)
	theme.set_stylebox("panel", "PanelCornerBadge", tip)
	theme.set_stylebox("panel", "PanelTopPanel", StyleBoxEmpty.new())
	theme.set_stylebox("panel", "PanelTransparent", StyleBoxEmpty.new())
	theme.set_stylebox("panel", "PanelRoundMedallion", StyleBoxEmpty.new())

func _labels() -> void:
	label_style("Label", FONT_BODY, 14, BONE)
	# Blackletter başlıklar (kemik beyazı; kırmızı yalnız vurgu/durum)
	label_style("LabelTitleLarge", FONT_TITLE, 26, BONE_BRIGHT)
	label_style("LabelTitle", FONT_TITLE, 20, BONE_BRIGHT)
	label_style("LabelCodexTitle", FONT_TITLE, 19, BONE_BRIGHT)
	label_style("LabelPopupTitle", FONT_TITLE, 17, BONE_BRIGHT)
	label_style("LabelTitleAnointed", FONT_TITLE, 15, Color("#a9bccb"))
	label_style("LabelTitleHeretic", FONT_TITLE, 15, Color("#cf5a4c"))
	label_style("LabelTitleDefeat", FONT_TITLE, 26, BLOOD_LIT)
	label_style("LabelPhaseIndicator", FONT_TITLE, 16, BLOOD_LIT)
	label_style("LabelRoundNumber", FONT_TITLE, 30, BONE_BRIGHT)
	label_style("LabelCornerBadgeCount", FONT_BODY, 22, BONE_BRIGHT)
	# Ara başlık: yaldızlı oyma Garamond
	label_style("LabelTitleSmall", FONT_TITLE, 17, GILT_LIT)
	label_style("LabelGoldAccent", FONT_ENGRAVED, 13, GILT)
	label_style("LabelCornerBadgeName", FONT_ENGRAVED, 11, BONE_DIM)
	# Gövde ve ikincil metin
	label_style("LabelBody", FONT_BODY, 14, BONE)
	label_style("LabelCodexBody", FONT_BODY, 14, BONE)
	label_style("LabelSubtitle", FONT_BODY, 14, ASH)
	label_style("LabelParchmentTan", FONT_BODY, 13, BONE_DIM)
	label_style("LabelMuted", FONT_BODY, 13, BONE_DIM)
	label_style("LabelSmall", FONT_BODY, 12, BONE)
	label_style("LabelGrayLight", FONT_BODY, 12, ASH)
	label_style("LabelGrayMedium", FONT_BODY, 12, ASH_DARK)
	label_style("LabelDarkGold", FONT_BODY, 12, GILT_DIM)
	label_style("LabelMutedBrown", FONT_BODY, 12, Color("#7a6a56"))
	label_style("LabelGoldBright", FONT_BODY, 14, GILT_LIT)
	label_style("LabelHP", FONT_BODY, 12, STATUS_HP)
	# Bildirim akışı (NoticeFeed): oyma harf başlık + gövde metni; kart çerçevesi PanelNotice
	label_style("LabelNoticeTitle", FONT_ENGRAVED, 13, GILT_LIT)
	label_style("LabelNoticeBody", FONT_BODY, 14, BONE)
	# Lider rozeti: kan kırmızısı zemin, varak altın kenar ve yazı — yerleştirme kartının tepesinde
	label_style("LabelBadgeLeader", FONT_ENGRAVED, 11, GILT_LIT)
	var badge := flat(BLOOD_DEEP, GILT, 1)
	badge.set_corner_radius_all(2)
	badge.content_margin_left = 7
	badge.content_margin_right = 7
	badge.content_margin_top = 1
	badge.content_margin_bottom = 2
	theme.set_stylebox("normal", "LabelBadgeLeader", badge)
	# Zar: sayılar Garamond (blackletter rakamlar okunmuyordu)
	label_style("LabelDiceValue", FONT_ENGRAVED, 24, BONE_BRIGHT)
	label_style("LabelDiceTotal", FONT_BODY, 14, BONE)
	label_style("LabelDiceResult", FONT_ENGRAVED, 13, BONE)

func _inputs() -> void:
	var line := tex_box("panel_inset.svg", 9, pad(10, 6))
	var line_focus := tex_box("panel_inset.svg", 9, pad(10, 6), Color(1.5, 1.35, 1.1))
	theme.set_font("font", "LineEdit", FONT_BODY)
	theme.set_stylebox("normal", "LineEdit", line)
	theme.set_stylebox("focus", "LineEdit", line_focus)
	theme.set_color("font_color", "LineEdit", BONE)
	theme.set_color("font_placeholder_color", "LineEdit", ASH_DARK)
	theme.set_color("caret_color", "LineEdit", GILT_LIT)
	theme.set_color("selection_color", "LineEdit", Color(BLOOD_LIT, 0.45))

	# Kaydırıcı (ses vb.)
	var track := flat(Color(0, 0, 0, 0.5), GILT_DIM, 1)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	var fill := flat(GILT)
	fill.content_margin_top = 3
	fill.content_margin_bottom = 3
	theme.set_stylebox("slider", "HSlider", track)
	theme.set_stylebox("grabber_area", "HSlider", fill)
	theme.set_stylebox("grabber_area_highlight", "HSlider", flat(GILT_LIT))

func _lists_and_tabs() -> void:
	var list_panel := tex_box("panel_inset.svg", 9, pad(8, 8))
	var sel := flat(Color(BLOOD, 0.55), GILT, 1)
	theme.set_font("font", "ItemList", FONT_BODY)
	theme.set_stylebox("panel", "ItemList", list_panel)
	theme.set_stylebox("selected", "ItemList", sel)
	theme.set_stylebox("selected_focus", "ItemList", sel)
	theme.set_color("font_color", "ItemList", BONE)
	theme.set_color("font_selected_color", "ItemList", BONE_BRIGHT)

	var tp := pad(16, 7)
	theme.set_font("font", "TabContainer", FONT_TITLE)
	theme.set_font_size("font_size", "TabContainer", 16)
	theme.set_stylebox("panel", "TabContainer", tex_box("panel_inset.svg", 9, pad(16, 14)))
	theme.set_stylebox("tab_selected", "TabContainer", tex_box("btn_selected.svg", 10, tp))
	theme.set_stylebox("tab_unselected", "TabContainer", tex_box("btn_normal.svg", 10, tp))
	theme.set_stylebox("tab_hovered", "TabContainer", tex_box("btn_hover.svg", 10, tp))
	theme.set_color("font_selected_color", "TabContainer", BONE_BRIGHT)
	theme.set_color("font_unselected_color", "TabContainer", BONE_DIM)
	theme.set_color("font_hovered_color", "TabContainer", BONE_BRIGHT)

func _bars_and_separators() -> void:
	var hl := StyleBoxLine.new()
	hl.color = Color(GILT_DIM, 0.8)
	hl.thickness = 1
	hl.content_margin_top = 8
	hl.content_margin_bottom = 8
	var vl := StyleBoxLine.new()
	vl.color = Color(GILT_DIM, 0.8)
	vl.thickness = 1
	vl.vertical = true
	theme.set_stylebox("separator", "HSeparator", hl)
	theme.set_stylebox("separator", "VSeparator", vl)

	theme.set_stylebox("background", "ProgressBar", flat(Color(0, 0, 0, 0.6), GILT_DIM, 1))
	theme.set_stylebox("fill", "ProgressBar", flat(GILT))
	variation("ProgressBarHP", "ProgressBar")
	theme.set_stylebox("fill", "ProgressBarHP", flat(BLOOD_LIT))
	variation("ProgressBarXP", "ProgressBar")
	theme.set_stylebox("fill", "ProgressBarXP", flat(GILT_LIT))

## İnce oluk + belirgin altın tutamak (kaydırılabilir alan tek bakışta anlaşılsın).
func _scrollbars() -> void:
	var groove := flat(Color(0, 0, 0, 0.3))
	groove.set_corner_radius_all(2)
	var grab := flat(GILT_DIM)
	grab.set_corner_radius_all(2)
	var grab_hl := flat(GILT)
	grab_hl.set_corner_radius_all(2)
	for orient in ["V", "H"]:
		var t: String = orient + "ScrollBar"
		var g := groove.duplicate() as StyleBoxFlat
		var a := grab.duplicate() as StyleBoxFlat
		var b := grab_hl.duplicate() as StyleBoxFlat
		for sb in [g, a, b]:
			if orient == "V":
				sb.content_margin_left = 3.0 if sb == g else 3.5
				sb.content_margin_right = sb.content_margin_left
			else:
				sb.content_margin_top = 3.0 if sb == g else 3.5
				sb.content_margin_bottom = sb.content_margin_top
		theme.set_stylebox("scroll", t, g)
		theme.set_stylebox("grabber", t, a)
		theme.set_stylebox("grabber_highlight", t, b)
		theme.set_stylebox("grabber_pressed", t, b)

func _popups_and_tooltips() -> void:
	theme.set_stylebox("panel", "PopupMenu", tex_box("tooltip.svg", 9, pad(6, 6)))
	theme.set_stylebox("hover", "PopupMenu", flat(Color(BLOOD, 0.6)))
	theme.set_font("font", "PopupMenu", FONT_BODY)
	theme.set_color("font_color", "PopupMenu", BONE)
	theme.set_color("font_hover_color", "PopupMenu", BONE_BRIGHT)
	theme.set_stylebox("panel", "TooltipPanel", tex_box("tooltip.svg", 9, pad(12, 8)))
	theme.set_color("font_color", "TooltipLabel", BONE)
	theme.set_font("font", "TooltipLabel", FONT_BODY)
	theme.set_font_size("font_size", "TooltipLabel", 13)

func _save() -> void:
	var dir := DirAccess.open("res://")
	if not dir.dir_exists("res://assets/themes"):
		dir.make_dir_recursive("res://assets/themes")
	var err := ResourceSaver.save(theme, "res://assets/themes/gothic_theme.tres")
	print("Theme successfully saved to: res://assets/themes/gothic_theme.tres" if err == OK
		else "Error saving theme: %d" % err)
	var visual_colors = load("res://scripts/data/game_visual_colors.gd").new()
	var err_colors := ResourceSaver.save(visual_colors, "res://assets/data/game_visual_colors.tres")
	print("GameVisualColors successfully saved to: res://assets/data/game_visual_colors.tres" if err_colors == OK
		else "Error saving GameVisualColors: %d" % err_colors)
	print("--- Gothic Theme Builder Finished ---")
