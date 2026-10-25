extends Control

## Slavemaster (Court of the Seven-Headed Serpent, P1-1) Komut seçim overlay'i. Compendium: hedef
## Yoke Fiend seçildikten SONRA Move/Shoot/Fight/Sacrifice komutlarından biri seçilir. Ammunition
## Sacrament picker ile AYNI desen: tam YEREL karar, seçim ability isteğine ekstra parametre olarak
## eklenir (Blood Marker ödemesi ise AbilityExecutor._handle_slavemaster'da, seçimden SONRA yapılır).

@onready var title: Label = $Center/Panel/Margin/VBox/Title
@onready var info: Label = $Center/Panel/Margin/VBox/Info
@onready var buttons: VBoxContainer = $Center/Panel/Margin/VBox/Buttons
@onready var cancel_btn: Button = $Center/Panel/Margin/VBox/CancelBtn

## Komutlar: [key, title_loc_key]. AbilityExecutor._handle_slavemaster bu key'lerle eşleşir.
const COMMANDS := [
	["move", "SLAVEMASTER_CMD_MOVE"],
	["shoot", "SLAVEMASTER_CMD_SHOOT"],
	["fight", "SLAVEMASTER_CMD_FIGHT"],
	["sacrifice", "SLAVEMASTER_CMD_SACRIFICE"],
]

var _callback: Callable = Callable()

func _ready() -> void:
	visible = false
	cancel_btn.text = LocalizationManager.tr_t("CANCEL")
	cancel_btn.pressed.connect(func(): _choose(""))

## target_display_name: seçim kartında gösterilecek Yoke Fiend adı. callback(String): seçilen
## komut key'i, ya da iptal edildiyse "".
func show_prompt(target_display_name: String, callback: Callable) -> void:
	_callback = callback
	title.text = LocalizationManager.tr_t("SLAVEMASTER_PICKER_TITLE")
	info.text = LocalizationManager.tr_t("SLAVEMASTER_PICKER_INFO") % target_display_name

	for c in buttons.get_children():
		c.queue_free()
	for entry in COMMANDS:
		var key: String = entry[0]
		var title_key: String = entry[1]
		var b := Button.new()
		b.theme_type_variation = &"ButtonSecondary"
		b.custom_minimum_size = Vector2(380, 44)
		b.text = LocalizationManager.tr_t(title_key)
		b.pressed.connect(func(): _choose(key))
		buttons.add_child(b)

	GothicThemeHelper.init_ui(self)
	visible = true

func _choose(value: String) -> void:
	visible = false
	var cb := _callback
	_callback = Callable()
	if cb.is_valid():
		cb.call(value)
