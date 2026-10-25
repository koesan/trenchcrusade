## DicePoolBuilder — Trench Crusade Zar Havuzu Hesaplama Motoru
##
## Bu sınıf STATELESS'tır: hiçbir durumu saklamaz, sadece hesaplar ve döndürür.
## unit.gd içindeki tüm modifier toplama mantığı buraya taşınmıştır.
##
## Kullanım:
##   var ctx = DicePoolBuilder.build_attack_context(attacker, atk, enemy, dist)
##   var mod = DicePoolBuilder.compute_success_modifier(ctx)
##   var inj_ctx = DicePoolBuilder.build_injury_context(attacker, atk, target, is_crit, is_melee)
##   var inj_mod = DicePoolBuilder.compute_injury_modifier(inj_ctx)
##   var flat = DicePoolBuilder.compute_injury_flat(inj_ctx)
class_name DicePoolBuilder

## Yakınlık pasifleri (Onward Christian Soldiers, Unholy Hymns vb.) için aura menzili (inç).
## Merkezi config'ten (game_config.json → balance/aura_range) okunur; 8.0 güvenli varsayılan.
## Statik sınıf olduğu için değer runtime'da (çağrı anında) GameConfig'ten alınır.
static func aura_range() -> float:
	return GameConfig.f("balance/aura_range", 8.0)

# ─────────────────────────────────────────────────────────────────────────────
# BAŞARI ZARI (Success Roll / Trench Roll) — Saldırı tarafı
# ─────────────────────────────────────────────────────────────────────────────

## Saldırı bağlamını Dictionary olarak derler.
## Tüm modifier kararları bu context üzerinden alınır.
static func build_attack_context(
		attacker,             # unit.gd node
		atk: Resource,        # AttackData
		enemy,                # unit.gd node (hedef)
		dist: float,          # Mesafe (metre)
		is_diving_charge: bool = false  # Caller hesaplar (circular dep önlemek için)
) -> Dictionary:
	var is_melee: bool = atk.attack_type == "MELEE"
	var half_range: float = atk.attack_range / 2.0
	var is_long_range: bool = not is_melee and dist > half_range

	# Siper: görüş hattı kısmi engellenmesi VEYA hedefin FORTIFY (Cover) yeteneği aktif.
	var in_cover: bool = false
	if enemy.has_method("get_line_of_sight_status"):
		var los = attacker.get_line_of_sight_status(enemy)
		in_cover = los.in_cover or los.is_blocked
	if "has_fortify_cover" in enemy and enemy.has_fortify_cover:
		in_cover = true
	# ARAZİ KAYNAKLI [Cover] (comprehensive-rules/terrain.md): siper gibi arazi parçalarının
	# üzerindeki/içindeki modeller [Cover] taşır. Kayıt TerrainManager'da; Fortify/Dug In ile
	# AYNI sonucu verir (menzilli saldırıya -1 Dice).
	if TerrainManager.has_keyword_at(enemy.global_position, &"cover"):
		in_cover = true

	# Kendi hücumundan mı geliyor?
	var is_from_charge: bool = attacker.actions_taken.has("charge")

	return {
		"attacker": attacker,
		"attack_data": atk,
		"enemy": enemy,
		"is_melee": is_melee,
		"is_long_range": is_long_range,
		"in_cover": in_cover,
		"is_from_charge": is_from_charge,
		"is_diving_charge": is_diving_charge,
		"attacker_is_down": attacker.is_down,
	}

