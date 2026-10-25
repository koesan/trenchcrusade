extends RefCounted

## Warband inşa kuralları — SAF fonksiyonlar (sahne kurmadan test edilir).
##
## KAYNAKLAR:
##  - recruit-your-warband.md: "A Warband can never include more than 6 models with the
##    [Elite] Keyword. This limit applies at all times."
##  - cult-of-the-black-grail.md "The Order of the Fly"
##  - court-of-the-seven-headed-serpent.md "Nobles of the Court"

func run(t) -> void:
	# ── Elite tavanı: 6 ────────────────────────────────────────────────────
	t.eq(RosterRules.ELITE_MAX, 6, "Elite tavanı 6 (compendium)")
	t.eq(RosterRules.elite_cap_ok(0), true,  "0 Elite → izinli")
	t.eq(RosterRules.elite_cap_ok(6), true,  "6 Elite → izinli (tavan DAHİL)")
	t.eq(RosterRules.elite_cap_ok(7), false, "7 Elite → REDDEDİLİR")

	# ── Order of the Fly (Cult of the Black Grail) ─────────────────────────
	# "Lord of Tumours: up to ONE Lord of Tumours and up to TWO Plague Knights."
	t.eq(RosterRules.order_of_the_fly_allowed(&"lord", 1, 0), true,  "Lord dalı: 1 Lord")
	t.eq(RosterRules.order_of_the_fly_allowed(&"lord", 1, 2), true,  "Lord dalı: 1 Lord + 2 Knight")
	t.eq(RosterRules.order_of_the_fly_allowed(&"lord", 1, 3), false, "Lord dalı: 3 Knight REDDEDİLİR")
	t.eq(RosterRules.order_of_the_fly_allowed(&"lord", 2, 0), false, "Lord dalı: 2 Lord REDDEDİLİR")
	# "Plague Knight: must include a Plague Knight and may include up to THREE."
	t.eq(RosterRules.order_of_the_fly_allowed(&"knight", 0, 3), true,  "Knight dalı: 3 Knight")
	t.eq(RosterRules.order_of_the_fly_allowed(&"knight", 0, 4), false, "Knight dalı: 4 Knight REDDEDİLİR")
	t.eq(RosterRules.order_of_the_fly_allowed(&"knight", 1, 1), false, "Knight dalı: Lord alınamaz")
	t.eq(RosterRules.order_of_the_fly_allowed(&"", 1, 3), true, "Dal seçilmemiş → limit uygulanmaz")

	# ── Nobles of the Court ────────────────────────────────────────────────
	t.eq(RosterRules.nobles_of_the_court_satisfied(1, 0), true,  "1 Praetor → hazır")
	t.eq(RosterRules.nobles_of_the_court_satisfied(0, 1), true,  "1 Sorcerer → hazır")
	t.eq(RosterRules.nobles_of_the_court_satisfied(1, 1), true,  "1 Praetor + 1 Sorcerer → hazır")
	t.eq(RosterRules.nobles_of_the_court_satisfied(0, 0), false, "Lidersiz → HAZIR DEĞİL")

	# ── warband_ready: yerleşimi bitirme ön koşulu ─────────────────────────
	t.eq(RosterRules.warband_ready(&"court_of_seven_headed_serpent",
		{"praetor": 0, "sorcerer": 0}), "ROSTER_FAIL_NOBLES_OF_THE_COURT",
		"Court lidersiz → yerleşim bitirilemez")
	t.eq(RosterRules.warband_ready(&"court_of_seven_headed_serpent",
		{"praetor": 1, "sorcerer": 0}), "", "Court Praetor ile → hazır")
	t.eq(RosterRules.warband_ready(&"court_of_seven_headed_serpent",
		{"praetor": 0, "sorcerer": 1}), "", "Court Sorcerer ile → hazır")
	t.eq(RosterRules.warband_ready(&"cult_of_the_black_grail",
		{"leader_choice": &"lord", "lord": 0, "knight": 2}), "ROSTER_FAIL_ORDER_OF_THE_FLY",
		"Grail Lord dalı ama Lord yok → yerleşim bitirilemez")
	t.eq(RosterRules.warband_ready(&"cult_of_the_black_grail",
		{"leader_choice": &"lord", "lord": 1, "knight": 0}), "", "Grail Lord dalı, 1 Lord → hazır")
	t.eq(RosterRules.warband_ready(&"cult_of_the_black_grail",
		{"leader_choice": &"knight", "lord": 0, "knight": 1}), "", "Grail Knight dalı, 1 Knight → hazır")
	t.eq(RosterRules.warband_ready(&"cult_of_the_black_grail",
		{"leader_choice": &"knight", "lord": 0, "knight": 0}), "ROSTER_FAIL_ORDER_OF_THE_FLY",
		"Grail Knight dalı ama Knight yok → yerleşim bitirilemez")
	# Lider dışında ek kuralı olmayan faksiyonlar: lider varsa hazır (Availability: 1 — Adım 3).
	t.eq(RosterRules.warband_ready(&"new_antioch", {"leader": 1}), "",
		"New Antioch Lieutenant'lı → hazır")
	t.eq(RosterRules.warband_ready(&"heretic_legion", {"leader": 1}), "", "Heretic Legion Priest'li → hazır")

	# ── Lokalizasyon anahtarları iki dilde de bulunmalı ────────────────────
	for key in ["ROSTER_FAIL_NOBLES_OF_THE_COURT", "ROSTER_FAIL_ORDER_OF_THE_FLY",
			"DEPLOY_FAIL_ELITE_CAP", "DEPLOY_FAIL_ORDER_OF_FLY"]:
		t.ok(LocalizationManager.has_key(key), "%s localization'da var" % key)

	# ── DeployValidator ret sebepleri kayıtlı olmalı ───────────────────────
	t.ok(DeployValidator.ALL_REASONS.has(DeployValidator.REASON_ELITE_CAP),
		"REASON_ELITE_CAP ALL_REASONS'ta kayıtlı")
	t.ok(DeployValidator.ALL_REASONS.has(DeployValidator.REASON_ORDER_OF_FLY),
		"REASON_ORDER_OF_FLY ALL_REASONS'ta kayıtlı")

	# ── FactionData.leader_choice alanı (Order of the Fly seçimi) ──────────
	var grail: Resource = load("res://assets/data/factions/cult_of_the_black_grail.tres")
	t.ok("leader_choice" in grail, "FactionData → leader_choice alanı var")
	t.ok(FactionData.LEADER_CHOICES.has(&"lord"), "LEADER_CHOICES → lord")
	t.ok(FactionData.LEADER_CHOICES.has(&"knight"), "LEADER_CHOICES → knight")
	for cid in FactionData.LEADER_CHOICES.keys():
		var cd: Dictionary = FactionData.LEADER_CHOICES[cid]
		t.ok(LocalizationManager.has_key(cd["display_name"]),
			"LEADER_CHOICES[%s].display_name localization'da var" % cid)
		t.ok(LocalizationManager.has_key(cd["desc"]),
			"LEADER_CHOICES[%s].desc localization'da var" % cid)

	# ── Plague Knight availability üst sınırı 3 olmalı (Knight dalı için) ──
	var pk: Resource = load("res://assets/data/units/plague_knight.tres")
	t.eq(pk.availability_max, 3,
		"Plague Knight availability_max=3 (Knight dalı 3'e izin verir; gerçek sınır RosterRules'ta)")
