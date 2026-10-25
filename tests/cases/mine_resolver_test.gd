extends RefCounted

## Mayın kuralları — SAF fonksiyonlar (sahne kurmadan test edilir).
## Kaynak: iron-sultanate.md (Sultanate Sapper) + new-antioch.md (Combat Engineer);
## iki faksiyonda da kural metni AYNIdır.

const UnitData = preload("res://scripts/data/unit_data.gd")

func _ud(kw: Dictionary) -> Resource:
	var u := UnitData.new()
	u.keywords = kw
	return u

func run(t) -> void:
	# ── Eşik ve bonus ──────────────────────────────────────────────────────
	# "take a Success Roll for the model and add [+2 Dice] to the roll"
	# Standart Success Roll eşiği 7'dir; eskiden set_mine.tres'te uydurma 5 vardı.
	t.eq(MineResolver.set_mine_threshold(), 7, "Set Mine eşiği 7+ (standart Success Roll)")
	t.eq(MineResolver.set_mine_bonus_dice(), 2, "Set Mine → +2 Dice")

	var sapper := _ud({&"negate_mined": 1})
	var trooper := _ud({})
	var flyer := _ud({&"flying": 1})

	# ── Mayın kurma ────────────────────────────────────────────────────────
	t.eq(MineResolver.can_set_mine(sapper, false), true, "Mayınsız araziye kurulabilir")
	t.eq(MineResolver.can_set_mine(sapper, true), false,
		"Zaten [Mined] araziye ikinci mayın kurulamaz")
	t.eq(MineResolver.can_set_mine(null, false), false, "null birim kuramaz")

	# ── Patlama ────────────────────────────────────────────────────────────
	# "the mine will detonate UNLESS the model is the one that set the mine, or has the
	#  Defuse Mine ability"
	t.eq(MineResolver.detonates_for(trooper, "Sapper1", "Trooper3"), true,
		"Sıradan model mayına basınca PATLAR")
	t.eq(MineResolver.detonates_for(sapper, "Sapper1", "Sapper2"), false,
		"[Negate Mined] taşıyan model patlatmaz (Defuse Mine yeteneği var)")
	t.eq(MineResolver.detonates_for(trooper, "Trooper3", "Trooper3"), false,
		"Mayını KURAN model kendi mayınını patlatmaz")

	# ── Etkisizleştirme ────────────────────────────────────────────────────
	t.eq(MineResolver.can_defuse(sapper), true, "[Negate Mined] → Defuse Mine yapabilir")
	t.eq(MineResolver.can_defuse(trooper), false, "Sıradan model Defuse Mine yapamaz")
	t.eq(MineResolver.defuse_is_automatic("Sapper1", "Sapper1"), true,
		"Kendi kurduğu mayını OTOMATİK etkisizleştirir (zar atılmaz)")
	t.eq(MineResolver.defuse_is_automatic("Sapper1", "Sapper2"), false,
		"Başkasının mayını için Risky Success Roll gerekir")
	t.eq(MineResolver.defuse_is_automatic("", "Sapper1"), false,
		"Kurucu bilinmiyorsa otomatik değil")

	# ── FLYING istisnası ───────────────────────────────────────────────────
	# "FLYING models only detonate a mine if they FINISH a move in contact with a Mined
	#  terrain piece (they can fly across it without setting it off)."
	t.eq(MineResolver.flying_triggers(flyer, false), false,
		"Uçan model mayının ÜZERİNDEN geçerken patlatmaz")
	t.eq(MineResolver.flying_triggers(flyer, true), true,
		"Uçan model hareketini mayının üzerinde BİTİRİRSE patlatır")
	t.eq(MineResolver.flying_triggers(trooper, false), true,
		"Yaya model hareketin ortasında da patlatır")

	# ── Mayın kurabilen birimler compendium'a göre doğru mu? ───────────────
	for name in ["sultanate_sapper", "new_antioch_combat_engineer"]:
		var ud: Resource = load("res://assets/data/units/%s.tres" % name)
		t.ok(ud != null, "%s yüklendi" % name)
		if ud == null:
			continue
		t.ok(KeywordSystem.has(ud, &"negate_mined"), "%s → [Negate Mined]" % name)
		t.eq(MineResolver.can_defuse(ud), true, "%s → Defuse Mine yapabilir" % name)
	# Sıradan bir asker yapamamalı
	var yeoman: Resource = load("res://assets/data/units/new_antioch_yeoman.tres")
	t.eq(MineResolver.can_defuse(yeoman), false, "Yeoman → Defuse Mine yapamaz")
