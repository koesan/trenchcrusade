## VENGEFUL SCRIPTURE — Scripture Guardian
##
## Yetenek handler'ı — sözleşme: `apply(ctx: AbilityContext) -> bool`
## (dönüş: `end_activation`). Kayıt: `abilities/ability_registry.gd`.
##
## Bu dosya `ability_executor.gd`den çıkarıldı: her yeni birime özel yetenek
## oraya bir `match` dalı daha ekliyordu ve dosya tavana dayanmıştı.
extends RefCounted

## Bu yeteneğin verdiği hazır saldırı kaynağı — `preload` (derleme-zamanı doğrulaması).
## Sabit artık YALNIZ onu kullanan handler'da duruyor; eskiden hepsi ability_executor'daydı.
const ATK_VENGEFUL_SCRIPTURE := preload("res://assets/data/attacks/vengeful_scripture_attack.tres")

## 18" içindeki düşmana kendi Başarı Zarını atar (9" içinde +2, aksi halde +1 DICE). Başarıda
## hedefe Yara Zarı — compendium: "+1 Injury Modifier for each Blood Marker the enemy model has
## (in addition to any benefits you receive if you then spend them to affect the Injury Roll)."
## Kritik: Ignore Armour (+1 Injury Dice zaten compute_injury_modifier'ın GENEL kritik bonusundan
## geliyor — RAW metni bunu tekrar ediyor, Vengeful Scripture'a ÖZGÜ EK bir bonus DEĞİL).
## QA denetimi (2026-07-16): önceki sürüm bu bonusu hiç uygulamıyordu (stale yorum, P0-1'in Blood
## Marker'ı OTOMATİK-eklemeyi kaldırmasından ÖNCE yazılmış) — extra_flat_mod ile düzeltildi.
static func apply(ctx: AbilityContext) -> bool:
	var caster = ctx.caster
	var target = ctx.target
	if not is_instance_valid(target) or target.current_health <= 0:
		return false
	var dist: float = caster.global_position.distance_to(target.global_position)
	var bonus: int = 2 if dist <= 9.0 else 1
	var res: Array = await caster.perform_unit_success_roll(bonus)
	var total: int = res[0]
	var is_crit: bool = res[1]
	GameLogger.log_info("[Vengeful Scripture] %s zar attı: %d (+%d DICE, %.1f m)" \
		% [caster.display_name, total, bonus, dist], "GAME")
	if total < 7:
		GameLogger.log_info("[Vengeful Scripture] Başarısız — hiçbir şey olmaz.", "GAME")
		if RiskyRolls.apply_failure(caster, total, false, "Vengeful Scripture"):
			return true
		return false
	# resolve_injury_roll'un KENDİ harcama seçimi target.blood_markers'ı azaltmadan ÖNCE okunmalı.
	var blood_bonus: int = target.blood_markers
	var atk: Resource = ATK_VENGEFUL_SCRIPTURE
	if is_crit:
		atk = atk.duplicate()
		atk.ignore_armour = true
		GameLogger.log_info("[Vengeful Scripture] Kritik Başarı! %s için Ignore Armour + Yara Zarı." % target.display_name, "COMBAT")
	else:
		GameLogger.log_info("[Vengeful Scripture] Başarılı! %s için Yara Zarı." % target.display_name, "COMBAT")
	await target.resolve_injury_roll(caster, is_crit, false, 0, 0, atk, false, false, false, blood_bonus)
	return false
