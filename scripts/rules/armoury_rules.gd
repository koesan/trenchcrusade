## ArmouryRules — Battlekit satın alma kuralları. STATELESS ve SAF (mechanics_resolver deseni).
##
## KURAL KAYNAĞI
## * warbands/<faction>#Armoury — bir model YALNIZCA kendi faksiyonunun Armoury Tablosundaki
##   kalemleri alabilir; tablo fiyatı, `LIMIT: N` (warband başına) ve kısıtları belirtir.
## * model-battlekit.md — "A model can carry at most one 2-Handed weapon OR two 1-Handed weapons
##   in each category (Melee and Ranged are counted separately)."
## * keyword.md `[Heavy]` — "A model cannot be equipped with more than one piece of Battlekit
##   with this Keyword."
## * Bir model tek bir Zırh giyer; Kalkan bir el işgal eder.
##
## Karar mantığı burada; veri `ArmouryItem`'da; ekran `armoury_panel.gd`'de. Panel de deploy
## akışı da AYNI `check()`'i çağırır — görsel kuralla çelişemez (DeployAvailability ile aynı ilke).
class_name ArmouryRules

const REASON_NOT_IN_TABLE := "ARM_FAIL_NOT_IN_TABLE"
const REASON_ELITE_ONLY := "ARM_FAIL_ELITE_ONLY"
const REASON_UNIT_ONLY := "ARM_FAIL_UNIT_ONLY"
const REASON_KEYWORD := "ARM_FAIL_KEYWORD"
const REASON_REQUIRES_ITEM := "ARM_FAIL_REQUIRES_ITEM"
const REASON_LIMIT := "ARM_FAIL_LIMIT"
const REASON_ALREADY_OWNED := "ARM_FAIL_ALREADY_OWNED"
const REASON_HANDS := "ARM_FAIL_HANDS"
const REASON_ARMOUR := "ARM_FAIL_ARMOUR"
const REASON_HEAVY := "ARM_FAIL_HEAVY"
const REASON_BUDGET := "ARM_FAIL_BUDGET"
const REASON_GLORY := "ARM_FAIL_GLORY"
const REASON_UNIT_RULE := "ARM_FAIL_UNIT_RULE"
const REASON_GRENADE := "ARM_FAIL_GRENADE"
const REASON_HEADGEAR := "ARM_FAIL_HEADGEAR"

const ALL_REASONS := [
	REASON_NOT_IN_TABLE, REASON_ELITE_ONLY, REASON_UNIT_ONLY, REASON_KEYWORD,
	REASON_REQUIRES_ITEM, REASON_LIMIT, REASON_ALREADY_OWNED, REASON_HANDS,
	REASON_ARMOUR, REASON_HEAVY, REASON_BUDGET, REASON_GLORY, REASON_UNIT_RULE, REASON_GRENADE, REASON_HEADGEAR,
]

## Kategori başlıkları — UI sekmelerinde bu sırayla gösterilir (compendium tablo sırası).
const CATEGORY_KEYS := [
	"ARM_CAT_MELEE", "ARM_CAT_RANGED", "ARM_CAT_GRENADE",
	"ARM_CAT_ARMOUR", "ARM_CAT_SHIELD", "ARM_CAT_EQUIPMENT",
]

## Faksiyonun Armoury Tablosu (boşsa boş dizi — çağıran taraf null kontrolü yapmak zorunda kalmaz).
static func table_for(faction: Resource) -> Array:
	if faction == null or not ("armoury" in faction):
		return []
	var out: Array = []
	for it in faction.armoury:
		if it != null:
			out.append(it)
	return out

## Tabloyu kategoriye göre gruplar: {kategori_indeksi: [ArmouryItem, ...]}
static func by_category(faction: Resource) -> Dictionary:
	var groups: Dictionary = {}
	for it in table_for(faction):
		var c: int = int(it.category)
		if not groups.has(c):
			groups[c] = []
		groups[c].append(it)
	return groups

