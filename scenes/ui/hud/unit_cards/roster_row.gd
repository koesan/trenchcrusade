extends Button

## Kadro listesinde tek bir birim satırı: durum ikonu · ad · (lider rozeti) · kan işareti sayısı.
## Durum, işaret ve seçim YALNIZ DEĞİŞİNCE yazılır (`_sig`) — her karede override yazmak
## yerleşimi yeniden hesaplatıp satırları kıpırdatıyordu.

const ICON_DIR := "res://assets/ui/icons/flat/"
## Durum → (ikon, tema rengi). Hazır = hücuma hazır haç; bitti = kum saati; yerde; savaş dışı.
const STATE_LOOK := {
	"ready": ["check", "color_status_good"],
	"spent": ["end_turn", "color_muted"],
	"down": ["down", "color_status_warn"],
	"active": ["march", "color_gold_bright"],
}

var unit: Node = null
var _sig := ""

@onready var _state_icon: TextureRect = %StateIcon
@onready var _name: Label = %Name
@onready var _blood_icon: TextureRect = %BloodIcon
@onready var _blood: Label = %Blood
@onready var _leader: Label = %LeaderBadge

func setup(p_unit: Node) -> void:
	unit = p_unit
	_name.text = unit.display_name
	_leader.visible = unit.unit_data != null and unit.unit_data.is_leader
	_leader.text = LocalizationManager.tr_t("DEPLOY_LEADER_BADGE")
	_blood_icon.texture = load(ICON_DIR + "blood.svg")
	_blood_icon.modulate = GothicThemeHelper.color("color_status_danger")
	refresh(false)

func refresh(is_selected: bool) -> void:
	if not is_instance_valid(unit):
		return
	var state := "ready"
	var cue: StringName = unit.get_meta("activation_cue", &"")
	if unit.has_moved:
		state = "spent"
	elif cue == ActivationCues.ACTIVE:
		state = "active"   # aktivasyonu sürüyor — bitene kadar başka model oynatılamaz
	elif unit.is_down:
		state = "down"
	# Başka model aktifken (ya da Hold Your Fire) bu satır şimdilik oynatılamaz → sönük.
	var waiting: bool = cue == ActivationCues.WAITING
	var sig := "%s|%d|%s|%s" % [state, unit.blood_markers, is_selected, waiting]
	if sig == _sig:
		return
	_sig = sig
	var look: Array = STATE_LOOK[state]
	_state_icon.texture = load(ICON_DIR + look[0] + ".svg")
	_state_icon.modulate = GothicThemeHelper.color(look[1])
	# Aktivasyonu bitmiş birimin adı söner — kim hâlâ hazır, tek bakışta.
	_name.modulate.a = 0.55 if state == "spent" or waiting else 1.0
	_state_icon.modulate.a = 0.55 if waiting else 1.0
	_blood_icon.visible = unit.blood_markers > 0
	_blood.visible = unit.blood_markers > 0
	_blood.text = str(unit.blood_markers)
	set_pressed_no_signal(is_selected)
