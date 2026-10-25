extends RefCounted

## LOKALİZASYON KAPSAM BEKÇİSİ.
##
## Kullanıcı bildirimi: *"bazı metinler local kısmında dil dosyalarında yok, koda metin
## koymayın, tüm metinler dil dosyasında olsun."*
##
## Bu test üç şeyi KALICI olarak garanti eder:
##  1. Koddaki her `tr_t("SABIT")` çağrısının iki dilde de karşılığı var.
##  2. `.tres` verilerindeki her lokalizasyon anahtarı alanının karşılığı var.
##  3. Sahnelerde ve kodda oyuncuya doğrudan gösterilen İngilizce/Türkçe metin YOK.
##
## `localization_parity_test.gd` iki dilin ANAHTAR KÜMELERİNİN eşitliğini denetler; bu test
## anahtarların gerçekten KULLANILDIĞI yerlerden geriye doğru bakar — ikisi birbirini tamamlar.

## Lokalizasyon anahtarı OLMAYAN, büyük harfli teknik alanlar (enum değerleri).
const NON_KEY_FIELDS := ["attack_type", "hands", "type", "mode"]

## Sahnelerde editör yer tutucusu olarak duran ve çalışma anında ÜZERİNE YAZILAN metinler.
## Her biri için, yazan kod satırı aşağıda gösterilmiştir — bayatlarsa 3. adım yakalar.
const RUNTIME_OVERWRITTEN := {
	"HINT_TITLE": "interaction_hint_card.gd::show_hint",
	"HINT_INFO": "interaction_hint_card.gd::show_hint",
	"MARKER_TITLE": "marker_spend_overlay.gd::setup",
	"MARKER_INFO": "marker_spend_overlay.gd::setup",
	"CLOSE": "game_end_overlay.gd::update_locale",
}

func _files(root: String, ext: String, out: Array) -> void:
	var d := DirAccess.open(root)
	if d == null:
		return
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		if d.current_is_dir():
			if not f.begins_with("."):
				_files(root + "/" + f, ext, out)
		elif f.ends_with(ext):
			out.append(root + "/" + f)
		f = d.get_next()
	d.list_dir_end()

func _read(path: String) -> String:
	var fa := FileAccess.open(path, FileAccess.READ)
	return fa.get_as_text() if fa != null else ""

