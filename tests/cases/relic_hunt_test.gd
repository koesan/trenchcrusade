extends RefCounted

## Relic Hunt senaryosu (compendium: scenarios/relic-hunt) — Reliquary claim/removal/VP döngüsü
## + Glorious Deeds (Relic Hunter, Blood Sacrifice, Protect the Relic).

const MechanicsResolver = preload("res://scripts/rules/mechanics_resolver.gd")
const RelicHuntLogic = preload("res://scripts/rules/scenarios/relic_hunt.gd")
const ScenarioData = preload("res://scripts/data/scenario_data.gd")
const ScenarioObjective = preload("res://scripts/data/scenario_objective.gd")
const UnitData = preload("res://scripts/data/unit_data.gd")

class FakeUnit:
	extends RefCounted
	var owner_id: int = 1
	var name: String = "u1"
	var current_health: int = 10
	var unit_data = null
	var global_position: Vector3 = Vector3.ZERO

func _obj(id: StringName, pos: Vector3) -> ScenarioObjective:
	var o := ScenarioObjective.new()
	o.objective_id = id
	o.position = pos
	o.control_radius = 1.0
	return o

func _data() -> ScenarioData:
	var d := ScenarioData.new()
	d.objectives = [
		_obj(&"r1", Vector3(0, 0, 0)),
		_obj(&"r2", Vector3(10, 0, 0)),
		_obj(&"r3", Vector3(20, 0, 0)),
		_obj(&"r4", Vector3(30, 0, 0)),
	]
	return d

