## "Fields of Glory" senaryo mantığı (compendium: scenarios/fields-of-glory).
##
## 4 tur. Objective YOK — VP tamamen Glorious Deeds'ten gelir. 4/8 Deed bağlandı (aşağıda gerekçeli):
## Death From Above, Elite Hunter, Personal Revenge, Reaper. No Escape (aktivasyon-başı LoS geçmişi),
## Risk It All (tüm Risky-roll çağrı noktalarını kapsayan çapraz-kesim takip), The Real Killer ve
## Trench Raider (Dangerous/Difficult terrain VE Trench section — oyunda hiçbiri sorgulanabilir
## durumda değil, bkz. plan.md §5) KASITLI BAĞLANMADI — sahte/yanlış bir tetikleyici uydurulmadı.
class_name FieldsOfGloryLogic
extends ScenarioLogic

var _kill_count: Dictionary = {}        ## unit_name -> toplam OOA sayısı (Reaper, oyun boyu)
var _elite_kill_count: Dictionary = {}  ## unit_name -> Elite OOA sayısı (Elite Hunter, oyun boyu)
var _has_killed_anyone: Dictionary = {} ## unit_name -> bool (Personal Revenge koşulu için)

func setup(p_data: ScenarioData) -> void:
	super.setup(p_data)
	_kill_count = {}
	_elite_kill_count = {}
	_has_killed_anyone = {}

## KAYIT/YÜKLEME: bkz. scenario_logic.gd::save_state.
func save_state() -> Dictionary:
	var d := super.save_state()
	d["kill_count"] = _kill_count.duplicate(true)
	d["elite_kill_count"] = _elite_kill_count.duplicate(true)
	d["has_killed_anyone"] = _has_killed_anyone.duplicate(true)
	return d

func load_state(d: Dictionary) -> void:
	super.load_state(d)
	_kill_count = d.get("kill_count", {}).duplicate(true)
	_elite_kill_count = d.get("elite_kill_count", {}).duplicate(true)
	_has_killed_anyone = d.get("has_killed_anyone", {}).duplicate(true)

func on_unit_out_of_action(attacker, target, is_melee: bool, ctx: Dictionary = {}) -> void:
	super.on_unit_out_of_action(attacker, target, is_melee, ctx)  # P1-1: Gather Knowledge (taban sınıf)
	if not ctx.get("is_ooa", false) or attacker == null or not is_instance_valid(attacker):
		return
	var pid: int = attacker.owner_id
	var akey: String = attacker.name

	# DEATH FROM AVOVE
	if is_melee and ctx.get("is_diving_charge", false):
		award_deed(pid, &"death_from_above")

	# PERSONAL REVENGE: iki-oyunculu oyunda target'ın "daha önce birini öldürmüş olması" = daha
	# önce attacker'ın takımından birini OOA etmiş olması (tek olası düşman takımı).
	if ctx.get("is_bloodbath", false) and target != null and _has_killed_anyone.get(target.name, false):
		award_deed(pid, &"personal_revenge")

	# REAPER (3 OOA, oyun boyu)
	_kill_count[akey] = _kill_count.get(akey, 0) + 1
	if _kill_count[akey] >= 3:
		award_deed(pid, &"reaper")

	# ELITE HUNTER (2 [Elite] OOA, oyun boyu)
	var target_is_elite: bool = target != null and target.unit_data != null \
		and KeywordSystem.has(target.unit_data, &"elite")
	if target_is_elite:
		_elite_kill_count[akey] = _elite_kill_count.get(akey, 0) + 1
		if _elite_kill_count[akey] >= 2:
			award_deed(pid, &"elite_hunter")

	_has_killed_anyone[akey] = true

## Oyun sonu: 1 VP/deed + Elite Hunter/Personal Revenge için +1 ekstra (compendium; Risk It All/
## Trench Raider bağlı olmadığı için hiç ortaya çıkmaz, ekstra mantığa dahil ama etkisiz).
func evaluate_end_of_game() -> Dictionary:
	var base := super.evaluate_end_of_game()
	var v1: int = player_vp.get(1, 0) + _deed_vp(1)
	var v2: int = player_vp.get(2, 0) + _deed_vp(2)
	var winner: int = 0
	if v1 > v2:
		winner = 1
	elif v2 > v1:
		winner = 2
	base["winner"] = winner
	base["vp"] = {1: v1, 2: v2}
	return base

const _BONUS_DEEDS := [&"elite_hunter", &"personal_revenge", &"risk_it_all"]

func _deed_vp(pid: int) -> int:
	var total := 0
	for d in glorious_deeds.get(pid, []):
		total += 1
		if _BONUS_DEEDS.has(d):
			total += 1
		elif d == &"trench_raider":
			total += 2
	return total
