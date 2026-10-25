extends RefCounted

## FAZ 3 (P1-5): Glorious Deeds altyapısı — saf predikatlar (MechanicsResolver) +
## ScenarioLogic.award_deed (taban sınıf, "ilk tamamlayan kazanır, bir kez") +
## ClaimNoMansLandLogic'in 6 bağlı deed'i (Cast Them Down kasıtlı hariç, bkz. plan.md).

const MechanicsResolver = preload("res://scripts/rules/mechanics_resolver.gd")
const ScenarioLogic = preload("res://scripts/rules/scenario_logic.gd")
const ClaimNoMansLandLogic = preload("res://scripts/rules/scenarios/claim_no_mans_land.gd")
const UnitData = preload("res://scripts/data/unit_data.gd")

class FakeUnit:
	extends RefCounted
	var owner_id: int = 1
	var name: String = "u1"
	var current_health: int = 10
	var unit_data = null
	var global_position: Vector3 = Vector3.ZERO
	var stood_up_this_activation: bool = false

func _ud(kw: Dictionary) -> UnitData:
	var u := UnitData.new()
	u.keywords = kw
	return u

func run(t) -> void:
	# ── MechanicsResolver saf predikatlar ──────────────────────────────────
	t.ok(MechanicsResolver.bloodletting_triggers(5, 6), "5→6 Blood Marker: 6.sı kondu → tetiklenir")
	t.ok(not MechanicsResolver.bloodletting_triggers(6, 6), "Zaten 6'daysa (artış yok) → tetiklenmez")
	t.ok(not MechanicsResolver.bloodletting_triggers(3, 4), "4'e çıkış (6 değil) → tetiklenmez")

	t.ok(MechanicsResolver.sniper_deed_triggers(false, true, true, true),
		"Menzilli+uzun menzil+siper+Elite → Sniper tetiklenir")
	t.ok(not MechanicsResolver.sniper_deed_triggers(true, true, true, true),
		"Melee → Sniper tetiklenmez")
	t.ok(not MechanicsResolver.sniper_deed_triggers(false, false, true, true),
		"Uzun menzil değil → tetiklenmez")
	t.ok(not MechanicsResolver.sniper_deed_triggers(false, true, false, true),
		"Siper yok → tetiklenmez")
	t.ok(not MechanicsResolver.sniper_deed_triggers(false, true, true, false),
		"Hedef Elite değil → tetiklenmez")

	t.ok(MechanicsResolver.suicidal_bravery_triggers(2), "2 düşmanla angaje → tetiklenir")
	t.ok(MechanicsResolver.suicidal_bravery_triggers(3), "3 düşmanla angaje → tetiklenir")
	t.ok(not MechanicsResolver.suicidal_bravery_triggers(1), "Tek düşman → tetiklenmez")

	# ── ScenarioLogic.award_deed (taban sınıf) ─────────────────────────────
	var base := ScenarioLogic.new()
	base.setup(null)
	t.ok(base.award_deed(1, &"test_deed"), "İlk verilişte true döner")
	t.ok(not base.award_deed(1, &"test_deed"), "Aynı oyuncuya ikinci kez verilmez")
	t.ok(not base.award_deed(2, &"test_deed"), "Başka oyuncuya da verilmez (ilk kazanan alır)")
	t.eq(base.glorious_deeds[1].size(), 1, "Oyuncu 1'in deed listesi 1 eleman")
	t.eq(base.glorious_deeds[2].size(), 0, "Oyuncu 2'nin deed listesi boş")

	# ── ClaimNoMansLandLogic — entegrasyon ─────────────────────────────────
	var logic := ClaimNoMansLandLogic.new()
	logic.setup(null)

	var attacker := FakeUnit.new()
	attacker.owner_id = 1
	attacker.name = "attacker"
	var target := FakeUnit.new()
	target.owner_id = 2
	target.unit_data = _ud({&"elite": 1})

	# BLOODLETTING (OOA gerekmez)
	logic.on_unit_out_of_action(attacker, target, false, {"blood_before": 5, "blood_after": 6, "is_ooa": false})
	t.ok(logic.glorious_deeds[1].has(&"bloodletting"), "Bloodletting: OOA olmadan da tetiklenir")

	# SNIPER (OOA + menzilli + uzun menzil + siper + Elite hedef)
	logic.on_unit_out_of_action(attacker, target, false,
		{"is_ooa": true, "is_long_range": true, "in_cover": true})
	t.ok(logic.glorious_deeds[1].has(&"sniper"), "Sniper: OOA+uzun menzil+siper+Elite → verilir")

	# LORD OF WAR (aynı model, aynı Turn'de 2. melee OOA)
	logic.on_unit_out_of_action(attacker, target, true, {"is_ooa": true})
	t.ok(not logic.glorious_deeds[1].has(&"lord_of_war"), "Lord of War: 1. melee OOA yeterli değil")
	logic.on_unit_out_of_action(attacker, target, true, {"is_ooa": true})
	t.ok(logic.glorious_deeds[1].has(&"lord_of_war"), "Lord of War: 2. melee OOA (aynı Turn) → verilir")

	# Turn sonu sayaç sıfırlama (Lord of War zaten oyuncu 1'e verildi — bu bölüm ayrı, taze bir
	# logic ile SAYAÇ sıfırlamasını izole test eder; "bir kez/oyun" kuralı yukarıda zaten kanıtlandı).
	var logic_reset := ClaimNoMansLandLogic.new()
	logic_reset.setup(null)
	var attacker2 := FakeUnit.new(); attacker2.owner_id = 2; attacker2.name = "attacker2"
	logic_reset.on_unit_out_of_action(attacker2, target, true, {"is_ooa": true})
	logic_reset.on_turn_end(1)
	logic_reset.on_unit_out_of_action(attacker2, target, true, {"is_ooa": true})
	t.ok(not logic_reset.glorious_deeds[2].has(&"lord_of_war"),
		"Turn sıfırlaması: önceki Turn'ün 1 OOA'sı yeni Turn'e taşınmaz (2. OOA yine 1. sayılır)")
	logic_reset.on_unit_out_of_action(attacker2, target, true, {"is_ooa": true})
	t.ok(logic_reset.glorious_deeds[2].has(&"lord_of_war"),
		"Yeni Turn içinde 2. melee OOA → verilir")

	# RESIST AND BITE
	var logic2 := ClaimNoMansLandLogic.new()
	logic2.setup(null)
	logic2.on_unit_out_of_action(attacker, target, true, {"is_ooa": true, "attacker_began_down": true})
	t.ok(logic2.glorious_deeds[1].has(&"resist_and_bite"), "Resist and Bite: Down başlayıp OOA edince verilir")

	# HOLD YOUR GROUND
	var logic3 := ClaimNoMansLandLogic.new()
	logic3.setup(null)
	logic3.on_morale_check_passed(2)
	t.ok(logic3.glorious_deeds[2].has(&"hold_your_ground"), "Hold Your Ground: ilk geçen ordu")
	logic3.on_morale_check_passed(1)
	t.ok(not logic3.glorious_deeds[1].has(&"hold_your_ground"), "İkinci geçen ordu deed'i almaz")

	# SUICIDAL BRAVERY
	var logic4 := ClaimNoMansLandLogic.new()
	logic4.setup(null)
	var charger := FakeUnit.new(); charger.owner_id = 1
	logic4.on_successful_charge(charger, 1)
	t.ok(not logic4.glorious_deeds[1].has(&"suicidal_bravery"), "Tek düşmanla angaje → verilmez")
	logic4.on_successful_charge(charger, 2)
	t.ok(logic4.glorious_deeds[1].has(&"suicidal_bravery"), "İki düşmanla angaje → verilir")

	# ── GATHER KNOWLEDGE (Combat Biologist, P1-1) — taban sınıfta, super() ile miras ────────
	# Compendium: warband'da bir Combat Biologist varsa TÜM senaryolara eklenir; "3+ düşman,
	# dost Combat Biologist'in 1" içindeyken OOA olursa" tamamlanır.
	var biologist := FakeUnit.new()
	biologist.owner_id = 1
	biologist.name = "biologist"
	biologist.unit_data = _ud({&"battlefield_vivisection": 1})
	biologist.global_position = Vector3(0, 0, 0)
	GameState.units[&"gk_attacker"] = attacker
	GameState.units[&"gk_biologist"] = biologist

	var logic5 := ClaimNoMansLandLogic.new()
	logic5.setup(null)
	var victim1 := FakeUnit.new(); victim1.owner_id = 2; victim1.global_position = Vector3(0.5, 0, 0)
	var victim2 := FakeUnit.new(); victim2.owner_id = 2; victim2.global_position = Vector3(0.6, 0, 0)
	var victim3 := FakeUnit.new(); victim3.owner_id = 2; victim3.global_position = Vector3(0.7, 0, 0)
	var far_victim := FakeUnit.new(); far_victim.owner_id = 2; far_victim.global_position = Vector3(50, 0, 0)

	logic5.on_unit_out_of_action(attacker, far_victim, true, {"is_ooa": true})
	t.ok(not logic5.glorious_deeds[1].has(&"gather_knowledge"),
		"Biologist'ten uzakta OOA → sayılmaz")
	logic5.on_unit_out_of_action(attacker, victim1, true, {"is_ooa": true})
	logic5.on_unit_out_of_action(attacker, victim2, true, {"is_ooa": true})
	t.ok(not logic5.glorious_deeds[1].has(&"gather_knowledge"), "2 OOA yeterli değil")
	logic5.on_unit_out_of_action(attacker, victim3, true, {"is_ooa": true})
	t.ok(logic5.glorious_deeds[1].has(&"gather_knowledge"), "3. OOA (Biologist'in 1\" içinde) → verilir")

	GameState.units.erase(&"gk_attacker")
	GameState.units.erase(&"gk_biologist")
