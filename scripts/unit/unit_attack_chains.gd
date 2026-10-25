## UnitAttackChains — ÇOKLU saldırı orkestrasyonu (Swinging Blow / Cleave / Automatic / Off-Hand).
##
## Bu dört mekanik aynı aileden gelir: tek bir Fight/Shoot aksiyonundan **birden fazla ayrı
## Success + Injury Roll dizisi** doğar. Hepsi `unit.gd`'nin içindeydi ve dosyayı şişiriyordu;
## sorumluluk buraya taşındı (proje kuralı: 400+ satırlık dosyalara yeni mantık eklenmez).
##
## KURAL KAYNAKLARI (comprehensive-rules/keyword.md + battlekit):
##   SWINGING BLOW (Tenderiser Maul): "you can make 1 Melee Attack against EACH enemy model
##     within 1" of the attacking model. Resolve each one at a time in the order of your choice."
##   CLEAVE(X): "make a number of Melee Attacks with this weapon equal to the value, one after
##     another... Resolve each attack one at a time, using steps 2 to 4 of the Melee Attack Sequence."
##   AUTOMATIC(X): "make a number of Ranged Attacks with this Weapon equal to X, one after another.
##     The attacks can target different enemy models... as long as they are all within 6" of each other."
##   OFF-HAND WEAPON: ikinci melee silahla yapılan saldırıya −1 Dice.
##
## Bu sınıf `unit` node'unu parametre olarak alır (statik/stateless); durum tutmaz.
class_name UnitAttackChains

## Başarı eşiği ve kritik eşiği — Trench Crusade standardı.
const SUCCESS := 7
const CRITICAL := 12
## AUTOMATIC(X) hedeflerinin birbirine azami uzaklığı (compendium: "within 6\" of each other").
const AUTOMATIC_SPREAD := 6.0

# ── ZİNCİR SEÇİMİ ────────────────────────────────────────────────────────────
# Üç zincir de tıklanan TEK hedefin YERİNE geçer (normal tek-hedef akışı atlanır). Seçim
# mantığı eskiden `unit.gd::server_request_attack_action` içinde üç ardışık `if ... return`
# bloğuydu; buraya taşındı ki yeni bir çoklu-saldırı keyword'ü eklemek saldırı AKIŞINA değil
# bu aileye dokunsun.
#
# SIRA ÖNEMLİ: bir silah hem `swinging_blow` hem `cleave` taşıyorsa Swinging Blow kazanır
# (refaktör öncesi davranışın birebir aynısı).

## Bu silah bir çoklu-saldırı zinciri tetikliyor mu? Döner: zincir adı, ya da &"" (tek hedef).
static func select_chain(atk: Resource, is_melee: bool) -> StringName:
	if atk == null:
		return &""
	if is_melee and KeywordSystem.has(atk, &"swinging_blow"):
		return &"swinging_blow"
	# CLEAVE(1) bir zincir DEĞİLDİR — tek saldırıya indirgenir, normal akıştan geçmeli.
	if is_melee and atk.has_cleave and atk.cleave_count > 1:
		return &"cleave"
	if not is_melee and KeywordSystem.has(atk, &"automatic"):
		return &"automatic"
	return &""

## `select_chain()`in döndürdüğü zinciri çalıştırır.
static func run(chain: StringName, unit, first_enemy, atk: Resource) -> void:
	match chain:
		&"swinging_blow":
			await execute_swinging_blow(unit, atk)
		&"cleave":
			await execute_cleave(unit, first_enemy, atk)
		&"automatic":
			await execute_automatic(unit, first_enemy, atk)
		_:
			GameLogger.log_warn("[AttackChains] Bilinmeyen zincir: %s" % chain, "COMBAT")

# ── SWINGING BLOW ────────────────────────────────────────────────────────────
## 1" içindeki HER düşmana birer melee saldırı.
static func execute_swinging_blow(unit, atk: Resource) -> void:
	var enemies: Array = UnitQuery.engaged_enemies(unit)
	if enemies.is_empty():
		GameLogger.log_warn("[Swinging Blow] %s: 1\" içinde düşman yok." % unit.display_name, "COMBAT")
		return
	for target_enemy in enemies:
		if not is_instance_valid(target_enemy) or target_enemy.current_health <= 0:
			continue
		if await _strike(unit, target_enemy, atk, 0, true, "Swinging Blow", 0):
			return

