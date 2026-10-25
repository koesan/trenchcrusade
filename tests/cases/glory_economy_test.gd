extends RefCounted

## Compendium (warbands/starting-a-warband/recruit-your-warband.md):
##   "Each model you recruit has a specific cost in . The Faction List will show how many
##    you have to spend; usually, it will be 700 ."
##   "Some models and pieces of Battlekit cost Glory Points () INSTEAD OF (), are earned by
##    performing valorous deeds in battle... Generally, Warbands don't have access to when
##    they are first created, so you will probably have to wait until later on in a campaign."
##   "Mercenaries... CANNOT BE PURCHASED WITH  — the only way to attract their services is to
##    perform glorious deeds on the battlefield!"
##
## Yani İKİ AYRI havuz vardır ve biri diğerinin yerine geçemez. Skirmish'te Glory havuzu 0'dır,
## dolayısıyla ilk kadroda mercenary bulunamaz (denetim bulgusu S-1).

## Compendium'da Glory Point ile fiyatlanan mercenary birimler
const MERCS := [
	"observer", "scripture_guardian", "combat_biologist", "communicant_anti_tank_hunter",
	"mamluk_faris", "mendelist_ammo_monk", "witchburner", "goetic_warlock", "sin_eater",
	"combat_medic",
]

## Ducat ile fiyatlanan normal roster birimleri (örnekleme)
const DUCAT_UNITS := [
	"new_antioch_yeoman", "heretic_trooper", "azebs", "grail_thrall", "court_yoke_fiend",
	"trench_pilgrim", "new_antioch_lieutenant", "lord_of_tumours", "court_praetor",
]

func run(t) -> void:
	for name in MERCS:
		var ud: Resource = load("res://assets/data/units/%s.tres" % name)
		t.ok(ud != null, "%s yüklendi" % name)
		if ud == null:
			continue
		t.eq(ud.cost_currency, UnitData.Currency.GLORY,
			"%s → Glory Point ile fiyatlanmış (compendium mercenary)" % name)

	for name in DUCAT_UNITS:
		var ud: Resource = load("res://assets/data/units/%s.tres" % name)
		if ud == null:
			continue
		t.eq(ud.cost_currency, UnitData.Currency.DUCAT, "%s → ducat ile fiyatlanmış" % name)

	# ── SAF KURALLAR (sahne kurmadan) ──────────────────────────────────────
	var merc: Resource = load("res://assets/data/units/witchburner.tres")      # 5 Glory
	var yeoman: Resource = load("res://assets/data/units/new_antioch_yeoman.tres")  # 30 ducat

	t.eq(EconomyRules.is_glory(merc), true, "Witchburner → Glory birimi")
	t.eq(EconomyRules.is_glory(yeoman), false, "Yeoman → ducat birimi")

	t.eq(EconomyRules.can_afford(merc, 700, 0), false,
		"Glory=0 iken 700 ducat ile Witchburner ALINAMAZ (compendium: mercenary ducat'la alınamaz)")
	t.eq(EconomyRules.can_afford(merc, 0, 5), true, "Glory=5 → Witchburner alınabilir (ducat 0 olsa bile)")
	t.eq(EconomyRules.can_afford(merc, 700, 4), false, "Glory=4 < 5 → alınamaz")
	t.eq(EconomyRules.can_afford(yeoman, 700, 0), true, "Ducat=700 → Yeoman alınabilir")
	t.eq(EconomyRules.can_afford(yeoman, 10, 999), false,
		"Ducat=10 iken Glory=999 Yeoman'ı (30 ducat) satın ALAMAZ")
	t.eq(EconomyRules.can_afford(null, 700, 700), false, "null birim → alınamaz")

	# Ödeme DOĞRU havuzdan düşer, diğerine dokunmaz
	var p1 := EconomyRules.pay(merc, {"ducat": 700, "glory": 5})
	t.eq(p1["ducat"], 700, "Mercenary ödemesi ducat havuzuna DOKUNMAZ")
	t.eq(p1["glory"], 0, "Mercenary ödemesi glory havuzundan düşer (5-5=0)")
	var p2 := EconomyRules.pay(yeoman, {"ducat": 700, "glory": 5})
	t.eq(p2["ducat"], 700 - yeoman.cost, "Normal asker ödemesi ducat havuzundan düşer (700 - Yeoman maliyeti)")
	t.eq(p2["glory"], 5, "Normal asker ödemesi glory havuzuna DOKUNMAZ")

	# UI için para birimi anahtarı — metin koda gömülmez
	t.eq(EconomyRules.currency_key(merc), "CURRENCY_GLORY", "Mercenary → CURRENCY_GLORY anahtarı")
	t.eq(EconomyRules.currency_key(yeoman), "CURRENCY_DUCAT", "Normal asker → CURRENCY_DUCAT anahtarı")
	t.ok(LocalizationManager.has_key("CURRENCY_GLORY"), "CURRENCY_GLORY localization'da var")
	t.ok(LocalizationManager.has_key("CURRENCY_DUCAT"), "CURRENCY_DUCAT localization'da var")
	t.ok(LocalizationManager.has_key("DEPLOY_FAIL_GLORY"), "DEPLOY_FAIL_GLORY localization'da var")

	# ── "Hiç alınabilir birim kaldı mı?" — iki havuzu birden gözetmeli ─────
	# Skirmish'te Glory=0 olduğu için, ducat'ı biten bir oyuncu 2 Glory'lik bir mercenary
	# yüzünden "hâlâ yerleştirebilir" sayılmamalı (yoksa yerleştirme fazı hiç bitmez).
	var na: Resource = load("res://assets/data/factions/new_antioch.tres")
	t.eq(EconomyRules.can_afford_any(na, 700, 0), true, "700 ducat → alınabilir birim var")
	t.eq(EconomyRules.can_afford_any(na, 29, 0), false,
		"29 ducat + 0 Glory → hiçbir birim alınamaz (en ucuz Yeoman 30; mercenary'ler Glory ister)")
	t.eq(EconomyRules.can_afford_any(na, 29, 3), true,
		"29 ducat + 3 Glory → Observer (3 Glory) alınabilir")
	t.eq(EconomyRules.can_afford_any(na, 0, 0), false, "İki havuz da boş → hiçbir şey alınamaz")

	# ── Senaryo bütçesi: her skirmish senaryosunda küçük bir Glory bütçesi ──
	for sc_name in ["great_war", "fields_of_glory", "marked_for_death", "relic_hunt", "the_high_ground", "claim_no_mans_land"]:
		var sc: Resource = load("res://assets/data/scenarios/%s.tres" % sc_name)
		if sc == null:
			continue
		# Compendium: "Generally, Warbands don't have access to Glory when they are first
		# created" — bu KAMPANYA varsayımıdır. Oyunda kampanya modu yok; bütçeyi 0 bırakmak
		# 12 mercenary birimini ERİŞİLEMEZ içerik yapıyordu (kullanıcı bildirimi: "paralı
		# askerler ducat ile yerleştirilemez"). Skirmish'te küçük bir Glory bütçesi verilir:
		# 2-3 mercenary'ye yeter, "hepsini al" sömürüsüne (7 merc = 29 Glory) yetmez.
		t.ok(sc.glory_budget >= 1,
			"%s → skirmish'te Glory bütçesi var (mercenary'ler erişilebilir)" % sc_name)
		t.ok(sc.glory_budget <= 15,
			"%s → Glory bütçesi sınırlı (tüm mercenary'ler alınamaz)" % sc_name)
		t.eq(sc.points_budget, 700, "%s → points_budget 700" % sc_name)