## Başarı Zarı modifikatör KALEMLERİNİ döndürür (tek kaynak). Her kalem: {key, value}.
## compute_success_modifier ve breakdown kartı bunu kullanır → tutarlılık (DRY).
static func _success_entries(ctx: Dictionary) -> Array:
	var attacker = ctx["attacker"]
	var atk: Resource = ctx["attack_data"]
	var is_melee: bool = ctx["is_melee"]
	var e: Array = []

	var base_mod: int = attacker.melee_dice_modifier if is_melee else attacker.ranged_dice_modifier
	if base_mod != 0:
		e.append({"key": "MOD_BASE_SKILL", "value": base_mod})
	if atk.dice_modifier != 0:
		e.append({"key": "MOD_WEAPON", "value": atk.dice_modifier})
	if ctx["attacker_is_down"]:
		e.append({"key": "MOD_DOWN", "value": -1})
	# IGNORE LONG RANGE (Infernal Bomb vb.): SNIPER'a EK bir istisna — o silahın kendi keyword'ü.
	# SHOTGUN: "Add -1 Injury Dice to rolls at Long Range INSTEAD OF the usual Long Range modifier
	# (-1 Dice)" — bu yüzden Success Roll cezası da SHOTGUN silahlarında uygulanmaz (injury tarafında
	# compute_injury_modifier'da uygulanır).
	if ctx["is_long_range"] and not atk.is_sniper and not KeywordSystem.has(atk, &"ignore_long_range") \
			and not KeywordSystem.has(atk, &"shotgun"):
		e.append({"key": "MOD_LONG_RANGE", "value": -1})
	if not is_melee and ctx["in_cover"] and not atk.ignore_cover:
		e.append({"key": "MOD_COVER", "value": -1})
	# DEFENDED OBSTACLE (core-rules/melee-attacks.md): "Add [-1 Dice] to the roll if the target is
	# in cover and the terrain piece providing the cover lies between it and the attacking model."
	# keyword.md COVER: "has the Cover OR Defended Obstacle attack modifiers". Önceden siper yalnız
	# menzilli saldırıda işliyordu — Fortify/Dug In/siper arazisi yakın dövüşe hiç koruma vermiyordu.
	if is_melee and ctx["in_cover"]:
		e.append({"key": "MOD_DEFENDED_OBSTACLE", "value": -1})

	# INFECTION MARKER Success Roll tarafı BURADA UYGULANMAZ (compendium denetimi, Adım 3).
	# keyword.md: "INFECTION MARKERS can be used to modify dice rolls exactly like Blood Markers."
	# Yani rakip kaç tane harcayacağını SEÇER ve harcananlar SİLİNİR — Kan İşaretiyle aynı akış.
	# Eskiden burada mevcut tüm işaretler koşulsuz -Dice olarak ekleniyor ve HİÇ TÜKENMİYORDU;
	# 6 işaretli bir model sonsuza kadar her Success Roll'unda -6 Dice yiyordu. Harcama artık
	# `Unit.perform_unit_success_roll` içinde (Kan/Nimet ile aynı yerde) sorulur.

	if is_melee:
		var enemy = ctx["enemy"]
		var tf: bool = enemy.unit_data != null and (enemy.unit_data.has_fear or KeywordSystem.has(enemy.unit_data, &"fear"))
		var af: bool = attacker.unit_data != null and (attacker.unit_data.has_fear or KeywordSystem.has(attacker.unit_data, &"fear"))
		var anf: bool = KeywordSystem.negates(attacker.unit_data, &"fear") if attacker.unit_data else false
		if not anf and attacker.unit_data != null and KeywordSystem.has(attacker.unit_data, &"new_antioch") \
				and _friendly_aura_nearby(attacker, &"onward_christian_soldiers", aura_range()):
			anf = true
		if tf and not af and not anf:
			e.append({"key": "MOD_FEAR", "value": -1})

	var enemy_t = ctx["enemy"]
	if enemy_t != null and enemy_t.unit_data != null:
		var tsp: int = KeywordSystem.value(enemy_t.unit_data, &"target_success_penalty", 0)
		if tsp != 0:
			e.append({"key": "MOD_TARGET_DEFENCE", "value": tsp})
		if not is_melee:
			var trp: int = KeywordSystem.value(enemy_t.unit_data, &"target_ranged_penalty", 0)
			if trp != 0:
				e.append({"key": "MOD_STEALTH", "value": trp})

	if is_melee and attacker.unit_data != null \
			and KeywordSystem.has(attacker.unit_data, &"counter_charge") and ctx["is_from_charge"]:
		e.append({"key": "MOD_COUNTER_CHARGE", "value": 1})
	# OVERWHELMING HORDE (Grail/Fly Thrall): melee'de 3" içindeki her dost için +1 DICE.
	if is_melee and attacker.unit_data != null and KeywordSystem.has(attacker.unit_data, &"overwhelming_horde"):
		var horde: int = _count_friendlies_within(attacker, 3.0)
		if horde > 0:
			e.append({"key": "MOD_OVERWHELMING_HORDE", "value": horde})
	# STRENGTH THROUGH PAIN (Crimson Communicant, Red Brigade): kendi üzerindeki her Blood Marker
	# için Melee Success Roll'una +1 Dice. (Rakibin bu Blood Marker'ları Fight'a karşı harcayarak
	# -Dice vermesini engelleyen ikinci cümle bu projede ayrı bir mekanik gerektiriyor, bağlanmadı.)
	if is_melee and attacker.unit_data != null and KeywordSystem.has(attacker.unit_data, &"strength_through_pain") \
			and attacker.blood_markers > 0:
		e.append({"key": "MOD_STRENGTH_THROUGH_PAIN", "value": attacker.blood_markers})
	if attacker.unit_data != null and _enemy_aura_nearby(attacker, &"unholy_hymns", aura_range()):
		e.append({"key": "MOD_UNHOLY_HYMNS", "value": -1})
	if is_melee and ctx.get("is_diving_charge", false):
		e.append({"key": "MOD_DIVING_CHARGE", "value": 1})
	if not is_melee:
		var enemy_e = ctx["enemy"]
		# IGNORE ELEVATED POSITION (battlekit/ranged.md — Infernal Bomb): havan/topçu tipi
		# silahlar yukarıdan atış avantajından yararlanmaz; mermi zaten balistik bir yay çizer.
		var ignores_elev: bool = KeywordSystem.has(atk, &"ignore_elevated_position")
		if enemy_e != null and not ignores_elev \
				and (attacker.global_position.y - enemy_e.global_position.y) >= 3.0:
			e.append({"key": "MOD_ELEVATED", "value": 1})

	var fr: int = FactionRules.get_success_dice_modifier(attacker, ctx)
	if fr != 0:
		e.append({"key": "MOD_FACTION", "value": fr})

	# DEMONIC AURA — WRATH (Court, Desecrated Saint): "Düşman modeller 3\" içinde Melee Success Roll'larına -1 Dice alır."
	if is_melee and MechanicsResolver.is_in_demonic_aura(attacker, &"wrath_aura"):
		e.append({"key": "MOD_WRATH_AURA", "value": -1})

	return e

