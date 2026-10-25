extends RefCounted

## Bu oturumda bulunan/düzeltilen yetenek-mekanizma boşluklarını kilitler — SAF mantık
## (MechanicsResolver) ve orijinal 57 birimlik roster verisi düzeyinde.
##
## NOT (2026-07-15): kendi 3D modeli olmayan (başka unitlerin modelini ödünç alan) 23 varyant
## birim (Silahdar/Sipahi/Master Assassin/Dervish/Faris/Takwin Homunculus, Highland×3/Lector/
## Crimson Communicant/4 Dog, Executor/Ravenous/Cradle Ravenous/Desiccated Husk/Butcher Knight/
## Matagot Hag/Gregori Gula, Barbed Wire Banshee) kullanıcı isteğiyle SİLİNDİ — roster artık
## orijinal 57'ye döndü. O birimler için yazılmış veri testleri de kaldırıldı (test edilecek
## dosya kalmadı), ama onlar için eklenen KOD/ALTYAPI (Guard Dog predicate, No Retreat/Shock
## Charge/Frenzied Followers keyword mekanizmaları, add_infection generic effect_type) BİLİNÇLİ
## KORUNDU — ileride gerçek modelli birimler eklenince tekrar kullanılabilir.

func run(t) -> void:
	_test_guard_dog_predicate(t)
	_test_original_52_gap_fixes_data(t)

func _test_guard_dog_predicate(t) -> void:
	var far := Vector3(20, 0, 0)
	var near := Vector3(5, 0, 0)
	var origin := Vector3.ZERO
	t.ok(not MechanicsResolver.blocked_by_enemy_guard_dog(origin, [far], 12.0),
		"Guard Dog 12\" dışındaysa engellemez")
	t.ok(MechanicsResolver.blocked_by_enemy_guard_dog(origin, [near], 12.0),
		"Guard Dog 12\" içindeyse engeller")
	t.ok(not MechanicsResolver.blocked_by_enemy_guard_dog(origin, [], 12.0),
		"Guard Dog yoksa engellemez")

## Orijinal 52/57 birimlik roster'da bulunan, ability_id string'i hiçbir yerde geçmediği için
## "sessiz ölü pasif" olduğu doğrulanan (compendium'la karşılaştırılarak, farklı bir keyword'e
## bağlı OLMADIĞI teyit edilerek) 8 gerçek boşluk — artık kod+veri ile bağlı.
func _test_original_52_gap_fixes_data(t) -> void:
	var expectations := {
		"witchburner": &"dignified_conduct",
		"ecclesiastic_prisoner": &"negate_shrapnel",
		"communicant": &"negate_shrapnel",
		"anointed_heavy_infantry": &"negate_fire",
		"scripture_guardian": &"slow_dash",
		"artillery_witch": &"levitate",
		"lions_of_jabir": &"pin",
		"wretched": &"dark_blessing",
	}
	for f in expectations:
		var ud = load("res://assets/data/units/%s.tres" % f)
		t.ok(ud != null, "%s yüklenir" % f)
		if ud != null:
			t.ok(KeywordSystem.has(ud, expectations[f]), "%s: '%s' keyword'ü var" % [f, expectations[f]])
