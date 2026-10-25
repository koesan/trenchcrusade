## MechanicsResolver — Trench Crusade Özel Savaş Mekanikleri
##
## FAZ 4: CLEAVE, BLAST, Bloodbath Roll ve Diving Charge uygulamaları.
## Bu sınıf STATELESS'tır — unit.gd ve ability_executor bu sınıfı çağırır.
##
## Kurallar (trench_compendium):
##   CLEAVE: Her Out of Action sonucunda, saldırgan 1" içindeki başka bir düşmana otomatik saldırı yapabilir.
##   BLAST X": Patlama merkezinden X" içindeki tüm birimler otomatik Injury Roll atar.
##   BLOODBATH ROLL: Kan İşareti eşiğe ulaşınca Injury Roll 3D6/4D6'ya yükseltilir (dice_pool_builder.gd + unit.gd::resolve_injury_roll).
##   DIVING CHARGE: Yüksek konumdan Charge yapan birim +1 INJURY DICE kazanır.
class_name MechanicsResolver

## ELEMENTAL CHANGE (Jabirean Alchemist): silah elementini bir sonrakine çevirir
## (fire → gas → shrapnel → fire; boş → fire). SAF (test edilebilir).
static func next_element(cur: StringName) -> StringName:
	match cur:
		&"fire":
			return &"gas"
		&"gas":
			return &"shrapnel"
		_:
			return &"fire"

## INFILTRATOR yerleşimi: birim, en yakın düşmandan >= min_dist (8") olacak şekilde yerleştirilebilir.
## SAF predikat (LoS kontrolü çağıran tarafından; sıralı yerleşimde çoğu durumda enemy henüz yok).
static func infiltrator_placement_valid(pos: Vector3, enemy_positions: Array, min_dist: float) -> bool:
	for ep in enemy_positions:
		if pos.distance_to(ep) < min_dist:
			return false
	return true

## GUARD DOG (New Antioch): "Models cannot use the Infiltrator Keyword to deploy within 12" of
## an enemy Guard Dog." SAF predikat — guard_dog_positions: düşman Guard Dog'ların konumları.
static func blocked_by_enemy_guard_dog(pos: Vector3, guard_dog_positions: Array, min_dist: float = 12.0) -> bool:
	for gp in guard_dog_positions:
		if pos.distance_to(gp) < min_dist:
			return true
	return false

## AUTOMATON DESTRIER (Mamluk Faris): "deploy within 1\" of any edge of the battlefield and more
## than 8\" away from any enemy models." SAF predikat — bounds: GameState.battlefield_bounds
## (navmesh AABB'sinden hesaplanır). Basitleştirme: "senaryo Infiltrator özel yerleşimine izin
## veriyorsa" ve "Infiltrator'lardan SONRA" şartları bu projede zaten Infiltrator'ın kendisi için
## de uygulanmadığı için (bkz. infiltrator_placement_valid) buraya da eklenmedi — tutarlı.
static func automaton_destrier_placement_valid(pos: Vector3, bounds: AABB, edge_tolerance: float, enemy_positions: Array, min_enemy_dist: float) -> bool:
	if bounds.size == Vector3.ZERO:
		return false
	var near_edge: bool = pos.x <= bounds.position.x + edge_tolerance \
		or pos.x >= bounds.position.x + bounds.size.x - edge_tolerance \
		or pos.z <= bounds.position.z + edge_tolerance \
		or pos.z >= bounds.position.z + bounds.size.z - edge_tolerance
	if not near_edge:
		return false
	for ep in enemy_positions:
		if pos.distance_to(ep) < min_enemy_dist:
			return false
	return true

## AUTOMATON DESTRIER kullanılabilirlik düzeltmesi: RAW'daki 1" kenar şeridi (edge_tolerance),
## onlarca birim genişliğindeki bir sahada fare ile piksel-hassasiyetinde tıklamayı gerektiriyordu
## (kullanıcı 3 kez üst üste "yerleşim başarısız" aldı, pes edip başka birim yerleştirdi — RAW
## KURALI aynı kalıyor, yalnız TIKLAMA toleransı genişletiliyor, tıpkı resolve_nav_target'ın hareket
## hedefini en yakın geçerli noktaya hizalaması gibi). Tıklama `snap_radius` içindeyse en yakın kenara
## dik izdüşümü alınıp tam `edge_tolerance` şeridinin içine (kenardan edge_tolerance*0.5 içeri) denk
## gelecek şekilde konum düzeltilir; kenar boyunca (paralel eksen) oyuncunun tıkladığı yer korunur.
## snap_radius dışındaysa null döner (o zaman normal ret mesajı gösterilir).
static func automaton_destrier_snap_edge_position(pos: Vector3, bounds: AABB, edge_tolerance: float, snap_radius: float) -> Variant:
	if bounds.size == Vector3.ZERO:
		return null
	var min_x: float = bounds.position.x
	var max_x: float = bounds.position.x + bounds.size.x
	var min_z: float = bounds.position.z
	var max_z: float = bounds.position.z + bounds.size.z

	var d_min_x: float = pos.x - min_x
	var d_max_x: float = max_x - pos.x
	var d_min_z: float = pos.z - min_z
	var d_max_z: float = max_z - pos.z
	var closest: float = min(d_min_x, min(d_max_x, min(d_min_z, d_max_z)))

	if closest > snap_radius:
		return null

	var snapped := pos
	var inset: float = edge_tolerance * 0.5
	if closest == d_min_x:
		snapped.x = min_x + inset
	elif closest == d_max_x:
		snapped.x = max_x - inset
	elif closest == d_min_z:
		snapped.z = min_z + inset
	else:
		snapped.z = max_z - inset
	return snapped

