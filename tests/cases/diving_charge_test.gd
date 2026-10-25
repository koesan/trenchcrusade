extends RefCounted

## MechanicsResolver.is_diving_charge_height — Diving Charge yükseklik koşulu.
## Eşik GameState.DIVING_CHARGE_MIN_HEIGHT: compendium (melee-attacks.md) "Jumps Down AT LEAST 3\"".
## Birim hedefin en az bu kadar ÜSTÜNDEN
## atlayıp inince Diving Charge geçerli olur. Tespit CHARGE ANINDA (birim henüz yüksekteyken).

const MechanicsResolver = preload("res://scripts/rules/mechanics_resolver.gd")

func run(t) -> void:
	var th: float = GameState.DIVING_CHARGE_MIN_HEIGHT

	# Eşik + 1 yükseklikten atlama → diving charge.
	t.ok(MechanicsResolver.is_diving_charge_height(0.0, -(th + 1.0)), "Eşik üstü düşüş → diving charge")

	# Düz zemin → koşul sağlanmaz.
	t.ok(not MechanicsResolver.is_diving_charge_height(-1.5, -1.5), "Düz zemin → diving charge yok")

	# Tam eşik → sağlanır (>=).
	t.ok(MechanicsResolver.is_diving_charge_height(th, 0.0), "Tam eşik → diving charge (sınır dahil)")

	# Eşik altı (siper duvarı derinliği, güvenli) → sağlanmaz.
	t.ok(not MechanicsResolver.is_diving_charge_height(th - 1.0, 0.0), "Eşik altı düşüş → diving charge yok")

	# Aşağıdan yukarı hücum → asla diving charge.
	t.ok(not MechanicsResolver.is_diving_charge_height(-1.5, 2.0), "Yukarı doğru hücum → diving charge yok")