## PAIN AMPLIFIER (Combat Biologist'in Vivisector'ı, P1-1): "Lower the roll needed to achieve a
## Critical Success... by 1 for each Blood Marker next to the target." Taban eşik 12; 7'nin altına
## düşürülmez (Success eşiğiyle çakışmasın — compendium bunu sınırlamıyor ama mantıksal taban).
static func compute_crit_threshold(atk: Resource, target_blood_markers: int) -> int:
	if atk == null or not KeywordSystem.has(atk, &"pain_amplifier"):
		return 12
	return maxi(7, 12 - target_blood_markers)

## Bağlamdan Success Roll DICE modifier'ını hesaplar (kalemlerin toplamı).
static func compute_success_modifier(ctx: Dictionary) -> int:
	var total: int = 0
	for it in _success_entries(ctx):
		total += it["value"]
	return total

## UI (Atış Breakdown Kartı) için modifikatör kalemleri.
static func compute_success_breakdown(ctx: Dictionary) -> Array:
	return _success_entries(ctx)

## Başarı olasılığı (%). 2 taban zar + |dice_mod| ek; mod>=0 ise 2 en yüksek, mod<0 ise 2 en
## düşük tutulur; toplam+flat >= threshold. Kartta isabet yüzdesi göstermek için (tam sayım).
static func success_probability(dice_mod: int, flat_mod: int = 0, threshold: int = 7) -> float:
	var n: int = mini(2 + absi(dice_mod), 6)
	var keep_high: bool = dice_mod >= 0
	var total_combos: int = int(pow(6, n))
	var success: int = 0
	var faces: Array = []
	faces.resize(n)
	for combo in range(total_combos):
		var c: int = combo
		for k in range(n):
			faces[k] = (c % 6) + 1
			c = c / 6
		faces.sort()
		var sm: int = (faces[n - 1] + faces[n - 2]) if keep_high else (faces[0] + faces[1])
		if sm + flat_mod >= threshold:
			success += 1
	return float(success) / float(total_combos)

