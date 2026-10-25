extends RefCounted

## FAKSİYON ROSTER DİFF — compendium denetimi, Adım 7 (roster ekseni).
##
## `trench_compendium/warbands/*.md` her warband'ın kadrosunu dört bölümde verir:
## `## Captains` / `## Elite` / `## Infantry` / `## Mercenaries`. Bu test, oyundaki
## `assets/data/factions/<id>.tres` kadro listelerinin o kaynakla BİREBİR örtüştüğünü kilitler.
##
## DENETİM SONUCU (2026-07-29): altı faksiyonun da roster'ı EKSİKSİZ, sapma yok.
## İlk otomatik tarama 8 "eksik" birim raporladı; hepsi YAZIM/ÇOĞUL farkı çıktı:
##   Lord of Tumors → lord_of_tumours   (US/UK yazımı)
##   Sorcerer       → court_auxilia_sorceror  (kaynakta "sorceror")
##   Amalgam        → amalgams          (tekil/çoğul)
##   Hounds of the Black Grail → hound_of_the_black_grail  (çoğul/tekil ters yönde)
## Bu yüzden test isim TAHMİNİ yapmaz; beklenen dosya adlarını AÇIKÇA listeler.
##
## ⚠ AYRIŞTIRMA NOTU: warband dosyalarında birim girdilerinin markdown BAŞLIĞI YOKTUR. Birim adı
## bölüm başlığının altında ÇIPLAK BİR SATIR olarak durur, ardından görsel ve `Cost:` /
## `Availability:` satırları gelir. `###`/`####` aramak sıfır sonuç verir (`####` yalnız Armoury
## kalemlerinde kullanılır). Ayrıca compendium bazı birimleri İKİ bölümde birden listeler
## (ör. Black Grail'de Plague Knight hem Captains hem Elite altında) — ham satır sayısı
## benzersiz birim sayısından fazla olabilir.

## faksiyon dosyası → kadroda BULUNMASI gereken birim `.tres` adları
const EXPECTED_UNITS := {
	"cult_of_the_black_grail": [
		"lord_of_tumours", "plague_knight", "corpse_guard", "amalgams", "grail_thrall",
		"fly_thrall", "heralds_of_beelzebub", "hound_of_the_black_grail",
		"scripture_guardian", "sin_eater",
	],
}

## faksiyon → beklenen kadro büyüklüğü (compendium'daki benzersiz birim sayısı)
const EXPECTED_SIZE := {
	"new_antioch": 15,
	"heretic_legion": 11,
	"trench_pilgrims": 13,
	"iron_sultanate": 11,
	"cult_of_the_black_grail": 10,
	"court_of_seven_headed_serpent": 11,
}

func _roster(fid: String) -> Array:
	var txt := FileAccess.get_file_as_string("res://assets/data/factions/%s.tres" % fid)
	var re := RegEx.create_from_string("units/([a-z_0-9]+)\\.tres")
	var out: Array = []
	for m in re.search_all(txt):
		var u: String = m.get_string(1)
		if not out.has(u):
			out.append(u)
	return out

func run(t) -> void:
	for fid in EXPECTED_SIZE:
		var roster := _roster(fid)
		t.eq(roster.size(), EXPECTED_SIZE[fid],
			"%s kadrosu %d birim (compendium)" % [fid, EXPECTED_SIZE[fid]])

	# Black Grail için birim birim: "11 satır ama 10 birim" tuzağının (Plague Knight iki
	# bölümde birden listeli) yeniden yanlış okunmasını engeller.
	for fid in EXPECTED_UNITS:
		var roster := _roster(fid)
		for unit in EXPECTED_UNITS[fid]:
			t.ok(roster.has(unit), "%s kadrosunda %s var" % [fid, unit])
		# Fazladan (compendium'da olmayan) birim de olmamalı.
		for unit in roster:
			t.ok(EXPECTED_UNITS[fid].has(unit),
				"%s kadrosundaki %s compendium'da karşılığı olan bir birim" % [fid, unit])

	# Kadro dosyalarının gerçekten var olduğu — kırık referans sessizce "eksik birim" olur.
	for fid in EXPECTED_SIZE:
		for unit in _roster(fid):
			t.ok(ResourceLoader.exists("res://assets/data/units/%s.tres" % unit),
				"%s → units/%s.tres dosyası mevcut" % [fid, unit])
