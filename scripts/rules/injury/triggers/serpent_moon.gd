## BLESSINGS OF THE SERPENT MOON (Sorcerer, Goetic (2/4/6) Spell)
##
## RAW: "Cast this spell before an Injury Roll is made for the spellcaster. If you do so, add a
## -1 Injury Modifier to the roll for every 2 Blood Markers that were paid to cast the spell."
##
## Bu projede 2-6 arası HERHANGİ bir değer seçilebilir — RAW'ın 3 ayrık değerinin (2/4/6) ÜST
## KÜMESİ, zararsız bir gevşetme (bkz. `AbilityExecutor.pay_goetic_cost` yorumu).
##
## FAZ: zar atılmadan ÖNCE (`flat_mod`u düşürür).
extends RefCounted

static func matches(ctx: InjuryContext) -> bool:
	return ctx.target_data() != null \
		and KeywordSystem.has(ctx.target_data(), &"blessings_of_serpent_moon")

static func apply(ctx: InjuryContext) -> void:
	var paid: int = await AbilityExecutor.try_cast_reactive_goetic(
		ctx.target, &"blessings_of_serpent_moon", 2, 6, "BLESSINGS_OF_SERPENT_MOON")
	if paid <= 0:
		return
	ctx.flat_mod -= int(paid / 2)
	GameLogger.log_info("[Blessings of the Serpent Moon] %s: -%d Injury Modifier (%d Kan İşareti)." \
		% [ctx.target.display_name, int(paid / 2), paid], "GAME")