## HATEFUL (Yoke Fiend): aktivasyonda TÜM düşmanlardan >1" uzaktaysa ve 12" içinde LoS'ta, exempt
## (Black Grail/Demonic) OLMAYAN düşman varsa en yakınına zorunlu Charge. SAF geometri predikatı;
## enemies: [{pos: Vector3, exempt: bool, los: bool}]. Dönüş: hedef indexi (yoksa -1).
static func hateful_target_index(fiend_pos: Vector3, enemies: Array) -> int:
	# Fiend zaten bir düşmanın 1" yakınındaysa (angaje) zorunlu charge tetiklenmez.
	for e in enemies:
		if fiend_pos.distance_to(e["pos"]) <= GameState.ENGAGE_RANGE:
			return -1
	var best := -1
	var best_d := 12.0 + 0.001
	for i in range(enemies.size()):
		var e = enemies[i]
		if e.get("exempt", false) or not e.get("los", true):
			continue
		var d: float = fiend_pos.distance_to(e["pos"])
		if d <= 12.0 and d < best_d:
			best_d = d
			best = i
	return best

## PRIZE SPECIMENS (Combat Biologist): Demonic VEYA Black Grail keyword'lü bir düşmanı MELEE ile
## Out of Action edince saldırgan +1 Blessing Marker kazanır. SAF predikat (test edilebilir).
static func prize_specimens_gains_blessing(attacker_ud, target_ud, is_melee: bool, is_ooa: bool) -> bool:
	if not is_melee or not is_ooa or attacker_ud == null or target_ud == null:
		return false
	if not KeywordSystem.has(attacker_ud, &"prize_specimens"):
		return false
	return KeywordSystem.has(target_ud, &"demonic") or KeywordSystem.has(target_ud, &"black_grail")

## Retreat sonrası bedava Melee Strike (P0-3): compendium bunu "1 Melee Weapon ile 1 saldırı"
## olarak tanımlıyor — saldıranın son UI'da seçili silahı (Ranged olabilir, ya da alakasız bir
## Melee silahı olabilir) DEĞİL, deliberate biçimde bir Melee silahı seçilmeli. Birden fazla Melee
## silahı varsa `attacks[]` sırasındaki İLKİ deterministik olarak seçilir (Cleave(X) varsa yine
## uygulanır — compendium açıkça belirtiyor). SAF/testli.
static func first_melee_attack(unit_data) -> Resource:
	if unit_data == null or not ("attacks" in unit_data):
		return null
	for a in unit_data.attacks:
		if a != null and "attack_type" in a and a.attack_type == "MELEE":
			return a
	return null

## first_melee_attack ile AYNI desen — SLAVEMASTER'ın "Shoot Command"ı gibi, bir Ranged saldırıyı
## deterministik seçmesi gereken durumlar için (Yoke Fiend'in en fazla 1 Ranged silahı olabilir,
## ama gelecekte birden fazlası olursa yine İLKİ seçilir).
static func first_ranged_attack(unit_data) -> Resource:
	if unit_data == null or not ("attacks" in unit_data):
		return null
	for a in unit_data.attacks:
		if a != null and "attack_type" in a and a.attack_type == "RANGED":
			return a
	return null

## REGENERATE(X): "keywords[&'regenerate']" X-değerini destekler (yoksa eski has_regeneration
## bool'u X=1 varsayılan davranışını korur — geriye dönük uyumlu). Döndürür: bu aktivasyonda
## temizlenecek Kan İşareti sayısı (mevcut blood_markers ile sınırlı). SAF/testli.
static func compute_regeneration(unit_data, blood_markers: int) -> int:
	if unit_data == null or blood_markers <= 0:
		return 0
	var amount := 0
	if KeywordSystem.has(unit_data, &"regenerate"):
		amount = KeywordSystem.value(unit_data, &"regenerate", 1)
	elif "has_regeneration" in unit_data and unit_data.has_regeneration:
		amount = 1
	return mini(amount, blood_markers)

# ─────────────────────────────────────────────────────────────────────────────
# HÜCUM GEOMETRİSİ — Araya giren düşman (P2-7: unit.gd'den çıkarıldı)
# ─────────────────────────────────────────────────────────────────────────────

