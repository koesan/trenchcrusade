## ENFORCED ORTHODOXY — menzildeki Down dostları ayağa kaldırır
##
## Yetenek handler'ı — sözleşme: `apply(ctx: AbilityContext) -> bool`
## (dönüş: `end_activation`). Kayıt: `abilities/ability_registry.gd`.
##
## Bu dosya `ability_executor.gd`den çıkarıldı: her yeni birime özel yetenek
## oraya bir `match` dalı daha ekliyordu ve dosya tavana dayanmıştı.
extends RefCounted

## ENFORCED ORTHODOXY — Castigator (Trench Pilgrims)
## Başarı: 8" içindeki tüm dost Down birimler hareket maliyeti olmadan ayağa kalkar.
static func apply(ctx: AbilityContext) -> bool:
	var ability = ctx.ability
	var caster = ctx.caster
	var roll_total = ctx.roll_total
	var healed := 0
	for u in UnitQuery.where(UnitQuery.allies_within(caster, ability.range_meters),
			func(a): return a.is_down):
		u.is_down = false
		healed += 1
		CombatResolver.sync_target_health(u)
		RpcHelper.sync(u, "play_ability_feedback", ["heal"])
	GameLogger.log_info("[Enforced Orthodoxy] %s vaazı başarılı (%d)! %d dost birim ayağa kalktı." \
		% [caster.display_name, roll_total, healed], "GAME")
	return false
