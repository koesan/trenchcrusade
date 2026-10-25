## DEVOUR THE GUILTY — Sin Eater Savaş Dışı kalınca yuttuğu modeli serbest bırakır
##
## RAW: "If the Sin Eater is taken Out of Action, before removing them from the battlefield,
## deploy the devoured model within 1\" of the Sin Eater and place it Down... the Sin Eater is
## then removed from the battlefield."
##
## SIRA KRİTİK: Sahadan kaldırma boru hattının SONUNDAKİ `sync_target_health(target, true)` ile
## olur — bu yüzden serbest bırakma ondan ÖNCE çalışmalıdır.
##
## Basitleştirme (dokümante): "yer bulunamazsa OOA" koşulu uygulanmadı — proje engel/çakışma
## kontrolünü tam modellemiyor, serbest bırakma her zaman başarılı sayılır.
extends RefCounted

static func matches(ctx: InjuryContext) -> bool:
	return ctx.is_ooa() and is_instance_valid(ctx.target.devoured_unit)

static func apply(ctx: InjuryContext) -> void:
	var t = ctx.target
	var freed = t.devoured_unit
	t.devoured_unit = null
	freed.devoured_by = null
	freed.global_position = t.global_position
	freed.is_down = true
	RpcHelper.sync(freed, "sync_devoured_state", [""])
	RpcHelper.sync(freed, "client_update_move", [freed.global_position])
	CombatResolver.sync_target_health(freed)
	GameLogger.log_info("[Devour the Guilty] %s Savaş Dışı oldu — yuttuğu %s serbest bırakıldı (Down)." \
		% [t.display_name, freed.display_name], "COMBAT")
