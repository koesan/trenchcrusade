extends RefCounted

## Yetenek `.tres` parametreleri compendium metniyle BİREBİR eşleşmeli
## (denetim bulguları P1-NA-7 Treat, P1-NA-8 Hold Your Fire!, P1-TP-4 Loudspeakers).

func run(t) -> void:
	# ── TREAT (Medi-Kit) — battlekit/equipment.md + new-antioch.md Combat Medic ──
	#   "take a [Risky Success] Roll... If the roll is a Failure, the model's Activation ENDS
	#    IMMEDIATELY. If Success: you can do ONE OF THE FOLLOWING:
	#      - Remove [1 Blood Marker] from the model or a friendly model within 1"
	#      - Stand up a friendly model that is Down and within 1""
	var treat: Resource = load("res://assets/data/abilities/treat.tres")
	t.eq(treat.is_risky, true, "Treat → Risky (başarısızlıkta aktivasyon biter)")
	t.approx(treat.range_meters, 1.0, "Treat menzili 1\" (eski 2.0 yanlıştı)")
	t.eq(treat.effect_type, "treat_choice",
		"Treat → oyuncuya SEÇİM sunar (Blood Marker kaldır VEYA ayağa kaldır)")
	t.ok(treat.requires_roll, "Treat → zar gerektirir")

	# Seçim metinleri iki dilde olmalı
	for key in ["TREAT_CHOICE_TITLE", "TREAT_CHOICE_INFO", "TREAT_CHOICE_REMOVE_BLOOD",
			"TREAT_CHOICE_STAND_UP", "TREAT_FAIL_GLUTTONY"]:
		t.ok(LocalizationManager.has_key(key), "%s localization'da var" % key)

	# ── HOLD YOUR FIRE! — new-antioch.md ──────────────────────────────────
	#   "pick 1 enemy model that is IN THE LIEUTENANT'S LINE OF SIGHT and that the opponent
	#    is allowed to Activate." → MENZİL SINIRI YOKTUR.
	var hyf: Resource = load("res://assets/data/abilities/hold_your_fire.tres")
	t.approx(hyf.range_meters, 0.0,
		"Hold Your Fire! → menzil sınırı YOK (kısıt yalnız Line of Sight)")
	t.eq(hyf.requires_roll, false, "Hold Your Fire! → zar gerektirmez")
	t.eq(hyf.effect_type, "force_activation", "Hold Your Fire! → force_activation")
	t.eq(hyf.target_type, "enemy", "Hold Your Fire! → düşman hedefler")
	t.ok(LocalizationManager.has_key("HOLD_YOUR_FIRE_FAIL_LOS"),
		"HOLD_YOUR_FIRE_FAIL_LOS localization'da var")

	# ── LOUDSPEAKERS — trench-pilgrims.md War Prophet ─────────────────────
	#   "take a [Risky Success] Roll and add [+2 Dice]... you can move all friendly models
	#    within 8" of the War Prophet UP TO 3"... This move can be used to bring a model within
	#    1" of an enemy model IN WHICH CASE THE MODEL COUNTS AS CHARGING."
	var ls: Resource = load("res://assets/data/abilities/loudspeakers.tres")
	t.approx(ls.range_meters, 8.0, "Loudspeakers → 8\" aura")
	t.eq(ls.is_risky, true, "Loudspeakers → Risky")
	t.eq(ls.dice_modifier, 2, "Loudspeakers → +2 Dice")
	t.eq(ls.effect_amount, 3, "Loudspeakers → 3\" hareket (compendium 'up to 3\"')")
	t.eq(ls.effect_type, "move_allies", "Loudspeakers → move_allies")

	# ── Yeteneği taşıyan birimler doğru mu? ───────────────────────────────
	var prophet: Resource = load("res://assets/data/units/war_prophet.tres")
	var p_ids: Array = []
	for ab in prophet.abilities:
		if ab != null:
			p_ids.append(ab.ability_id)
	t.ok(p_ids.has(&"loudspeakers"), "War Prophet → Loudspeakers")

	var lt: Resource = load("res://assets/data/units/new_antioch_lieutenant.tres")
	var l_ids: Array = []
	for ab in lt.abilities:
		if ab != null:
			l_ids.append(ab.ability_id)
	t.ok(l_ids.has(&"hold_your_fire"), "Lieutenant → Hold Your Fire!")

	# Medi-Kit taşıyan birimlerin hepsi Treat'i AYNI (düzeltilmiş) .tres'ten alır
	for name in ["new_antioch_combat_medic", "combat_medic", "observer"]:
		var ud: Resource = load("res://assets/data/units/%s.tres" % name)
		if ud == null:
			continue
		for ab in ud.abilities:
			if ab != null and ab.ability_id == &"treat":
				t.eq(ab.is_risky, true, "%s → Treat Risky" % name)
				t.eq(ab.effect_type, "treat_choice", "%s → Treat seçim sunar" % name)
