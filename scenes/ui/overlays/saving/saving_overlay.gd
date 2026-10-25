extends ColorRect

@onready var label: Label = $Center/Panel/Margin/VBox/Label
@onready var loader_label: Label = $Center/Panel/Margin/VBox/Loader

func _ready() -> void:
	if not Engine.is_editor_hint():
		LocalizationManager.locale_changed.connect(update_locale)
		update_locale()
		
		visibility_changed.connect(_on_visibility_changed)
		set_process(visible)

func _on_visibility_changed() -> void:
	set_process(visible)
	if visible:
		update_locale()

func update_locale(_new_lang: String = "") -> void:
	if is_instance_valid(label):
		label.text = LocalizationManager.tr_t("SAVING_CAMPAIGN")

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	# Gotik haç sembolünü ritmik olarak karartıp aydınlatalım (Opacity Pulse)
	if is_instance_valid(loader_label):
		var pulse = 0.3 + 0.7 * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.005))
		loader_label.modulate.a = pulse