## Bir modelin ŞU AN kullandığı el sayısı (kategori bazında).
## Satın alınan silahlar `unit_data.attacks`'e eklendiği için tek kaynaktan sayılır.
static func hands_used(unit_data: Resource, melee: bool) -> int:
	if unit_data == null:
		return 0
	var total := 0
	var has_strong: bool = KeywordSystem.has(unit_data, &"strong")
	var strong_applied := false
	for atk in unit_data.attacks:
		if atk == null:
			continue
		if melee and atk.attack_type == "MELEE":
			var can_strong: bool = has_strong and not strong_applied
			var c: int = LoadoutResolver.melee_hand_cost(atk, can_strong)
			if can_strong and atk.hands == "2H" and not atk.is_cumbersome and c == 1:
				strong_applied = true
			total += c
		elif not melee and (atk.attack_type == "RANGED" or atk.attack_type == "AREA"):
			total += (2 if atk.hands == "2H" else 1)
	# Kalkan HER İKİ bağlamda da bir el tutar (battlekit/shield.md: "1 Hands (Ranged)
	# 1 Hands (Melee)") — bkz. `shield_hand_cost`.
	return total + shield_hand_cost(unit_data)

## Modelin taşıdığı KALKANIN el maliyeti — 1, `[Shield Combo]` muafiyeti varsa 0.
##
## ⚠ İKİ KURAL BOŞLUĞU (compendium denetimi, Adım 6), ikisi iç içe:
##
## 1) SATIN ALINAN KALKANIN ELİ HİÇ SAYILMIYORDU. `hands_used()` yalnız `unit_data.attacks`i
##    geziyor; kalkan bir SALDIRI değil, modele `&"shield"` veren bir Battlekit kalemidir ve
##    `granted_attacks` listesi boştur. Kalkanın `hands = 1` alanı yalnız SATIN ALMA ANINDA
##    kontrol ediliyordu. Sonuç: önce kalkan al (0+1 ≤ 2 geçer), sonra 2-El silah al
##    (hands_used = 0 → 0+2 ≤ 2 geçer) → model 3 EL kullanır hâle geliyordu.
##
## 2) `[Shield Combo]` UYGULANMIYORDU. keyword.md:
##    > "For the purposes of wielding a 2-handed weapon with the 'Shield Combo' indicator, the
##    > Trench Shield does not take a hand to wield but still functions as normal."
##    Oyunda bu göstergeyi taşıyan DOKUZ silah var (putrid_shotgun, heavy_shotgun, polearm…).
##
## İkisi BİRLİKTE düzeltilmeli: yalnız (1) düzeltilirse, kuralın AÇIKÇA izin verdiği
## "Shield Combo 2-El silah + kalkan" kuşanımı yanlışlıkla engellenirdi.
##
## `incoming`: satın alınmak ÜZERE olan kalem. Muafiyet, henüz `attacks`e girmemiş olan bu
## kalemin vereceği silahlar için de değerlendirilir — aksi hâlde kalkanı olan bir modele
## Shield Combo silahı satılamazdı (sıraya bağlı, tutarsız sonuç).
static func shield_hand_cost(unit_data: Resource, incoming: Resource = null) -> int:
	if unit_data == null or not KeywordSystem.has(unit_data, &"shield"):
		return 0
	if _has_shield_combo_2h(unit_data.attacks):
		return 0
	if incoming != null and "granted_attacks" in incoming \
			and _has_shield_combo_2h(incoming.granted_attacks):
		return 0
	return 1

static func _has_shield_combo_2h(attacks: Array) -> bool:
	for atk in attacks:
		if atk != null and atk.hands == "2H" and KeywordSystem.has(atk, &"shield_combo"):
			return true
	return false

