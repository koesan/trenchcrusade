extends RefCounted

## P0-5 regresyon kilidi: HEAVY kısıtı SİMETRİK olmalı. Önceden yalnız "Move/Charge/Retreat/Dash
## sonrası HEAVY Shoot" yönü vardı (CombatResolver.validate_attack); "HEAVY Shoot sonrası Move/
## Charge/Retreat/Dash" yönü eksikti. CombatResolver.heavy_blocks_move_action bu ikinci yönü
## kapsıyor (unit_actions.gd::can_perform_action tarafından tüketilir).

const CombatResolver = preload("res://scripts/rules/combat_resolver.gd")

func run(t) -> void:
	t.ok(CombatResolver.heavy_blocks_move_action(true, "move"), "HEAVY Shoot sonrası Move engellenir")
	t.ok(CombatResolver.heavy_blocks_move_action(true, "charge"), "HEAVY Shoot sonrası Charge engellenir")
	t.ok(CombatResolver.heavy_blocks_move_action(true, "retreat"), "HEAVY Shoot sonrası Retreat engellenir")
	t.ok(CombatResolver.heavy_blocks_move_action(true, "dash"), "HEAVY Shoot sonrası Dash engellenir")
	t.ok(not CombatResolver.heavy_blocks_move_action(true, "melee"), "HEAVY Shoot, Fight'ı engellemez (kısıt yalnız hareket eylemlerinde)")
	t.ok(not CombatResolver.heavy_blocks_move_action(true, "shoot"), "HEAVY Shoot, ikinci bir Shoot'u bu kısıttan engellemez (o zaten tekrar-kısıtıyla engelli)")
	t.ok(not CombatResolver.heavy_blocks_move_action(false, "move"), "HEAVY Shoot yapılmadıysa Move serbest")
