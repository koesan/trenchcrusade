## TRIGGER MARTYRDOM DEVICE — Ecclesiastic Prisoner (Trench Pilgrims)
##
## Yetenek handler'ı — sözleşme: `apply(ctx: AbilityContext) -> bool`
## (dönüş: `end_activation`). Kayıt: `abilities/ability_registry.gd`.
##
## Bu dosya `ability_executor.gd`den çıkarıldı: her yeni birime özel yetenek
## oraya bir `match` dalı daha ekliyordu ve dosya tavana dayanmıştı.
extends RefCounted

## Bu yeteneğin verdiği hazır saldırı kaynağı — `preload` (derleme-zamanı doğrulaması).
## Sabit artık YALNIZ onu kullanan handler'da duruyor; eskiden hepsi ability_executor'daydı.
const ATK_MARTYRDOM_DEVICE := preload("res://assets/data/attacks/martyrdom_device.tres")

## Zar atılmaz (requires_roll=false). Doğrudan MechanicsResolver.execute_martyrdom_device'a delege eder.
static func apply(ctx: AbilityContext) -> bool:
	var caster = ctx.caster
	var atk: Resource = ATK_MARTYRDOM_DEVICE
	await MechanicsResolver.execute_martyrdom_device(caster, atk)
	return true  # Tek kullanımlık — aktivasyon biter

# ─────────────────────────────────────────────────────────────────────────────
# YARDIMCI — Aksiyon senkronizasyonu
# ─────────────────────────────────────────────────────────────────────────────
