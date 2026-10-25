## GLORIOUS DEEDS — Savaş Dışı olayını aktif senaryo mantığına bildirir
##
## Sniper / Lord of War / Bloodletting / Resist and Bite / Death From Above / Personal Revenge /
## Reaper / Elite Hunter — HANGİSİNİN değerlendirileceğine senaryo mantığı kendi karar verir;
## burası yalnız olayı ve bağlamını iletir.
##
## Yalnız sunucuda anlamlıdır (`ScenarioManager.logic` sunucu-otoriter; `run_morale_checks_phase`
## ile aynı desen) — istemcide `logic` null olduğu için sessizce atlanır.
extends RefCounted

static func matches(ctx: InjuryContext) -> bool:
	return ScenarioManager.logic != null

static func apply(ctx: InjuryContext) -> void:
	ScenarioManager.logic.on_unit_out_of_action(ctx.attacker, ctx.target, ctx.is_melee, {
		"is_ooa": ctx.is_ooa(),
		"blood_before": ctx.blood_before_outcome,
		"blood_after": ctx.target.blood_markers,
		"is_long_range": ctx.deed_is_long_range,
		"in_cover": ctx.deed_in_cover,
		"is_diving_charge": ctx.deed_is_diving_charge,
		"is_bloodbath": ctx.is_bloodbath,
		"attacker_began_down": ctx.attacker.stood_up_this_activation \
			if "stood_up_this_activation" in ctx.attacker else false,
	})
