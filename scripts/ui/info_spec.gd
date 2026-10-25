## HOVER KARTI SÖZLEŞMESİ ÜRETİCİLERİ — oyun verisini `InfoPopup`un anladığı sözlüğe çevirir.
##
## NEDEN AYRI: kart artık TEK bir bileşen (bkz. `scenes/ui/shared/info_popup.gd`), ama gösterdiği
## şeyler çok farklı: sahadaki bir birim, henüz yerleştirilmemiş bir birim künyesi, bir yetenek
## butonunun açıklaması. Bu "veri → bölümler" dönüşümünü kartın İÇİNE koymak onu her yeni içerik
## türünde büyütürdü. Burada saf fonksiyonlar olarak durur: girdi veri, çıktı sözlük, sahne ağacı
## gerektirmez — dolayısıyla headless test edilebilir.
##
## Sözlük biçimi için bkz. `InfoPopup.show_spec`.
class_name InfoSpec

## Sahadaki bir BİRİM için: ad, statlar, işaretçiler, durum rozetleri ve yetenekler.
static func for_unit(unit: Node) -> Dictionary:
	if not is_instance_valid(unit):
		return {}
	var spd: float = unit.speed if "speed" in unit else 0.0
	var mel: int = unit.melee_dice_modifier if "melee_dice_modifier" in unit else 0
	var rng: int = unit.ranged_dice_modifier if "ranged_dice_modifier" in unit else 0
	var arm: int = unit.armour if "armour" in unit else 0

	var blood: int = unit.blood_markers if "blood_markers" in unit else 0
	var blessing: int = unit.blessing_markers if "blessing_markers" in unit else 0
	var infection: int = unit.infection_markers if "infection_markers" in unit else 0
	var inf_str := ""
	if infection > 0:
		inf_str = LocalizationManager.tr_t("LABEL_VEBA") % infection

	var ud = unit.unit_data if "unit_data" in unit else null
	return {
		"title": LocalizationManager.tr_t("LABEL_UNIT") % unit.display_name,
		"subtitle": LocalizationManager.tr_t("LABEL_STATS_FORMAT") % [spd, mel, rng, arm],
		"body": LocalizationManager.tr_t("LABEL_BLOOD_MARKERS") % [blood, blessing, inf_str],
		"badges": _unit_badges(unit),
		"sections": ability_sections(ud.abilities if ud else []),
	}

## Henüz sahada OLMAYAN bir birim (yerleştirme kartı) için: STATİK profil — ad, statlar,
## maliyet ve yetenekler. Runtime durumu (işaret/rozet/Down) burada YOKTUR.
static func for_unit_data(ud: Resource) -> Dictionary:
	if ud == null:
		return {}
	var uname: String = LocalizationManager.tr_t(
		ud.unit_name.to_upper().replace(" ", "_").replace("-", "_"))
	var facts: Array = [{
		"label": LocalizationManager.tr_t("COST_LABEL"),
		"value": "%d %s" % [ud.cost, LocalizationManager.tr_t(EconomyRules.currency_key(ud))],
	}]
	if "is_leader" in ud and ud.is_leader:
		facts.append({"label": LocalizationManager.tr_t("DEPLOY_LEADER_BADGE"),
			"value": LocalizationManager.tr_t("DEPLOY_LEADER_FACT")})
	return {
		"title": LocalizationManager.tr_t("LABEL_UNIT") % uname,
		"subtitle": LocalizationManager.tr_t("LABEL_STATS_FORMAT") % [
			ud.speed, ud.melee_dice_modifier, ud.ranged_dice_modifier, ud.armour],
		"facts": facts,
		"sections": ability_sections(ud.abilities if ud.abilities else []),
	}

## Yetenek listesi → başlıklı paragraflar.
##
## KÖK NEDEN (kullanıcı bildirimi: "popup içindeki metinler düzgün değil"): yetenekler TEK bir
## Label'a `ABILITY_TEXT` ("\nYetenek: %s\n(%s)") ile ARDIŞIK olarak ekleniyordu. Dört yetenekli
## bir birimde sonuç, durum metnine yapışmış, başlıkla açıklaması aynı renk/boyutta, araları
## ayırt edilemeyen bir metin yığınıydı. Artık her yetenek kendi başlık + gövde çiftinde.
static func ability_sections(abilities: Array) -> Array:
	var out: Array = []
	for abil in abilities:
		if abil == null:
			continue
		out.append({
			"heading": LocalizationManager.tr_t(abil.display_name),
			"text": LocalizationManager.tr_t(abil.description),
		})
	return out

## Bir birim YETENEĞİ (aktif ya da pasif) için: ad, kendi açıklaması ve kısa künye rozetleri
## (pasif / riskli / hedef / menzil). Yetenek butonları eskiden genel eylem anahtarlarını
## (`ACTION_X_TOOLTIP_DESC`) arıyordu; yetenekler için bunlar yok, kartta yalnız başlık kalıyordu.
static func for_ability(ab: Resource) -> Dictionary:
	if ab == null:
		return {}
	var badges: Array = []
	var gold: Color = GothicThemeHelper.color("color_gold_bright")
	var warn: Color = GothicThemeHelper.color("color_status_warn")
	var muted: Color = GothicThemeHelper.color("color_dim_text")
	if not AbilityExecutor.is_actionable_ability(ab):
		badges.append({"text": LocalizationManager.tr_t("ABILITY_PASSIVE"), "color": muted})
	else:
		if ab.is_risky:
			badges.append({"text": LocalizationManager.tr_t("ABILITY_RISKY"), "color": warn})
		var tkey := "ABILITY_TARGET_" + String(ab.target_type).to_upper()
		if LocalizationManager.has_key(tkey):
			badges.append({"text": LocalizationManager.tr_t(tkey), "color": gold})
		if ab.range_meters > 0.0:
			badges.append({"text": "%.0f\"" % ab.range_meters, "color": gold})
	return {
		"title": LocalizationManager.tr_t(ab.display_name),
		"body": LocalizationManager.tr_t(ab.description),
		"badges": badges,
	}

