extends RefCounted

## Marked for Death (Ölüm Damgası) — özgün senaryo: Bounty Target belirleme/yeniden-atama +
## VP (bounty avı +3, koruma +1/tur) + Glorious Deeds (Head Hunter, Untouchable).

const MechanicsResolver = preload("res://scripts/rules/mechanics_resolver.gd")
const MarkedForDeathLogic = preload("res://scripts/rules/scenarios/marked_for_death.gd")
const UnitData = preload("res://scripts/data/unit_data.gd")

class FakeUnit:
	extends RefCounted
	var owner_id: int = 1
	var name: String = "u1"
	var current_health: int = 10
	var unit_data = null
	var global_position: Vector3 = Vector3.ZERO
	var display_name: String = "Fake"
	# NOT: set_bounty_target() BİLİNÇLİ eklenmedi — _sync_badge() has_method() ile korunuyor,
	# gerçek unit.gd (Node, .multiplayer'a sahip) DIŞINDAKİ testlerde RPC yoluna hiç girilmez
	# (RefCounted'ın multiplayer property'si yok). Bu test yalnız SAF durum mantığını (bounty_target
	# dict) doğrular, görsel rozet senkronu ayrı bir katman (canlı test/entegrasyon konusu).

func _ud(cost: int) -> UnitData:
	var u := UnitData.new()
	u.cost = cost
	return u

func run(t) -> void:
	t.ok(MechanicsResolver.head_hunter_triggers(3), "3 farklı Bounty Target avı → Head Hunter tetiklenir")
	t.ok(not MechanicsResolver.head_hunter_triggers(2), "2 → tetiklenmez")

	var logic := MarkedForDeathLogic.new()
	logic.setup(null)

	# ── establish_bounty_targets: en pahalı SAHADAKİ model seçilir ────────────
	var cheap1 := FakeUnit.new(); cheap1.owner_id = 1; cheap1.name = "p1_cheap"; cheap1.unit_data = _ud(20)
	var expensive1 := FakeUnit.new(); expensive1.owner_id = 1; expensive1.name = "p1_expensive"; expensive1.unit_data = _ud(150)
	var dead1 := FakeUnit.new(); dead1.owner_id = 1; dead1.name = "p1_dead"; dead1.unit_data = _ud(300); dead1.current_health = 0
	var only2 := FakeUnit.new(); only2.owner_id = 2; only2.name = "p2_only"; only2.unit_data = _ud(80)

	GameState.units[&"p1_cheap"] = cheap1
	GameState.units[&"p1_expensive"] = expensive1
	GameState.units[&"p1_dead"] = dead1
	GameState.units[&"p2_only"] = only2

	logic.establish_bounty_targets()
	t.eq(logic.bounty_target[1], "p1_expensive", "Oyuncu 1 → en pahalı CANLI model seçilir (150 Cost)")
	t.eq(logic.original_bounty_target[1], "p1_expensive", "Orijinal Bounty Target da aynı şekilde kilitlenir")
	t.eq(logic.bounty_target[2], "p2_only", "Oyuncu 2 → tek canlı modeli seçilir")

	# ── Bounty Target OOA olunca +3 VP + yeniden atama ────────────────────────
	# NOT: gerçek oyunda resolve_injury_roll, ScenarioLogic çağrılmadan ÖNCE current_health'i 0'a
	# indirir — test bunu simüle etmeli, aksi halde _highest_cost_living_unit expensive1'i hâlâ
	# "canlı" sayıp yeniden seçer (bu satır olmadan bu test yanlışlıkla başarısız oluyordu).
	expensive1.current_health = 0
	var attacker2 := FakeUnit.new(); attacker2.owner_id = 2; attacker2.name = "attacker2"
	logic.on_unit_out_of_action(attacker2, expensive1, true, {"is_ooa": true})
	t.eq(logic.player_vp[2], 3, "Bounty Target avlandı → saldırana +3 VP")
	t.eq(logic.bounty_target[1], "p1_cheap", "Oyuncu 1'in YENİ Bounty Target'ı → sıradaki en pahalı canlı (p1_cheap)")

	# Aynı hedefi (artık ölü) tekrar OOA etmek bir şey yapmaz (zaten değişti, was_bounty=false)
	logic.on_unit_out_of_action(attacker2, expensive1, true, {"is_ooa": true})
	t.eq(logic.player_vp[2], 3, "Aynı (artık eski) hedefi tekrar 'öldürmek' VP eklemez")

	# Normal (bounty olmayan) bir düşman OOA etmek bounty VP eklemez.
	var random_enemy := FakeUnit.new(); random_enemy.owner_id = 1; random_enemy.name = "random_enemy"
	logic.on_unit_out_of_action(attacker2, random_enemy, true, {"is_ooa": true})
	t.eq(logic.player_vp[2], 3, "Bounty olmayan hedef → +3 VP eklenmez")

	# ── on_turn_end: orijinal Bounty Target hayattaysa +1 VP ──────────────────
	var logic2 := MarkedForDeathLogic.new()
	logic2.setup(null)
	var vip := FakeUnit.new(); vip.owner_id = 1; vip.name = "vip"; vip.unit_data = _ud(200)
	GameState.units[&"vip"] = vip
	GameState.units.erase(&"p1_cheap"); GameState.units.erase(&"p1_expensive")
	GameState.units.erase(&"p1_dead"); GameState.units.erase(&"p2_only"); GameState.units.erase(&"random_enemy")
	logic2.establish_bounty_targets()
	t.eq(logic2.bounty_target[1], "vip", "Tek canlı model → Bounty Target")
	logic2.on_turn_end(1)
	t.eq(logic2.player_vp[1], 1, "Tur sonu: orijinal Bounty Target hayatta → +1 VP")
	logic2.on_turn_end(2)
	t.eq(logic2.player_vp[1], 2, "2. tur sonu: hâlâ hayatta → kümülatif +1 daha")

	vip.current_health = 0
	logic2.on_turn_end(3)
	t.eq(logic2.player_vp[1], 2, "VIP öldükten sonra → artık +1 VP gelmez")

	# ── evaluate_end_of_game: Untouchable deed (orijinal hedef hayatta bitirdi) ──
	var logic3 := MarkedForDeathLogic.new()
	logic3.setup(null)
	var survivor := FakeUnit.new(); survivor.owner_id = 1; survivor.name = "survivor"; survivor.unit_data = _ud(100)
	GameState.units[&"survivor"] = survivor
	logic3.establish_bounty_targets()
	var result: Dictionary = logic3.evaluate_end_of_game()
	t.ok(logic3.glorious_deeds[1].has(&"untouchable"), "Orijinal Bounty Target hayatta oyunu bitirdi → Untouchable")
	t.eq(result["vp"][1], 1, "1 deed (Untouchable) → +1 VP toplam")

	GameState.units.erase(&"vip")
	GameState.units.erase(&"survivor")

	# ── ScenarioManager otomatik keşif ─────────────────────────────────────────
	var found := false
	for s in ScenarioManager.available_scenarios:
		if s != null and s.scenario_id == &"marked_for_death":
			found = true
			t.eq(s.turn_limit, 4, "Marked for Death → 4 tur")
			t.ok(s.infiltrators_allowed, "Marked for Death → Infiltrator serbest (harita kısıtı yok)")
			t.eq(s.objectives.size(), 0, "Marked for Death → harita objective'i YOK (terrain gerektirmez)")
	t.ok(found, "marked_for_death.tres ScenarioManager tarafından otomatik keşfedildi")