## p noktası, a→b segmenti boyunca uçlar ARASINDA (dışlayıcı) ve segmentten `radius` içinde mi?
## (Saf projeksiyon geometrisi — STATELESS/testli.) a==b dejenere segmentte false.
static func segment_interposes(a: Vector3, b: Vector3, p: Vector3, radius: float) -> bool:
	var ab: Vector3 = b - a
	var ab_len: float = ab.length()
	if ab_len < 0.01:
		return false
	var dir: Vector3 = ab / ab_len
	var proj: float = (p - a).dot(dir)
	if proj <= 0.0 or proj >= ab_len:
		return false  # hedefin gerisinde veya ötesinde
	var closest: Vector3 = a + dir * proj
	return p.distance_to(closest) < radius

## Hücum düz çizgisinde (attacker→target), hedeften ÖNCE 1" içinden geçilen başka bir DÜŞMAN
## var mı? Compendium: araya giren düşman varsa o hedef seçilmelidir. Varsa döndürür, yoksa null.
static func charge_interposing_enemy(attacker, target) -> Node3D:
	var a: Vector3 = attacker.global_position
	var b: Vector3 = target.global_position
	for u in UnitQuery.enemies_of(attacker):
		if u == target:
			continue
		if segment_interposes(a, b, u.global_position, GameState.ENGAGE_RANGE):
			return u
	return null

# ─────────────────────────────────────────────────────────────────────────────
# CLEAVE — bkz. UnitAttackChains.execute_cleave/next_cleave_target (P1-30 düzeltmesi,
# 2026-07-16). Eski "OOA-kill sonrası zincirleme saldırı" yorumu (find_cleave_target/
# execute_cleave/execute_cleave_chain) RAW'a AYKIRI olduğu için kaldırıldı — gerçek RAW
# (keyword.md): "Fight Action alırken bu silahla X kadar Melee Attack yapılabilir, art arda,
# farklı düşman modellere (hepsi 1" içinde) — kill koşulu YOK." Yeni implementasyon Fight
# Action'ın KENDİSİNDEN X ayrı Success+Injury Roll dizisi üretir (unit.gd, silahın kendi
# has_cleave/cleave_count alanlarını okur — artık ölü UnitData.has_cleave bayrağına değil).
# ─────────────────────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────────────────────
# BLAST — Patlama Alanı
# ─────────────────────────────────────────────────────────────────────────────

## BLAST efektini uygular: merkez noktasından blast_radius" içindeki herkese Injury Roll.
## BLAST HEDEF SEÇİMİ — compendium (keyword.md, BLAST (X)):
##   "every model that has a Line of Sight to the target and which is within the Weapon's blast
##    radius is hit. **In addition, friendly models that are within 1" of an enemy model that was
##    hit by the blast radius are also hit.**"
##
## KURAL SAPMASI DÜZELTMESİ (2026-07-29 compendium denetimi): eski kod yarıçaptaki HERKESİ
## (saldıran hariç) vuruyordu. Yani saldıranın kendi dostları, hiçbir düşmanın yakınında
## olmasalar bile patlamadan yara alıyordu — RAW ise dostları YALNIZ "vurulan bir düşmanın 1"
## içindeyseler" kapsıyor. Bu, Blast silahlarının kendi ordusuna verdiği zararı RAW'ın
## öngördüğünden çok daha yüksek yapıyordu.
##
## BİLİNÇLİ BASİTLEŞTİRME (dokümante): RAW ayrıca kurbanın HEDEFE görüş hattı olmasını şart
## koşar. Bu proje görüş hattını yalnız model-model hesaplar ve patlama merkezi bir NOKTA da
## olabilir; koşul uygulanmadı (mevcut arazi/LoS modelinin çözünürlüğünün altında kalıyor).
##
## Döner: Injury Roll atılacak modeller.
static func blast_victims(attacker, blast_center: Vector3, blast_radius: float) -> Array:
	var in_radius: Array = UnitQuery.where(
		UnitQuery.within(UnitQuery.alive(), blast_center, blast_radius),
		func(u): return u != attacker)

	# Düşmanlar KOŞULSUZ vurulur.
	var enemies: Array = UnitQuery.where(in_radius,
		func(u): return u.owner_id != attacker.owner_id)
	var victims: Array = enemies.duplicate()

	# Dostlar YALNIZ vurulan bir düşmanın 1" içindeyseler vurulur.
	for f in UnitQuery.where(in_radius, func(u): return u.owner_id == attacker.owner_id):
		if not UnitQuery.within(enemies, f.global_position, GameState.ENGAGE_RANGE).is_empty():
			victims.append(f)
	return victims

