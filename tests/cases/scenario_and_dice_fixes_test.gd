extends RefCounted

## 2026-07-18 genel bakım turu — senaryo/ses/zar bulguları (Scenario+Audio+Dice fork denetimi).

const DiceRoller = preload("res://scripts/utils/dice_roller.gd")

func run(t) -> void:
	_test_dice_result_text_never_empty(t)
	_test_infiltrators_allowed_matches_compendium(t)

## Zar sonuç metni: HER roll_type (tanınan veya tanınmayan) için BOŞ OLMAYAN bir anahtar döner.
## Kök neden (fork denetimiyle doğrulandı): dice_bar.gd'nin match'inde "bonus_roll" için hiç dal
## yoktu (Charge bonus mesafesi, Puppet Master, Temporal Assassin — 4 çağrı yeri) → sonuç etiketi
## boş kalıyordu. DiceRoller.result_text_key artık TEK KAYNAK (dice_bar.gd bunu çağırıyor).
func _test_dice_result_text_never_empty(t) -> void:
	var all_known_roll_types := ["success", "morale", "injury", "d6", "bonus_roll", "unknown_future_type"]
	for rt in all_known_roll_types:
		for total in [2, 3, 6, 7, 8, 9, 11, 12]:
			var key := DiceRoller.result_text_key(rt, total)
			t.ok(key != "", "roll_type='%s' total=%d → BOŞ OLMAYAN anahtar (%s)" % [rt, total, key])

	t.eq(DiceRoller.result_text_key("success", 7), "ROLL_SUCCESS_OK", "success eşiği 7+ (regresyon)")
	t.eq(DiceRoller.result_text_key("success", 6), "ROLL_SUCCESS_FAIL", "success eşiği <7 başarısız")
	t.eq(DiceRoller.result_text_key("d6", 3), "ROLL_FRIENDLY_FIRE", "d6 ≤3 → Dost Ateşi (regresyon)")
	t.eq(DiceRoller.result_text_key("d6", 4), "ROLL_ENEMY_HIT", "d6 >3 → Düşman Vuruldu")
	t.eq(DiceRoller.result_text_key("bonus_roll", 5), "ROLL_BONUS_DISTANCE",
		"bonus_roll → artık BOŞ değil, nötr 'atış tamamlandı' mesajı (bu turun ana bug'ı)")

	# Lokalizasyon anahtarları her iki dilde de mevcut olmalı (dice_bar.gd tr_t ile çeviriyor).
	for key in ["ROLL_SUCCESS_OK", "ROLL_SUCCESS_FAIL", "ROLL_INJURY_NONE", "ROLL_INJURY_SCRATCH",
			"ROLL_INJURY_DOWN", "ROLL_INJURY_OUT", "ROLL_FRIENDLY_FIRE", "ROLL_ENEMY_HIT", "ROLL_BONUS_DISTANCE"]:
		t.ok(LocalizationManager.tr_t(key) != key, "TR çeviri mevcut: " + key)

## INFILTRATORS_ALLOWED: ScenarioData alanı fork denetimiyle "tanımlı ama hiç okunmuyordu" bulundu
## (Claim No Man's Land'de Infiltrator'lar RAW'ın yasakladığı özel 8\" yerleşimini hâlâ kullanabiliyordu).
## game.gd::request_deploy_unit artık ScenarioManager.active_scenario.infiltrators_allowed'ı kontrol
## ediyor (canlı-sunucu RPC akışı olduğu için burada yalnız VERİ tarafı kilitleniyor).
func _test_infiltrators_allowed_matches_compendium(t) -> void:
	var claim = load("res://assets/data/scenarios/claim_no_mans_land.tres")
	t.ok(not claim.infiltrators_allowed,
		"Claim No Man's Land → Infiltrators Not Allowed (compendium)")
	var great_war = load("res://assets/data/scenarios/great_war.tres")
	t.ok(great_war.infiltrators_allowed, "Great War → Infiltrators Allowed (compendium)")
	var fields = load("res://assets/data/scenarios/fields_of_glory.tres")
	t.ok(fields.infiltrators_allowed, "Fields of Glory → Infiltrators Allowed (compendium)")
	var high_ground = load("res://assets/data/scenarios/the_high_ground.tres")
	t.ok(high_ground.infiltrators_allowed,
		"The High Ground → Infiltrators Special (izinli, 3\" objective kısıtı ayrı/dokunulmadı)")
