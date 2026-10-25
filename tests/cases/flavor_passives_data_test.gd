extends RefCounted

## Flavor pasif "wiring" regresyon kilidi — pasiflerin mekanik etkisi doğru keyword'lerle
## unit .tres'lerine bağlı mı? (Kod hook'ları zaten var: dash_dice_bonus unit.gd:364; agile
## climb/diving roll'larında; ignore_standup_penalty standup halving'de.)

func _kw(path: String) -> Dictionary:
	var ud = load("res://assets/data/units/" + path + ".tres")
	if ud == null:
		return {}
	return ud.keywords

func run(t) -> void:
	# ── Dash +1 DICE (Frightening Speed / Loping Dash / Mad Dash / Agile) ──
	t.eq(int(_kw("hound_of_the_black_grail").get(&"dash_dice_bonus", 0)), 1,
		"Hound (Frightening Speed) → dash_dice_bonus=1")
	t.eq(int(_kw("hound_of_the_black_grail").get(&"ignore_standup_penalty", 0)), 1,
		"Hound (Frightening Speed) → ignore_standup_penalty=1")
	t.eq(int(_kw("war_wolf_assault_beast").get(&"dash_dice_bonus", 0)), 1,
		"War Wolf (Loping Dash) → dash_dice_bonus=1")
	t.eq(int(_kw("ecclesiastic_prisoner").get(&"dash_dice_bonus", 0)), 1,
		"Ecclesiastic Prisoner (Mad Dash) → dash_dice_bonus=1")

	# ── Agile: Dash + Climb/Jump/Diving Charge +1 DICE ──
	t.eq(int(_kw("lions_of_jabir").get(&"dash_dice_bonus", 0)), 1,
		"Lion of Jabir (Agile) → dash_dice_bonus=1")
	t.eq(int(_kw("lions_of_jabir").get(&"agile", 0)), 1,
		"Lion of Jabir (Agile) → agile=1")
	t.eq(int(_kw("stigmatic_nun").get(&"dash_dice_bonus", 0)), 1,
		"Stigmatic Nun (Agile) → dash_dice_bonus=1")
	t.eq(int(_kw("stigmatic_nun").get(&"agile", 0)), 1,
		"Stigmatic Nun (Agile) → agile=1")

	# ── Iron Fists (Communicant Anti-Tank Hunter): silahsız Cleave 2 MELEE saldırısı ──
	var ath = load("res://assets/data/units/communicant_anti_tank_hunter.tres")
	var has_cleave_melee := false
	if ath != null:
		for a in ath.attacks:
			if a != null and a.attack_type == "MELEE" and a.has_cleave and a.cleave_count == 2:
				has_cleave_melee = true
	t.ok(has_cleave_melee, "Communicant ATH (Iron Fists) → Cleave 2 melee saldırısı var")

	# ── Overwhelming Horde (Grail/Fly Thrall): 3" içi dost başına +1 DICE aura keyword'ü ──
	t.eq(int(_kw("grail_thrall").get(&"overwhelming_horde", 0)), 1,
		"Grail Thrall → overwhelming_horde=1")
	t.eq(int(_kw("fly_thrall").get(&"overwhelming_horde", 0)), 1,
		"Fly Thrall → overwhelming_horde=1")

	# ── Skirmisher (Azeb, RAW: +5 Ducats'lık İSTEĞE BAĞLI yükseltme, taban yetenek DEĞİL) ──
	# Bkz. iron-sultanate.md "Upgrades: Skirmisher - 5" — taban keywords'te YER ALMAMALI,
	# yalnız AZEB_LOADOUT_SKIRMISHER seçildiğinde LoadoutResolver.extra_keywords ile eklenir.
	t.eq(int(_kw("azebs").get(&"skirmisher", 0)), 0, "Azeb taban → skirmisher=0 (yalnız loadout ile)")
	var azeb_base = load("res://assets/data/units/azebs.tres")
	t.ok(azeb_base.loadout_options.size() >= 2,
		"Azeb → en az 2 loadout (Standard/Skirmisher; Armoury seçenekleri sonradan eklenebilir)")
	var azeb_skirmisher_opt = azeb_base.loadout_options[1]
	t.eq(int(azeb_skirmisher_opt.extra_keywords.get(&"skirmisher", 0)), 1,
		"Azeb Skirmisher loadout → extra_keywords.skirmisher=1")

	# ── Hateful (Yoke Fiend): zorunlu charge keyword'ü ──
	t.eq(int(_kw("court_yoke_fiend").get(&"hateful", 0)), 1, "Yoke Fiend → hateful=1")

	# ── Prize Specimens (Combat Biologist): keyword ──
	t.eq(int(_kw("combat_biologist").get(&"prize_specimens", 0)), 1, "Combat Biologist → prize_specimens=1")

	# ── Mastery of the Elements (Jabirean Alchemist): keyword (Elemental Change için) ──
	t.eq(int(_kw("jabirean_alchemist").get(&"mastery_of_elements", 0)), 1,
		"Jabirean Alchemist → mastery_of_elements=1")

	# ── Dug In (battlekit.md Shovel — "equipment", faction-bağımsız): şovel taşıyan HER birime
	# uygulanmalı, yalnız New Antioch Combat Engineer'a değil (QA denetimi 2026-07-16'da Sultanate
	# Sapper'da eksik olduğu tespit edildi — aynı sapper_shovel.tres kaynağını paylaşıyorlar) ──
	t.eq(int(_kw("new_antioch_combat_engineer").get(&"dug_in", 0)), 1,
		"Combat Engineer (Şovel) → dug_in=1")
	t.eq(int(_kw("sultanate_sapper").get(&"dug_in", 0)), 1,
		"Sultanate Sapper (Şovel, 'this equipment can never be removed') → dug_in=1")