## Modelin EL BÜTÇESİ — normalde 2, `[Held]` bir Battlekit taşıyorsa 1.
##
## COMPENDIUM (`comprehensive-rules/keyword.md`, HELD):
## > "A piece of Battlekit with this Keyword requires one hand to carry and **cannot be put
## > down**. Because of this, a model that has this Keyword can only be equipped with or use
## > either a 1-Handed Weapon or a Shield. It cannot be equipped with or use any 2-Handed
## > Weapons, or both a Weapon and a Shield (even if the Shield has the Shield Combo rule).
## > It may still carry Grenades."
##
## ⚠ KURAL BOŞLUĞU (compendium denetimi, Adım 5): `[Held]` kod tabanında HİÇ geçmiyordu.
## Sancak/enstrüman taşıyan bir model 2-El silah da kuşanabiliyor, hem silah hem kalkan da
## alabiliyordu — yani kalemi elinden bırakmış gibi davranıyordu.
##
## KURALIN TEK SATIRA İNDİRGENMESİ: kalem elden bırakılamadığı için BİR EL KALICI olarak
## doludur. Bütçeyi 1'e çekmek RAW'ın üç yasağını da tek başına üretir:
##   • 2-El silah   → 2 > 1 ................ reddedilir
##   • silah+kalkan → 1+1 = 2 > 1 .......... reddedilir
##   • tek 1-El silah VEYA tek kalkan → 1 ≤ 1  izinli
## Bombalar (`hands = 0`) bu kapıya hiç girmez — RAW'ın "It may still carry Grenades" maddesi.
##
## NOT: `hands_used()` yalnız `unit_data.attacks`i sayar; `[Held]` kalem bir saldırı DEĞİLDİR,
## bu yüzden onun eli oradan görünmez. Bütçeyi düşürmek o eli doğru biçimde hesaba katar.
static func hand_budget(unit_data: Resource, melee: bool = true) -> int:
	if unit_data != null and KeywordSystem.has(unit_data, &"held"):
		return 1
	if melee and unit_data != null and "battlekit_rules" in unit_data \
			and unit_data.battlekit_rules.has("melee_hand_budget"):
		return int(unit_data.battlekit_rules["melee_hand_budget"])
	return 2

## Modelin taşıdığı `[Heavy]` Battlekit sayısı.
static func heavy_count(unit_data: Resource) -> int:
	if unit_data == null:
		return 0
	var n := 0
	for atk in unit_data.attacks:
		if atk != null and KeywordSystem.has(atk, &"heavy"):
			n += 1
	if KeywordSystem.has(unit_data, &"carries_heavy_gear"):
		n += 1
	return n

