## YARA ZARI TETİKLEYİCİ KAYIT DEFTERİ — faz → SIRALI handler listesi.
##
## NEDEN VAR: `unit.gd::resolve_injury_roll` 306 satırdı ve gövdesinin çoğu ardışık, birbirinden
## bağımsız özel kural bloğuydu. Her yeni birim kuralı oraya bir `if KeywordSystem.has(...)`
## bloğu daha ekliyordu; hiçbiri izole test edilemiyordu.
##
## TETİKLEYİCİ SÖZLEŞMESİ (`injury/triggers/<ad>.gd`):
##     static func matches(ctx: InjuryContext) -> bool   # koşul — SAF olmalı, yan etkisiz
##     static func apply(ctx: InjuryContext) -> void     # etki — `await` edebilir
##
## YENİ TETİKLEYİCİ EKLEME: `triggers/` altına 1 dosya + aşağıdaki uygun faza 1 satır.
## `unit.gd`ye ve `injury_pipeline.gd`ye DOKUNULMAZ.
##
## ⚠ SIRA ANLAMLIDIR. Aşağıdaki diziler, refaktör öncesi `resolve_injury_roll`daki ARDIŞIK blok
## sırasının BİREBİR aynısıdır. Sıra değişirse davranış değişir (ör. Devour serbest bırakma,
## boru hattının sonundaki `sync_target_health(target, true)` sahadan kaldırmasından ÖNCE
## çalışmak ZORUNDADIR). Yeni bir tetikleyiciyi listenin ortasına eklemeden önce düşün.
class_name InjuryTriggers

## Zar ATILMADAN önce — havuz/modifier üzerinde son söz.
const PRE_ROLL := [
	preload("res://scripts/rules/injury/triggers/serpent_moon.gd"),
]

## Yara TABLOSU okundu, `apply_outcome` HENÜZ çağrılmadı — sonucun kendisini değiştirebilirler.
const POST_TABLE := [
	preload("res://scripts/rules/injury/triggers/oracle_beast_cloak.gd"),
]

## Sonuç uygulandı, AKTİVASYON-BİTİŞ kontrolünden ÖNCE.
const POST_OUTCOME := [
	preload("res://scripts/rules/injury/triggers/slashing_attack.gd"),
	preload("res://scripts/rules/injury/triggers/inflict_pain.gd"),
	preload("res://scripts/rules/injury/triggers/ledge_fall.gd"),
]

## Aktivasyon-bitiş kontrolünden SONRA, ağ senkronizasyonundan ÖNCE.
const AFTER_EFFECTS := [
	preload("res://scripts/rules/injury/triggers/devour_release.gd"),
	preload("res://scripts/rules/injury/triggers/whip_of_god.gd"),
	preload("res://scripts/rules/injury/triggers/prize_specimens.gd"),
	preload("res://scripts/rules/injury/triggers/dark_blessing.gd"),
	preload("res://scripts/rules/injury/triggers/beelzebubs_touch.gd"),
	preload("res://scripts/rules/injury/triggers/parasite_host.gd"),
	preload("res://scripts/rules/injury/triggers/law_of_hell.gd"),
	preload("res://scripts/rules/injury/triggers/glorious_deeds.gd"),
]

## Bir fazın tüm tetikleyicilerini SIRAYLA çalıştırır: koşulu tutanların etkisi uygulanır.
##
## Hedef aradaki bir `await` sırasında geçersizleşebilir (ör. Inflict Pain'in serbest vuruşları
## onu Savaş Dışı edebilir) — her adımda yeniden doğrulanır.
static func run_phase(phase: Array, ctx: InjuryContext) -> void:
	for trigger in phase:
		if not is_instance_valid(ctx.target):
			return
		if trigger.matches(ctx):
			await trigger.apply(ctx)

## Kayıtlı TÜM tetikleyiciler (bekçi testleri için).
static func all() -> Array:
	var out: Array = []
	out.append_array(PRE_ROLL)
	out.append_array(POST_TABLE)
	out.append_array(POST_OUTCOME)
	out.append_array(AFTER_EFFECTS)
	return out
