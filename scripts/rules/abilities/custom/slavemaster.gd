## SLAVEMASTER — Yoke Fiend komut sistemi (Court of the Seven-Headed Serpent)
##
## Yetenek handler'ı — sözleşme: `apply(ctx: AbilityContext) -> bool`
## (dönüş: `end_activation`). Kayıt: `abilities/ability_registry.gd`.
##
## Bu dosya `ability_executor.gd`den çıkarıldı: her yeni birime özel yetenek
## oraya bir `match` dalı daha ekliyordu ve dosya tavana dayanmıştı.
extends RefCounted

## SLAVEMASTER — Praetor/Sorcerer/Hell Knight (Court of the Seven-Headed Serpent) — GOETIC (1)
## Spell, Cast Spell Action. target (bir Yoke Fiend, is_valid_ability_target'ta &"hateful" ile
## doğrulanır) normal ability-hedefleme akışıyla ÖNCEDEN seçildi (18" içinde); extra_param
## seçilen komuttur (map_input.gd'nin slavemaster_command_picker akışı, Ammunition Sacrament ile
## AYNI desen). Compendium: "Carrying out a Command does not stop the Yoke Fiend from being
## Activated in the same Turn" — bu yüzden target.has_moved/actions_taken HİÇ değiştirilmez.
static func apply(ctx: AbilityContext) -> bool:
	var caster = ctx.caster
	var target = ctx.target
	var extra_param = ctx.extra_param
	if not is_instance_valid(target) or target.current_health <= 0:
		return false
	var paid: int = await AbilityExecutor.pay_goetic_cost(caster, 1, 1, "SLAVEMASTER")
	if paid <= 0:
		GameLogger.log_info("[Slavemaster] %s büyünün bedelini ödemedi/iptal etti." % caster.display_name, "GAME")
		return false
	match extra_param:
		"move":
			await _slavemaster_move(target)
		"shoot":
			await _slavemaster_shoot(target)
		"fight":
			await _slavemaster_fight(target)
		"sacrifice":
			_slavemaster_sacrifice(target)
		_:
			GameLogger.log_warn("[Slavemaster] Geçersiz komut: '%s'" % extra_param, "GAME")
	return false  # Caster'ın kendi aktivasyonu bitmez (Cast Spell Action normal bir aksiyondur).

## Move Command: harita tıklamasıyla seçilen bir nokta (Yoke Fiend'in kendi Movement'ı kadar,
## nav-mesh clamp'li) — normal Charge/Retreat DEĞİL, düz bir hareket.
static func _slavemaster_move(yoke) -> void:
	var dest = await CombatChoice.request_position_pick(yoke, yoke.movement_range, "SLAVEMASTER_MOVE_PICK")
	if dest == null:
		GameLogger.log_info("[Slavemaster] Move Command iptal edildi.", "GAME")
		return
	var map_rid: RID = yoke.get_world_3d().navigation_map
	var clamped: Vector3 = MovementHelper.keep_base_clearance(yoke, map_rid,
		MovementHelper.get_clamped_target(map_rid, yoke.global_position, dest, yoke.movement_range))
	yoke.global_position = clamped
	RpcHelper.sync(yoke, "client_update_move", [clamped])
	GameLogger.log_info("[Slavemaster] %s Move Command ile hareket etti." % yoke.display_name, "GAME")

## Shoot Command: Yoke Fiend'in kendi Ranged silahıyla (varsa) seçilen bir düşmana ateş eder.
static func _slavemaster_shoot(yoke) -> void:
	var weapon: Resource = MechanicsResolver.first_ranged_attack(yoke.unit_data)
	if weapon == null:
		GameLogger.log_warn("[Slavemaster] %s: Ranged silahı yok, Shoot Command iptal." % yoke.display_name, "GAME")
		GameEvents.ability_rejected.emit("SLAVEMASTER_FAIL_NO_RANGED")
		return
	var reach: float = weapon.attack_range + GameState.ATTACK_RANGE_TOLERANCE
	var in_reach: Array = UnitQuery.where(UnitQuery.within(UnitQuery.enemies_of(yoke), yoke.global_position, reach),
		func(e): return not yoke.get_line_of_sight_status(e).get("is_blocked", false))
	var enemy = await CombatChoice.request_enemy_unit_pick(yoke, "SLAVEMASTER_SHOOT_PICK", in_reach)
	if enemy == null or not is_instance_valid(enemy) or enemy.current_health <= 0:
		GameLogger.log_info("[Slavemaster] Shoot Command iptal edildi (hedef seçilmedi).", "GAME")
		return
	var dist: float = yoke.global_position.distance_to(enemy.global_position)
	if dist > reach:
		GameLogger.log_warn("[Slavemaster] %s: hedef %s menzil dışında, Shoot Command iptal." \
			% [yoke.display_name, enemy.display_name], "GAME")
		GameEvents.ability_rejected.emit("SLAVEMASTER_FAIL_OUT_OF_RANGE")
		return
	var atk_ctx: Dictionary = DicePoolBuilder.build_attack_context(yoke, weapon, enemy, dist)
	var modifier: int = DicePoolBuilder.compute_success_modifier(atk_ctx)
	var roll_res: Array = await yoke.perform_unit_success_roll(modifier)
	var total: int = roll_res[0]
	# Sarsılmış ordu / Maddening Buzzing altında komut atışları da Risky sayılır (bkz. RiskyRolls).
	if RiskyRolls.apply_failure(yoke, total, RiskyRolls.weapon_is_risky(weapon), "Slavemaster"):
		return
	if total >= 7:
		var is_crit: bool = total >= 12
		var injury_target = await enemy._maybe_redirect_to_bodyguard()
		await injury_target.resolve_injury_roll(yoke, is_crit, false, 0, 0, weapon)
	else:
		GameLogger.log_info("[Slavemaster] %s Shoot Command ıskaladı (%d)." % [yoke.display_name, total], "GAME")

