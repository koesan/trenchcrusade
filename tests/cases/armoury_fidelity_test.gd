extends RefCounted

## Compendium Armoury silahlarının oyundaki .tres karşılıkları, kaynaktaki menzil / el sayısı /
## keyword değerleriyle BİREBİR eşleşmeli (denetim bulgusu S-3).
##
## KAYNAK: trench_compendium/battlekit/{ranged,melee,grenade}.md — bunlar silahların resmî
## stat bloklarıdır (warband dosyalarındaki Armoury tabloları yalnız FİYAT verir).
##
## NOT — denetim raporundaki bir tahminin düzeltilmesi: 01_new_antioch.md'de Sniper Rifle
## "≈36\", [Sniper], +1 Injury" diye tahmin edilmişti. Gerçek battlekit verisi:
## **48"**, `[+1 Dice]`, `[Critical]`, `[Risky]` + Bull's Eye (kritikte Ignore Armour).
## `[Sniper]` diye bir compendium keyword'ü YOKTUR; motordaki `is_sniper` bayrağı aslında
## `[Ignore Long Range]`in eş anlamlısıdır (bkz. dice_pool_builder.gd:80).

## file → {range, type, hands, dice(dice_modifier), injury(injury_dice_modifier)}
const EXPECT := {
	# ── RANGED ─────────────────────────────────────────────────────────────
	"sniper_rifle":        {"range": 48.0, "type": "RANGED", "hands": "2H", "dice": 1,  "injury": 0},
	"machine_gun":         {"range": 36.0, "type": "RANGED", "hands": "2H", "dice": 0,  "injury": 0},
	"heavy_flamethrower":  {"range": 10.0, "type": "RANGED", "hands": "2H", "dice": 0,  "injury": -1},
	"flamethrower":        {"range": 8.0,  "type": "RANGED", "hands": "2H", "dice": 0,  "injury": -1},
	"automatic_rifle":     {"range": 24.0, "type": "RANGED", "hands": "2H", "dice": 0,  "injury": 0},
	"alaybozan":           {"range": 12.0, "type": "RANGED", "hands": "2H", "dice": 0,  "injury": 0},
	"flame_cannon":        {"range": 12.0, "type": "RANGED", "hands": "1H", "dice": 0,  "injury": 0},
	"murad_bombard":       {"range": 36.0, "type": "RANGED", "hands": "1H", "dice": 0,  "injury": 0},
	"siege_jezzail":       {"range": 30.0, "type": "RANGED", "hands": "2H", "dice": 0,  "injury": 1},
	"infested_rifle":      {"range": 18.0, "type": "RANGED", "hands": "2H", "dice": 0,  "injury": 0},
	"putrid_shotgun":      {"range": 12.0, "type": "RANGED", "hands": "2H", "dice": 1,  "injury": 0},
	"corruption_belcher":  {"range": 8.0,  "type": "RANGED", "hands": "2H", "dice": 0,  "injury": 0},
	"viscera_cannon":      {"range": 24.0, "type": "RANGED", "hands": "2H", "dice": 2,  "injury": 0},
	"musket":              {"range": 18.0, "type": "RANGED", "hands": "2H", "dice": 0,  "injury": -1},
	"blunderbuss":         {"range": 10.0, "type": "RANGED", "hands": "2H", "dice": 0,  "injury": 0},
	"ophidian_rifle":      {"range": 30.0, "type": "RANGED", "hands": "2H", "dice": 0,  "injury": 0},
	"serpent_assault_gun": {"range": 36.0, "type": "RANGED", "hands": "2H", "dice": 0,  "injury": 0},
	"arquebus":            {"range": 18.0, "type": "RANGED", "hands": "2H", "dice": 0,  "injury": 0},
	"pistol":              {"range": 12.0, "type": "RANGED", "hands": "1H", "dice": 0,  "injury": 0},
	"automatic_pistol":    {"range": 12.0, "type": "RANGED", "hands": "1H", "dice": 0,  "injury": 0},
	# ── GRENADES ───────────────────────────────────────────────────────────
	"parasite_grenades":   {"range": 8.0,  "type": "RANGED", "hands": "1H", "dice": 0,  "injury": 0},
	"molotov_cocktail":    {"range": 6.0,  "type": "RANGED", "hands": "1H", "dice": 0,  "injury": -1},
	"war_cross":           {"range": 8.0,  "type": "RANGED", "hands": "1H", "dice": 0,  "injury": 0},
	"satchel_charge":      {"range": 6.0,  "type": "RANGED", "hands": "1H", "dice": 0,  "injury": 1},
	# ── MELEE ──────────────────────────────────────────────────────────────
	"hellblade":           {"range": 1.0,  "type": "MELEE",  "hands": "2H", "dice": 0,  "injury": 1},
	"plague_blade":        {"range": 1.0,  "type": "MELEE",  "hands": "1H", "dice": 0,  "injury": 0},
	"head_taker":          {"range": 1.0,  "type": "MELEE",  "hands": "1H", "dice": 0,  "injury": 0},
	"torture_instrument":  {"range": 1.0,  "type": "MELEE",  "hands": "2H", "dice": 0,  "injury": 0},
	"malebranche_sword":   {"range": 1.0,  "type": "MELEE",  "hands": "2H", "dice": 0,  "injury": 0},
	"beelzebubs_axe":      {"range": 1.0,  "type": "MELEE",  "hands": "2H", "dice": 0,  "injury": 2},
	"great_hammer_maul":   {"range": 1.0,  "type": "MELEE",  "hands": "2H", "dice": 0,  "injury": 0},
	"sword_axe":           {"range": 1.0,  "type": "MELEE",  "hands": "1H", "dice": 0,  "injury": 0},
	"trench_club":         {"range": 1.0,  "type": "MELEE",  "hands": "1H", "dice": 0,  "injury": 0},
	"bayonet":             {"range": 1.0,  "type": "MELEE",  "hands": "2H", "dice": 0,  "injury": 0},
	"flail_scourge":       {"range": 1.0,  "type": "MELEE",  "hands": "1H", "dice": 1,  "injury": 0},
	"anti_tank_hammer":    {"range": 1.0,  "type": "MELEE",  "hands": "2H", "dice": 0,  "injury": 1},
	"blasphemous_staff":   {"range": 1.0,  "type": "MELEE",  "hands": "1H", "dice": 0,  "injury": 0},
	"sacrificial_blade":   {"range": 1.0,  "type": "MELEE",  "hands": "1H", "dice": 0,  "injury": 0},
	"tartarus_claws":      {"range": 1.0,  "type": "MELEE",  "hands": "2H", "dice": 0,  "injury": 0},
}

