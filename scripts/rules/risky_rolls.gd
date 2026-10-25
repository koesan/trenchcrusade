## RISKY SUCCESS ROLL — "başarısızlıkta aktivasyon biter" kuralının TEK kaynağı.
##
## COMPENDIUM (comprehensive-rules/success-rolls.md):
##   "A [Risky Success] Roll is taken in exactly the same way as a normal Success Roll. However,
##    if the roll is failed the model's Activation immediately ends."
##
## COMPENDIUM (morale-phase-comprehensive.md, Shaken Warbands):
##   "**ALL** Success Rolls taken for models from a Shaken Warband are treated as Risky Success
##    Rolls (unless they are Risky Success Rolls already)."
##
## KURAL SAPMASI DÜZELTMESİ (2026-07-29 compendium denetimi): "Shaken → hepsi Risky" kuralı
## kod tabanında 19 Success Roll çağrı yerinden yalnız 3'ünde uygulanıyordu (ana saldırı,
## off-hand, yetenek çalıştırıcı). Uygulanmayanlar: çoklu-saldırı zincirlerinin her atışı
## (Cleave/Swinging Blow/Automatic), mayın kurma/etkisizleştirme, kendi zarını atan birime özel
## yetenek handler'ları (Burning Inferno, Temporal Assassin, Vengeful Scripture, Slavemaster,
## Devour the Guilty) ve serbest melee vuruşu. Yani Sarsılmış bir ordu, RAW'ın öngördüğü cezanın
## çoğundan kaçıyordu. Artık karar TEK yerde.
##
## MADDENING BUZZING (Herald of Beelzebub'un +10 terfisi) da aynı aileden: "Success Rolls taken
## for enemy models within 8\" of a model with this ability become Risky Success Rolls."
class_name RiskyRolls

## Başarı eşiği (compendium Success Roll Table: 7-11 Success, 12 Critical).
const SUCCESS_THRESHOLD := 7

## Bu birimin Success Roll'u RISKY sayılır mı?
##
## `source_is_risky`: zarın KAYNAĞI zaten Risky mi (Dash, tırmanma, `is_risky` yetenek,
## `[Risky]` keyword'lü silah). Öyleyse Shaken'a bakmaya gerek yok — sonuç aynı.
static func is_risky(unit, source_is_risky: bool = false) -> bool:
	if source_is_risky:
		return true
	if unit == null or not is_instance_valid(unit):
		return false
	if TurnManager.is_shaken(unit.owner_id):
		return true
	# MADDENING BUZZING: düşman aurası içindeki modelin Success Roll'ları Risky olur.
	return DicePoolBuilder._enemy_aura_nearby(unit, &"maddening_buzzing", DicePoolBuilder.aura_range())

## Bir Success Roll sonucunu değerlendirir; Risky bir BAŞARISIZLIK ise aktivasyonu bitirir.
##
## Döner: aktivasyon bitirildi mi? Çağıran `true` gelince kendi akışını da SONLANDIRMALIDIR
## (ör. çoklu-saldırı zinciri kalan atışları yapmamalı).
##
## `label`: log'da görünecek bağlam ("Cleave", "Set Mine", "Burning Inferno"…).
static func apply_failure(unit, total: int, source_is_risky: bool = false,
		label: String = "") -> bool:
	if total >= SUCCESS_THRESHOLD:
		return false
	if not is_risky(unit, source_is_risky):
		return false
	if unit == null or not is_instance_valid(unit):
		return false
	GameLogger.log_info("[Risky] %s başarısız oldu%s — aktivasyon sona eriyor." \
		% [unit.display_name, (" (%s)" % label) if label != "" else ""], "COMBAT")
	TurnManager.end_unit_activation(unit)
	return true

## Silahın kendi `[Risky]` keyword'ü var mı? (Çağrı yerlerinde tekrar eden kontrol.)
static func weapon_is_risky(atk: Resource) -> bool:
	return atk != null and KeywordSystem.has(atk, &"risky")