# ── CLEAVE(X) ────────────────────────────────────────────────────────────────
## CLEAVE(X) hedef seçimi: 1" içindeki, bu zincirde HENÜZ hedeflenmemiş en yakın canlı düşman
## tercih edilir; yoksa zaten hedeflenmiş ama HÂLÂ CANLI en yakın düşmana geri dönülür
## (RAW aynı modele birden fazla Cleave saldırısını yasaklamıyor). İkisi de yoksa null.
static func next_cleave_target(unit, already_targeted: Array):
	return _nearest_within(unit, unit.global_position, GameState.ENGAGE_RANGE, already_targeted)

## HEDEF SEÇİMİ OYUNCUNUNDUR (compendium denetimi, Adım 4): Cleave "make a number of Melee
## Attacks... one after another", Automatic "The attacks can target different enemy models",
## Multiple Melee Weapons "You can pick the same or a different model as the target for each
## attack". Önceden zincir hedefi kod seçiyordu (en yakın). Artık birden fazla aday varsa
## saldıranın sahibine haritada tıklatılır; tek aday varsa doğrudan o. `optional`: iptal = saldırı
## yapılmaz (Off-Hand isteğe bağlıdır); değilse iptal/geçersiz seçim en yakın adaya düşer.
static func choose_target(unit, candidates: Array, hint_key: String, optional: bool = false):
	var alive: Array = candidates.filter(func(u): return is_instance_valid(u) and u.current_health > 0)
	if alive.is_empty():
		return null
	if alive.size() == 1 and not optional:
		return alive[0]
	var picked = await CombatChoice.request_enemy_unit_pick(unit, hint_key, alive)
	if picked != null and picked in alive:
		return picked
	if optional:
		return null
	return UnitQuery.nearest(alive, unit.global_position)

## Bu silahla şu an yakın dövüşte vurulabilecek canlı düşmanlar (menzil + toleransla).
static func melee_candidates(unit, atk: Resource) -> Array:
	var reach: float = (atk.attack_range if atk != null else 1.0) + GameState.ATTACK_RANGE_TOLERANCE
	return UnitQuery.within(UnitQuery.enemies_of(unit), unit.global_position, reach)

## IRON CLAWED HANDS / IRON FISTS: bu iki silah "gerçek bir Melee Weapon olmadan Cleave 2" verir
## ve RAW AÇIKÇA ekler: "the Off-Hand Weapon modifier applies to the second attack." Genel
## Cleave(X) (Polearm / Poison Stingers / Crushing Blows) bu notu TAŞIMAZ — bu yüzden ceza yalnız
## silahın kendi `&"cleave_offhand"` keyword'ü varsa uygulanır.
static func execute_cleave(unit, first_enemy, atk: Resource) -> void:
	var count: int = maxi(1, atk.cleave_count)
	var already_targeted: Array = []
	var current_target = first_enemy
	var offhand_penalty: bool = KeywordSystem.has(atk, &"cleave_offhand") \
		and not (unit.unit_data != null and KeywordSystem.has(unit.unit_data, &"ignore_offhand_weapon"))
	for i in range(count):
		if not is_instance_valid(current_target) or current_target.current_health <= 0:
			current_target = next_cleave_target(unit, already_targeted)
			if current_target == null:
				break
		already_targeted.append(current_target)
		var penalty: int = -1 if (i > 0 and offhand_penalty) else 0
		if await _strike(unit, current_target, atk, penalty, true, "Cleave", i + 1):
			return
		if i < count - 1:
			current_target = await choose_target(unit, melee_candidates(unit, atk), "CLEAVE_PICK")
			if current_target == null:
				break

# ── AUTOMATIC(X) ─────────────────────────────────────────────────────────────
## AUTOMATIC(X) hedef seçimi — Cleave'in ranged eşdeğeri; hedefler İLK hedefin 6" çevresinden seçilir.
static func next_automatic_target(unit, origin_enemy, already_targeted: Array):
	if not is_instance_valid(origin_enemy):
		return null
	return _nearest_within(unit, origin_enemy.global_position, AUTOMATIC_SPREAD, already_targeted)

