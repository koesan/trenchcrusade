extends RefCounted

## Yerleştirme uygunluğunun TEK kaynağı. Hem `game.gd` doğrulaması hem yerleştirme kartı
## bu fonksiyonu kullanır — görsel ile kural asla çelişemez.
##
## Kullanıcı bildirimi: "bazı unitlere gelince 'bu faksiyona ait değil' / 'sınırlı ekleyemezsin'
## hatası veriyor" — sebep artık karta tıklamadan ÖNCE gösteriliyor.

func _counts(d: Dictionary = {}) -> Dictionary:
	var base := {"same_type": 0, "elite": 0, "lord": 0, "knight": 0,
		"demonic": 0, "court_wretched": 0, "leader_choice": &""}
	base.merge(d, true)
	return base

func run(t) -> void:
	var na: Resource = load("res://assets/data/factions/new_antioch.tres")
	var grail: Resource = load("res://assets/data/factions/cult_of_the_black_grail.tres")
	var yeoman: Resource = load("res://assets/data/units/new_antioch_yeoman.tres")     # 30 ducat
	var lieutenant: Resource = load("res://assets/data/units/new_antioch_lieutenant.tres")  # Elite, avail 1
	var observer: Resource = load("res://assets/data/units/observer.tres")             # 3 Glory
	var lord: Resource = load("res://assets/data/units/lord_of_tumours.tres")
	var knight: Resource = load("res://assets/data/units/plague_knight.tres")
	var trooper: Resource = load("res://assets/data/units/heretic_trooper.tres")

	# ── Normal durum ───────────────────────────────────────────────────────
	t.eq(DeployAvailability.check(yeoman, na, 700, 10, _counts()), "",
		"Yeoman + bol bütçe → alınabilir")
	t.eq(DeployAvailability.check(null, na, 700, 10, _counts()), "DEPLOY_FAIL_NO_FACTION",
		"null birim → reddedilir")
	t.eq(DeployAvailability.check(yeoman, null, 700, 10, _counts()), "DEPLOY_FAIL_NO_FACTION",
		"faksiyon yok → reddedilir")

	# ── Roster üyeliği ─────────────────────────────────────────────────────
	t.eq(DeployAvailability.check(trooper, na, 700, 10, _counts()), "DEPLOY_FAIL_WRONG_FACTION",
		"Heretic Trooper → New Antioch rosterinde değil")

	# ── Availability tavanı ────────────────────────────────────────────────
	t.eq(DeployAvailability.check(lieutenant, na, 700, 10, _counts({"same_type": 1})),
		"DEPLOY_FAIL_AVAILABILITY", "Lieutenant (Availability 1) → ikincisi reddedilir")
	t.eq(DeployAvailability.check(lieutenant, na, 700, 10, _counts()), "",
		"Lieutenant → İLKİ alınabilir")

	# ── Artillery Witch Battery (compendium Heretic Legion): diğer modeller 1000+ → 0-2 ─────
	var heretic: Resource = load("res://assets/data/factions/heretic_legion.tres")
	var witch: Resource = load("res://assets/data/units/artillery_witch.tres")
	t.eq(DeployAvailability.check(witch, heretic, 2000, 0, _counts({"same_type": 1, "other_cost": 900})),
		"DEPLOY_FAIL_AVAILABILITY", "Artillery Witch: diğerleri <1000 → ikincisi reddedilir")
	t.eq(DeployAvailability.check(witch, heretic, 2000, 0, _counts({"same_type": 1, "other_cost": 1000})),
		"", "Artillery Witch Battery: diğerleri 1000+ → ikincisi alınabilir")
	t.eq(DeployAvailability.check(witch, heretic, 2000, 0, _counts({"same_type": 2, "other_cost": 1500})),
		"DEPLOY_FAIL_AVAILABILITY", "Artillery Witch Battery: üçüncüsü yine reddedilir")

	# ── [Elite] tavanı (6) ─────────────────────────────────────────────────
	t.eq(DeployAvailability.check(lieutenant, na, 700, 10, _counts({"elite": 6})),
		"DEPLOY_FAIL_ELITE_CAP", "6 Elite varken 7.si reddedilir")
	t.eq(DeployAvailability.check(lieutenant, na, 700, 10, _counts({"elite": 5})), "",
		"5 Elite varken 6.sı alınabilir")

	# ── Bütçe (iki ayrı havuz) ─────────────────────────────────────────────
	t.eq(DeployAvailability.check(yeoman, na, 29, 10, _counts()), "DEPLOY_FAIL_BUDGET",
		"29 ducat → Yeoman (30) alınamaz")
	t.eq(DeployAvailability.check(observer, na, 700, 0, _counts()), "DEPLOY_FAIL_GLORY",
		"Glory 0 → Observer (3 Glory) alınamaz; ducat işe yaramaz")
	t.eq(DeployAvailability.check(observer, na, 0, 3, _counts()), "",
		"Glory 3 → Observer alınabilir (ducat 0 olsa bile)")

	# ── Order of the Fly ───────────────────────────────────────────────────
	# KULLANICI BİLDİRİMİ: "Tümör Lordu eklemeye çalışıyorum, ilk lordu ekleyeceğim,
	# 'sınırlı ekleyemezsin' diyor." Dal seçilmemişse veya Lord dalıysa İLK Lord alınabilir.
	t.eq(DeployAvailability.check(lord, grail, 700, 10, _counts()), "",
		"Dal seçilmemiş → İLK Lord of Tumours ALINABİLİR")
	t.eq(DeployAvailability.check(lord, grail, 700, 10, _counts({"leader_choice": &"lord"})), "",
		"Lord dalı → İLK Lord alınabilir")
	t.eq(DeployAvailability.check(lord, grail, 700, 10,
		_counts({"leader_choice": &"knight"})), "DEPLOY_FAIL_ORDER_OF_FLY",
		"Knight dalı seçilmişse Lord ALINAMAZ (compendium) — sebep artık kartta görünür")
	t.eq(DeployAvailability.check(knight, grail, 700, 10,
		_counts({"leader_choice": &"knight", "knight": 3})), "DEPLOY_FAIL_ORDER_OF_FLY",
		"Knight dalı → 4. Plague Knight reddedilir")
	t.eq(DeployAvailability.check(knight, grail, 700, 10,
		_counts({"leader_choice": &"knight", "knight": 2})), "",
		"Knight dalı → 3. Plague Knight alınabilir")

	# ── ALIGNMENT (Faithful / Fallen) ──────────────────────────────────────
	t.eq(AlignmentRules.of_faction(na), AlignmentRules.Alignment.FAITHFUL, "New Antioch → Faithful")
	t.eq(AlignmentRules.of_faction(grail), AlignmentRules.Alignment.FALLEN, "Black Grail → Fallen")
	var hl: Resource = load("res://assets/data/factions/heretic_legion.tres")
	var is_f: Resource = load("res://assets/data/factions/iron_sultanate.tres")
	t.eq(AlignmentRules.of_faction(hl), AlignmentRules.Alignment.FALLEN, "Heretic Legion → Fallen")
	t.eq(AlignmentRules.of_faction(is_f), AlignmentRules.Alignment.FAITHFUL, "Iron Sultanate → Faithful")

	var sin_eater: Resource = load("res://assets/data/units/sin_eater.tres")
	var scripture: Resource = load("res://assets/data/units/scripture_guardian.tres")
	t.eq(AlignmentRules.of_unit(observer), AlignmentRules.Alignment.FAITHFUL, "Observer → Faithful merc")
	t.eq(AlignmentRules.of_unit(sin_eater), AlignmentRules.Alignment.FALLEN, "Sin Eater → Fallen merc")
	# Scripture Guardian compendium'da HEM Sadık HEM Sapkın listelerinde ("holy (or desecrated)
	# scroll or tome it holds") → bilinçli olarak NÖTR bırakıldı.
	t.eq(AlignmentRules.of_unit(scripture), AlignmentRules.Alignment.UNSET,
		"Scripture Guardian → nötr (iki tarafa da hizmet eder)")

	t.eq(AlignmentRules.compatible(na, observer), true, "Faithful warband + Faithful merc → uyumlu")
	t.eq(AlignmentRules.compatible(na, sin_eater), false, "Faithful warband + Fallen merc → UYUMSUZ")
	t.eq(AlignmentRules.compatible(grail, sin_eater), true, "Fallen warband + Fallen merc → uyumlu")
	t.eq(AlignmentRules.compatible(na, scripture), true, "Nötr merc → her warband'a girer")
	t.eq(AlignmentRules.compatible(grail, scripture), true, "Nötr merc → Fallen warband'a da girer")

	for key in ["ALIGNMENT_FAITHFUL", "ALIGNMENT_FALLEN", "ALIGNMENT_NEUTRAL",
			"DEPLOY_FAIL_ALIGNMENT", "DEPLOY_CARD_HINT"]:
		t.ok(LocalizationManager.has_key(key), "%s localization'da var" % key)
	t.ok(DeployValidator.ALL_REASONS.has(DeployValidator.REASON_ALIGNMENT),
		"REASON_ALIGNMENT ALL_REASONS'ta kayıtlı")

	# Her ret sebebinin oyuncuya gösterilebilir bir metni olmalı
	for reason in DeployValidator.ALL_REASONS:
		t.ok(LocalizationManager.has_key(reason), "Ret sebebi localization'da: %s" % reason)