func run(t) -> void:
	var gd: Array = []
	_files("res://scripts", ".gd", gd)
	_files("res://scenes", ".gd", gd)
	t.ok(gd.size() > 50, "Taranacak betik bulundu (%d)" % gd.size())

	# ── 1) Koddaki tr_t("SABIT") çağrıları ────────────────────────────────
	var call_re := RegEx.new()
	call_re.compile('tr_t\\(\\s*"([A-Z0-9_]+)"\\s*\\)')
	var missing_code: Array[String] = []
	for path in gd:
		for m in call_re.search_all(_read(path)):
			var key := m.get_string(1)
			if not LocalizationManager.has_key(key) and not missing_code.has(key):
				missing_code.append("%s (%s)" % [key, String(path).get_file()])
	missing_code.sort()
	t.eq(missing_code.size(), 0,
		"Koddaki her tr_t() anahtarının karşılığı var — %d eksik: %s"
			% [missing_code.size(), str(missing_code.slice(0, 10))])

	# ── 2) .tres verilerindeki lokalizasyon anahtarları ───────────────────
	var tres: Array = []
	_files("res://assets/data", ".tres", tres)
	t.ok(tres.size() > 200, "Taranacak veri kaynağı bulundu (%d)" % tres.size())
	var field_re := RegEx.new()
	field_re.compile('(?m)^(\\w+) = "([A-Z][A-Z0-9_]{3,})"$')
	var missing_data: Array[String] = []
	for path in tres:
		for m in field_re.search_all(_read(path)):
			var field := m.get_string(1)
			var key := m.get_string(2)
			if NON_KEY_FIELDS.has(field) or LocalizationManager.has_key(key):
				continue
			var entry := "%s.%s=%s" % [String(path).get_file(), field, key]
			if not missing_data.has(entry):
				missing_data.append(entry)
	missing_data.sort()
	t.eq(missing_data.size(), 0,
		"Her .tres lokalizasyon alanının karşılığı var — %d eksik: %s"
			% [missing_data.size(), str(missing_data.slice(0, 10))])

	# ── 3) Sahnelerdeki metinler ya anahtar ya da çalışma anında yazılıyor ─
	var tscn: Array = []
	_files("res://scenes", ".tscn", tscn)
	var text_re := RegEx.new()
	text_re.compile('(?m)^(?:text|tooltip_text|placeholder_text) = "([A-Z][A-Z0-9_]{3,})"$')
	var unresolved: Array[String] = []
	for path in tscn:
		for m in text_re.search_all(_read(path)):
			var key := m.get_string(1)
			if LocalizationManager.has_key(key) or RUNTIME_OVERWRITTEN.has(key):
				continue
			var entry := "%s: %s" % [String(path).get_file(), key]
			if not unresolved.has(entry):
				unresolved.append(entry)
	unresolved.sort()
	t.eq(unresolved.size(), 0,
		"Sahnelerdeki her metin çevrilmiş ya da çalışma anında yazılıyor — %d çözümsüz: %s"
			% [unresolved.size(), str(unresolved.slice(0, 10))])

	# Yer tutucu listesi bayatlamasın: üzerine yazan dosya hâlâ var olmalı
	for key in RUNTIME_OVERWRITTEN:
		var src: String = RUNTIME_OVERWRITTEN[key]
		var fname: String = src.split("::")[0]
		var found := false
		for path in gd:
			if String(path).get_file() == fname:
				found = true
				break
		t.ok(found, "Yer tutucu '%s' metnini yazan dosya mevcut: %s" % [key, fname])

	# ── 4) Koda gömülü, oyuncuya gösterilen düz metin olmasın ─────────────
	# Biçimlendirme şablonları ("%d %s", "\n" gibi) sayılmaz — içerikleri çeviriden gelir.
	var lit_re := RegEx.new()
	lit_re.compile('(?m)^\\s*[^#\\n]*\\.(?:text|tooltip_text|placeholder_text)\\s*\\+?=\\s*"([^"]{2,})"')
	var word_re := RegEx.new()
	word_re.compile("[A-Za-zÇĞİÖŞÜçğıöşü]{3,}")
	# BBCode etiketleri ([center], [color=#...]) biçimlendirmedir, oyuncu metni DEĞİLDİR.
	var bbcode_re := RegEx.new()
	bbcode_re.compile("\\[/?[a-z]+(=[^\\]]*)?\\]")
	# %s / %d / %.1f / %+d gibi biçim belirteçleri — içerikleri çeviriden gelir.
	var fmt_re := RegEx.new()
	fmt_re.compile("%[-+ #0-9.]*[a-zA-Z%]")
	var hardcoded: Array[String] = []
	for path in gd:
		for m in lit_re.search_all(_read(path)):
			var s := m.get_string(1)
			var residue := bbcode_re.sub(s, "", true)
			residue = fmt_re.sub(residue, "", true)
			if word_re.search(residue) == null:
				continue                      # geriye yalnız boşluk/simge kaldı
			if s.to_upper() == s:
				continue                      # lokalizasyon anahtarının kendisi
			hardcoded.append("%s: \"%s\"" % [String(path).get_file(), s])
	hardcoded.sort()
	t.eq(hardcoded.size(), 0,
		"Koda gömülü oyuncu metni yok — %d bulundu: %s"
			% [hardcoded.size(), str(hardcoded.slice(0, 6))])

	# ── 5) Biçimlendirici taşıması gereken anahtarlar ─────────────────────
	# Kod bunları `% deger` ile kullanır; biçimlendirici düşerse çalışma anında patlar.
	for key in ["PLAYER_X_VICTORY", "ARMOURY_LIMIT_LEFT", "HINT_AUTO_CANCEL"]:
		t.ok(LocalizationManager.has_key(key), "%s mevcut" % key)
		var v: String = LocalizationManager.tr_t(key)
		t.ok(v.contains("%d") or v.contains("%s"),
			"%s biçimlendirici taşıyor (kod '%% deger' ile kullanıyor): %s" % [key, v])
