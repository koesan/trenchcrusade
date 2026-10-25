## CombatResolver — Trench Crusade Ana Savaş Çözümleyici
##
## Bu sınıf STATELESS'tır.
## unit.gd'deki server_request_attack_action() bu sınıfı delege olarak kullanır.
##
## Sorumluluk:
##   1. Saldırı geçerlilik kontrolleri (menzil, angaje, LOS)
##   2. Success Roll havuzunu DicePoolBuilder'a delege et
##   3. İsabet → InjuryResolver'a delege et
##   4. Senkronizasyon çağrıları için attacker'a geri döner
##
## Şu an doğrudan çağrılmıyor (FAZ 2 bağlantısı unit.gd üzerinden).
## FAZ 3'te AbilityExecutor ile tam entegrasyon yapılacak.
class_name CombatResolver

## HEAVY (compendium keyword.md): bu birincil hareket/Dash eylemlerinden biri aynı aktivasyonda
## alınmışsa HEAVY Ranged/Grenade ile saldırı yapılamaz.
const HEAVY_EXCLUDED_ACTIONS := ["move", "charge", "retreat", "dash"]

## HEAVY kısıtının SİMETRİK yönü (P0-5): bu aktivasyonda zaten bir HEAVY Ranged/Grenade saldırısı
## yapıldıysa (has_heavy_shot), Move/Charge/Retreat/Dash de artık yapılamaz. (Diğer yön —
## bu eylemlerden biri yapıldıktan sonra HEAVY saldırı engeli — validate_attack'te uygulanıyor.)
## SAF/testli.
static func heavy_blocks_move_action(has_heavy_shot: bool, action_name: String) -> bool:
	return has_heavy_shot and action_name in HEAVY_EXCLUDED_ACTIONS

# ─────────────────────────────────────────────────────────────────────────────
# SHOOT ↔ CHARGE/FIGHT ETKİLEŞİM KURALI (SAF — test edilebilir)
# ─────────────────────────────────────────────────────────────────────────────

## Compendium (Actions + [Assault] keyword): Assault OLMAYAN bir Shoot ile Charge/Fight aynı
## aktivasyonda BİRLİKTE yapılamaz. Somut sonuçlar:
##   - Charge sonrası Fight (melee): HER ZAMAN serbest ("Dash, Charge, Fight" yasal dizisi).
##   - Charge veya Fight yapıldıysa Shoot: yalnız silah [Assault] ise.
##   - Assault OLMAYAN bir Shoot yapıldıysa: Charge ve Fight kilitlenir.
## Bu SAF fonksiyondur; angaje/menzil/tekrar/LoS kontrolleri ayrıca yapılır.
##   is_melee: bu saldırı yakın dövüş mü | is_assault: silahın [Assault] bayrağı
##   charged/fought: bu aktivasyonda Charge/Fight yapıldı mı
##   did_non_assault_shot: bu aktivasyonda Assault OLMAYAN bir Shoot yapıldı mı
## CHARGE, Assault OLMAYAN bir Shoot'tan SONRA yapılamaz.
##
## Compendium (actions.md, Charge): "A model cannot take a Shoot or Fight [Action] **and a Charge
## [Action] in the same Activation**, unless it uses a Weapon that has the [Assault] keyword."
##
## KURAL BOŞLUĞU DÜZELTMESİ (2026-07-29 denetimi): kısıt yalnız TEK YÖNDE uygulanıyordu —
## `attack_interaction_allowed` "Shoot sonrası Fight" ve "Charge/Fight sonrası Shoot"u
## engelliyordu, ama "Shoot sonrası CHARGE" serbestti. Model menzilden ateş edip aynı
## aktivasyonda hücum edebiliyordu. (`AttackFlow._record_action`in yorumu zaten "Charge/Fight
## kilitlenir" DİYORDU — Charge tarafı hiç bağlanmamıştı.)
##
## NOT: "Fight sonrası Charge" ayrıca ele alınmaz; Fight yapan model angaje olur ve angaje
## modeller zaten Charge edemez (compendium: "You cannot take a Charge Action with a model that
## is already within 1" of an enemy model") — o kural `unit_actions` içinde uygulanıyor.
static func charge_blocked_by_shot(did_non_assault_shot: bool) -> bool:
	return did_non_assault_shot

