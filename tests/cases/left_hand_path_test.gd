extends RefCounted

## LEFT-HAND PATH (Hunter of the Left Hand Path, Court) — veride vardı ama hiçbir kodu yoktu,
## oyuncu büyüyü kullanamıyordu (2026-10-24 yetenek denetimi). Kullanılabilir olduğunu kilitler.

func run(t) -> void:
	var ab: Resource = load("res://assets/data/abilities/left_hand_path.tres")
	t.ok(ab != null, "left_hand_path.tres yüklendi")
	if ab == null:
		return
	t.eq(ab.action_key, "left_hand_path", "Eylem anahtarı var (buton üretir)")
	t.eq(ab.target_type, "position", "Hedef: haritada nokta")
	t.ok(AbilityRegistry.is_implemented(&"left_hand_path"), "Handler kayıtlı")
	t.ok(AbilityExecutor.is_actionable_ability(ab), "Komuta panelinde buton olarak görünür")
	var hunter: Resource = load("res://assets/data/units/court_hunter_of_the_left_hand_path.tres")
	t.ok(hunter != null and hunter.abilities.has(ab), "Hunter of the Left Hand Path bu yeteneği taşır")
	t.ok(LocalizationManager.has_key("ACTION_LEFT_HAND_PATH"), "Buton adı lokalize")

	# Goetic güç seçenekleri (compendium: Sorcerer 3 güce kadar, Hell Knight Blood Magic + 1)
	var sorc: Resource = load("res://assets/data/units/court_auxilia_sorceror.tres")
	var hk: Resource = load("res://assets/data/units/court_hell_knight.tres")
	var keys := func(u): return u.loadout_options.map(func(o): return o.option_name_key)
	t.ok(keys.call(sorc).has("SORCERER_GOETIC_BURNING_INFERNO"), "Sorcerer yalnız Burning Inferno seçebilir")
	t.ok(keys.call(hk).has("HELL_KNIGHT_GOETIC_BURNING_INFERNO"), "Hell Knight Burning Inferno seçebilir")
