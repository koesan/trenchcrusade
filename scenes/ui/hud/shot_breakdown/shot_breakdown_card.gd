extends PanelContainer

## Atış Breakdown Kartı. Oyuncu saldırıdan ÖNCE (attack eylemi seçili + düşman üzerine gelince)
## saldırıyı etkileyen tüm +/- DICE modifikatörlerini, menzil ve görüş hattı (LoS) durumunu ve
## isabet olasılığını görür. Tüm metinler localization'dan; görsel tema .tres ile.

@onready var title: Label = $Margin/VBox/Title
@onready var status: RichTextLabel = $Margin/VBox/Status
@onready var mods: VBoxContainer = $Margin/VBox/Mods
@onready var footer: Label = $Margin/VBox/Footer

func _ready():
	visible = false
	# Bu kart yalnız BİLGİ gösterir (isabet olasılığı dökümü) — altındaki birime/butona
	# tıklamayı ENGELLEMEMELİ. `PanelContainer`/`MarginContainer`/`VBoxContainer` varsayılan
	# olarak fare olaylarını YAKALAR ve `mouse_filter` Godot'ta miras alınmaz; ağacın tamamı
	# şeffaflaştırılır (bkz. UIPlacement.make_click_through).
	UIPlacement.make_click_through(self)

## Tema durum rengiyle BBCode açılış etiketi (eskiden sabit hex'ler — eski paletten kalmıştı).
static func _tag(color_name: String) -> String:
	return "[color=#%s]" % GothicThemeHelper.color(color_name).to_html(false)

func hide_card() -> void:
	visible = false

## attacker'ın seçili silahıyla target'a karşı breakdown'ı gösterir.
func show_for(attacker, target) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target) or attacker.unit_data == null:
		hide_card()
		return
	var atk = attacker._get_selected_attack()
	if atk == null:
		hide_card()
		return

	var is_melee: bool = atk.attack_type == "MELEE"
	var dist: float = attacker.global_position.distance_to(target.global_position)
	var diving: bool = is_melee and attacker.diving_charge_bonus_pending
	var ctx: Dictionary = DicePoolBuilder.build_attack_context(attacker, atk, target, dist, diving)
	var entries: Array = DicePoolBuilder.compute_success_breakdown(ctx)
	var total: int = 0
	for e in entries:
		total += e["value"]

	title.text = "%s  →  %s" % [LocalizationManager.tr_t(atk.attack_name), target.display_name]

	# ── Menzil + LoS durumu ──
	var parts: Array = []
	var in_range: bool = dist <= atk.attack_range + GameState.ATTACK_RANGE_TOLERANCE
	if is_melee:
		if in_range:
			parts.append(_tag("color_status_good") + "%s[/color]" % LocalizationManager.tr_t("MELEE_IN_RANGE"))
		else:
			parts.append(_tag("color_status_danger") + "%s[/color]" % LocalizationManager.tr_t("OUT_OF_RANGE"))
	else:
		var half: float = atk.attack_range / 2.0
		var rng_word: String = LocalizationManager.tr_t("RANGE_SHORT") if dist <= half else LocalizationManager.tr_t("RANGE_LONG")
		if in_range:
			parts.append(_tag("color_status_good") + "%s %.1f/%d (%s)[/color]" % [LocalizationManager.tr_t("RANGE_LABEL"), dist, int(atk.attack_range), rng_word])
		else:
			parts.append(_tag("color_status_danger") + "%s (%.1f/%d)[/color]" % [LocalizationManager.tr_t("OUT_OF_RANGE"), dist, int(atk.attack_range)])
		var los: Dictionary = attacker.get_line_of_sight_status(target)
		if los.is_blocked:
			parts.append(_tag("color_status_danger") + "%s[/color]" % LocalizationManager.tr_t("LOS_BLOCKED"))
		elif los.in_cover:
			parts.append(_tag("color_status_caution") + "%s[/color]" % LocalizationManager.tr_t("LOS_COVER"))
		else:
			parts.append(_tag("color_status_good") + "%s[/color]" % LocalizationManager.tr_t("LOS_CLEAR"))
	# Ayraç da lokalizasyondan: kodda görünür karakter bırakılmaz (bazı diller farklı ayraç
	# ya da farklı boşluk kullanır).
	status.text = LocalizationManager.tr_t("LIST_SEPARATOR").join(parts)

	# ── Modifikatör listesi ──
	for c in mods.get_children():
		c.queue_free()
	if entries.is_empty():
		var l := Label.new()
		l.theme_type_variation = &"LabelGrayLight"
		l.text = LocalizationManager.tr_t("MOD_NONE")
		mods.add_child(l)
	else:
		for e in entries:
			var l := Label.new()
			l.theme_type_variation = &"LabelParchmentTan" if e["value"] >= 0 else &"LabelGrayLight"
			l.text = "%s   %+d" % [LocalizationManager.tr_t(e["key"]), e["value"]]
			mods.add_child(l)

	# ── Toplam + isabet % ──
	var prob: float = DicePoolBuilder.success_probability(total, 0)
	footer.text = "%s %+d %s    ·    %s %%%d" % [
		LocalizationManager.tr_t("TOTAL_LABEL"), total,
		LocalizationManager.tr_t("DICE_LABEL"),
		LocalizationManager.tr_t("HIT_CHANCE"), int(round(prob * 100.0))]

	# Not: tema+rivet HUD'ın _ready init_ui'siyle bir kez uygulanır; burada tekrar gezilmez.
	visible = true