## AUTOMATIC adayları: ilk hedefin 6" çevresinde, menzilde, görüş hattı kapalı olmayan ve
## saklanmayan canlı düşmanlar.
static func automatic_candidates(unit, origin_enemy, atk: Resource) -> Array:
	if not is_instance_valid(origin_enemy):
		return []
	return UnitQuery.where(
		UnitQuery.within(UnitQuery.enemies_of(unit), origin_enemy.global_position, AUTOMATIC_SPREAD),
		func(e):
			if unit.global_position.distance_to(e.global_position) > atk.attack_range + GameState.ATTACK_RANGE_TOLERANCE:
				return false
			if unit.get_line_of_sight_status(e).get("is_blocked", false):
				return false
			return not (e.has_method("is_untargetable_by") and e.is_untargetable_by(unit)))

static func execute_automatic(unit, first_enemy, atk: Resource) -> void:
	var count: int = maxi(1, KeywordSystem.value(atk, &"automatic", 1))
	var already_targeted: Array = []
	var current_target = first_enemy
	for i in range(count):
		if not is_instance_valid(current_target) or current_target.current_health <= 0:
			current_target = next_automatic_target(unit, first_enemy, already_targeted)
			if current_target == null:
				break
		already_targeted.append(current_target)
		if await _strike(unit, current_target, atk, 0, false, "Automatic", i + 1):
			return
		if i < count - 1:
			current_target = await choose_target(unit, automatic_candidates(unit, first_enemy, atk), "AUTOMATIC_PICK")
			if current_target == null:
				break

# ── OFF-HAND ─────────────────────────────────────────────────────────────────
## Multiple Melee Weapons'ın ikinci (Off-Hand) saldırısı — ana Fight action'ın DEVAMI,
## ayrı bir Action harcamaz. Off-Hand modifikatörü −1 Dice.
static func execute_offhand(unit, enemy, offhand_atk: Resource) -> void:
	var dist: float = unit.global_position.distance_to(enemy.global_position)
	var ctx: Dictionary = DicePoolBuilder.build_attack_context(unit, offhand_atk, enemy, dist)
	# IGNORE OFF-HAND WEAPON (Mamluk Faris vb.): −1 Dice cezası bu birimlerde uygulanmaz.
	var offhand_penalty: int = 0 if (unit.unit_data != null \
		and KeywordSystem.has(unit.unit_data, &"ignore_offhand_weapon")) else -1
	var modifier: int = DicePoolBuilder.compute_success_modifier(ctx) + offhand_penalty \
		+ block_penalty(unit, enemy, true)
	GameLogger.log_info("[Multiple Melee Weapons] %s Off-Hand saldırısı: %s" \
		% [unit.display_name, offhand_atk.attack_name], "COMBAT")
	var roll_res: Array = await unit.perform_unit_success_roll(modifier)
	var total_roll: int = roll_res[0]
	if not is_instance_valid(enemy) or enemy.current_health <= 0:
		return
	if total_roll >= SUCCESS:
		var injury_target = await enemy._maybe_redirect_to_bodyguard()
		await injury_target.resolve_injury_roll(unit, total_roll >= crit_threshold(offhand_atk, enemy, true),
			true, 0, 0, offhand_atk)
		return

	GameLogger.log_info("%s Off-Hand saldırısı ıskaladı. Zar: %d" % [unit.display_name, total_roll], "COMBAT")
	# TIME SLIP (Sultanate Assassin): hedefin sahibine opsiyonel yeniden konuşlanma sorulur.
	if is_instance_valid(enemy):
		await enemy._maybe_time_slip(false)
	# SHAKEN / [Risky] silah / Maddening Buzzing — karar tek kaynakta (bkz. RiskyRolls).
	RiskyRolls.apply_failure(unit, total_roll, RiskyRolls.weapon_is_risky(offhand_atk), "Off-Hand")