static func attack_interaction_allowed(is_melee: bool, is_assault: bool, charged: bool, fought: bool, did_non_assault_shot: bool) -> bool:
	if is_melee:
		# Fight: yalnız Assault olmayan bir Shoot yapıldıysa engellenir (charge dahil aksi hâlde serbest).
		return not did_non_assault_shot
	# Shoot: Charge veya Fight yapıldıysa yalnız Assault silahla.
	if (charged or fought) and not is_assault:
		return false
	return true

# ─────────────────────────────────────────────────────────────────────────────
# GEÇERLİLİK KONTROL — Saldırı yapılabilir mi?
# ─────────────────────────────────────────────────────────────────────────────

## Bu saldırgan, melee saldırısında dost bir hedefi seçebilir mi? (Tek kaynak — validate_attack VE
## unit_movement._compute_is_valid_target ikisi de bunu kullanır, hedef vurgusu tutarlı kalır.)
## WHIP OF GOD (Castigator): herhangi bir dost hedef. TORTURER (Yoke Fiend): [Demonic] OLMAYAN dost.
static func allows_friendly_melee_target(attacker_unit_data: Resource, target_unit_data: Resource) -> bool:
	if attacker_unit_data == null:
		return false
	if KeywordSystem.has(attacker_unit_data, &"whip_of_god"):
		return true
	if KeywordSystem.has(attacker_unit_data, &"torturer"):
		return not (target_unit_data != null and KeywordSystem.has(target_unit_data, &"demonic"))
	return false

## Saldırının geçerli olup olmadığını kontrol eder.
## Döndürür: "" (geçerli) veya hata mesajı (String)
## P2-8: Saldırı için TEK doğrulama kaynağı. unit.server_request_attack_action bunu çağırıp
## sonuca göre erken döner (artık inline menzil/LoS/Hide/etkileşim tekrarı YOK). Boş "" = geçerli;
## aksi halde hata mesajı döner (ve loglanır). Sıra: hedef → dost/menzil → silah kullanılabilirliği
## (angaje/tekrar/tur + Assault etkileşim kuralı, tek kaynak can_use_attack) → LoS/Hide.
## (Eski "CUMBERSOME silah Dash sonrası kullanılamaz" kuralı compendium'da YOK — keyword.md'de
## Cumbersome yalnız "iki el gerektirir" der; Adım 5'te kaldırıldı.)
static func validate_attack(attacker, atk: Resource, enemy, dist: float) -> String:
	var err := ""
	if atk == null:
		err = "Geçersiz saldırı."
	elif not is_instance_valid(enemy):
		err = "Geçersiz hedef."
	elif enemy.current_health <= 0:
		err = "Hedef zaten Savaş Dışı."
	else:
		var is_melee: bool = atk.attack_type == "MELEE"
		var allow_friendly_target: bool = is_melee \
			and allows_friendly_melee_target(attacker.unit_data, enemy.unit_data)
		if enemy.owner_id == attacker.owner_id and not allow_friendly_target:
			err = "Dost hedefe saldırılamaz."
		elif dist > atk.attack_range + GameState.ATTACK_RANGE_TOLERANCE:
			err = "Menzil dışında! Mesafe: %.1f, Menzil: %.1f" % [dist, atk.attack_range]
		elif not attacker.can_use_attack(atk):
			# angaje/tekrar/tur kısıtı + Assault↔Charge/Fight etkileşim kuralı (compendium). Panel,
			# hedef vurgusu ve has_any_remaining_action ile AYNI kaynak → tutarlılık.
			err = "Bu saldırı şu an kullanılamaz (angaje/tekrar/Assault etkileşim kuralı)."
		elif not is_melee and KeywordSystem.has(atk, &"heavy") \
				and not (attacker.unit_data and KeywordSystem.negates(attacker.unit_data, &"heavy")) \
				and HEAVY_EXCLUDED_ACTIONS.any(func(a): return attacker.actions_taken.has(a)):
			err = "HEAVY silah/grenade ile aynı aktivasyonda Move/Charge/Retreat/Dash sonrası saldırılamaz."
		elif attacker.get_line_of_sight_status(enemy).get("is_blocked", false):
			# Görüş hattı HER saldırıda gerekir — melee-attacks.md: "The target must be within 1"
			# of the attacking model in its Line of Sight." (önceden yalnız menzilliye bakılıyordu)
			err = "Görüş hattı tamamen kapalı."
		elif not is_melee and enemy.has_method("is_untargetable_by") and enemy.is_untargetable_by(attacker):
			err = "Hedef saklanıyor (Hide)."

	if err != "":
		GameLogger.log_warn("Saldırı doğrulama başarısız (%s -> %s): %s" % [attacker.display_name, enemy.display_name if is_instance_valid(enemy) else "Bilinmeyen", err], "COMBAT")
		return err

	GameLogger.log_info("Saldırı doğrulandı: %s -> %s (%s silahı ile, mesafe: %.1fm)" % [attacker.display_name, enemy.display_name, atk.attack_name, dist], "COMBAT")
	return ""

