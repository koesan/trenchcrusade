extends CenterContainer

## Senaryo seçim paneli. SCENARIO_SELECT aşamasında gösterilir; host/aktif oyuncu bir senaryo
## kartına tıklayarak maçın senaryosunu belirler. İstemciler "host bekleniyor" mesajı görür.
## Kartlar ScenarioManager.available_scenarios'tan dinamik üretilir (yeni senaryo = otomatik kart).

signal scenario_selected(scenario_id: StringName)

const SCENARIO_CARD_SCENE := preload("res://scenes/ui/scenario_select/scenario_card.tscn")

@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var desc_label: Label = $Panel/Margin/VBox/Desc
@onready var cards_scroll: ScrollContainer = $Panel/Margin/VBox/CardsScroll
@onready var cards: GridContainer = $Panel/Margin/VBox/CardsScroll/Cards

## Kart ölçüleri (aşağıdaki `_build_cards` ile aynı değerler) ve ızgara düzeni.
const CARD_WIDTH := 240.0
const CARD_HEIGHT := 150.0
const CARD_SEPARATION := 16.0
const COLUMNS := 3
## Kaydırmasız gösterilecek en fazla SATIR. Panel 420px taban yüksekliğinde; 2 satır
## (2*150 + 16 = 316) başlık/açıklamayla birlikte 720px ekrana rahat sığar.
const MAX_VISIBLE_ROWS := 2
@onready var waiting_label: Label = $Panel/Margin/VBox/Waiting

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	LocalizationManager.locale_changed.connect(_update_locale)
	_update_locale()
	GothicThemeHelper.init_ui(self)

## Bu oyuncu senaryo seçebilir mi? (Host/aktif oyuncu = kartlar; diğerleri = bekleme mesajı.)
func set_local_can_choose(can_choose: bool) -> void:
	if is_instance_valid(cards_scroll):
		cards_scroll.visible = can_choose
	if is_instance_valid(waiting_label):
		waiting_label.visible = not can_choose

func _update_locale(_l: String = "") -> void:
	title_label.text = LocalizationManager.tr_t("SCENARIO_SELECT_TITLE")
	desc_label.text = LocalizationManager.tr_t("SCENARIO_SELECT_DESC")
	waiting_label.text = LocalizationManager.tr_t("SCENARIO_WAITING_HOST")
	_build_cards()

## Senaryo künyesi popup'ı. Sahne ağacına ilk ihtiyaç anında eklenir.
var _info_popup: InfoPopup = null

func _ensure_popup() -> InfoPopup:
	if is_instance_valid(_info_popup):
		return _info_popup
	_info_popup = preload("res://scenes/ui/shared/info_popup.tscn").instantiate()
	# Container'a EKLENMEZ: Container çocuklarının konumunu her karede zorla ayarlar ve
	# popup'ın kendi konumlandırmasını ezer (bkz. UIPlacement.attach_popup).
	UIPlacement.attach_popup(self, _info_popup)
	GothicThemeHelper.init_ui(_info_popup)
	return _info_popup

## Zafer koşulunun okunabilir adı (ScenarioData.VictoryType → lokalize metin).
func _victory_label(sdata: Resource) -> String:
	match sdata.victory_type:
		ScenarioData.VictoryType.OBJECTIVE_VP:
			return LocalizationManager.tr_t("VICTORY_TYPE_VP")
		_:
			return LocalizationManager.tr_t("VICTORY_TYPE_ELIMINATION")

