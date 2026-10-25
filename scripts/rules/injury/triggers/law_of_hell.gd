## LAW OF HELL (Wretched)
##
## [Elite] bir düşmanı Savaş Dışı ederse özgürlüğünü kazanır — SALDIRAN sahadan kaldırılır,
## roster/moral dışı kalır. (Hasar değil, kaçış; OOA-temizlik yolu RPC ile kullanılır.)
## Saf predikat `MechanicsResolver.law_of_hell_triggers`te (testli).
extends RefCounted

static func matches(ctx: InjuryContext) -> bool:
	return MechanicsResolver.law_of_hell_triggers(
		ctx.attacker_data(), ctx.target_data(), ctx.is_ooa())

static func apply(ctx: InjuryContext) -> void:
	var a = ctx.attacker
	GameLogger.log_info("[Law of Hell] %s özgürlüğünü kazandı, sahadan çekiliyor." \
		% a.display_name, "GAME")
	RpcHelper.sync(a, "sync_health_states",
		[0, a.is_down, a.blood_markers, a.blessing_markers, a.infection_markers, false])
