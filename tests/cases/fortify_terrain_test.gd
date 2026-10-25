extends RefCounted

## Siper (trench.glb) sahada HAZIR BULUNMAZ — Fortify / Dug In yeteneklerinin görsel ve
## mekanik karşılığıdır.
##
## KURAL KAYNAĞI:
##   Fortify (new-antioch.md Combat Engineer / iron-sultanate.md Sultanate Sapper):
##     "take a [Risky Success] Roll... If Success or Critical Success, the model has the
##      [Cover] Keyword UNTIL THEY MOVE AWAY from their current position."
##   Dug In (battlekit Shovel):
##     "a model equipped with a Shovel that STARTS THE GAME on Open terrain has the [Cover]
##      Keyword until it moves away from its starting position."
##
## Compendium'da "bu senaryoda siper vardır" diye bir kural YOKTUR. Önceki turda senaryolara
## 5'er siper otomatik yerleştirilmişti — bu kaynaksız bir eklemeydi ve geri alındı.

func run(t) -> void:
	run_permanence(t)
	# ── Senaryolarda otomatik siper OLMAMALI ───────────────────────────────
	for sc_name in ["great_war", "fields_of_glory", "marked_for_death", "relic_hunt",
			"the_high_ground", "claim_no_mans_land"]:
		var path := "res://assets/data/scenarios/%s.tres" % sc_name
		if not ResourceLoader.exists(path):
			continue
		var sc: Resource = load(path)
		t.eq(sc.terrain_placements.size(), 0,
			"%s → senaryoda otomatik siper YOK (siper Fortify/Dug In ile kurulur)" % sc_name)

	# ── Fortify / Dug In taşıyan birimler ──────────────────────────────────
	for name in ["new_antioch_combat_engineer", "sultanate_sapper"]:
		var ud: Resource = load("res://assets/data/units/%s.tres" % name)
		t.ok(ud != null, "%s yüklendi" % name)
		if ud == null:
			continue
		var ids: Array = []
		for ab in ud.abilities:
			if ab != null:
				ids.append(ab.ability_id)
		t.ok(ids.has(&"fortify"), "%s → Fortify yeteneği" % name)
		t.ok(KeywordSystem.has(ud, &"dug_in"), "%s → Dug In (Shovel)" % name)

	# ── FortifyActions siperi TerrainManager'a ekler ve [Cover] verir ──────
	TerrainManager.clear_all()
	t.eq(TerrainManager.feature_count(), 0, "Başlangıçta sahada arazi parçası yok")
	t.ok(FortifyActions.TRENCH_FEATURE != null, "FortifyActions siper tanımını yüklüyor")
	t.ok(KeywordSystem.has(FortifyActions.TRENCH_FEATURE, &"cover"),
		"Fortify'ın kurduğu parça [Cover] taşır")

	# ── Siper konumu ve [Cover] kontrolü ───────────────────────────────────
	TerrainManager.spawn_feature(FortifyActions.TRENCH_FEATURE, Vector3(4, 0, 4), "Engineer1")
	TerrainManager.spawn_feature(FortifyActions.TRENCH_FEATURE, Vector3(-9, 0, 0), "Sapper2")
	t.eq(TerrainManager.feature_count(), 2, "İki mevzi kazıldı")
	t.eq(TerrainManager.has_keyword_at(Vector3(4, 0, 4), &"cover"), true,
		"Engineer1'in mevzisi [Cover] veriyor")
	t.eq(TerrainManager.has_keyword_at(Vector3(-9, 0, 0), &"cover"), true,
		"Sapper2'nin mevzisi [Cover] veriyor")

	# ── Siper KALICI — clear_all harici yollarla SİLİNMEZ ────────────────
	# Compendium: birim hareket edince yalnız has_fortify_cover bayrağı düşer,
	# kazılan siper SAHADA KALIR. remove_by_setter gibi silme fonksiyonları kaldırıldı.
	TerrainManager.clear_all()
	t.eq(TerrainManager.feature_count(), 0, "clear_all temizler")

## KAZILAN MEVZİ KALICIDIR (kullanıcı bildirimi: "tekrar tahkim et deyince eski tahkim
## gidiyor ve yeni yere ışınlanıyor"). Kazılmış toprak sahada durur; birim uzaklaşınca
## yalnız [Cover] AVANTAJINI kaybeder.
func run_permanence(t) -> void:
	TerrainManager.clear_all()
	var f: Node = TerrainManager.spawn_feature(
		load("res://assets/data/terrain/trench.tres"), Vector3(0, 0, 0), "Sapper")
	t.ok(f != null, "İlk mevzi kazıldı")
	t.eq(TerrainManager.features.size(), 1, "Sahada 1 mevzi var")

	# İkinci Fortify → sahaya YENİ mevzi eklenir, eskisi yerinde kalır (ışınlanmaz)
	TerrainManager.spawn_feature(
		load("res://assets/data/terrain/trench.tres"), Vector3(6, 0, 0), "Sapper")
	t.eq(TerrainManager.features.size(), 2,
		"İkinci Fortify YENİ mevzi ekler — eskisi yerinde kalır, ışınlanmaz")

	# Modelin tabanı zemine oturur (haritanın içine gömülmez)
	t.ok(f.has_method("_lowest_point"), "Arazi parçası zemine oturtma mantığını taşıyor")
	t.ok(f.global_position.y >= -0.01, "Mevzi haritanın ÜSTÜNDE duruyor (y >= 0)")
	TerrainManager.clear_all()
