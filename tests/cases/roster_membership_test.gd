extends RefCounted

## Compendium Mercenaries listeleriyle FactionData.available_units eşleşmeli ve birimlere
## gösterilen yetenek kartları doğru olmalı (denetim bulguları P0-TP-2, P1-IS-6, P2-CT-7i, P1-HL-4a).

## faction .tres → compendium "## Mercenaries" bölümünde listelenen birim adları
const MERC_ROSTER := {
	"new_antioch": ["Combat Biologist", "Communicant Anti-Tank Hunter", "Mamluk Faris",
		"Mendelist Ammo Monk", "Observer", "Scripture Guardian", "Witchburner"],
	"heretic_legion": ["Goetic Warlock", "Scripture Guardian", "Sin Eater"],
	"trench_pilgrims": ["Sister of Saint Cosmas", "Communicant Anti-Tank Hunter",
		"Mendelist Ammo Monk", "Observer", "Scripture Guardian", "Witchburner"],
	"iron_sultanate": ["Combat Biologist", "Mamluk Faris", "Scripture Guardian"],
	"cult_of_the_black_grail": ["Scripture Guardian", "Sin Eater"],
	"court_of_seven_headed_serpent": ["Goetic Warlock", "Scripture Guardian", "Sin Eater"],
}

const MANIFEST := preload("res://assets/data/factions/factions_manifest.tres")

func _unit_names(faction: Resource) -> Array[String]:
	var out: Array[String] = []
	for u in faction.available_units:
		if u != null:
			out.append(u.unit_name)
	return out

func run(t) -> void:
	for f in MANIFEST.factions:
		var fid := String(f.faction_id)
		if not MERC_ROSTER.has(fid):
			continue
		var names := _unit_names(f)
		for merc in MERC_ROSTER[fid]:
			t.ok(names.has(merc),
				"%s rosterinde '%s' var (compendium Mercenaries)" % [fid, merc])

	# ── Lion of Jabir: yeteneği Artificial Life'tır (TÜM saldırılara -1 Injury Dice).
	# Abiotic Life ise Artillery Witch'in yalnız [Gas]'a özgü kuralıdır — yanlış kart gösteriliyordu.
	var lion: Resource = load("res://assets/data/units/lions_of_jabir.tres")
	var lion_ids: Array = []
	for ab in lion.abilities:
		if ab != null:
			lion_ids.append(ab.ability_id)
	t.ok(lion_ids.has(&"artificial_life"), "Lion of Jabir → artificial_life yeteneği")
	t.ok(not lion_ids.has(&"abiotic_life"),
		"Lion of Jabir → abiotic_life TAŞIMAMALI (o Artillery Witch'in Gas kuralı)")

	# Artillery Witch ise gerçekten Abiotic Life taşımalı (karışıklığın diğer ucu).
	var witch: Resource = load("res://assets/data/units/artillery_witch.tres")
	var witch_ids: Array = []
	for ab in witch.abilities:
		if ab != null:
			witch_ids.append(ab.ability_id)
	t.ok(witch_ids.has(&"abiotic_life"), "Artillery Witch → abiotic_life yeteneği")

	# ── Pit Locust'un Poison Stingers'ı bir Ability olarak listelenmeli (birim panelinde görünsün)
	var locust: Resource = load("res://assets/data/units/court_pit_locust.tres")
	var l_ids: Array = []
	for ab in locust.abilities:
		if ab != null:
			l_ids.append(ab.ability_id)
	t.ok(l_ids.has(&"poison_stingers"), "Pit Locust → poison_stingers ability kartı")

	# ── Infernal Bomb: compendium'da [Cumbersome] YOKTUR (uydurma kısıt, Artillery Witch'i
	# Dash yapamaz hâle getiriyordu — oysa lore "stalk the battlefields... lightning assaults" der)
	var bomb: Resource = load("res://assets/data/attacks/infernal_bomb.tres")
	t.eq(bomb.is_cumbersome, false, "Infernal Bomb → [Cumbersome] taşımamalı (uydurma kısıt)")
	t.ok(KeywordSystem.has(bomb, &"ignore_elevated_position"),
		"Infernal Bomb → [Ignore Elevated Position] (compendium)")

	# ── Poison Stingers: compendium yalnız [Cleave 2] + [Shrapnel] verir; [Gas] YOK
	var ps: Resource = load("res://assets/data/attacks/poison_stingers.tres")
	t.eq(ps.is_poison, false, "Poison Stingers → [Gas] taşımamalı")
	t.ok(ps.has_cleave and ps.cleave_count == 2, "Poison Stingers → [Cleave 2]")
	t.ok(KeywordSystem.has(ps, &"shrapnel"), "Poison Stingers → [Shrapnel]")
