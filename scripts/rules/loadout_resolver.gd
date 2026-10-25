## LoadoutResolver — Trench Crusade Silah Yükleme (Loadout) Kuralları
##
## Bu sınıf STATELESS'tır (mechanics_resolver.gd/faction_rules.gd ile aynı desen).
## Kural kitabı (model-battlekit.md): bir model aynı kategoride en fazla
## 1x2H silah VEYA 2x1H silah taşıyabilir (Melee ve Ranged ayrı ayrı sayılır).
class_name LoadoutResolver

## unit_data.attacks[]'in yükleme kurallarını ihlal edip etmediğini kontrol eder.
## Döndürür: "" (geçerli) veya hata mesajı.
static func validate_loadout(unit_data: Resource) -> String:
	if unit_data == null:
		return ""
	# FIXED_WEAPON_LOADOUT: compendium bazı modellerin silahlarını "bu modele aittir, kaybedilemez/
	# değiştirilemez, başka Battlekit taşıyamaz" diye sabitler (War Wolf'un Chainsaw Mouth+Shredding
	# Claws'ı; Amalgam'ın Six-Armed Monstrosity'siyle altı kola kadar silahı). Bu modeller compendium'da
	# AÇIKÇA standart "1x2H veya 2x1H" el-taşıma limitinin İSTİSNASIdır (oyuncunun seçtiği bir Battlekit
	# DEĞİL, sabit stat-blok) — bu yüzden el-limiti/HEAVY-adet kontrolü onlara uygulanmaz.
	if KeywordSystem.has(unit_data, &"fixed_weapon_loadout"):
		return ""

	# BRAZEN BULL (Court, P1-1): "May ONLY have Weapons with the Heavy Keyword."
	# heavy_only keyword'üne sahip birimler sadece HEAVY silah taşıyabilir.
	if KeywordSystem.has(unit_data, &"heavy_only"):
		for atk_check in unit_data.attacks:
			if atk_check != null and not KeywordSystem.has(atk_check, &"heavy"):
				return "Bu birim yalnızca HEAVY keyword'lü silah taşıyabilir ('%s' HEAVY değil)." % (atk_check.display_name if "display_name" in atk_check else "?")
		return ""

	var melee_hands := 0
	var ranged_hands := 0
	# STRONG: model bir adet 2H Melee silahını 1H gibi kuşanabilir (CUMBERSOME hariç,
	# compendium keyword.md). Yalnızca ilk uygun 2H Melee silaha uygulanır.
	var has_strong: bool = KeywordSystem.has(unit_data, &"strong")
	var strong_applied: bool = false
	for atk_res in unit_data.attacks:
		var atk: Resource = atk_res
		if atk == null:
			continue
		if atk.attack_type == "MELEE":
			var can_strong: bool = has_strong and not strong_applied
			var cost: int = melee_hand_cost(atk, can_strong)
			if can_strong and atk.hands == "2H" and not atk.is_cumbersome and cost == 1:
				strong_applied = true
			melee_hands += cost
		elif atk.attack_type == "RANGED" or atk.attack_type == "AREA":
			# GRENADES (battlekit/grenades.md) el gerektirmez — compendium onlara "Hands" vermez.
			if KeywordSystem.has(atk, &"grenade"):
				continue
			ranged_hands += (2 if atk.hands == "2H" else 1)
	if melee_hands > 2:
		return "Melee silah yükü 2 eli aşıyor (%d el)." % melee_hands
	if ranged_hands > 2:
		return "Ranged silah yükü 2 eli aşıyor (%d el)." % ranged_hands

	# HEAVY (compendium keyword.md): "A model cannot be equipped with more than one piece of
	# Battlekit with this Keyword." STRONG "Negate Heavy" verir → bu kısıt onlar için uygulanmaz.
	if not KeywordSystem.negates(unit_data, &"heavy"):
		var heavy_count := 0
		for atk_res2 in unit_data.attacks:
			if atk_res2 != null and KeywordSystem.has(atk_res2, &"heavy"):
				heavy_count += 1
		if heavy_count > 1:
			return "Birden fazla HEAVY silah taşınamıyor (%d adet)." % heavy_count

	return ""

