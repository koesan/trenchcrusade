extends RefCounted

## SENARYO DİFF — compendium denetimi, Adım 13 (senaryolar ve zafer koşulları).
##
## `trench_compendium/scenarios/*.md` on iki senaryo tanımlar (`random.md` ve `rules.md`
## meta dosyalardır, senaryo değildir).
##
## DENETİM SONUCU (2026-07-29):
##   • Uygulanan 5 kanonik senaryonun TUR SINIRI compendium ile birebir.
##   • 7 kanonik senaryo HENÜZ UYGULANMADI (içerik boşluğu — aşağıda listeli).
##   • 1 senaryo (`marked_for_death`) compendium'da KARŞILIĞI OLMAYAN, uydurma bir moddur.

## Uygulanmış kanonik senaryolar → compendium'daki tur sınırı.
## NOT: `ScenarioData.turn_limit` varsayılanı 4'tür; Godot varsayılana eşit alanları `.tres`e
## YAZMAZ, dolayısıyla `claim_no_mans_land` dosyasında satırın olmaması "eksik" değil "4" demektir.
const CANONICAL_TURNS := {
	"claim_no_mans_land": 4,
	"fields_of_glory": 4,
	"great_war": 5,
	"relic_hunt": 4,
	"the_high_ground": 5,
}

## Compendium'da tanımlı ama HENÜZ UYGULANMAMIŞ senaryolar.
## Bu liste bilinçli bir kapsam kaydıdır; biri eklenince buradan çıkarılmalıdır.
const NOT_YET_IMPLEMENTED := [
	"armoured-train", "dont-breathe", "dragon-hunt", "from-below",
	"hunt-for-heroes", "supply-raid", "trench-warfare",
]

## Compendium'da KAYNAĞI OLMAYAN senaryo(lar).
##
## `marked_for_death`: "sahadaki en pahalı model Bounty Target olur, onu düşüren +VP alır".
## Hiçbir compendium senaryosunda böyle bir kural yok. Bu, önceki denetimin **S-9 "Uydurulmuş
## içerik"** bulgusuyla aynı sınıfa girer — ancak uydurma KURAL METNİ veya SİLAHIN aksine, bir
## senaryo hiçbir çekirdek kuralı bozmaz; yalnız fazladan bir oyun modudur. Bu yüzden SİLİNMEDİ,
## kanonik-olmayan olarak İŞARETLENDİ; kaldırma kararı kullanıcıya aittir.
const NON_CANONICAL := ["marked_for_death"]

func run(t) -> void:
	# ── Kanonik senaryoların tur sınırı ─────────────────────────────────
	for sid in CANONICAL_TURNS:
		var path := "res://assets/data/scenarios/%s.tres" % sid
		var txt := FileAccess.get_file_as_string(path)
		t.ok(txt != "", "%s.tres okunabildi" % sid)
		if txt == "":
			continue
		var re := RegEx.create_from_string("turn_limit = (\\d+)")
		var m := re.search(txt)
		# Alan yoksa varsayılan 4 geçerlidir (bkz. sınıf notu).
		var turns: int = int(m.get_string(1)) if m != null else 4
		t.eq(turns, CANONICAL_TURNS[sid],
			"%s tur sınırı %d (compendium)" % [sid, CANONICAL_TURNS[sid]])

	# ── Uygulanmamış senaryolar gerçekten yok mu? ───────────────────────
	# Biri sessizce eklenirse bu liste bayatlar ve kapsam kaydı yanıltıcı olur.
	for name in NOT_YET_IMPLEMENTED:
		var sid: String = name.replace("-", "_")
		t.ok(not ResourceLoader.exists("res://assets/data/scenarios/%s.tres" % sid),
			"Henüz uygulanmamış senaryo listede doğru: %s" % name)

	# ── Kanonik-olmayan senaryo işaretli mi? ────────────────────────────
	for sid in NON_CANONICAL:
		t.ok(ResourceLoader.exists("res://assets/data/scenarios/%s.tres" % sid),
			"Kanonik-olmayan senaryo hâlâ mevcut (silinmedi): %s" % sid)

	# ── Toplam sayım tutuyor mu? ────────────────────────────────────────
	var dir := DirAccess.open("res://assets/data/scenarios")
	t.ok(dir != null, "scenarios dizini okunabildi")
	if dir != null:
		var n := 0
		for f in dir.get_files():
			if f.ends_with(".tres"):
				n += 1
		t.eq(n, CANONICAL_TURNS.size() + NON_CANONICAL.size(),
			"Oyunda %d senaryo (5 kanonik + 1 kanonik-olmayan)" % n)

	# ── Zafer koşulu: hepsi Victory Point tabanlı ───────────────────────
	# Compendium'da bu beş senaryonun tamamı "Victory Points" ile kazanılır.
	for sid in CANONICAL_TURNS:
		var txt := FileAccess.get_file_as_string("res://assets/data/scenarios/%s.tres" % sid)
		t.ok(txt.contains("victory_type = 1"),
			"%s zafer koşulu Victory Point tabanlı" % sid)
