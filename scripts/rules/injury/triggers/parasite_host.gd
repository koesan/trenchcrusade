## PARASITE HOST (Corpse Guard) + INFECTED PROBOSCIS (Herald of Beelzebub)
##
## Parasite Host: "remove up to 1 Blood Marker OR Infection Marker" — Blood öncelikli, yoksa
## Infection düşer (compendium ikisine de izin veriyor).
##
## Infected Proboscis: compendium AÇIKÇA yalnız Blood Marker der ("you can remove up to 1 Blood
## Marker from the attacking Herald of Beelzebub") — Infection'a DÜŞMEZ. İkisini AYNI kod yolunda
## birleştirmek QA denetiminde hata olarak tespit edilmişti (0 Blood + Infection'ı olan bir Herald
## yanlışlıkla kendi Infection'ını kaldırabiliyordu); bu ayrım burada korunuyor.
extends RefCounted

static func _is_infected_proboscis(ctx: InjuryContext) -> bool:
	return ctx.is_melee and ctx.marker_placed_this_attack \
		and ctx.attacker_data() != null \
		and KeywordSystem.has(ctx.attacker_data(), &"infected_proboscis")

static func matches(ctx: InjuryContext) -> bool:
	return MechanicsResolver.parasite_host_triggers(
		ctx.attacker_data(), ctx.is_melee, ctx.marker_placed_this_attack) \
		or _is_infected_proboscis(ctx)

static func apply(ctx: InjuryContext) -> void:
	var a = ctx.attacker
	var proboscis: bool = _is_infected_proboscis(ctx)
	if a.blood_markers > 0:
		a.blood_markers -= 1
		GameLogger.log_info("[Parasite Host/Infected Proboscis] %s: kendi üzerinden 1 Kan İşareti kaldırdı." \
			% a.display_name, "GAME")
	elif a.infection_markers > 0 and not proboscis:
		a.infection_markers -= 1
		GameLogger.log_info("[Parasite Host] %s: kendi üzerinden 1 Enfeksiyon İşareti kaldırdı." \
			% a.display_name, "GAME")
	CombatResolver.sync_target_health(a)
	RpcHelper.sync(a, "play_ability_feedback", ["buff"])