## Bir MELEE saldırısının el bütçesinden ne kadar harcadığı. SAF fonksiyon.
##
## PISTOL İSTİSNASI (battlekit/ranged.md): Pistol "Range: 12\" / Melee", "Hands: 1 Hands (Ranged)"
## olarak tanımlıdır — TEK bir kalemdir ve melee'de de kullanılabilir. Bu projede iki AttackData
## ile modellenir (RANGED + MELEE eşi, bkz. weapon_keyword_test) ve el bütçesine YALNIZ BİR KEZ,
## RANGED tarafında sayılmalıdır. Aksi hâlde tabanca taşıyan her birim 1 fazla el harcar ve
## "Geçersiz silah ve teçhizat yüklemesi" hatası alır (kullanıcı bildirimi).
##
## can_use_strong: bu saldırıya STRONG uygulanabilir mi (model STRONG taşıyor VE henüz
## başka bir 2H melee'ye uygulanmadı).
static func melee_hand_cost(atk: Resource, can_use_strong: bool) -> int:
	if atk == null or atk.attack_type != "MELEE":
		return 0
	if KeywordSystem.has(atk, &"pistol"):
		return 0  # aynı fiziksel kalem, ranged tarafında sayıldı
	# DOĞUŞTAN (silahsız) SALDIRILAR — Crushing Blows, Iron Fists, Teeth and Claws, Poison
	# Stingers, Infected Proboscis, Feeble Flailing... Bunlar Battlekit DEĞİL, modelin kendi
	# bedenidir; compendium hepsini "even though it does not have a Melee Weapon" diye tanımlar.
	# Dolayısıyla el bütçesinden hiçbir şey harcamazlar.
	if KeywordSystem.has(atk, &"innate"):
		return 0
	if atk.hands != "2H":
		return 1
	# STRONG: bir adet 2H Melee silahı tek elle kuşanılabilir (CUMBERSOME hariç).
	if can_use_strong and not atk.is_cumbersome:
		return 1
	return 2

## FAZ 5 (P1-1): Seçilen Battlekit/loadout'u uygulayarak BİRİM-BAZINDA (paylaşılan .tres'i
## MUTASYONA UĞRATMADAN) yeni bir UnitData döndürür. loadout_index geçersizse (yok/aralık dışı)
## base'i OLDUĞU GİBİ döner — geriye dönük tam uyumlu, davranış değişmez.
## ÖNEMLİ: base.duplicate(true) DERİN kopya alır; her deploy'da tazedir, aynı unit tipinin başka
## bir kopyası bundan ETKİLENMEZ (attack_data.gd'nin kendi uyarısı: "paylaşılan .tres'i mutasyona
## uğratma" ilkesiyle birebir tutarlı).
static func resolve_loadout(base: Resource, loadout_index: int) -> Resource:
	if base == null or base.loadout_options == null or loadout_index < 0 \
			or loadout_index >= base.loadout_options.size():
		return base
	var opt: Resource = base.loadout_options[loadout_index]
	if opt == null:
		return base
	var dup: Resource = base.duplicate(true)
	if not opt.attacks_override.is_empty():
		dup.attacks = opt.attacks_override
	if opt.armour_override >= 0:
		dup.armour = opt.armour_override
	if opt.melee_dice_delta != 0:
		dup.melee_dice_modifier += opt.melee_dice_delta
	if opt.ranged_dice_delta != 0:
		dup.ranged_dice_modifier += opt.ranged_dice_delta
	if not opt.extra_keywords.is_empty():
		var kw: Dictionary = dup.keywords.duplicate()
		for k in opt.extra_keywords:
			kw[k] = opt.extra_keywords[k]
		dup.keywords = kw
	# SATIN ALINAN YETENEKLER (extra_abilities): Martyrdom Device'ın Trigger aksiyonu,
	# Court'un Goetic Power'ları. Birime gömülü DEĞİL — ücretli birer seçim.
	if not opt.extra_abilities.is_empty():
		var abs_merged: Array[Resource] = []
		for ab in dup.abilities:
			abs_merged.append(ab)
		for ab in opt.extra_abilities:
			if ab != null and not abs_merged.has(ab):
				abs_merged.append(ab)
		dup.abilities = abs_merged
	dup.cost += opt.cost_delta
	return dup

