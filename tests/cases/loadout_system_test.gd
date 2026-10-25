extends RefCounted

## FAZ 5 (P1-1): Battlekit/Loadout seçim sistemi.
## LoadoutResolver.resolve_loadout (saf, paylaşılan .tres mutasyona uğramaz) +
## GameState.can_deploy_loadout / deployed_count_of_loadout_group (warband-limit sayımı).

const LoadoutResolver = preload("res://scripts/rules/loadout_resolver.gd")
const LoadoutOption = preload("res://scripts/data/loadout_option.gd")
const UnitData = preload("res://scripts/data/unit_data.gd")
const AttackData = preload("res://scripts/data/attack_data.gd")

class FakeUnit:
	extends RefCounted
	var owner_id: int = 1
	var unit_data = null
	var chosen_loadout_index: int = -1

func _atk(name: String) -> AttackData:
	var a := AttackData.new()
	a.attack_name = name
	return a

func _opt(name_key: String, attacks: Array[Resource] = [], armour: int = -1, cost: int = 0,
		kw: Dictionary = {}, maxpw: int = 999, group: StringName = &"") -> LoadoutOption:
	var o := LoadoutOption.new()
	o.option_name_key = name_key
	o.attacks_override = attacks
	o.armour_override = armour
	o.cost_delta = cost
	o.extra_keywords = kw
	o.max_per_warband = maxpw
	o.limit_group = group
	return o

func _base_unit() -> UnitData:
	var u := UnitData.new()
	u.unit_name = "Test Unit"
	u.cost = 10
	u.armour = 1
	u.attacks = [_atk("base_weapon")]
	u.keywords = {&"base_kw": 1}
	return u