## is_critical: Patlama kritik mi? (Bazı silahlar için)
static func execute_blast(
		attacker,
		blast_center: Vector3,
		blast_radius: float,
		attack_data,
		is_critical: bool = false,
		primary_target = null
) -> void:
	GameLogger.log_info("[BLAST] %s patlaması tetiklendi! Merkez: %s, Çap: %.1f m" \
		% [attacker.display_name, blast_center, blast_radius], "COMBAT")
	var hit_count := 0
	for u in blast_victims(attacker, blast_center, blast_radius):
		# `resolve_injury_roll` bir coroutine'dir (await edilmez ama askıya alınabilir);
		# liste alındıktan sonra bir modelin durumu değişmiş olabilir — yeniden doğrula.
		if not is_instance_valid(u) or u.current_health <= 0:
			continue
		hit_count += 1
		# KRİTİK BONUSU YALNIZ HEDEFE — compendium (keyword.md, BLAST): "If you roll a Critical
		# Success, **only add the extra Injury Dice to the roll for a model IF IT WAS CHOSEN AS
		# THE TARGET of the attack.**" Eski kod bonusu patlamadaki HERKESE veriyordu.
		var crit_for_this: bool = is_critical and u == primary_target
		GameLogger.log_info("[BLAST] %s patlama alanında! (%.2f m) → Injury Roll başlıyor." \
			% [u.display_name, u.global_position.distance_to(blast_center)], "COMBAT")
		# BLAST: Başarı zarı yok — doğrudan Injury Roll. QA denetimi (2026-07-16): attack_data
		# parametresi önceden resolve_injury_roll'a HİÇ iletilmiyordu — Injury Modifier/keyword'ler
		# (Deadly, Ignore Armour vb.) gerçek patlama silahından değil, saldıranın o an UI'de
		# "seçili" olan silahından (veya hiçbiri seçili değilse yanlış/boş) okunuyordu. Düzeltildi.
		u.resolve_injury_roll(attacker, crit_for_this, false, 0, 0, attack_data)
	if hit_count == 0:
		GameLogger.log_info("[BLAST] Patlama alanında hiçbir birim yok.", "COMBAT")

## GENEL SCATTER+BLAST ÇÖZÜMÜ (keyword.md SCATTER): unit.gd, is_blast+blast_radius>0+scatter
## keyword'ü taşıyan HERHANGİ bir silah için bu fonksiyonu çağırır (blast_center zaten unit.gd'de
## hesaplanmış kayma noktasıdır). "Infernal Strike" (primary hedefe Deadly) ve "Mighty Explosion"
## (D3" geri itme) Artillery Witch'in Infernal Bomb'una ÖZGÜ isimli EK yeteneklerdir — genel SCATTER
## kuralının bir parçası DEĞİLDİR — bu yüzden silahın kendi `&"infernal_strike"`/`&"mighty_explosion"`
## keyword'lerine bağlıdır (yalnız infernal_bomb.tres taşır). Böylece ileride Scatter+Blast taşıyan
## AMA bu iki ek yeteneği taşımayan başka bir silah eklenirse, o silah yalnız normal Blast Injury
## Roll'u tetikler (execute_blast ile AYNI davranış), yanlışlıkla Deadly/knockback ALMAZ.
## Basitleştirme (dokümante): "impassable terrain/Climb" şartı taşınmıyor — yalnız başka bir modele
## çarpma kontrol edilir (Inflict Pain ile AYNI desen).
static func execute_infernal_bomb_blast(attacker, primary_target, blast_center: Vector3,
		blast_radius: float, attack_data: Resource, is_critical: bool, primary_gets_deadly: bool) -> void:
	GameLogger.log_info("[Scatter Blast] %s patlaması tetiklendi! Merkez: %s, Çap: %.1f m" \
		% [attacker.display_name, blast_center, blast_radius], "COMBAT")
	var grants_deadly: bool = KeywordSystem.has(attack_data, &"infernal_strike")
	var grants_knockback: bool = KeywordSystem.has(attack_data, &"mighty_explosion")
	for u in blast_victims(attacker, blast_center, blast_radius):
		# Liste döngüden ÖNCE alınır; aradaki `await`larda bir model Savaş Dışı kalmış
		# olabilir — her adımda yeniden doğrula (aksi hâlde ölüye Injury Roll atılır).
		if not is_instance_valid(u) or u.current_health <= 0:
			continue
		var is_primary: bool = u == primary_target
		var atk_for_this: Resource = attack_data
		if is_primary and primary_gets_deadly and grants_deadly:
			atk_for_this = attack_data.duplicate()
			atk_for_this.is_deadly = true
		var blow_origin: Vector3 = attacker.global_position if is_primary else blast_center
		# Kritik bonusu YALNIZ hedeflenen modele (compendium BLAST kuralı — bkz. execute_blast).
		await u.resolve_injury_roll(attacker, is_critical and is_primary, false, 0, 0, atk_for_this)
		if grants_knockback and is_instance_valid(u) and u.current_health > 0:
			var push_dist: int = randi_range(1, 3)
			var dir: Vector3 = u.global_position - blow_origin
			dir.y = 0.0
			if dir.length() < 0.01:
				dir = Vector3(1, 0, 0)
			dir = dir.normalized()
			var pushed: Vector3 = u.global_position + dir * float(push_dist)
			# İtilecek nokta başka bir modelin angaje mesafesine düşüyorsa savrulma engellenir.
			var blocked: bool = UnitQuery.any(UnitQuery.where(
				UnitQuery.within(UnitQuery.alive(), pushed, GameState.ENGAGE_RANGE),
				func(u2): return u2 != u))
			if not blocked:
				u.global_position = pushed
				RpcHelper.sync(u, "client_update_move", [pushed])
				GameLogger.log_info("[Mighty Explosion] %s patlamayla %d\" savruldu." % [u.display_name, push_dist], "COMBAT")

