## GUIDE (Codex) overlay kökü — sözleşmeyi asıl işi yapan `CodexPanel`e iletir.
##
## NEDEN İNCE BİR SARMALAYICI: Bu overlay'in tüm mantığı bir ALT düğümdeki `codex_panel.gd`de
## yaşıyor; kökün kendisi (CenterContainer) scriptsizdi. `OverlayManager` ise overlay'in KÖK
## düğümünü tutar ve sözleşme metotlarını ONUN üzerinde arar — dolayısıyla Guide, `open_panel()`
## kancasına diğer 8 panelin aksine hiçbir zaman erişemiyordu (yapısal bir istisna, sessiz).
## Bu sarmalayıcı istisnayı kaldırır: Guide artık sözleşmenin normal bir üyesi.
extends OverlayPanel

@onready var codex_panel: Node = $Panel/Margin/VBox/CodexPanel

func _bind_controls() -> void:
	# `close_pressed` gerçek panelden gelir; kök düğüm üzerinden yeniden yayınlanır ki
	# `game_hud` diğer overlay'lerle AYNI şekilde (tek döngüde) bağlayabilsin.
	if codex_panel != null and codex_panel.has_signal("close_pressed"):
		codex_panel.close_pressed.connect(func(): close_pressed.emit())

func update_locale(_new_lang: String = "") -> void:
	# CodexPanel kendi lokalizasyonunu doğrudan LocalizationManager'a bağlı yönetir.
	pass

func open_panel() -> void:
	if codex_panel != null and codex_panel.has_method("open_panel"):
		codex_panel.open_panel()
