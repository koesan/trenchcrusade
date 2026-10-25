extends RefCounted

## VERİ BÜTÜNLÜĞÜ KİLİDİ (Mimari Faz 1 — Faction Single Source of Truth):
## Faksiyon kataloğu `factions_manifest.tres` TEK KAYNAK'tır. Bu test şunu garanti eder:
##  - Manifest yüklenir ve ≥6 FactionData taşır.
##  - Her faction: logo atanmış, faction_id dolu, faction_rule_summary geçerli localization anahtarı.
##  - Klasördeki HER FactionData `.tres` manifest'te KAYITLI (unutulan/orphan faction yok).
##  - Alias'lar benzersiz ve hiçbir canonical faction_id ile çakışmıyor.
##
## Böylece yeni faction eklerken (manifest'e eklemeyi unutmak / logo atamamak / bozuk rule anahtarı)
## sessizce kırık bir katalog oluşmaz — CI/headless testte hemen yakalanır.

const FACTION_DIR := "res://assets/data/factions/"
const MANIFEST_PATH := "res://assets/data/factions/factions_manifest.tres"

func run(t) -> void:
	var manifest = load(MANIFEST_PATH)
	t.ok(manifest != null, "factions_manifest.tres yüklenir")
	if manifest == null:
		return
	t.ok(manifest is FactionManifest, "manifest FactionManifest tipinde")

	var factions: Array = manifest.factions
	t.ok(factions.size() >= 6, "manifest ≥6 faction taşır (gelen: %d)" % factions.size())

	var canonical_ids := {}
	var alias_seen := {}
	for f in factions:
		t.ok(f is FactionData, "manifest girdisi FactionData")
		if not (f is FactionData):
			continue
		var fid := String(f.faction_id)
		t.ok(fid != "", "faction_id boş değil")
		canonical_ids[f.faction_id] = true
		t.ok(f.logo != null, "%s: logo atanmış" % fid)
		# faction_rule_summary YALNIZ has_faction_rule=true olan faksiyonlarda doludur.
		# Compendium'da `## Faction Rules` bölümü olmayan faksiyonlarda (Heretic Legion,
		# Iron Sultanate, Trench Pilgrims) bu alan BOŞ olmalıdır — dolu bırakılırsa masa
		# oyununda var olmayan bir kural metnine işaret eder (denetim bulgusu S-9).
		# Ayrıntılı denetim: tests/cases/faction_rule_text_test.gd
		if f.has_faction_rule:
			t.ok(f.faction_rule_summary != "",
				"%s: has_faction_rule=true → faction_rule_summary dolu" % fid)
			t.ok(LocalizationManager.has_key(f.faction_rule_summary),
				"%s: rule anahtarı localization'da mevcut (%s)" % [fid, f.faction_rule_summary])
		else:
			t.eq(f.faction_rule_summary, "",
				"%s: has_faction_rule=false → faction_rule_summary boş" % fid)
		for a in f.aliases:
			t.ok(not alias_seen.has(a), "alias benzersiz: %s" % String(a))
			alias_seen[a] = true

	# Alias hiçbir canonical id ile çakışmamalı (arama belirsizliği olmasın).
	for a in alias_seen.keys():
		t.ok(not canonical_ids.has(a), "alias canonical id ile çakışmıyor: %s" % String(a))

	# Klasördeki her FactionData manifest'te kayıtlı mı? (regist; unutulan faction yok)
	var dir := DirAccess.open(FACTION_DIR)
	t.ok(dir != null, "faksiyon klasörü açılır")
	if dir != null:
		for file in dir.get_files():
			if not file.ends_with(".tres"):
				continue
			var res = load(FACTION_DIR + file)
			if not (res is FactionData):
				continue  # factions_manifest.tres gibi FactionData olmayanları atla
			t.ok(canonical_ids.has(res.faction_id),
				"%s manifest'te kayıtlı (unutulan faction yok)" % file)

	# Alias resolver (Faz 2): kısa/eski id ve canonical id, GameState tek kaynağından çözülür.
	for f in factions:
		if not (f is FactionData):
			continue
		t.ok(GameState.get_faction_by_id(f.faction_id) == f,
			"canonical '%s' çözülür" % String(f.faction_id))
		for a in f.aliases:
			var resolved = GameState.get_faction_by_id(a)
			t.ok(resolved != null and resolved.faction_id == f.faction_id,
				"alias '%s' → '%s' çözülür" % [String(a), String(f.faction_id)])