# ─────────────────────────────────────────────────────────────────────────────
# MARTYRDOM DEVICE — Ecclesiastic Prisoner (Trench Pilgrims)
# ─────────────────────────────────────────────────────────────────────────────

## Kural kitabı: "Trigger Martyrdom Device" Action — zar atılmaz, doğrudan tetiklenir.
## 3" içindeki HERKES (dost/düşman, tetikleyen dahil) Injury Roll atar.
## Tetikleyenin kendi Injury Roll'u her zaman 4D6 (Bloodbath'ten bağımsız).
## 1" içindeki DİĞER modeller +1 Injury Dice alır. Tek kullanımlıktır (çağıran taraf
## ability_executor.gd üzerinden action_key'i actions_taken'a ekleyerek tekrar kullanımı engeller).
static func execute_martyrdom_device(prisoner, attack_data: Resource) -> void:
	var center: Vector3 = prisoner.global_position
	# Aygıt dost/düşman ayırmaz — 3" içindeki HERKES (tetikleyen dâhil) etkilenir.
	var targets: Array = UnitQuery.within(UnitQuery.alive(), center, 3.0 + GameState.ATTACK_RANGE_TOLERANCE)

	GameLogger.log_warn("[Martyrdom Device] %s Şehitlik Aygıtını tetikledi! %d model etki alanında." \
		% [prisoner.display_name, targets.size()], "COMBAT")

	for u in targets:
		if not is_instance_valid(u) or u.current_health <= 0:
			continue
		if u == prisoner:
			await u.resolve_injury_roll(prisoner, false, false, 4, 0, attack_data)
			# AWAITED (P1-1): Martyrdom Device ile Savaş Dışı kalırsa Morale sayımına girmez.
			if prisoner.current_health <= 0 and prisoner.unit_data != null \
					and KeywordSystem.has(prisoner.unit_data, &"awaited"):
				TurnManager.exempt_from_morale_count(prisoner.owner_id)
		else:
			var dist: float = u.global_position.distance_to(center)
			var bonus: int = 1 if dist <= GameState.ENGAGE_RANGE else 0
			await u.resolve_injury_roll(prisoner, false, false, 0, bonus, attack_data)

# ─────────────────────────────────────────────────────────────────────────────
# BLOODBATH ROLL — bkz. scripts/rules/dice_pool_builder.gd (bloodbath_threshold,
# compute_bloodbath_dice_count) ve scenes/unit/unit.gd::resolve_injury_roll().
# Kural kitabındaki gerçek mekanik: hedefin Kan İşaretleri eşiğe ulaştığında (6, Down ise 3)
# Injury Roll 3D6'ya (DEADLY silahla 4D6) yükseltilir. Willpower testi/saldırı-kilidi
# homebrew mekaniği kaldırıldı — compendium'da karşılığı yoktu.
# ─────────────────────────────────────────────────────────────────────────────
# DIVING CHARGE — Yüksek Konumdan Hücum Bonusu
# ─────────────────────────────────────────────────────────────────────────────

## Diving Charge YÜKSEKLİK koşulu (STATELESS, saf).
## Kural (comprehensive-rules/melee-attacks.md): bir charge, hedefin en az 3" ÜSTÜNDEN atlayıp
## (Jump Down ≥3") hedefin 1" içine inince Diving Charge'a çevrilebilir. Bu koşul CHARGE ANINDA
## (birim henüz yüksekteyken) değerlendirilir — saldırı anında DEĞİL (o an birim melee mesafesinde,
## hedefle aynı yükseklikte olur ve koşul asla sağlanmazdı; eski hata buydu).
## Riskli zar + bonus/ceza akışı unit.resolve_diving_charge() içinde; +1 DICE melee SUCCESS roll'una
## (injury'ye değil) diving_charge_bonus_pending bayrağı ile uygulanır.
static func is_diving_charge_height(attacker_start_y: float, target_y: float) -> bool:
	return (attacker_start_y - target_y) >= GameState.DIVING_CHARGE_MIN_HEIGHT

# ─────────────────────────────────────────────────────────────────────────────
# HEAVY — bkz. comprehensive-rules/keyword.md. STRONG "Negate Heavy" verir (KeywordSystem.negates).
# ─────────────────────────────────────────────────────────────────────────────

