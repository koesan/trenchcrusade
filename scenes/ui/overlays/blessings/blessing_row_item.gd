extends HBoxContainer

@onready var name_lbl: Label = $NameLabel
@onready var count_lbl: Label = $CountLabel

func setup(unit: Node) -> void:
	name_lbl.text = unit.display_name
	count_lbl.text = LocalizationManager.tr_t("BLESSING_MARKERS_ROSTER") % unit.blessing_markers
