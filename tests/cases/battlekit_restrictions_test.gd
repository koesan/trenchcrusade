extends RefCounted

## BİRİME ÖZEL BATTLEKIT KISITLARI + "One type of Grenade" + hazır kitlerin LIMIT sayımı +
## zorunlu lider (compendium denetimi, Adım 3).
##
## Önceden ArmouryRules yalnız faction tablosu/Elite/LIMIT/el/zırh/Heavy'ye bakıyordu; birimlerin
## kendi "Battlekit" paragrafı hiç uygulanmıyordu: War Wolf 25, Ammo Monk 32 kalem alabiliyordu;
## Wretched 10 ducat tavanı, Death Commando/Nun menzilli kısıtı, Brazen Bull "yalnız Heavy" yoktu.

func _item(id: String) -> Resource:
	return load("res://assets/data/armoury/%s.tres" % id)

func _unit(id: String) -> Resource:
	return load("res://assets/data/units/%s.tres" % id)

func _reason(item_id: String, unit_id: String, faction_id: String) -> String:
	var f: Resource = load("res://assets/data/factions/%s.tres" % faction_id)
	return ArmouryRules.check(_item(item_id), _unit(unit_id), f, {}, [], 9999, 99)

func run(t) -> void:
	var U := ArmouryRules.REASON_UNIT_RULE
	t.eq(_reason("combat_helmet", "war_wolf_assault_beast", "heretic_legion"), U,
		"War Wolf: 'It cannot have any other Battlekit'")
	t.eq(_reason("gas_mask", "grail_thrall", "cult_of_the_black_grail"), ArmouryRules.REASON_NOT_IN_TABLE \
		if not (_item("gas_mask") in load("res://assets/data/factions/cult_of_the_black_grail.tres").armoury) else U,
		"Grail Thrall: 'cannot have any Battlekit'")
	t.eq(_reason("combat_helmet", "hound_of_the_black_grail", "cult_of_the_black_grail"), U,
		"Hound: 'cannot have any Battlekit'")
	t.eq(_reason("standard_armour", "new_antioch_mechanized_heavy_infantry", "new_antioch"), U,
		"MHI: 'any Battlekit ... apart from Armour'")
	t.eq(_reason("combat_helmet", "new_antioch_mechanized_heavy_infantry", "new_antioch"), "",
		"MHI zırh dışı Battlekit alabilir")
	t.eq(_reason("shotgun", "wretched", "heretic_legion"), "", "Wretched 10 ducat'lık Shotgun alabilir")
	t.eq(_reason("semi_automatic_rifle", "wretched", "heretic_legion"), U, "Wretched 15 ducat'lık kalem alamaz")
	t.eq(_reason("pistol", "death_commando", "heretic_legion"), U, "Death Commando: yalnız Silenced Pistol/Tormentor Chains")
	t.eq(_reason("frag_grenades", "death_commando", "heretic_legion"), U, "Death Commando: yalnız Gas Grenades")
	t.eq(_reason("shotgun", "stigmatic_nun", "trench_pilgrims"), U, "Nun: yalnız Pistol/Automatic Pistol")
	t.eq(_reason("bolt_action_rifle", "artillery_witch", "heretic_legion"), U, "Artillery Witch: Ranged Weapon alamaz")
	t.eq(_reason("great_hammer_maul", "brazen_bull", "iron_sultanate"), ArmouryRules.REASON_HANDS \
		if _reason("great_hammer_maul", "brazen_bull", "iron_sultanate") == ArmouryRules.REASON_HANDS else "",
		"Brazen Bull Heavy silahı reddedilmez (kısıt yönünden)")
	t.eq(_reason("pistol", "brazen_bull", "iron_sultanate"), U, "Brazen Bull: yalnız [Heavy] silah")
	t.eq(_reason("shovel", "brazen_bull", "iron_sultanate"), U, "Brazen Bull: Marid Shovel dışında Shovel yok")
	t.eq(_reason("wind_amulet", "lions_of_jabir", "iron_sultanate"), "", "Lion: Wind Amulet alabilir")
	t.eq(_reason("trench_shield", "lions_of_jabir", "iron_sultanate"), U, "Lion: Kalkan alamaz")
	t.eq(_reason("crown_of_hellfire", "court_pit_locust", "court_of_seven_headed_serpent"), "", "Pit Locust: Crown of Hellfire")
	t.eq(_reason("combat_helmet", "court_pit_locust", "court_of_seven_headed_serpent"), U, "Pit Locust başka kalem alamaz")
	t.eq(_reason("shotgun", "court_yoke_fiend", "court_of_seven_headed_serpent"), U,
		"Yoke Fiend: tek menzilli silah (hazır tabanca zaten o hak)")
	t.eq(_reason("trench_club", "heralds_of_beelzebub", "cult_of_the_black_grail"), U, "Herald: yalnız Ranged + Compound Eyes Helmet")

	# One type of Grenade
	t.eq(_reason("incendiary_grenades", "new_antioch_yeoman", "new_antioch"), "", "Bombası olmayan model bomba alabilir")
	var yeo_frag: Resource = LoadoutResolver.resolve_loadout(_unit("new_antioch_yeoman"), 2)
	t.eq(ArmouryRules.check(_item("incendiary_grenades"), yeo_frag, load("res://assets/data/factions/new_antioch.tres"),
		{}, [], 999, 0), ArmouryRules.REASON_GRENADE, "Frag'li Yeoman ikinci tür bomba alamaz")

	# Hazır kit silahları LIMIT'e sayılır
	var mhi: Resource = _unit("new_antioch_mechanized_heavy_infantry")
	var na: Resource = load("res://assets/data/factions/new_antioch.tres")
	var wc: Dictionary = ArmouryRules.weapon_counts([mhi, mhi], na)
	t.eq(int(wc.get(&"machine_gun", 0)), 2, "İki MHI'nin hazır Machine Gun'u sayılır")
	t.eq(ArmouryRules.check(_item("machine_gun"), _unit("new_antioch_yeoman"), na, wc, [], 999, 0),
		ArmouryRules.REASON_LIMIT, "Hazır kitlerle LIMIT dolunca Machine Gun satın alınamaz")

	# Zorunlu lider
	t.eq(RosterRules.warband_ready(&"new_antioch", {"leader": 0}), "ROSTER_FAIL_LEADER", "New Antioch Lieutenant'sız sahaya çıkamaz")
	t.eq(RosterRules.warband_ready(&"iron_sultanate", {"leader": 1}), "", "Yüzbaşı'lı Sultanate hazır")
	t.eq(RosterRules.warband_ready(&"heretic_legion", {}), "ROSTER_FAIL_LEADER", "Heretic Legion Priest'siz sahaya çıkamaz")
	t.eq(RosterRules.warband_ready(&"trench_pilgrims", {"leader": 1}), "", "War Prophet'li Pilgrims hazır")
