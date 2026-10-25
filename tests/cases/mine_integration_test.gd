extends RefCounted

## Set Mine / Defuse Mine artık GERÇEKTEN çalışan aksiyonlar olmalı (denetim bulgusu S-5).
## Önceden `.tres` dosyaları vardı ama `AbilityRegistry.CUSTOM` kaydında olmadıkları için
## `AbilityExecutor.execute()` onları erkenden iptal ediyor, buton bile üretilmiyordu.

func run(t) -> void:
	# ── Yetenekler uygulanmış olarak kayıtlı mı? ───────────────────────────
	t.ok(AbilityRegistry.is_implemented(&"set_mine"),
		"set_mine → AbilityRegistry.CUSTOM kaydında (artık iptal edilmiyor)")
	t.ok(AbilityRegistry.is_implemented(&"defuse_mine"),
		"defuse_mine → AbilityRegistry.CUSTOM kaydında")

	# ── .tres parametreleri compendium'a uygun mu? ─────────────────────────
	var sm: Resource = load("res://assets/data/abilities/set_mine.tres")
	t.eq(sm.success_threshold, 7, "Set Mine eşiği 7+ (uydurma 5 düzeltildi)")
	t.eq(sm.dice_modifier, 2, "Set Mine → +2 Dice")
	t.eq(sm.is_risky, false,
		"Set Mine Risky DEĞİL (compendium: 'If the roll is a Failure, nothing happens')")
	t.ok(AbilityExecutor.is_actionable_ability(sm), "Set Mine → aksiyon butonu üretebilir")

	var dm: Resource = load("res://assets/data/abilities/defuse_mine.tres")
	t.eq(dm.is_risky, false,
		"Defuse Mine .tres seviyesinde Risky DEĞİL (risky davranış MineActions.handle_defuse_mine içinde yönetilir)")
	t.ok(AbilityExecutor.is_actionable_ability(dm), "Defuse Mine → aksiyon butonu üretebilir")

	# ── Yeteneği taşıyan birimler ──────────────────────────────────────────
	for name in ["sultanate_sapper", "new_antioch_combat_engineer"]:
		var ud: Resource = load("res://assets/data/units/%s.tres" % name)
		t.ok(ud != null, "%s yüklendi" % name)
		if ud == null:
			continue
		var ids: Array = []
		for ab in ud.abilities:
			if ab != null:
				ids.append(ab.ability_id)
		t.ok(ids.has(&"set_mine"), "%s → Set Mine yeteneği" % name)
		t.ok(ids.has(&"defuse_mine"), "%s → Defuse Mine yeteneği" % name)
		t.ok(KeywordSystem.has(ud, &"negate_mined"), "%s → [Negate Mined]" % name)

	# ── Patlama saldırısı [Shrapnel] taşımalı ──────────────────────────────
	var det: Resource = load("res://assets/data/attacks/mine_detonation.tres")
	t.ok(det != null, "mine_detonation.tres mevcut")
	t.ok(KeywordSystem.has(det, &"shrapnel"),
		"Mayın patlaması → [Shrapnel] (compendium: 'Injury Roll with the [Shrapnel] Keyword')")
	t.ok(LocalizationManager.has_key(det.attack_name), "mine_detonation → ad anahtarı localization'da")

	# ── Hata mesajları iki dilde ───────────────────────────────────────────
	for key in ["MINE_FAIL_ALREADY_MINED", "MINE_FAIL_NO_MINE"]:
		t.ok(LocalizationManager.has_key(key), "%s localization'da var" % key)

	# ── Uçtan uca: mayın kur → kayıtta görün → tüket ───────────────────────
	TerrainManager.clear_all()
	var mine_data: Resource = load("res://assets/data/terrain/mine.tres")
	TerrainManager.spawn_feature(mine_data, Vector3(3, 0, 3), "Sapper1")
	t.eq(TerrainManager.has_keyword_at(Vector3(3, 0, 3), &"mined"), true, "Mayın sahada")

	# Kuran model patlatmaz; sıradan model patlatır (MineResolver kararı)
	var sapper_ud: Resource = load("res://assets/data/units/sultanate_sapper.tres")
	var yeoman_ud: Resource = load("res://assets/data/units/new_antioch_yeoman.tres")
	t.eq(MineResolver.detonates_for(sapper_ud, "Sapper1", "Sapper1"), false,
		"Kuran model kendi mayınını patlatmaz")
	t.eq(MineResolver.detonates_for(sapper_ud, "Sapper1", "Sapper2"), false,
		"[Negate Mined] taşıyan başka bir Sapper de patlatmaz")
	t.eq(MineResolver.detonates_for(yeoman_ud, "Sapper1", "Yeoman1"), true,
		"Sıradan asker patlatır")

	TerrainManager.consume_at(Vector3(3, 0, 3))
	t.eq(TerrainManager.has_keyword_at(Vector3(3, 0, 3), &"mined"), false,
		"Patlayan mayın sahadan kalkar ('the terrain piece is then no longer Mined')")
	TerrainManager.clear_all()