## Bu birim, en az bir HEAVY battlekit'i taşıyor mu (ve bu HEAVY negate edilmemiş mi)?
## Kural: "does not receive a Charge Bonus when it makes a charge move" — bu SAF predikat
## Charge Bonus D6'sının atılıp atılmayacağını belirler (unit.gd::server_request_charge).
## LAW OF HELL (Wretched, Heretic Legion/Court): saldıran bir Wretched, [Elite] bir düşmanı
## Savaş Dışı ederse "özgürlüğünü kazanır" (sahadan kaldırılır, roster/moral dışı kalır). SAF predikat.
static func law_of_hell_triggers(attacker_unit_data: Resource, target_unit_data: Resource, target_went_ooa: bool) -> bool:
	if not target_went_ooa or attacker_unit_data == null or target_unit_data == null:
		return false
	return KeywordSystem.has(attacker_unit_data, &"law_of_hell") \
		and KeywordSystem.has(target_unit_data, &"elite")

## BEELZEBUB'S TOUCH (Lord of Tumours): melee saldırısı hedefe Blood/Infection Marker koyduysa
## +1 ek Infection Marker. SAF predikat (marker_placed = bu saldırıda herhangi bir Blood/Infection
## Marker eklendi mi — çağıran taraf hesaplar, öncesi/sonrası fark).
static func beelzebubs_touch_triggers(attacker_unit_data: Resource, is_melee: bool, marker_placed: bool) -> bool:
	if not is_melee or not marker_placed or attacker_unit_data == null:
		return false
	return KeywordSystem.has(attacker_unit_data, &"beelzebubs_touch")

## PARASITE HOST (Corpse Guard): melee saldırısı hedefe Blood/Infection Marker koyduysa, saldıran
## kendi üzerinden 1 Blood VEYA Infection Marker kaldırabilir. SAF predikat (tetikleme koşulu).
static func parasite_host_triggers(attacker_unit_data: Resource, is_melee: bool, marker_placed: bool) -> bool:
	if not is_melee or not marker_placed or attacker_unit_data == null:
		return false
	return KeywordSystem.has(attacker_unit_data, &"parasite_host")

# ─────────────────────────────────────────────────────────────────────────────
# GLORIOUS DEEDS — saf tetikleme predikatları (scenarios/rules/glorious-deeds.md +
# scenarios/claim-no-mans-land.md). Senaryo mantığı (ScenarioLogic alt sınıfları) bunları
# çağırıp award_deed() ile oyuncuya verir; VP/tekrarlama kuralları ScenarioLogic'te.
# ─────────────────────────────────────────────────────────────────────────────

## BLOODLETTING: "An attack... results in the sixth Blood Marker being placed beside an enemy."
static func bloodletting_triggers(blood_before: int, blood_after: int) -> bool:
	return blood_before < 6 and blood_after >= 6

## SNIPER: "A friendly model takes an enemy [Elite] model Out of Action with a Ranged Weapon
## Attack that has the Long Range and Cover modifiers." (OOA koşulu çağıran tarafından sağlanır.)
static func sniper_deed_triggers(is_melee: bool, is_long_range: bool, in_cover: bool, target_is_elite: bool) -> bool:
	return not is_melee and is_long_range and in_cover and target_is_elite

## GREAT WAR VP formülü: "VPs for enemy models taken Out of Action equal to the model's Cost,
## divided by 10 if it has a Cost in [Dukats] (rounding fractions up)." Glory-item para birimi
## (Cost in Glory) bu projede modellenmiyor — tüm Cost Dukat sayılır.
static func great_war_vp_for_cost(cost: int) -> int:
	if cost <= 0:
		return 0
	return int(ceil(cost / 10.0))

## SUICIDAL BRAVERY: "A friendly model successfully charges two models with the same charge move."
## Yaklaşıklık: hücum SONUNDA 1" içinde (ENGAGE_RANGE) kaç düşman varsa onunla ölçülür.
static func suicidal_bravery_triggers(engaged_enemy_count: int) -> bool:
	return engaged_enemy_count >= 2

## BLOOD SACRIFICE (Relic Hunt): "A friendly model causes three enemy models to be taken Out of
## Action during the game." Aynı modelin OYUN BOYUNCA (tur/aktivasyon sıfırlaması YOK) OOA ettiği
## düşman sayısı.
static func blood_sacrifice_triggers(ooa_count_this_game: int) -> bool:
	return ooa_count_this_game >= 3

## RELIC HUNTER (Relic Hunt): "A friendly model claims two different Reliquaries during the game."
static func relic_hunter_triggers(distinct_reliquaries_claimed: int) -> bool:
	return distinct_reliquaries_claimed >= 2

## PROTECT THE RELIC (Relic Hunt): "A friendly model causes an enemy model that is within 1" of a
## Reliquary Marker to be taken Out of Action." Mesafe hesabı çağıran tarafça yapılır (Vector2 XZ,
## get_objective_controller'daki desenle AYNI); bu saf fonksiyon yalnız koşulu adlandırır.
static func protect_the_relic_triggers(target_was_near_active_reliquary: bool) -> bool:
	return target_was_near_active_reliquary

