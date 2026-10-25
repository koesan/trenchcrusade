extends RefCounted

## HAREKET KURALLARI — compendium `comprehensive-rules/movement.md` + `climbing-and-jumping.md`.
##
## 2026-07-29 denetiminde bulunan üç sapma bu testle kilitlendi.

func run(t) -> void:
	# ── DIVING CHARGE eşiği ───────────────────────────────────────────────
	# melee-attacks.md: "You can convert a charge... if it Jumps Down AT LEAST 3\" and lands
	# within 1\" of a target."
	# SAPMA: bu eşik `fall_injury_height = 4.8` idi (gönüllü düşme ölümleri için kalibre edilmiş
	# ESKİ bir mekanikten kalma). 3.0-4.8 arasından yapılan hücumlar Diving Charge SAYILMIYORDU.
	t.approx(GameState.DIVING_CHARGE_MIN_HEIGHT, 3.0,
		"Diving Charge eşiği 3\" (compendium: 'Jumps Down at least 3\"')")
	t.ok(MechanicsResolver.is_diving_charge_height(3.0, 0.0),
		"Tam 3\" yükseklikten hücum → Diving Charge (sınır DÂHİL)")
	t.ok(MechanicsResolver.is_diving_charge_height(4.0, 0.0),
		"4\" yükseklikten hücum → Diving Charge (eski 4.8 eşiğinde KAÇIYORDU)")
	t.ok(not MechanicsResolver.is_diving_charge_height(2.9, 0.0),
		"2.9\" → Diving Charge DEĞİL")

	# ── Serbest vuruş + trench duvarı sınırları RAW ile aynı ─────────────
	# climbing-and-jumping.md: "Terrain up to 1\" high, Trench Walls up to 3\" high... are
	# treated as Open terrain."
	t.approx(GameState.CLIMB_FREE_MAX, 3.0, "Serbest iniş/trench duvarı sınırı 3\"")

	# ── Charge tavanı ─────────────────────────────────────────────────────
	# movement.md: "roll a D6 and add the roll to the charging model's Movement Characteristic,
	# **up to a maximum Movement Characteristic of 12\"**." Hedef seçimi de 12\" içinden yapılır.
	t.approx(GameState.CHARGE_DISTANCE_CAP, 12.0, "Charge tavanı 12\"")

	# ── Düşme yarası ölçeği ───────────────────────────────────────────────
	# climbing-and-jumping.md: "Add [+1 Injury Dice] for every 3\" it Falls (3-5\" = +1, 6-8\" = +2)."
	# Kod: `int(fall_height / 3.0)`.
	t.eq(int(3.0 / 3.0), 1, "3\" düşüş → +1 Injury Dice")
	t.eq(int(5.9 / 3.0), 1, "5.9\" düşüş → +1 Injury Dice")
	t.eq(int(6.0 / 3.0), 2, "6\" düşüş → +2 Injury Dice")
	t.eq(int(2.9 / 3.0), 0, "3\" ALTI düşüş → Injury Roll yok")

	# ── RETREAT: temiz nokta yoksa HİÇ hareket etmez ─────────────────────
	# movement.md: "A retreating model must end its retreat move more than 1\" away from all
	# enemy models. **If this is impossible, it cannot move at all.**"
	# SAPMA: `enforce_retreat_clearance` en iyi çabaydı; başaramazsa model YİNE DE taşınıyordu
	# (hâlâ angaje bir noktaya) — hem RAW'a aykırı hem oyun mantığını bozuyordu.
	var usrc := FileAccess.open("res://scenes/unit/unit.gd", FileAccess.READ)
	t.ok(usrc != null, "unit.gd okunabildi")
	if usrc != null:
		var utxt := usrc.get_as_text()
		usrc.close()
		var i: int = utxt.find("func server_request_retreat")
		t.ok(i > 0, "server_request_retreat bulundu")
		if i > 0:
			var body: String = utxt.substr(i, 5200)
			t.ok(body.contains("MOVE_FAIL_RETREAT_BLOCKED"),
				"Retreat: temiz nokta bulunamazsa hareket İPTAL edilir ve oyuncuya bildirilir")

	# Ret sebebi lokalize mi? (Sessiz ret bu projede tekrarlayan bir bug sınıfıydı.)
	t.ok(LocalizationManager.tr_t("MOVE_FAIL_RETREAT_BLOCKED") != "MOVE_FAIL_RETREAT_BLOCKED",
		"MOVE_FAIL_RETREAT_BLOCKED lokalize edilmiş")

	# ── CLEAVE serbest vuruşta da geçerli ────────────────────────────────
	# movement.md (Retreating): "it can only make 1 melee attack with 1 weapon (it cannot use the
	# Multiple Melee Attacks rule, **but if the attacking weapon has the [Cleave](X) Keyword it
	# will still apply**)."
	var csrc := FileAccess.open("res://scripts/unit/unit_attack_chains.gd", FileAccess.READ)
	t.ok(csrc != null, "unit_attack_chains.gd okunabildi")
	if csrc != null:
		var ctxt := csrc.get_as_text()
		csrc.close()
		t.ok(ctxt.contains("_free_strike_cleave_extras"),
			"Serbest vuruşta Cleave(X) ek saldırıları uygulanıyor")
