extends OverlayPanel

signal resume_pressed
signal settings_pressed
signal save_pressed
signal exit_pressed

func _bind_controls() -> void:
	$Panel/Margin/VBox/ResumeBtn.pressed.connect(func(): resume_pressed.emit())
	$Panel/Margin/VBox/SettingsBtn.pressed.connect(func(): settings_pressed.emit())
	$Panel/Margin/VBox/SaveBtn.pressed.connect(func(): save_pressed.emit())
	$Panel/Margin/VBox/SaveQuitBtn.pressed.connect(func(): exit_pressed.emit())

func update_locale(_new_lang: String = "") -> void:
	$Panel/Margin/VBox/Title.text = LocalizationManager.tr_t("PAUSE_MENU")
	# Alt başlık: oynanan senaryonun adı (yoksa genel cephe başlığı).
	var sc = ScenarioManager.active_scenario
	$Panel/Margin/VBox/SubTitle.text = LocalizationManager.tr_t(sc.scenario_name_key) \
		if sc != null else LocalizationManager.tr_t("SECTOR_TITLE")
	$Panel/Margin/VBox/ResumeBtn.text = LocalizationManager.tr_t("RESUME_MISSION")
	$Panel/Margin/VBox/SettingsBtn.text = LocalizationManager.tr_t("ORDINANCES_SETTINGS")
	$Panel/Margin/VBox/SaveBtn.text = LocalizationManager.tr_t("SAVE_GAME")
	$Panel/Margin/VBox/SaveQuitBtn.text = LocalizationManager.tr_t("SAVE_QUIT")

func open_panel() -> void:
	update_locale()   # senaryo adı panel kurulduktan sonra belli olur