# ─────────────────────────────────────────────────────────────────────────────
# DOST ATEŞİ — Angaje hedefe menzilli ateş
# ─────────────────────────────────────────────────────────────────────────────

## Angaje düşmana ateş edildiğinde zar at, dost ateşi olursa hedefi değiştir.
## Döndürür: gerçek hedef unit (değişmiş olabilir)
static func resolve_friendly_fire_check(attacker, enemy):
	# Hedefin ENGAGE_RANGE'i içinde saldıranın kendi dostlarından biri var mı? (Dost ateşi riski)
	var friendly_model = UnitQuery.nearest(
		UnitQuery.within(UnitQuery.allies_of(attacker), enemy.global_position,
			GameState.ENGAGE_RANGE),
		enemy.global_position)

	if is_instance_valid(friendly_model):
		GameLogger.log_warn("Dost birime (%s) yakın olan düşmana (%s) ateş ediliyor! Dost ateşi zar kontrolü..." % [friendly_model.display_name, enemy.display_name], "COMBAT")
		var roll: int = randi_range(1, 6)
		DiceManager.show_dice_bar_ui.emit([roll], 1, true, 0, roll, "d6")
		if roll <= 3:
			# NOT: Bu kurallara-uygun, beklenen bir oyun olayıdır (compendium'un zar-bazlı dost
			# ateşi mekaniği) — bir yazılım hatası DEĞİLDİR. log_error() yerine log_warn() kullanılır
			# (ERROR seviyesi gerçek kod/mantık hatalarına ayrılmalı, log tarama/izleme araçlarının
			# bu normal oyun olayını yanlışlıkla bir bug sanmaması için).
			GameLogger.log_warn("Dost Ateşi gerçekleşti! Mermi %s dost birimine isabet etti (Zar: %d)!" % [friendly_model.display_name, roll], "COMBAT")
			return friendly_model
		else:
			GameLogger.log_info("Dost ateşi olmadı. Mermi düşman %s hedefine yöneldi (Zar: %d)." % [enemy.display_name, roll], "COMBAT")

	return enemy

# ─────────────────────────────────────────────────────────────────────────────
# SENKRON YARDIMCILARI
# ─────────────────────────────────────────────────────────────────────────────

## Hedef birimin durumunu tüm istemcilere senkronize eder.
## unit.gd'deki tekrar eden senkronizasyon kodunu tek yere toplar.
static func sync_target_health(target, play_shake: bool = false) -> void:
	if not is_instance_valid(target):
		return
	if target.multiplayer.has_multiplayer_peer():
		target.rpc("sync_health_states",
			target.current_health, target.is_down,
			target.blood_markers, target.blessing_markers, target.infection_markers, play_shake)
	else:
		target.sync_health_states(
			target.current_health, target.is_down,
			target.blood_markers, target.blessing_markers, target.infection_markers, play_shake)
