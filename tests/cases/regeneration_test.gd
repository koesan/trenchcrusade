extends RefCounted

## P0-6 regresyon kilidi: REGENERATE(X) artık X-değerini yok saymıyor.
## MechanicsResolver.compute_regeneration saf/testli — unit.gd::set_selected bu sonucu kullanır.

func run(t) -> void:
	# Eski veri: has_regeneration=true, keywords'te "regenerate" yok → X=1 varsayılan (geriye dönük uyumlu)
	var legacy_ud := UnitData.new()
	legacy_ud.has_regeneration = true
	t.eq(MechanicsResolver.compute_regeneration(legacy_ud, 3), 1,
		"has_regeneration=true, regenerate keyword yok → X=1 varsayılan")
	t.eq(MechanicsResolver.compute_regeneration(legacy_ud, 0), 0,
		"Kan İşareti yoksa Regenerate hiçbir şey temizlemez")

	# Yeni veri: keywords[&"regenerate"]=3 → X'i onurlandırır
	var x_ud := UnitData.new()
	x_ud.keywords = {&"regenerate": 3}
	t.eq(MechanicsResolver.compute_regeneration(x_ud, 5), 3,
		"regenerate=3 keyword'ü → 3 Kan İşareti temizlenir (X onurlandırılıyor)")
	t.eq(MechanicsResolver.compute_regeneration(x_ud, 2), 2,
		"regenerate=3 ama sadece 2 Kan İşareti varsa → yalnız 2 temizlenir (mevcutla sınırlı)")

	# Regenerate'i olmayan birim hiç temizlemez
	var none_ud := UnitData.new()
	t.eq(MechanicsResolver.compute_regeneration(none_ud, 4), 0,
		"Regenerate keyword'ü/bool'u olmayan birim → 0")

	# Gerçek roster verisi: Stigmatic Nun/Communicant/Communicant ATH → Regenerate 1
	for unit_path in ["stigmatic_nun", "communicant", "communicant_anti_tank_hunter"]:
		var ud = load("res://assets/data/units/" + unit_path + ".tres")
		t.eq(MechanicsResolver.compute_regeneration(ud, 4), 1,
			unit_path + " (compendium'da Regenerate 1) → aktivasyon başına 1 Kan İşareti temizler")
