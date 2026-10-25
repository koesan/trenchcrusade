## "Relic Hunt" senaryo mantığı (compendium: scenarios/relic-hunt).
##
## 4 tur, No Man's Land arazi arketipi, Infiltrator YASAK (compendium: "must deploy normally").
## "To The Death!" — Morale Check YOK (special_rules["skip_morale"], Great War'ın kurduğu altyapı).
##
## BİLİNÇLİ SADELEŞTİRME (dokümante, kullanıcıya iletildi): compendium'un "6 model + tur başına
## D3 reinforcement dalgası" staggered-deployment mekaniği bu projede UYGULANMADI — bu proje her
## senaryoda tek-seferlik standart deployment fazı kullanıyor (game.gd/GameState mimarisi bu dalga
## sistemini desteklemiyor, ayrı bir alt-sistem gerektirir). Senaryonun ASIL kimliği olan Reliquary
## yarışı/claim mekaniği TAM uygulanıyor. "40mm+ taban 2 model sayılır" kuralı da aynı nedenle
## (UnitData'da taban boyutu alanı yok — Six-Armed/Unstoppable/Devour'ın da bloke olduğu bilinen
## eksik, bkz. plan.md) uygulanmadı.
##
## RELIQUARY YAŞAM DÖNGÜSÜ (compendium "Reliquary Markers" + "Victory Conditions"):
##   - 4 Reliquary sahaya yerleştirilir. Her TUR, sahada duran (kaldırılmamış) ve bu tur henüz
##     kimse tarafından claim edilmemiş bir Reliquary'nin 1" içindeki bir model "Claim Reliquary"
##     eylemi alabilir → Success Roll → başarılıysa o Reliquary bu TUR için o oyuncuya claim edilir
##     (aynı tur içinde tekrar claim edilemez; sonraki turda serbest kalır — sahadaysa).
##   - Tur 1 sonunda: VP hesaplanır, SONRA ilk 2 Reliquary sahadan kaldırılır — o anki sahipleri
##     KALICI olur (bir daha claim edilemez ama VP saymaya devam eder, kaybedilmez).
##   - Tur 2 sonunda: aynı şekilde kalan 2 Reliquary kaldırılır + kalıcı sahiplik kilitlenir.
##   - Tur 1-3: sahip başına Reliquary başına 1 VP. Tur 4: sahip başına Reliquary başına 2 VP.
##   - Oyun sonu: tamamlanan Glorious Deed başına +1 VP (taban sınıfın ClaimNoMansLand deseni).
class_name RelicHuntLogic
extends ScenarioLogic

## Reliquary durumu, objective_id (StringName) anahtarlı.
var _removed: Dictionary = {}          # id -> bool (fiziksel olarak sahadan kaldırıldı mı)
var _claimed_this_turn: Dictionary = {}  # id -> player_id (0 = bu tur henüz claim edilmedi)
var _permanent_owner: Dictionary = {}   # id -> player_id (kaldırıldıktan sonra KİLİTLİ sahiplik)

## Glorious Deeds sayaçları — OYUN BOYUNCA (tur/aktivasyon sıfırlaması YOK).
var _ooa_count_per_model: Dictionary = {}         # attacker.name -> int (Blood Sacrifice)
var _claimed_ids_per_player: Dictionary = {1: [], 2: []}  # Relic Hunter (farklı id sayısı)

func setup(p_data: ScenarioData) -> void:
	super.setup(p_data)
	_removed = {}
	_claimed_this_turn = {}
	_permanent_owner = {}
	_ooa_count_per_model = {}
	_claimed_ids_per_player = {1: [], 2: []}
	if data == null:
		return
	for obj_res in data.objectives:
		var obj := obj_res as ScenarioObjective
		if obj != null:
			_removed[obj.objective_id] = false
			_claimed_this_turn[obj.objective_id] = 0
			_permanent_owner[obj.objective_id] = 0

## KAYIT/YÜKLEME: bkz. scenario_logic.gd::save_state.
func save_state() -> Dictionary:
	var d := super.save_state()
	var removed_out := {}
	for k in _removed:
		removed_out[String(k)] = _removed[k]
	var claimed_turn_out := {}
	for k in _claimed_this_turn:
		claimed_turn_out[String(k)] = _claimed_this_turn[k]
	var perm_out := {}
	for k in _permanent_owner:
		perm_out[String(k)] = _permanent_owner[k]
	var claimed_ids_out := {}
	for pid in _claimed_ids_per_player:
		var arr: Array = []
		for cid in _claimed_ids_per_player[pid]:
			arr.append(String(cid))
		claimed_ids_out[str(pid)] = arr
	d["removed"] = removed_out
	d["claimed_this_turn"] = claimed_turn_out
	d["permanent_owner"] = perm_out
	d["ooa_count_per_model"] = _ooa_count_per_model.duplicate(true)
	d["claimed_ids_per_player"] = claimed_ids_out
	return d

