## "The High Ground" senaryo mantığı (compendium: scenarios/the-high-ground).
##
## 5 tur. 5 objective (taban sınıf on_turn_end zaten 2 VP/tur/kontrol işler — Claim No Man's Land
## ile birebir aynı mekanik). Ek olarak: Diving Charge OOA başına +1 VP (anlık, tur sonu değil),
## King of the Hill Glorious Deed (bir modelin oyun boyunca 5 objective'in HEPSİNİ ziyaret etmesi —
## tur-sonu anlık kontrolüyle yaklaşık ölçülür, bkz. plan.md notu), Death From Above Glorious Deed.
##
## Top Priority Objective (gizli seçim, +3/+3 VP) VE Down With You / Back To The Mud Glorious Deeds
## KASITLI BAĞLANMADI: Top Priority yeni bir gizli-seçim ağ akışı gerektiriyor (ayrı özellik);
## Down With You "taller Objective" karşılaştırması gerektiriyor ama mevcut 5 objective'in hepsi
## aynı yükseklikte (position.y=0) — anlamsız/her zaman yanlış bir karşılaştırma olurdu; Back To
## The Mud düşmanı zorla düşürecek bir push/knockback mekaniği gerektiriyor (yok, Cast Them Down
## ile aynı gerekçe). Victory or Death yalnız kampanya modunda anlamlı, tek-maçlık oyunda kapsam dışı.
class_name TheHighGroundLogic
extends ScenarioLogic

var _visited_objectives: Dictionary = {}  ## unit_name -> Array[StringName] ziyaret edilen objective'ler

func setup(p_data: ScenarioData) -> void:
	super.setup(p_data)
	_visited_objectives = {}

## KAYIT/YÜKLEME: bkz. scenario_logic.gd::save_state.
func save_state() -> Dictionary:
	var d := super.save_state()
	var out := {}
	for unit_name in _visited_objectives:
		var arr: Array = []
		for oid in _visited_objectives[unit_name]:
			arr.append(String(oid))
		out[unit_name] = arr
	d["visited_objectives"] = out
	return d

func load_state(d: Dictionary) -> void:
	super.load_state(d)
	_visited_objectives = {}
	var vis_in = d.get("visited_objectives", {})
	for unit_name in vis_in:
		var arr: Array = []
		for oid in vis_in[unit_name]:
			arr.append(StringName(oid))
		_visited_objectives[unit_name] = arr

func on_turn_end(round_number: int) -> void:
	super.on_turn_end(round_number)
	_track_king_of_the_hill()

## Tur sonunda hangi birimler hangi objective'lerin üzerinde/1" içinde — ziyaret geçmişine ekler.
## Basitleştirme: yalnız tur SONUNDAKİ konum kontrol edilir (sürekli izleme değil).
func _track_king_of_the_hill() -> void:
	if data == null or data.objectives.is_empty():
		return
	for obj_res in data.objectives:
		var obj := obj_res as ScenarioObjective
		if obj == null:
			continue
		for u in UnitQuery.within(UnitQuery.alive(), obj.position, obj.control_radius):
			var u_name := String(u.name)
			var visited: Array = _visited_objectives.get(u_name, [])
			if not visited.has(obj.objective_id):
				visited.append(obj.objective_id)
				_visited_objectives[u_name] = visited
			if visited.size() >= data.objectives.size():
				award_deed(u.owner_id, &"king_of_the_hill")

func on_unit_out_of_action(attacker, target, is_melee: bool, ctx: Dictionary = {}) -> void:
	super.on_unit_out_of_action(attacker, target, is_melee, ctx)  # P1-1: Gather Knowledge (taban sınıf)
	if not ctx.get("is_ooa", false) or attacker == null or not is_instance_valid(attacker):
		return
	if is_melee and ctx.get("is_diving_charge", false):
		# "Each player scores 1 VP each time..." — anlık, tekrar edebilir (Deed değil, düz VP).
		player_vp[attacker.owner_id] = player_vp.get(attacker.owner_id, 0) + 1
		award_deed(attacker.owner_id, &"death_from_above")
		GameLogger.log_info("[The High Ground] Oyuncu %d: Diving Charge OOA → +1 VP." % attacker.owner_id, "SCENARIO")

## Oyun sonu: objective VP (zaten player_vp'de, on_turn_end'den) + Diving Charge VP (zaten player_vp'de)
## + Glorious Deed başına +1 VP (Death From Above + King of the Hill).
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
