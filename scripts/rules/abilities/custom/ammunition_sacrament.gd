## AMMUNITION SACRAMENT — Mendelist Ammo Monk (New Antioch)
##
## Yetenek handler'ı — sözleşme: `apply(ctx: AbilityContext) -> bool`
## (dönüş: `end_activation`). Kayıt: `abilities/ability_registry.gd`.
##
## Bu dosya `ability_executor.gd`den çıkarıldı: her yeni birime özel yetenek
## oraya bir `match` dalı daha ekliyordu ve dosya tavana dayanmıştı.
extends RefCounted

## AMMUNITION SACRAMENT — Mendelist Ammo Monk (New Antioch/Iron Sultanate, P1-1). extra_param,
## ammunition_sacrament_picker.gd'nin SACRAMENTS listesindeki 3 key'den biri (yerel seçim, ability
## RPC'sine parametre olarak taşındı). "until the end of its next Activation": bu projede mevcut
## melee/ranged_dice_modifier ömrüyle AYNI yaklaşım kullanılır — unit.reset_turn_actions'ta (yeni
## Tur başında TÜM birimler için) sıfırlanır; "Cartridge"/"Echo" da aynı ömrü paylaşan yeni geçici
## alanlar (temp_cartridge_of_wrath/temp_ranged_injury_bonus).
static func apply(ctx: AbilityContext) -> bool:
	var caster = ctx.caster
	var target = ctx.target
	var extra_param = ctx.extra_param
	if not is_instance_valid(target) or target.current_health <= 0:
		return false
	match extra_param:
		"bullet_of_guided_path":
			target.ranged_dice_modifier += 1
			GameLogger.log_info("[Ammunition Sacrament] %s: Bullet of the Guided Path — %s +1 Ranged Dice." \
				% [caster.display_name, target.display_name], "GAME")
		"echo_of_his_word":
			target.temp_ranged_injury_bonus += 1
			GameLogger.log_info("[Ammunition Sacrament] %s: Echo of His Word — %s +1 Ranged Injury Dice." \
				% [caster.display_name, target.display_name], "GAME")
		"cartridge_of_his_wrath":
			target.temp_cartridge_of_wrath = true
			GameLogger.log_info("[Ammunition Sacrament] %s: Cartridge of His Wrath — %s'in Ranged silahı Blast 2\"+Shrapnel kazandı." \
				% [caster.display_name, target.display_name], "GAME")
		_:
			GameLogger.log_warn("[Ammunition Sacrament] Geçersiz/boş sacrament seçimi — hiçbir efekt uygulanmadı.", "GAME")
			return false
	CombatResolver.sync_target_health(target)
	RpcHelper.sync(target, "play_ability_feedback", ["buff"])
	return false