func run(t) -> void:
	# ── MechanicsResolver saf predikatlar ──────────────────────────────────
	t.ok(MechanicsResolver.blood_sacrifice_triggers(3), "3 OOA → Blood Sacrifice tetiklenir")
	t.ok(not MechanicsResolver.blood_sacrifice_triggers(2), "2 OOA → tetiklenmez")
	t.ok(MechanicsResolver.relic_hunter_triggers(2), "2 farklı Reliquary → Relic Hunter tetiklenir")
	t.ok(not MechanicsResolver.relic_hunter_triggers(1), "1 Reliquary → tetiklenmez")
	t.ok(MechanicsResolver.protect_the_relic_triggers(true), "Aktif Reliquary yakınıysa tetiklenir")
	t.ok(not MechanicsResolver.protect_the_relic_triggers(false), "Uzaktaysa tetiklenmez")

	# ── find_claimable_reliquary ─────────────────────────────────────────────
	var logic := RelicHuntLogic.new()
	logic.setup(_data())
	t.eq(logic.find_claimable_reliquary(Vector3(0.5, 0, 0)), &"r1", "1\" içinde → id döner")
	t.eq(logic.find_claimable_reliquary(Vector3(5, 0, 0)), &"", "Menzil dışı → boş döner")

	# ── claim_reliquary ───────────────────────────────────────────────────────
	logic.claim_reliquary(&"r1", 1, "attacker1")
	t.eq(logic.find_claimable_reliquary(Vector3(0.5, 0, 0)), &"",
		"Bu tur zaten claim edildi → tekrar claim edilemez (aynı tur içinde)")
	logic.claim_reliquary(&"r1", 2, "attacker2")
	t.eq(logic._effective_owner(&"r1"), 1, "Aynı tur içinde 2. claim denemesi İLK sahibi DEĞİŞTİRMEZ")

	# ── RELIC HUNTER: 2 farklı Reliquary claim edince tetiklenir ──────────────
	t.ok(not logic.glorious_deeds[1].has(&"relic_hunter"), "1 Reliquary → henüz Relic Hunter yok")
	logic.claim_reliquary(&"r2", 1, "attacker1")
	t.ok(logic.glorious_deeds[1].has(&"relic_hunter"), "2. FARKLI Reliquary → Relic Hunter verilir")

	# ── on_turn_end: VP (1/reliquary tur 1-3, 2/reliquary tur 4) + kaldırma programı ──────────
	var logic2 := RelicHuntLogic.new()
	logic2.setup(_data())
	logic2.claim_reliquary(&"r1", 1, "a1")  # Reliquary 1 → Oyuncu 1
	logic2.claim_reliquary(&"r2", 2, "a2")  # Reliquary 2 → Oyuncu 2
	# r3/r4 hiç claim edilmedi (0 = kimsenin)
	logic2.on_turn_end(1)
	t.eq(logic2.player_vp[1], 1, "Tur 1 sonu: Oyuncu 1 → 1 VP (r1)")
	t.eq(logic2.player_vp[2], 1, "Tur 1 sonu: Oyuncu 2 → 1 VP (r2)")
	t.ok(logic2.is_reliquary_removed(&"r1"), "Tur 1 sonu: İLK Reliquary (r1) kaldırılır")
	t.ok(logic2.is_reliquary_removed(&"r2"), "Tur 1 sonu: İLK 2. Reliquary (r2) kaldırılır")
	t.ok(not logic2.is_reliquary_removed(&"r3"), "r3 henüz kaldırılmadı (tur 2 sonuna kadar)")
	t.eq(logic2._effective_owner(&"r1"), 1, "r1'in sahipliği KALICI kilitlendi (kaldırılsa da)")

	# Tur 2: r1/r2 artık claim edilemez (kaldırıldı), ama VP saymaya devam eder.
	t.eq(logic2.find_claimable_reliquary(Vector3(0, 0, 0)), &"",
		"Kaldırılmış Reliquary artık claim edilemez")
	logic2.claim_reliquary(&"r3", 1, "a1")
	logic2.on_turn_end(2)
	t.eq(logic2.player_vp[1], 1 + 2, "Tur 2 sonu: Oyuncu 1 → r1(kalıcı,+1) + r3(bu tur,+1) = kümülatif 3")
	t.ok(logic2.is_reliquary_removed(&"r3"), "Tur 2 sonu: r3 kaldırılır")
	t.ok(logic2.is_reliquary_removed(&"r4"), "Tur 2 sonu: r4 kaldırılır (kimsenin sahibi olmadan)")
	t.eq(logic2._effective_owner(&"r4"), 0, "r4 hiç claim edilmedi → kalıcı sahibi YOK")

	# Tur 3-4: hepsi kaldırılmış, VP kalıcı sahiplikten gelmeye devam eder (tur 4'te 2x).
	logic2.on_turn_end(3)
	t.eq(logic2.player_vp[1], 3 + 2, "Tur 3: r1+r3 kalıcı sahiplik → +2 (1 VP/reliquary)")
	logic2.on_turn_end(4)
	t.eq(logic2.player_vp[1], 5 + 4, "Tur 4: r1+r3 kalıcı sahiplik → +4 (2 VP/reliquary, compendium)")

	# ── PROTECT THE RELIC + BLOOD SACRIFICE (on_unit_out_of_action) ──────────
	var logic3 := RelicHuntLogic.new()
	logic3.setup(_data())
	var attacker := FakeUnit.new()
	attacker.owner_id = 1
	attacker.name = "protector"
	var near_target := FakeUnit.new()
	near_target.owner_id = 2
	near_target.global_position = Vector3(0.3, 0, 0)  # r1'e (0,0,0) çok yakın, henüz kaldırılmadı
	var far_target := FakeUnit.new()
	far_target.owner_id = 2
	far_target.global_position = Vector3(100, 0, 0)

	logic3.on_unit_out_of_action(attacker, near_target, true, {"is_ooa": true})
	t.ok(logic3.glorious_deeds[1].has(&"protect_the_relic"),
		"Aktif Reliquary'nin 1\" içindeki düşman OOA → Protect the Relic verilir")

	var logic4 := RelicHuntLogic.new()
	logic4.setup(_data())
	logic4.on_unit_out_of_action(attacker, far_target, true, {"is_ooa": true})
	t.ok(not logic4.glorious_deeds[1].has(&"protect_the_relic"),
		"Reliquary'den uzak düşman OOA → Protect the Relic verilmez")

	# Blood Sacrifice: aynı model 3 farklı düşmanı OOA eder (konum önemsiz, uzak hedefler kullanıldı;
	# TAZE bir logic/attacker — logic4 zaten yukarıda 1 OOA saydı, sayaç karışmasın).
	var logic6 := RelicHuntLogic.new()
	logic6.setup(_data())
	var sacrificer := FakeUnit.new()
	sacrificer.owner_id = 1
	sacrificer.name = "sacrificer"
	var v1 := FakeUnit.new(); v1.owner_id = 2; v1.global_position = Vector3(100, 0, 0)
	var v2 := FakeUnit.new(); v2.owner_id = 2; v2.global_position = Vector3(101, 0, 0)
	var v3 := FakeUnit.new(); v3.owner_id = 2; v3.global_position = Vector3(102, 0, 0)
	logic6.on_unit_out_of_action(sacrificer, v1, true, {"is_ooa": true})
	logic6.on_unit_out_of_action(sacrificer, v2, true, {"is_ooa": true})
	t.ok(not logic6.glorious_deeds[1].has(&"blood_sacrifice"), "2 OOA → henüz Blood Sacrifice yok")
	logic6.on_unit_out_of_action(sacrificer, v3, true, {"is_ooa": true})
	t.ok(logic6.glorious_deeds[1].has(&"blood_sacrifice"), "3. OOA (aynı model, oyun boyunca) → verilir")

	# ── evaluate_end_of_game: VP + tamamlanan deed başına +1 ──────────────────
	var logic5 := RelicHuntLogic.new()
	logic5.setup(_data())
	logic5.player_vp = {1: 4, 2: 2}
	logic5.glorious_deeds = {1: [&"relic_hunter"], 2: []}
	var result: Dictionary = logic5.evaluate_end_of_game()
	t.eq(result["vp"][1], 5, "Oyuncu 1: 4 VP + 1 deed = 5")
	t.eq(result["vp"][2], 2, "Oyuncu 2: 2 VP + 0 deed = 2")
	t.eq(result["winner"], 1, "Daha yüksek toplam kazanır")

	# ── ScenarioManager otomatik keşif: relic_hunt.tres taranan klasörde mi? ──
	var found := false
	for s in ScenarioManager.available_scenarios:
		if s != null and s.scenario_id == &"relic_hunt":
			found = true
			t.eq(s.turn_limit, 4, "Relic Hunt → 4 tur (compendium)")
			t.ok(not s.infiltrators_allowed, "Relic Hunt → Infiltrators Not Allowed (compendium)")
			t.eq(s.objectives.size(), 4, "Relic Hunt → 4 Reliquary")
			t.ok(bool(s.special_rules.get(&"skip_morale", false)),
				"Relic Hunt → To The Death! (skip_morale)")
	t.ok(found, "relic_hunt.tres ScenarioManager tarafından otomatik keşfedildi")
