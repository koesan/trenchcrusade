## InjuryResolver — Trench Crusade Yara Tablosu ve Sonuç Çözümleyici
##
## Bu sınıf STATELESS'tır: hesap yapar ve standart sonuç döndürür.
## unit.gd içindeki resolve_injury_roll() artık bu sınıfı kullanır.
##
## Yara Tablosu (kural kitabı Bölüm 3):
##   ≤ 1    → NO_EFFECT  (Etkisiz)
##   2–6    → SCRATCH    (+1 Blood Marker)
##   7–8    → DOWN       (+1 Blood Marker, yere serilir; zaten Down ise +2)
##   9+     → OUT_OF_ACTION
class_name InjuryResolver

# ─────────────────────────────────────────────────────────────────────────────
# SONUÇ ENUM — Yara tablosu çıktısı
# ─────────────────────────────────────────────────────────────────────────────
enum Outcome {
	NO_EFFECT,
	SCRATCH,
	DOWN,
	DOWN_ON_DOWN,   ## Zaten Down olan birim tekrar Down aldı (+2 Blood Marker)
	OUT_OF_ACTION,
	NEGATED_MEMENTO_MORI,   ## War Prophet Memento Mori devreye girdi
	NEGATED_TOUGH,          ## TOUGH keyword devreye girdi (OOA → Down)
	NEGATED_GOLEM,          ## GOLEM keyword devreye girdi (OOA → Down, Bloodbath hariç)
	NEGATED_BROKEN_ON_WHEEL,  ## Anchorite Shrine'ın Broken on the Wheel'i devreye girdi (OOA → No Effect, TEK KEZ)
}

# ─────────────────────────────────────────────────────────────────────────────
# YARA TABLOSU
# ─────────────────────────────────────────────────────────────────────────────

## Ham zar toplamından temel sonuç tipini döndürür.
## Tough / Memento Mori burada uygulanmaz — apply_outcome() bunu yapar.
static func resolve_table(total: int) -> Outcome:
	if total <= 1:
		return Outcome.NO_EFFECT
	elif total <= 6:
		return Outcome.SCRATCH
	elif total <= 8:
		return Outcome.DOWN
	else:
		return Outcome.OUT_OF_ACTION

# ─────────────────────────────────────────────────────────────────────────────
# SONUÇ UYGULAMA — Target birim üzerinde yara etkisini uygular
# ─────────────────────────────────────────────────────────────────────────────

