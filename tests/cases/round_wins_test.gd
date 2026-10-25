extends RefCounted

## UI/UX yeniden tasarımı — kullanıcı isteği: "Top Bar'ın en sağ ve en sol altında... her
## faction'ın kazandığı round sayısını göstersin." Compendium'da ayrık bir "round kazananı" kuralı
## yok (yalnız oyun sonunda toplam VP'ye göre tek kazanan belirlenir) — bu yüzden UI'ye özgü bir
## türetilmiş sayaç eklendi: bir round'da hangi oyuncu DİĞERİNDEN DAHA FAZLA VP kazandıysa
## (objective kontrolü) o oyuncunun ScenarioLogic.player_round_wins sayacı +1 artar.

const ScenarioLogic = preload("res://scripts/rules/scenario_logic.gd")
const ScenarioData = preload("res://scripts/data/scenario_data.gd")
const ScenarioObjective = preload("res://scripts/data/scenario_objective.gd")

class FakeUnit:
	extends RefCounted
	var owner_id: int = 1
	var name: String = "u1"
	var current_health: int = 10
	var is_down: bool = false
	var unit_data = null
	var global_position: Vector3 = Vector3.ZERO

func _obj(id: StringName, pos: Vector3, vp: int = 2) -> ScenarioObjective:
	var o := ScenarioObjective.new()
	o.objective_id = id
	o.position = pos
	o.control_radius = 1.0
	o.vp_per_turn = vp
	return o

func _vp_data(objectives: Array[Resource]) -> ScenarioData:
	var d := ScenarioData.new()
	d.victory_type = ScenarioData.VictoryType.OBJECTIVE_VP
	d.objectives = objectives
	return d

func run(t) -> void:
	var original_units: Dictionary = GameState.units.duplicate()

	# ── Oyuncu 1, objective'i kontrol ediyor → Oyuncu 1'in round sayacı +1 ────────────────
	var logic := ScenarioLogic.new()
	logic.setup(_vp_data([_obj(&"o1", Vector3.ZERO)]))
	var u1 := FakeUnit.new()
	u1.owner_id = 1
	u1.global_position = Vector3.ZERO
	GameState.units = {"u1": u1}

	logic.on_turn_end(1)
	t.eq(logic.player_vp[1], 2, "Oyuncu 1 objective'i kontrol etti → +2 VP")
	t.eq(logic.player_round_wins[1], 1, "Oyuncu 1'in round kazanma sayacı +1")
	t.eq(logic.player_round_wins[2], 0, "Oyuncu 2'nin sayacı değişmedi")

	# ── Round 2: Oyuncu 2 devralıyor → Oyuncu 2'nin sayacı +1 ─────────────────────────────
	var u2 := FakeUnit.new()
	u2.owner_id = 2
	u2.global_position = Vector3.ZERO
	GameState.units = {"u2": u2}

	logic.on_turn_end(2)
	t.eq(logic.player_vp[2], 2, "Oyuncu 2 objective'i devraldı → +2 VP")
	t.eq(logic.player_round_wins[1], 1, "Oyuncu 1'in sayacı bu round'da ARTMADI")
	t.eq(logic.player_round_wins[2], 1, "Oyuncu 2'nin sayacı +1 oldu")

	# ── Eşitlik (hiç objective yok → hiç VP kazanılmaz) → HİÇBİRİNİN sayacı artmaz ────────
	var tie_logic := ScenarioLogic.new()
	tie_logic.setup(_vp_data([]))
	GameState.units = {}
	tie_logic.on_turn_end(1)
	t.eq(tie_logic.player_round_wins[1], 0, "Eşitlikte (0-0 VP kazanımı) Oyuncu 1'in sayacı artmaz")
	t.eq(tie_logic.player_round_wins[2], 0, "Eşitlikte Oyuncu 2'nin sayacı da artmaz")

	# ── setup() sıfırlama ──────────────────────────────────────────────────────────────
	logic.setup(null)
	t.eq(logic.player_round_wins, {1: 0, 2: 0}, "setup() → player_round_wins sıfırlanır")

	GameState.units = original_units