## UNARMED (battlekit/melee.md): yakın dövüş silahı olmayan model "Unarmed" dövüşür — profilsiz,
## ceza YOK (cezalı olan ayrı "Weakly Unarmed" girdisidir) ve "you can never fight with unarmed as
## an Off-Hand weapon". Önceden silahsız modeller (Sniper Priest, Artillery Witch...) hiç Fight
## yapamıyordu. Yakın dövüş silahı alınca Unarmed düşer. "No weapons" taşıyan model (Mendelist
## Ammo Monk: "has no weapons and therefore cannot attack") dövüşemez.
## Paylaşılan .tres'i değiştirmez: gerekiyorsa kopya döner, değilse aynısını.
const UNARMED_PATH := "res://assets/data/attacks/unarmed.tres"

static func with_unarmed(ud: Resource) -> Resource:
	if ud == null:
		return ud
	var has_weapon := false
	var has_unarmed := false
	for a in ud.attacks:
		if a == null or a.attack_type != "MELEE":
			continue
		if KeywordSystem.has(a, &"unarmed"):
			has_unarmed = true
		else:
			has_weapon = true
	var want_unarmed: bool = not has_weapon and not KeywordSystem.has(ud, &"no_weapons")
	if want_unarmed == has_unarmed:
		return ud
	var dup: Resource = ud.duplicate(true)
	var atks: Array[Resource] = []
	for a in ud.attacks:
		if a != null and not KeywordSystem.has(a, &"unarmed"):
			atks.append(a)
	if want_unarmed:
		atks.append(load(UNARMED_PATH))
	dup.attacks = atks
	return dup

## Bu silahla yapılan saldırıdan sonra kullanılabilecek Off-Hand silahı (yoksa null).
## ASSAULT BEAST (War Wolf): "attack once using either its Chainsaw Mouth or Shredding Claws, or
## twice, first with the Chainsaw Mouth and second with its Shredding Claws (the Off-Hand Weapon
## modifier applies to the attack made with the Shredding Claws)". Pençeler 2-El olduğu için genel
## 2x1H kuralı bu çifti hiç bulamıyordu — çift saldırı çalışmıyordu.
static func offhand_for(unit_data: Resource, used: Resource) -> Resource:
	if unit_data == null or used == null:
		return null
	if KeywordSystem.has(unit_data, &"assault_beast"):
		var first: Resource = null
		var second: Resource = null
		for a in unit_data.attacks:
			if a == null:
				continue
			var stem: String = a.resource_path.get_file().get_basename()
			if stem == "chainsaw_mouth":
				first = a
			elif stem == "shredding_claws":
				second = a
		return second if (used == first and second != null) else null
	var pair: Array = get_offhand_pair(unit_data)
	if pair.size() != 2 or not (used in pair):
		return null
	return pair[1] if pair[0] == used else pair[0]

## Multiple Melee Weapons: unit'in 2x1H Melee silahı varsa [ana_silah, off_hand_silah]
## döner (Fight action'ında ikinci saldırı Off-Hand modifikatörüyle yapılabilir).
## Yoksa boş dizi döner (tek silahlı Fight'a devam edilir).
static func get_offhand_pair(unit_data: Resource) -> Array:
	if unit_data == null:
		return []
	var melee_1h: Array = []
	for atk_res in unit_data.attacks:
		var atk: Resource = atk_res
		if atk != null and atk.attack_type == "MELEE" and atk.hands == "1H" \
				and not KeywordSystem.has(atk, &"unarmed"):
			melee_1h.append(atk)
	if melee_1h.size() >= 2:
		return [melee_1h[0], melee_1h[1]]
	return []
