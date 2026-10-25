extends RefCounted

## KALKAN EL EKONOMİSİ + `[Shield Combo]` (compendium denetimi, Adım 6).
##
## `battlekit/shield.md`: her kalkan "1 Hands (Ranged) 1 Hands (Melee)" taşır — yani kalkan
## HER İKİ bağlamda da bir el tutar.
##
## `comprehensive-rules/keyword.md` (SHIELD COMBO):
## > "For the purposes of wielding a 2-handed weapon with the 'Shield Combo' indicator, the
## > Trench Shield does not take a hand to wield but still functions as normal."
##
## İKİ İÇ İÇE KURAL BOŞLUĞU:
##  1. Satın alınan kalkanın eli SATIN ALMA SONRASI hiç sayılmıyordu. `hands_used()` yalnız
##     `unit_data.attacks`i gezer; kalkan bir saldırı değil, `granted_attacks` listesi boş bir
##     kalemdir. Sonuç: önce kalkan al (0+1 <= 2 geçer), sonra 2-El silah al (0+2 <= 2 geçer)
##     → model ÜÇ EL kullanır hâle geliyordu.
##  2. `[Shield Combo]` hiç uygulanmıyordu (oyunda bu göstergeyi taşıyan 9 silah var).
##
## İkisi BİRLİKTE düzeltilmeli: yalnız (1) düzeltilseydi kuralın AÇIKÇA izin verdiği
## "Shield Combo 2-El silah + kalkan" kuşanımı yanlışlıkla engellenirdi.

const ArmouryRules = preload("res://scripts/rules/armoury_rules.gd")
const UnitData = preload("res://scripts/data/unit_data.gd")
const AttackData = preload("res://scripts/data/attack_data.gd")

func _atk(hands: String, combo: bool) -> Resource:
	var a := AttackData.new()
	a.attack_type = "MELEE"
	a.hands = hands
	if combo:
		a.keywords[&"shield_combo"] = 1
	return a

func _unit(has_shield: bool, attacks: Array) -> Resource:
	var u := UnitData.new()
	if has_shield:
		u.keywords[&"shield"] = 1
	u.attacks.assign(attacks)
	return u

func run(t) -> void:
	# ── Kalkan bir el tutar ─────────────────────────────────────────────
	t.eq(ArmouryRules.shield_hand_cost(_unit(false, [])), 0, "Kalkansız model: 0 el")
	t.eq(ArmouryRules.shield_hand_cost(_unit(true, [])), 1, "Kalkanlı model: kalkan 1 el tutar")
	t.eq(ArmouryRules.shield_hand_cost(null), 0, "unit_data yoksa 0 (güvenli)")

	# ── [Shield Combo]: 2-El silah varsa kalkan el TÜKETMEZ ─────────────
	t.eq(ArmouryRules.shield_hand_cost(_unit(true, [_atk("2H", true)])), 0,
		"Shield Combo 2-El silah → kalkan el tutmaz")
	t.eq(ArmouryRules.shield_hand_cost(_unit(true, [_atk("2H", false)])), 1,
		"Shield Combo OLMAYAN 2-El silah → kalkan yine 1 el tutar")
	t.eq(ArmouryRules.shield_hand_cost(_unit(true, [_atk("1H", true)])), 1,
		"Shield Combo yalnız 2-EL silahta muafiyet verir (1-El'de hayır)")

	# ── Toplam el sayımı kalkanı içeriyor mu? ───────────────────────────
	# Boşluğun özü buydu: kalkan `attacks` içinde olmadığı için hiç görünmüyordu.
	t.eq(ArmouryRules.hands_used(_unit(true, []), true), 1,
		"Silahsız + kalkanlı model 1 el kullanıyor (kalkan artık sayılıyor)")
	t.eq(ArmouryRules.hands_used(_unit(false, []), true), 0, "Silahsız + kalkansız: 0 el")
	# Kalkan + Shield Combo 2-El silah = tam olarak 2 el (kalkan bedava) → yasal.
	t.eq(ArmouryRules.hands_used(_unit(true, [_atk("2H", true)]), true), 2,
		"Kalkan + Shield Combo 2-El silah = 2 el (kuralın izin verdiği kuşanım)")
	# Kalkan + normal 2-El silah = 3 el → bütçeyi aşar, yasa dışı.
	t.ok(ArmouryRules.hands_used(_unit(true, [_atk("2H", false)]), true)
			> ArmouryRules.hand_budget(_unit(true, [])),
		"Kalkan + normal 2-El silah bütçeyi AŞIYOR (eskiden sessizce geçiyordu)")

	# ── Veri: Shield Combo göstergesi gerçekten silahlarda mı? ──────────
	var dir := DirAccess.open("res://assets/data/attacks")
	t.ok(dir != null, "attacks dizini okunabildi")
	var combo_count := 0
	if dir != null:
		for f in dir.get_files():
			if f.ends_with(".tres") and FileAccess.get_file_as_string(
					"res://assets/data/attacks/" + f).contains("shield_combo"):
				combo_count += 1
	t.ok(combo_count >= 5,
		"Veride [Shield Combo] taşıyan silahlar var (%d) — kural ölü değil" % combo_count)

	# ── Trench Shield kalemi compendium değerleriyle uyumlu mu? ─────────
	var ts := FileAccess.get_file_as_string("res://assets/data/armoury/trench_shield.tres")
	t.ok(ts.contains("armour_value = 1"), "Trench Shield: [-1 Injury Modifier] (armour 1)")
	t.ok(ts.contains("hands = 1"), "Trench Shield: 1 el")
	t.ok(ts.contains("&\"shield\": 1"), "Trench Shield modele [Shield] veriyor (el sayımının anahtarı)")