# ─────────────────────────────────────────────────────────────────────────────
# AURA YARDIMCISI — belirli bir keyword'e sahip dost bir birim menzil içinde mi?
# (Onward, Christian Soldiers! gibi yakınlık pasifleri için.)
# ─────────────────────────────────────────────────────────────────────────────
## Belirtilen menzil içindeki (kendisi hariç) ayaktaki dost birim SAYISI. (Overwhelming Horde.)
static func _count_friendlies_within(unit, range_u: float) -> int:
	return UnitQuery.allies_within(unit, range_u).size()

static func _friendly_aura_nearby(unit, aura_kw: StringName, range_u: float) -> bool:
	return UnitQuery.any(UnitQuery.with_keyword(
		UnitQuery.allies_within(unit, range_u), aura_kw))

## Belirli bir keyword'e sahip DÜŞMAN bir birim menzil içinde mi? (Unholy Hymns gibi
## düşmanı zayıflatan yakınlık pasifleri için.)
static func _enemy_aura_nearby(unit, aura_kw: StringName, range_u: float) -> bool:
	return UnitQuery.any(UnitQuery.with_keyword(
		UnitQuery.enemies_within(unit, range_u), aura_kw))

# ─────────────────────────────────────────────────────────────────────────────
# YARA ZARI (Injury Roll) — Savunma tarafı (hedef birim tarafından çağrılır)
# ─────────────────────────────────────────────────────────────────────────────

## Yara zarı bağlamını Dictionary olarak derler.
## is_diving_charge: Caller tarafından hesaplanıp geçirilir (circular dep önlemek için)
static func build_injury_context(
		attacker,             # unit.gd node (saldıran)
		atk: Resource,        # AttackData (saldıranın silahı)
		target,               # unit.gd node (hedef)
		is_critical: bool,    # Çift 6 veya 12+
		is_melee: bool,       # Yakın dövüş mü?
		is_diving_charge: bool = false,  # Caller hesaplar, buraya geçirir
		is_long_range: bool = false      # SHOTGUN keyword'ü için (compute_injury_modifier)
) -> Dictionary:
	return {
		"attacker": attacker,
		"attack_data": atk,
		"target": target,
		"is_critical": is_critical,
		"is_melee": is_melee,
		"is_long_range": is_long_range,
		"target_is_down": target.is_down,
		"target_armour": target.armour,
		"target_blood": target.blood_markers,
		"target_blessing": target.blessing_markers,
		"target_infection": target.infection_markers,
		"target_has_undead_fortitude": target.unit_data.has_undead_fortitude if target.unit_data else false,
		"attack_is_fire": atk.is_fire,
		# DESPATCH (Combat Medic'in Misericordia'sı, P1-1): "this weapon has [Ignore Armour] if
		# the target is Down" — koşullu Ignore Armour, statik atk.ignore_armour'a EK olarak.
		"attack_ignore_armour": atk.ignore_armour or (KeywordSystem.has(atk, &"despatch") and target.is_down),
		"weapon_injury_mod": atk.injury_dice_modifier,
		"is_diving_charge": is_diving_charge,
		# ECHO OF HIS WORD (Ammunition Sacrament, P1-1): saldıranın bir sonraki Ranged saldırısına
		# geçici +1 Injury Dice (yalnız Ranged — compendium "Ranged Attacks").
		"attacker_ranged_injury_bonus": attacker.temp_ranged_injury_bonus \
			if (attacker != null and not is_melee and "temp_ranged_injury_bonus" in attacker) else 0,
	}