## "Bu model bu kalemi alabilir mi?" — TEK KAYNAK.
##
## warband_owned : {item_id: adet} — warband genelinde alınmış kalemler (LIMIT için)
## unit_owned    : [item_id, ...]  — BU modele alınmış kalemler (tekrar/ön koşul için)
## Döndürür: "" = alınabilir; dolu string = ret sebebinin lokalizasyon anahtarı.
static func check(item: Resource, unit_data: Resource, faction: Resource,
		warband_owned: Dictionary, unit_owned: Array, ducat_pool: int, glory_pool: int) -> String:
	if item == null or unit_data == null:
		return REASON_NOT_IN_TABLE

	# 1) Faksiyon tablosu üyeliği — "A model can have any Battlekit from the X Armoury Tables."
	if not (item in table_for(faction)):
		return REASON_NOT_IN_TABLE

	# 2) "Elite only"
	if item.elite_only and not KeywordSystem.has(unit_data, &"elite"):
		return REASON_ELITE_ONLY

	# 3) "<Birim> only"
	if not item.required_unit_names.is_empty() \
			and not (unit_data.unit_name in item.required_unit_names):
		return REASON_UNIT_ONLY

	# 4) "BAYONET LUG only" — modelin taşıdığı silahlardan biri anahtar kelimeyi taşımalı
	for kw in item.required_keywords:
		if not _unit_or_weapons_have(unit_data, kw):
			return REASON_KEYWORD

	# 5) "Machine Armour only" — önce başka bir kalem alınmış olmalı
	if item.required_item_id != &"" and not (item.required_item_id in unit_owned):
		return REASON_REQUIRES_ITEM

	# 6) Aynı kalem bir modele iki kez takılmaz (Grail Devotee gibi istifleneni compendium
	#    ayrıca belirtir; oyunda tekil tutulur).
	if item.item_id in unit_owned:
		return REASON_ALREADY_OWNED

	# 6b) Birime özel Battlekit paragrafı (Thrall "cannot have any Battlekit", Wretched "costs
	#     up to 10", Death Commando "the only Ranged Weapons they can have are..." vb.)
	var rule_reason := battlekit_rule_reason(item, unit_data)
	if rule_reason != "":
		return rule_reason

	# 6c) "One type of Grenade" (model-battlekit.md, Battlekit Limits)
	if item.category == ArmouryItem.Category.GRENADE and _has_grenade(unit_data):
		return REASON_GRENADE

	# 6d) Headgear — modelde en fazla bir parça
	if item.is_headgear and table_for(faction).any(
			func(it): return it != null and it.is_headgear and it.item_id in unit_owned):
		return REASON_HEADGEAR

	# 7) `LIMIT: N` — warband başına üst sınır
	if item.limit_per_warband > 0 \
			and int(warband_owned.get(item.item_id, 0)) >= item.limit_per_warband:
		return REASON_LIMIT

	# 8) Zırh: bir model tek bir Zırh giyer
	if item.category == ArmouryItem.Category.ARMOUR:
		if unit_data.armour >= item.armour_value:
			return REASON_ARMOUR

	# 9) El bütçesi (model-battlekit.md) — silahlar ve kalkanlar
	if item.hands > 0:
		var melee: bool = item.category == ArmouryItem.Category.MELEE \
			or item.category == ArmouryItem.Category.SHIELD
		# Kalkan eli, ALINMAK ÜZERE olan kalem de hesaba katılarak değerlendirilir
		# (bkz. `shield_hand_cost` — Shield Combo muafiyeti sıraya bağlı olmamalı).
		var used: int = hands_used(unit_data, melee) \
			- shield_hand_cost(unit_data) + shield_hand_cost(unit_data, item)
		if used + item.hands > hand_budget(unit_data, melee):
			return REASON_HANDS

	# 10) `[Heavy]` — model birden fazla Heavy Battlekit taşıyamaz (STRONG bunu iptal eder)
	if _grants_heavy(item) and not KeywordSystem.negates(unit_data, &"heavy") \
			and heavy_count(unit_data) >= 1:
		return REASON_HEAVY

	# 11) Bütçe — Glory ve ducat AYRI havuzlardır
	if item.cost_currency == ArmouryItem.Currency.GLORY:
		if glory_pool < item.cost:
			return REASON_GLORY
	elif ducat_pool < item.cost:
		return REASON_BUDGET

	return ""

## Birimin `battlekit_rules` kısıtı bu kalemi engelliyor mu? "" = hayır.
static func battlekit_rule_reason(item: Resource, unit_data: Resource) -> String:
	if not ("battlekit_rules" in unit_data):
		return ""
	var r: Dictionary = unit_data.battlekit_rules
	if r.is_empty():
		return ""
	var id: StringName = item.item_id
	var cat: int = int(item.category)
	if r.get("none", false):
		return REASON_UNIT_RULE
	if id in r.get("forbid", []):
		return REASON_UNIT_RULE
	var whitelisted: bool = id in r.get("items", [])
	if r.has("categories") and not whitelisted and not (cat in r["categories"]):
		return REASON_UNIT_RULE
	if r.has("max_cost") and item.cost > int(r["max_cost"]):
		return REASON_UNIT_RULE
	if cat == ArmouryItem.Category.RANGED:
		if r.has("ranged_only") and not (id in r["ranged_only"]):
			return REASON_UNIT_RULE
		if r.has("ranged_max_cost") and item.cost > int(r["ranged_max_cost"]):
			return REASON_UNIT_RULE
		if r.has("max_ranged") and _ranged_weapon_count(unit_data) >= int(r["max_ranged"]):
			return REASON_UNIT_RULE
	if cat == ArmouryItem.Category.GRENADE and r.has("grenade_only") and not (id in r["grenade_only"]):
		return REASON_UNIT_RULE
	if r.get("heavy_weapons_only", false) and cat <= ArmouryItem.Category.GRENADE \
			and not _grants_heavy(item):
		return REASON_UNIT_RULE
	return ""

