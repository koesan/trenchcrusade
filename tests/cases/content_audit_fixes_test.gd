extends RefCounted

## 2026-07-16 kapsamlı compendium denetimi (6 fork ile faction-by-faction karşılaştırma) sonucunda
## bulunan/düzeltilen gerçek boşlukların SAF mantık + statik veri düzeyinde kilidi.

const MechanicsResolver = preload("res://scripts/rules/mechanics_resolver.gd")
const KeywordSystem = preload("res://scripts/rules/keyword_system.gd")
const UnitData = preload("res://scripts/data/unit_data.gd")

func _kw(path: String) -> Dictionary:
	var ud = load("res://assets/data/units/" + path + ".tres")
	if ud == null:
		return {}
	return ud.keywords

func run(t) -> void:
	_test_heretic_legionnaire_ratio_predicate(t)
	_test_data_fixes(t)

## HERETIC LEGIONNAIRE (Heretic Legion): "cannot upgrade a Heretic Trooper if doing so would
## result in more Legionnaires than Troopers" — terfi edilmemiş sayı terfi SONRASI Legionnaire
## sayısından az olamaz.
func _test_heretic_legionnaire_ratio_predicate(t) -> void:
	t.ok(MechanicsResolver.heretic_legionnaire_upgrade_allowed(2, 2), "2 Trooper, 2 Legionnaire (eşit) → izinli")
	t.ok(MechanicsResolver.heretic_legionnaire_upgrade_allowed(3, 2), "3 Trooper, 2 Legionnaire → izinli")
	t.ok(not MechanicsResolver.heretic_legionnaire_upgrade_allowed(1, 2), "1 Trooper, 2 Legionnaire → reddedilir")
	t.ok(not MechanicsResolver.heretic_legionnaire_upgrade_allowed(0, 1), "0 Trooper, 1 Legionnaire → reddedilir")
	t.ok(MechanicsResolver.heretic_legionnaire_upgrade_allowed(0, 0), "0 Trooper, 0 Legionnaire → izinli (terfi yok)")

	# Loadout verisi: iki Legionnaire seçeneği ortak &"legionnaire_upgrade" işaretini taşımalı,
	# Standard seçenek taşımamalı (game.gd'nin deploy-zamanı sayımı buna dayanıyor).
	var ud = load("res://assets/data/units/heretic_trooper.tres")
	var opts: Array = ud.loadout_options
	t.ok(opts.size() >= 3,
		"Heretic Trooper → en az 3 loadout (Standard + 2 Legionnaire; Armoury seçenekleri eklenebilir)")
	t.ok(not opts[0].extra_keywords.has(&"legionnaire_upgrade"), "Standard loadout → legionnaire_upgrade YOK")
	t.ok(opts[1].extra_keywords.get(&"legionnaire_upgrade", 0) == 1, "Legionnaire (Ranged) loadout → legionnaire_upgrade VAR")
	t.ok(opts[2].extra_keywords.get(&"legionnaire_upgrade", 0) == 1, "Legionnaire (Melee) loadout → legionnaire_upgrade VAR")

## Fork denetiminde bulunan tek-satırlık/statik veri düzeltmeleri.
func _test_data_fixes(t) -> void:
	# New Antioch — Combat Engineer: Engineer Body Armour [Negate Shrapnel] eksikti.
	t.eq(int(_kw("new_antioch_combat_engineer").get(&"negate_shrapnel", 0)), 1,
		"Combat Engineer → negate_shrapnel=1 (Engineer Body Armour)")

	# Court — Yoke Fiend: Slavemaster'ın Shoot Command'ı için Ranged silahı yoktu (yapısal olarak
	# HİÇBİR Yoke Fiend'in Shoot Command'ı çalışamıyordu).
	var yoke_ud = load("res://assets/data/units/court_yoke_fiend.tres")
	t.ok(MechanicsResolver.first_ranged_attack(yoke_ud) != null,
		"Yoke Fiend → artık bir Ranged silahı var (Shoot Command çalışabilir)")

	# Cult of the Black Grail — Plague Knight: compendium'a göre warband lideri olabilir
	# ("Plague-Knight-led" seçeneği), is_leader=false yanlıştı.
	var pk_ud = load("res://assets/data/units/plague_knight.tres")
	t.ok(pk_ud.is_leader, "Plague Knight → is_leader=true (Order of the Fly liderlik seçeneği)")

	# Cult of the Black Grail — Amalgam: Six-Armed Monstrosity'nin (annihilator keyword, 1 Fight/
	# silah) anlamlı olması için birden fazla silaha ihtiyacı var; tek silahla mekanik etkisizdi.
	var amalgam_ud = load("res://assets/data/units/amalgams.tres")
	t.ok(amalgam_ud.attacks.size() > 1,
		"Amalgam → birden fazla silahı var (Six-Armed Monstrosity artık gerçekten çoklu saldırı üretir)")

	# Heretic Legion — Shredding Claws (War Wolf): compendium "2 Hands (Melee)" diyor, "1H" yanlıştı.
	var shredding = load("res://assets/data/attacks/shredding_claws.tres")
	t.eq(shredding.hands, "2H", "Shredding Claws → hands=2H (regresyon)")

	# Trench Pilgrims — Stigmatic Nun: compendium'da Crossbow diye bir silah YOK, Battlekit'i
	# yalnız Pistol/Automatic Pistol'a izin veriyor:
	#   "The only Ranged Weapons they can have are Automatic Pistols and Pistols"
	#
	# 2026-07-28: Eskiden bu, `nun_crossbow.tres` dosyasına Pistol stat'ları verilerek "çözülmüştü"
	# — ama dosya adı hâlâ compendium'da olmayan bir silahı ima ediyordu ve menzil 6"ydi
	# (battlekit/ranged.md'ye göre HER tabanca 12"dir). Artık birim doğrudan gerçek
	# `automatic_pistol.tres`i (12", [Assault][Automatic 2][Pistol]) taşıyor; uydurma dosya silindi.
	var nun = load("res://assets/data/units/stigmatic_nun.tres")
	var nun_ranged: Resource = null
	for a in nun.attacks:
		if a != null and a.attack_type == "RANGED":
			nun_ranged = a
	t.ok(nun_ranged != null, "Stigmatic Nun → bir menzilli silahı var")
	if nun_ranged != null:
		t.eq(nun_ranged.attack_range, 12.0, "Stigmatic Nun'un tabancası → 12\" (compendium Pistol menzili)")
		t.ok(not nun_ranged.is_sniper, "Stigmatic Nun'un tabancası → Sniper DEĞİL")
		t.ok(KeywordSystem.has(nun_ranged, &"pistol"), "Stigmatic Nun'un tabancası → [Pistol] keyword'ü")
	t.ok(not ResourceLoader.exists("res://assets/data/attacks/nun_crossbow.tres"),
		"nun_crossbow.tres silinmiş (compendium'da böyle bir silah yok)")