## Yara zarı INJURY DICE modifier'ını hesaplar.
## exclude_blood_bonus: BLOODBATH ROLL tetiklendiğinde true geçilir — o durumda Kan İşaretleri
## tek tek +1 Injury Dice olarak SAYILMAZ, çünkü hepsi zaten Bloodbath'i tetiklemek için "harcanıyor".
## Döndürülen değer perform_trench_roll(dice_mod)'a geçirilir.
static func compute_injury_modifier(ctx: Dictionary, exclude_blood_bonus: bool = false) -> int:
	var mod: int = 0

	# Kritik isabet: +1 INJURY DICE (silahta CRITICAL keyword varsa +2)
	if ctx["is_critical"]:
		var atk: Resource = ctx.get("attack_data")
		var crit_bonus: int = 2 if (atk != null and KeywordSystem.has(atk, &"critical")) else 1
		mod += crit_bonus
		GameLogger.log_info("[Injury Pool] Kritik İsabet: +%d Injury Dice" % crit_bonus, "COMBAT")

	# Down hedef + yakın dövüş: +1 INJURY DICE (kural kitabı Bölüm 3)
	if ctx["target_is_down"] and ctx["is_melee"]:
		mod += 1
		GameLogger.log_info("[Injury Pool] Down hedefe yakın dövüş: +1 Injury Dice", "COMBAT")

	# Silah injury_dice_modifier
	var wpn_mod: int = ctx["weapon_injury_mod"]
	if wpn_mod != 0:
		mod += wpn_mod
		GameLogger.log_info("[Injury Pool] Silah modifier: %+d" % wpn_mod, "COMBAT")

	# SHOTGUN (keyword.md): "Add -1 Injury Dice to rolls for attacks made at Long Range with a
	# Weapon that has this Keyword INSTEAD OF the usual Long Range modifier (-1 Dice)" — Success
	# Roll tarafında bu silahlar zaten muaf (bkz. _success_entries), ceza burada uygulanır.
	if ctx.get("is_long_range", false):
		var atk_shotgun: Resource = ctx.get("attack_data")
		if atk_shotgun != null and KeywordSystem.has(atk_shotgun, &"shotgun"):
			mod -= 1
			GameLogger.log_info("[Injury Pool] Shotgun (Long Range): -1 Injury Dice", "COMBAT")

	# ECHO OF HIS WORD (Ammunition Sacrament, P1-1)
	var ranged_bonus: int = ctx.get("attacker_ranged_injury_bonus", 0)
	if ranged_bonus != 0:
		mod += ranged_bonus
		GameLogger.log_info("[Injury Pool] Echo of His Word: +%d Injury Dice" % ranged_bonus, "COMBAT")

	# UNDEAD FORTITUDE: ateş olmayan saldırıda -1 INJURY DICE. PLAGUE-RIDDEN FLESH (Gregori Gula):
	# aynı desenin GÜÇLENDİRİLMİŞ hâli, -2 Injury Dice (Undead Fortitude ile ÇAKIŞMAZ, yerine geçer).
	var tgt_pf = ctx["target"]
	if tgt_pf != null and tgt_pf.unit_data != null and KeywordSystem.has(tgt_pf.unit_data, &"plague_ridden_flesh") and not ctx["attack_is_fire"]:
		mod -= 2
		GameLogger.log_info("[Injury Pool] Plague-Ridden Flesh: -2 Injury Dice", "COMBAT")
	elif ctx["target_has_undead_fortitude"] and not ctx["attack_is_fire"]:
		mod -= 1
		GameLogger.log_info("[Injury Pool] Undead Fortitude: -1 Injury Dice", "COMBAT")

	# BLOOD MARKERS: Artık OTOMATIK eklenmez. Compendium'a göre saldıran oyuncu hedefin Kan
	# İşaretlerini harcamayı SEÇER (her biri +1 Injury Dice ya da Bloodbath). Bu seçim ve ekleme
	# resolve_injury_roll içinde CombatChoice ile yapılır (bkz. unit.gd). exclude_blood_bonus
	# parametresi geriye dönük uyumluluk için korunur ama artık kullanılmaz.

	# INFECTION MARKERS: Artık OTOMATIK eklenmez (Blood Marker ile AYNI kural: "modify dice rolls
	# EXACTLY LIKE Blood Markers"). Bu seçim ve ekleme resolve_injury_roll içinde CombatChoice
	# ile yapılır (bkz. unit.gd — 2026-07-16 düzeltmesi, önceden koşulsuz otomatikti).

	# NOT: DIVING CHARGE artık Injury değil, MELEE SUCCESS ROLL'una +1 DICE olarak
	# uygulanıyor (bkz. compute_success_modifier — compendium melee-attacks.md).

	# FINISH THE FALLEN (Combat Medic): Down hedefe yakın dövüşte +1 Injury Dice
	# (hedef DEMONIC veya BLACK GRAIL DEĞİLSE — compendium).
	var atkr = ctx.get("attacker")
	var tgt = ctx.get("target")
	var atk_r: Resource = ctx.get("attack_data")

	# DEATH WAIL (Barbed Wire Banshee, Trench Ghosts): hedefin 8" içinde düşman Banshee varsa
	# TÜM Injury Roll'lara +1 Injury Dice (Unholy Hymns ile aynı aura deseni, Success yerine Injury).
	if tgt != null and tgt.unit_data != null and _enemy_aura_nearby(tgt, &"death_wail", aura_range()):
		mod += 1
		GameLogger.log_info("[Injury Pool] Death Wail: +1 Injury Dice", "COMBAT")
	if ctx["is_melee"] and ctx["target_is_down"] \
			and atkr != null and atkr.unit_data != null and KeywordSystem.has(atkr.unit_data, &"finish_the_fallen") \
			and tgt != null and tgt.unit_data != null \
			and not (KeywordSystem.has(tgt.unit_data, &"demonic") or KeywordSystem.has(tgt.unit_data, &"black_grail")):
		mod += 1
		GameLogger.log_info("[Injury Pool] Finish the Fallen: +1 Injury Dice", "COMBAT")

	# Model düzeyi savunma: -X INJURY DICE (Artificial Life = -1, Corpulent = -2).
	if tgt != null and tgt.unit_data != null:
		var idd: int = KeywordSystem.value(tgt.unit_data, &"injury_dice_defence", 0)
		if idd != 0:
			mod += idd
			GameLogger.log_info("[Injury Pool] Model savunması: %+d Injury Dice" % idd, "COMBAT")
		# ABIOTIC LIFE (Artillery Witch): GAS saldırılarına -1 Injury Dice.
		if atk_r != null and atk_r.is_poison and KeywordSystem.has(tgt.unit_data, &"abiotic_life"):
			mod -= 1
			GameLogger.log_info("[Injury Pool] Abiotic Life (Gas): -1 Injury Dice", "COMBAT")

	# MUBARIZUN (Yüzbaşı): hedef TOUGH ise +1 Injury Dice.
	if atkr != null and atkr.unit_data != null and KeywordSystem.has(atkr.unit_data, &"mubarizun") \
			and tgt != null and tgt.unit_data != null and tgt.unit_data.has_tough:
		mod += 1
		GameLogger.log_info("[Injury Pool] Mubarizun (Tough hedef): +1 Injury Dice", "COMBAT")

	# BALLISTIC BOX ARMOUR / ENGINEER BODY ARMOUR (Combat Engineer, P1-1): "Add -1 Injury Dice
	# to Injury Rolls for a model that has Engineer Body Armour hit by Shrapnel even if weapon has
	# Ignore Armour." negate_shrapnel keyword'ü bu birimi tanımlar; saldırıdaki shrapnel keyword'ü
	# kontrol edilir — ignore_armour olsa bile -1 Injury Dice uygulanır.
	# DÜZELTME (denetim P2-NA-15b): eskiden `negate_shrapnel` ile eşleşiyordu — ama o keyword'ü
	# Combat Helmet (5 ) taşıyan HER birim alır. Compendium bu ek −1 Injury Dice'ı YALNIZ
	# Engineer Body Armour'a verir, o da yalnız New Antioch Combat Engineer'da bulunur.
	if tgt != null and tgt.unit_data != null and KeywordSystem.has(tgt.unit_data, &"ballistic_box_armour") \
			and atk_r != null and KeywordSystem.has(atk_r, &"shrapnel") and ctx["attack_ignore_armour"]:
		mod -= 1
		GameLogger.log_info("[Injury Pool] Ballistic Box Armour (Shrapnel+Ignore Armour): -1 Injury Dice", "COMBAT")

	return mod


