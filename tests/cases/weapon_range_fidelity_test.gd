extends RefCounted

## Oyundaki hiçbir menzilli silah, compendium'da karşılığı olmayan bir menzil taşımamalı
## (denetim bulguları P0-NA-2, P0-HL-2, P2-NA-13, P1-IS-4b, P1-TP-6).
##
## KAYNAK: trench_compendium/battlekit/ranged.md
##   - Compendium'daki HER tabanca (Pistol, Automatic Pistol, Silenced Pistol) **12"**dir.
##   - En kısa 2-El uzun silah **Blunderbuss 10"**; tüfekler 18"+.
##   - "Heavy Pistol", "Crusader Rifle", "Heretic Rifle", "Templar Pistol", "Alchemist Pistol",
##     "Nun Crossbow", "Rot Grenade" diye kalemler compendium'da **YOKTUR** — hepsi uydurmaydı.

## Compendium'da hiç var olmayan, silinmiş olması gereken varlıklar
const DEAD_ASSETS := [
	"crusader_rifle", "heretic_rifle",
	"templar_pistol", "templar_pistol_melee",
	"alchemist_pistol", "alchemist_pistol_melee",
	"heavy_pistol", "heavy_pistol_melee",
	"nun_crossbow", "rot_grenade",
	"atonement_bell", "holy_water_grenade",
]

## Doğrudan battlekit/ranged.md'den alınan menziller
const EXACT_RANGE := {
	"pistol": 12.0, "automatic_pistol": 12.0, "silenced_pistol": 12.0,
	"bolt_action_rifle": 24.0, "shotgun": 12.0, "anti_materiel_rifle": 36.0,
}

func run(t) -> void:
	for dead in DEAD_ASSETS:
		t.ok(not ResourceLoader.exists("res://assets/data/attacks/%s.tres" % dead),
			"uydurma varlık silinmiş: %s" % dead)

	for name in EXACT_RANGE.keys():
		var path := "res://assets/data/attacks/%s.tres" % name
		if not ResourceLoader.exists(path):
			t.ok(false, "%s.tres mevcut" % name)
			continue
		var a: Resource = load(path)
		t.approx(a.attack_range, EXACT_RANGE[name],
			"%s menzil %.0f\"" % [name, EXACT_RANGE[name]])

	# Anti-Materiel Rifle compendium'da 2 EL'dir (Communicant'ın süpermenschal gücü bu yüzden gerekir).
	var amr: Resource = load("res://assets/data/attacks/anti_materiel_rifle.tres")
	t.eq(amr.hands, "2H", "Anti-Materiel Rifle → 2 El")

	# GENEL SÜPÜRME: compendium'da 10"den kısa menzilli tek 2-El silah yoktur; ayrıca
	# `[Pistol]` keyword'lü hiçbir silah 12"den kısa olamaz.
	var bad_2h: Array[String] = []
	var bad_pistol: Array[String] = []
	var dir := DirAccess.open("res://assets/data/attacks")
	dir.list_dir_begin()
	var fn := dir.get_next()
	while fn != "":
		if fn.ends_with(".tres"):
			var a: Resource = load("res://assets/data/attacks/" + fn)
			if a != null and a.attack_type == "RANGED":
				if a.hands == "2H" and a.attack_range < 8.0:
					bad_2h.append("%s(%.0f)" % [fn.get_basename(), a.attack_range])
				if KeywordSystem.has(a, &"pistol") and a.attack_range < 12.0:
					bad_pistol.append("%s(%.0f)" % [fn.get_basename(), a.attack_range])
		fn = dir.get_next()
	dir.list_dir_end()
	bad_2h.sort()
	bad_pistol.sort()
	t.eq(bad_2h.size(), 0, "2-El menzilli silahların hepsi >= 8\" %s" % str(bad_2h))
	t.eq(bad_pistol.size(), 0, "[Pistol] keyword'lü silahların hepsi 12\" %s" % str(bad_pistol))

	# Sniper Priest gerçek bir Sniper Rifle taşımalı (Aim + Absolute Faith'in tek anlamı
	# uzun menzildir; 10"lik uydurma bir tüfek yeteneklerini anlamsızlaştırıyordu).
	var sp: Resource = load("res://assets/data/units/new_antioch_sniper_priest.tres")
	var sp_ok := false
	for a in sp.attacks:
		if a != null and String(a.resource_path).contains("sniper_rifle"):
			sp_ok = true
	t.ok(sp_ok, "Sniper Priest → Sniper Rifle (48\") taşıyor")

	# Plague Knight'ın el bombası compendium'da Parasite Grenades'tir (BG Armoury'de
	# Frag/Rot Grenade yoktur).
	var pk: Resource = load("res://assets/data/units/plague_knight.tres")
	var pk_ok := false
	for a in pk.attacks:
		if a != null and String(a.resource_path).contains("parasite_grenades"):
			pk_ok = true
	t.ok(pk_ok, "Plague Knight → Parasite Grenades (BG Armoury)")
