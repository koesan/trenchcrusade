extends RefCounted

## CombatResolver.validate_attack — TEK doğrulama kaynağı (P2-8).
## Sahte (fake) attacker/enemy/atk node'larıyla tüm karar yollarını kilitler. unit_data=null
## tutulur (whip_of_god yolu KeywordSystem'e gitmeden kısa devre yapar).

const CombatResolver = preload("res://scripts/rules/combat_resolver.gd")

# ── Fake'ler ────────────────────────────────────────────────────────────────
class FakeAtk:
	extends Resource
	var attack_type: String = "MELEE"
	var attack_range: float = 10.0
	var is_cumbersome: bool = false
	var is_assault: bool = false
	var attack_name: String = "test_weapon"

class FakeUnit:
	extends RefCounted
	var unit_data = null
	var owner_id: int = 1
	var current_health: int = 1
	var display_name: String = "Fake"
	var actions_taken: Array = []
	var _can_use: bool = true
	var _los_blocked: bool = false
	var _untargetable: bool = false
	func can_use_attack(_atk) -> bool: return _can_use
	func get_line_of_sight_status(_t) -> Dictionary: return {"is_blocked": _los_blocked, "in_cover": false}
	func is_untargetable_by(_a) -> bool: return _untargetable

func run(t) -> void:
	var atk := FakeAtk.new()

	# 1. Geçerli melee → "" (boş = geçerli).
	var a := FakeUnit.new()
	var e := FakeUnit.new(); e.owner_id = 2
	t.eq(CombatResolver.validate_attack(a, atk, e, 1.0), "", "Geçerli melee doğrulanır")

	# 2. Dost hedef (aynı owner, whip yok) → reddedilir.
	var friend := FakeUnit.new(); friend.owner_id = 1
	t.ok(CombatResolver.validate_attack(a, atk, friend, 1.0) != "", "Dost hedef reddedilir")

	# 3. Hedef Savaş Dışı (health<=0) → reddedilir.
	var dead := FakeUnit.new(); dead.owner_id = 2; dead.current_health = 0
	t.ok(CombatResolver.validate_attack(a, atk, dead, 1.0) != "", "Savaş Dışı hedef reddedilir")

	# 4. Menzil dışı → reddedilir (range=10, tolerans ~1.2, dist=20).
	t.ok(CombatResolver.validate_attack(a, atk, e, 20.0) != "", "Menzil dışı reddedilir")

	# 5. can_use_attack false (angaje/tekrar/etkileşim) → reddedilir.
	var a2 := FakeUnit.new(); a2._can_use = false
	t.ok(CombatResolver.validate_attack(a2, atk, e, 1.0) != "", "Kullanılamaz saldırı reddedilir")

	# 6. Cumbersome + dash: compendium'da böyle bir yasak YOK (keyword.md: Cumbersome yalnız iki el
	#    gerektirir) — eski uydurma kural kaldırıldı, saldırı geçerli.
	var cumb := FakeAtk.new(); cumb.is_cumbersome = true
	var a3 := FakeUnit.new(); a3.actions_taken = ["dash"]
	t.eq(CombatResolver.validate_attack(a3, cumb, e, 1.0), "", "CUMBERSOME silah Dash sonrası da kullanılabilir")

	# 7. Menzilli + LoS kapalı → reddedilir.
	var ranged := FakeAtk.new(); ranged.attack_type = "RANGED"
	var a4 := FakeUnit.new(); a4._los_blocked = true
	t.ok(CombatResolver.validate_attack(a4, ranged, e, 1.0) != "", "Menzilli + LoS kapalı reddedilir")

	# 8. Menzilli + hedef Hide (untargetable) → reddedilir.
	var hidden := FakeUnit.new(); hidden.owner_id = 2; hidden._untargetable = true
	t.ok(CombatResolver.validate_attack(a, ranged, hidden, 1.0) != "", "Menzilli + Hide hedef reddedilir")

	# 9. Menzilli + LoS açık + görünür → geçerli.
	t.eq(CombatResolver.validate_attack(a, ranged, e, 1.0), "", "Geçerli menzilli doğrulanır")
