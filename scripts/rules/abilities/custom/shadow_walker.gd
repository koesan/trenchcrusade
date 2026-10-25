## SHADOW WALKER — Goetic Spell
##
## Yetenek handler'ı — sözleşme: `apply(ctx: AbilityContext) -> bool`
## (dönüş: `end_activation`). Kayıt: `abilities/ability_registry.gd`.
##
## Bu dosya `ability_executor.gd`den çıkarıldı: her yeni birime özel yetenek
## oraya bir `match` dalı daha ekliyordu ve dosya tavana dayanmıştı.
extends RefCounted

## SHADOW WALKER — Hunter of the Left Hand Path (Court) — GOETIC (2) Spell.
## Compendium: "You can cast this spell before the spellcaster takes a Retreat Action. If you do
## so, enemy models cannot make a Melee Attack on the spellcaster when they retreat."
## Başarı: bu aktivasyondaki Retreat sırasında düşmanlar serbest yakın dövüş YAPAMAZ (retreat'te tüketilir).
static func apply(ctx: AbilityContext) -> bool:
	var caster = ctx.caster
	var roll_total = ctx.roll_total
	var paid: int = await AbilityExecutor.pay_goetic_cost(caster, 2, 2, "SHADOW_WALKER")
	if paid <= 0:
		GameLogger.log_info("[Shadow Walker] %s büyünün bedelini ödemedi/iptal etti." % caster.display_name, "GAME")
		return false
	caster.shadow_walker_active = true
	if caster.multiplayer.has_multiplayer_peer():
		caster.rpc("sync_ability_flags", caster.is_hidden, caster.has_fortify_cover, caster.shadow_walker_active, caster.slashing_attack_active)
	GameLogger.log_info("[Shadow Walker] %s gölge büyüsü hazır (%d)! Sıradaki Retreat serbest vuruşsuz." \
		% [caster.display_name, roll_total], "GAME")
	RpcHelper.sync(caster, "play_ability_feedback", ["buff"])
	return false
