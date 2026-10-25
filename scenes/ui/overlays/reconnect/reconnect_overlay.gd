extends ColorRect

@onready var title: Label = $Center/Panel/Margin/VBox/Title
@onready var subtitle: Label = $Center/Panel/Margin/VBox/SubTitle
@onready var quit_btn: Button = $Center/Panel/Margin/VBox/QuitBtn

func _ready() -> void:
	quit_btn.pressed.connect(_on_quit_pressed)
	
	if not Engine.is_editor_hint():
		LocalizationManager.locale_changed.connect(update_locale)
		update_locale()

func update_locale(_new_lang: String = "") -> void:
	if is_instance_valid(title):
		title.text = LocalizationManager.tr_t("WAITING_RECONNECT")
	if is_instance_valid(subtitle):
		subtitle.text = LocalizationManager.tr_t("WAITING_RECONNECT_SUB")
	if is_instance_valid(quit_btn):
		quit_btn.text = LocalizationManager.tr_t("LEAVE_THE_BATTLEFIELD")

func _on_quit_pressed() -> void:
	NetworkManager.leave_game()
	GameState.clear_state()
	LoadingManager.load_scene("res://scenes/ui/main_menu/main_menu.tscn")
