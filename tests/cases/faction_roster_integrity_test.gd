extends RefCounted

## VERİ BÜTÜNLÜĞÜ KİLİDİ (FAZ A-1, v2 — P0-1/P0-2 düzeltmesiyle güncellendi):
## Her available_units girdisi null olmamalı ve geçerli bir faction_id taşımalı.
##
## ÖNEMLİ: unit.faction_id == faction.faction_id ARTIK ZORUNLU DEĞİL. Compendium'da bir
## faction'ın Armoury/roster listesi başka bir faction'a "ev sahipliği" yapan mercenary
## birimleri de meşru şekilde içerebilir (örn. Combat Biologist'in faction_id'si
## iron_sultanate ama New Antioch'un resmi Mercenaries listesinde de yer alır). Deploy
## doğrulaması (game.gd) artık faction_id eşitliği değil, available_units ÜYELİĞİ kontrol
## ediyor — bu test de aynı gerçek kaynağı esas almalı. Bunun yerine: aynı unit'in bir
## faction listesinde YİNELENMEDİĞİNİ (duplicate ExtResource) doğruluyoruz.

const FACTION_DIR := "res://assets/data/factions/"

func run(t) -> void:
	var dir := DirAccess.open(FACTION_DIR)
	t.ok(dir != null, "faksiyon klasörü açılır")
	if dir == null:
		return

	var checked := 0
	for file in dir.get_files():
		if not file.ends_with(".tres"):
			continue
		var faction = load(FACTION_DIR + file)
		t.ok(faction != null, "yüklenir: " + file)
		if faction == null:
			continue
		# Klasörde FactionData dışı kaynaklar da olabilir (ör. factions_manifest.tres =
		# FactionManifest kataloğu). Roster denetimi yalnız FactionData'yı ilgilendirir.
		if not (faction is FactionData):
			continue
		checked += 1
		var fid: StringName = faction.faction_id
		t.ok(fid != &"", "%s faction_id boş değil" % file)

		var seen: Array = []
		for ud in faction.available_units:
			t.ok(ud != null, "%s: available_units girdisi null değil" % file)
			if ud == null:
				continue
			t.ok(ud.faction_id != &"", "%s: '%s' geçerli bir faction_id taşıyor" % [file, ud.unit_name])
			t.ok(not seen.has(ud), "%s: '%s' rosterde yinelenmemiş" % [file, ud.unit_name])
			seen.append(ud)

	t.ok(checked >= 6, "en az 6 faksiyon denetlendi (denetlenen: %d)" % checked)