## Fight Command: Yoke Fiend'in ANGAJE olduğu (1" içindeki) bir düşmana Melee saldırı. Hedef artık
## otomatik EN YAKIN düşman DEĞİL — Shoot Command ile TUTARLI şekilde oyuncu seçiyor (canlı test
## geri bildirimi: "unit'le hiçbir şey yapamıyorum" — tek yönlü otomatik seçim oyuncuya hiç kontrol
## hissi vermiyordu; birden fazla angaje düşman varken hangisinin vurulacağını oyuncu belirlemeli).
static func _slavemaster_fight(yoke) -> void:
	var weapon: Resource = MechanicsResolver.first_melee_attack(yoke.unit_data)
	if weapon == null:
		GameLogger.log_warn("[Slavemaster] %s: Melee silahı yok, Fight Command iptal." % yoke.display_name, "GAME")
		GameEvents.ability_rejected.emit("SLAVEMASTER_FAIL_NO_MELEE")
		return
	if UnitQuery.engaged_enemies(yoke).is_empty():
		GameLogger.log_warn("[Slavemaster] %s: angaje düşman yok, Fight Command iptal." % yoke.display_name, "GAME")
		GameEvents.ability_rejected.emit("SLAVEMASTER_FAIL_NO_ENGAGED_ENEMY")
		return
	var enemy = await CombatChoice.request_enemy_unit_pick(yoke, "SLAVEMASTER_FIGHT_PICK", UnitQuery.engaged_enemies(yoke))
	if enemy == null or not is_instance_valid(enemy) or enemy.current_health <= 0:
		GameLogger.log_info("[Slavemaster] Fight Command iptal edildi (hedef seçilmedi).", "GAME")
		return
	if yoke.global_position.distance_to(enemy.global_position) > GameState.ENGAGE_RANGE:
		GameLogger.log_warn("[Slavemaster] %s: hedef %s angaje değil, Fight Command iptal." \
			% [yoke.display_name, enemy.display_name], "GAME")
		GameEvents.ability_rejected.emit("SLAVEMASTER_FAIL_NO_ENGAGED_ENEMY")
		return
	var dist: float = yoke.global_position.distance_to(enemy.global_position)
	var atk_ctx: Dictionary = DicePoolBuilder.build_attack_context(yoke, weapon, enemy, dist)
	var modifier: int = DicePoolBuilder.compute_success_modifier(atk_ctx)
	var roll_res: Array = await yoke.perform_unit_success_roll(modifier)
	var total: int = roll_res[0]
	# Sarsılmış ordu / Maddening Buzzing altında komut atışları da Risky sayılır (bkz. RiskyRolls).
	if RiskyRolls.apply_failure(yoke, total, RiskyRolls.weapon_is_risky(weapon), "Slavemaster"):
		return
	if total >= 7:
		var is_crit: bool = total >= 12
		var injury_target = await enemy._maybe_redirect_to_bodyguard()
		await injury_target.resolve_injury_roll(yoke, is_crit, true, 0, 0, weapon)
	else:
		GameLogger.log_info("[Slavemaster] %s Fight Command ıskaladı (%d)." % [yoke.display_name, total], "GAME")

## Sacrifice Command: "The Yoke Fiend kills itself. It is taken Out of Action and crossed off its
## Warband Roster." — doğrudan sahadan kaldırılır (Law of Hell'in kaldırma şekliyle AYNI RPC deseni).
static func _slavemaster_sacrifice(yoke) -> void:
	GameLogger.log_warn("[Slavemaster] %s Sacrifice Command ile kendini feda etti." % yoke.display_name, "GAME")
	RpcHelper.sync(yoke, "sync_health_states",
		[0, yoke.is_down, yoke.blood_markers, yoke.blessing_markers, yoke.infection_markers, false])
