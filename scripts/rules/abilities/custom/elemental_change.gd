## ELEMENTAL CHANGE — Jabirean Alchemist (Iron Sultanate)
##
## Yetenek handler'ı — sözleşme: `apply(ctx: AbilityContext) -> bool`
## (dönüş: `end_activation`). Kayıt: `abilities/ability_registry.gd`.
##
## Bu dosya `ability_executor.gd`den çıkarıldı: her yeni birime özel yetenek
## oraya bir `match` dalı daha ekliyordu ve dosya tavana dayanmıştı.
extends RefCounted

## Başarı: silah elementini bir sonrakine çevirir (fire → gas → shrapnel → fire). Fire/Gas/Shrapnel
## mekanik olarak özdeş; fark hedefin negate_* keyword'ü (bir elementi negate eden düşmana karşı
## başka elemente geçmek avantaj sağlar). Etki injury_resolver.apply_outcome'da current_element ile.
static func apply(ctx: AbilityContext) -> bool:
	var caster = ctx.caster
	var roll_total = ctx.roll_total
	var new_el: StringName = MechanicsResolver.next_element(caster.current_element)
	caster.current_element = new_el
	if caster.multiplayer.has_multiplayer_peer():
		caster.rpc("sync_current_element", new_el)
	GameLogger.log_info("[Elemental Change] %s silah elementini '%s' yaptı (%d)." \
		% [caster.display_name, String(new_el), roll_total], "GAME")
	RpcHelper.sync(caster, "play_ability_feedback", ["buff"])
	return false