## Kullanıcı isteği: "yetenek seçince unit üstüne gelen popup'ta da aynı şekilde gerekli bilgiler
## olsun — kaç zar atılacak, karşı tarafı nasıl etkiler net olsun." Attack breakdown'ın tam
## zar-modifikatörü hesaplaması abilities için uygulanamaz (çok çeşitli efekt tipleri), bu yüzden
## bunun yerine yeteneğin kendi (Task 3'te TÜM yeteneklere eklenen) TOOLTIP_SUCCESS açıklaması +
## menzil/hedef bilgisi gösterilir — oyuncu tıklamadan önce ne olacağını okuyabilir.
func show_for_ability(caster, target, ability: AbilityData, ability_label_key: String) -> void:
	if not is_instance_valid(caster) or not is_instance_valid(target):
		hide_card()
		return

	title.text = "%s  →  %s" % [LocalizationManager.tr_t(ability_label_key), target.display_name]

	if ability != null and ability.range_meters > 0.0:
		var dist: float = caster.global_position.distance_to(target.global_position)
		var in_range: bool = dist <= ability.range_meters + GameState.ATTACK_RANGE_TOLERANCE
		if in_range:
			status.text = _tag("color_status_good") + "%s %.1f/%d[/color]" \
				% [LocalizationManager.tr_t("RANGE_LABEL"), dist, int(ability.range_meters)]
		else:
			status.text = _tag("color_status_danger") + "%s (%.1f/%d)[/color]" \
				% [LocalizationManager.tr_t("OUT_OF_RANGE"), dist, int(ability.range_meters)]
	else:
		status.text = ""

	for c in mods.get_children():
		c.queue_free()
	var success_key: String = ability_label_key + "_TOOLTIP_SUCCESS"
	var l := Label.new()
	l.theme_type_variation = &"LabelParchmentTan"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.text = LocalizationManager.tr_t(success_key) if LocalizationManager.has_key(success_key) \
		else LocalizationManager.tr_t("FALLBACK_ACTION_SUCCESS")
	mods.add_child(l)

	footer.text = ""
	visible = true

## Charge hedeflerken gösterilen basitleştirilmiş bilgi: mesafe + olası hücum menzili aralığı
## (Movement – Movement+D6, 12" tavanlı). Gerçek D6 sonucu atılana kadar bilinmediği için kesin
## "isabet %" hesaplanamaz; bunun yerine oyuncu en azından "bu mesafe ulaşılabilir mi" görür.
func show_for_charge(attacker, target) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		hide_card()
		return

	title.text = "%s  →  %s" % [LocalizationManager.tr_t("ACTION_ONSLAUGHT_CHARGE"), target.display_name]

	var dist: float = attacker.global_position.distance_to(target.global_position)
	var max_possible: float = min(attacker.speed + 6.0, 12.0)
	if dist <= max_possible + GameState.CHARGE_REACH_TOLERANCE:
		status.text = _tag("color_status_good") + "%s %.1f  (%.1f–%.1f)[/color]" \
			% [LocalizationManager.tr_t("RANGE_LABEL"), dist, attacker.speed, max_possible]
	else:
		status.text = _tag("color_status_danger") + "%s (%.1f > %.1f)[/color]" \
			% [LocalizationManager.tr_t("OUT_OF_RANGE"), dist, max_possible]

	for c in mods.get_children():
		c.queue_free()
	footer.text = ""
	visible = true
