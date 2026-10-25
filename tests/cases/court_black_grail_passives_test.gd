extends RefCounted

## FAZ 2 (P0-6): Court/Black Grail'in daha önce ölü veri olan 6 pasifi — SAF predikatlar.
## Annihilator (Desecrated Saint), Torturer (Yoke Fiend), Law of Hell (Wretched),
## Beelzebub's Touch (Lord of Tumours), Parasite Host (Corpse Guard) + Ignore Off-Hand Weapon
## (Mamluk Faris). Goetic-büyü etiketli (blood_magic/blessings_of_serpent_moon/left_hand_path/
## oracle_beast_cloak) ve Demonic Aura (Deadly Sin dedikasyonuna bağlı) BİLİNÇLİ ERTELENDİ —
## bu test onları kapsamaz (bkz. plan.md P0-6 notu).

const MechanicsResolver = preload("res://scripts/rules/mechanics_resolver.gd")
const CombatResolver = preload("res://scripts/rules/combat_resolver.gd")
const UnitActions = preload("res://scripts/unit/unit_actions.gd")
const UnitData = preload("res://scripts/data/unit_data.gd")
const AttackData = preload("res://scripts/data/attack_data.gd")

func _ud(kw: Dictionary, attacks: Array[Resource] = []) -> UnitData:
	var u := UnitData.new()
	u.keywords = kw
	u.attacks = attacks
	return u

func run(t) -> void:
	# LAW OF HELL
	var wretched := _ud({&"law_of_hell": 1})
	var elite_enemy := _ud({&"elite": 1})
	var normal_enemy := _ud({})
	t.ok(MechanicsResolver.law_of_hell_triggers(wretched, elite_enemy, true),
		"Wretched Elite'i OOA eder → özgürlük")
	t.ok(not MechanicsResolver.law_of_hell_triggers(wretched, normal_enemy, true),
		"Elite olmayan düşman → tetiklenmez")
	t.ok(not MechanicsResolver.law_of_hell_triggers(wretched, elite_enemy, false),
		"OOA değil → tetiklenmez")
	t.ok(not MechanicsResolver.law_of_hell_triggers(_ud({}), elite_enemy, true),
		"law_of_hell yok → tetiklenmez")

	# BEELZEBUB'S TOUCH
	var lord := _ud({&"beelzebubs_touch": 1})
	t.ok(MechanicsResolver.beelzebubs_touch_triggers(lord, true, true),
		"Melee + marker koyuldu → tetiklenir")
	t.ok(not MechanicsResolver.beelzebubs_touch_triggers(lord, false, true),
		"Menzilli saldırı → tetiklenmez")
	t.ok(not MechanicsResolver.beelzebubs_touch_triggers(lord, true, false),
		"Marker koyulmadı → tetiklenmez")
	t.ok(not MechanicsResolver.beelzebubs_touch_triggers(_ud({}), true, true),
		"beelzebubs_touch yok → tetiklenmez")

	# PARASITE HOST
	var corpse := _ud({&"parasite_host": 1})
	t.ok(MechanicsResolver.parasite_host_triggers(corpse, true, true),
		"Melee + marker koyuldu → tetiklenir")
	t.ok(not MechanicsResolver.parasite_host_triggers(corpse, true, false),
		"Marker koyulmadı → tetiklenmez")

	# TORTURER / WHIP OF GOD — dost hedef izni (CombatResolver tek kaynak)
	var yoke_fiend := _ud({&"torturer": 1})
	var demonic_ally := _ud({&"demonic": 1})
	var non_demonic_ally := _ud({})
	t.ok(CombatResolver.allows_friendly_melee_target(yoke_fiend, non_demonic_ally),
		"Torturer: Demonic olmayan dost hedeflenebilir")
	t.ok(not CombatResolver.allows_friendly_melee_target(yoke_fiend, demonic_ally),
		"Torturer: Demonic dost hedeflenemez")
	t.ok(not CombatResolver.allows_friendly_melee_target(_ud({}), non_demonic_ally),
		"Torturer yok → dost hedef yasak")
	var castigator := _ud({&"whip_of_god": 1})
	t.ok(CombatResolver.allows_friendly_melee_target(castigator, demonic_ally),
		"Whip of God: her dost hedeflenebilir (Demonic dahil)")

	# ANNIHILATOR — çoklu Fight aksiyonu (UnitActions._melee_weapon_count saf yardımcı)
	var sword := AttackData.new()
	sword.attack_type = "MELEE"
	var axe := AttackData.new()
	axe.attack_type = "MELEE"
	var pistol := AttackData.new()
	pistol.attack_type = "RANGED"
	var saint_attacks: Array[Resource] = [sword, axe, pistol]
	t.eq(UnitActions._melee_weapon_count(_ud({}, saint_attacks)), 2,
		"3 silahtan 2'si MELEE → melee_weapon_count=2")
	t.eq(UnitActions._melee_weapon_count(_ud({}, [])), 0,
		"Silahsız → 0")
