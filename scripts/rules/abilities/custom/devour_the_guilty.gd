## DEVOUR THE GUILTY — Sin Eater
##
## Yetenek handler'ı — sözleşme: `apply(ctx: AbilityContext) -> bool`
## (dönüş: `end_activation`). Kayıt: `abilities/ability_registry.gd`.
##
## Bu dosya `ability_executor.gd`den çıkarıldı: her yeni birime özel yetenek
## oraya bir `match` dalı daha ekliyordu ve dosya tavana dayanmıştı.
extends RefCounted

## DEVOUR THE GUILTY — Sin Eater (Heretic Legion/Court/Black Grail mercenary, P1-1). Compendium:
## hedef (dost/düşman, 40mm veya daha küçük taban — BU PROJE taban-boyutunu modellemediği için
## bu şart ATLANDI, dokümante) 1" içinde. Düşmansa Risky Success Roll; dostsa Success Roll +1
## Dice (Risky DEĞİL — başarısızlıkta aktivasyon bitmez). Bu ayrım generic requires_roll/is_risky
## sistemine SIĞMADIĞI için (ikisi de sabit alanlar, hedefin ittifakına göre DEĞİŞMİYOR) zar
## burada elle atılıyor (requires_roll=false, bkz. .tres).
static func apply(ctx: AbilityContext) -> bool:
	var caster = ctx.caster
	var target = ctx.target
	if not is_instance_valid(target) or target.current_health <= 0:
		return false
	var is_enemy: bool = target.owner_id != caster.owner_id
	var roll_mod: int = 0 if is_enemy else 1
	var roll_res: Array = await caster.perform_unit_success_roll(roll_mod)
	var total: int = roll_res[0]
	if total < 7:
		GameLogger.log_info("[Devour the Guilty] %s başarısız (%d)." % [caster.display_name, total], "GAME")
		if is_enemy:
			# Düşman hedefte Risky Success Roll — başarısızlık aktivasyonu bitirir.
			return true
		return false
	GameLogger.log_info("[Devour the Guilty] %s başarılı (%d)! %s yutuldu." \
		% [caster.display_name, total, target.display_name], "GAME")
	caster.devoured_unit = target
	# "While it is in the Sin Eater it is considered to be Down for the purposes of Morale Checks."
	target.is_down = true
	RpcHelper.sync(target, "sync_devoured_state", [caster.name])
	CombatResolver.sync_target_health(target)
	RpcHelper.sync(caster, "play_ability_feedback", ["curse"])
	return false
