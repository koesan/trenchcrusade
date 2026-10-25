## SALDIRI AKSİYONU (Shoot / Fight) AKIŞI — çözümlemenin TEK sahibi.
##
## `unit.gd::server_request_attack_action` 231 satırlık, erken-dönüşlerle dolu tek bir prosedürdü
## ve dosya tavanına dayanmıştı. Artık burası adlandırılmış fazlardan oluşuyor; her fazın ne
## yaptığı imzasından okunuyor:
##
##   1. `_validate()`            — RPC yetkisi, hedef/indeks geçerliliği, tek doğrulama kaynağı
##   2. `_prepare()`             — Hide bozma, dost ateşi yönlendirmesi
##   3. `_compute_modifier()`    — havuz + Diving Charge tüketimi + BLOCK
##   4. `_record_action()`       — actions_taken, Assault/HEAVY kilitleri, senkron
##   5. `_run_chain_if_any()`    — Swinging Blow / Cleave(X) / Automatic(X) → çoklu saldırı
##   6. `_roll_success()`        — Flamethrower otomatik isabet / Absolute Faith
##   7. `_resolve_hit()`         — Blast aileleri veya tek hedef Injury Roll
##   8. `_resolve_miss()`        — Scatter, Time Slip
##   9. `_finish()`              — Risky/Shaken bitişi, Off-Hand, Reload bitişi
##
## YENİ SALDIRI KURALI EKLERKEN: ilgili faza git, tüm prosedürü okumana gerek yok.
class_name AttackFlow

## Tek giriş noktası. `unit.gd::server_request_attack_action` buraya delege eder.
static func execute(attacker, enemy_name: String, attack_idx: int) -> void:
	# DANGEROUS TERRAIN (compendium keyword.md): "If you **Activate** a model that is in terrain
	# with this Keyword ... you must take a [Risky Success] Roll." Aktivasyon başına bir kez;
	# başarısızlıkta Injury Roll + aktivasyon biter, saldırı hiç çözümlenmez.
	if await TerrainRules.check_activation_start(attacker):
		return
	var ctx := _build(attacker, enemy_name, attack_idx)
	if ctx == null:
		return
	if not _validate(ctx):
		return

	_prepare(ctx)
	if ctx.enemy == null:
		# Dost ateşi hedefi düşürdü — aktivasyon durumu yine de güncellenmeli.
		attacker.check_activation_complete()
		return

	_compute_modifier(ctx)
	_record_action(ctx)

	# ÇOKLU SALDIRI ZİNCİRİ (Swinging Blow / Cleave(X) / Automatic(X)): tıklanan tek hedefin
	# YERİNE geçer, kendi Success/Injury Roll dizisini yürütür. Ama aksiyon-sonu kuralları
	# (RELOAD, Off-Hand) yine İŞLEMELİDİR — bkz. `_finish_after_chain`.
	if await _run_chain_if_any(ctx):
		await _finish_after_chain(ctx)
		return

	RpcHelper.sync(ctx.enemy, "set_targeted", [true])
	RpcHelper.sync(attacker, "play_attack_effect", [ctx.enemy.global_position])

	await _roll_success(ctx)

	if is_instance_valid(ctx.enemy):
		RpcHelper.sync(ctx.enemy, "set_targeted", [false])
	if not is_instance_valid(ctx.enemy) or ctx.enemy.current_health <= 0:
		return

	if ctx.total_roll >= 7:
		await _resolve_hit(ctx)
	else:
		await _resolve_miss(ctx)

	await _finish(ctx)

# ─────────────────────────────────────────────────────────────────────────────
#  FAZLAR
# ─────────────────────────────────────────────────────────────────────────────

## Bağlamı kurar. Hedef/indeks geçersizse null döner (sessizce iptal — bozuk/eski RPC).
static func _build(attacker, enemy_name: String, attack_idx: int) -> AttackContext:
	if not GameState.units.has(enemy_name):
		return null
	if attack_idx < 0 or attack_idx >= attacker.unit_data.attacks.size():
		return null

	var ctx := AttackContext.new()
	ctx.attacker = attacker
	ctx.enemy = GameState.units[enemy_name]
	ctx.atk = attacker.unit_data.attacks[attack_idx]
	ctx.is_melee = ctx.atk.attack_type == "MELEE"
	ctx.dist = attacker.global_position.distance_to(ctx.enemy.global_position)
	ctx.action_key = "melee" if ctx.is_melee else "shoot"
	return ctx

