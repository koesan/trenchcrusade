extends RefCounted

## Compendium'da `## Faction Rules` bölümü OLMAYAN faksiyonlar (Heretic Legion, Iron Sultanate,
## Trench Pilgrims) has_faction_rule=false taşır. Bu faksiyonların faction_rule_summary alanı
## BOŞ olmalıdır — dolu bırakılırsa bayrak bir gün açıldığında oyuncuya masa oyununda var
## olmayan kurallar gösterilir (denetim bulgusu S-9).
##
## Silinen uydurma metinler ve neden uydurma oldukları:
##   FACTION_HERETIC_LEGION_RULES  → "Blood Sacrifice: Gain 1 Faith Point"
##       "Faith Point" Trench Crusade'de var olmayan bir kaynaktır.
##   FACTION_IRON_SULTANATE_RULES  → "Alchemical Armor: All models receive a +1 Armour bonus"
##       Compendium'un TAM TERSİ: Iron Sultanate'in 8 çekirdek biriminin tamamı Armour 0'dır.
##   FACTION_TRENCH_PILGRIMS_RULES → "Martyrdom: ...faith generating acts"
##       Yine var olmayan "faith" kaynağına atıf.
##   FACTION_DEFAULT_RULES         → "Shield of Faith: Spend Faith points"
##       Aynı hayalet mekanik.

const MANIFEST := preload("res://assets/data/factions/factions_manifest.tres")

const DEAD_KEYS := [
	"FACTION_HERETIC_LEGION_RULES",
	"FACTION_IRON_SULTANATE_RULES",
	"FACTION_TRENCH_PILGRIMS_RULES",
	"FACTION_DEFAULT_RULES",
]

func _read(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var s := f.get_as_text()
	f.close()
	return s

func run(t) -> void:
	for f in MANIFEST.factions:
		if not f.has_faction_rule:
			t.eq(f.faction_rule_summary, "",
				"%s: has_faction_rule=false → faction_rule_summary BOŞ olmalı" % f.faction_id)
		else:
			t.ok(f.faction_rule_summary != "",
				"%s: has_faction_rule=true → faction_rule_summary DOLU olmalı" % f.faction_id)

	var tr_txt := _read("res://assets/localization/tr.json")
	var en_txt := _read("res://assets/localization/en.json")
	for dead_key in DEAD_KEYS:
		var needle := "\"%s\"" % dead_key
		t.ok(not en_txt.contains(needle), "en.json: uydurma anahtar silinmiş → %s" % dead_key)
		t.ok(not tr_txt.contains(needle), "tr.json: uydurma anahtar silinmiş → %s" % dead_key)

	# "Faith Point" Trench Crusade'de var olmayan bir kaynaktır; hiçbir metinde geçmemeli.
	t.ok(not en_txt.contains("Faith Point"),
		"en.json: 'Faith Point' geçmiyor (Trench Crusade'de böyle bir kaynak yok)")
