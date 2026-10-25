## DEFUSE MINE — Sultanate Sapper / New Antioch Combat Engineer
##
## Yetenek handler'ı — sözleşme: `apply(ctx: AbilityContext) -> bool`
## (dönüş: `end_activation`). Kayıt: `abilities/ability_registry.gd`.
##
## İnce adaptör: kural gövdesi `MineActions`ta (bkz. set_mine.gd).
extends RefCounted

static func apply(ctx: AbilityContext) -> bool:
	return await MineActions.handle_defuse_mine(ctx.caster)