## TEK DOĞRULAMA KAYNAĞI (P2-8): hedef/menzil/LoS/Hide/angaje/etkileşim —
## hepsi `CombatResolver.validate_attack`te. Aksiyon paneli, hedef vurgusu ve
## `has_any_remaining_action` da AYNI kaynağı (`can_use_attack`) kullanır.
static func _validate(ctx: AttackContext) -> bool:
	return CombatResolver.validate_attack(ctx.attacker, ctx.atk, ctx.enemy, ctx.dist) == ""

## Saldırı öncesi yan etkiler.
static func _prepare(ctx: AttackContext) -> void:
	# Saldırı, saldıranın saklanmasını (Hide) bozar — HAREKET değil, bu yüzden Fortify korunur.
	ctx.attacker.break_stealth_on_own_action(false)

	if ctx.is_melee:
		return
	# DOST ATEŞİ: hedefin yakınında dost varsa zar atılır, sonuç hedefi DEĞİŞTİREBİLİR.
	ctx.enemy = CombatResolver.resolve_friendly_fire_check(ctx.attacker, ctx.enemy)
	if not is_instance_valid(ctx.enemy) or ctx.enemy.current_health <= 0:
		ctx.enemy = null

## Success Roll modifikatörü.
static func _compute_modifier(ctx: AttackContext) -> void:
	# DIVING CHARGE: başarılı riskli sıçrama sonrası SONRAKİ Melee Success Roll'una +1 DICE.
	# Bonus yalnız BİR KEZ uygulanır — burada tüketilir (compendium "next Melee Attack").
	ctx.diving = ctx.is_melee and ctx.attacker.diving_charge_bonus_pending
	if ctx.diving:
		ctx.attacker.diving_charge_bonus_pending = false
		RpcHelper.sync(ctx.attacker, "sync_diving_charge_pending", [false])

	ctx.pool_ctx = DicePoolBuilder.build_attack_context(
		ctx.attacker, ctx.atk, ctx.enemy, ctx.dist, ctx.diving)
	ctx.modifier = DicePoolBuilder.compute_success_modifier(ctx.pool_ctx)

	# BLOCK (Polearm, keyword.md): "Add -1 Dice for Melee Attacks targeting that model if the
	# attacker made a Charge Action before making the attack this turn."
	if ctx.is_melee and ctx.attacker.actions_taken.has("charge") \
			and ctx.attacker._target_wields_block_weapon(ctx.enemy):
		ctx.modifier -= 1
		GameLogger.log_info("[Block] %s: hedefin BLOCK silahı, Charge sonrası saldırıya -1 Dice." \
			% ctx.attacker.display_name, "COMBAT")

## Aksiyonu kaydeder ve bu saldırının doğurduğu KİLİTLERİ kurar.
static func _record_action(ctx: AttackContext) -> void:
	var a = ctx.attacker
	a.actions_taken.append(ctx.action_key)

	# Assault OLMAYAN Shoot yapıldıysa bu aktivasyonda Charge/Fight kilitlenir (compendium).
	if not ctx.is_melee and not ctx.atk.is_assault:
		a.has_non_assault_shot = true

	# HEAVY: bu saldırı sonrası Move/Charge/Retreat/Dash da kilitlenir (P0-5, simetrik kısıt).
	# `negate_heavy_effect` (Assault Drill / Battlefield Demolition) yalnız BU silahın etkisini
	# yok sayar — `has()` zaten atk-spesifik olduğundan unit-wide negate ile aynı satırda
	# kontrol edilmesi doğrudur (bkz. mechanics_resolver.gd::has_unnegated_heavy_loadout).
	if not ctx.is_melee and KeywordSystem.has(ctx.atk, &"heavy") \
			and not (a.unit_data and (KeywordSystem.negates(a.unit_data, &"heavy") \
				or KeywordSystem.has(a.unit_data, &"negate_heavy_effect"))):
		a.has_heavy_shot = true

	RpcHelper.sync(a, "sync_actions_taken", [a.actions_taken])

