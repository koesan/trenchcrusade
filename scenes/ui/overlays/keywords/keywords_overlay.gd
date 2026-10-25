extends OverlayPanel

## Anahtar Kelime Sözlüğü (Keyword Glossary) — kullanıcı isteği: ability/silah açıklamalarında
## "[Blast]", "[Cleave]" gibi terimler hiçbir yerde tanımlanmadan kullanılıyordu, oyun içi bir
## sözlük YOKTU (release-candidate QC turunda bulunan yapısal eksiklik). Chronicles hub'ından
## açılır (bkz. chronicles_overlay.gd::keywords_pressed).
##
## Statik bir liste — anahtar kelimeler oyun kuralı olduğundan birim/senaryo verisine bağlı
## DEĞİLDİR, tek seferlik doldurulur yeterlidir (Blessings/Roster'ın "her açılışta yenile"
## ihtiyacı burada yok).


@onready var keyword_list: VBoxContainer = %KeywordList
@onready var close_btn: Button = $Panel/Margin/VBox/CloseKeywordsBtn

## En sık kullanılan ~24 mekanik keyword (terrain-özel olanlar hariç — bu proje terrain
## kurallarını kapsam dışı tutuyor, bkz. plan.md). Sıra kabaca compendium'daki alfabetik sıraya
## yakın tutuldu.
const KEYWORD_IDS := [
	"ASSAULT", "AUTOMATIC", "BLAST", "BLESSING_MARKER", "BLOCK", "BLOOD_MARKER", "CLEAVE",
	"COVER", "CRITICAL", "CUMBERSOME", "DEADLY", "ELITE", "FEAR", "FIRE", "FLAMETHROWER",
	"FLYING", "GAS", "GOLEM", "HEAVY", "IGNORE_ARMOUR", "IGNORE_X", "INFECTION_MARKER",
	"INFILTRATOR", "LEADER", "NEGATE_X", "PISTOL", "REGENERATE", "RELOAD", "RISKY", "SCATTER",
	"SHOTGUN", "SHRAPNEL", "SKIRMISHER", "STRONG", "TOUGH",
]

func _bind_controls() -> void:
	close_btn.pressed.connect(func(): close_pressed.emit())

func update_locale(_new_lang: String = "") -> void:
	$Panel/Margin/VBox/Title.text = LocalizationManager.tr_t("KEYWORDS_GLOSSARY")
	close_btn.text = LocalizationManager.tr_t("BACK")
	_populate()

## OverlayManager.open_overlay() her açılışta çağırır (Blessings/Roster ile aynı desen) —
## içerik statik olduğundan pratikte yalnız dil değişiminde fark yaratır, ama tutarlılık için var.
func open_panel() -> void:
	_populate()

func _populate() -> void:
	if not is_instance_valid(keyword_list):
		return
	for child in keyword_list.get_children():
		child.queue_free()

	for kw_id in KEYWORD_IDS:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 2)

		var name_lbl := Label.new()
		name_lbl.theme_type_variation = &"LabelTitleSmall"
		name_lbl.text = LocalizationManager.tr_t("KEYWORD_" + kw_id)
		row.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.text = LocalizationManager.tr_t("KEYWORD_" + kw_id + "_DESC")
		row.add_child(desc_lbl)

		keyword_list.add_child(row)
