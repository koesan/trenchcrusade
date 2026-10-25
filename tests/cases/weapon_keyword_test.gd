extends RefCounted

## P1-1 (silah/keyword boşlukları — PISTOL/FLAMETHROWER/BLOCK, 2026-07-16): veri-bağlama
## regresyon kilidi. Gerçek mekanik davranış (Success Roll atlama, -1 Dice, Off-Hand eşleşmesi)
## async/canlı-birim akışına bağlı, headless test edilemez — bu dosya yalnız "doğru silahta doğru
## keyword var mı, doğru unit'e bağlı mı" doğrular (weapon_overapplication_test.gd ile AYNI desen).

const KeywordSystem = preload("res://scripts/rules/keyword_system.gd")

func _attacks_of(unit_path: String) -> Array:
	var ud = load("res://assets/data/units/" + unit_path + ".tres")
	if ud == null:
		return []
	return ud.attacks

func _has_pistol_pair(unit_path: String) -> bool:
	var ranged_found := false
	var melee_found := false
	for a in _attacks_of(unit_path):
		if a == null or not KeywordSystem.has(a, &"pistol"):
			continue
		if a.attack_type == "RANGED":
			ranged_found = true
		elif a.attack_type == "MELEE":
			melee_found = true
	return ranged_found and melee_found

func run(t) -> void:
	# ── PISTOL (keyword.md): "can be used as a Melee Weapon or a Ranged Weapon, and can be used
	# as both in the same Activation" — her pistol taşıyan birim hem RANGED hem MELEE pistol
	# saldırısına (aynı &"pistol" keyword'lü, ayrı AttackData girdisi olarak) sahip olmalı. ──
	# Combat Medic / Sister of Saint Cosmas compendium'da tabanca TAŞIMAZ ("always has Standard Armour,
	# a Gas Mask, a Medi-kit, and a Misericordia") — eski uydurma Medic Pistol kaldırıldı.
	t.ok(not _has_pistol_pair("combat_medic"), "Sister of Saint Cosmas → tabanca yok (compendium kiti)")
	t.ok(not _has_pistol_pair("new_antioch_combat_medic"), "New Antioch Combat Medic → tabanca yok (compendium kiti)")
	t.ok(_has_pistol_pair("war_prophet"), "War Prophet → Ranged+Melee Pistol çifti var")
	t.ok(_has_pistol_pair("jabirean_alchemist"), "Jabirean Alchemist → Ranged+Melee Pistol çifti var")
	t.ok(_has_pistol_pair("yuzbasi"), "Yuzbasi → Ranged+Melee Pistol çifti var")
	t.ok(_has_pistol_pair("death_commando"), "Death Commando → Ranged+Melee Pistol çifti var")
	t.ok(_has_pistol_pair("new_antioch_lieutenant"), "Lieutenant → Ranged+Melee Pistol çifti var")
	t.ok(_has_pistol_pair("castigator"), "Castigator → Ranged+Melee Pistol çifti var")

	# Anointed Heavy Infantry LİSTEDE DEĞİL: compendium (heretic-legion.md) ona yalnız
	# Reinforced Armour + Infernal Brand verir, tabanca vermez. Ranged +1D'si HL Armoury'sindeki
	# ağır menzilli silahlar içindir (Machine Gun 50, Heavy Flamethrower 55) — denetim bulgusu
	# S-2/P0-HL-1. Eskiden ona `templar_pistol` (New Antioch temalı, uydurma 6" menzilli bir
	# varlık) verilmişti ve bu test onu ZORUNLU kılıyordu.
	t.ok(not _has_pistol_pair("anointed_heavy_infantry"),
		"Anointed Heavy Infantry → compendium'da tabancası YOK")

	# GENEL DEĞİŞMEZ (liste bakımı gerektirmez): RANGED pistol taşıyan HER birim, aynı
	# aktivasyonda melee'de de kullanabilmek için MELEE pistol girdisine de sahip olmalı.
	# Bu, yukarıdaki elle tutulan listeden daha güçlüdür — yeni eklenen birimleri de kapsar.
	var unpaired: Array[String] = []
	var dir := DirAccess.open("res://assets/data/units")
	if dir != null:
		dir.list_dir_begin()
		var fn := dir.get_next()
		while fn != "":
			if fn.ends_with(".tres"):
				var uname := fn.get_basename()
				var ranged_pistol := false
				var melee_pistol := false
				for a in _attacks_of(uname):
					if a == null or not KeywordSystem.has(a, &"pistol"):
						continue
					if a.attack_type == "RANGED":
						ranged_pistol = true
					elif a.attack_type == "MELEE":
						melee_pistol = true
				if ranged_pistol and not melee_pistol:
					unpaired.append(uname)
			fn = dir.get_next()
		dir.list_dir_end()
	unpaired.sort()
	t.eq(unpaired.size(), 0,
		"RANGED pistol taşıyan her birimin MELEE pistol eşi de var %s" % str(unpaired))

	# Mamluk Faris: base attacks pistol taşımaz (Jezzail+Greatsword), yalnız "Sword/Axe and
	# Pistol" loadout'unda (index 1) pistol çifti olmalı.
	var faris = load("res://assets/data/units/mamluk_faris.tres")
	t.ok(not _has_pistol_pair("mamluk_faris"), "Mamluk Faris taban silahları → pistol YOK (Jezzail+Greatsword)")
	var sword_pistol_loadout = faris.loadout_options[1]
	var lo_ranged := false
	var lo_melee := false
	for a in sword_pistol_loadout.attacks_override:
		if a != null and KeywordSystem.has(a, &"pistol"):
			if a.attack_type == "RANGED":
				lo_ranged = true
			elif a.attack_type == "MELEE":
				lo_melee = true
	t.ok(lo_ranged and lo_melee, "Mamluk Faris 'Sword/Axe and Pistol' loadout'u → Ranged+Melee Pistol çifti var")

	# ── FLAMETHROWER (keyword.md): "automatically a Success... cannot achieve a Critical
	# Success" — mekanik unit.gd::server_request_attack_action'da genel (silah-bağımsız) olarak
	# kodlanmış; burada yalnız daha önce yanlış/eksik olan witchburner_flamer.tres'in artık
	# hiçbir unit'e bağlı OLMADIĞI (silindi, RAW'da Witchburner'ın silahı Gavel of Justice'tir)
	# doğrulanır. ──
	var witchburner = load("res://assets/data/units/witchburner.tres")
	var has_flamer := false
	for a in witchburner.attacks:
		if a != null and a.attack_name == "ATTACK_WITCHBURNER_FLAMER":
			has_flamer = true
	t.ok(not has_flamer, "Witchburner → yanlış Flamer silahı YOK (gerçek silahı Gavel of Justice)")

	# ── BLOCK (keyword.md): "-1 Dice for Melee Attacks targeting that model if the attacker
	# made a Charge Action before the attack" — Polearm'ın BLOCK keyword'ü hâlâ doğru bağlı mı? ──
	var polearm = load("res://assets/data/attacks/polearm.tres")
	t.ok(KeywordSystem.has(polearm, &"block"), "Polearm → block keyword'ü var (regresyon)")