## ÇOKLU SALDIRI ZİNCİRLERİ — Swinging Blow / Cleave(X) / Automatic(X).
## Üçü de tıklanan TEK hedefin YERİNE geçer (normal tek-hedef akışı atlanır).
## Döner: bir zincir çalıştı mı? (true ise çağıran erken döner.)
static func _run_chain_if_any(ctx: AttackContext) -> bool:
	var chain: StringName = UnitAttackChains.select_chain(ctx.atk, ctx.is_melee)
	if chain == &"":
		return false
	await UnitAttackChains.run(chain, ctx.attacker, ctx.enemy, ctx.atk)
	return true

## Success Roll (ya da otomatik isabet).
static func _roll_success(ctx: AttackContext) -> void:
	# FLAMETHROWER (keyword.md): "it is automatically a Success. Do not make a Success Roll for
	# the attack. Note that this means that the attack cannot achieve a Critical Success."
	if not ctx.is_melee and KeywordSystem.has(ctx.atk, &"flamethrower"):
		ctx.total_roll = 7
		GameLogger.log_info("[Flamethrower] %s: Success Roll atlandı, otomatik isabet." \
			% ctx.attacker.display_name, "COMBAT")
		return

	# ABSOLUTE FAITH (Sniper Priest): "the opposing player cannot spend Blood Markers to add
	# -Dice to a Ranged Attack by a Sniper Priest" — yalnız Ranged saldırıda geçerli.
	var ud = ctx.attacker.unit_data
	var allow_blood: bool = ctx.is_melee or ud == null \
		or not KeywordSystem.has(ud, &"absolute_faith")
	var roll_res: Array = await ctx.attacker.perform_unit_success_roll(ctx.modifier, allow_blood)
	ctx.total_roll = roll_res[0]

## İSABET — Blast aileleri ya da tek hedef Injury Roll.
static func _resolve_hit(ctx: AttackContext) -> void:
	var a = ctx.attacker
	# PAIN AMPLIFIER (Combat Biologist'in Vivisector'ı): hedefin Kan İşareti sayısı kadar düşük
	# Kritik eşiği — yalnız MELEE (compendium "for a Melee Attack made by this weapon").
	var crit_threshold: int = DicePoolBuilder.compute_crit_threshold(
		ctx.atk, ctx.enemy.blood_markers) if ctx.is_melee else 12
	ctx.is_crit = ctx.total_roll >= crit_threshold
	GameLogger.log_info("%s Başarılı İsabet! Zar: %d. Yara zarına geçiliyor." \
		% [a.display_name, ctx.total_roll], "COMBAT")
	BattleEvents.hit(a, ctx.enemy, ctx.atk.attack_name, ctx.total_roll, ctx.is_crit)

	# CARTRIDGE OF HIS WRATH (Ammunition Sacrament): Ranged silah zaten Blast/Flamethrower
	# taşımıyorsa geçici olarak Blast 2" kazanır. (Shrapnel tarafı `InjuryPipeline._attack_element`.)
	var cartridge_blast: bool = not ctx.is_melee and a.temp_cartridge_of_wrath \
		and not ctx.atk.is_blast and not KeywordSystem.has(ctx.atk, &"flamethrower")
	var has_blast: bool = ctx.atk.is_blast and ctx.atk.blast_radius > 0.0

	if has_blast and KeywordSystem.has(ctx.atk, &"scatter"):
		# SCATTER + INFERNAL STRIKE + MIGHTY EXPLOSION (Artillery Witch'in Infernal Bomb'u):
		# Success/Crit → doğrudan hedeflenen model Deadly kazanır, blast'a yakalanan diğerleri
		# ALMAZ (bu yüzden `execute_blast`ten İZOLE bir fonksiyon).
		MechanicsResolver.execute_infernal_bomb_blast(
			a, ctx.enemy, ctx.enemy.global_position, ctx.atk.blast_radius, ctx.atk, ctx.is_crit, true)
		return
	if has_blast:
		# BLOOD MAGIC boşluğu (dokümante): Blast silahlı bir yükleme bugün ERİŞİLEMEZ (Hell
		# Knight'ın loadout_options'ı yok) — bu yüzden +1 Injury Dice yalnız tek-hedef yolunda.
		# `primary_target`: Kritik bonusu RAW'da YALNIZ hedeflenen modele verilir.
		MechanicsResolver.execute_blast(
			a, ctx.enemy.global_position, ctx.atk.blast_radius, ctx.atk, ctx.is_crit, ctx.enemy)
		return
	if cartridge_blast:
		MechanicsResolver.execute_blast(
			a, ctx.enemy.global_position, 2.0, ctx.atk, ctx.is_crit, ctx.enemy)
		return

	# BLOOD MAGIC (Hell Knight, Goetic (1) Spell): "Cast this spell before making any Injury Rolls
	# for an attack made by the spellcaster. If you do so, add +1 Injury Dice."
	var extra_injury_dice: int = 0
	if a.unit_data != null and KeywordSystem.has(a.unit_data, &"blood_magic"):
		var paid: int = await AbilityExecutor.try_cast_reactive_goetic(
			a, &"blood_magic", 1, 1, "BLOOD_MAGIC")
		if paid > 0:
			extra_injury_dice = 1

	# PILGRIM / BLACK GRAIL BODYGUARD: darbe başka bir modele yönlendirilebilir.
	var injury_target = await ctx.enemy._maybe_redirect_to_bodyguard()
	await injury_target.resolve_injury_roll(a, ctx.is_crit, ctx.is_melee, 0, extra_injury_dice, null,
		ctx.pool_ctx.get("is_long_range", false), ctx.pool_ctx.get("in_cover", false), ctx.diving)