## Yara tablosu sonucunu hedef birim üzerinde uygular.
## attack_data: FIRE/GAS(POISON) silahlarla, kural kitabına göre No Effect dahil
## her sonuca +1 ekstra Blood Marker uygulanır (SHRAPNEL henüz veride tanımlı değil).
## Döndürür: uygulanan nihai Outcome
static func apply_outcome(raw: Outcome, target, attack_data: Resource = null, is_bloodbath: bool = false, attacker_element: StringName = &"") -> Outcome:
	# P0-8: [Infection Markers] keyword'lü silahlar, Blood Marker YERİNE Infection Marker basar
	# (cult-of-the-black-grail.md: "cause Infection Markers (instead of Blood Markers) to be
	# placed next to the target" — Herald of Beelzebub'un Infected Proboscis'i gibi). Bu silahın
	# yerleştireceği HER marker (temel sonuç + FIRE/GAS/SHRAPNEL/Found Guilty ekstra) bu havuza gider.
	var places_infection: bool = attack_data != null and KeywordSystem.has(attack_data, &"infection_markers")

	# FIRE / GAS(POISON) / SHRAPNEL: kural kitabına göre No Effect dahil her sonuca +1 ekstra
	# Blood Marker. İlgili NEGATE keyword'ü (Negate Fire — DEMONIC dahil, Negate Gas — GOLEM
	# dahil, Negate Shrapnel) etkiyi iptal eder. attacker_element: Elemental Change ile saldıranın
	# silahına atanan dinamik element (Fire/Gas/Shrapnel) — aynı kurala tabidir (silah keyword'ü
	# gibi davranır, paylaşılan AttackData mutasyona uğratılmaz).
	var extra_marker: int = 0
	if target.unit_data != null:
		var neg_fire: bool = KeywordSystem.negates(target.unit_data, &"fire")
		var neg_gas: bool = KeywordSystem.negates(target.unit_data, &"gas")
		var neg_shrap: bool = KeywordSystem.negates(target.unit_data, &"shrapnel")
		var causes_marker: bool = false
		if attack_data != null:
			causes_marker = (attack_data.is_fire and not neg_fire) \
				or (attack_data.is_poison and not neg_gas) \
				or (KeywordSystem.has(attack_data, &"shrapnel") and not neg_shrap)
		# ELEMENTAL CHANGE dinamik elementi
		if not causes_marker and attacker_element != &"":
			causes_marker = (attacker_element == &"fire" and not neg_fire) \
				or (attacker_element == &"gas" and not neg_gas) \
				or (attacker_element == &"shrapnel" and not neg_shrap)
		if causes_marker:
			extra_marker = 1

		# FOUND GUILTY (Gavel of Justice): Injury Roll sonrası +1 (hedef Black Grail/
		# Demonic/Heretic ise +2) Blood Marker — No Effect dahil.
		if attack_data != null and KeywordSystem.has(attack_data, &"found_guilty"):
			extra_marker += 2 if KeywordSystem.is_unholy(target.unit_data) else 1

	match raw:
		Outcome.NO_EFFECT:
			GameLogger.log_info("[Injury] %s: Etkisiz (No Effect)!" % target.display_name, "COMBAT")
			if extra_marker > 0:
				_place_marker(target, extra_marker, places_infection)
				GameLogger.log_info("[Injury] FIRE/GAS: Etkisiz sonuca rağmen +%d %s → Toplam: %d" \
					% [extra_marker, "Enfeksiyon İşareti" if places_infection else "Kan İşareti",
					target.infection_markers if places_infection else target.blood_markers], "COMBAT")
			return Outcome.NO_EFFECT

		Outcome.SCRATCH:
			_place_marker(target, 1 + extra_marker, places_infection)
			GameLogger.log_info("[Injury] %s: Sıyrık (Scratch)! +%d %s → Toplam: %d" \
				% [target.display_name, 1 + extra_marker, "Enfeksiyon İşareti" if places_infection else "Kan İşareti",
				target.infection_markers if places_infection else target.blood_markers], "COMBAT")
			return Outcome.SCRATCH

		Outcome.DOWN:
			if target.is_down:
				# Zaten Down olan birim tekrar Down aldı: +2 marker (kural kitabı)
				_place_marker(target, 2 + extra_marker, places_infection)
				GameLogger.log_info("[Injury] %s: Down üstüne Down! +%d %s → Toplam: %d" \
					% [target.display_name, 2 + extra_marker, "Enfeksiyon İşareti" if places_infection else "Kan İşareti",
					target.infection_markers if places_infection else target.blood_markers], "COMBAT")
				return Outcome.DOWN_ON_DOWN
			# STEADFAST (Mechanized Heavy Infantry'nin Machine Armour'ı) / BROKEN ON THE WHEEL
			# (Anchorite Shrine, aktif fazda — P1-1): ikisi de "Down sonucu Minor Hit/Scratch sayılır".
			elif (target.unit_data != null and KeywordSystem.has(target.unit_data, &"steadfast")) \
					or ("broken_on_wheel_active" in target and target.broken_on_wheel_active):
				_place_marker(target, 1 + extra_marker, places_infection)
				GameLogger.log_info("[Steadfast] %s: Down yerine Sıyrık! +%d %s → Toplam: %d" \
					% [target.display_name, 1 + extra_marker, "Enfeksiyon İşareti" if places_infection else "Kan İşareti",
					target.infection_markers if places_infection else target.blood_markers], "COMBAT")
				return Outcome.SCRATCH
			else:
				_place_marker(target, 1 + extra_marker, places_infection)
				target.is_down = true
				GameLogger.log_info("[Injury] %s: Yere Serildi (Down)! +%d %s → Toplam: %d" \
					% [target.display_name, 1 + extra_marker, "Enfeksiyon İşareti" if places_infection else "Kan İşareti",
					target.infection_markers if places_infection else target.blood_markers], "COMBAT")
				return Outcome.DOWN

		Outcome.OUT_OF_ACTION:
			return _resolve_out_of_action(target, is_bloodbath)

		_:
			return raw

## P0-8: Blood/Infection Marker'ı ilgili havuza yerleştirir (6 tavan, KeywordSystem.has kontrolüne
## göre yönlendirilir — bkz. apply_outcome başındaki places_infection).
static func _place_marker(target, amount: int, as_infection: bool) -> void:
	if as_infection:
		target.infection_markers = min(target.infection_markers + amount, 6)
	else:
		target.blood_markers = min(target.blood_markers + amount, 6)

