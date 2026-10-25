class_name OverlayManager
extends RefCounted

## Arayüz katmanlarının (Overlay) açılıp kapatılmasını yöneten yardımcı sınıf.
## Navigasyon ve geri gitme mantığı bu sınıfta kapsüllendi.

var hud: CanvasLayer
var current_overlay: String = ""

# Overlays haritası
var overlays: Dictionary = {}

# Geri navigasyon haritası (Hangi overlay'in hangi üst menüye döneceğini tanımlar)
const NAVIGATION_MAP := {
	"roster": "chronicles",
	"profile": "chronicles",
	"blessings": "chronicles",
	"keywords": "chronicles",
	"guide": "chronicles",
	"settings": "pause",
}

func _init(p_hud: CanvasLayer):
	hud = p_hud
	overlays = {
		"pause": hud.get_node_or_null("%PauseOverlay"),
		"settings": hud.get_node_or_null("%SettingsOverlay"),
		"roster": hud.get_node_or_null("%RosterOverlay"),
		"chronicles": hud.get_node_or_null("%ChroniclesOverlay"),
		"blessings": hud.get_node_or_null("%BlessingsOverlay"),
		"keywords": hud.get_node_or_null("%KeywordsOverlay"),
		"profile": hud.get_node_or_null("%ProfileOverlay"),
		"game_end": hud.get_node_or_null("%GameEndOverlay"),
		"guide": hud.get_node_or_null("%GuideOverlay"),
	}

func open_overlay(overlay_name: String):
	# Mevcut olanı kapat
	close_current_overlay()
	
	if not overlays.has(overlay_name) or overlays[overlay_name] == null:
		return
		
	var overlay = overlays[overlay_name]
	# Açılış hareketi: karartma + panelin hafifçe yerine oturması (bkz. UIAnim)
	UIAnim.pop_in(overlay, overlay.get_node_or_null("Panel"))
	current_overlay = overlay_name

	# SÖZLEŞME: kayıtlı her overlay `OverlayPanel`i türetir ve `open_panel()` sunar
	# (bkz. scenes/ui/overlays/overlay_panel.gd, bekçi: overlay_contract_test.gd).
	# Eskiden burada `has_method("populate_profile")` diye TEK BİR PANELE ÖZEL bir dal vardı —
	# yönetici o panelin metod adını biliyordu. Sözleşme tek tipleşince o dal kaldırıldı.
	overlay.open_panel()

	GameLogger.log_info("Arayüz Katmanı açıldı: %s" % overlay_name.to_upper(), "UI")

func close_current_overlay():
	if current_overlay == "":
		return
		
	var overlay = overlays[current_overlay]
	if is_instance_valid(overlay):
		overlay.visible = false
		if overlay.has_method("close_panel"):
			overlay.close_panel()
			
	GameLogger.log_info("Arayüz Katmanı kapatıldı: %s" % current_overlay.to_upper(), "UI")
	current_overlay = ""

func toggle_overlay(overlay_name: String):
	if current_overlay == overlay_name:
		go_back()
	else:
		open_overlay(overlay_name)

func go_back():
	var parent_key: String = NAVIGATION_MAP.get(current_overlay, "")
	if parent_key != "":
		open_overlay(parent_key)
	else:
		close_current_overlay()
