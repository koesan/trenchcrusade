extends RefCounted

## Compendium (warbands/starting-a-warband/recruit-your-warband.md):
##   "Mercenaries DO NOT BENEFIT from the Faction Special Rules of your Warband, SUCH AS THE
##    NEW ANTIOCH CONCENTRATED ATTACK RULE."
##
## Fireteam eşleştirmesi bu yüzden OYUNCUNUN faksiyonuna değil, BİRİMİN `[New Antioch]`
## keyword'üne bakmalıdır. Önceki uygulama oyuncunun faksiyonuna bakıyor ve mercenary'leri de
## eşleştiriyordu — compendium'un İSMEN yasakladığı şey (denetim bulgusu P0-NA-4).

func run(t) -> void:
	var yeoman: Resource = load("res://assets/data/units/new_antioch_yeoman.tres")
	var lieutenant: Resource = load("res://assets/data/units/new_antioch_lieutenant.tres")
	var observer: Resource = load("res://assets/data/units/observer.tres")
	var witchburner: Resource = load("res://assets/data/units/witchburner.tres")
	var scripture: Resource = load("res://assets/data/units/scripture_guardian.tres")
	var mamluk: Resource = load("res://assets/data/units/mamluk_faris.tres")

	# ── Fireteam uygunluğu ─────────────────────────────────────────────────
	t.eq(FactionRules.is_fireteam_eligible(yeoman), true,
		"Yeoman ([New Antioch]) → Fireteam'e uygun")
	t.eq(FactionRules.is_fireteam_eligible(lieutenant), true,
		"Lieutenant ([New Antioch]) → Fireteam'e uygun")
	t.eq(FactionRules.is_fireteam_eligible(observer), false,
		"Observer (mercenary) → Fireteam'e UYGUN DEĞİL")
	t.eq(FactionRules.is_fireteam_eligible(witchburner), false,
		"Witchburner (mercenary) → Fireteam'e UYGUN DEĞİL")
	t.eq(FactionRules.is_fireteam_eligible(scripture), false,
		"Scripture Guardian (mercenary) → Fireteam'e UYGUN DEĞİL")
	t.eq(FactionRules.is_fireteam_eligible(mamluk), false,
		"Mamluk Faris (mercenary) → Fireteam'e UYGUN DEĞİL")
	t.eq(FactionRules.is_fireteam_eligible(null), false, "null → uygun değil")

	# ── Concentrated Attack ────────────────────────────────────────────────
	t.eq(FactionRules.can_use_concentrated_attack(yeoman), true,
		"Yeoman → Concentrated Attack kullanabilir")
	t.eq(FactionRules.can_use_concentrated_attack(observer), false,
		"Observer → Concentrated Attack KULLANAMAZ (compendium ismen yasaklıyor)")
	t.eq(FactionRules.can_use_concentrated_attack(witchburner), false,
		"Witchburner → Concentrated Attack KULLANAMAZ")

	# ── Başka faksiyonun birimi de uygun olmamalı ─────────────────────────
	var trooper: Resource = load("res://assets/data/units/heretic_trooper.tres")
	t.eq(FactionRules.is_fireteam_eligible(trooper), false,
		"Heretic Trooper → New Antioch Fireteam'ine uygun değil")

	# ── New Antioch roster'ındaki HER çekirdek birim uygun olmalı ─────────
	var na: Resource = load("res://assets/data/factions/new_antioch.tres")
	var core_eligible := 0
	var merc_ineligible := 0
	for u in na.available_units:
		if u == null:
			continue
		if KeywordSystem.has(u, &"new_antioch"):
			t.ok(FactionRules.is_fireteam_eligible(u), "%s → Fireteam'e uygun" % u.unit_name)
			core_eligible += 1
		else:
			t.ok(not FactionRules.is_fireteam_eligible(u),
				"%s (mercenary) → Fireteam'e uygun DEĞİL" % u.unit_name)
			merc_ineligible += 1
	t.eq(core_eligible, 8, "New Antioch → 8 çekirdek birim Fireteam'e uygun")
	t.eq(merc_ineligible, 7, "New Antioch → 7 mercenary Fireteam'e uygun değil")
