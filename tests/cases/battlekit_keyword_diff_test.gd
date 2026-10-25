extends RefCounted

## BATTLEKIT KEYWORD DİFF (compendium denetimi, Adım 6).
##
## `trench_compendium/battlekit/{ranged,melee,grenade}.md` her silahın RESMÎ keyword bloğunu
## verir. Bu test, oyundaki `.tres` silahlarının o bloktaki keyword'leri GERÇEKTEN taşıdığını
## doğrular — yani bir silahın kuralı sessizce eksik kalamaz.
##
## NEDEN GEREKLİ: Adım 6 taramasında dört silahta eksik keyword bulundu ve hepsi oynanışı
## doğrudan etkiliyordu:
##   • Vivisector          → `[Block]` yok (yakın dövüş savunması çalışmıyordu)
##   • Corruption Belcher  → `[Gas]` yok (element tepkimeleri/muafiyetleri devre dışıydı)
##   • Serpent Assault Gun → `[Gas]` yok (aynı)
##   • Shotgun             → `[Bayonet Lug]` + `[Shield Combo]` yok
## Ayrıca `[Shield Combo]`nun eksikliği, Adım 6'da yeni bağlanan kalkan-el kuralını da
## ölü bırakıyordu.
##
## KAPSAM: burada TEK TEK, kaynakta doğrulanmış eşleştirmeler tutulur. Otomatik ayrıştırma
## yanlış pozitif üretiyor (ör. Sniper Rifle'ın "Bull's Eye" düzyazısındaki KOŞULLU Ignore
## Armour'ı, Punt Gun açıklamasındaki "Reload" kelimesi) — bu yüzden liste elle doğrulanmıştır.

## silah dosyası → compendium keyword bloğunda GEÇEN, oyunda da bulunması gereken keyword'ler
const EXPECTED := {
	"vivisector":          ["block", "cumbersome"],
	"corruption_belcher":  ["flamethrower", "gas"],
	"serpent_assault_gun": ["automatic", "gas", "heavy"],
	"shotgun":             ["shotgun", "bayonet_lug", "shield_combo"],
	"punt_gun":            ["shotgun", "shrapnel", "heavy"],
	"sniper_rifle":        ["critical", "risky"],
}

## Compendium'da BULUNMAYAN, dolayısıyla oyunda da OLMAMASI gereken keyword'ler.
## (Otomatik taramanın ürettiği yanlış pozitifleri kalıcı olarak yanlış işaretler.)
const FORBIDDEN := {
	"sniper_rifle":     ["ignore_armour"],  # Bull's Eye yalnız KRİTİKTE, koşulsuz değil
	"molotov_cocktail": ["ignore_armour"],  # compendium bloğunda yok
	"punt_gun":         ["reload"],         # açıklamada geçiyor, keyword bloğunda yok
}

## Bir keyword İKİ biçimde saklanabilir ve ikisi de geçerlidir:
##   • `keywords` sözlüğünde  →  `&"block": 1`
##   • TİPLİ ALAN olarak      →  `is_cumbersome = true`, `ignore_armour = true`
## `AttackData` sık kullanılan bazı keyword'leri tipli alana çıkarmıştır (is_deadly,
## is_cumbersome, ignore_armour, is_sniper…). Test biçime değil VARLIĞA bakmalı — aksi hâlde
## doğru veriyi hatalı raporlar (ilk yazımında `vivisector`ın [Cumbersome]'ı böyle kaçtı).
func _has_keyword(txt: String, kw: String) -> bool:
	return txt.contains("&\"%s\"" % kw) \
		or txt.contains("is_%s = true" % kw) \
		or txt.contains("%s = true" % kw)

func run(t) -> void:
	for stem in EXPECTED:
		var path := "res://assets/data/attacks/%s.tres" % stem
		var txt := FileAccess.get_file_as_string(path)
		t.ok(txt != "", "%s.tres okunabildi" % stem)
		if txt == "":
			continue
		for kw in EXPECTED[stem]:
			t.ok(_has_keyword(txt, kw),
				"%s → [%s] taşıyor (compendium keyword bloğu)" % [stem, kw])

	for stem in FORBIDDEN:
		var txt2 := FileAccess.get_file_as_string("res://assets/data/attacks/%s.tres" % stem)
		if txt2 == "":
			continue
		for kw in FORBIDDEN[stem]:
			t.ok(not _has_keyword(txt2, kw),
				"%s → [%s] TAŞIMAMALI (compendium bloğunda yok)" % [stem, kw])

	# ── Menzil ekseni: Adım 6 taramasında 89 compendium silahında sapma çıkmadı ──
	# Halberd Gun iki profile ayrılır (melee 2" + ranged 24"); bu ayrımın korunduğu
	# doğrulanır, aksi hâlde tek profile indirgenip menzillerden biri kaybolur.
	var hb := FileAccess.get_file_as_string("res://assets/data/attacks/halberd_gun.tres")
	var hs := FileAccess.get_file_as_string("res://assets/data/attacks/halberd_gun_shot.tres")
	t.ok(hb.contains("attack_type = \"MELEE\"") and hb.contains("attack_range = 1.0"),
		"Halberd Gun melee profili: tüm yakın dövüş silahlarıyla aynı erişim (1.0)")
	t.ok(hs.contains("attack_type = \"RANGED\"") and hs.contains("attack_range = 24.0"),
		"Halberd Gun ranged profili: 24\"")