func _show_details(anchor: Control, sdata: Resource) -> void:
	var facts: Array = [
		{"label": LocalizationManager.tr_t("SCENARIO_FACT_TURNS"),
		 "value": "%d" % sdata.turn_limit},
		{"label": LocalizationManager.tr_t("SCENARIO_FACT_VICTORY"),
		 "value": _victory_label(sdata)},
		{"label": LocalizationManager.tr_t("SCENARIO_FACT_BUDGET"),
		 "value": "%d %s" % [sdata.points_budget, LocalizationManager.tr_t("DUKATS")]},
	]
	if sdata.glory_budget > 0:
		facts.append({"label": LocalizationManager.tr_t("SCENARIO_FACT_GLORY"),
			"value": "%d" % sdata.glory_budget})
	if sdata.objectives.size() > 0:
		facts.append({"label": LocalizationManager.tr_t("SCENARIO_FACT_OBJECTIVES"),
			"value": "%d" % sdata.objectives.size()})
	if sdata.infiltrators_allowed:
		facts.append({"label": LocalizationManager.tr_t("SCENARIO_FACT_SPECIAL"),
			"value": LocalizationManager.tr_t("SCENARIO_FACT_INFILTRATORS_OK")})
	_ensure_popup().show_spec(anchor, {
		"title": LocalizationManager.tr_t(sdata.scenario_name_key),
		"body": LocalizationManager.tr_t(sdata.scenario_desc_key),
		"facts": facts,
	})

## Fare KARTTAN çıktı — ama popup'a doğru gidiyor olabilir. `request_hide` kartın üstündeyse
## açık bırakır (kullanıcı isteği: "üstüne gidince açık kalsın ki kaydırabilsin").
func _hide_details() -> void:
	if is_instance_valid(_info_popup):
		_info_popup.request_hide()

func _build_cards() -> void:
	# Kartlar yok ediliyor: popup KOŞULSUZ kapanmalı (fare üstünde olsa bile artık geçersiz).
	if is_instance_valid(_info_popup):
		_info_popup.hide_popup()
	for c in cards.get_children():
		c.queue_free()
	for s in ScenarioManager.available_scenarios:
		if s == null:
			continue
		var sid: StringName = s.scenario_id
		var btn: Button = SCENARIO_CARD_SCENE.instantiate()
		cards.add_child(btn)
		btn.setup(s, _victory_label(s))
		btn.pressed.connect(func(): scenario_selected.emit(sid))
		# ZENGİN AÇIKLAMA: eskiden `tooltip_text` kullanılıyordu — Godot'un yerleşik tooltip'i
		# metni SARMAZ, 150+ karakterlik senaryo açıklamaları ekranı boydan boya geçen TEK BİR
		# SATIR olarak çıkıp okunamıyordu (kullanıcı bildirimi). Artık sarmalı, künyeli
		# `InfoPopup` kartın ÜSTÜNDE açılıyor.
		var sdata: Resource = s
		btn.mouse_entered.connect(func(): _show_details(btn, sdata))
		btn.mouse_exited.connect(_hide_details)
		btn.focus_entered.connect(func(): _show_details(btn, sdata))
		btn.focus_exited.connect(_hide_details)

	# TAŞMA GÜVENLİĞİ: senaryo listesi `assets/data/scenarios/` DİZİN TARAMASINDAN geliyor —
	# yeni bir .tres eklemek kart sayısını otomatik artırır. Tavanı aşan satırlar eskiden paneli
	# 720px'lik ekranın dışına taşırıp alttaki kartları tıklanamaz yapardı; artık kaydırmayla
	# erişiliyor (diğer uzayabilen listelerle AYNI UIScrollHelper deseni).
	var row_count: int = ceili(float(cards.get_child_count()) / float(COLUMNS))
	UIScrollHelper.apply_max_visible(cards_scroll, CARD_HEIGHT, row_count,
		MAX_VISIBLE_ROWS, CARD_SEPARATION)
	# GENİŞLİK: kaydırıcı, ızgaranın TAM bir satırını sığdırmalı. Aksi hâlde container
	# kaydırıcıya kalan yeri verir (bu panelde 724px) ve 3 sütunluk ızgara (752px) yatayda
	# kırpılır — kartların sağ kenarı görünmez olurdu. Panel taban genişliği (820) bunu
	# kaldırıyor, dolayısıyla panel BÜYÜMEZ.
	cards_scroll.custom_minimum_size.x = UIScrollHelper.content_height(
		CARD_WIDTH, COLUMNS, CARD_SEPARATION)
	GothicThemeHelper.init_ui(self)

## Arkadaki savaş alanını karartır (bkz. ModalBackdrop).
func _draw() -> void:
	ModalBackdrop.paint(self)