## Yara zarı FLAT modifier'ını hesaplar (zırh + model/silah Injury Modifier'ları).
## SAF: yalnız `ctx` ile statik `unit_data`/`attack_data` okur, HİÇBİR durumu değiştirmez.
## (Eski "blessing_markers burada harcanır" notu geçersizdi — Nimet harcaması artık oyuncu
## seçimiyle `InjuryMarkerSpend`te yapılıyor.)
static func compute_injury_flat(ctx: Dictionary) -> int:
	var flat: int = 0
	var target = ctx.get("target")
	var atk: Resource = ctx.get("attack_data")
	var target_ud: Resource = target.unit_data if (target != null and target.unit_data != null) else null

	# IMPERVIOUS (hedef): IGNORE ARMOUR ve ARMOUR PIERCING etkileri bu modelin zırhını
	# etkilemez (compendium keyword.md).
	var impervious: bool = target_ud != null and KeywordSystem.has(target_ud, &"impervious")

	var arm: int = clampi(ctx["target_armour"], 0, 3)
	if ctx["attack_ignore_armour"] and not impervious:
		GameLogger.log_info("[Injury Pool] IGNORE ARMOUR: Zırh yok sayıldı.", "COMBAT")
		arm = 0
	elif atk != null and KeywordSystem.has(atk, &"armour_piercing") and not impervious:
		# ARMOUR PIERCING: hedefin zırh injury modifikatörünü 1 azalt (min 0).
		var pierced: int = maxi(arm - 1, 0)
		if pierced != arm:
			GameLogger.log_info("[Injury Pool] ARMOUR PIERCING: Zırh %d → %d" % [arm, pierced], "COMBAT")
		arm = pierced
	if arm > 0:
		flat -= arm
		GameLogger.log_info("[Injury Pool] Zırh: -%d flat" % arm, "COMBAT")

	# Model düzeyi +/- INJURY MODIFIER (savunma; örn. Observer [-1 Injury Modifier]).
	if target_ud != null:
		var im_mod: int = KeywordSystem.value(target_ud, &"injury_modifier", 0)
		if im_mod != 0:
			flat += im_mod
			GameLogger.log_info("[Injury Pool] Model Injury Modifier: %+d flat" % im_mod, "COMBAT")

	# SİLAH düzeyi +/- INJURY MODIFIER (saldırı; battlekit/melee.md). Compendium bunu
	# [+N Injury Dice]'tan AYIRIR: "Injury Dice" zar SAYISINI, "Injury Modifier" zar
	# toplamına eklenen FLAT değeri değiştirir. Örn. Great Hammer/Maul [+1 Injury Modifier],
	# Sacrificial Blade [+2 Injury Modifier]. (Zar sayısı tarafı: compute_injury_modifier.)
	if atk != null:
		var w_im: int = KeywordSystem.value(atk, &"injury_modifier", 0)
		if w_im != 0:
			flat += w_im
			GameLogger.log_info("[Injury Pool] Silah Injury Modifier: %+d flat" % w_im, "COMBAT")

	# Toplam flat -3'ten küçük olamaz (compendium injuries.md).
	# NOT: bu YALNIZ buradaki kaynakları (zırh + model/silah Injury Modifier) sınırlar. Dışarıdan
	# eklenen modifikatörler (Vengeful Scripture, Blessings of the Serpent Moon) de tavana tabidir
	# ve NİHAİ tavan `InjuryPipeline` içinde, zar atılmadan hemen önce uygulanır.
	flat = maxi(flat, InjuryPipeline.INJURY_MODIFIER_FLOOR)
	return flat

