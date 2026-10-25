extends RefCounted

## 2026-07-18 genel bakım turu — fork denetimiyle bulunan 2 gerçek içerik boşluğu.

const KeywordSystem = preload("res://scripts/rules/keyword_system.gd")

func run(t) -> void:
	_test_infernal_bomb_ignores_long_range(t)
	_test_herald_maddening_buzzing_not_base_ability(t)

## Artillery Witch'in Infernal Bomb'u compendium'da [Ignore Long Range] taşıyor
## (heretic-legion.md) ama dice_pool_builder.gd'nin uzun-menzil cezası bunu hiç kontrol etmiyordu
## — sonuç: silah her uzun menzilli atışta yanlışlıkla -1 Dice alıyordu. Fix: dice_pool_builder.gd
## _success_entries artık `not KeywordSystem.has(atk, &"ignore_long_range")` de kontrol ediyor
## (kod tarafı tek satır, tam ctx mock'lamak kırılgan olduğu için burada yalnız VERİ kilitleniyor).
func _test_infernal_bomb_ignores_long_range(t) -> void:
	var atk = load("res://assets/data/attacks/infernal_bomb.tres")
	t.ok(KeywordSystem.has(atk, &"ignore_long_range"), "Infernal Bomb → ignore_long_range keyword'ü var")

## Herald of Beelzebub'un Maddening Buzzing'i +10 Dukat'lık Limit-1 bir Battlekit terfisidir
## (loadout_options[1]), TABAN yetenek DEĞİL — ama abilities[]'e koşulsuz eklenmişti, Codex/Guide
## her Herald'ı bu terfiyi almış gibi gösteriyordu. Mekanik zaten keywords{} üzerinden çalışıyordu
## (loadout seçilmeden ateşlenmiyordu) — yalnız YANILTICI base-ability listesi düzeltildi.
func _test_herald_maddening_buzzing_not_base_ability(t) -> void:
	var ud = load("res://assets/data/units/heralds_of_beelzebub.tres")
	for ab in ud.abilities:
		t.ok(ab.ability_id != &"maddening_buzzing",
			"Herald of Beelzebub → Maddening Buzzing artık TABAN ability listesinde değil")
	var found_in_loadout := false
	for opt in ud.loadout_options:
		if opt.extra_keywords.has(&"maddening_buzzing"):
			found_in_loadout = true
	t.ok(found_in_loadout, "Maddening Buzzing hâlâ Battlekit terfisi (loadout_options) olarak seçilebilir")
