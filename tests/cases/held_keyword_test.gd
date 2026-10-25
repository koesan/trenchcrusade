extends RefCounted

## `[Held]` KEYWORD'Ü — el bütçesi (compendium denetimi, Adım 5).
##
## `comprehensive-rules/keyword.md`:
## > "A piece of Battlekit with this Keyword requires one hand to carry and **cannot be put
## > down**. Because of this, a model that has this Keyword can only be equipped with or use
## > either a 1-Handed Weapon or a Shield. It cannot be equipped with or use any 2-Handed
## > Weapons, or both a Weapon and a Shield (even if the Shield has the Shield Combo rule).
## > It may still carry Grenades."
##
## KURAL BOŞLUĞU: keyword VERİDE vardı (`troop_flag`, `musical_instrument` kalemleri modele
## `&"held"` veriyor) ama KURAL motorda hiç yoktu. Sancak/enstrüman taşıyan bir model 2-El silah
## da kuşanabiliyor, hem silah hem kalkan da alabiliyordu — yani kalemi elinden bırakmış gibi
## davranıyordu.
##
## ÇÖZÜMÜN ÖZÜ: kalem elden bırakılamadığı için BİR EL KALICI olarak doludur → el bütçesi 2
## yerine 1. Bu tek değişiklik RAW'ın üç yasağını da üretir (aşağıda tek tek doğrulanıyor).

const ArmouryRules = preload("res://scripts/rules/armoury_rules.gd")
const UnitData = preload("res://scripts/data/unit_data.gd")

func _unit(keywords: Dictionary) -> Resource:
	var u := UnitData.new()
	u.keywords = keywords
	return u

func run(t) -> void:
	# ── Bütçe: [Held] varsa 1, yoksa 2 ──────────────────────────────────
	t.eq(ArmouryRules.hand_budget(_unit({})), 2, "Normal model: 2 el")
	t.eq(ArmouryRules.hand_budget(_unit({&"held": 1})), 1,
		"[Held] taşıyan model: 1 el (kalem elden bırakılamaz)")
	t.eq(ArmouryRules.hand_budget(null), 2, "unit_data yoksa güvenli varsayılan 2")

	# ── RAW'ın üç yasağı bütçeden doğal olarak çıkıyor mu? ───────────────
	var held_budget: int = ArmouryRules.hand_budget(_unit({&"held": 1}))
	t.ok(2 > held_budget, "2-El silah [Held] ile alınamaz (2 > %d)" % held_budget)
	t.ok(1 + 1 > held_budget, "Silah + kalkan birlikte alınamaz (1+1 > %d)" % held_budget)
	t.ok(1 <= held_budget, "Tek 1-El silah VEYA tek kalkan alınabilir (1 <= %d)" % held_budget)
	# Bombalar `hands = 0` taşır ve el kapısına hiç girmez — RAW: "It may still carry Grenades."
	t.ok(0 <= held_budget, "Bombalar serbest (0 el)")

	# ── Kapı gerçekten bütçeyi kullanıyor mu? ───────────────────────────
	# Sabit `> 2` karşılaştırması geri gelirse kural sessizce ölür.
	var src := FileAccess.get_file_as_string("res://scripts/rules/armoury_rules.gd")
	t.ok(src.contains("hand_budget(unit_data, melee)"),
		"El kapısı sabit 2 yerine hand_budget() kullanıyor")
	t.ok(not src.contains("+ item.hands > 2"),
		"Sabit 2 el karşılaştırması kalmadı")

	# ── Veri tarafı: [Held] kalemler gerçekten işaretli mi? ──────────────
	# Kural ile veri birbirine bağlı; biri olmadan diğeri işe yaramaz. Compendium'da bu iki
	# kalem `[Held]` taşır (equipment.md: Musical Instrument, Troop Flag).
	var expected := {
		"troop_flag": "Troop Flag",
		"musical_instrument": "Musical Instrument",
	}
	for item_id in expected:
		var path := "res://assets/data/armoury/%s.tres" % item_id
		var txt := FileAccess.get_file_as_string(path)
		t.ok(txt != "", "%s.tres okunabildi" % item_id)
		t.ok(txt.contains("&\"held\": 1"),
			"%s modele [Held] veriyor (compendium: %s)" % [item_id, expected[item_id]])
		# `[Held]` kalemin KENDİ `hands` alanı 0 olmalı: eli bütçe düşürerek hesaba katıyoruz,
		# ayrıca `hands`ten de saymak aynı eli İKİ KEZ harcardı.
		t.ok(txt.contains("hands = 0"),
			"%s kendi `hands` alanını 0 tutuyor (el bütçeden düşülüyor)" % item_id)