# ── SERBEST VURUŞ (Retreat tepkisi) ──────────────────────────────────────────
## RISKY NÜANSI (compendium success-rolls.md): "If a model takes a [Risky Success] Roll as part
## of an ACTION **OUTSIDE OF THAT MODEL'S ACTIVATION** and the roll is a Failure, **that ACTION**
## immediately ends." — AKTİVASYON değil, yalnız o aksiyon. Serbest melee vuruşu tam olarak
## böyledir (kaçan düşmana verilen tepki, vuran modelin kendi aktivasyonu DEĞİL). Bu yüzden
## burada `RiskyRolls.apply_failure` KULLANILMAZ: ıska zaten "aksiyonun bitmesi"dir; vuran
## modelin kendi aktivasyonunu bitirmek RAW'a AYKIRI olurdu.
##
## TAM MELEE ATTACK (compendium denetimi, Adım 5): serbest vuruş "1 melee attack with 1 weapon" —
## yani normal bir Melee Attack'in TÜM modifikatörleri geçerlidir (silahın Dice'ı, Fear, Defended
## Obstacle, Unholy Hymns...). Önceden yalnız modelin Melee karakteristiği (+ Down cezası)
## kullanılıyordu; Flail'in +1 Dice'ı, Trench Knife'ın -1 Dice'ı, Fear yok sayılıyordu.
static func execute_free_strike(unit, target) -> bool:
	# P0-3: son UI-seçili silah (Ranged olabilir/alakasız olabilir) DEĞİL, deliberate bir Melee
	# silahı kullanılır (compendium: "1 melee attack with 1 weapon").
	var strike_weapon: Resource = MechanicsResolver.first_melee_attack(unit.unit_data)
	var modifier: int = _free_strike_modifier(unit, target, strike_weapon)

	var roll_res = await unit.perform_unit_success_roll(modifier)
	var total = roll_res[0]

	if total >= SUCCESS:
		# PAIN AMPLIFIER (Combat Biologist'in Vivisector'ı, P1-1): hedefin Kan İşareti sayısı kadar
		# düşük Kritik eşiği.
		var is_crit = total >= DicePoolBuilder.compute_crit_threshold(strike_weapon, target.blood_markers)
		GameLogger.log_info("%s kaçan rakip %s hedefini yakaladı (%d)!" % [unit.display_name, target.display_name, total], "COMBAT")
		var injury_target = await target._maybe_redirect_to_bodyguard()
		await injury_target.resolve_injury_roll(unit, is_crit, true, 0, 0, strike_weapon)
		await _free_strike_cleave_extras(unit, target, strike_weapon)
		return false
	else:
		GameLogger.log_info("%s kaçan rakibi %s ıskaladı (%d)." % [unit.display_name, target.display_name, total], "COMBAT")
		if is_instance_valid(target):
			return await target._maybe_time_slip(true)
		return false

## CLEAVE(X) SERBEST VURUŞTA DA GEÇERLİDİR — compendium (movement.md, Retreating):
## "it can only make 1 melee attack with 1 weapon (it cannot use the Multiple Melee Attacks rule,
## **but if the attacking weapon has the [Cleave](X) Keyword it will still apply**)."
##
## KURAL BOŞLUĞU DÜZELTMESİ (2026-07-29 compendium denetimi): serbest vuruş Cleave'i hiç
## uygulamıyordu — Polearm/Iron Fists gibi Cleave(2) silahı taşıyan bir model, kaçan düşmana
## RAW'ın verdiği ikinci vuruşu yapamıyordu.
##
## BİLİNÇLİ BASİTLEŞTİRME (dokümante): RAW'da Cleave saldırıları saldıranın 1" çevresindeki FARKLI
## modelleri hedefleyebilir; burada ek vuruşlar KAÇAN modele yönlendirilir — serbest vuruşun kendisi
## zaten "kaçan modele tepki"dir, başka hedefe kaymak bağlamı bozardı.
static func _free_strike_cleave_extras(unit, target, strike_weapon: Resource) -> void:
	if strike_weapon == null or not strike_weapon.has_cleave or strike_weapon.cleave_count <= 1:
		return
	for i in range(strike_weapon.cleave_count - 1):
		if not is_instance_valid(target) or target.current_health <= 0 or target.is_down:
			return
		var extra_roll: Array = await unit.perform_unit_success_roll(
			_free_strike_modifier(unit, target, strike_weapon))
		var extra_total: int = extra_roll[0]
		if extra_total < SUCCESS:
			GameLogger.log_info("[Cleave] %s serbest vuruşun %d. saldırısını ıskaladı (%d)." \
				% [unit.display_name, i + 2, extra_total], "COMBAT")
			continue
		var crit: bool = extra_total >= DicePoolBuilder.compute_crit_threshold(
			strike_weapon, target.blood_markers)
		GameLogger.log_info("[Cleave] %s serbest vuruşun %d. saldırısı isabet etti (%d)." \
			% [unit.display_name, i + 2, extra_total], "COMBAT")
		var t2 = await target._maybe_redirect_to_bodyguard()
		await t2.resolve_injury_roll(unit, crit, true, 0, 0, strike_weapon)

