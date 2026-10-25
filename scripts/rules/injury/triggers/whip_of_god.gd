## WHIP OF GOD (Castigator, Trench Pilgrims)
##
## DOST bir hedefi yakın dövüşle Savaş Dışı ederse, bir sonraki Morale Check'e +1 Dice ayrılır.
extends RefCounted

static func matches(ctx: InjuryContext) -> bool:
	return ctx.is_ooa() and ctx.is_melee and ctx.is_friendly_fire() \
		and ctx.attacker_data() != null \
		and KeywordSystem.has(ctx.attacker_data(), &"whip_of_god")

static func apply(ctx: InjuryContext) -> void:
	var pid: int = ctx.attacker.owner_id
	TurnManager.pending_morale_bonus_dice[pid] = \
		TurnManager.pending_morale_bonus_dice.get(pid, 0) + 1
	GameLogger.log_info("[Whip of God] %s bir sonraki Morale Check'e +1 Dice ayırdı." \
		% ctx.attacker.display_name, "GAME")
