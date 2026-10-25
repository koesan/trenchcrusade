extends OverlayPanel


@onready var close_btn = $Panel/Margin/VBox/CloseProfileBtn
@onready var title_label = $Panel/Margin/VBox/Title
@onready var speed_lbl = $Panel/Margin/VBox/HBox/StatsVBox/StatsGrid/SpeedLbl
@onready var melee_lbl = $Panel/Margin/VBox/HBox/StatsVBox/StatsGrid/MeleeLbl
@onready var ranged_lbl = $Panel/Margin/VBox/HBox/StatsVBox/StatsGrid/RangedLbl
@onready var armour_lbl = $Panel/Margin/VBox/HBox/StatsVBox/StatsGrid/ArmourLbl

@onready var equipped_title = $Panel/Margin/VBox/HBox/FighterDetails/EquippedTitle
@onready var ability_title = $Panel/Margin/VBox/HBox/FighterDetails/AbilityTitle
@onready var status_title = $Panel/Margin/VBox/HBox/FighterDetails/StatusTitle

@onready var fighter_name = %FighterName
@onready var fighter_class = %FighterClass
@onready var speed_val = %SpeedVal
@onready var melee_val = %MeleeVal
@onready var ranged_val = %RangedVal
@onready var armour_val = %ArmourVal

@onready var fighter_gear = %FighterGear
@onready var fighter_ability = %FighterAbility
@onready var fighter_status = %FighterStatus

func _bind_controls() -> void:
	close_btn.pressed.connect(func(): close_pressed.emit())

func update_locale(_new_lang: String = "") -> void:
	title_label.text = LocalizationManager.tr_t("FIGHTER_CARD")
	close_btn.text = LocalizationManager.tr_t("BACK")
	
	speed_lbl.text = LocalizationManager.tr_t("PROFILE_SPEED")
	melee_lbl.text = LocalizationManager.tr_t("PROFILE_MELEE")
	ranged_lbl.text = LocalizationManager.tr_t("PROFILE_RANGED")
	armour_lbl.text = LocalizationManager.tr_t("PROFILE_ARMOUR")
	
	equipped_title.text = LocalizationManager.tr_t("PROFILE_EQUIPPED_GEAR")
	ability_title.text = LocalizationManager.tr_t("PROFILE_SPECIAL_ABILITY")
	status_title.text = LocalizationManager.tr_t("PROFILE_STATUS_BLOOD")
	
	populate_profile()

## Panel her açıldığında O ANDA seçili birimi gösterir.
##
## Eskiden bu davranış `OverlayManager.open_overlay()` içinde `has_method("populate_profile")`
## diye BU PANELE ÖZEL bir dala gömülüydü — yönetici tek bir panelin metod adını biliyordu.
## Sözleşme (`open_panel`) tek tipleşince o özel dal kaldırıldı.
## Kadrodan tıklanan birim (varsa) seçili birimden önceliklidir; bir açılışta kullanılır.
## Seçili birim YOKKEN Kayıtlar → Profil boş sayfa yerine kadroyu açar (game_hud).
var focus_unit: Node = null

func open_panel() -> void:
	populate_profile(focus_unit if is_instance_valid(focus_unit) else GameState.selected_unit)
	focus_unit = null

func populate_profile(p_unit = null) -> void:
	if Engine.is_editor_hint():
		return
		
	var unit = p_unit if is_instance_valid(p_unit) else GameState.selected_unit
	if is_instance_valid(unit):
		fighter_name.text = unit.display_name
		var cls_name = LocalizationManager.tr_t(unit.unit_data.unit_name.to_upper().replace(" ", "_").replace("-", "_")) if (unit.unit_data and unit.unit_data.unit_name != "") else LocalizationManager.tr_t("TRENCH_FIGHTER")
		fighter_class.text = LocalizationManager.tr_t("CLASS_LBL") % cls_name
		
		speed_val.text = "%.0f\"" % unit.speed  # masa oyunu birimi: inç
		melee_val.text = LocalizationManager.tr_t("DICE_MOD_FMT") % unit.melee_dice_modifier
		ranged_val.text = LocalizationManager.tr_t("DICE_MOD_FMT") % unit.ranged_dice_modifier
		armour_val.text = str(unit.armour)
		
		if unit.unit_data:
			var abils = []
			for abil in unit.unit_data.abilities:
				if abil:
					abils.append("%s: %s" % [LocalizationManager.tr_t(abil.display_name), LocalizationManager.tr_t(abil.description)])
			if abils.size() > 0:
				# Her yetenek ayrı paragraf — eskiden aralıksız tek blok hâlinde okunmuyordu.
				fighter_ability.text = "\n\n".join(abils)
			else:
				fighter_ability.text = "-"
			var gear = []
			for atk in unit.unit_data.attacks:
				var l_atk_name = LocalizationManager.tr_t(atk.attack_name)
				gear.append("%s (%s: %+d, %s: %d)" % [l_atk_name, LocalizationManager.tr_t("HASAR"), atk.injury_dice_modifier, LocalizationManager.tr_t("MENZIL"), int(atk.attack_range)])
			if gear.size() > 0:
				fighter_gear.text = "\n".join(gear)
			else:
				fighter_gear.text = LocalizationManager.tr_t("NO_GEAR")
		else:
			fighter_ability.text = "-"
			fighter_gear.text = "-"
			
		var state_key = unit.get_fighter_state()
		var state_str = LocalizationManager.tr_t(state_key)
		fighter_status.text = LocalizationManager.tr_t("STATUS_LBL") % [state_str, unit.blood_markers]
	else:
		fighter_name.text = LocalizationManager.tr_t("SELECT_MINIATURE")
		fighter_class.text = ""
		speed_val.text = "-"
		melee_val.text = "-"
		ranged_val.text = "-"
		armour_val.text = "-"
		fighter_gear.text = "-"
		fighter_ability.text = "-"
		fighter_status.text = "-"