# ─────────────────────────────────────────────────────────────────────────────
# BLOODBATH ROLL — Rakip oyuncu Kan Nişanelerini harcayarak 3D6 veya 4D6
# ─────────────────────────────────────────────────────────────────────────────

## Bloodbath Roll için kaç zar atılacağını hesaplar.
## 6 Kan Nişanesi = Bloodbath Roll (3D6); Down ise 3 Kan Nişanesi yeterli.
## DEADLY silahla: 4D6 atılır.
static func compute_bloodbath_dice_count(
		target,               # unit.gd node (Kan Nişaneleri olan hedef)
		atk: Resource,        # AttackData
		markers_to_spend: int # Harcanacak Kan Nişanesi sayısı
) -> int:
	if atk.is_deadly:
		return 4
	return 3

## Injury Roll'da KAÇ zar tutulacağını hesaplar (P0-2). Compendium (keyword.md DEADLY):
## "roll 3D6 ... pick the 3 highest or lowest dice in the roll instead of the 2 highest or
## lowest" — DEADLY'nin bu ana etkisi yalnız Bloodbath'e özgü DEĞİL, HER Injury Roll'da geçerli.
## Bloodbath'te zaten farklı bir zar sayısı var (compute_bloodbath_dice_count: 3, DEADLY ise 4);
## normal (Bloodbath olmayan) bir Injury Roll'da ise DEADLY 2→3'e çıkarır.
static func compute_injury_keep_count(atk: Resource, is_bloodbath: bool) -> int:
	if is_bloodbath:
		return compute_bloodbath_dice_count(null, atk, 0)
	return 3 if atk.is_deadly else 2

## Bloodbath için minimum Kan Nişanesi eşiğini hesaplar.
## Normal: 6, Down hedef: 3 (kural kitabı)
## attacker: opsiyonel — PLAGUE ALMONER (Plague Knight'ın +10 terfisi, P1-1) "Bloodbath Roll'un
## Blood/Infection Marker maliyeti 1 azalır" için. Taban altına inmez (Down hedefte 3-1=2, en az 1).
static func bloodbath_threshold(target, attacker = null) -> int:
	var base: int = 3 if target.is_down else 6
	if attacker != null and "unit_data" in attacker and attacker.unit_data != null \
			and KeywordSystem.has(attacker.unit_data, &"plague_almoner"):
		base = maxi(1, base - 1)
	return base

## P0-1: Success Roll'a harcanan Blood/Blessing Marker'ların zar değiştiricisine etkisi.
## Compendium (blood-markers.md/blessing-markers.md): Blood -1 Dice/marker (RAKİP harcar),
## Blessing +1 Dice/marker (SAHİBİ harcar). Injury Roll'daki gibi Bloodbath eşdeğeri YOK.
static func apply_success_marker_spend(dice_modifier: int, blood_spend: int, blessing_spend: int) -> int:
	return dice_modifier - blood_spend + blessing_spend
