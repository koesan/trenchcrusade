extends RefCounted

## Derleme dumanı (compile smoke) testi.
## Kritik script'leri load() ile derleyerek parse hatalarını erkenden yakalar.
## (GDScript load() sırasında derlenir; parse hatası → null döner.)

const PATHS := [
	"res://scenes/unit/unit.gd",
	"res://scenes/unit/path_range_visualizer.gd",
	"res://scenes/game/game.gd",
	"res://scenes/ui/hud/game_hud.gd",
	"res://scenes/ui/hud/notice_feed/notice_feed.gd",
	"res://scripts/audio/audio_manager.gd",
	"res://scripts/audio/audio_director.gd",
	"res://scenes/ui/hud/action_panel/action_buttons_panel.gd",
	"res://scenes/ui/hud/action_panel/hud_action_button.gd",
	"res://scenes/ui/hud/top_bar/top_bar.gd",
	"res://scripts/turn_manager/turn_manager.gd",
	"res://scripts/game_state/game_state.gd",
	"res://scripts/rules/dice_pool_builder.gd",
	"res://scripts/rules/injury_resolver.gd",
	"res://scripts/rules/mechanics_resolver.gd",
	"res://scripts/rules/combat_resolver.gd",
	"res://scripts/rules/ability_executor.gd",
	"res://scripts/rules/climbing_resolver.gd",
	"res://scripts/unit/unit_actions.gd",
	"res://scripts/unit/unit_combat.gd",
	"res://scripts/unit/unit_movement.gd",
	"res://scripts/unit/unit_visuals.gd",
	"res://scripts/input/map_input.gd",
	"res://scripts/utils/rpc_helper.gd",
	"res://scripts/utils/movement_helper.gd",
	"res://scripts/data/game_visual_colors.gd",
	"res://scripts/game_config.gd",
	"res://scripts/rules/deploy_validator.gd",
	"res://scripts/rules/loadout_resolver.gd",
	"res://scripts/data/loadout_option.gd",
	"res://scenes/ui/deploy/loadout_picker_overlay.gd",
	"res://scenes/ui/hud/deploy/deploy_panel.gd",
	"res://scripts/rules/scenario_logic.gd",
	"res://scripts/rules/scenarios/claim_no_mans_land.gd",
	"res://scripts/rules/scenarios/great_war.gd",
	"res://scripts/rules/scenarios/fields_of_glory.gd",
	"res://scripts/rules/scenarios/the_high_ground.gd",
	"res://scenes/ui/hud/shot_breakdown/shot_breakdown_card.gd",
	"res://scenes/ui/hud/unit_cards/unit_cards_container.gd",
	"res://scenes/ui/hud/deploy/deploy_unit_card.gd",
	"res://scenes/ui/shared/info_popup.gd",
	"res://scripts/ui/info_spec.gd",
]

func run(t) -> void:
	for p in PATHS:
		var s: Resource = load(p)
		t.ok(s != null, "derlenir: " + p.get_file())
