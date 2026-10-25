extends RefCounted

## tr.json ve en.json ANAHTAR KÜMELERİ birebir aynı olmalı ve hiçbir değer boş olmamalı.
##
## Bu test, projenin "hiçbir metin koda gömülmez, her metin iki dilde de bulunur" kuralının
## otomatik bekçisidir. Yeni bir lokalizasyon anahtarı yalnız tek dile eklenirse burada yakalanır.

const TR_PATH := "res://assets/localization/tr.json"
const EN_PATH := "res://assets/localization/en.json"

func _load(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var txt := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(txt)
	return parsed if parsed is Dictionary else {}

func run(t) -> void:
	var tr_d := _load(TR_PATH)
	var en_d := _load(EN_PATH)
	t.ok(tr_d.size() > 0, "tr.json yüklendi (%d anahtar)" % tr_d.size())
	t.ok(en_d.size() > 0, "en.json yüklendi (%d anahtar)" % en_d.size())

	var missing_in_en: Array[String] = []
	var missing_in_tr: Array[String] = []
	for k in tr_d.keys():
		if not en_d.has(k):
			missing_in_en.append(String(k))
	for k in en_d.keys():
		if not tr_d.has(k):
			missing_in_tr.append(String(k))
	missing_in_en.sort()
	missing_in_tr.sort()
	t.eq(missing_in_en.size(), 0, "en.json'da eksik anahtar yok %s" % str(missing_in_en.slice(0, 8)))
	t.eq(missing_in_tr.size(), 0, "tr.json'da eksik anahtar yok %s" % str(missing_in_tr.slice(0, 8)))

	var empty_tr: Array[String] = []
	var empty_en: Array[String] = []
	for k in tr_d.keys():
		if String(tr_d[k]).strip_edges() == "":
			empty_tr.append(String(k))
	for k in en_d.keys():
		if String(en_d[k]).strip_edges() == "":
			empty_en.append(String(k))
	empty_tr.sort()
	empty_en.sort()
	t.eq(empty_tr.size(), 0, "tr.json'da boş değer yok %s" % str(empty_tr.slice(0, 8)))
	t.eq(empty_en.size(), 0, "en.json'da boş değer yok %s" % str(empty_en.slice(0, 8)))
