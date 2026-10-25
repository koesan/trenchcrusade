extends Control

## Ammunition Sacrament seçim overlay'i (P1-1, Mendelist Ammo Monk). Compendium: Risky Roll
## başarılı olduktan sonra 1 dost hedef seçilir, ardından 3 Sacrament'tan biri seçilir. Bu proje
## hedefi ÖNCE harita tıklamasıyla seçtiriyor (mevcut ability-hedefleme akışı); bu overlay hedef
## seçildikten SONRA, RPC isteği gönderilmeden ÖNCE gösterilir — loadout_picker_overlay ile AYNI
## desen (tamamen YEREL karar, seçim ability RPC'sine ekstra parametre olarak eklenir).

@onready var title: Label = $Center/Panel/Margin/VBox/Title
@onready var info: Label = $Center/Panel/Margin/VBox/Info
@onready var buttons: VBoxContainer = $Center/Panel/Margin/VBox/Buttons
@onready var cancel_btn: Button = $Center/Panel/Margin/VBox/CancelBtn

## Sacrament seçenekleri: [key, title_loc_key, desc_loc_key]. AbilityExecutor._handle_ammunition_
## sacrament bu key'lerle eşleşir (bkz. o fonksiyonun match'i) — TEK KAYNAK burada tanımlı.
const SACRAMENTS := [
	["bullet_of_guided_path", "SACRAMENT_BULLET_TITLE", "SACRAMENT_BULLET_DESC"],
	["cartridge_of_his_wrath", "SACRAMENT_CARTRIDGE_TITLE", "SACRAMENT_CARTRIDGE_DESC"],
	["echo_of_his_word", "SACRAMENT_ECHO_TITLE", "SACRAMENT_ECHO_DESC"],
]

var _callback: Callable = Callable()

func _ready() -> void:
	visible = false
	cancel_btn.text = LocalizationManager.tr_t("CANCEL")
	cancel_btn.pressed.connect(func(): _choose(""))

## target_display_name: seçim kartında gösterilecek hedef adı. callback(String): seçilen sacrament
## key'i, ya da iptal edildiyse "".
func show_prompt(target_display_name: String, callback: Callable) -> void:
	_callback = callback
	title.text = LocalizationManager.tr_t("SACRAMENT_PICKER_TITLE")
	info.text = LocalizationManager.tr_t("SACRAMENT_PICKER_INFO") % target_display_name

	for c in buttons.get_children():
		c.queue_free()
	for entry in SACRAMENTS:
		var key: String = entry[0]
		var title_key: String = entry[1]
		var desc_key: String = entry[2]
		var b := Button.new()
		b.theme_type_variation = &"ButtonSecondary"
		b.custom_minimum_size = Vector2(380, 56)
		b.text = "%s\n%s" % [LocalizationManager.tr_t(title_key), LocalizationManager.tr_t(desc_key)]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD
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
