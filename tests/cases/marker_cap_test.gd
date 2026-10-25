extends RefCounted

## İŞARET TAVANI — compendium denetimi, Adım 4 (moral, işaretçiler, kazanma).
##
## `core-rules/blood-markers.md` ve `blessing-markers.md` aynı cümleyi kurar:
## > "A model cannot have more than 6 [Blood/Blessing Markers] at any time. When a model gets
## > to this point, **ignore any instructions to place more** ... until there are less than 6."
##
## `comprehensive-rules/keyword.md` (INFECTION MARKER):
## > "A model may have up to six INFECTION MARKERS **and** six Blood Markers at the same time."
## Yani üç havuz da BAĞIMSIZ ve her biri 6 ile sınırlı.
##
## NEDEN BEKÇİ GEREKİYOR: tavan tek bir yerde uygulanmıyor — işaret basan HER çağrı yeri kendi
## `min(..., 6)` ifadesini taşıyor (bugün 14 yer: injury_resolver, ability_effects, üç injury
## trigger, unit.gd). Denetimde hepsi doğru çıktı, ama yeni bir yetenek/tetikleyici eklerken
## tavanı unutmak sessiz bir kural ihlali üretir: 6'nın üstündeki işaretler hem Bloodbath
## maliyetini hem harcanabilir zar sayısını RAW'ın üstüne çıkarır.

## İşaret alanı basan satırların taranacağı dosyalar.
const SCANNED := [
	"res://scripts/rules/injury_resolver.gd",
	"res://scripts/rules/abilities/ability_effects.gd",
	"res://scripts/rules/injury/triggers/prize_specimens.gd",
	"res://scripts/rules/injury/triggers/beelzebubs_touch.gd",
	"res://scripts/rules/injury/triggers/dark_blessing.gd",
	"res://scenes/unit/unit.gd",
]

const MARKER_FIELDS := ["blood_markers", "blessing_markers", "infection_markers"]

func run(t) -> void:
	var total_placements := 0
	for path in SCANNED:
		var txt := FileAccess.get_file_as_string(path)
		t.ok(txt != "", "%s okunabildi" % path.get_file())
		for line in txt.split("\n"):
			var s := line.strip_edges()
			# İşaret ARTIRAN satırlar: "<alan> = ... + ..." biçimi. Harcama (`-=`) ve
			# sıfırlama/atama (`= 0`) hariç.
			var is_placement := false
			for f in MARKER_FIELDS:
				if s.contains(f + " = ") and s.contains("+"):
					is_placement = true
			if not is_placement:
				continue
			total_placements += 1
			t.ok(s.contains("6"),
				"Tavan uygulanmış (%s): %s" % [path.get_file(), s.left(90)])

	# Tarama gerçekten bir şey bulmuş olmalı — yol/desen bayatlarsa test sessizce boş geçmesin.
	t.ok(total_placements >= 10,
		"İşaret basan en az 10 çağrı yeri tarandı (bulunan: %d)" % total_placements)

	# Üç havuz BAĞIMSIZ olmalı: aynı alana yazan tek bir ortak sayaç olmamalı.
	var unit_txt := FileAccess.get_file_as_string("res://scenes/unit/unit.gd")
	for f in MARKER_FIELDS:
		t.ok(unit_txt.contains("var " + f),
			"%s ayrı bir alan (havuzlar bağımsız)" % f)

	# Harcama yönleri: Kan/Veba Success Roll'da EKSİ, Nimet ARTI (Adım 3'te düzeltilen desen).
	var D = load("res://scripts/rules/dice_pool_builder.gd")
	t.eq(D.apply_success_marker_spend(0, 6, 0), -6, "6 Kan/Veba harcaması → -6 Dice (tavan kadar)")
	t.eq(D.apply_success_marker_spend(0, 0, 6), 6, "6 Nimet harcaması → +6 Dice (tavan kadar)")
