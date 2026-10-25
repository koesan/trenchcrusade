## "Claim No Man's Land" senaryo mantığı (compendium: scenarios/claim-no-mans-land).
##
## 4 tur. 5 objective. Kontrol = 1" içinde daha fazla dost model. Tur sonu her kontrol edilen
## objective için 2 VP. Oyun sonunda en çok VP kazanır (düşman sahadan silinirse/kaçarsa anında).
##
## Objective VP puanlaması ve tur limiti taban ScenarioLogic tarafından karşılanır. Bu sınıf
## 7 Glorious Deed'den 6'sını değerlendirir (P1-5): Sniper, Lord of War, Bloodletting,
## Hold Your Ground, Suicidal Bravery, Resist and Bite. "Cast Them Down" (düşmanı 3"+ düşürme)
## KASITLI OLARAK BAĞLANMADI — oyunda hiçbir mekanik düşmanı zorla düşürmüyor (push/knockback
## yok), tetikleme noktası yok; bkz. plan.md P1-5 notu.
class_name ClaimNoMansLandLogic
extends ScenarioLogic

## LORD OF WAR: "A friendly model takes two enemy models Out of Action with Melee Attacks in a
## single Turn." Aynı modelin bu TUR içindeki melee-OOA sayısı. { unit_name: String -> count: int }
## Her Turn sonunda (on_turn_end) sıfırlanır.
var _melee_ooa_this_turn: Dictionary = {}

func setup(p_data: ScenarioData) -> void:
	super.setup(p_data)
	_melee_ooa_this_turn = {}

## KAYIT/YÜKLEME: bkz. scenario_logic.gd::save_state.
func save_state() -> Dictionary:
	var d := super.save_state()
	d["melee_ooa_this_turn"] = _melee_ooa_this_turn.duplicate(true)
	return d

func load_state(d: Dictionary) -> void:
	super.load_state(d)
	_melee_ooa_this_turn = d.get("melee_ooa_this_turn", {}).duplicate(true)

func on_turn_end(round_number: int) -> void:
	super.on_turn_end(round_number)
	_melee_ooa_this_turn = {}

## Her Injury Roll sonucunda çağrılır (unit.gd::resolve_injury_roll) — OOA olsun olmasın (Bloodletting
## OOA koşullu değil). ctx["is_ooa"] hedefin bu saldırıyla Out of Action olup olmadığını taşır.
func on_unit_out_of_action(attacker, target, is_melee: bool, ctx: Dictionary = {}) -> void:
	super.on_unit_out_of_action(attacker, target, is_melee, ctx)  # P1-1: Gather Knowledge (taban sınıf)
	if attacker == null or not is_instance_valid(attacker):
		return
	var pid: int = attacker.owner_id
	var is_ooa: bool = ctx.get("is_ooa", false)

	# BLOODLETTING (OOA koşulu YOK — herhangi bir saldırı 6. Blood Marker'ı koyabilir)
	if MechanicsResolver.bloodletting_triggers(ctx.get("blood_before", 0), ctx.get("blood_after", 0)):
		award_deed(pid, &"bloodletting")

	if not is_ooa:
		return

	# SNIPER
	var target_is_elite: bool = target != null and target.unit_data != null \
		and KeywordSystem.has(target.unit_data, &"elite")
	if MechanicsResolver.sniper_deed_triggers(
			is_melee, ctx.get("is_long_range", false), ctx.get("in_cover", false), target_is_elite):
		award_deed(pid, &"sniper")

	# LORD OF WAR
	if is_melee:
		var key: String = attacker.name
		_melee_ooa_this_turn[key] = _melee_ooa_this_turn.get(key, 0) + 1
		if _melee_ooa_this_turn[key] >= 2:
			award_deed(pid, &"lord_of_war")

	# RESIST AND BITE: saldıran aktivasyona Down başlamış (stood_up_this_activation) ve bu
	# aktivasyonda bir düşmanı OOA etmiş.
	if ctx.get("attacker_began_down", false):
		award_deed(pid, &"resist_and_bite")

## Başarılı bir Charge sonunda çağrılır (unit.gd::server_request_charge).
func on_successful_charge(charger, engaged_enemy_count: int) -> void:
	if is_instance_valid(charger) and MechanicsResolver.suicidal_bravery_triggers(engaged_enemy_count):
		award_deed(charger.owner_id, &"suicidal_bravery")

## HOLD YOUR GROUND: ilk Morale Check'i geçen ordu.
func on_morale_check_passed(player_id: int) -> void:
	var was_first: bool = first_morale_pass_player == 0
	super.on_morale_check_passed(player_id)
	if was_first and first_morale_pass_player == player_id:
		award_deed(player_id, &"hold_your_ground")

## Oyun sonu: objective VP + tamamlanan Glorious Deed başına +1 VP (compendium).
func evaluate_end_of_game() -> Dictionary:
	var base := super.evaluate_end_of_game()
	var v1: int = player_vp.get(1, 0) + glorious_deeds.get(1, []).size()
	var v2: int = player_vp.get(2, 0) + glorious_deeds.get(2, []).size()
	var winner: int = 0
	if v1 > v2:
		winner = 1
	elif v2 > v1:
		winner = 2
	base["winner"] = winner
	base["vp"] = {1: v1, 2: v2}
	return base
