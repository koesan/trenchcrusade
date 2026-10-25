## BURNING INFERNO — Goetic Spell (Blast + Scatter)
##
## Yetenek handler'ı — sözleşme: `apply(ctx: AbilityContext) -> bool`
## (dönüş: `end_activation`). Kayıt: `abilities/ability_registry.gd`.
##
## Bu dosya `ability_executor.gd`den çıkarıldı: her yeni birime özel yetenek
## oraya bir `match` dalı daha ekliyordu ve dosya tavana dayanmıştı.
extends RefCounted

## Bu yeteneğin verdiği hazır saldırı kaynağı — `preload` (derleme-zamanı doğrulaması).
## Sabit artık YALNIZ onu kullanan handler'da duruyor; eskiden hepsi ability_executor'daydı.
const ATK_BURNING_INFERNO := preload("res://assets/data/attacks/burning_inferno_attack.tres")

## BURNING INFERNO — Sorcerer/Praetor (Court) — GOETIC (1-3) Spell, Cast Spell Action. target
## normal ability-hedefleme akışıyla (target_type="enemy", 36") ÖNCEDEN seçildi.
## SCATTER (keyword.md, 2026-07-16 eklendi): "if the Success Roll was a Failure, the attack will
## scatter instead of missing... subtract the Success Roll from 7... Your opponent must move the
## attack exactly that many inches in a direction of their choice." Hedefin SAHİBİNE (rakip),
## mevcut position-pick altyapısıyla (GameState.pick_mode) yön seçtirilir — tıklanan nokta,
## orijinal hedeften TAM scatter mesafesi kadar (up-to DEĞİL, exact) uzağa normalize edilir.
## Basitleştirme (dokümante): "chosen point ve orijinal hedef arasında Line of Sight olmalı" şartı
## atlandı (proje bu tür LoS-arası-iki-nokta kontrolünü genel olarak modellemiyor).
static func apply(ctx: AbilityContext) -> bool:
	var caster = ctx.caster
	var target = ctx.target
	if not is_instance_valid(target) or target.current_health <= 0:
		return false
	var cost: int = await AbilityExecutor.pay_goetic_cost(caster, 1, 3, "BURNING_INFERNO")
	if cost <= 0:
		GameLogger.log_info("[Burning Inferno] %s büyünün bedelini ödemedi/iptal etti." % caster.display_name, "GAME")
		return false
	var atk: Resource = ATK_BURNING_INFERNO.duplicate()
	atk.blast_radius = float(cost)
	var dist: float = caster.global_position.distance_to(target.global_position)
	var atk_ctx: Dictionary = DicePoolBuilder.build_attack_context(caster, atk, target, dist)
	var modifier: int = DicePoolBuilder.compute_success_modifier(atk_ctx)
	var roll_res: Array = await caster.perform_unit_success_roll(modifier)
	var total: int = roll_res[0]
	# Sarsılmış ordu / Maddening Buzzing altında bu da Risky bir Success Roll'dur (bkz. RiskyRolls).
	if RiskyRolls.apply_failure(caster, total, false, "Burning Inferno"):
		return true
	if total >= 7:
		var is_crit: bool = total >= 12
		atk.ignore_armour = true  # Success/Critical Success → Ignore Armour (compendium)
		GameLogger.log_info("[Burning Inferno] %s isabet ettirdi (%d)! %d\" çaplı patlama, Ignore Armour." \
			% [caster.display_name, total, cost], "GAME")
		MechanicsResolver.execute_blast(caster, target.global_position, atk.blast_radius, atk, is_crit, target)
	else:
		var scatter_dist: float = 7.0 - float(total)
		var picked = await CombatChoice.request_position_pick(target, scatter_dist, "BURNING_INFERNO_SCATTER")
		if picked == null:
			GameLogger.log_info("[Burning Inferno] %s ıskaladı (%d) — hedef sahibi yön seçmedi, patlama tetiklenmedi." \
				% [caster.display_name, total], "GAME")
			return false
		var dir: Vector3 = (picked - target.global_position)
		dir.y = 0.0
		if dir.length() < 0.01:
			dir = Vector3(1, 0, 0)
		dir = dir.normalized()
		var scatter_point: Vector3 = target.global_position + dir * scatter_dist
		GameLogger.log_info("[Burning Inferno] %s ıskaladı (%d) — SCATTER: %.1f\" kaydı." \
			% [caster.display_name, total, scatter_dist], "GAME")
		MechanicsResolver.execute_blast(caster, scatter_point, atk.blast_radius, atk, false)
	return false
