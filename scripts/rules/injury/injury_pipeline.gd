## YARA ZARI (INJURY ROLL) BORU HATTI — çözümlemenin TEK sahibi.
##
## `unit.gd::resolve_injury_roll` 306 satırlık bir dev fonksiyondu ve gövdesinin çoğu ardışık,
## birbirinden bağımsız özel kural bloğuydu. Artık burası yalnız SIRAYI tutar; her adımın gövdesi
## kendi modülünde:
##
##   1. Saldırı verisi + Special Ammunition seçimi     → `_resolve_attack_data()`
##   2. Havuz bağlamı + Fireteam isabet kaydı          → `DicePoolBuilder` / `_record_fireteam_hit()`
##   3. İşaret harcamaları (Kan/Enfeksiyon/Nimet)      → `InjuryMarkerSpend`
##   4. PRE_ROLL tetikleyicileri                       → `InjuryTriggers.PRE_ROLL`
##   5. Zar                                            → `attacker.perform_trench_roll()`
##   6. Yara tablosu + POST_TABLE tetikleyicileri      → `InjuryResolver` / `POST_TABLE`
##   7. Sonucu uygula                                  → `InjuryResolver.apply_outcome()`
##   8. POST_OUTCOME tetikleyicileri                   → `POST_OUTCOME`
##   9. Aktivasyon bitişi kontrolü                     → `InjuryResolver.maybe_end_activation()`
##  10. AFTER_EFFECTS tetikleyicileri                  → `AFTER_EFFECTS`
##  11. Ağ senkronizasyonu                             → `CombatResolver.sync_target_health()`
##
## YENİ ÖZEL KURAL EKLEME: bu dosyaya DOKUNMA — `injury/triggers/` altına 1 dosya yaz,
## `InjuryTriggers`in uygun fazına 1 satır ekle.
class_name InjuryPipeline

## Compendium (injuries.md): "The maximum -INJURY MODIFIER cannot be more than -3 in total."
const INJURY_MODIFIER_FLOOR := -3

## Tek giriş noktası. `unit.gd::resolve_injury_roll` buraya delege eder.
static func resolve(ctx: InjuryContext) -> void:
	if not _resolve_attack_data(ctx):
		return
	await _apply_special_ammunition(ctx)

	# ── 1. INJURY DICE HAVUZU ────────────────────────────────────────────
	# Diving Charge bonusu YALNIZ melee Success Roll'una etkir (injury'ye DEĞİL — compendium),
	# bu yüzden havuz bağlamına `false` geçilir.
	ctx.pool_ctx = DicePoolBuilder.build_injury_context(
		ctx.attacker, ctx.atk, ctx.target, ctx.critical_hit, ctx.is_melee, false,
		ctx.deed_is_long_range)
	ctx.dice_mod = DicePoolBuilder.compute_injury_modifier(ctx.pool_ctx) + ctx.dice_mod
	ctx.flat_mod = DicePoolBuilder.compute_injury_flat(ctx.pool_ctx) + ctx.flat_mod

	_record_fireteam_hit(ctx)

	# ── 2. İŞARET HARCAMALARI (oyuncu kararları) ─────────────────────────
	await InjuryMarkerSpend.run(ctx)

	# ── 3. ZAR ÖNCESİ TETİKLEYİCİLER ─────────────────────────────────────
	await InjuryTriggers.run_phase(InjuryTriggers.PRE_ROLL, ctx)

	# ── INJURY MODIFIER TABANI ───────────────────────────────────────────
	# Compendium (injuries.md, İKİ AYRI YERDE vurgulanır): "The maximum -INJURY MODIFIER cannot
	# be more than -3 in total." Tavan TOPLAMA uygulanır, tek tek kaynaklara değil.
	#
	# KURAL SAPMASI DÜZELTMESİ (2026-07-29 compendium denetimi): `-3` sınırı yalnız
	# `DicePoolBuilder.compute_injury_flat()` İÇİNDE vardı — yani zırh + model/silah Injury
	# Modifier'ları için. Dışarıdan gelen kaynaklar tavanı AŞABİLİYORDU:
	#   • `extra_flat_mod` (Vengeful Scripture)
	#   • Blessings of the Serpent Moon (PRE_ROLL tetikleyicisi, -1 … -3 arası)
	# Zırhı 3 olan bir modele Serpent Moon eklenince toplam -6'ya kadar inebiliyor, yani hedef
	# RAW'ın izin verdiğinden çok daha korunaklı oluyordu. Artık tavan SON değere uygulanır.
	# NOT: POZİTİF tarafta tavan YOKTUR — compendium yalnız eksi yönü sınırlar.
	ctx.flat_mod = maxi(ctx.flat_mod, INJURY_MODIFIER_FLOOR)

	# ── 4. ZARI AT ───────────────────────────────────────────────────────
	var roll_res: Array = await ctx.attacker.perform_trench_roll(
		ctx.dice_mod, ctx.flat_mod, "injury", ctx.keep_count)
	ctx.total = roll_res[0]
	GameLogger.log_info("Injury Roll: %s → %s | Sonuç: %d (Zar: %+d, Flat: %+d, %dD6)" \
		% [ctx.attacker.display_name, ctx.target.display_name, ctx.total,
			ctx.dice_mod, ctx.flat_mod, ctx.keep_count], "COMBAT")

	# ── 5. YARA TABLOSU ──────────────────────────────────────────────────
	ctx.raw_outcome = InjuryResolver.resolve_table(ctx.total)
	await InjuryTriggers.run_phase(InjuryTriggers.POST_TABLE, ctx)

	# ── 6. SONUCU UYGULA ─────────────────────────────────────────────────
	ctx.blood_before_outcome = ctx.target.blood_markers
	ctx.infection_before_outcome = ctx.target.infection_markers
	ctx.final_outcome = InjuryResolver.apply_outcome(
		ctx.raw_outcome, ctx.target, ctx.atk, ctx.is_bloodbath, _attack_element(ctx))
	# [Infection Markers] silahları da `apply_outcome` içinde işaret bastığı için HER İKİ havuz
	# da karşılaştırılır (P0-8).
	ctx.marker_placed_this_attack = ctx.target.blood_markers > ctx.blood_before_outcome \
		or ctx.target.infection_markers > ctx.infection_before_outcome
	BattleEvents.injury(ctx.target, ctx.final_outcome,
		(ctx.target.blood_markers - ctx.blood_before_outcome)
		+ (ctx.target.infection_markers - ctx.infection_before_outcome))

	await InjuryTriggers.run_phase(InjuryTriggers.POST_OUTCOME, ctx)
	if not is_instance_valid(ctx.target):
		return

	# ── 7. AKTİVASYON BİTİŞİ ─────────────────────────────────────────────
	InjuryResolver.maybe_end_activation(ctx.final_outcome, ctx.target)

	# CLEAVE burada DEĞİL — bkz. `unit.gd::server_request_attack_action` (P1-30, 2026-07-16):
	# RAW'da Cleave bir OOA-kill sonucu değil, Fight Action'ın kendisinin ürettiği X ayrı saldırı.

	await InjuryTriggers.run_phase(InjuryTriggers.AFTER_EFFECTS, ctx)
	if not is_instance_valid(ctx.target):
		return

	# ── 8. AĞ SENKRONİZASYONU ────────────────────────────────────────────
	CombatResolver.sync_target_health(ctx.target, true)

