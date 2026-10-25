## VOICE OF GOD — Observer (New Antioch)
##
## Yetenek handler'ı — sözleşme: `apply(ctx: AbilityContext) -> bool`
## (dönüş: `end_activation`). Kayıt: `abilities/ability_registry.gd`.
##
## Bu dosya `ability_executor.gd`den çıkarıldı: her yeni birime özel yetenek
## oraya bir `match` dalı daha ekliyordu ve dosya tavana dayanmıştı.
extends RefCounted

## Başarı: seçili başka bir DOST model derhal (sıra dışı) aktive olmaya zorlanır. Bu, bir sonraki
## aktivasyonu o modele kilitleyen forced_next_activator ile yaklaşık olarak modellenir.
static func apply(ctx: AbilityContext) -> bool:
	var caster = ctx.caster
	var target = ctx.target
	var roll_total = ctx.roll_total
	# _handle_force_activation ile AYNI düzeltme: has_moved YERİNE TurnManager.activated_units —
	# hareket etmeden ateş eden/yetenek kullanan bir dost has_moved=false kalıp yanlışlıkla
	# "henüz aktive olmamış" sayılabiliyordu.
	if not is_instance_valid(target) or target.current_health <= 0 or target == caster \
			or TurnManager.activated_units.has(target.name):
		GameLogger.log_warn("[Voice of God] Geçersiz hedef (aktive edilmemiş dost model gerekir).", "GAME")
		return false
	TurnManager.forced_next_activator = target.name
	if target.multiplayer.has_multiplayer_peer():
		TurnManager.rpc("sync_forced_activator", target.name)
	GameLogger.log_info("[Voice of God] %s başarılı (%d)! %s sıra dışı aktive olacak." \
		% [caster.display_name, roll_total, target.display_name], "GAME")
	RpcHelper.sync(target, "play_ability_feedback", ["buff"])
	return true  # Caster aksiyonunu kullandı → aktivasyonu biter; zorlanan dost model sırada.
