## SUCCESS ROLL İŞARET HARCAMASI — Blood / Infection / Blessing tek yerde.
##
## COMPENDIUM
##   `core-rules/blood-markers.md`: "your opponent can declare that they are spending one or more
##   of them, REMOVING the model's [Blood Marker]s as they are spent. For each [Blood Marker]
##   that is spent, add [-1 Dice] to the Success Roll."
##
##   `core-rules/blessing-markers.md`: modelin SAHİBİ kendi Blessing Marker'larını harcayıp
##   Success Roll'a +1 Dice ekler.
##
##   `comprehensive-rules/keyword.md` (INFECTION MARKER): "INFECTION MARKERS can be used to
##   modify dice rolls **exactly like Blood Markers** (i.e. Action rolls and injury rolls and
##   used in Bloodbaths)."
##
## ⚠ KURAL SAPMASI DÜZELTMESİ (compendium denetimi, Adım 3): Infection Marker'ın Success Roll
## tarafı `DicePoolBuilder` içinde OTOMATİK ve KOŞULSUZ bir `-Dice` kalemiydi; ne rakibe seçim
## soruluyor ne de işaretler TÜKETİLİYORDU. Sonuç: 6 Veba İşaretli bir model SONSUZA KADAR her
## Success Roll'unda -6 Dice yiyordu. RAW'da rakip bunları bir kez harcar ve işaretler biter —
## yani sınırlı bir kaynak yönetimi kararıdır. (Injury Roll tarafı zaten doğruydu.)
##
## NEDEN AYRI MODÜL: üç işaretin akışı birebir aynı (sor → sınırla → düş → modifikatör → logla)
## ve `unit.gd` mimari tavanındaydı; kural burada tek bir yerde ve tek bir desende durur.
class_name MarkerSpend

## Üç işaret türü için de harcamayı sorar, işaretleri DÜŞER ve nihai dice modifikatörünü döndürür.
##
## `allow_hostile_spend`: rakibin harcayabileceği işaretler (Blood/Infection) devre dışı mı?
## ABSOLUTE FAITH (Sniper Priest) gibi hedef-özel istisnalar `false` geçer. Modelin KENDİ
## Blessing harcaması bundan etkilenmez.
##
## Döner: { "modifier": int, "spent": bool }
static func apply_to_success_roll(unit, dice_modifier: int, allow_hostile_spend: bool = true) -> Dictionary:
	var mod: int = dice_modifier
	var spent_any: bool = false

	if unit.blood_markers > 0 and allow_hostile_spend:
		var n: int = await CombatChoice.request_blood_spend_on_success(unit, unit.blood_markers)
		n = clampi(n, 0, unit.blood_markers)
		if n > 0:
			unit.blood_markers -= n
			mod = DicePoolBuilder.apply_success_marker_spend(mod, n, 0)
			spent_any = true
			GameLogger.log_info("[Blood] Rakip %s'in Success Roll'una %d Kan İşareti harcadı: -%d Dice" \
				% [unit.display_name, n, n], "COMBAT")

	# [Negate Gas] taşıyan model Veba İşaretinin etkisinden muaftır.
	var neg_gas: bool = unit.unit_data != null and KeywordSystem.negates(unit.unit_data, &"gas")
	if unit.infection_markers > 0 and allow_hostile_spend and not neg_gas:
		var n2: int = await CombatChoice.request_infection_spend_on_success(unit, unit.infection_markers)
		n2 = clampi(n2, 0, unit.infection_markers)
		if n2 > 0:
			unit.infection_markers -= n2
			mod = DicePoolBuilder.apply_success_marker_spend(mod, n2, 0)
			spent_any = true
			GameLogger.log_info("[Infection] Rakip %s'in Success Roll'una %d Veba İşareti harcadı: -%d Dice" \
				% [unit.display_name, n2, n2], "COMBAT")

	if unit.blessing_markers > 0:
		var n3: int = await CombatChoice.request_blessing_spend_on_success(unit, unit.blessing_markers)
		n3 = clampi(n3, 0, unit.blessing_markers)
		if n3 > 0:
			unit.blessing_markers -= n3
			mod = DicePoolBuilder.apply_success_marker_spend(mod, 0, n3)
			spent_any = true
			GameLogger.log_info("[Blessing] %s kendi Success Roll'una %d Nimet İşareti harcadı: +%d Dice" \
				% [unit.display_name, n3, n3], "COMBAT")

	return {"modifier": mod, "spent": spent_any}