func run(t) -> void:
	# ── LoadoutResolver.resolve_loadout ─────────────────────────────────────
	t.eq(LoadoutResolver.resolve_loadout(null, 0), null, "null base → null")

	var base := _base_unit()
	var no_opt := LoadoutResolver.resolve_loadout(base, -1)
	t.ok(no_opt == base, "loadout_index=-1 → AYNI referans (kopya yok, sıfır ek maliyet)")

	var oob := LoadoutResolver.resolve_loadout(base, 5)
	t.ok(oob == base, "aralık dışı index → base değişmeden döner")

	var alt_weapon := _atk("alt_weapon")
	base.loadout_options = [
		_opt("OPT_A", [alt_weapon], 3, 7, {&"extra_kw": 1}, 999, &""),
	]
	var resolved := LoadoutResolver.resolve_loadout(base, 0)
	t.ok(resolved != base, "geçerli index → DUPLICATE (farklı referans, paylaşılan .tres korunur)")
	t.eq(resolved.attacks.size(), 1, "attacks_override uygulandı")
	t.ok(resolved.attacks[0] == alt_weapon, "doğru silah")
	t.eq(resolved.armour, 3, "armour_override uygulandı")
	t.eq(resolved.cost, 17, "cost_delta eklendi (10+7=17)")
	t.ok(resolved.keywords.has(&"base_kw"), "orijinal keyword korundu")
	t.ok(resolved.keywords.has(&"extra_kw"), "extra_keywords birleştirildi")
	t.eq(base.attacks.size(), 1, "ORİJİNAL base.attacks MUTASYONA UĞRAMADI (hâlâ base_weapon)")
	t.eq(base.armour, 1, "ORİJİNAL base.armour MUTASYONA UĞRAMADI")
	t.eq(base.cost, 10, "ORİJİNAL base.cost MUTASYONA UĞRAMADI")

	# armour_override=-1 → değişmez
	base.loadout_options = [_opt("OPT_B", [], -1, 0)]
	var resolved2 := LoadoutResolver.resolve_loadout(base, 0)
	t.eq(resolved2.armour, 1, "armour_override=-1 → değişmez (base'den miras)")
	t.eq(resolved2.attacks.size(), 1, "attacks_override boş → base attacks korunur")

	# ── GameState.can_deploy_loadout / deployed_count_of_loadout_group ──────
	var mole_ud := UnitData.new()
	mole_ud.unit_name = "Mole Test Unit"
	mole_ud.loadout_options = [
		_opt("A", [], -1, 0, {}, 999, &""),                          # 0: grupsuz
		_opt("MOLE", [], -1, 10, {&"infiltrator": 1}, 2, &"mole"),   # 1: mole grubu, limit 2
		_opt("RIFLE_MOLE", [], -1, 15, {&"infiltrator": 1}, 2, &"mole"), # 2: aynı grup
	]

	t.ok(GameState.can_deploy_loadout(1, mole_ud, 1), "hiç deploy yokken mole seçilebilir")

	var f1 := FakeUnit.new(); f1.owner_id = 1; f1.unit_data = mole_ud; f1.chosen_loadout_index = 1
	var f2 := FakeUnit.new(); f2.owner_id = 1; f2.unit_data = mole_ud; f2.chosen_loadout_index = 2
	GameState.units[&"__test_mole_1__"] = f1
	GameState.units[&"__test_mole_2__"] = f2

	t.eq(GameState.deployed_count_of_loadout_group(1, "Mole Test Unit", &"mole", 1), 2,
		"limit_group PAYLAŞAN iki farklı index BİRLİKTE sayılır (1 mole + 1 rifle_mole = 2)")
	t.ok(not GameState.can_deploy_loadout(1, mole_ud, 1), "2/2 mole limiti doldu → 3. mole reddedilir")
	t.ok(not GameState.can_deploy_loadout(1, mole_ud, 2), "rifle_mole de aynı grupta olduğu için reddedilir")
	t.ok(GameState.can_deploy_loadout(2, mole_ud, 1), "başka oyuncu kendi limitine sahip (izole)")
	t.ok(GameState.can_deploy_loadout(1, mole_ud, 0), "grupsuz (index 0) seçenek etkilenmez")

	GameState.units.erase(&"__test_mole_1__")
	GameState.units.erase(&"__test_mole_2__")

	# ── LoadoutResolver.validate_loadout — el (hand) taşıma limiti ──────────
	# Genel kural hâlâ geçerli: 2 elden fazla melee/ranged yükü reddedilir.
	var overloaded := _base_unit()
	overloaded.attacks = [_atk("a"), _atk("b"), _atk("c")]
	for a in overloaded.attacks:
		a.attack_type = "MELEE"
		a.hands = "1H"
	t.ok(LoadoutResolver.validate_loadout(overloaded) != "",
		"3x1H melee (fixed_weapon_loadout YOK) → hâlâ reddedilir (genel kural bozulmadı)")

	# fixed_weapon_loadout: War Wolf/Amalgam gibi "silahları modele ait, Battlekit değil" birimler
	# standart el-limitinin İSTİSNASI (regresyon kilidi — bkz. ebbc54a'nın yeniden açtığı bug).
	overloaded.keywords[&"fixed_weapon_loadout"] = 1
	t.eq(LoadoutResolver.validate_loadout(overloaded), "",
		"fixed_weapon_loadout → el-limiti kontrolü atlanır (RAW: 'cannot have any other Battlekit')")

	var war_wolf_ud = load("res://assets/data/units/war_wolf_assault_beast.tres")
	t.eq(LoadoutResolver.validate_loadout(war_wolf_ud), "",
		"War Wolf Assault Beast → artık deploy edilebilir (Chainsaw Mouth 1H + Shredding Claws 2H)")

	var amalgam_ud2 = load("res://assets/data/units/amalgams.tres")
	t.eq(LoadoutResolver.validate_loadout(amalgam_ud2), "",
		"Amalgam → artık deploy edilebilir (Six-Armed Monstrosity'nin 3+ silahı el-limitinden muaf)")
