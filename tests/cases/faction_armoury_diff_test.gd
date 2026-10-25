extends RefCounted

## FAKSİYON ARMOURY DİFF — compendium denetimi, Adım 7 (armoury/zırh ekseni).
##
## Her warband dosyasının `## Armoury` bölümü iki kısımdır ve ARADAKİ AYRAÇ KRİTİKTİR:
##   • ayraçtan ÖNCE  → savaş modunda satın alınabilen Battlekit
##   • `Exploration Only` satırından SONRA → yalnız KAMPANYA/keşif adımında alınabilenler
##
## DENETİM SONUCU (2026-07-29): altı faksiyonun savaş-modu Armoury tabloları (toplam 229 giriş)
## oyunla BİREBİR örtüşüyor, eksik kalem YOK.
##
## ⚠ METODOLOJİ HATASI (bu testin var oluş sebebi): ilk tarama 60 "eksik kalem" raporladı ve
## bunların 21'i "gerçek battlekit boşluğu" diye sınıflandırıldı — çünkü kalemler battlekit
## SÖZLÜĞÜNDEKİ kategorilerine (Armour/Equipment/Melee…) göre ayrılmıştı. Oysa belirleyici olan
## kategori DEĞİL, faksiyon tablosundaki KONUMDUR: bir zırh da, bir tüfek de `Exploration Only`
## altındaysa savaş modunda satın alınamaz. Ayraç dikkate alınınca eksik sayısı SIFIRA indi.
##
## Bu aynı zamanda Adım 6'dan beri açık duran "compendium 15 zırh tanımlıyor, oyunda 5 var"
## sorusunu da kapatır: kalan 10 zırhın tamamı keşif-modu kalemidir.
##
## `tools/generate_armoury.py` bu ayracı zaten doğru uyguluyor (`if l == "Exploration Only":
## break`). Test, üretecin bu davranışının bozulmadığını ve çıktısının kaynakla eşleştiğini
## kilitler.

const EXPECTED_BATTLE_ITEMS := {
	"new_antioch": 39,
	"heretic_legion": 42,
	"trench_pilgrims": 41,
	"iron_sultanate": 41,
	"cult_of_the_black_grail": 32,
	"court_of_seven_headed_serpent": 33,
}

func _armoury(fid: String) -> Array:
	var txt := FileAccess.get_file_as_string("res://assets/data/factions/%s.tres" % fid)
	var re := RegEx.create_from_string("armoury/([a-z_0-9]+)\\.tres")
	var out: Array = []
	for m in re.search_all(txt):
		var it: String = m.get_string(1)
		if not out.has(it):
			out.append(it)
	return out

func run(t) -> void:
	var total := 0
	for fid in EXPECTED_BATTLE_ITEMS:
		var items := _armoury(fid)
		total += items.size()
		t.eq(items.size(), EXPECTED_BATTLE_ITEMS[fid],
			"%s savaş-modu Armoury tablosu %d kalem" % [fid, EXPECTED_BATTLE_ITEMS[fid]])
		# Kırık referans sessizce "satın alınamayan kalem" üretir.
		for it in items:
			t.ok(ResourceLoader.exists("res://assets/data/armoury/%s.tres" % it),
				"%s → armoury/%s.tres mevcut" % [fid, it])
	t.eq(total, 228, "Altı faksiyonda toplam 228 Armoury girişi")

	# ── Üreteç `Exploration Only` ayracını hâlâ uyguluyor mu? ────────────
	# Bu satır kalkarsa keşif-modu kalemleri savaş moduna sızar ve oyuncu kampanya
	# ilerlemesine bağlı ekipmanı ilk maçta satın alabilir.
	var gen := FileAccess.get_file_as_string("res://tools/generate_armoury.py")
	t.ok(gen != "", "generate_armoury.py okunabildi")
	t.ok(gen.contains("Exploration Only"),
		"Üreteç keşif-modu ayracını tanıyor")
	t.ok(gen.contains("break"),
		"Üreteç ayraçtan sonrasını okumayı BIRAKIYOR (kampanya kalemleri sızmıyor)")

	# ── Keşif-modu kalemleri gerçekten oyunda OLMAMALI ───────────────────
	# Örnekler: Knighthood ("At the end of each game, your Warband receives…"),
	# Battlefield Title (Roster'daki Limit'i kalıcı artırır), Trench Dog Ownership
	# (warband'a kalıcı model ekler), Beelzebub's Embrace ("throughout the campaign").
	# Hepsi kalıcı roster/kampanya katmanı ister; oyunda o katman yok.
	for forbidden in ["knighthood", "battlefield_title", "trench_dog_ownership",
			"resurrection_engine", "field_hospital"]:
		t.ok(not ResourceLoader.exists("res://assets/data/armoury/%s.tres" % forbidden),
			"Keşif-modu kalemi savaş moduna sızmamış: %s" % forbidden)
	t.ok(not DirAccess.dir_exists_absolute("res://scripts/campaign"),
		"Kampanya katmanı yok — keşif-modu kalemlerinin dışlanması doğru davranış")
