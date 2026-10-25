extends RefCounted

## Kullanıcı isteğiyle eklenen 3 genel keyword mekaniği: AUTOMATIC(X), SHOTGUN, ve SCATTER'ın
## Artillery Witch'e özgü Infernal Strike/Mighty Explosion eklerinden ayrıştırılmış genel hali.

const KeywordSystem = preload("res://scripts/rules/keyword_system.gd")
const DicePoolBuilder = preload("res://scripts/rules/dice_pool_builder.gd")
const AttackData = preload("res://scripts/data/attack_data.gd")
const UnitData = preload("res://scripts/data/unit_data.gd")

class FakeUnit:
	extends RefCounted
	var is_down: bool = false
	var armour: int = 0
	var blood_markers: int = 0
	var blessing_markers: int = 0
	var infection_markers: int = 0
	var unit_data: UnitData = null
	var global_position: Vector3 = Vector3.ZERO
	var temp_ranged_injury_bonus: int = 0
	var melee_dice_modifier: int = 0
	var ranged_dice_modifier: int = 0

func _atk(kw: Dictionary = {}) -> AttackData:
	var a := AttackData.new()
	a.attack_type = "RANGED"
	a.keywords = kw
	return a

func run(t) -> void:
	# ── AUTOMATIC(X): silahtan X değeri okunabilir mi ──────────────────────────
	var machine_gun := _atk({&"automatic": 3, &"heavy": 1, &"reload": 1})
	t.eq(KeywordSystem.value(machine_gun, &"automatic", 1), 3,
		"Machine Gun → AUTOMATIC(3) değeri okunuyor (Shoot Action'da 3 ardışık Ranged Attack)")
	var no_auto := _atk({})
	t.eq(KeywordSystem.value(no_auto, &"automatic", 1), 1,
		"AUTOMATIC keyword'ü yoksa varsayılan 1 (tek atış, davranış değişmez)")

	# ── SHOTGUN: uzun menzilde Success cezası YOK, Injury'de -1 Dice VAR ────────
	var shotgun := _atk({&"shotgun": 1})
	var attacker := FakeUnit.new()
	var target := FakeUnit.new()

	var ctx_long: Dictionary = DicePoolBuilder.build_injury_context(attacker, shotgun, target, false, false, false, true)
	var ctx_short: Dictionary = DicePoolBuilder.build_injury_context(attacker, shotgun, target, false, false, false, false)
	t.ok(ctx_long["is_long_range"], "build_injury_context → is_long_range doğru taşınıyor")
	var mod_long: int = DicePoolBuilder.compute_injury_modifier(ctx_long)
	var mod_short: int = DicePoolBuilder.compute_injury_modifier(ctx_short)
	t.eq(mod_long, mod_short - 1,
		"Shotgun → uzun menzilde -1 Injury Dice (normal -1 Dice cezasının YERİNE, keyword.md)")

	# Success Roll tarafında shotgun silahları uzun menzil cezası ALMAZ (injury'ye taşındı).
	var success_ctx: Dictionary = {
		"attacker": attacker, "attack_data": shotgun, "is_melee": false,
		"attacker_is_down": false, "is_long_range": true, "in_cover": false,
		"attacker_blessed": 0, "enemy": target, "is_from_charge": false,
	}
	var success_mod: int = DicePoolBuilder.compute_success_modifier(success_ctx)
	t.eq(success_mod, 0, "Shotgun → Success Roll'da uzun menzil cezası YOK (Injury tarafına taşındı)")

	# Shotgun olmayan bir silah kısa/uzun menzilde aynı injury modifier'a sahip olmalı.
	var normal_rifle := _atk({})
	var ctx_rifle_long: Dictionary = DicePoolBuilder.build_injury_context(attacker, normal_rifle, target, false, false, false, true)
	var ctx_rifle_short: Dictionary = DicePoolBuilder.build_injury_context(attacker, normal_rifle, target, false, false, false, false)
	t.eq(DicePoolBuilder.compute_injury_modifier(ctx_rifle_long), DicePoolBuilder.compute_injury_modifier(ctx_rifle_short),
		"Shotgun OLMAYAN silah → uzun menzil Injury Dice'ı etkilemez (regresyon yok)")

	# ── SCATTER genel hali: Infernal Strike/Mighty Explosion artık AYRI keyword'ler ────────────
	var infernal_bomb = load("res://assets/data/attacks/infernal_bomb.tres")
	t.ok(KeywordSystem.has(infernal_bomb, &"scatter"), "Infernal Bomb → scatter keyword'ü var (değişmedi)")
	t.ok(KeywordSystem.has(infernal_bomb, &"infernal_strike"),
		"Infernal Bomb → infernal_strike keyword'ü artık AÇIK (Deadly-on-primary artık genel scatter'dan AYRI)")
	t.ok(KeywordSystem.has(infernal_bomb, &"mighty_explosion"),
		"Infernal Bomb → mighty_explosion keyword'ü artık AÇIK (D3 knockback artık genel scatter'dan AYRI)")

	# Hipotetik "sade" bir Scatter+Blast silahı (Infernal Strike/Mighty Explosion YOK) bu iki
	# keyword'ü TAŞIMAMALI — execute_infernal_bomb_blast artık bunlara bakıp bonusları atlar.
	var plain_scatter := _atk({&"scatter": 1})
	t.ok(not KeywordSystem.has(plain_scatter, &"infernal_strike"),
		"Sade bir Scatter+Blast silahı → infernal_strike YOK (Artillery Witch'e özgü bonus almaz)")
	t.ok(not KeywordSystem.has(plain_scatter, &"mighty_explosion"),
		"Sade bir Scatter+Blast silahı → mighty_explosion YOK (Artillery Witch'e özgü bonus almaz)")
