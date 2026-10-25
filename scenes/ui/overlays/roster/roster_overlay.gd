extends OverlayPanel

## Kadrodaki bir satıra tıklandı — o birimin profili açılır (game_hud).
signal unit_picked(unit: Node)


@onready var fighter_list = %FighterList
@onready var value_label = %ValueLabel
@onready var title_label = $Panel/Margin/VBox/HeaderHBox/Title
@onready var close_btn = $Panel/Margin/VBox/CloseRosterBtn

func _bind_controls() -> void:
	close_btn.pressed.connect(func(): close_pressed.emit())

func update_locale(_new_lang: String = "") -> void:
	title_label.text = LocalizationManager.tr_t("WARBAND_ROSTER")
	close_btn.text = LocalizationManager.tr_t("BACK")
	populate_roster()

## OverlayManager.open_overlay() her açılışta bunu çağırır (has_method kontrolü). Bunsuz liste
## yalnız _ready()'de (HUD kurulurken, henüz hiçbir birim yerleştirilmeden ÖNCE) dolduruluyordu
## ve bir daha ASLA yenilenmiyordu — savaş ortasında açılan Roster "tamamen boş" görünüyordu.
func open_panel() -> void:
	populate_roster()

func populate_roster() -> void:
	if Engine.is_editor_hint():
		return
		
	for child in fighter_list.get_children():
		child.queue_free()
		
	var local_id = NetworkManager.get_local_canonical_id()
	var faction = GameState.get_faction_for_player(local_id)
	var total_cost = 0
	
	var color_gold_bright := GothicThemeHelper.color("color_gold_bright")
	var color_status_down := GothicThemeHelper.color("color_status_down")
	var color_status_hp := GothicThemeHelper.color("color_status_hp")
	var color_muted := GothicThemeHelper.color("color_muted")
	
	for unit in UnitQuery.roster_of(local_id):
		var row = preload("res://scenes/ui/overlays/roster/roster_row_item.tscn").instantiate()
		fighter_list.add_child(row)
		row.setup(unit, color_gold_bright, color_status_down, color_status_hp, color_muted)
		row.picked.connect(func(u): unit_picked.emit(u))
		total_cost += unit.unit_data.cost if unit.unit_data else 0
		
	if faction:
		var fac_name = LocalizationManager.tr_t("FACTION_" + faction.faction_id.to_upper())
		value_label.text = "%d %s [%s]" % [total_cost, LocalizationManager.tr_t("DUKATS"), fac_name]
	else:
		value_label.text = "%d %s" % [total_cost, LocalizationManager.tr_t("DUKATS")]
