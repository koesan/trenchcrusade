extends Label
class_name DiceValueLabel

## Represents a single 3D die face result value in the 2D UI.
## Formats the unicode text and applies highlight coloring.

func setup_dice(value: int, is_kept: bool) -> void:
	var unicode_faces = ["", "⚀", "⚁", "⚂", "⚃", "⚄", "⚅"]
	text = unicode_faces[clampi(value, 1, 6)]
	
	if is_kept:
		add_theme_color_override("font_color", GothicThemeHelper.color("color_gold_bright"))
	else:
		add_theme_color_override("font_color", GothicThemeHelper.color("color_muted"))
