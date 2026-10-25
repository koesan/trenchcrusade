extends RefCounted

## P1-1 (Combat Biologist — Vivisector'ın Pain Amplifier'ı): "Lower the roll needed to achieve
## a Critical Success... by 1 for each Blood Marker next to the target." Inflict Pain (D3" itme)
## NavigationServer3D'ye bağlı, headless test edilemez — yalnız SAF eşik formülü testli.

const DicePoolBuilder = preload("res://scripts/rules/dice_pool_builder.gd")
const AttackData = preload("res://scripts/data/attack_data.gd")

func _atk(kw: Dictionary) -> AttackData:
	var a := AttackData.new()
	a.keywords = kw
	return a

func run(t) -> void:
	var pain_atk := _atk({&"pain_amplifier": 1})
	var normal_atk := _atk({})

	t.eq(DicePoolBuilder.compute_crit_threshold(normal_atk, 3), 12, "Pain Amplifier yoksa eşik hep 12")
	t.eq(DicePoolBuilder.compute_crit_threshold(pain_atk, 0), 12, "0 Kan İşareti → eşik değişmez (12)")
	t.eq(DicePoolBuilder.compute_crit_threshold(pain_atk, 1), 11, "1 Kan İşareti → 11+ Kritik")
	t.eq(DicePoolBuilder.compute_crit_threshold(pain_atk, 3), 9, "3 Kan İşareti → 9+ Kritik")
	t.eq(DicePoolBuilder.compute_crit_threshold(pain_atk, 6), 7, "6 Kan İşareti → taban 7'de durur (Success eşiğinin altına inmez)")
	t.eq(DicePoolBuilder.compute_crit_threshold(null, 5), 12, "null silah → güvenli varsayılan 12")
