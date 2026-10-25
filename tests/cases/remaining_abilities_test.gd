extends RefCounted

## Denetimde tespit edilen kalan eksik yetenekler
## (P1-HL-5, P2-NA-15b, P1-IS-4a, P2-HL-9c).

func run(t) -> void:
	# ── WAR WOLF: [Negate Difficult Terrain] ───────────────────────────────
	# heretic-legion.md: "This abomination charges through miles of barbed wire, clearing a
	# path for the Heretic infantry." — 145 ducat'lık birimin lore'unun tek mekanik ifadesi.
	var ww: Resource = load("res://assets/data/units/war_wolf_assault_beast.tres")
	t.ok(KeywordSystem.has(ww, &"negate_difficult_terrain"), "War Wolf → keyword mevcut")
	t.eq(MechanicsResolver.ignores_difficult_terrain(ww), true,
		"War Wolf → zorlu araziyi yok sayar (kural artık OKUNUYOR)")
	var yeoman: Resource = load("res://assets/data/units/new_antioch_yeoman.tres")
	t.eq(MechanicsResolver.ignores_difficult_terrain(yeoman), false,
		"Yeoman → zorlu araziden etkilenir")

	# Arazi sorgusuyla birlikte
	TerrainManager.clear_all()
	t.eq(MechanicsResolver.suffers_difficult_terrain(yeoman, Vector3.ZERO), false,
		"Zorlu arazi yokken ceza yok")
	t.eq(MechanicsResolver.suffers_difficult_terrain(ww, Vector3.ZERO), false,
		"War Wolf hiçbir durumda ceza almaz")
	TerrainManager.clear_all()

	# ── BALLISTIC BOX ARMOUR — yalnız Engineer Body Armour'a özel ─────────
	# new-antioch.md: "Add [-1 Injury Dice] ... for a model that has ENGINEER BODY ARMOUR that
	# has been hit by an attack with the [Shrapnel] Keyword even if the attacking weapon has
	# the [Ignore Armour] Keyword."
	# Eskiden `negate_shrapnel` ile eşleşiyordu — o keyword'ü Combat Helmet taşıyan HER birim
	# alır, yani kural fazla geniş uygulanıyordu (denetim bulgusu P2-NA-15b).
	var eng: Resource = load("res://assets/data/units/new_antioch_combat_engineer.tres")
	t.ok(KeywordSystem.has(eng, &"ballistic_box_armour"),
		"Combat Engineer → [ballistic_box_armour]")
	# Combat Helmet taşıyan ama Engineer OLMAYAN birimler bu bonusu ALMAMALI
	for name in ["mamluk_faris", "scripture_guardian", "witchburner", "sin_eater"]:
		var ud: Resource = load("res://assets/data/units/%s.tres" % name)
		if ud == null:
			continue
		t.ok(KeywordSystem.has(ud, &"negate_shrapnel"),
			"%s → Combat Helmet'ten [Negate Shrapnel]" % name)
		t.ok(not KeywordSystem.has(ud, &"ballistic_box_armour"),
			"%s → Ballistic Box Armour bonusunu ALMAZ (Engineer'a özel)" % name)

	# ── MASTERY OF THE ELEMENTS — oyuncu seçimi ───────────────────────────
	# iron-sultanate.md: "you can give ONE OF THE FOLLOWING Keywords to all of the Jabirean
	# Alchemist's Weapons: [Fire] or [Gas] or [Shrapnel]." Seçim oyuncunundur.
	var alch: Resource = load("res://assets/data/units/jabirean_alchemist.tres")
	t.ok(KeywordSystem.has(alch, &"mastery_of_elements"), "Alchemist → mastery keyword'ü")
	var choices: Array = MechanicsResolver.mastery_element_choices()
	t.eq(choices.size(), 3, "Mastery → üç element seçeneği")
	t.ok(choices.has(&"fire"), "Mastery → Fire seçeneği")
	t.ok(choices.has(&"gas"), "Mastery → Gas seçeneği")
	t.ok(choices.has(&"shrapnel"), "Mastery → Shrapnel seçeneği")
	for key in ["ELEMENT_CHOICE_TITLE", "ELEMENT_CHOICE_INFO", "ELEMENT_FIRE",
			"ELEMENT_GAS", "ELEMENT_SHRAPNEL"]:
		t.ok(LocalizationManager.has_key(key), "%s localization'da var" % key)

	# ── MARTIAL PROWESS (Mamluk Faris) — Greatsword'den [Heavy] kalkar ────
	# iron-sultanate.md: "The Mamluk's Greatsword does not have the HEAVY Keyword."
	var gs: Resource = load("res://assets/data/attacks/mamluk_greatsword.tres")
	t.ok(gs != null, "mamluk_greatsword.tres mevcut")
	if gs != null:
		t.ok(not KeywordSystem.has(gs, &"heavy"),
			"Mamluk Greatsword → [Heavy] taşımıyor (Martial Prowess)")
	# Karşılaştırma: standart Greatsword/Axe [Heavy] taşır
	var std_gs: Resource = load("res://assets/data/attacks/greatsword_axe.tres")
	t.ok(KeywordSystem.has(std_gs, &"heavy"), "Standart Greatsword/Axe → [Heavy] taşır")
