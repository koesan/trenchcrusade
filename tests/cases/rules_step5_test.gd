extends RefCounted

## Compendium denetimi, Adım 5: serbest vuruş tam Melee Attack, uydurma Cumbersome kuralı yok,
## ayağa kalkınca Charge bonusu da yarıya iner, Sounding the Retreat.

func run(t) -> void:
	var ch := FileAccess.get_file_as_string("res://scripts/unit/unit_attack_chains.gd")
	t.ok(ch.contains("_free_strike_modifier(unit, target, strike_weapon)"),
		"Serbest vuruş normal Melee Attack havuzunu kullanır (silah Dice'ı, Fear, Defended Obstacle)")
	t.ok(not ch.contains("perform_unit_success_roll(unit.melee_dice_modifier)"),
		"Serbest vuruşta yalnız Melee karakteristiği kullanan eski yol kalmadı")
	var cr := FileAccess.get_file_as_string("res://scripts/rules/combat_resolver.gd")
	t.ok(not cr.contains("atk.is_cumbersome and attacker.actions_taken.has(\"dash\")"),
		"Compendium'da olmayan 'Cumbersome + Dash' yasağı kaldırıldı")
	var u := FileAccess.get_file_as_string("res://scenes/unit/unit.gd")
	t.ok(u.contains("max_charge_speed *= 0.5\n\t\tbonus_dist *= 0.5"),
		"Ayağa kalkan modelin Charge bonusu da yarıya iner (injuries.md)")
	var tm := FileAccess.get_file_as_string("res://scripts/turn_manager/turn_manager.gd")
	t.ok(tm.contains("CombatChoice.request_sound_retreat(player_id)"), "Moral başarısızlığında Sounding the Retreat sorulur")
