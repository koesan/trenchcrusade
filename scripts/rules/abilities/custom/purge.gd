## PURGE — Sin Eater (yutulmuş modeli serbest bırakır)
##
## Yetenek handler'ı — sözleşme: `apply(ctx: AbilityContext) -> bool`
## (dönüş: `end_activation`). Kayıt: `abilities/ability_registry.gd`.
##
## Bu dosya `ability_executor.gd`den çıkarıldı: her yeni birime özel yetenek
## oraya bir `match` dalı daha ekliyordu ve dosya tavana dayanmıştı.
extends RefCounted

## PURGE — Sin Eater (P1-1). Compendium: "A Sin Eater that has a devoured model inside it can
## take a Purge Action. Success Roll +4 Dice. If Success or Critical, deploy the devoured model
## within 1" and place it Down." Success Roll GENERİK execute() akışıyla zaten atıldı
## (requires_roll=true, dice_modifier=4 — bkz. .tres); burada yalnız BAŞARI efekti uygulanır.
static func apply(ctx: AbilityContext) -> bool:
	var caster = ctx.caster
	var roll_total = ctx.roll_total
	var freed = caster.devoured_unit
	if not is_instance_valid(freed):
		caster.devoured_unit = null
		return false
	GameLogger.log_info("[Purge] %s başarılı (%d)! %s serbest bırakıldı." \
		% [caster.display_name, roll_total, freed.display_name], "GAME")
	caster.devoured_unit = null
	freed.is_down = true
	RpcHelper.sync(freed, "sync_devoured_state", [""])
	CombatResolver.sync_target_health(freed)
	RpcHelper.sync(freed, "play_ability_feedback", ["heal"])
	return false
