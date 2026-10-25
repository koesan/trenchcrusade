extends RefCounted

## DİL DOSYASI OTOMATİK KEŞFİ.
##
## Kullanıcı isteği: "farklı dil dosyaları eklenince otomatik olarak oyun dil kısmında gözüksün;
## bir kişi alıp sadece json'u farklı dile çevirip buraya ekleyince oyun arayüzünde otomatik
## görünsün ve tıklayınca o dile çevrilsin. Bu sayede çeviri çok kolay olur."
##
## Bu test o vaadi UÇTAN UCA doğrular: geçici bir dil dosyası yazar, yöneticiyi yeniden yükletir,
## dilin listede belirdiğini ve ona geçilebildiğini denetler, sonra dosyayı siler.
##
## NEDEN GEREKLİ: keşif mantığı sessizce bozulabilir (klasör adı değişir, uzantı filtresi
## bozulur, menü yeniden sabit tr/en listesine döner) ve bu ancak bir çevirmen çeviri
## eklemeye çalıştığında fark edilirdi.

const TEST_CODE := "zz"
const TEST_NAME := "Test Dili"

func run(t) -> void:
	# ── Paketle gelen diller keşfedilmiş mi? ────────────────────────────
	t.ok(LocalizationManager.available_languages.has("tr"), "tr keşfedildi")
	t.ok(LocalizationManager.available_languages.has("en"), "en keşfedildi")
	t.ok(LocalizationManager.available_languages.size() >= 2,
		"En az iki dil yüklü (%d)" % LocalizationManager.available_languages.size())

	# ── Her dil KENDİ adını veriyor mu? ─────────────────────────────────
	# Menüde "TR"/"EN" değil, dilin kendi adı görünmeli.
	t.eq(LocalizationManager.language_display_name("tr"), "Türkçe",
		"tr menüde 'Türkçe' olarak görünür")
	t.eq(LocalizationManager.language_display_name("en"), "English",
		"en menüde 'English' olarak görünür")
	# `LANGUAGE_NAME` yoksa dil kodu büyük harfle — çeviri yarım da olsa menü kırılmaz.
	t.eq(LocalizationManager.language_display_name("xx"), "XX",
		"Bilinmeyen dil için güvenli geri düşüş (kod büyük harf)")

	# ── YENİ DİL EKLEME: uçtan uca ──────────────────────────────────────
	var previous: String = LocalizationManager.current_language
	var dir_ok := DirAccess.make_dir_recursive_absolute(LocalizationManager.USER_DIR) == OK \
		or DirAccess.dir_exists_absolute(LocalizationManager.USER_DIR)
	t.ok(dir_ok, "Kullanıcı çeviri klasörü hazır (%s)" % LocalizationManager.USER_DIR)

	var path := LocalizationManager.USER_DIR.path_join(TEST_CODE + ".json")
	var f := FileAccess.open(path, FileAccess.WRITE)
	t.ok(f != null, "Geçici dil dosyası yazılabildi")
	if f == null:
		return
	f.store_string(JSON.stringify({
		"LANGUAGE_NAME": TEST_NAME,
		"MAIN_MENU_PLAY": "Oyna-ZZ",
	}))
	f.close()

	LocalizationManager.load_translations()
	t.ok(LocalizationManager.available_languages.has(TEST_CODE),
		"Klasöre bırakılan dil KENDİLİĞİNDEN listeye girdi")
	t.eq(LocalizationManager.language_display_name(TEST_CODE), TEST_NAME,
		"Yeni dilin adı kendi dosyasından okundu")

	# Geçiş çalışıyor mu ve metin gerçekten değişiyor mu?
	LocalizationManager.set_language(TEST_CODE)
	t.eq(LocalizationManager.current_language, TEST_CODE, "Yeni dile geçildi")
	t.eq(LocalizationManager.tr_t("MAIN_MENU_PLAY"), "Oyna-ZZ",
		"Metin yeni dilden geliyor")
	# Çevrilmemiş anahtar oyunu boş bırakmamalı — anahtarın kendisi görünür.
	t.eq(LocalizationManager.tr_t("SETTINGS_TITLE"), "SETTINGS_TITLE",
		"Eksik çeviri boş metin değil, anahtar döndürür (yarım çeviri oyunu kırmaz)")

	# ── Temizlik: geçici dili kaldır, önceki dile dön ───────────────────
	DirAccess.remove_absolute(path)
	LocalizationManager.load_translations()
	t.ok(not LocalizationManager.available_languages.has(TEST_CODE),
		"Dosya silinince dil listeden düştü")
	LocalizationManager.set_language(previous)
	t.eq(LocalizationManager.current_language, previous, "Önceki dile geri dönüldü")

	# ── Menü sabit bir dil listesi TAŞIMAMALI ───────────────────────────
	# Eski kod `"tr" if index == 0 else "en"` ile seçim yapıyordu; üçüncü bir dil eklendiğinde
	# yanlış dile geçerdi. Menü artık öğe metadata'sındaki dil kodunu okur.
	var ui := FileAccess.get_file_as_string(
		"res://scenes/ui/overlays/settings/settings_overlay.gd")
	t.ok(not ui.contains('"tr" if index == 0 else "en"'),
		"Dil seçimi sabit tr/en varsayımı taşımıyor")
	t.ok(ui.contains("available_languages"),
		"Menü keşfedilen dillerden kuruluyor")
	t.ok(ui.contains("get_item_metadata"),
		"Seçilen dil, sıraya değil öğe metadata'sına göre okunuyor")
