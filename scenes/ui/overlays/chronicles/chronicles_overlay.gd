extends OverlayPanel

signal roster_pressed
signal profile_pressed
signal blessings_pressed
signal lore_pressed
signal keywords_pressed

func _bind_controls() -> void:
	$Panel/Margin/VBox/RosterBtn.pressed.connect(func(): roster_pressed.emit())
	$Panel/Margin/VBox/ProfileBtn.pressed.connect(func(): profile_pressed.emit())
	$Panel/Margin/VBox/BlessingsBtn.pressed.connect(func(): blessings_pressed.emit())
	$Panel/Margin/VBox/LoreBtn.pressed.connect(func(): lore_pressed.emit())
	$Panel/Margin/VBox/KeywordsBtn.pressed.connect(func(): keywords_pressed.emit())
	$Panel/Margin/VBox/CloseChroniclesBtn.pressed.connect(func(): close_pressed.emit())


func update_locale(_new_lang: String = "") -> void:
	$Panel/Margin/VBox/Title.text = LocalizationManager.tr_t("CHRONICLES_TITLE")
	$Panel/Margin/VBox/RosterBtn.text = LocalizationManager.tr_t("ROSTER")
	$Panel/Margin/VBox/ProfileBtn.text = LocalizationManager.tr_t("PROFILE")
	$Panel/Margin/VBox/BlessingsBtn.text = LocalizationManager.tr_t("BLESSINGS")
	$Panel/Margin/VBox/LoreBtn.text = LocalizationManager.tr_t("LORE_RULES")
	$Panel/Margin/VBox/KeywordsBtn.text = LocalizationManager.tr_t("KEYWORDS_GLOSSARY")
	$Panel/Margin/VBox/CloseChroniclesBtn.text = LocalizationManager.tr_t("BACK")
