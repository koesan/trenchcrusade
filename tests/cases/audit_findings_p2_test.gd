extends RefCounted

## 2026-07-18 genel bakım turu — New Antioch/Iron Sultanate fork denetimiyle bulunan boşluklar.

const KeywordSystem = preload("res://scripts/rules/keyword_system.gd")

## Combat Helmet ([Negate Shrapnel]) 6 warband sayfasında da "always has ... a Combat Helmet"
## diyen birimlerden yalnız 4'ünde (Ecclesiastic Prisoner/Combat Engineer/Shrine Anchorite/
## Communicant) modellenmiş, kalan 6'sında UNUTULMUŞTU: Communicant Anti-Tank Hunter, Mamluk
## Faris, Observer, Scripture Guardian, Sin Eater, Witchburner.
func run(t) -> void:
	_test_combat_helmet_negate_shrapnel_sweep(t)
	_test_mechanized_heavy_infantry_no_tough(t)

func _test_combat_helmet_negate_shrapnel_sweep(t) -> void:
	var units := [
		"communicant_anti_tank_hunter", "mamluk_faris", "observer",
		"scripture_guardian", "sin_eater", "witchburner",
	]
	for name_str in units:
		var ud = load("res://assets/data/units/%s.tres" % name_str)
		t.ok(KeywordSystem.has(ud, &"negate_shrapnel"),
			"%s → Combat Helmet'in [Negate Shrapnel]'i artık modellenmiş" % name_str)

## Mechanized Heavy Infantry'nin compendium profili yalnız [Strong][Negate Heavy][New Antioch]
## taşıyor (new-antioch.md) — [Tough] YOK. has_tough=true fazlalıktı.
func _test_mechanized_heavy_infantry_no_tough(t) -> void:
	var ud = load("res://assets/data/units/new_antioch_mechanized_heavy_infantry.tres")
	t.ok(not ud.has_tough, "Mechanized Heavy Infantry → has_tough KALDIRILDI (compendium'da yok)")
	# Machine Armour loadout'unun Steadfast'i (Down→Scratch) doğrulandı, DOKUNULMADI:
	t.ok(ud.loadout_options[1].extra_keywords.has(&"steadfast"),
		"Machine Armour loadout'u → steadfast korunuyor (compendium: Down→Minor Hit, doğru)")