## ISKA — Scatter ve Time Slip.
static func _resolve_miss(ctx: AttackContext) -> void:
	GameLogger.log_info("%s Iskalandı. Zar: %d (Gerekli: 7+)" \
		% [ctx.attacker.display_name, ctx.total_roll], "COMBAT")
	BattleEvents.miss(ctx.attacker, ctx.enemy, ctx.atk.attack_name, ctx.total_roll)

	if ctx.atk.is_blast and ctx.atk.blast_radius > 0.0 \
			and KeywordSystem.has(ctx.atk, &"scatter") and is_instance_valid(ctx.enemy):
		await _resolve_scatter(ctx)

	# TIME SLIP (Sultanate Assassin): hedefin sahibine opsiyonel yeniden konuşlanma sorulur.
	if is_instance_valid(ctx.enemy):
		await ctx.enemy._maybe_time_slip(false)

## SCATTER (keyword.md): "if the Success Roll was a Failure, the attack scatters instead of
## missing entirely... subtract the Success Roll from 7... the opponent moves the attack exactly
## that many inches in a direction of their choice."
## Yönü HEDEFİN SAHİBİ (rakip) seçer; kayma noktası bir modelin tabanına denk gelirse o model
## Infernal Strike'ın Deadly bonusunu alır (primary_target olur).
static func _resolve_scatter(ctx: AttackContext) -> void:
	var scatter_dist: float = 7.0 - float(ctx.total_roll)
	if scatter_dist <= 0.0:
		return

	var pick = await CombatChoice.request_position_pick(
		ctx.enemy, scatter_dist, "INFERNAL_BOMB_SCATTER")
	var center: Vector3 = ctx.enemy.global_position
	if pick != null:
		var dir: Vector3 = pick - ctx.enemy.global_position
		dir.y = 0.0
		dir = dir.normalized() if dir.length() > 0.01 else Vector3(1, 0, 0)
		center = ctx.enemy.global_position + dir * scatter_dist

	var landed_on = UnitQuery.nearest(
		UnitQuery.where(UnitQuery.within(UnitQuery.alive(), center, 0.75),
			func(u): return u != ctx.attacker),
		center)
	MechanicsResolver.execute_infernal_bomb_blast(
		ctx.attacker, landed_on, center, ctx.atk.blast_radius, ctx.atk, false, landed_on != null)

