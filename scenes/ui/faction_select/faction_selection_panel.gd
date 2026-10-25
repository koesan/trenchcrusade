extends CenterContainer

## Controller for the Faction Selection Panel.
## Encapsulates faction card initialization and handles selection signals.

signal faction_selected(faction: Resource)

@onready var title_label: Label = $PanelContainer/MarginContainer/VBoxContainer/Label
@onready var desc_label: Label = $PanelContainer/MarginContainer/VBoxContainer/Description
## KAYDIRMA YOK — kullanıcı isteği: "faction seçim ekranı yarım gözüküyor, aşağı kaydırma
## olmasın, TAM gözüksün". Bu yüzden kartlar `HFlowContainer`da: hepsi aynı anda görünür,
## panel genişliğine sığmazlarsa kaydırma yerine ALT SATIRA sarar. Faksiyon sayısı manifest'ten
## gelse de (bugün 6) kart sayısı hiçbir zaman çok yükselmeyecek — sarma bunun için yeterli
## ve kaydırmadan daha okunaklı.
@onready var cards_container: HFlowContainer = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer

## PANEL GENİŞLİĞİ HESABI (kullanıcı bildirimi: "6 faction yan yana gözüksün, 5 üste 1 alta olmasın")
##   kart 160 (faction_selection.tscn custom_minimum_size)
##   aralık 12 (HFlowContainer h_separation)
##   6 kart = 6*160 + 5*12 = 1020
##   panel iç payı = MarginContainer 2*20 + PanelIron stylebox 2*20 = 80
##   → panel taban genişliği en az 1100 olmalı; 1130 seçildi (küçük emniyet payı).
## Panel 1080'deydi ve akış konteynerine yalnız 1000px kalıyordu — 20px eksik yüzünden 6. kart
## alt satıra düşüyordu. Kart ayrıca `size_flags_horizontal = 3` (EXPAND) ile 190px'e şişiyordu;
## SHRINK_CENTER'a çevrildi.
##
## 7. bir faksiyon eklenirse (7*160 + 6*12 = 1192 > kullanılabilir) HFlowContainer iki satıra
## sarar ve ortalar — bozulma olmaz, yalnız iki sıra olur.
const CARD_WIDTH := 160.0
const CARD_SEPARATION := 12.0

## Hotseat'te (çevrimdışı, aynı ekranda 2 oyuncu) hangi oyuncunun seçim yaptığı artık NET
## gösterilmeli — otomatik faksiyon ataması kaldırıldığından (bkz. GameState.select_faction),
## bu panel artık İKİ oyuncu için de sırayla, gerçekten açılıyor; başlığa "Oyuncu N" eklenmezse
## ikinci oyuncu bunun kendisine mi yoksa bir hataya mı sorulduğunu anlayamaz.
var _active_player_id: int = 0

func _ready() -> void:
	if not Engine.is_editor_hint():
		LocalizationManager.locale_changed.connect(update_locale)
		update_locale()

## game_hud.gd::_update_hud_visibility panel görünür olduğunda çağırır (_get_local_player_id ile).
## Multiplayer'da bu her zaman kendi oyuncunuzdur (bilgi zararsız); hotseat'te sırası gelen oyuncuyu ayırt eder.
func set_active_player(player_id: int) -> void:
	if _active_player_id == player_id:
		return
	_active_player_id = player_id
	update_locale()

func update_locale(_new_lang: String = "") -> void:
	var title: String = LocalizationManager.tr_t("FACTION_SELECT_TITLE")
	if _active_player_id > 0:
		title += "  —  " + PlayerLabel.generic(_active_player_id)
	title_label.text = title
	desc_label.text = LocalizationManager.tr_t("FACTION_SELECT_DESC")
	_setup_faction_cards()

func _setup_faction_cards() -> void:
	if not cards_container:
		return
		
	# Önceki dinamik kartları temizle
	for child in cards_container.get_children():
		child.queue_free()
		
	var card_scene = preload("res://scenes/ui/faction_select/faction_selection.tscn")
	
	for faction in GameState.available_factions:
		var card = card_scene.instantiate()
		card.name = faction.faction_id.to_pascal_case()
		cards_container.add_child(card)
		
		# Logoyu yükle ve ata
		var logo_rect = card.get_node_or_null("MarginContainer/VBoxContainer/FactionLogo")
		if logo_rect:
			logo_rect.texture = faction.logo
			
		# Faksiyon ismini ata
		var name_label = card.get_node_or_null("MarginContainer/VBoxContainer/FactionName")
		if name_label:
			name_label.text = LocalizationManager.tr_t("FACTION_" + faction.faction_id.to_upper())
			
		card.pressed.connect(_on_faction_pressed.bind(faction))
		# BİLGİ POPUP'I (kullanıcı isteği): kartın üstüne gelince faksiyonun hikâyesi ve
		# kısa künyesi gösterilir. TÜM metinler `assets/localization/` içinden gelir —
		# hiçbiri koda gömülü değildir (çeviri tek yerden yapılabilsin).
		var fac: Resource = faction
		card.mouse_entered.connect(func(): _show_faction_info(card, fac))
		card.mouse_exited.connect(_hide_faction_info)
		card.focus_entered.connect(func(): _show_faction_info(card, fac))
		card.focus_exited.connect(_hide_faction_info)
		GothicThemeHelper.init_ui(card)

## Faksiyon künyesi popup'ı. İlk ihtiyaç anında sahne ağacına eklenir.
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

## Faksiyonun okunabilir adı (lokalizasyon anahtarı: FACTION_<ID>).
func _faction_name(faction: Resource) -> String:
	return LocalizationManager.tr_t("FACTION_" + faction.faction_id.to_upper())

func _show_faction_info(anchor: Control, faction: Resource) -> void:
	var upper: String = faction.faction_id.to_upper()
	var facts: Array = [
		{"label": LocalizationManager.tr_t("FACTION_FACT_UNITS"),
		 "value": "%d" % faction.available_units.size()},
		{"label": LocalizationManager.tr_t("FACTION_FACT_ALIGNMENT"),
		 "value": LocalizationManager.tr_t(
			AlignmentRules.label_key(AlignmentRules.of_faction(faction)))},
	]
	# Faksiyona özel kural ÖZETİ varsa künyeye eklenir (Codex'teki ile AYNI kaynak).
	if faction.has_faction_rule and faction.faction_rule_summary != "":
		facts.append({"label": LocalizationManager.tr_t("FACTION_RULES"),
			"value": LocalizationManager.tr_t(faction.faction_rule_summary)})
	_ensure_popup().show_spec(anchor, {
		"title": _faction_name(faction),
		"body": LocalizationManager.tr_t("FACTION_" + upper + "_STORY"),
		"facts": facts,
	})

## Fare KARTTAN çıktı — ama popup'a doğru gidiyor olabilir. `request_hide` kartın üstündeyse
## açık bırakır (kullanıcı isteği: "üstüne gidince açık kalsın ki kaydırabilsin").
func _hide_faction_info() -> void:
	if is_instance_valid(_info_popup):
		_info_popup.request_hide()

func _on_faction_pressed(faction: Resource) -> void:
	if is_instance_valid(_info_popup):
		_info_popup.hide_popup()   # seçim yapıldı: koşulsuz kapat
	faction_selected.emit(faction)

## Arkadaki savaş alanını karartır (bkz. ModalBackdrop).
func _draw() -> void:
	ModalBackdrop.paint(self)
