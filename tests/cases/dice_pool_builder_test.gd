extends RefCounted

## DicePoolBuilder — saf zar-havuzu hesaplamaları (durum tutmayan).
##   - success_probability: bilinen 2D6 dağılımı
##   - bloodbath_threshold: 6 (Down ise 3)
##   - compute_bloodbath_dice_count: 3 (DEADLY ise 4)

const DicePoolBuilder = preload("res://scripts/rules/dice_pool_builder.gd")
const UnitData = preload("res://scripts/data/unit_data.gd")

class FakeUnit extends Resource:
	var is_down: bool = false

class FakeAtk extends Resource:
	var is_deadly: bool = false

class FakeAttackerUnit extends RefCounted:
	var unit_data: UnitData = null

func run(t) -> void:
	# ── success_probability: mod=0, threshold=7 → 2D6 toplamı ≥7 = 21/36 ──
	t.approx(DicePoolBuilder.success_probability(0, 0, 7), 21.0 / 36.0, "P(2D6≥7)=21/36")
	# threshold=12 → yalnız (6,6) = 1/36
	t.approx(DicePoolBuilder.success_probability(0, 0, 12), 1.0 / 36.0, "P(2D6=12)=1/36")
	# Olasılık 0..1 aralığında ve +dice ile artar
	var p0 := DicePoolBuilder.success_probability(0, 0, 7)
	var p1 := DicePoolBuilder.success_probability(1, 0, 7)
	t.ok(p1 > p0, "+1 DICE isabet olasılığını artırır")
	var pm1 := DicePoolBuilder.success_probability(-1, 0, 7)
	t.ok(pm1 < p0, "-1 DICE isabet olasılığını düşürür")

	# ── bloodbath_threshold ──
	var up := FakeUnit.new()
	t.eq(DicePoolBuilder.bloodbath_threshold(up), 6, "Ayakta hedef → Bloodbath eşiği 6")
	up.is_down = true
	t.eq(DicePoolBuilder.bloodbath_threshold(up), 3, "Down hedef → Bloodbath eşiği 3")

	# ── PLAGUE ALMONER (Plague Knight'ın +10 terfisi, P1-1): saldıranda varsa Bloodbath maliyeti -1 ──
	var down_target := FakeUnit.new()
	down_target.is_down = true
	var standing_target := FakeUnit.new()
	var almoner := FakeAttackerUnit.new()
	almoner.unit_data = UnitData.new()
	almoner.unit_data.keywords = {&"plague_almoner": 1}
	t.eq(DicePoolBuilder.bloodbath_threshold(standing_target, almoner), 5, "Plague Almoner: ayakta hedef 6→5")
	t.eq(DicePoolBuilder.bloodbath_threshold(down_target, almoner), 2, "Plague Almoner: Down hedef 3→2")
	var non_almoner := FakeAttackerUnit.new()
	non_almoner.unit_data = UnitData.new()
	t.eq(DicePoolBuilder.bloodbath_threshold(standing_target, non_almoner), 6, "Plague Almoner yoksa eşik değişmez")
	t.eq(DicePoolBuilder.bloodbath_threshold(standing_target), 6, "attacker=null → eşik değişmez (geriye dönük uyumlu)")

	# ── compute_bloodbath_dice_count ──
	var atk := FakeAtk.new()
	t.eq(DicePoolBuilder.compute_bloodbath_dice_count(up, atk, 0), 3, "Normal Bloodbath → 3D6")
	atk.is_deadly = true
	t.eq(DicePoolBuilder.compute_bloodbath_dice_count(up, atk, 0), 4, "DEADLY Bloodbath → 4D6")

	# ── compute_injury_keep_count (P0-2): DEADLY'nin "3 zar tut" etkisi Bloodbath DIŞINDA da geçerli ──
	var normal_atk := FakeAtk.new()
	t.eq(DicePoolBuilder.compute_injury_keep_count(normal_atk, false), 2,
		"Normal silah, normal Injury Roll → 2 zar tutulur")
	t.eq(DicePoolBuilder.compute_injury_keep_count(normal_atk, true), 3,
		"Normal silah, Bloodbath Roll → 3 zar tutulur")
	var deadly_atk := FakeAtk.new()
	deadly_atk.is_deadly = true
	t.eq(DicePoolBuilder.compute_injury_keep_count(deadly_atk, false), 3,
		"DEADLY silah, NORMAL Injury Roll → 3 zar tutulur (önceden yanlışlıkla 2'ydi)")
	t.eq(DicePoolBuilder.compute_injury_keep_count(deadly_atk, true), 4,
		"DEADLY silah, Bloodbath Roll → 4 zar tutulur")