func load_state(d: Dictionary) -> void:
	super.load_state(d)
	_removed = {}
	for k in d.get("removed", {}):
		_removed[StringName(k)] = d["removed"][k]
	_claimed_this_turn = {}
	for k in d.get("claimed_this_turn", {}):
		_claimed_this_turn[StringName(k)] = int(d["claimed_this_turn"][k])
	_permanent_owner = {}
	for k in d.get("permanent_owner", {}):
		_permanent_owner[StringName(k)] = int(d["permanent_owner"][k])
	_ooa_count_per_model = d.get("ooa_count_per_model", {}).duplicate(true)
	_claimed_ids_per_player = {1: [], 2: []}
	var claimed_ids_in = d.get("claimed_ids_per_player", {})
	for pid_str in claimed_ids_in:
		var arr: Array = []
		for cid in claimed_ids_in[pid_str]:
			arr.append(StringName(cid))
		_claimed_ids_per_player[int(pid_str)] = arr

# ── RELIQUARY SORGULARI (unit.gd/unit_actions.gd/game.gd tarafından kullanılır) ─────────────

## Bu Reliquary fiziksel olarak sahadan kaldırıldı mı (artık claim edilemez, görsel gizlenir)?
func is_reliquary_removed(objective_id: StringName) -> bool:
	return _removed.get(objective_id, false)

## Verilen konuma 1" içinde, sahada duran ve bu tur HENÜZ claim edilmemiş bir Reliquary var mı?
## Varsa objective_id döner (yoksa &"").
func find_claimable_reliquary(pos: Vector3) -> StringName:
	if data == null:
		return &""
	var pos_xz := Vector2(pos.x, pos.z)
	for obj_res in data.objectives:
		var obj := obj_res as ScenarioObjective
		if obj == null or _removed.get(obj.objective_id, false):
			continue
		if _claimed_this_turn.get(obj.objective_id, 0) != 0:
			continue
		if pos_xz.distance_to(Vector2(obj.position.x, obj.position.z)) <= obj.control_radius:
			return obj.objective_id
	return &""

## Verilen konum, sahada duran (kaldırılmamış) HERHANGİ bir Reliquary'nin 1" içinde mi?
## (Protect the Relic Glorious Deed'i için — claim edilmiş olması ŞART DEĞİL.)
func is_position_near_active_reliquary(pos: Vector3) -> bool:
	if data == null:
		return false
	var pos_xz := Vector2(pos.x, pos.z)
	for obj_res in data.objectives:
		var obj := obj_res as ScenarioObjective
		if obj == null or _removed.get(obj.objective_id, false):
			continue
		if pos_xz.distance_to(Vector2(obj.position.x, obj.position.z)) <= obj.control_radius:
			return true
	return false

## Claim Reliquary Action'ın Success Roll'u BAŞARILI olduğunda unit.gd tarafından çağrılır.
func claim_reliquary(objective_id: StringName, player_id: int, claimer_name: String = "") -> void:
	if not _removed.has(objective_id) or _removed[objective_id] \
			or _claimed_this_turn.get(objective_id, 0) != 0:
		return
	_claimed_this_turn[objective_id] = player_id
	var claimed_list: Array = _claimed_ids_per_player.get(player_id, [])
	if not claimed_list.has(objective_id):
		claimed_list.append(objective_id)
		_claimed_ids_per_player[player_id] = claimed_list
		if MechanicsResolver.relic_hunter_triggers(claimed_list.size()):
			award_deed(player_id, &"relic_hunter")
	GameLogger.log_info("[Relic Hunt] Oyuncu %d '%s' Reliquary'sini talep etti (%s)." \
		% [player_id, objective_id, claimer_name], "SCENARIO")

## Bu turun VP hesabında / kalıcı-kilit anında kullanılacak "etkin sahip": bu tur claim edilmişse
## o, sahadan kaldırılmışsa kalıcı sahip, ikisi de yoksa 0 (kimsenin değil).
func _effective_owner(objective_id: StringName) -> int:
	var this_turn: int = _claimed_this_turn.get(objective_id, 0)
	if this_turn != 0:
		return this_turn
	return _permanent_owner.get(objective_id, 0)