static func _ranged_weapon_count(unit_data: Resource) -> int:
	var n := 0
	for atk in unit_data.attacks:
		if atk != null and atk.attack_type == "RANGED" and not KeywordSystem.has(atk, &"grenade"):
			n += 1
	return n

static func _has_grenade(unit_data: Resource) -> bool:
	for atk in unit_data.attacks:
		if atk != null and KeywordSystem.has(atk, &"grenade"):
			return true
	return false

## Warband'daki SİLAH kalemlerinin adedi — hazır kitler de dahil (`LIMIT: N` sayımı için).
## Silah kalemleri modele saldırı profili olarak eklendiği için profil üzerinden sayılır; böylece
## hazır kitteki ile sonradan satın alınan Machine Gun aynı sayaçta toplanır.
## `unit_datas`: oyuncunun sahadaki birimlerinin UnitData'ları.
static func weapon_counts(unit_datas: Array, faction: Resource) -> Dictionary:
	var counts: Dictionary = {}
	var table := table_for(faction)
	for ud in unit_datas:
		if ud == null:
			continue
		var paths: Array = []
		for a in ud.attacks:
			if a != null:
				paths.append(a.resource_path)
		for it in table:
			if it.granted_attacks.is_empty() or it.granted_attacks[0] == null:
				continue
			if it.granted_attacks[0].resource_path in paths:
				counts[it.item_id] = int(counts.get(it.item_id, 0)) + 1
	return counts

## Satın alınan kalemi modele uygular ve YENİ bir UnitData döndürür.
## Paylaşılan `.tres` ASLA mutasyona uğratılmaz (attack_data.gd'nin kendi uyarısıyla tutarlı).
static func apply(unit_data: Resource, item: Resource) -> Resource:
	if unit_data == null or item == null:
		return unit_data
	var dup: Resource = unit_data.duplicate(true)
	if not item.granted_attacks.is_empty():
		var atks: Array[Resource] = []
		for a in dup.attacks:
			atks.append(a)
		for a in item.granted_attacks:
			if a != null:
				atks.append(a)
		dup.attacks = atks
	if item.armour_value > 0:
		dup.armour = max(dup.armour, item.armour_value)
	if not item.granted_keywords.is_empty():
		var kw: Dictionary = dup.keywords.duplicate()
		for k in item.granted_keywords:
			kw[k] = item.granted_keywords[k]
		dup.keywords = kw
	dup.cost += item.cost
	return dup

## Kalemin oyuncuya gösterilecek fiyat para birimi anahtarı (metin koda gömülmez).
static func currency_key(item: Resource) -> String:
	if item != null and item.cost_currency == ArmouryItem.Currency.GLORY:
		return "CURRENCY_GLORY"
	return "CURRENCY_DUCAT"

static func _grants_heavy(item: Resource) -> bool:
	if item.granted_keywords.has(&"heavy"):
		return true
	for a in item.granted_attacks:
		if a != null and KeywordSystem.has(a, &"heavy"):
			return true
	return false

static func _unit_or_weapons_have(unit_data: Resource, kw: StringName) -> bool:
	if KeywordSystem.has(unit_data, kw):
		return true
	for a in unit_data.attacks:
		if a != null and KeywordSystem.has(a, kw):
			return true
	return false
