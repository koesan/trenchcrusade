extends RefCounted

## P1-1 (Court of the Seven-Headed Serpent): Goetic Spell altyapısının SAF/veri parçaları.
## Async/CombatChoice/harita-tıklama gerektiren parçalar (pay_goetic_cost, try_cast_reactive_
## goetic, blood_drain pick akışı, Slavemaster komutları, Burning Inferno'nun kendisi) headless
## test edilemez — canlı doğrulanmalı (bu projenin genel async/RPC kuralıyla tutarlı).

const MechanicsResolver = preload("res://scripts/rules/mechanics_resolver.gd")
const KeywordSystem = preload("res://scripts/rules/keyword_system.gd")
const UnitData = preload("res://scripts/data/unit_data.gd")
const AttackData = preload("res://scripts/data/attack_data.gd")
const AbilityExecutor = preload("res://scripts/rules/ability_executor.gd")
const AbilityData = preload("res://scripts/data/ability_data.gd")

class _FakeUnit:
	extends RefCounted
	var unit_data
	var owner_id: int = 1
	var current_health: int = 10
	var global_position: Vector3 = Vector3.ZERO

func _kw(path: String) -> Dictionary:
	var ud = load("res://assets/data/units/" + path + ".tres")
	if ud == null:
		return {}
	return ud.keywords