## Objectives panelinin/marker renklendirmesinin kullandığı GENEL API — taban sınıfın proximity-
## sayım mantığının YERİNE geçer (Relic Hunt'ta kontrol proximity DEĞİL, claim/kilit durumudur).
func get_persistent_objective_controller(obj: ScenarioObjective) -> int:
	return _effective_owner(obj.objective_id)

# ── TUR SONU: VP + kaldırma programı ─────────────────────────────────────────────────────────

func on_turn_end(round_number: int) -> void:
	if data == null:
		return
	# 1) VP: tur 1-3 → sahip başına Reliquary başına 1 VP, tur 4 → 2 VP (compendium).
	var vp_per_reliquary: int = 2 if round_number >= 4 else 1
	for obj_res in data.objectives:
		var obj := obj_res as ScenarioObjective
		if obj == null:
			continue
		var owner: int = _effective_owner(obj.objective_id)
		if owner != 0:
			player_vp[owner] = player_vp.get(owner, 0) + vp_per_reliquary

	# 2) Kaldırma programı (compendium: "At the end of Turn 1, remove Reliquaries 1 and 2, and at
	# the end of turn 2, remove Reliquaries 3 and 4") — objectives dizisindeki SIRA 1-2-3-4 kabul
	# edilir (relic_hunt.tres'te bu sıraya göre tanımlanmalı). Kaldırılan Reliquary'nin O ANKİ
	# (henüz sıfırlanmamış) sahibi KALICI olarak kilitlenir.
	if round_number == 1 or round_number == 2:
		var ids: Array = []
		for obj_res in data.objectives:
			var obj := obj_res as ScenarioObjective
			if obj != null:
				ids.append(obj.objective_id)
		var to_remove: Array = ids.slice(0, 2) if round_number == 1 else ids.slice(2, 4)
		for rid in to_remove:
			if not _removed.get(rid, false):
				_permanent_owner[rid] = _effective_owner(rid)
				_removed[rid] = true

	# 3) Bu turun claim durumu sıfırlanır (sahada kalan Reliquary'ler bir sonraki tur yeniden
	# claim edilebilir — compendium: "it can then be claimed again by either side in subsequent Turns").
	for id in _claimed_this_turn.keys():
		_claimed_this_turn[id] = 0

# ── GLORIOUS DEEDS ────────────────────────────────────────────────────────────────────────────

func on_unit_out_of_action(attacker, target, is_melee: bool, ctx: Dictionary = {}) -> void:
	super.on_unit_out_of_action(attacker, target, is_melee, ctx)  # Gather Knowledge (taban sınıf)
	if attacker == null or not is_instance_valid(attacker):
		return
	var pid: int = attacker.owner_id
	if not ctx.get("is_ooa", false):
		return

	# SNIPER
	var target_is_elite: bool = target != null and is_instance_valid(target) and target.unit_data != null \
		and KeywordSystem.has(target.unit_data, &"elite")
	if MechanicsResolver.sniper_deed_triggers(
			is_melee, ctx.get("is_long_range", false), ctx.get("in_cover", false), target_is_elite):
		award_deed(pid, &"sniper")

	# RESIST AND BITE
	if ctx.get("attacker_began_down", false):
		award_deed(pid, &"resist_and_bite")

	# BLOOD SACRIFICE: aynı modelin oyun boyunca OOA ettiği düşman sayısı.
	var akey: String = attacker.name
	_ooa_count_per_model[akey] = _ooa_count_per_model.get(akey, 0) + 1
	if MechanicsResolver.blood_sacrifice_triggers(_ooa_count_per_model[akey]):
		award_deed(pid, &"blood_sacrifice")

	# PROTECT THE RELIC: hedef OOA olduğu anda aktif (kaldırılmamış) bir Reliquary'nin 1" içindeydi mi?
	if target != null and is_instance_valid(target) \
			and MechanicsResolver.protect_the_relic_triggers(
				is_position_near_active_reliquary(target.global_position)):
		award_deed(pid, &"protect_the_relic")
	# Not: "Cast Them Down" (düşmanı 3"+ düşürme) BİLİNÇLİ BAĞLANMADI — Claim No Man's Land ile
	# aynı gerekçe: oyunda hiçbir mekanik düşmanı zorla düşürmüyor (push/knockback yok).

# ── OYUN SONU ─────────────────────────────────────────────────────────────────────────────────

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
