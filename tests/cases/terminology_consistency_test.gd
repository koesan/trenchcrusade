extends RefCounted

## TERİM TUTARLILIĞI — Türkçe metinlerde İngilizce terim sızıntısı olmamalı.
##
## Kullanıcı isteği: "açıklamalar hiç bilmeyen bir kişinin bile anlayacağı hâlde olsun …
## profesyonel, sade, net olsun."
##
## SORUN: Türkçe açıklamaların içinde çevrilmemiş İngilizce terimler dolaşıyordu —
## "bir Success Roll ile", "+4 Dice'lı", "Moral için Down sayılır", "Retreat başarısız olursa",
## "Charge yapamaz". Aynı kavram bazı metinlerde Türkçe, bazılarında İngilizceydi; oyunu
## bilmeyen biri iki terimin aynı şey olduğunu anlayamıyordu. 94 metinde düzeltildi.
##
## ⚠ TEK İSTİSNA — `KEYWORD_*` sözlük girdileri: orada İngilizce terim KASITLIDIR ve
## korunmalıdır. Sözlüğün işi oyuncuya kartlarda/compendium'da göreceği ÖZGÜN terimi
## öğretmektir: "Hücum (Charge)", "Alan Etkisi (Blast X)". Bu test onları hariç tutar.

## Türkçe metinde bulunmaması gereken İngilizce terimler.
const FORBIDDEN_IN_TR := [
	"Success Roll", "Injury Roll", "Injury Dice", "Out of Action",
	"Blood Marker", "Blessing Marker", "Infection Marker",
	"Charge", "Retreat", "Cleave", "Blast", "Cover", "Risky", "Assault",
]

## `Assault` ve `Charge` AYRI terimlerdir ve ayrı karşılıkları olmalıdır:
## Charge bir EYLEM (Hücum), Assault bir SİLAH anahtar kelimesidir (Taarruz).
## İkisini "Hücum" ile karşılamak, silahın hangi kuralı taşıdığını belirsizleştiriyordu.
const DISTINCT_TERMS := {
	"KEYWORD_ASSAULT": "Taarruz",
	"ACTION_ONSLAUGHT_CHARGE": "Hücum",
}

func _tr() -> Dictionary:
	var d = JSON.parse_string(FileAccess.get_file_as_string("res://assets/localization/tr.json"))
	return d if d is Dictionary else {}

func run(t) -> void:
	var tr := _tr()
	t.ok(not tr.is_empty(), "tr.json okunabildi")

	# ── Sızıntı taraması ────────────────────────────────────────────────
	var leaks: Array[String] = []
	for key in tr:
		if key.begins_with("KEYWORD_"):
			continue          # sözlükte İngilizce terim kasıtlı
		var value = tr[key]
		if not (value is String):
			continue
		for term in FORBIDDEN_IN_TR:
			if (value as String).contains(term):
				leaks.append("%s → '%s'" % [key, term])
	t.eq(leaks.size(), 0,
		"Türkçe metinlerde çevrilmemiş İngilizce terim yok%s"
			% ("" if leaks.is_empty() else ": " + ", ".join(leaks.slice(0, 5))))

	# ── Sözlük girdileri İngilizce terimi KORUYOR mu? ───────────────────
	# Ters yönde bir regresyon de mümkün: toplu değiştirme sözlüğü de temizlerse
	# oyuncu kartındaki terimi öğrenemez.
	t.ok(String(tr.get("KEYWORD_ASSAULT", "")).contains("Assault"),
		"Sözlük girdisi özgün terimi koruyor (KEYWORD_ASSAULT)")
	t.ok(String(tr.get("KEYWORD_BLAST", "")).contains("Blast"),
		"Sözlük girdisi özgün terimi koruyor (KEYWORD_BLAST)")

	# ── Ayrı kavramlar ayrı kelimelerle mi karşılanıyor? ────────────────
	# Buton metinleri büyük harfli olabilir; karşılaştırma harf durumuna DUYARSIZ.
	for key in DISTINCT_TERMS:
		var text: String = String(tr.get(key, "")).to_lower()
		t.ok(text.contains(String(DISTINCT_TERMS[key]).to_lower()),
			"%s → '%s' terimini kullanıyor" % [key, DISTINCT_TERMS[key]])

	# ── Biçimlendirme bozulmamış mı? ────────────────────────────────────
	# Toplu düzenleme sırasında `strip()` bazı metinlerin başındaki `\n`i silmişti;
	# o metinler bir listeye eklendiği için satır başı ANLAMLIDIR.
	t.ok(String(tr.get("ABILITY_TEXT", "")).begins_with("\n"),
		"ABILITY_TEXT satır başıyla başlıyor (listeye eklenirken ayrım için)")
	t.ok(String(tr.get("ACTIONS_TAKEN_TEXT", "")).begins_with("\n"),
		"ACTIONS_TAKEN_TEXT satır başıyla başlıyor")

	# ── Ek çekimi ────────────────────────────────────────────────────────
	# Özel adları toplu değiştirmek Türkçe ek uyumunu bozabiliyor ("Yiyici'a").
	var bad_suffix := 0
	for key in tr:
		var v = tr[key]
		if v is String and (v as String).contains("Yiyici'a"):
			bad_suffix += 1
	t.eq(bad_suffix, 0, "Toplu değiştirme ek uyumunu bozmamış (Yiyici'ye, Yiyici'a değil)")

	# ── İşaret terimleri TEK biçimde mi? ────────────────────────────────
	# Metinlerde "İşaretçisi"/"İşareti" ve "Enfeksiyon"/"Veba" karışık kullanılıyordu; oyunu
	# bilmeyen biri aynı kavramın iki adı olduğunu sanıyordu. Panel rozetleri ve `LABEL_VEBA`
	# ile aynı biçimde birleştirildi.
	var mixed := 0
	for key in tr:
		var val = tr[key]
		if not (val is String):
			continue
		if (val as String).contains("İşaretçi") or (val as String).contains("Enfeksiyon İşaret"):
			mixed += 1
	t.eq(mixed, 0, "İşaret terimleri tek biçimde ('… İşareti', 'Veba İşareti')")

	# ── İki dil anahtar bazında eşit mi? ────────────────────────────────
	var en = JSON.parse_string(FileAccess.get_file_as_string("res://assets/localization/en.json"))
	t.ok(en is Dictionary, "en.json okunabildi")
	if en is Dictionary:
		var missing_en := 0
		var missing_tr := 0
		for key in tr:
			if not (en as Dictionary).has(key):
				missing_en += 1
		for key in en:
			if not tr.has(key):
				missing_tr += 1
		t.eq(missing_en, 0, "EN'de eksik anahtar yok")
		t.eq(missing_tr, 0, "TR'de eksik anahtar yok")
