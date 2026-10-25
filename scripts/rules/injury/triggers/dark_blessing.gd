## DARK BLESSING (Wretched)
##
## Savaş Dışı kalınca EN YAKIN dost [Elite] [Heretic] modele +1 Nimet İşareti verir.
extends RefCounted

static func matches(ctx: InjuryContext) -> bool:
	return ctx.is_ooa() and ctx.target_data() != null \
		and KeywordSystem.has(ctx.target_data(), &"dark_blessing")

static func apply(ctx: InjuryContext) -> void:
	var t = ctx.target
	var nearest = UnitQuery.nearest(
		UnitQuery.with_keyword(
			UnitQuery.with_keyword(UnitQuery.allies_of(t), &"elite"), &"heretic"),
		t.global_position)
	if nearest == null:
		return
	nearest.blessing_markers = min(nearest.blessing_markers + 1, 6)
	GameLogger.log_info("[Dark Blessing] %s Savaş Dışı kaldı → %s +1 Nimet İşareti aldı." \
		% [t.display_name, nearest.display_name], "GAME")
	CombatResolver.sync_target_health(nearest)
	RpcHelper.sync(nearest, "play_ability_feedback", ["bless"])
