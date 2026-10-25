## BEELZEBUB'S TOUCH (Lord of Tumours)
##
## Bu saldırı hedefe Kan VEYA Enfeksiyon İşareti koyduysa +1 EK Enfeksiyon İşareti.
## Saf predikat `MechanicsResolver.beelzebubs_touch_triggers`te (testli).
extends RefCounted

static func matches(ctx: InjuryContext) -> bool:
	return MechanicsResolver.beelzebubs_touch_triggers(
		ctx.attacker_data(), ctx.is_melee, ctx.marker_placed_this_attack)

static func apply(ctx: InjuryContext) -> void:
	var t = ctx.target
	t.infection_markers = min(t.infection_markers + 1, 6)
	GameLogger.log_info("[Beelzebub's Touch] %s: +1 ek Enfeksiyon İşareti." % t.display_name, "GAME")
	RpcHelper.sync(t, "play_ability_feedback", ["curse"])
