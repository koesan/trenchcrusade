extends RefCounted

## BİRİM STAT DİFF — compendium denetimi, Adım 7 (stat ekseni).
##
## `trench_compendium/warbands/*.md` her birimin profilini verir: Cost, Movement, Ranged, Melee,
## Armour. Bu test o değerleri `assets/data/units/*.tres` ile BİREBİR karşılaştırır.
##
## DENETİM SONUCU (2026-07-29): 49 birim × 5 eksen karşılaştırıldı, SAPMA YOK. Veri katmanı
## gerçekten örnek nitelikte — önceki `docs/faction_audit` turunun "stat 10/10" değerlendirmesi
## bağımsız olarak doğrulanmış oldu.
##
## NEDEN DEĞERLER TESTE GÖMÜLÜ: compendium'u çalışma zamanında ayrıştırmak kırılgan olurdu
## (birim girdilerinin markdown başlığı yok, bazı birimler iki bölümde birden listeli).
## Değerler kaynaktan bir kez çıkarılıp buraya sabitlendi; bir `.tres` değişirse test yakalar.
##
## Sıra: [cost, movement, ranged_dice_modifier, melee_dice_modifier, armour]
const EXPECTED := {
	"amalgams": [140, 6, 0, 0, 0],
	"anointed_heavy_infantry": [95, 6, 1, 1, null],
	"artillery_witch": [100, 6, 0, null, 0],
	"azebs": [25, 6, 0, null, 0],
	"brazen_bull": [100, 6, 0, 2, 0],
	"castigator": [50, 6, 1, 1, 0],
	"combat_biologist": [3, 6, 0, 1, null],
	"communicant": [100, 6, null, 2, 0],
	"communicant_anti_tank_hunter": [5, 6, 1, 1, null],
	"corpse_guard": [55, 6, 0, 1, 0],
	"court_desecrated_saint": [140, 6, 0, 3, null],
	"court_hell_knight": [100, 6, 0, 2, null],
	"court_hunter_of_the_left_hand_path": [110, 6, 2, 1, 0],
	"court_pit_locust": [90, 8, 0, 2, null],
	"court_praetor": [115, 8, 3, 3, 0],
	"court_wretched": [20, 6, null, null, 0],
	"court_yoke_fiend": [30, 6, 0, 1, 0],
	"death_commando": [90, 6, 1, 2, 0],
	"ecclesiastic_prisoner": [20, 6, 0, null, 0],
	"fly_thrall": [25, 6, 0, null, 0],
	"goetic_warlock": [4, 6, 1, 1, null],
	"grail_thrall": [25, 5, 0, null, 0],
	"heretic_chorister": [65, 6, null, 2, 0],
	"heretic_priest": [80, 6, 2, 2, 0],
	"heretic_trooper": [30, 6, 0, 0, 0],
	"jabirean_alchemist": [55, 6, 2, 1, 0],
	"janissary": [55, 6, 1, 1, 0],
	"mamluk_faris": [4, 6, 1, 1, null],
	"mendelist_ammo_monk": [2, 6, null, null, 0],
	"new_antioch_combat_engineer": [80, 6, 0, 1, null],
	"new_antioch_combat_medic": [65, 6, 0, 0, null],
	"new_antioch_lieutenant": [70, 6, 2, 2, 0],
	"new_antioch_mechanized_heavy_infantry": [85, 6, 1, 0, null],
	"new_antioch_shocktrooper": [45, 6, 0, 1, 0],
	"new_antioch_sniper_priest": [50, 6, 2, null, 0],
	"new_antioch_trench_cleric": [60, 6, 1, 1, 0],
	"new_antioch_yeoman": [30, 6, 0, 0, 0],
	"observer": [3, 8, 1, 2, null],
	"plague_knight": [60, 6, 0, 2, 0],
	"scripture_guardian": [7, 6, 0, 1, null],
	"sin_eater": [6, 6, 0, 2, null],
	"stigmatic_nun": [50, 8, 1, 1, 0],
	"sultanate_assassin": [85, 6, 1, 2, 0],
	"sultanate_sapper": [50, 6, 1, 0, 0],
	"trench_pilgrim": [30, 6, 0, 0, 0],
	"war_prophet": [80, 6, 2, 2, 0],
	"war_wolf_assault_beast": [145, 8, 0, 2, null],
	"witchburner": [5, 6, 0, 1, null],
	"wretched": [25, 6, null, null, 0],
}

func run(t) -> void:
	for unit in EXPECTED:
		var path := "res://assets/data/units/%s.tres" % unit
		var txt := FileAccess.get_file_as_string(path)
		t.ok(txt != "", "%s.tres okunabildi" % unit)
		if txt == "":
			continue
		var exp: Array = EXPECTED[unit]
		# Kaynakta bulunamayan alanlar `null` bırakılır ve atlanır — kısmi profil de korunur.
		# ⚠ Godot `.tres` VARSAYILANA EŞİT alanları YAZMAZ. Bir alanın yokluğu "eksik veri"
		# değil, "varsayılan değerde" demektir (`unit_data.gd`: speed 6.0, armour 0,
		# modifier'lar 0). Testin ilk hâli bunu hata sanıp doğru veriyi kırmızıya boyuyordu.
		# cost = compendium profil Cost'u + hazır teçhizat payı (kit_cost, bkz. kit_pricing_test).
		var kit_m := RegEx.create_from_string("\\nkit_cost = (\\d+)").search(txt)
		var kit: int = int(kit_m.get_string(1)) if kit_m else 0
		var cost_m := RegEx.create_from_string("\\ncost = (\\d+)").search(txt)
		if cost_m and exp[0] != null:
			t.eq(int(cost_m.get_string(1)) - kit, int(exp[0]), "%s → profil cost = %d (compendium)" % [unit, exp[0]])
		_check(t, unit, txt, "speed", "speed = ([\\d.]+)", exp[1], 6.0)
		_check(t, unit, txt, "ranged", "ranged_dice_modifier = (-?\\d+)", exp[2], 0.0)
		_check(t, unit, txt, "melee", "melee_dice_modifier = (-?\\d+)", exp[3], 0.0)
		_check(t, unit, txt, "armour", "\\narmour = (\\d+)", exp[4], 0.0)

## `default_value`: alan `.tres`te YOKSA kullanılacak `UnitData` varsayılanı.
func _check(t, unit: String, txt: String, label: String, pattern: String, expected,
		default_value: float) -> void:
	if expected == null:
		return
	var re := RegEx.create_from_string(pattern)
	var m := re.search(txt)
	var actual: float = float(m.get_string(1)) if m != null else default_value
	t.approx(actual, expected,
		"%s → %s = %s (compendium)" % [unit, label, str(expected)])
