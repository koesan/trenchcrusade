extends Control

## Battlekit/Loadout seçim overlay'i (FAZ 5, P1-1). Deploy panelinde birden fazla `loadout_options`
## taşıyan bir birim kartı seçildiğinde gösterilir; oyuncu hangi Battlekit kombinasyonuyla
## yerleştireceğini seçer. Tamamen YEREL bir karardır (ağ round-trip'i gerekmez — deploy eden
## oyuncunun kendi ekranında karar verilir, seçim yalnız request_deploy_unit ile sunucuya gider).
## İptal → çağıran taraf birim seçimini de iptal eder (map_input akışı bozulmaz).

@onready var title: Label = $Center/Panel/Margin/VBox/Title
@onready var info: Label = $Center/Panel/Margin/VBox/Info
@onready var buttons: VBoxContainer = $Center/Panel/Margin/VBox/Buttons
@onready var cancel_btn: Button = $Center/Panel/Margin/VBox/CancelBtn

var _callback: Callable = Callable()

func _ready() -> void:
	visible = false
	cancel_btn.text = LocalizationManager.tr_t("CANCEL")
	cancel_btn.pressed.connect(func(): _choose(-1))

## unit_display_name: kartta gösterilecek birim adı. options: Array[LoadoutOption].
## callback(int): seçilen index (0-tabanlı) veya iptal edildiyse -1.
func show_prompt(unit_display_name: String, options: Array, callback: Callable) -> void:
	_callback = callback
	title.text = LocalizationManager.tr_t("LOADOUT_PICKER_TITLE")
	info.text = LocalizationManager.tr_t("LOADOUT_PICKER_INFO") % unit_display_name

	for c in buttons.get_children():
		c.queue_free()
	for i in range(options.size()):
		var opt = options[i]
		var b := Button.new()
		b.theme_type_variation = &"ButtonSecondary"
		b.custom_minimum_size = Vector2(360, 44)
		var label: String = LocalizationManager.tr_t(opt.option_name_key)
		if opt.cost_delta != 0:
			label += "  (%s%d %s)" % ["+" if opt.cost_delta > 0 else "", opt.cost_delta, LocalizationManager.tr_t("DUKATS")]
		b.text = label
		var idx: int = i
		b.pressed.connect(func(): _choose(idx))
		buttons.add_child(b)

	GothicThemeHelper.init_ui(self)
	visible = true

func _choose(value: int) -> void:
	visible = false
	var cb := _callback
	_callback = Callable()
	if cb.is_valid():
		cb.call(value)