## Bir YETENEK/EYLEM BUTONU açıklaması: başlık + açıklama + başarı/başarısızlık satırları.
## Eksik anahtarlar için tür bazlı geri düşüşler kullanılır (silah mı, eylem mi).
static func for_action(key: String) -> Dictionary:
	var is_weapon: bool = key.begins_with("ATTACK_")
	var title: String = LocalizationManager.tr_t(key)
	var desc: String = _tr_or(key + "_TOOLTIP_DESC",
		"FALLBACK_WEAPON_DESC" if is_weapon else "", title)
	var success: String = _tr_or(key + "_TOOLTIP_SUCCESS",
		"FALLBACK_WEAPON_SUCCESS" if is_weapon else "FALLBACK_ACTION_SUCCESS", "")
	var failure: String = _tr_or(key + "_TOOLTIP_FAILURE",
		"FALLBACK_WEAPON_FAILURE" if is_weapon else "FALLBACK_ACTION_FAILURE", "")
	return {
		"title": title,
		"body": desc,
		"sections": [
			{"heading": LocalizationManager.tr_t("TOOLTIP_SUCCESS_HEADING"), "text": success,
			 "color": GothicThemeHelper.color("color_status_good")},
			{"heading": LocalizationManager.tr_t("TOOLTIP_FAILURE_HEADING"), "text": failure,
			 "color": GothicThemeHelper.color("color_status_danger")},
		],
	}

# ─────────────────────────────────────────────────────────────────────────────

## `key` varsa onu, yoksa `fallback_key`i, o da yoksa `literal`i döndürür.
static func _tr_or(key: String, fallback_key: String, literal: String) -> String:
	if LocalizationManager.has_key(key):
		return LocalizationManager.tr_t(key)
	if fallback_key != "" and LocalizationManager.has_key(fallback_key):
		return LocalizationManager.tr_t(fallback_key)
	return literal

## Durum + yapılan aksiyon rozetleri. Renkler `gothic_theme.tres`ten (TEK KAYNAK).
static func _unit_badges(unit: Node) -> Array:
	var gold: Color = GothicThemeHelper.color("color_gold_bright")
	var muted: Color = GothicThemeHelper.color("color_dim_text")
	var red: Color = GothicThemeHelper.color("color_status_danger")
	var orange: Color = GothicThemeHelper.color("color_status_warn")
	var green: Color = GothicThemeHelper.color("color_status_good")

	var out: Array = []
	var state_key := &"STATE_ACTIVE"
	if unit.has_method("get_fighter_state"):
		state_key = unit.get_fighter_state()
	if state_key == &"STATE_DOWN":
		out.append(_badge("BADGE_DOWN", orange))

	var owner_id: int = unit.owner_id if "owner_id" in unit else 1
	if TurnManager.player_shaken_state.get(owner_id, false):
		out.append(_badge("BADGE_SHAKEN", red))

	# Aktif yetenek durumları — kalıcı görünür gösterge (Hide/Fortify/Shadow Walker "başarılı"
	# dendiğinde artık bilgi kartında da görülür).
	if ("is_hidden" in unit) and unit.is_hidden:
		out.append(_badge("BADGE_HIDDEN", muted))
	if ("has_fortify_cover" in unit) and unit.has_fortify_cover:
		out.append(_badge("BADGE_FORTIFIED", gold))
	# ARAZİ KAYNAKLI [Cover]: birim bir siperin içindeyse de −1 Dice yer. Rozet, DicePoolBuilder
	# ile AYNI kaynağı (TerrainManager) okur — oyuncu neden ceza aldığını karttan görebilsin.
	# Fortify rozeti zaten varsa tekrar gösterilmez (aynı etkinin iki kez yazılması kafa karıştırır).
	elif ("global_position" in unit) and TerrainManager.has_keyword_at(unit.global_position, &"cover"):
		out.append(_badge("BADGE_IN_COVER", gold))
	if ("shadow_walker_active" in unit) and unit.shadow_walker_active:
		out.append(_badge("BADGE_SHADOW", green))
	if ("is_bounty_target" in unit) and unit.is_bounty_target:
		out.append(_badge("BADGE_BOUNTY_TARGET", red))

	var actions: Array = unit.actions_taken if "actions_taken" in unit else []
	for act in actions:
		match act:
			"move": out.append(_badge("BADGE_MOVED", muted))
			"dash": out.append(_badge("BADGE_DASHED", muted))
			"charge": out.append(_badge("BADGE_CHARGED", gold))
			"retreat": out.append(_badge("BADGE_RETREATED", muted))
			"shoot": out.append(_badge("BADGE_SHOT", gold))
			"melee": out.append(_badge("BADGE_FOUGHT", gold))

	var has_moved: bool = unit.has_moved if "has_moved" in unit else false
	if not has_moved and actions.is_empty() and state_key != &"STATE_DOWN":
		out.append(_badge("BADGE_READY", green))
	return out

## Rozet metni TAMAMEN lokalizasyondan gelir — ikon dâhil (ör. "▼ Yere Serili").
## Kodda tek bir görünür karakter bile bırakılmaz; çevirmen dizgenin tamamını denetler.
static func _badge(key: String, col: Color) -> Dictionary:
	return {"text": LocalizationManager.tr_t(key), "color": col}