## ÇOKLU SALDIRI ZİNCİRİ sonrası aksiyon-sonu kuralları.
##
## KURAL BOŞLUĞU DÜZELTMESİ (2026-07-29 compendium denetimi): zincir dalları eskiden doğrudan
## `check_activation_complete()` deyip DÖNÜYORDU, yani `_finish()` HİÇ çalışmıyordu. Sonuçları:
##
##  1. RELOAD hiç tetiklenmiyordu. `machine_gun.tres` hem `automatic` hem `reload` taşır;
##     keyword.md: "If a model makes an attack with a Weapon that has this Keyword then its
##     Activation ends after the ACTION that allowed the attack is completed." Makineli tüfek
##     ateşledikten sonra aktivasyon BİTMELİ — bitmiyordu.
##  2. Off-Hand saldırısı yapılmıyordu. melee-attacks.md "Multiple Melee Weapons" AÇIKÇA şunu
##     der: "If a model has two Melee Weapons, and one or both of them have the [Cleave]
##     Keyword, pick one of them and make a Melee Attack with it; if it has the [Cleave]
##     Keyword carry out ALL of its attacks one after the other. THEN pick the other Melee
##     Weapon and make a Melee Attack with it using the Off-Hand Modifier." Yani Cleave'li bir
##     silahla vuran çift-silahlı model ikinci silahıyla da vurmalı.
##
## RISKY/Sarsılmış "ıskada aktivasyon biter" kuralı burada UYGULANMAZ: zincir tek bir Success
## Roll değil, kendi içinde birden çok atış yapar (`ctx.total_roll` hiç doldurulmaz) — o kural
## zincirin kendi atış döngüsüne aittir, buradan bakılırsa "0 < 7" sanılıp HER zincir yanlışlıkla
## aktivasyonu bitirirdi.
static func _finish_after_chain(ctx: AttackContext) -> void:
	if ctx.is_melee:
		await _offhand_strike(ctx)
	if _reload_ends_activation(ctx):
		return
	ctx.attacker.check_activation_complete()

## Saldırı sonrası: aktivasyonu bitiren kurallar ve otomatik Off-Hand vuruşu.
static func _finish(ctx: AttackContext) -> void:
	var a = ctx.attacker

	# RISKY: Shaken ordu VEYA [Risky] silah VEYA Maddening Buzzing → ıska aktivasyonu ANINDA
	# bitirir. Karar tek kaynakta (bkz. scripts/rules/risky_rolls.gd).
	if RiskyRolls.apply_failure(a, ctx.total_roll, RiskyRolls.weapon_is_risky(ctx.atk), "Saldırı"):
		return

	await _offhand_strike(ctx)

	if _reload_ends_activation(ctx):
		return

	a.check_activation_complete()

## MULTIPLE MELEE WEAPONS: 2x1H Melee taşıyan model, kullandığı silah bu çiftten biriyse
## diğeriyle otomatik bir Off-Hand saldırısı (-1 Dice) yapar.
##
## ANNIHILATOR (Desecrated Saint) İSTİSNASI: "Off-hand Weapon modifier does not apply to any of
## its Melee Attacks" — her silah kendi TAM Fight action'ıyla vurur, otomatik off-hand eki YOK
## (bkz. unit_actions.can_perform_action'daki tekrar-Fight gevşetmesi).
## İSTEĞE BAĞLI ve HEDEFİ SEÇİLİR (melee-attacks.md): "can use a single Fight Action to make two
## separate Melee Attacks... You can pick the same or a different model as the target for each
## attack." Oyuncuya ikinci saldırının hedefi sorulur; iptal = ikinci saldırı yapılmaz.
static func _offhand_strike(ctx: AttackContext) -> void:
	var a = ctx.attacker
	if not ctx.is_melee:
		return
	if a.unit_data != null and KeywordSystem.has(a.unit_data, &"annihilator"):
		return
	var offhand: Resource = LoadoutResolver.offhand_for(a.unit_data, ctx.atk)
	if offhand == null:
		return
	var target = await UnitAttackChains.choose_target(
		a, UnitAttackChains.melee_candidates(a, offhand), "OFFHAND_PICK", true)
	if target == null:
		GameLogger.log_info("[Multiple Melee Weapons] %s ikinci silahla saldırmadı." % a.display_name, "COMBAT")
		return
	await UnitAttackChains.execute_offhand(a, target, offhand)

## RELOAD (keyword.md): "If a model makes an attack with a Weapon that has this Keyword then its
## Activation ends after the ACTION that allowed the attack is completed." Hit/miss FARK ETMEZ.
## Döner: aktivasyon bitirildi mi?
static func _reload_ends_activation(ctx: AttackContext) -> bool:
	if not KeywordSystem.has(ctx.atk, &"reload"):
		return false
	GameLogger.log_info("[Reload] %s: silah yeniden doldurulmalı — aktivasyon sona eriyor." \
		% ctx.attacker.display_name, "COMBAT")
	TurnManager.end_unit_activation(ctx.attacker)
	return true
