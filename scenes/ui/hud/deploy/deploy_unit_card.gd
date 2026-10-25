extends Button

## Yerleştirme kartı — sivri kemerli niş içinde birimin 3B modeli, adı ve fiyatı.
##
## Durum (seçili / alınamaz) `refresh_deploy_state` ile YERİNDE güncellenir: kart ve 3B önizlemesi
## bütçe her değiştiğinde yıkılıp yeniden kurulmaz (eskiden kurulurdu → kartlar titreşirdi).
## Alınamayan kart temanın "söndürülmüş niş" stiline (disabled) geçer; NEDENİ üzerine gelince
## açılan bilgi kartında yazar (bkz. game_hud → InfoSpec.for_unit_data).

const ICON_DIR := "res://assets/ui/icons/flat/"

@onready var name_label: Label = $MarginContainer/VBoxContainer/UnitName
@onready var hp_label: Label = $MarginContainer/VBoxContainer/HPLabel
@onready var status_label: Label = $MarginContainer/VBoxContainer/CostRow/StatusLabel
@onready var cost_icon: TextureRect = $MarginContainer/VBoxContainer/CostRow/CostIcon
@onready var preview_placeholder: Control = $MarginContainer/VBoxContainer/PreviewPlaceholder
@onready var leader_badge: Label = %LeaderBadge

var unit_data_res: Resource = null
## Son yazılan durum (değişmediyse hiçbir şey yazılmaz).
var _sig := ""

func setup_for_deployment(ud: Resource, is_selected: bool) -> void:
	unit_data_res = ud
	name_label.text = LocalizationManager.tr_t(ud.unit_name.to_upper().replace(" ", "_").replace("-", "_"))
	for child in preview_placeholder.get_children():
		child.queue_free()
	preview_placeholder.add_child(UIPreviewHelper.create_3d_preview(ud.model_scene_path, Vector2(110, 102)))
	# Maliyet DOĞRU para biriminde — mercenary'ler Glory, diğerleri ducat (iki havuz ayrıdır).
	var glory := EconomyRules.is_glory(ud)
	cost_icon.texture = load(ICON_DIR + ("glory" if glory else "ducat") + ".svg")
	cost_icon.modulate = GothicThemeHelper.color("color_gold_bright" if glory else "color_gold_accent")
	status_label.text = str(ud.cost)
	# Lider olabilen model (warband'da bulunması zorunlu) kartın tepesinde rozetle işaretlenir.
	leader_badge.visible = "is_leader" in ud and ud.is_leader
	leader_badge.text = LocalizationManager.tr_t("DEPLOY_LEADER_BADGE")
	refresh_deploy_state(is_selected)

## Seçim + yerleştirilebilirlik. Karar DeployAvailability'de (kural motoruyla TEK kaynak).
func refresh_deploy_state(is_selected: bool) -> void:
	if unit_data_res == null:
		return
	var reason: String = DeployAvailability.block_reason(GameState.active_deployer_id, unit_data_res)
	var sig := "%s|%s" % [is_selected, reason]
	if sig == _sig:
		return
	_sig = sig
	disabled = reason != ""
	set_pressed_no_signal(is_selected and not disabled)
	name_label.modulate.a = 0.5 if disabled else 1.0
	set_meta("block_reason", reason)
