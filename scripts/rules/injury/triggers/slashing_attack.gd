## SLASHING ATTACK (Assassin's Dagger, Battlekit özel kuralı)
##
## RAW: "if an Assassin's Dagger causes at least one Blood Marker to be placed next to the target
## model, the Assassin can use a Dash Action to Retreat in the same Activation... enemy models
## within 1\" cannot make a Melee Attack against it before it is moved."
## Yalnız BLOOD (Infection değil) — compendium metni açık.
extends RefCounted

static func matches(ctx: InjuryContext) -> bool:
	return ctx.is_melee and ctx.atk != null \
		and ctx.target.blood_markers > ctx.blood_before_outcome \
		and KeywordSystem.has(ctx.atk, &"slashing_attack")

static func apply(ctx: InjuryContext) -> void:
	var a = ctx.attacker
	a.slashing_attack_active = true
	RpcHelper.sync(a, "sync_ability_flags",
		[a.is_hidden, a.has_fortify_cover, a.shadow_walker_active, true])
	GameLogger.log_info("[Slashing Attack] %s: %s'e Kan İşareti koydu — bu Aktivasyonda Dash ile Retreat yapabilir (serbest vuruşsuz)." \
		% [a.display_name, ctx.target.display_name], "COMBAT")
