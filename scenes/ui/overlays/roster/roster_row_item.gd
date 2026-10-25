extends HBoxContainer

## Satıra tıklanınca o birimin profili açılır (roster_overlay → unit_picked).
signal picked(unit: Node)
var _unit: Node = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and is_instance_valid(_unit):
			picked.emit(_unit))
	mouse_entered.connect(func(): modulate = Color.WHITE.lightened(0.12))
	mouse_exited.connect(func(): modulate = Color.WHITE)

@onready var name_lbl = $NameLabel
@onready var gear_lbl = $GearLabel
@onready var status_lbl = $StatusLabel
@onready var blood_lbl = $BloodLabel

func setup(unit: Node, color_gold_bright: Color, color_status_down: Color, color_status_hp: Color, color_muted: Color) -> void:
	_unit = unit
	name_lbl.text = unit.display_name
	
	var gear_text = LocalizationManager.tr_t("RIFLE_BLADE")
	if unit.unit_data:
		var gear_names = []
		for atk in unit.unit_data.attacks:
			gear_names.append(LocalizationManager.tr_t(atk.attack_name))
		if gear_names.size() > 0:
			gear_text = ", ".join(gear_names)
	
	gear_lbl.text = gear_text
	gear_lbl.add_theme_color_override("font_color", color_muted)
	
	var state_key = unit.get_fighter_state()
	status_lbl.text = LocalizationManager.tr_t(state_key)
	if state_key == &"STATE_ACTIVE":
		status_lbl.add_theme_color_override("font_color", color_gold_bright)
	elif state_key == &"STATE_DOWN":
		status_lbl.add_theme_color_override("font_color", color_status_down)
	else:
		status_lbl.add_theme_color_override("font_color", color_status_hp)
		
	blood_lbl.text = LocalizationManager.tr_t("BLOOD_MARKERS_ROSTER") % unit.blood_markers
	blood_lbl.add_theme_color_override("font_color", color_status_hp)
