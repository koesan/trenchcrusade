extends RefCounted

## YAKIN DÖVÜŞ KURALLARI (compendium denetimi, Adım 4): Defended Obstacle, Unarmed, Assault Beast,
## isteğe bağlı/hedefi seçilen Off-Hand, zincirde oyuncu hedef seçimi.

func run(t) -> void:
	# ── UNARMED ──────────────────────────────────────────────────────────────
	var sniper: Resource = load("res://assets/data/units/new_antioch_sniper_priest.tres")
	var armed: Resource = LoadoutResolver.with_unarmed(sniper)
	var has_unarmed := false
	for a in armed.attacks:
		if a != null and KeywordSystem.has(a, &"unarmed"):
			has_unarmed = true
			t.eq(a.dice_modifier, 0, "Unarmed cezasız (cezalı olan ayrı 'Weakly Unarmed')")
	t.ok(has_unarmed, "Yakın dövüş silahı olmayan Sniper Priest Unarmed dövüşebilir")
	t.ok(not sniper.attacks.any(func(a): return a != null and KeywordSystem.has(a, &"unarmed")),
		"Paylaşılan .tres değişmedi")
	var trooper: Resource = load("res://assets/data/units/heretic_trooper.tres")
	t.ok(LoadoutResolver.with_unarmed(trooper) == trooper, "Süngülü Trooper'a Unarmed eklenmez")
	var monk: Resource = load("res://assets/data/units/mendelist_ammo_monk.tres")
	t.ok(LoadoutResolver.with_unarmed(monk) == monk, "Ammo Monk 'has no weapons and therefore cannot attack'")
	# Silah alınınca Unarmed düşer
	var bought: Resource = ArmouryRules.apply(armed, load("res://assets/data/armoury/sword_axe.tres"))
	var after: Resource = LoadoutResolver.with_unarmed(bought)
	t.ok(not after.attacks.any(func(a): return a != null and KeywordSystem.has(a, &"unarmed")),
		"Kılıç alınınca Unarmed kalkar")
	t.eq(LoadoutResolver.get_offhand_pair(armed), [], "Unarmed asla Off-Hand olamaz")

	# ── ASSAULT BEAST ────────────────────────────────────────────────────────
	var wolf: Resource = load("res://assets/data/units/war_wolf_assault_beast.tres")
	var mouth: Resource = load("res://assets/data/attacks/chainsaw_mouth.tres")
	var claws: Resource = load("res://assets/data/attacks/shredding_claws.tres")
	t.eq(LoadoutResolver.offhand_for(wolf, mouth), claws, "Assault Beast: Chainsaw Mouth'tan sonra Shredding Claws Off-Hand")
	t.eq(LoadoutResolver.offhand_for(wolf, claws), null, "Assault Beast: önce pençeyle vurursa ikinci saldırı yok")

	# ── DEFENDED OBSTACLE ────────────────────────────────────────────────────
	var src := FileAccess.get_file_as_string("res://scripts/rules/dice_pool_builder.gd")
	t.ok(src.contains("if is_melee and ctx[\"in_cover\"]:") and src.contains("MOD_DEFENDED_OBSTACLE"),
		"Siperdeki hedefe yakın dövüşte -1 Dice (Defended Obstacle)")

	# ── OFF-HAND isteğe bağlı + hedef seçimi; zincirde seçim ─────────────────
	var af := FileAccess.get_file_as_string("res://scripts/unit/attack_flow.gd")
	t.ok(af.contains("\"OFFHAND_PICK\", true)"), "Off-Hand isteğe bağlı ve hedefi oyuncu seçer")
	var ch := FileAccess.get_file_as_string("res://scripts/unit/unit_attack_chains.gd")
	t.ok(ch.contains("\"CLEAVE_PICK\"") and ch.contains("\"AUTOMATIC_PICK\""), "Cleave/Automatic hedefini oyuncu seçer")
	t.ok(ch.contains("block_penalty(unit, target, is_melee)"), "Zincir atışlarında Block uygulanır")
	t.ok(ch.contains("crit_threshold(atk, target, is_melee)"), "Zincir atışlarında Pain Amplifier kritik eşiği uygulanır")