# ─────────────────────────────────────────────────────────────────────────────
#  ADIMLAR
# ─────────────────────────────────────────────────────────────────────────────

## Kullanılacak AttackData'yı belirler. Döner: devam edilebilir mi?
static func _resolve_attack_data(ctx: InjuryContext) -> bool:
	if ctx.atk == null and ctx.attacker != null:
		ctx.atk = ctx.attacker._get_selected_attack()
	if ctx.atk == null:
		GameLogger.log_warn("Saldırı verisi bulunamadı, yara zarı atlanıyor.", "COMBAT")
		return false
	return true

## SPECIAL AMMUNITION (Bow of Lethe, Hunter of the Left Hand Path)
## RAW: "Before making an Injury Roll for an attack made with a Bow of Lethe, you must choose if
## the roll will have the +2 Injury Dice Keyword or the Ignore Armour Keyword."
##
## `atk` PAYLAŞILAN bir .tres olabilir — mutasyondan önce MUTLAKA `duplicate()`
## (bkz. attack_data.gd'nin "paylaşılanı mutasyona uğratma" uyarısı).
static func _apply_special_ammunition(ctx: InjuryContext) -> void:
	if not KeywordSystem.has(ctx.atk, &"special_ammunition"):
		return
	var want_dice: bool = await CombatChoice.request_special_ammunition_choice(
		ctx.attacker, ctx.target.display_name)
	ctx.atk = ctx.atk.duplicate()
	if want_dice:
		ctx.dice_mod += 2
		GameLogger.log_info("[Special Ammunition] %s: +2 Injury Dice seçildi." \
			% ctx.attacker.display_name, "COMBAT")
	else:
		ctx.atk.ignore_armour = true
		GameLogger.log_info("[Special Ammunition] %s: Ignore Armour seçildi." \
			% ctx.attacker.display_name, "COMBAT")

## FIRETEAM / CONCENTRATED ATTACK (New Antioch): bu isabeti saldıranın listesine kaydeder —
## partner daha sonra AYNI hedefe vurursa indirimli Bloodbath eşiğini kullanabilir.
static func _record_fireteam_hit(ctx: InjuryContext) -> void:
	var a = ctx.attacker
	if a == null or not is_instance_valid(a.fireteam_partner):
		return
	if not a.fireteam_hit_targets_this_activation.has(ctx.target):
		a.fireteam_hit_targets_this_activation.append(ctx.target)

## Saldırının ELEMENT'i — `apply_outcome`un FIRE/GAS/SHRAPNEL ekstra-marker mekanizmasını besler.
##   • ELEMENTAL CHANGE (Jabirean Alchemist): saldıranın dinamik silah elementi.
##   • CARTRIDGE OF HIS WRATH (Ammunition Sacrament): Ranged saldırı Shrapnel kazanır — element
##     zaten atanmışsa ona DOKUNMAZ (aynı yolu paylaşırlar).
static func _attack_element(ctx: InjuryContext) -> StringName:
	var a = ctx.attacker
	var element: StringName = a.current_element if "current_element" in a else &""
	if element == &"" and not ctx.is_melee \
			and "temp_cartridge_of_wrath" in a and a.temp_cartridge_of_wrath:
		element = &"shrapnel"
	return element
