## ORACLE BEAST CLOAK (Hunter of the Left Hand Path, Goetic (3) Spell)
##
## RAW: "You can cast this spell once per Turn after an Injury Roll is made for the spellcaster.
## If you do so, the result of the Injury Roll is changed to a No Effect result."
##
## FAZ: yara TABLOSU okundu ama `apply_outcome` HENÜZ çağrılmadı. Böylece `apply_outcome`un yan
## etkilerinden (marker basma, Tough negasyonu vb.) tamamen kaçınılır — sonuç doğrudan
## NO_EFFECT'e çevrilir.
##
## "Turn başına 1" kısıtı `goetic_spells_cast_this_activation` ile sağlanır: bu projede her birim
## rounda (= compendium'un "Turn"u) yalnız 1 kez aktive olduğundan "Activation başına 1" ile
## "Turn başına 1" AYNI şeydir (bkz. `AbilityExecutor.try_cast_reactive_goetic`).
extends RefCounted

static func matches(ctx: InjuryContext) -> bool:
	return ctx.raw_outcome != InjuryResolver.Outcome.NO_EFFECT \
		and ctx.target_data() != null \
		and KeywordSystem.has(ctx.target_data(), &"oracle_beast_cloak")

static func apply(ctx: InjuryContext) -> void:
	var paid: int = await AbilityExecutor.try_cast_reactive_goetic(
		ctx.target, &"oracle_beast_cloak", 3, 3, "ORACLE_BEAST_CLOAK")
	if paid <= 0:
		return
	GameLogger.log_info("[Oracle Beast Cloak] %s Yara Zarı sonucunu No Effect'e çevirdi." \
		% ctx.target.display_name, "GAME")
	ctx.raw_outcome = InjuryResolver.Outcome.NO_EFFECT
