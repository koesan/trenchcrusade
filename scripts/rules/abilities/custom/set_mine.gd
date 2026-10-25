## SET MINE — Sultanate Sapper / New Antioch Combat Engineer
##
## Yetenek handler'ı — sözleşme: `apply(ctx: AbilityContext) -> bool`
## (dönüş: `end_activation`). Kayıt: `abilities/ability_registry.gd`.
##
## İnce adaptör: kural gövdesi `MineActions`ta durur (mayın kurma/etkisizleştirme birlikte
## anlamlı bir alt sistemdir; ikisini tek modülde tutmak doğru sınır).
extends RefCounted

static func apply(ctx: AbilityContext) -> bool:
	return await MineActions.handle_set_mine(ctx.caster)
