extends VBoxContainer

signal close_pressed

@onready var codex_faction_list = $MainHBox/LeftPanel/ScrollFactions/FactionList
@onready var codex_logo_rect = $MainHBox/MidPanel/HeaderHBox/FactionLogo
@onready var codex_faction_name = $MainHBox/MidPanel/HeaderHBox/FactionName
@onready var codex_faction_lore = $MainHBox/MidPanel/ScrollLore/LoreVBox/FactionLore
@onready var codex_unit_grid = $MainHBox/MidPanel/ScrollUnits/UnitGrid
@onready var codex_unit_preview_container = $MainHBox/RightPanel/RightMargin/ScrollDetails/DetailsVBox/PreviewContainer
@onready var codex_unit_name = $MainHBox/RightPanel/RightMargin/ScrollDetails/DetailsVBox/UnitName
@onready var codex_unit_stats = $MainHBox/RightPanel/RightMargin/ScrollDetails/DetailsVBox/UnitStats
@onready var codex_unit_ability = $MainHBox/RightPanel/RightMargin/ScrollDetails/DetailsVBox/UnitAbility
@onready var codex_unit_lore = $MainHBox/RightPanel/RightMargin/ScrollDetails/DetailsVBox/UnitLore
@onready var close_btn = $CloseButton

func _ready() -> void:
	close_btn.pressed.connect(func(): close_pressed.emit())
	if not Engine.is_editor_hint():
		LocalizationManager.locale_changed.connect(update_locale)
		update_locale()

func _process(delta: float) -> void:
	if not visible or Engine.is_editor_hint():
		return
		
	# Rotate the Codex 3D Preview model
	if codex_unit_preview_container != null and is_instance_valid(codex_unit_preview_container):
		for child in codex_unit_preview_container.get_children():
			if child.get_child_count() > 0:
				var vp = child.get_child(0)
				if vp is SubViewport:
					for model in vp.get_children():
						if model is Node3D and not model is DirectionalLight3D and not model is WorldEnvironment and not model is Camera3D:
							model.rotate_y(0.5 * delta)
							
	# Rotate grid previews slightly
	if codex_unit_grid != null and is_instance_valid(codex_unit_grid):
		for grid_btn in codex_unit_grid.get_children():
			var vbox = grid_btn.get_node_or_null("MarginContainer/VBoxContainer")
			if vbox:
				for sub_child in vbox.get_children():
					if sub_child is SubViewportContainer:
						var vp = sub_child.get_child(0)
						if vp is SubViewport:
							for model in vp.get_children():
								if model is Node3D and not model is DirectionalLight3D and not model is WorldEnvironment and not model is Camera3D:
									model.rotate_y(0.3 * delta)

func update_locale(_new_lang: String = "") -> void:
	$Title.text = LocalizationManager.tr_t("LORE_RULES")
	$MainHBox/LeftPanel/FactionsTitle.text = LocalizationManager.tr_t("MEZHEPLER_FACTIONS")
	$MainHBox/MidPanel/RosterTitle.text = LocalizationManager.tr_t("MEZHEP_NEFERLERI_UNITS")
	close_btn.text = "← " + LocalizationManager.tr_t("BACK")
	
	_populate_codex_factions()

## Overlay sözleşmesi (bkz. `overlay_panel.gd`) — kök `guide_overlay.gd` her açılışta iletir.
## Codex içeriği STATİK veriden gelir (faksiyon/birim .tres'leri), ama liste yeniden kurulunca
## seçim durumu da sıfırlanır; her açılışta tutarlı bir başlangıç sunar.
func open_panel() -> void:
	_populate_codex_factions()

func _populate_codex_factions():
	if not codex_faction_list:
		return
	for child in codex_faction_list.get_children():
		child.queue_free()
		
	for faction in GameState.available_factions:
		var btn = preload("res://scenes/ui/overlays/guide/codex_faction_item.tscn").instantiate()
		
		var tex = faction.logo
		if tex:
			btn.get_node("MarginContainer/HBoxContainer/FactionLogo").texture = tex
			
		btn.get_node("MarginContainer/HBoxContainer/FactionName").text = LocalizationManager.tr_t("FACTION_" + faction.faction_id.to_upper())
		
		btn.pressed.connect(func():
			_on_codex_faction_selected(faction)
		)
		codex_faction_list.add_child(btn)
		
	if GameState.available_factions.size() > 0:
		_on_codex_faction_selected(GameState.available_factions[0])

func _on_codex_faction_selected(faction: Resource):
	codex_faction_name.text = LocalizationManager.tr_t("FACTION_" + faction.faction_id.to_upper())
	var story_key = "FACTION_" + faction.faction_id.to_upper() + "_STORY"
	codex_faction_lore.text = LocalizationManager.tr_t(story_key)
	
	var tex = faction.logo
	if tex:
		codex_logo_rect.texture = tex
		
	for child in codex_unit_grid.get_children():
		child.queue_free()
		
	for ud in faction.available_units:
		var btn = preload("res://scenes/ui/overlays/guide/codex_unit_item.tscn").instantiate()
		btn.custom_minimum_size = Vector2(115, 130)
		
		var preview = UIPreviewHelper.create_3d_preview(ud.model_scene_path, Vector2(105, 80))
		btn.get_node("MarginContainer/VBoxContainer").add_child(preview)
		btn.get_node("MarginContainer/VBoxContainer").move_child(preview, 0)
		
		btn.get_node("MarginContainer/VBoxContainer/UnitName").text = LocalizationManager.tr_t(ud.unit_name.to_upper().replace(" ", "_").replace("-", "_"))
		
		btn.pressed.connect(func():
			_on_codex_unit_selected(ud)
		)
		codex_unit_grid.add_child(btn)
		
	if faction.available_units.size() > 0:
		_on_codex_unit_selected(faction.available_units[0])

func _on_codex_unit_selected(ud: Resource):
	for child in codex_unit_preview_container.get_children():
		child.queue_free()
		
	var preview_3d = UIPreviewHelper.create_3d_preview(ud.model_scene_path, Vector2(260, 200))
	codex_unit_preview_container.add_child(preview_3d)
	
	codex_unit_name.text = LocalizationManager.tr_t(ud.unit_name.to_upper().replace(" ", "_").replace("-", "_"))
	
	# Gerçek Trench Crusade statları (Hız/Zırh/Yakın/Menzil). HP ve İrade (Willpower)
	# masa oyununda YOKTUR — 2026-07-28'de veri katmanından da kaldırıldı (denetim P2-NA-14).
	var spd = ud.speed
	var arm = ud.armour
	var mel = ud.melee_dice_modifier
	var rng = ud.ranged_dice_modifier

	codex_unit_stats.text = LocalizationManager.tr_t("CODEX_STATS_FMT") % [spd, arm, mel, rng]
		
	if ud.get("abilities") and ud.abilities.size() > 0:
		var ability_texts = []
		for abil in ud.abilities:
			if abil:
				var abil_name = LocalizationManager.tr_t(abil.display_name.to_upper().replace(" ", "_"))
				var abil_desc = LocalizationManager.tr_t(abil.description.to_upper().replace(" ", "_"))
				ability_texts.append("✨ %s\n%s" % [abil_name, abil_desc])
		codex_unit_ability.text = "\n\n".join(ability_texts)
		codex_unit_ability.visible = true
	else:
		codex_unit_ability.visible = false

		
	var desc_key = ud.unit_name.to_upper().replace(" ", "_").replace("-", "_") + "_DESC"
	codex_unit_lore.text = LocalizationManager.tr_t(desc_key)
