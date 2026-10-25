extends Node

## ÇEVİRİ YÖNETİCİSİ — dil dosyalarını KENDİ KEŞFEDER.
##
## Kullanıcı isteği: "farklı dil dosyaları eklenince otomatik olarak oyun dil kısmında
## gözüksün; bir kişi alıp sadece json'u farklı dile çevirip buraya ekleyince oyun arayüzünde
## otomatik görünsün ve tıklayınca o dile çevrilsin."
##
## ÇEVİRİ EKLEMEK İÇİN KOD DEĞİŞİKLİĞİ GEREKMEZ:
##   1. `assets/localization/tr.json` dosyasını kopyala, adını dil koduyla değiştir (ör. `de.json`).
##   2. Değerleri çevir. Anahtarlara DOKUNMA — anahtarlar oyunun iç adlarıdır.
##   3. `LANGUAGE_NAME` anahtarına dilin KENDİ dilindeki adını yaz (ör. "Deutsch").
##   4. Oyunu aç: dil, Ayarlar menüsünde kendiliğinden görünür.
##
## İKİ KAYNAK TARANIR:
##   • `res://assets/localization/`  — oyunla birlikte gelen diller
##   • `user://localization/`        — oyuncunun sonradan eklediği diller (kurulu oyunda,
##     paketi açmadan çeviri eklenebilsin diye). Aynı dil kodu iki yerde varsa KULLANICI
##     dosyası kazanır; böylece oyuncu gelen bir çeviriyi düzeltebilir.
signal locale_changed(new_language: String)

## Oyunla gelen dil dosyalarının klasörü.
const BUNDLED_DIR := "res://assets/localization"
## Oyuncunun sonradan çeviri ekleyebileceği klasör.
const USER_DIR := "user://localization"

## Hiç dil dosyası bulunamazsa başvurulacak kod.
const FALLBACK_LANGUAGE := "tr"

## `LANGUAGE_NAME` anahtarı yoksa menüde gösterilecek ad: dil kodunun büyük harfi.
const DISPLAY_NAME_KEY := "LANGUAGE_NAME"

var current_language: String = FALLBACK_LANGUAGE

## dil kodu → { anahtar: metin }
var translations: Dictionary = {}

## Keşfedilen dil kodları, menüde görünecek sırada (alfabetik).
var available_languages: Array[String] = []

func _ready() -> void:
	load_translations()
	TranslationServer.set_locale(current_language)

# ─── YÜKLEME ──────────────────────────────────────────────────────────────────

func load_translations() -> void:
	translations.clear()
	available_languages.clear()

	# Sıra ÖNEMLİ: kullanıcı klasörü sonra okunur ki aynı kodlu dosya paketi EZSİN.
	for dir_path in [BUNDLED_DIR, USER_DIR]:
		for lang in _language_codes_in(dir_path):
			var data: Dictionary = _read_json(dir_path.path_join(lang + ".json"))
			if data.is_empty():
				continue
			translations[lang] = data

	available_languages.assign(translations.keys())
	available_languages.sort()

	if available_languages.is_empty():
		GameLogger.log_warn("Hiç dil dosyası bulunamadı: %s" % BUNDLED_DIR, "SYSTEM")
	elif not translations.has(current_language):
		current_language = available_languages[0]

	var summary: Array[String] = []
	for lang in available_languages:
		summary.append("%s:%d" % [lang, translations[lang].size()])
	GameLogger.log_info("LocalizationManager: %d dil yüklendi (%s)." \
		% [available_languages.size(), ", ".join(summary)], "SYSTEM")

## Bir klasördeki dil kodlarını döndürür. Klasör yoksa boş liste (hata değil —
## `user://localization` çoğu kurulumda hiç oluşturulmaz).
func _language_codes_in(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for file in dir.get_files():
		# ⚠ Dışa aktarılmış yapılarda Godot kaynakları `.json.import`/`.remap` uzantısıyla
		# listeleyebilir; taban adı almak her iki durumda da doğru kodu verir.
		var base := file.trim_suffix(".remap").trim_suffix(".import")
		if base.get_extension().to_lower() != "json":
			continue
		var code := base.get_basename()
		if code != "" and not out.has(code):
			out.append(code)
	return out

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		GameLogger.log_warn("Dil dosyası açılamadı: %s" % path, "SYSTEM")
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		GameLogger.log_warn("Dil dosyası bozuk (%s) — satır %d: %s" \
			% [path, json.get_error_line(), json.get_error_message()], "SYSTEM")
		return {}
	if not (json.data is Dictionary):
		GameLogger.log_warn("Dil dosyası sözlük değil: %s" % path, "SYSTEM")
		return {}
	return json.data

# ─── SORGU ────────────────────────────────────────────────────────────────────

func tr_t(key: String) -> String:
	var godot_tr := tr(key)
	if godot_tr != key:
		return godot_tr
	var table: Dictionary = translations.get(current_language, {})
	if table.has(key):
		return table[key]
	return key

func has_key(key: String) -> bool:
	return translations.get(current_language, {}).has(key)

## Dilin menüde görünecek adı — KENDİ dilinde (ör. "Türkçe", "English", "Deutsch").
## Çevirmen `LANGUAGE_NAME` anahtarını doldurur; yoksa dil kodu büyük harfle gösterilir.
func language_display_name(lang: String) -> String:
	var table: Dictionary = translations.get(lang, {})
	var name: String = table.get(DISPLAY_NAME_KEY, "")
	return name if name != "" else lang.to_upper()

# ─── DEĞİŞTİRME ───────────────────────────────────────────────────────────────

## Keşfedilen HERHANGİ bir dile geçer. Bilinmeyen kod sessizce yok sayılır (bozuk bir
## ayar dosyası oyunu metinsiz bırakmasın).
func set_language(lang: String) -> void:
	if not translations.has(lang):
		GameLogger.log_warn("Bilinmeyen dil kodu: %s" % lang, "SYSTEM")
		return
	if lang == current_language:
		return
	current_language = lang
	TranslationServer.set_locale(lang)
	locale_changed.emit(current_language)
