extends RefCounted

## ARMOURY (Battlekit satın alma) — veri sadakati + kural denetimi.
##
## Kaynak: warbands/<faction>#Armoury tabloları (fiyat, LIMIT, kısıt) ve battlekit/*.md
## (anahtar kelimeler). Veri `tools/generate_armoury.py` ile üretilir; bu test üretimin
## compendium ile uyumlu kaldığını ve kural motorunun tabloya uyduğunu kanıtlar.

const FACTIONS := ["new_antioch", "heretic_legion", "trench_pilgrims", "iron_sultanate",
	"cult_of_the_black_grail", "court_of_seven_headed_serpent"]

## Compendium'daki tablo boyutları (Exploration Only bölümü çatışma modunda geçerli değil).
const EXPECTED_SIZE := {
	"new_antioch": 39, "heretic_legion": 42, "trench_pilgrims": 41,
	"iron_sultanate": 41, "cult_of_the_black_grail": 32,
	"court_of_seven_headed_serpent": 33,
}

func _find(faction: Resource, id: StringName) -> Resource:
	for it in ArmouryRules.table_for(faction):
		if it.item_id == id:
			return it
	return null

func run(t) -> void:
	var by_faction := {}
	for fid in FACTIONS:
		var f: Resource = load("res://assets/data/factions/%s.tres" % fid)
		t.ok(f != null, "%s yüklendi" % fid)
		if f == null:
			continue
		by_faction[fid] = f
		var table: Array = ArmouryRules.table_for(f)
		t.eq(table.size(), EXPECTED_SIZE[fid],
			"%s Armoury tablosu compendium ile aynı boyutta" % fid)
		for it in table:
			t.ok(it.item_id != &"", "%s: kalem id'si dolu" % fid)
			t.ok(it.cost > 0, "%s/%s: fiyat > 0" % [fid, it.item_id])
			t.ok(LocalizationManager.has_key(it.name_key),
				"%s/%s: ad anahtarı localization'da (%s)" % [fid, it.item_id, it.name_key])
			t.ok(LocalizationManager.has_key(it.desc_key),
				"%s/%s: açıklama anahtarı localization'da (%s)" % [fid, it.item_id, it.desc_key])
			if it.restriction_key != "":
				t.ok(LocalizationManager.has_key(it.restriction_key),
					"%s/%s: kısıt anahtarı localization'da" % [fid, it.item_id])
			# Silah kalemleri gerçek bir saldırı vermeli, diğerleri gerçek bir etki taşımalı
			var is_weapon: bool = it.category <= ArmouryItem.Category.GRENADE
			if is_weapon:
				t.ok(not it.granted_attacks.is_empty(),
					"%s/%s: silah kalemi bir AttackData veriyor" % [fid, it.item_id])
			else:
				t.ok(it.armour_value > 0 or not it.granted_keywords.is_empty(),
					"%s/%s: silah dışı kalem gerçek bir etki taşıyor" % [fid, it.item_id])

	# ── FİYAT SADAKATİ (compendium tablosundan doğrudan alıntı) ────────────
	var na: Resource = by_faction["new_antioch"]
	t.eq(_find(na, &"machine_gun").cost, 50, "New Antioch Machine Gun 50 ducat")
	t.eq(_find(na, &"machine_gun").limit_per_warband, 2, "New Antioch Machine Gun LIMIT: 2")
	t.eq(_find(na, &"trench_knife").cost, 1, "Trench Knife 1 ducat")
	t.eq(_find(na, &"machine_armour").armour_value, 3, "Machine Armour [-3 Injury Modifier]")
	t.eq(_find(na, &"standard_armour").armour_value, 1, "Standard Armour [-1 Injury Modifier]")
	t.eq(_find(na, &"reinforced_armour").armour_value, 2, "Reinforced Armour [-2 Injury Modifier]")
	t.eq(_find(na, &"machine_armour").elite_only, true, "Machine Armour: Elite only")

	# Aynı kalem, faksiyona göre FARKLI limit taşıyabilir (compendium böyle listeler)
	var hl: Resource = by_faction["heretic_legion"]
	t.eq(_find(hl, &"machine_gun").limit_per_warband, 1, "Heretic Legion Machine Gun LIMIT: 1")

	# ── GLORY POINT FİYATLI KALEMLER ──────────────────────────────────────
	# Compendium: "Some pieces of Battlekit cost Glory Points instead of ducats."
	var tp: Resource = by_faction["trench_pilgrims"]
	t.eq(_find(tp, &"machine_gun").cost_currency, ArmouryItem.Currency.GLORY,
		"Trench Pilgrims Machine Gun Şan Puanı ile fiyatlanmış (New Antioch'ta 50 ducat)")
	t.eq(_find(na, &"machine_gun").cost_currency, ArmouryItem.Currency.DUCAT,
		"New Antioch Machine Gun ducat ile fiyatlanmış")

	# ── KURAL MOTORU ──────────────────────────────────────────────────────
	var yeoman: Resource = load("res://assets/data/units/new_antioch_yeoman.tres").duplicate(true)
	var lieutenant: Resource = load("res://assets/data/units/new_antioch_lieutenant.tres").duplicate(true)
	var trench_knife := _find(na, &"trench_knife")
	var machine_armour := _find(na, &"machine_armour")
	var std_armour := _find(na, &"standard_armour")

	# Yeoman'ın Süngüsü 2 elli ve [Hantal]dır (battlekit/melee.md) — yakın dövüş elleri ZATEN
	# doludur, bu yüzden ikinci bir yakın dövüş silahı alamaz. Bu doğru davranıştır.
	t.eq(ArmouryRules.check(trench_knife, yeoman, na, {}, [], 700, 0), ArmouryRules.REASON_HANDS,
		"Süngü (2 El) taşıyan Yeoman ikinci yakın dövüş silahı alamaz")

	var free_hands: Resource = yeoman.duplicate(true)
	free_hands.attacks = [] as Array[Resource]
	t.eq(ArmouryRules.check(trench_knife, free_hands, na, {}, [], 700, 0), "",
		"Elleri boş model + bol ducat → Trench Knife alınabilir")
	t.eq(ArmouryRules.check(trench_knife, free_hands, na, {}, [], 0, 700),
		ArmouryRules.REASON_BUDGET,
		"Ducat 0 iken Şan Puanı ducat kalemi satın ALAMAZ (havuzlar ayrı)")

	# "Elite only"
	t.eq(ArmouryRules.check(machine_armour, yeoman, na, {}, [], 700, 0),
		ArmouryRules.REASON_ELITE_ONLY, "Yeoman [Elite] değil → Makine Zırhı alamaz")
	t.eq(ArmouryRules.check(machine_armour, lieutenant, na, {}, [], 700, 0), "",
		"Lieutenant [Elite] → Makine Zırhı alabilir")

	# LIMIT: 1
	t.eq(ArmouryRules.check(machine_armour, lieutenant, na, {&"machine_armour": 1}, [], 700, 0),
		ArmouryRules.REASON_LIMIT, "Makine Zırhı LIMIT: 1 → ikincisi reddedilir")

	# Aynı kalem bir modele iki kez takılmaz
	t.eq(ArmouryRules.check(trench_knife, yeoman, na, {}, [&"trench_knife"], 700, 0),
		ArmouryRules.REASON_ALREADY_OWNED, "Aynı kalem aynı modele iki kez takılamaz")

	# Ön koşul: "Machine Armour only"
	var ballistic := _find(na, &"heavy_ballistic_shield")
	t.eq(ArmouryRules.check(ballistic, lieutenant, na, {}, [], 700, 0),
		ArmouryRules.REASON_REQUIRES_ITEM,
		"Ağır Balistik Kalkan önce Makine Zırhı ister")
	t.eq(ArmouryRules.check(ballistic, lieutenant, na, {}, [&"machine_armour"], 700, 0), "",
		"Makine Zırhı alındıysa Ağır Balistik Kalkan alınabilir")

	# Faksiyon tablosu üyeliği — Heretic Legion kalemi New Antioch modeline satılamaz
	var hellblade := _find(hl, &"hellblade")
	t.ok(hellblade != null, "Heretic Legion Hellblade tabloda var")
	t.eq(ArmouryRules.check(hellblade, lieutenant, na, {}, [], 700, 700),
		ArmouryRules.REASON_NOT_IN_TABLE,
		"Başka faksiyonun Armoury kalemi satın ALINAMAZ")

	# "<Birim> only"
	var isf: Resource = by_faction["iron_sultanate"]
	var zulfiqar := _find(isf, &"titan_zulfiqar")
	var janissary: Resource = load("res://assets/data/units/janissary.tres").duplicate(true)
	t.eq(zulfiqar.required_unit_names, PackedStringArray(["Brazen Bull"]) as Array[String],
		"Titan Zulfiqar yalnızca Tunç Boğa'ya ait")
	t.eq(ArmouryRules.check(zulfiqar, janissary, isf, {}, [], 700, 0),
		ArmouryRules.REASON_UNIT_ONLY, "Yeniçeri Titan Zulfiqar alamaz")

	# Zırh: model tek zırh giyer, daha zayıfı satın alınamaz
	var armoured: Resource = load("res://assets/data/units/new_antioch_yeoman.tres").duplicate(true)
	armoured.armour = 2
	t.eq(ArmouryRules.check(std_armour, armoured, na, {}, [], 700, 0),
		ArmouryRules.REASON_ARMOUR, "Zaten daha iyi zırh giyen model Standart Zırh alamaz")

	# El bütçesi: 2 elli silah taşıyan model bir daha 2 elli silah alamaz
	var rifle := _find(na, &"bolt_action_rifle")
	var loaded: Resource = load("res://assets/data/units/new_antioch_yeoman.tres").duplicate(true)
	t.eq(ArmouryRules.hands_used(loaded, false) <= 2, true, "Yeoman menzilli el bütçesi geçerli")
	loaded.attacks = [load("res://assets/data/attacks/machine_gun.tres")] as Array[Resource]
	t.eq(ArmouryRules.check(rifle, loaded, na, {}, [], 700, 0), ArmouryRules.REASON_HANDS,
		"Zaten 2 elli silah taşıyan model ikinci 2 elli silahı alamaz")

	# [Heavy]: bir model birden fazla Heavy Battlekit taşıyamaz
	var mg := _find(na, &"machine_gun")
	var heavy_carrier: Resource = load("res://assets/data/units/new_antioch_yeoman.tres").duplicate(true)
	heavy_carrier.attacks = [load("res://assets/data/attacks/heavy_shotgun.tres")] as Array[Resource]
	t.ok(ArmouryRules.check(mg, heavy_carrier, na, {}, [], 700, 0) != "",
		"İkinci [Ağır] Battlekit reddedilir")

	# ── SATIN ALMA UYGULAMASI ─────────────────────────────────────────────
	var base: Resource = load("res://assets/data/units/new_antioch_yeoman.tres")
	var before: int = base.attacks.size()
	var after: Resource = ArmouryRules.apply(base, trench_knife)
	t.eq(after.attacks.size(), before + 1, "Silah satın alımı modele saldırı ekler")
	t.eq(base.attacks.size(), before,
		"Paylaşılan .tres MUTASYONA UĞRAMAZ (satın alma kopya üzerinde çalışır)")
	t.eq(after.cost, base.cost + trench_knife.cost, "Kalem maliyeti modelin değerine eklenir")

	var armed: Resource = ArmouryRules.apply(base, std_armour)
	t.eq(armed.armour, 1, "Standart Zırh satın alımı modelin zırhını 1 yapar")
	t.eq(base.armour, 0, "Zırh satın alımı paylaşılan .tres'i bozmaz")

	var masked: Resource = ArmouryRules.apply(base, _find(na, &"gas_mask"))
	t.ok(KeywordSystem.has(masked, &"negate_gas"),
		"Gaz Maskesi satın alımı modele [Gazı Engelle] verir")

	# ── LOKALİZASYON & FAZ ────────────────────────────────────────────────
	for reason in ArmouryRules.ALL_REASONS:
		t.ok(LocalizationManager.has_key(reason), "Ret sebebi localization'da: %s" % reason)
	for key in ArmouryRules.CATEGORY_KEYS:
		t.ok(LocalizationManager.has_key(key), "Kategori başlığı localization'da: %s" % key)
	for key in ["ARMOURY_TITLE", "ARMOURY_SUBTITLE", "ARMOURY_BUY", "ARMOURY_FINISH",
			"ARMOURY_WAITING", "ARMOURY_SELECT_UNIT", "ARMOURY_NO_ITEMS",
			"ARMOURY_EQUIPPED_NONE", "ARMOURY_LIMIT_LEFT", "ARMOURY_OWNED"]:
		t.ok(LocalizationManager.has_key(key), "Armoury UI metni localization'da: %s" % key)

	# Faz sırası: DEPLOYMENT -> ARMOURY -> BATTLE
	t.ok(GameState.GamePhase.DEPLOYMENT < GameState.GamePhase.ARMOURY,
		"ARMOURY fazı yerleştirmeden SONRA gelir")
	t.ok(GameState.GamePhase.ARMOURY < GameState.GamePhase.BATTLE,
		"ARMOURY fazı savaştan ÖNCE gelir")
	t.ok(ResourceLoader.exists("res://scenes/ui/armoury/armoury_panel.tscn"),
		"Armoury ekranı mevcut")