## file → zorunlu keyword listesi (compendium'daki `Keywords` satırından birebir)
const EXPECT_KW := {
	"sniper_rifle":        ["critical", "risky"],
	"heavy_flamethrower":  ["automatic", "flamethrower", "heavy"],
	"automatic_rifle":     ["automatic", "bayonet_lug"],
	"alaybozan":           ["shrapnel", "shield_combo"],
	"flame_cannon":        ["heavy"],
	"murad_bombard":       ["scatter", "heavy"],
	"siege_jezzail":       ["heavy"],
	"infested_rifle":      ["armour_piercing", "bayonet_lug"],
	"putrid_shotgun":      ["shotgun", "bayonet_lug", "shield_combo", "infection_markers"],
	"corruption_belcher":  ["flamethrower"],
	"viscera_cannon":      ["heavy"],
	"musket":              ["bayonet_lug"],
	"blunderbuss":         ["shrapnel", "shield_combo"],
	"ophidian_rifle":      ["heavy"],
	"serpent_assault_gun": ["automatic", "heavy"],
	"pistol":              ["pistol"],
	"automatic_pistol":    ["automatic", "pistol"],
	"satchel_charge":      ["scatter", "consumable", "heavy"],
	"plague_blade":        ["infection_markers"],
	"beelzebubs_axe":      ["heavy", "infection_markers"],
	"great_hammer_maul":   ["heavy", "injury_modifier"],
	"greatsword_axe":      ["critical", "heavy"],
	"sword_axe":           ["critical"],
	"bayonet":             ["shield_combo"],
	"anti_tank_hammer":    ["critical", "risky"],
	"sacrificial_blade":   ["risky", "injury_modifier"],
	"tartarus_claws":      ["critical"],
	"malebranche_sword":   ["heavy"],
}

