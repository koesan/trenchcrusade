## PRIZE SPECIMENS (Combat Biologist)
##
## Demonic/Black Grail bir düşmanı MELEE ile Savaş Dışı edince saldıran +1 Nimet İşareti kazanır.
## Saf predikat `MechanicsResolver.prize_specimens_gains_blessing`te (testli).
extends RefCounted

static func matches(ctx: InjuryContext) -> bool:
	return MechanicsResolver.prize_specimens_gains_blessing(
		ctx.attacker_data(), ctx.target_data(), ctx.is_melee, ctx.is_ooa())

static func apply(ctx: InjuryContext) -> void:
	var a = ctx.attacker
	a.blessing_markers = min(a.blessing_markers + 1, 6)
	GameLogger.log_info("[Prize Specimens] %s değerli bir örnek aldı → +1 Nimet İşareti." \
		% a.display_name, "GAME")
	CombatResolver.sync_target_health(a)
	RpcHelper.sync(a, "play_ability_feedback", ["bless"])
