extends RefCounted

## INFECTION MARKER — SUCCESS ROLL HARCAMASI (compendium denetimi, Adım 3).
##
## `comprehensive-rules/keyword.md`:
## > "INFECTION MARKERS can be used to modify dice rolls **exactly like Blood Markers**
## > (i.e. Action rolls and injury rolls and used in Bloodbaths)."
##
## `core-rules/blood-markers.md` (dolayısıyla Veba İşareti için de geçerli):
## > "your opponent can declare that they are spending one or more of them, **REMOVING** the
## > model's markers as they are spent. For each ... add [-1 Dice] to the Success Roll."
##
## KURAL SAPMASI: Success Roll tarafında bu bir SEÇİM değildi. `DicePoolBuilder` mevcut TÜM Veba
## İşaretlerini koşulsuz `-Dice` olarak ekliyor ve onları HİÇ TÜKETMİYORDU. İki sonucu vardı:
##   1. Rakibin kaynak yönetimi kararı yok olmuştu (RAW'da "kaç tane harcayayım?" bir tercihtir).
##   2. İşaretler kalıcı olduğu için 6 işaretli bir model SONSUZA KADAR her Success Roll'unda
##      -6 Dice yiyordu — RAW'da rakip onları bir kez harcar ve biterler.
## (Injury Roll tarafı zaten `request_infection_spend` ile doğruydu; sapma yalnız Success Roll'daydı.)

func run(t) -> void:
	# ── Otomatik ceza kaldırıldı mı? ────────────────────────────────────
	var dpb := FileAccess.get_file_as_string("res://scripts/rules/dice_pool_builder.gd")
	t.ok(dpb != "", "dice_pool_builder.gd okunabildi")
	t.ok(not dpb.contains("\"key\": \"MOD_INFECTION\""),
		"Success Roll'da OTOMATİK Veba cezası kalemi YOK (harcama seçime bağlı)")
	t.ok(not dpb.contains("attacker_infection"),
		"Success Roll bağlamı artık Veba sayısını taşımıyor (kullanılmıyor)")

	# ── Harcama akışı Kan İşaretiyle AYNI desende mi? ───────────────────
	var ms := FileAccess.get_file_as_string("res://scripts/rules/marker_spend.gd")
	t.ok(ms != "", "marker_spend.gd okunabildi")
	for needle in [
		"request_blood_spend_on_success",
		"request_infection_spend_on_success",
		"request_blessing_spend_on_success",
	]:
		t.ok(ms.contains(needle), "Harcama sorusu bağlı: %s" % needle)
	# İşaretler GERÇEKTEN düşülmeli — sapmanın ikinci yarısı buydu.
	t.ok(ms.contains("unit.infection_markers -= "),
		"Harcanan Veba İşaretleri modelden SİLİNİYOR (kalıcı ceza değil)")
	t.ok(ms.contains("unit.blood_markers -= "), "Kan İşaretleri de siliniyor (mevcut davranış korundu)")
	t.ok(ms.contains("unit.blessing_markers -= "), "Nimet İşaretleri de siliniyor")

	# ── Yön doğru mu? Veba/Kan EKSİ, Nimet ARTI ─────────────────────────
	# `apply_success_marker_spend(mod, minus_count, plus_count)` imzası: ilk sayaç -1 Dice/adet.
	var D = load("res://scripts/rules/dice_pool_builder.gd")
	t.eq(D.apply_success_marker_spend(0, 3, 0), -3, "3 Veba/Kan harcaması → -3 Dice")
	t.eq(D.apply_success_marker_spend(0, 0, 2), 2, "2 Nimet harcaması → +2 Dice")
	t.eq(D.apply_success_marker_spend(1, 2, 0), -1, "Mevcut +1 modifikatör üstüne 2 harcama → -1")

	# ── [Negate Gas] muafiyeti korunuyor mu? ────────────────────────────
	# Eski otomatik kalem `[Negate Gas]` taşıyan modeli muaf tutuyordu; harcamaya geçerken bu
	# muafiyetin DÜŞMEMESİ gerekir, aksi hâlde gaz maskeli birimler yeni bir ceza kazanırdı.
	t.ok(ms.contains("negates(unit.unit_data, &\"gas\")"),
		"[Negate Gas] taşıyan model Veba harcamasından muaf")

	# ── Rakip mi soruluyor, sahibi mi? ──────────────────────────────────
	# Kan ve Veba RAKİBİN kararıdır; Nimet modelin SAHİBİNİN.
	var cc := FileAccess.get_file_as_string("res://scripts/combat/combat_choice.gd")
	var ii: int = cc.find("func request_infection_spend_on_success")
	t.ok(ii >= 0, "request_infection_spend_on_success tanımlı")
	if ii >= 0:
		var body: String = cc.substr(ii, 320)
		t.ok(body.contains("get_opponent_id"),
			"Veba harcamasını RAKİP seçiyor (Kan İşaretiyle aynı taraf)")

	# ── Oyuncuya sorulan metin lokalize mi? ─────────────────────────────
	for key in ["MARKER_INFECTION_SUCCESS_TITLE", "MARKER_INFECTION_SUCCESS_INFO"]:
		t.ok(LocalizationManager.has_key(key), "Lokalizasyon anahtarı var: %s" % key)