## Cult of the Black Grail'in enfeksiyon DAĞITIM araçları. Compendium'da `[Infection Marker]`
## keyword'ünü DOĞRUDAN taşıyan silahlar bunlardır (denetim bulgusu P0-BG-2).
## NOT: Corruption Belcher `[Gas]`, Infested Rifle `[Armour Piercing]`, Parasite Grenades ise
## "Terrifying Hallucinations" özel kuralı taşır — bunlar enfeksiyon BASMAZ; denetim raporundaki
## "dört menzilli enfeksiyon silahı" ifadesi bu veriyle düzeltilmiştir.
const INFECTION_WEAPONS := ["putrid_shotgun", "plague_blade", "beelzebubs_axe"]

func run(t) -> void:
	for name in EXPECT.keys():
		var path := "res://assets/data/attacks/%s.tres" % name
		t.ok(ResourceLoader.exists(path), "%s.tres mevcut" % name)
		if not ResourceLoader.exists(path):
			continue
		var a: Resource = load(path)
		var e: Dictionary = EXPECT[name]
		t.approx(a.attack_range, e["range"], "%s menzil %.0f\"" % [name, e["range"]])
		t.eq(a.attack_type, e["type"], "%s tip %s" % [name, e["type"]])
		t.eq(a.hands, e["hands"], "%s el %s" % [name, e["hands"]])
		t.eq(a.dice_modifier, e["dice"], "%s dice %+d" % [name, e["dice"]])
		t.eq(a.injury_dice_modifier, e["injury"], "%s injury dice %+d" % [name, e["injury"]])

	for name in EXPECT_KW.keys():
		var path := "res://assets/data/attacks/%s.tres" % name
		if not ResourceLoader.exists(path):
			continue
		var a: Resource = load(path)
		for kw in EXPECT_KW[name]:
			t.ok(KeywordSystem.has(a, StringName(kw)), "%s → [%s]" % [name, kw])

	for name in INFECTION_WEAPONS:
		var a: Resource = load("res://assets/data/attacks/%s.tres" % name)
		t.ok(a != null and KeywordSystem.has(a, &"infection_markers"),
			"%s → [Infection Marker] taşıyor (Black Grail dağıtım aracı)" % name)

	# Menzilli enfeksiyon dağıtımı gerçekten mümkün olmalı: en az bir RANGED silah
	# [Infection Markers] taşımalı (denetim bulgusu P0-BG-2'nin çekirdeği).
	var ranged_infection := 0
	for name in INFECTION_WEAPONS:
		var a: Resource = load("res://assets/data/attacks/%s.tres" % name)
		if a != null and a.attack_type == "RANGED":
			ranged_infection += 1
	t.ok(ranged_infection >= 1,
		"En az 1 MENZİLLİ enfeksiyon silahı var (enfeksiyon artık melee'ye hapis değil)")

	# Silah düzeyi [+N Injury Modifier] motorda okunuyor olmalı (Great Hammer/Maul,
	# Sacrificial Blade bu keyword olmadan compendium'daki hâllerini temsil edemez).
	var ghm: Resource = load("res://assets/data/attacks/great_hammer_maul.tres")
	t.eq(KeywordSystem.value(ghm, &"injury_modifier", 0), 1,
		"Great Hammer/Maul → [+1 Injury Modifier]")
	var sb: Resource = load("res://assets/data/attacks/sacrificial_blade.tres")
	t.eq(KeywordSystem.value(sb, &"injury_modifier", 0), 2,
		"Sacrificial Blade → [+2 Injury Modifier]")

	# Her silahın adı ve açıklaması BİR LOKALİZASYON ANAHTARI olmalı ve o anahtar iki dilde de
	# bulunmalı (Global Constraint: hiçbir metin koda/veriye gömülmez). Bu, "silah eklendi ama
	# metni eklenmedi" hata sınıfını yakalar; anahtarın iki dilde de olmasını
	# localization_parity_test.gd ayrıca garanti eder.
	var missing_text: Array[String] = []
	var dir := DirAccess.open("res://assets/data/attacks")
	if dir != null:
		dir.list_dir_begin()
		var fn := dir.get_next()
		while fn != "":
			if fn.ends_with(".tres"):
				var a: Resource = load("res://assets/data/attacks/" + fn)
				if a != null:
					if a.attack_name == "" or not LocalizationManager.has_key(a.attack_name):
						missing_text.append("%s.attack_name=%s" % [fn, a.attack_name])
					if a.description == "" or not LocalizationManager.has_key(a.description):
						missing_text.append("%s.description=%s" % [fn, a.description])
			fn = dir.get_next()
		dir.list_dir_end()
	missing_text.sort()
	t.eq(missing_text.size(), 0,
		"Her silahın ad/açıklama anahtarı localization'da mevcut %s" % str(missing_text.slice(0, 6)))

	# ── ÖDÜNÇ SİLAH YASAĞI (denetim bulgusu S-3) ──────────────────────────
	# Bir faksiyonun birimi BAŞKA faksiyonun imza silahını taşımamalı. Compendium'da her
	# faksiyonun kendi Armoury tablosu vardır; tek istisna Plague Knight'ın "Knight of the
	# Rotten Cross" terfisidir (henüz uygulanmadı — kapsam dışı).
	# Mercenary'ler muaf: birden çok faksiyonda hizmet ederler.
	var owner := {
		"templar_": &"new_antioch", "crusader_": &"new_antioch", "medic_": &"new_antioch",
		"legionary_": &"heretic_legion", "anointed_": &"heretic_legion",
		"nun_": &"trench_pilgrims", "prophet_": &"trench_pilgrims",
		"castigator_": &"trench_pilgrims", "communicant_": &"trench_pilgrims",
		"yuzbasi_": &"iron_sultanate", "janissary_": &"iron_sultanate",
		"alchemist_": &"iron_sultanate", "mamluk_": &"iron_sultanate",
		"court_": &"court_of_seven_headed_serpent",
	}
	var borrowed: Array[String] = []
	var udir := DirAccess.open("res://assets/data/units")
	if udir != null:
		udir.list_dir_begin()
		var ufn := udir.get_next()
		while ufn != "":
			if ufn.ends_with(".tres"):
				var ud: Resource = load("res://assets/data/units/" + ufn)
				# Mercenary'ler (Glory ile alınanlar) muaf
				if ud != null and int(ud.cost_currency) == 0:
					for a2 in ud.attacks:
						if a2 == null:
							continue
						var fname := String(a2.resource_path).get_file()
						for prefix in owner.keys():
							if fname.begins_with(prefix) and ud.faction_id != owner[prefix]:
								borrowed.append("%s(%s)→%s" % [ufn.get_basename(), ud.faction_id, fname])
			ufn = udir.get_next()
		udir.list_dir_end()
	borrowed.sort()
	t.eq(borrowed.size(), 0,
		"Hiçbir birim başka faksiyonun imza silahını taşımıyor %s" % str(borrowed.slice(0, 6)))