## Serbest vuruşun Success Roll modifikatörü — normal Melee Attack havuzunun aynısı.
static func _free_strike_modifier(unit, target, weapon: Resource) -> int:
	if weapon == null:
		return unit.melee_dice_modifier - (1 if unit.is_down else 0)
	var dist: float = unit.global_position.distance_to(target.global_position)
	return DicePoolBuilder.compute_success_modifier(
		DicePoolBuilder.build_attack_context(unit, weapon, target, dist))

# ── ORTAK YARDIMCILAR ────────────────────────────────────────────────────────
## Tek bir Success + Injury Roll dizisi. Dört zincir de bunu kullanır (DRY).
## extra_modifier: zincire özgü ek modifikatör (örn. Cleave'in off-hand cezası).
## Döner: RISKY başarısızlık yüzünden aktivasyon bitti mi? (true ise zincir DURMALIDIR —
## compendium: "if the roll is failed the model's Activation immediately ends".)
static func _strike(unit, target, atk: Resource, extra_modifier: int, is_melee: bool,
		chain_label: String, index: int) -> bool:
	var dist: float = unit.global_position.distance_to(target.global_position)
	var ctx: Dictionary = DicePoolBuilder.build_attack_context(unit, atk, target, dist)
	var modifier: int = DicePoolBuilder.compute_success_modifier(ctx) + extra_modifier \
		+ block_penalty(unit, target, is_melee)
	var roll_res: Array = await unit.perform_unit_success_roll(modifier)
	var total: int = roll_res[0]
	if total >= SUCCESS:
		var injury_target = await target._maybe_redirect_to_bodyguard()
		await injury_target.resolve_injury_roll(unit, total >= crit_threshold(atk, target, is_melee),
			is_melee, 0, 0, atk)
		return false
	if index > 0:
		GameLogger.log_info("[%s] %s %d. saldırısı ıskaladı (%d)." \
			% [chain_label, unit.display_name, index, total], "COMBAT")
	else:
		GameLogger.log_info("[%s] %s ıskaladı %s (%d)." \
			% [chain_label, unit.display_name, target.display_name, total], "COMBAT")
	# Zincirin HER atışı bir Success Roll'dur; Sarsılmış ordu / [Risky] silah / Maddening Buzzing
	# altında bunlar da Risky sayılır ve ıska aktivasyonu ANINDA bitirir (bkz. RiskyRolls).
	return RiskyRolls.apply_failure(unit, total, RiskyRolls.weapon_is_risky(atk), chain_label)

## BLOCK (keyword.md): Charge sonrası BLOCK silahlı hedefe yapılan Melee Attack'e -1 Dice. Ana
## saldırı akışında (AttackFlow._compute_modifier) vardı; zincir ve Off-Hand atışları atlıyordu.
static func block_penalty(unit, target, is_melee: bool) -> int:
	if is_melee and unit.actions_taken.has("charge") and unit._target_wields_block_weapon(target):
		return -1
	return 0

## PAIN AMPLIFIER kritik eşiği (Vivisector) — zincir/Off-Hand atışlarında da geçerli.
static func crit_threshold(atk: Resource, target, is_melee: bool) -> int:
	return DicePoolBuilder.compute_crit_threshold(atk, target.blood_markers) if is_melee else CRITICAL

## `origin` noktasının `radius` çevresindeki en yakın uygun düşmanı seçer.
## Önce bu zincirde hedeflenmemiş olan; yoksa hedeflenmiş ama hâlâ canlı olan.
static func _nearest_within(unit, origin: Vector3, radius: float, already_targeted: Array):
	var candidates: Array = UnitQuery.within(UnitQuery.enemies_of(unit), origin, radius)
	var fresh = UnitQuery.nearest(
		UnitQuery.where(candidates, func(u): return not already_targeted.has(u)), origin)
	if fresh != null:
		return fresh
	return UnitQuery.nearest(candidates, origin)
