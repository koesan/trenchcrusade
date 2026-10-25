extends RefCounted

## SALDIRI AKIŞI — faz sözleşmesi + çoklu-saldırı zinciri seçimi.
##
## `unit.gd::server_request_attack_action` 231 satırlık, erken-dönüşlerle dolu tek bir prosedürdü;
## içindeki hiçbir karar izole sınanamıyordu. Zincir seçimi (Swinging Blow / Cleave(X) /
## Automatic(X)) artık SAF bir fonksiyon — burada doğrudan test ediliyor.

const FLOW := "res://scripts/unit/attack_flow.gd"

func _atk(attack_type: String, kws: Array[StringName] = [],
		cleave: int = 0) -> AttackData:
	var a := AttackData.new()
	a.attack_type = attack_type
	for kw in kws:
		a.keywords[kw] = true
	if cleave > 0:
		a.has_cleave = true
		a.cleave_count = cleave
	return a

func run(t) -> void:
	# ── ZİNCİR SEÇİMİ (UnitAttackChains.select_chain) ─────────────────────
	var melee := _atk("MELEE")
	var ranged := _atk("RANGED")

	t.eq(UnitAttackChains.select_chain(melee, true), &"",
		"Düz melee silahı → zincir yok (tek hedef akışı)")
	t.eq(UnitAttackChains.select_chain(ranged, false), &"",
		"Düz menzilli silah → zincir yok")
	t.eq(UnitAttackChains.select_chain(null, true), &"",
		"null silah → zincir yok (çökmez)")

	t.eq(UnitAttackChains.select_chain(_atk("MELEE", [&"swinging_blow"]), true), &"swinging_blow",
		"Swinging Blow → swinging_blow zinciri")
	t.eq(UnitAttackChains.select_chain(_atk("MELEE", [], 3), true), &"cleave",
		"Cleave(3) → cleave zinciri")
	t.eq(UnitAttackChains.select_chain(_atk("RANGED", [&"automatic"]), false), &"automatic",
		"Automatic → automatic zinciri")

	# CLEAVE(1) BİR ZİNCİR DEĞİLDİR — tek saldırıya indirgenir, normal akıştan geçmeli.
	# (Aksi hâlde off-hand/Reload/Risky gibi akış-sonu kuralları ATLANIRDI.)
	t.eq(UnitAttackChains.select_chain(_atk("MELEE", [], 1), true), &"",
		"Cleave(1) → zincir DEĞİL, normal tek hedef akışı")

	# Zincirler saldırı TİPİNE bağlı: melee keyword'ü menzilli silahta tetiklenmemeli.
	t.eq(UnitAttackChains.select_chain(_atk("MELEE", [&"automatic"]), true), &"",
		"Automatic yalnız MENZİLLİ saldırıda zincir açar")
	t.eq(UnitAttackChains.select_chain(_atk("RANGED", [&"swinging_blow"]), false), &"",
		"Swinging Blow yalnız MELEE saldırıda zincir açar")
	t.eq(UnitAttackChains.select_chain(_atk("RANGED", [], 3), false), &"",
		"Cleave yalnız MELEE saldırıda zincir açar")

	# ÖNCELİK: aynı anda iki keyword varsa Swinging Blow kazanır (refaktör öncesi davranış).
	t.eq(UnitAttackChains.select_chain(_atk("MELEE", [&"swinging_blow"], 3), true), &"swinging_blow",
		"Swinging Blow + Cleave → Swinging Blow önceliklidir")

	# ── AKIŞ SÖZLEŞMESİ ───────────────────────────────────────────────────
	var flow: GDScript = load(FLOW)
	t.ok(flow != null, "attack_flow.gd yüklenebiliyor")
	for fn in ["execute", "_build", "_validate", "_prepare", "_compute_modifier",
			"_record_action", "_run_chain_if_any", "_roll_success", "_resolve_hit",
			"_resolve_miss", "_resolve_scatter", "_finish"]:
		t.ok(flow.has_method(fn), "AttackFlow.%s() var" % fn)

	# NOT: `UnitAttackChains` bir `class_name` olduğu için üzerinde doğrudan `has_method()`
	# çağrılamaz ("Make an instance instead") — script kaynağı üzerinden sorgulanır.
	var chains: GDScript = load("res://scripts/unit/unit_attack_chains.gd")
	t.ok(chains.has_method("run"), "UnitAttackChains.run(chain, ...) var")
	t.ok(chains.has_method("select_chain"), "UnitAttackChains.select_chain() var")

	# ── AttackContext ─────────────────────────────────────────────────────
	var ctx := AttackContext.new()
	ctx.is_melee = true
	ctx.modifier = -2
	ctx.total_roll = 9
	t.eq(ctx.action_key, "", "AttackContext varsayılanları temiz")
	t.eq(ctx.modifier, -2, "AttackContext.modifier taşınıyor")
	t.eq(ctx.total_roll, 9, "AttackContext.total_roll taşınıyor")

	# ── unit.gd artık YALNIZ yönlendirici ────────────────────────────────
	var src := FileAccess.open("res://scenes/unit/unit.gd", FileAccess.READ)
	t.ok(src != null, "unit.gd okunabildi")
	if src != null:
		var txt := src.get_as_text()
		src.close()
		t.ok(txt.contains("AttackFlow.execute("),
			"unit.gd saldırıyı AttackFlow'a delege ediyor")
		# Ölü sarmalayıcılar geri gelmemeli (hepsi UnitAttackChains'e taşındı).
		for dead in ["func _execute_swinging_blow", "func _execute_cleave_attacks",
				"func _execute_automatic_attacks", "func _execute_offhand_attack",
				"func _next_cleave_target", "func _next_automatic_target"]:
			t.ok(not txt.contains(dead), "unit.gd'de ölü sarmalayıcı yok: %s" % dead)