## Out of Action çözümleyici — BROKEN ON THE WHEEL, MEMENTO MORI, TOUGH ve GOLEM'i uygular.
static func _resolve_out_of_action(target, is_bloodbath: bool = false) -> Outcome:
	# BROKEN ON THE WHEEL (Anchorite Shrine, P1-1): aktif fazda İLK Out of Action → Etkisiz
	# (No Effect). Kan İşaretleri silinir, TEK KEZ tükenir; sonrasında normal (armour=3, Tough,
	# Negate Shrapnel) duruma geri döner — bkz. unit.gd::_maybe_consume_broken_on_wheel.
	if "broken_on_wheel_active" in target and target.broken_on_wheel_active:
		target.broken_on_wheel_active = false
		target.blood_markers = 0
		target.armour = 3
		if target.unit_data != null:
			target.unit_data.has_tough = true
			target.unit_data.keywords[&"negate_shrapnel"] = 1
		GameLogger.log_info("[Broken on the Wheel] %s'in kurbanı can verdi — ölümcül yara Etkisiz sayıldı, artık tam zırhlı/Tough/Negate Shrapnel." \
			% target.display_name, "COMBAT")
		return Outcome.NEGATED_BROKEN_ON_WHEEL

	# MEMENTO MORI (War Prophet): İlk Out of Action → Etkisiz
	if target.unit_data and target.unit_data.has_memento_mori and not target.has_memento_mori_used:
		target.has_memento_mori_used = true
		GameLogger.log_info("[Memento Mori] %s ölümcül yaradan Memento Mori sayesinde kurtuldu! (Etkisiz)" % target.display_name, "COMBAT")
		return Outcome.NEGATED_MEMENTO_MORI

	# TOUGH: İlk Out of Action → Down
	if target.unit_data and target.unit_data.has_tough and not target.has_tough_used:
		target.has_tough_used = true
		# "treated as a Down result" → zaten Down ise Down üstüne Down gibi 2 Kan İşareti.
		var tough_markers: int = 2 if target.is_down else 1
		target.blood_markers = min(target.blood_markers + tough_markers, 6)
		target.is_down = true
		GameLogger.log_info("[Tough] %s (Tough): Savaş Dışı yerine Yere Serildi! +%d Kan İşareti → Toplam: %d" % [target.display_name, tough_markers, target.blood_markers], "COMBAT")
		return Outcome.NEGATED_TOUGH

	# GOLEM: Bloodbath Roll dışındaki her Out of Action → Down (tükenmez, her seferinde).
	# GOLEM modeli TOUGH olamaz (compendium), o yüzden çakışma yok.
	if not is_bloodbath and target.unit_data and KeywordSystem.has(target.unit_data, &"golem"):
		var golem_markers: int = 2 if target.is_down else 1
		target.blood_markers = min(target.blood_markers + golem_markers, 6)
		target.is_down = true
		GameLogger.log_info("[Golem] %s (Golem): Savaş Dışı yerine Yere Serildi! +%d Kan İşareti → Toplam: %d" % [target.display_name, golem_markers, target.blood_markers], "COMBAT")
		return Outcome.NEGATED_GOLEM

	# Gerçek Out of Action
	target.current_health = 0
	GameLogger.log_info("[Injury] %s: Savaş Dışı (Out of Action)!" % target.display_name, "COMBAT")
	return Outcome.OUT_OF_ACTION

# ─────────────────────────────────────────────────────────────────────────────
# AKTIVASYON KESİNTİSİ — Down/OOA sonrası gerekli temizlik
# ─────────────────────────────────────────────────────────────────────────────

## Down veya Out of Action sonucunda eğer hedef kendi aktivasyonundaysa biter.
## unit.gd'deki TurnManager.end_unit_activation çağrısını merkezi yönetir.
static func maybe_end_activation(outcome: Outcome, target) -> void:
	var ends_activation: bool = (
		outcome == Outcome.DOWN or
		outcome == Outcome.DOWN_ON_DOWN or
		outcome == Outcome.NEGATED_TOUGH or
		outcome == Outcome.NEGATED_GOLEM
	)
	if ends_activation:
		if TurnManager.current_turn_player_id == target.owner_id and GameState.selected_unit == target:
			TurnManager.end_unit_activation(target)
