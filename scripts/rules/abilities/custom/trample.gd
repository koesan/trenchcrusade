## TRAMPLE — Automaton/ağır model ezme saldırısı
##
## Yetenek handler'ı — sözleşme: `apply(ctx: AbilityContext) -> bool`
## (dönüş: `end_activation`). Kayıt: `abilities/ability_registry.gd`.
##
## Bu dosya `ability_executor.gd`den çıkarıldı: her yeni birime özel yetenek
## oraya bir `match` dalı daha ekliyordu ve dosya tavana dayanmıştı.
extends RefCounted

## Bu yeteneğin verdiği hazır saldırı kaynağı — `preload` (derleme-zamanı doğrulaması).
## Sabit artık YALNIZ onu kullanan handler'da duruyor; eskiden hepsi ability_executor'daydı.
const ATK_TRAMPLE := preload("res://assets/data/attacks/trample_attack.tres")

## TRAMPLE — Brazen Bull / Amalgam
## Yere Serilmiş (Down) bir düşman modele silahsız, Zırh Delen bir Yara Zarı uygular.
static func apply(ctx: AbilityContext) -> bool:
	var caster = ctx.caster
	var target = ctx.target
	if not is_instance_valid(target) or target.current_health <= 0:
		return false
	if not target.is_down:
		GameLogger.log_info("[Trample] %s hedefi Down değil — Trample yalnızca Yere Serilmiş düşmana yapılır." \
			% target.display_name, "GAME")
		return false
	var atk: Resource = ATK_TRAMPLE
	GameLogger.log_info("[Trample] %s → %s: Ezme saldırısı (Zırh Delme)!" % [caster.display_name, target.display_name], "COMBAT")
	await target.resolve_injury_roll(caster, false, true, 0, 0, atk)
	return false
