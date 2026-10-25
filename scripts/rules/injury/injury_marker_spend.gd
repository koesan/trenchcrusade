## YARA ZARI — İŞARET HARCAMA ADIMI (Kan / Enfeksiyon / Nimet)
##
## Bu bir "tetikleyici" DEĞİLDİR: koşullu bir özel kural değil, her Yara Zarında çalışan ÇEKİRDEK
## akıştır. Yine de kendi modülünde durur, çünkü üçü de OYUNCU KARARI içerir (`CombatChoice` ile
## await edilen istemler) ve birlikte ~60 satır tutar.
##
## COMPENDIUM:
##   • Kan İşareti — SALDIRAN harcar. Her biri +1 Injury Dice; ya da eşik kadar (6, hedef Down
##     ise 3) harcayarak Injury Roll'u BLOODBATH'a çevirir (3D6; silah DEADLY ise 4D6).
##   • Enfeksiyon İşareti — "can be used to modify dice rolls EXACTLY LIKE Blood Markers (i.e.
##     Action rolls and injury rolls and used in Bloodbaths)". Kan ile AYNI oyuncu-seçimli akış.
##   • Nimet İşareti — SAVUNAN harcar; her biri -1 INJURY DICE (flat modifier DEĞİL).
class_name InjuryMarkerSpend

## Üç harcama akışını sırayla yürütür ve `ctx.dice_mod` / `ctx.is_bloodbath` / `ctx.keep_count`
## alanlarını günceller.
##
## `forced_keep_count > 0` ise (ör. Martyrdom Device'ın kendi 4D6'sı) Kan/Enfeksiyon akışları
## ATLANIR — zar sayısı zaten dışarıdan dayatılmıştır. Nimet (savunan) harcaması yine sorulur.
static func run(ctx: InjuryContext) -> void:
	var blood_spend: int = 0
	var infection_spend: int = 0

	if ctx.forced_keep_count <= 0:
		blood_spend = await _spend_blood(ctx)
		infection_spend = await _spend_infection(ctx)

	ctx.keep_count = ctx.forced_keep_count if ctx.forced_keep_count > 0 \
		else DicePoolBuilder.compute_injury_keep_count(ctx.atk, ctx.is_bloodbath)

	# `compute_injury_modifier` Kan/Enfeksiyon'u OTOMATİK EKLEMEZ (2026-07-16 düzeltmesi);
	# ikisi de burada, oyuncu seçimiyle eklenir.
	ctx.dice_mod += blood_spend + infection_spend

	await _spend_blessing(ctx)

## KAN İŞARETİ — saldıran oyuncu seçimi. Döner: +Injury Dice olarak harcanan miktar.
static func _spend_blood(ctx: InjuryContext) -> int:
	var t = ctx.target
	if t.blood_markers <= 0:
		return 0

	var bb_cost: int = DicePoolBuilder.bloodbath_threshold(t, ctx.attacker)

	# CONCENTRATED ATTACK (New Antioch Fireteam): "if a model from a Fireteam hits a target that
	# had been hit by an attack made by the other member of their Fireteam earlier in the same
	# joint Activation, spend 3 Blood Markers to convert to Bloodbath, EVEN IF THE TARGET IS NOT
	# DOWN." Normalde Down değilse maliyet 6'dır; şart sağlanırsa 3'e sabitlenir.
	# YALNIZ [New Antioch] modellerine açıktır — compendium mercenary'leri faksiyon özel
	# kurallarından AÇIKÇA muaf tutar (denetim bulgusu P0-NA-4).
	var a = ctx.attacker
	# "joint Activation" şartı: eş bu round ORTAK aktive edildiyse (joint_partner) geçerli.
	if not t.is_down and a != null and is_instance_valid(a.fireteam_partner) \
			and a.get("joint_partner") == a.fireteam_partner \
			and FactionRules.can_use_concentrated_attack(a.unit_data) \
			and a.fireteam_partner.fireteam_hit_targets_this_activation.has(t):
		bb_cost = 3

	var choice: Dictionary = await CombatChoice.request_blood_spend(a, t, t.blood_markers, bb_cost)
	if choice.get("bloodbath", false) and t.blood_markers >= bb_cost:
		ctx.is_bloodbath = true
		t.blood_markers = max(0, t.blood_markers - bb_cost)
		GameLogger.log_warn("[Bloodbath Roll] %s: %d Kan İşareti harcandı!" \
			% [t.display_name, bb_cost], "COMBAT")
		return 0

	var spend: int = clampi(choice.get("spend", 0), 0, t.blood_markers)
	t.blood_markers -= spend
	if spend > 0:
		GameLogger.log_info("[Blood] Saldıran %d Kan İşareti harcadı: +%d Injury Dice" \
			% [spend, spend], "COMBAT")
	return spend

## ENFEKSİYON İŞARETİ — Kan ile AYNI akış. Kan zaten Bloodbath'i tetiklediyse Enfeksiyon'a
## Bloodbath TEKRAR SORULMAZ (eşik 0 geçilir → buton hiç çıkmaz, yalnız +Dice harcaması sorulur).
static func _spend_infection(ctx: InjuryContext) -> int:
	var t = ctx.target
	if t.infection_markers <= 0:
		return 0

	var bb_cost: int = 0 if ctx.is_bloodbath \
		else DicePoolBuilder.bloodbath_threshold(t, ctx.attacker)
	var choice: Dictionary = await CombatChoice.request_infection_spend(
		ctx.attacker, t, t.infection_markers, bb_cost)

	if choice.get("bloodbath", false) and not ctx.is_bloodbath and t.infection_markers >= bb_cost:
		ctx.is_bloodbath = true
		t.infection_markers = max(0, t.infection_markers - bb_cost)
		GameLogger.log_warn("[Bloodbath Roll] %s: %d Enfeksiyon İşareti harcandı!" \
			% [t.display_name, bb_cost], "COMBAT")
		return 0

	var spend: int = clampi(choice.get("spend", 0), 0, t.infection_markers)
	t.infection_markers -= spend
	if spend > 0:
		GameLogger.log_info("[Infection] Saldıran %d Enfeksiyon İşareti harcadı: +%d Injury Dice" \
			% [spend, spend], "COMBAT")
	return spend

## NİMET İŞARETİ — SAVUNAN oyuncu seçimi; her biri -1 Injury DICE.
static func _spend_blessing(ctx: InjuryContext) -> void:
	var t = ctx.target
	if t.blessing_markers <= 0:
		return
	var spend: int = await CombatChoice.request_blessing_spend(t, t.blessing_markers)
	spend = clampi(spend, 0, t.blessing_markers)
	if spend <= 0:
		return
	t.blessing_markers -= spend
	ctx.dice_mod -= spend
	GameLogger.log_info("%s %d Nimet İşareti harcadı: -%d Injury Dice" \
		% [t.display_name, spend, spend], "COMBAT")
