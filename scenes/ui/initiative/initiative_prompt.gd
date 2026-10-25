extends PanelContainer

## Initiative (öncelik) seçim istemi. Raund başında, initiative'i kazanan oyuncuya gösterilir:
## ilk mi yoksa ikinci mi aktive olmak istediğini seçer (compendium: initiative sahibi seçer).

signal order_chosen(go_first: bool)

## Ekranın ortasında sabit karar penceresi: başlık + açıklama + iki seçenek.
@onready var title: Label = $Margin/HBox/Title
@onready var label: Label = $Margin/HBox/Label
@onready var first_btn: Button = $Margin/HBox/Buttons/FirstBtn
@onready var second_btn: Button = $Margin/HBox/Buttons/SecondBtn

func _ready():
	if Engine.is_editor_hint():
		return
	first_btn.pressed.connect(func(): order_chosen.emit(true))
	second_btn.pressed.connect(func(): order_chosen.emit(false))
	LocalizationManager.locale_changed.connect(func(_l): _update_locale())
	_update_locale()
	GothicThemeHelper.init_ui(self)

func _update_locale():
	title.text = LocalizationManager.tr_t("INITIATIVE_TITLE")
	label.text = LocalizationManager.tr_t("INITIATIVE_PROMPT")
	first_btn.text = LocalizationManager.tr_t("INITIATIVE_FIRST")
	second_btn.text = LocalizationManager.tr_t("INITIATIVE_SECOND")