func run(t) -> void:
	# ── is_goetic_blood_source: Demonic/Black Grail HARİÇ herkesten alınabilir ──
	var demonic_ud := UnitData.new()
	demonic_ud.keywords = {&"demonic": 1}
	t.ok(not MechanicsResolver.is_goetic_blood_source(demonic_ud), "Demonic → Goetic kaynağı OLAMAZ")

	var black_grail_ud := UnitData.new()
	black_grail_ud.keywords = {&"black_grail": 1}
	t.ok(not MechanicsResolver.is_goetic_blood_source(black_grail_ud), "Black Grail → Goetic kaynağı OLAMAZ")

	var heretic_ud := UnitData.new()
	heretic_ud.keywords = {&"heretic": 1}
	t.ok(MechanicsResolver.is_goetic_blood_source(heretic_ud), "Heretic → Goetic kaynağı OLABİLİR (yalnız Demonic/Black Grail hariç)")

	var plain_ud := UnitData.new()
	t.ok(MechanicsResolver.is_goetic_blood_source(plain_ud), "Sıradan bir model → Goetic kaynağı OLABİLİR")
	t.ok(not MechanicsResolver.is_goetic_blood_source(null), "null → false (güvenli varsayılan)")

	# ── court_wretched_deploy_allowed: Demonic sayısı Wretched sayısını KESİN aşmalı ──
	t.ok(MechanicsResolver.court_wretched_deploy_allowed(2, 1), "2 Demonic, 1 Wretched → izinli")
	t.ok(not MechanicsResolver.court_wretched_deploy_allowed(1, 1), "1 Demonic, 1 Wretched → EŞİTLİK yetmez, reddedilir")
	t.ok(not MechanicsResolver.court_wretched_deploy_allowed(0, 1), "0 Demonic, 1 Wretched → reddedilir")
	t.ok(MechanicsResolver.court_wretched_deploy_allowed(3, 2), "3 Demonic, 2 Wretched → izinli")

	# ── first_ranged_attack: first_melee_attack ile aynı desen ──
	var melee_a := AttackData.new()
	melee_a.attack_type = "MELEE"
	var ranged_a := AttackData.new()
	ranged_a.attack_type = "RANGED"
	var ud_mixed := UnitData.new()
	ud_mixed.attacks = [melee_a, ranged_a]
	t.eq(MechanicsResolver.first_ranged_attack(ud_mixed), ranged_a, "first_ranged_attack: karışık silahlardan RANGED olanı seçer")
	var ud_melee_only := UnitData.new()
	ud_melee_only.attacks = [melee_a]
	t.eq(MechanicsResolver.first_ranged_attack(ud_melee_only), null, "first_ranged_attack: RANGED silah yoksa null")

	# ── Leader kuralı (Nobles of the Court, P1-21): Sorcerer de is_leader olmalı (Praetor gibi) ──
	var sorcerer = load("res://assets/data/units/court_auxilia_sorceror.tres")
	t.ok(sorcerer.is_leader, "Sorcerer → is_leader=true (Morale +1 Dice bonusu Praetor gibi tetiklenmeli)")
	var praetor = load("res://assets/data/units/court_praetor.tres")
	t.ok(praetor.is_leader, "Praetor → is_leader=true (regresyon)")

	# ── Reaktif Goetic Spell keyword'leri doğru birimlere bağlı ──
	t.eq(int(_kw("court_auxilia_sorceror").get(&"blessings_of_serpent_moon", 0)), 1,
		"Sorcerer → blessings_of_serpent_moon=1")
	t.eq(int(_kw("court_hell_knight").get(&"blood_magic", 0)), 1,
		"Hell Knight → blood_magic=1")
	t.eq(int(_kw("court_hunter_of_the_left_hand_path").get(&"oracle_beast_cloak", 0)), 1,
		"Hunter of the Left Hand Path → oracle_beast_cloak=1")

	# ── Wretched roster kısıtı keyword'ü ──
	t.eq(int(_kw("court_wretched").get(&"outnumbered_by_demonic_required", 0)), 1,
		"Court Wretched → outnumbered_by_demonic_required=1")

	# ── Slavemaster hedefleme: yalnız Yoke Fiend (vekil: &hateful) ──
	var slavemaster_ab: AbilityData = load("res://assets/data/abilities/slavemaster.tres")
	var caster := _FakeUnit.new()
	caster.unit_data = UnitData.new()
	var yoke := _FakeUnit.new()
	yoke.owner_id = 1
	yoke.unit_data = UnitData.new()
	yoke.unit_data.keywords = {&"hateful": 1}
	var non_yoke := _FakeUnit.new()
	non_yoke.owner_id = 1
	non_yoke.unit_data = UnitData.new()

	t.ok(AbilityExecutor.is_valid_ability_target(slavemaster_ab, caster, yoke),
		"Slavemaster: Yoke Fiend (hateful) geçerli hedef")
	t.ok(not AbilityExecutor.is_valid_ability_target(slavemaster_ab, caster, non_yoke),
		"Slavemaster: Yoke Fiend OLMAYAN dost geçersiz hedef")

	# ── Goetic Gaze kritik bonusu (add_blood crit_amount deseni) ──
	var goetic_gaze_ab: AbilityData = load("res://assets/data/abilities/goetic_gaze.tres")
	t.eq(goetic_gaze_ab.crit_amount, 2, "Goetic Gaze: Kritik Başarı → +2 Kan İşareti (crit_amount)")

	# ── Bow of Lethe / Tenderiser Maul silah-keyword bağlantıları ──
	var bow: AttackData = load("res://assets/data/attacks/bow_of_lethe.tres")
	t.ok(KeywordSystem.has(bow, &"special_ammunition"), "Bow of Lethe → special_ammunition keyword'ü var")
	var maul: AttackData = load("res://assets/data/attacks/tenderiser_maul.tres")
	t.ok(KeywordSystem.has(maul, &"swinging_blow"), "Tenderiser Maul → swinging_blow keyword'ü var")
	t.ok(KeywordSystem.has(maul, &"heavy"), "Tenderiser Maul → heavy keyword'ü var (RAW: [Heavy])")

	# ── negate_heavy_effect vs blanket negate_heavy (Assault Drill/Battlefield Demolition ile
	# AYNI ayrım, ama Sin Eater burada blanket negate_heavy'yi DOĞRU kullanıyor — regresyon) ──
	t.eq(int(_kw("sin_eater").get(&"negate_heavy", 0)), 1, "Sin Eater → blanket negate_heavy=1 (STRONG'dan)")

	# ── total_available_goetic_blood: pay_goetic_cost'un blood_drain pick modunu HİÇ açmadan önce
	# ön-kontrolü (canlı test bulgusu: sahada Kan İşareti yokken Slavemaster/Burning Inferno/Shadow
	# Walker "butona bastım hiçbir şey olmadı" hissi veriyordu — 30sn'lik sessiz kilitlenme). ──
	t.eq(MechanicsResolver.total_available_goetic_blood([]), 0, "Boş saha → 0 Kan İşareti")
	t.eq(MechanicsResolver.total_available_goetic_blood([
		{"blood_markers": 0, "unit_data": plain_ud},
	]), 0, "Kan İşareti 0 olan model katkı vermez")
	t.eq(MechanicsResolver.total_available_goetic_blood([
		{"blood_markers": 2, "unit_data": plain_ud},
		{"blood_markers": 1, "unit_data": demonic_ud},
		{"blood_markers": 3, "unit_data": black_grail_ud},
	]), 2, "Demonic/Black Grail'in Kan İşaretleri SAYILMAZ (yalnız sıradan modelin 2'si)")
	t.eq(MechanicsResolver.total_available_goetic_blood([
		{"blood_markers": 2, "unit_data": plain_ud},
		{"blood_markers": 3, "unit_data": heretic_ud},
	]), 5, "Heretic (Demonic/Black Grail DEĞİL) → kaynağa dahil, toplam 5")