## HEAD HUNTER (Marked for Death, özgün senaryo): aynı modelin oyun boyunca OOA ettiği FARKLI
## Bounty Target sayısı >= 3 (rakip birden fazla kez yeniden atadıysa aynı model peş peşe hepsini
## avlayabilir — RAW tarzı bir "3 farklı X" deed kalıbı, diğer senaryoların Reaper/Relic Hunter'ıyla
## AYNI aile).
static func head_hunter_triggers(distinct_bounty_targets_slain: int) -> bool:
	return distinct_bounty_targets_slain >= 3

## negate_heavy_effect (Assault Drill/Battlefield Demolition, P1-1): STRONG'un blanket
## Negate Heavy'sinden FARKLI — yalnız TEK bir spesifik silahın Heavy ETKİSİNİ (Charge Bonus
## reddi + Move+Shoot kilidi) yok sayar, "en fazla 1 Heavy silah" SAYIM kısıtını DEĞİL
## (compendium: "still cannot have more than 1 Weapon... with the Heavy Keyword" — bu yüzden
## loadout_resolver.gd'nin max-1-heavy doğrulaması bu keyword'ü BİLEREK dinlemez). Bu birimlerin
## bugün tek bir Heavy silahı olduğu için pratikte blanket negate ile aynı sonucu verir, ama
## ileride 2. bir Heavy Battlekit eklenirse (max-1 kısıtı hâlâ geçerli olduğundan) doğru davranır.
static func has_unnegated_heavy_loadout(unit_data: Resource) -> bool:
	if unit_data == null:
		return false
	if KeywordSystem.negates(unit_data, &"heavy") or KeywordSystem.has(unit_data, &"negate_heavy_effect"):
		return false
	for atk_res in unit_data.attacks:
		if atk_res != null and KeywordSystem.has(atk_res, &"heavy"):
			return true
	return false

## BULKY (Machine Armour, battlekit/armour.md): "has a Charge Bonus of D3" instead of D6"."
## Proje D3 zar modeli içermiyor; standart D6→D3 dönüşümü uygulanır (zaten atılmış D6 sonucunu
## 2'ye bölüp yukarı yuvarlama: 1-2→1, 3-4→2, 5-6→3). Görsel zar atışı DEĞİŞMEZ, yalnız bu
## SONUCU çeviren saf fonksiyon — unit.gd::server_request_charge_action tarafından çağrılır.
static func apply_charge_bonus_d3(unit_data: Resource, rolled_d6: int) -> int:
	if unit_data != null and KeywordSystem.has(unit_data, &"charge_bonus_d3"):
		return int(ceil(rolled_d6 / 2.0))
	return rolled_d6

## "Aktivasyonu Bitir" — kullanıcı bildirimi: "bazen tur atla diyorum atlamıyor." Oyuncu bir
## birimi aktive edip (en az 1 aksiyon aldıktan) sonra seçimi bırakmışsa/başka bir birime
## tıklamışsa, TurnManager.end_turn() artık yeniden seçtirmeye zorlamadan bu YARIDA kalan birimi
## kendisi bulur. SAF fonksiyon (Node/RPC gerektirmez) — units: {name: unit} sözlüğü, her unit'te
## owner_id/current_health/has_moved/actions_taken alanları olmalı (gerçek Unit veya sahte test nesnesi).
static func find_stuck_activation_unit(units: Dictionary, player_id: int):
	for u_name in units:
		var u = units[u_name]
		if is_instance_valid(u) and u.owner_id == player_id and u.current_health > 0 \
				and not u.has_moved and not u.actions_taken.is_empty():
			return u
	return null

# NOT: Eski `get_shaken_modifier` (yanlış "Shaken = -1 DICE" yorumu) ve `log_morale_status`
# yardımcıları kaldırıldı — hiçbir yerden çağrılmıyorlardı. Shaken'in doğru davranışı (Sarsılmış
# ordunun tüm Success Roll'ları Risky sayılır) TurnManager.is_shaken() ile saldırı/yetenek
# çözümleme noktalarında uygulanıyor (compendium morale-phase).

# ─────────────────────────────────────────────────────────────────────────────
# GOETIC SPELLS — Court of the Seven-Headed Serpent (P1-1)
# ─────────────────────────────────────────────────────────────────────────────

## Bir modelin Blood Marker'ları bir Goetic Spell'in maliyetini ödemek için "kaynak" olarak
## kullanılabilir mi? Compendium: "You can remove the Blood Markers from any models (friend or
## foe) that do not have the Black Grail or Demonic Keywords." — HERETIC dahil her şeyden
## alınabilir, yalnız Black Grail/Demonic hariç (KeywordSystem.is_unholy() farklıdır, o
## HERETIC'i de sayar — burada bilerek KULLANILMIYOR).
static func is_goetic_blood_source(unit_data: Resource) -> bool:
	if unit_data == null:
		return false
	return not (KeywordSystem.has(unit_data, &"demonic") or KeywordSystem.has(unit_data, &"black_grail"))

