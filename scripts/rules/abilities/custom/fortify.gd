## FORTIFY — Sultanate Sapper / Combat Engineer
##
## Yetenek handler'ı — sözleşme: `apply(ctx: AbilityContext) -> bool`
## (dönüş: `end_activation`). Kayıt: `abilities/ability_registry.gd`.
##
## Bu dosya `ability_executor.gd`den çıkarıldı: her yeni birime özel yetenek
## oraya bir `match` dalı daha ekliyordu ve dosya tavana dayanmıştı.
extends RefCounted

## Başarı: model hareket edene kadar Cover (−1 DICE savunma) kazanır (DicePoolBuilder in_cover).
static func apply(ctx: AbilityContext) -> bool:
	var caster = ctx.caster
	var roll_total = ctx.roll_total
	# Gövde FortifyActions'ta: mevzi sahaya GERÇEK bir siper arazi parçası olarak konur
	# (compendium "[Cover] until they move away" — hareket edince unit_movement kaldırır).
	GameLogger.log_info("[Fortify] %s tahkimat kurdu (%d)." % [caster.display_name, roll_total], "GAME")
	return FortifyActions.apply_fortify(caster)
