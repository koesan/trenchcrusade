extends PanelContainer
class_name ResourcesPanel

## Oyun içi dukat, inanç ve kan işaretçisi kaynaklarını görselleştiren bağımsız bileşen.

@onready var dukats_lbl = $Margin/HBox/DukatsHBox/DukatsLbl
@onready var dukats_val = $Margin/HBox/DukatsHBox/DukatsVal
@onready var faith_lbl = $Margin/HBox/FaithHBox/FaithLbl
@onready var faith_val = $Margin/HBox/FaithHBox/FaithVal
@onready var blood_lbl = $Margin/HBox/BloodHBox/BloodMarkersLbl
@onready var blood_val = $Margin/HBox/BloodHBox/BloodMarkersVal

func _ready():
	if not Engine.is_editor_hint():
		LocalizationManager.locale_changed.connect(update_locale)
		update_locale()

func update_resources(dukats: int, faith: int, blood: int):
	if not is_node_ready():
		return
	if is_instance_valid(dukats_val) and dukats_val.text != str(dukats):
		dukats_val.text = str(dukats)
	if is_instance_valid(faith_val) and faith_val.text != str(faith):
		# Faith = yerel oyuncunun toplam Nimet İşareti (gerçek veri; sabit /3 kaldırıldı)
		faith_val.text = str(faith)
	if is_instance_valid(blood_val) and blood_val.text != str(blood):
		blood_val.text = str(blood)

func update_locale(_new_lang: String = ""):
	if is_instance_valid(dukats_lbl):
		dukats_lbl.text = LocalizationManager.tr_t("DUKATS")
	if is_instance_valid(faith_lbl):
		faith_lbl.text = LocalizationManager.tr_t("FAITH")
	if is_instance_valid(blood_lbl):
		blood_lbl.text = LocalizationManager.tr_t("BLOOD_MARKERS")