## Sahadaki Goetic-kaynağı sayılan (is_goetic_blood_source) modellerin toplam Blood Marker'ı.
## SAF: `sources` çağıran tarafça [{"blood_markers":int,"unit_data":Resource}, ...] şeklinde
## toplanır (GameState.units'e burada dokunulmaz — testte gerçek sahne kurmadan çağrılabilir).
## KULLANIM: pay_goetic_cost, request_blood_drain'i (harita-tıklama pick modu) açmadan ÖNCE bunu
## kontrol eder — sahada hiç Blood Marker yoksa oyuncu asla tamamlanamayacak bir seçim ekranında
## sessizce kilitlenmez ("butona bastım hiçbir şey olmadı" hatası).
static func total_available_goetic_blood(sources: Array) -> int:
	var total := 0
	for s in sources:
		var bm: int = int(s.get("blood_markers", 0))
		if bm > 0 and is_goetic_blood_source(s.get("unit_data")):
			total += bm
	return total

## NEGATE DIFFICULT TERRAIN (War Wolf, heretic-legion.md): "This abomination charges through
## miles of barbed wire, CLEARING A PATH for the Heretic infantry." Bu keyword'ü taşıyan model
## `[Difficult]` arazi parçalarının hareket cezasından etkilenmez.
## SAF: yalnız birimin keyword'üne bakar; arazi sorgusu çağıran tarafta (TerrainManager).
static func ignores_difficult_terrain(unit_data: Resource) -> bool:
	return unit_data != null and KeywordSystem.has(unit_data, &"negate_difficult_terrain")

## Bu birim bu konumda zorlu arazi cezası alır mı? (TerrainManager + yukarıdaki muafiyet)
static func suffers_difficult_terrain(unit_data: Resource, pos: Vector3) -> bool:
	if ignores_difficult_terrain(unit_data):
		return false
	return TerrainManager.has_keyword_at(pos, &"difficult")

## MASTERY OF THE ELEMENTS (Jabirean Alchemist, iron-sultanate.md): "you can give ONE OF THE
## FOLLOWING Keywords to all of the Alchemist's Weapons: [Fire] OR [Gas] OR [Shrapnel]."
## Seçim OYUNCUNUNdur — eskiden koda `fire` sabitlenmişti (denetim bulgusu P1-IS-4a).
static func mastery_element_choices() -> Array:
	return [&"fire", &"gas", &"shrapnel"]

## Heretic Trooper → Heretic Legionnaire terfisi (Heretic Legion, loadout upgrade). Compendium:
## "You cannot upgrade a Heretic Trooper if doing so would result in there being more Heretic
## Legionnaires in your Warband than there are Heretic Troopers." — terfi ettirilmemiş (Standard
## loadout) Trooper sayısı, terfi SONRASI Legionnaire sayısından KESİNLİKLE az olamaz.
static func heretic_legionnaire_upgrade_allowed(plain_trooper_count: int, legionnaire_count_after: int) -> bool:
	return legionnaire_count_after <= plain_trooper_count

## Wretched (Court): "Availability: Must be outnumbered by models with the Keyword DEMONIC."
## Bu birimden BİR TANE DAHA yerleştirilmek istendiğinde (deploy_after dahil sayım), Demonic
## sayısı Wretched sayısını KESİNLİKLE AŞMALI (eşitlik yetmez — "outnumbered" = kesin çoğunluk).
static func court_wretched_deploy_allowed(demonic_count: int, wretched_count_after: int) -> bool:
	return demonic_count > wretched_count_after

## DEMONIC AURA (Court of the Seven-Headed Serpent): `sin_aura_id` aura'sını taşıyan bir
## Desecrated Saint 3" içinde mi? Döner: true = düşman bu aura alanında.
static func is_in_demonic_aura(unit_node, sin_aura_id: StringName) -> bool:
	# 3" içindeki Demonic düşmanlar — asıl filtre (Desecrated Saint + seçili günah) aşağıda.
	for u in UnitQuery.with_keyword(UnitQuery.enemies_within(unit_node, 3.0), &"demonic"):
		if u.unit_data.faction_id != &"court_of_seven_headed_serpent":
			continue
		# Desecrated Saint kontrolü: demonic_aura ability'si olan birim
		var has_aura := false
		for ab in u.unit_data.abilities:
			if ab != null and ab.ability_id == &"demonic_aura":
				has_aura = true
				break
		if not has_aura:
			continue
		# Seçilen günah kontrolü
		var faction = GameState.get_faction_for_player(u.owner_id)
		if faction == null or faction.selected_sin == &"":
			continue
		var sin_data: Dictionary = FactionData.SEVEN_DEADLY_SINS.get(faction.selected_sin, {})
		if sin_data.get("demonic_aura", "") == String(sin_aura_id):
			return true
	return false
