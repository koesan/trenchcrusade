extends RefCounted

## Kullanıcı isteği: "oyunda olan silah ve zırhları incele, eksik silah/zırh varsa ekle." 5 gerçek
## armoury silahı compendium'da isimle geçiyordu (battlekit/ranged.md, melee.md, grenade.md) ama
## hiçbir unit'te veri olarak yoktu: Machine Gun, Shotgun, Frag Grenade, Greatsword/Axe (jenerik),
## Trench Knife. Her biri en az bir uygun birimin loadout_options'ına (mevcut deploy-zamanı
## Battlekit seçim ekranı — loadout_picker_overlay.gd, kullanıcının "mağaza" dediği mekanizma)
## bağlandı.

const KeywordSystem = preload("res://scripts/rules/keyword_system.gd")
const LoadoutResolver = preload("res://scripts/rules/loadout_resolver.gd")

func run(t) -> void:
	# ── Yeni silah verilerinin kendisi compendium'a uygun mu ──────────────────
	var mg = load("res://assets/data/attacks/machine_gun.tres")
	t.eq(mg.attack_range, 36.0, "Machine Gun → 36\" menzil")
	t.eq(mg.hands, "2H", "Machine Gun → 2H")
	t.eq(KeywordSystem.value(mg, &"automatic", 1), 3, "Machine Gun → Automatic 3")
	t.ok(KeywordSystem.has(mg, &"heavy"), "Machine Gun → Heavy")
	t.ok(KeywordSystem.has(mg, &"reload"), "Machine Gun → Reload")

	var sg = load("res://assets/data/attacks/shotgun.tres")
	t.eq(sg.attack_range, 12.0, "Shotgun → 12\" menzil")
	t.eq(sg.dice_modifier, 1, "Shotgun → +1 Dice")
	t.ok(KeywordSystem.has(sg, &"shotgun"), "Shotgun → Shotgun keyword'ü")

	var fg = load("res://assets/data/attacks/frag_grenade.tres")
	t.eq(fg.attack_range, 8.0, "Frag Grenade → 8\" menzil")
	t.ok(fg.is_blast and fg.blast_radius == 2.0, "Frag Grenade → Blast 2\"")
	t.ok(fg.ignore_cover, "Frag Grenade → Ignore Cover")
	t.ok(KeywordSystem.has(fg, &"ignore_long_range"), "Frag Grenade → Ignore Long Range")
	t.ok(KeywordSystem.has(fg, &"shrapnel"), "Frag Grenade → Shrapnel")

	var gs = load("res://assets/data/attacks/greatsword_axe.tres")
	t.eq(gs.hands, "2H", "Greatsword/Axe (jenerik) → 2H")
	t.eq(gs.injury_dice_modifier, 1, "Greatsword/Axe → +1 Injury Dice")
	t.ok(KeywordSystem.has(gs, &"critical") and KeywordSystem.has(gs, &"heavy"),
		"Greatsword/Axe → Critical + Heavy")

	var tk = load("res://assets/data/attacks/trench_knife.tres")
	t.eq(tk.hands, "1H", "Trench Knife → 1H")
	t.eq(tk.dice_modifier, -1, "Trench Knife → -1 Dice")

	# ── Deploy-zamanı "mağaza" (loadout_options) entegrasyonu — her yeni silah en az 1 birimde ──
	var yuzbasi = load("res://assets/data/units/yuzbasi.tres")
	t.ok(yuzbasi.loadout_options[2].attacks_override.has(mg),
		"Yüzbaşı'nın 3. loadout'u Machine Gun içeriyor")

	var heretic_priest = load("res://assets/data/units/heretic_priest.tres")
	t.ok(heretic_priest.loadout_options.size() >= 2, "Heretic Priest → en az 2 loadout (Shotgun dahil)")
	t.ok(heretic_priest.loadout_options[1].attacks_override.has(sg),
		"Heretic Priest'in 2. loadout'u Shotgun içeriyor")

	# TRENCH PILGRIMS Armoury'sinde Frag Grenade YOKTUR — yalnız Incendiary Grenades (15),
	# Molotov Cocktail (5) ve War-Cross (5) vardır. Eskiden New Antioch'un Frag Grenade'i
	# onun fiyatıyla (7) verilmişti (denetim bulgusu P1-TP-7).
	var molotov = load("res://assets/data/attacks/molotov_cocktail.tres")
	var trench_pilgrim = load("res://assets/data/units/trench_pilgrim.tres")
	t.ok(trench_pilgrim.loadout_options.size() >= 3, "Trench Pilgrim → en az 3 loadout")
	t.ok(trench_pilgrim.loadout_options[2].attacks_override.has(molotov),
		"Trench Pilgrim'in 3. loadout'u Molotov Cocktail içeriyor (TP Armoury)")
	t.eq(trench_pilgrim.loadout_options[2].cost_delta, 5, "Molotov Cocktail 5 ducat")

	var janissary = load("res://assets/data/units/janissary.tres")
	t.ok(janissary.loadout_options[1].attacks_override.has(gs),
		"Janissary'nin 2. loadout'u Greatsword/Axe içeriyor")

	var lieutenant = load("res://assets/data/units/new_antioch_lieutenant.tres")
	t.eq(lieutenant.loadout_options.size(), 2, "Lieutenant → 2 loadout seçeneği (yeni: Trench Knife)")
	t.ok(lieutenant.loadout_options[1].attacks_override.has(tk),
		"Lieutenant'ın 2. loadout'u Trench Knife içeriyor")

	# ── LoadoutResolver ile gerçekten çözülebiliyor mu (deploy akışının kullandığı yol) ──────
	var resolved = LoadoutResolver.resolve_loadout(yuzbasi, 2)
	t.ok(resolved.attacks.has(mg), "LoadoutResolver.resolve_loadout → Yüzbaşı+Machine Gun doğru çözülüyor")
	# Iron Sultanate Armoury: Machine Gun **50** (LIMIT 1). Eskiden 45 girilmişti (denetim P2-IS-8c).
	# Machine Gun loadout'u tabancayı (6) bırakıp Machine Gun'u (50) alır → +44.
	t.eq(resolved.cost, yuzbasi.cost - 6 + 50, "Machine Gun loadout'u doğru maliyet ekliyor (armoury: 50, tabanca 6 düşer)")

	# ── Zırh (armour) seçenekleri — compendium: Reinforced Armour=[-2 Injury Modifier]/Elite only,
	# Standard Armour=[-1 Injury Modifier] (bu projede armour=magnitude konvansiyonu) ────────────
	t.eq(yuzbasi.loadout_options.size(), 4, "Yüzbaşı → 4. loadout: Reinforced Armour")
	t.eq(yuzbasi.loadout_options[3].armour_override, 2, "Yüzbaşı Reinforced Armour → armour=2 (-2 Injury Modifier)")
	var resolved_armour = LoadoutResolver.resolve_loadout(yuzbasi, 3)
	t.eq(resolved_armour.armour, 2, "LoadoutResolver → Yüzbaşı+Reinforced Armour doğru çözülüyor")

	# İNDEKS YERİNE ANAHTARLA ARA: Armoury genişledikçe loadout indeksleri kayıyor; testin
	# gerçekten önemsediği şey "Standard Armour seçeneği VAR ve -1 veriyor".
	var jan_armour: Resource = null
	for o in janissary.loadout_options:
		if o != null and o.option_name_key == "JANISSARY_LOADOUT_ARMOURED":
			jan_armour = o
	t.ok(jan_armour != null, "Janissary → Standard Armour loadout'u var")
	if jan_armour != null:
		t.eq(jan_armour.armour_override, 1, "Janissary Standard Armour → armour=1 (-1 Injury Modifier)")
