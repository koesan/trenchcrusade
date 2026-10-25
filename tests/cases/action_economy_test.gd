extends RefCounted

## AKSİYON EKONOMİSİ — compendium `comprehensive-rules/actions.md` + `ranged-attacks.md`.
##
## RAW (actions.md, Charge): "A model cannot take a Shoot or Fight [Action] **and a Charge
## [Action] in the same Activation**, unless it uses a Weapon that has the [Assault] keyword."
## RAW (ranged-attacks.md): "A model cannot use a Shoot ACTION to make a Ranged Attack if it has
## used a Charge or Fight ACTION in the same Activation, unless... [Assault]."
##
## 2026-07-29 denetimi: kısıt yalnız TEK YÖNDE uygulanıyordu. "Shoot sonrası Fight" ve
## "Charge/Fight sonrası Shoot" engelleniyordu ama **"Shoot sonrası CHARGE" serbestti** — model
## menzilden ateş edip aynı aktivasyonda hücum edebiliyordu. (`AttackFlow._record_action`in
## yorumu zaten "Charge/Fight kilitlenir" diyordu; Charge tarafı hiç bağlanmamıştı.)

func run(t) -> void:
	# ── Shoot → Charge yasağı (YENİ) ──────────────────────────────────────
	t.ok(CombatResolver.charge_blocked_by_shot(true),
		"Assault OLMAYAN Shoot yapıldıysa Charge engellenir")
	t.ok(not CombatResolver.charge_blocked_by_shot(false),
		"Assault silahla (veya hiç) atış yapıldıysa Charge serbest")

	# ── Mevcut yönler korunuyor mu? ───────────────────────────────────────
	# Fight: yalnız Assault OLMAYAN bir Shoot yapıldıysa engellenir.
	t.ok(CombatResolver.attack_interaction_allowed(true, false, false, false, false),
		"Temiz aktivasyonda Fight serbest")
	t.ok(not CombatResolver.attack_interaction_allowed(true, false, false, false, true),
		"Assault olmayan Shoot sonrası Fight ENGELLİ")
	t.ok(CombatResolver.attack_interaction_allowed(true, false, true, false, false),
		"CHARGE sonrası Fight SERBEST (hücumun tüm amacı budur — movement.md)")

	# Shoot: Charge veya Fight yapıldıysa yalnız Assault silahla.
	t.ok(not CombatResolver.attack_interaction_allowed(false, false, true, false, false),
		"Charge sonrası Assault OLMAYAN Shoot ENGELLİ")
	t.ok(CombatResolver.attack_interaction_allowed(false, true, true, false, false),
		"Charge sonrası ASSAULT Shoot serbest")
	t.ok(not CombatResolver.attack_interaction_allowed(false, false, false, true, false),
		"Fight sonrası Assault OLMAYAN Shoot ENGELLİ")
	t.ok(CombatResolver.attack_interaction_allowed(false, true, false, true, false),
		"Fight sonrası ASSAULT Shoot serbest")

	# ── Kısıt gerçekten aksiyon kontrolüne BAĞLI mı? ─────────────────────
	# (Asıl bulgu buydu: saf predikat vardı ama Charge yolunda çağrılmıyordu.)
	var src := FileAccess.open("res://scripts/unit/unit_actions.gd", FileAccess.READ)
	t.ok(src != null, "unit_actions.gd okunabildi")
	if src != null:
		var txt := src.get_as_text()
		src.close()
		t.ok(txt.contains("CombatResolver.charge_blocked_by_shot"),
			"can_perform_action('charge') atış kısıtını uyguluyor")
		# RAW: "You cannot take a Charge Action with a model that is already within 1\" of an
		# enemy model." — angaje modelin Charge yasağı.
		t.ok(txt.contains('"move", "charge", "dash", "shoot"'),
			"Angaje model Charge/Move/Dash/Shoot yapamaz (compendium)")
