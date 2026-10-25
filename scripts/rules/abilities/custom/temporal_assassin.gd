## TEMPORAL ASSASSIN (Zamanı Böl) — Sultanate Assassin
##
## Yetenek handler'ı — sözleşme: `apply(ctx: AbilityContext) -> bool`
## (dönüş: `end_activation`). Kayıt: `abilities/ability_registry.gd`.
##
## Bu dosya `ability_executor.gd`den çıkarıldı: her yeni birime özel yetenek
## oraya bir `match` dalı daha ekliyordu ve dosya tavana dayanmıştı.
extends RefCounted

## TEMPORAL ASSASSIN — Sultanate Assassin (Iron Sultanate, P1-1). Normal Charge'ın YERİNE
## kullanılır: `target` (1. hedef) map_input'un normal ability-hedefleme akışıyla önceden seçildi
## (target_type="enemy" — bkz. .tres). Charge Bonus atılır, hedefe hücum edilir, Fight action
## alınır; ardından oyuncudan HARİTADA TIKLAYARAK 2. bir düşman hedef seçmesi istenir
## (CombatChoice.request_enemy_unit_pick — hint kartı: TEMPORAL_ASSASSIN_PICK2), o hedefin 1"
## yanına ışınlanılır, AYNI silahla ikinci bir Fight action alınır (compendium: "must use the
## same Melee Weapon for both attacks, and cannot take a Fight Action later in the same
## Activation" — actions_taken.append("melee") bunu unit_actions.can_perform_action ile doğal
## olarak sağlar).
## Basitleştirme: Shock Charge/Diving Charge senkronizasyonu yok (Sultanate Assassin'de bu
## keyword'ler zaten yok); hedefe menzil yetmezse normal "başarısız hücum" gibi maksimum mesafe
## koşulur ve zincir hiç tetiklenmez (compendium bu durumu tarif etmiyor — makul bir yorum).
static func apply(ctx: AbilityContext) -> bool:
	var caster = ctx.caster
	var target_a = ctx.target
	if not is_instance_valid(target_a) or target_a.current_health <= 0:
		return false
	var strike_weapon: Resource = MechanicsResolver.first_melee_attack(caster.unit_data)
	if strike_weapon == null:
		GameLogger.log_warn("[Temporal Assassin] %s: melee silahı yok, iptal." % caster.display_name, "GAME")
		return false

	# ── Charge Bonus (normal Charge ile aynı D6 + HEAVY istisnası) ──
	var bonus_dist: int = 0
	if not MechanicsResolver.has_unnegated_heavy_loadout(caster.unit_data):
		# roll_id FİLTRESİ (DiceRoller.perform_trench_roll ile AYNI desen) — bkz. Puppet Master notu.
		var is_roll_owner: bool = not caster.multiplayer.has_multiplayer_peer() or caster.multiplayer.is_server()
		if is_roll_owner:
			DiceManager.roll_dice(1)
		var expected_roll_id: int = DiceManager.current_roll_id if is_roll_owner else -1
		var d6_res = await DiceManager.dice_roll_completed
		while is_roll_owner and d6_res[2] != expected_roll_id:
			d6_res = await DiceManager.dice_roll_completed
		bonus_dist = d6_res[0]
		# UI: bu çıplak D6 atışı önceden zar-sonuç barı göstermiyordu (kullanıcı bildirimi:
		# "Zamanı Böl kullanınca zar düşünce zar paneli gelmiyor") — 3D animasyon oynuyordu
		# ama sonuç ekranda görünmüyordu. Mekanik/oran DEĞİŞMEDİ, yalnız görsel geri bildirim eklendi.
		# roll_type="d6" KULLANMA — bkz. yukarıdaki not (Puppet Master): o etiket "dost ateşi"
		# metnini tetikler, bu bonus-mesafe atışıyla ilgisi yok (kullanıcı bunu canlı yakaladı:
		# "zar küçük geldi, dost ateşi yazıyordu ama dost unit yoktu").
		DiceManager.show_dice_bar_ui.emit(d6_res[1], 1, true, 0, d6_res[0], "bonus_roll")
	var max_charge_dist: float = min(caster.speed + bonus_dist, GameState.CHARGE_DISTANCE_CAP)
	if caster.stood_up_this_activation:
		max_charge_dist = min((caster.speed * 0.5) + bonus_dist, GameState.CHARGE_DISTANCE_CAP)

	var map_rid: RID = caster.get_world_3d().navigation_map

	# INTERPOSING ENEMY (compendium: "do not count enemy models picked as targets for the
	# Charge as interposing enemy models" — yalnız target_a/target_b BİRBİRİ için istisna;
	# üçüncü bir düşman hâlâ normal hücum kuralına tabi: "you must choose the interposing enemy
	# model as the target of the charge, OR NOT MAKE THE CHARGE AT ALL"). target_b henüz
	# seçilmediğinden (bu projede 2. hedef ilk Fight'tan SONRA seçiliyor) tam yönlendirme yerine
	# basitleştirme: araya giren varsa hücum tamamen iptal edilir (RAW'ın izin verdiği 2. seçenek).
	var interposer = MechanicsResolver.charge_interposing_enemy(caster, target_a)
	if interposer != null:
		GameLogger.log_warn("[Temporal Assassin] %s: %s araya giriyor; hücum iptal." \
			% [caster.display_name, interposer.display_name], "GAME")
		return false

	var dist_a: float = caster.global_position.distance_to(target_a.global_position)
	if dist_a > max_charge_dist + GameState.CHARGE_REACH_TOLERANCE:
		var short_target: Vector3 = MovementHelper.get_clamped_target(map_rid, caster.global_position, target_a.global_position, max_charge_dist)
		caster.actions_taken.append("charge")
		caster.global_position = short_target
		RpcHelper.sync(caster, "client_update_move", [short_target])
		GameLogger.log_warn("[Temporal Assassin] %s hedefe ulaşamadı — başarısız hücum gibi davranıldı." % caster.display_name, "GAME")
		return false

	var pos_near_a: Vector3 = _adjacent_point(map_rid, caster.global_position, target_a.global_position)
	caster.actions_taken.append("charge")
	caster.global_position = pos_near_a
	RpcHelper.sync(caster, "client_update_move", [pos_near_a])
	GameLogger.log_info("[Temporal Assassin] %s zamanı böldü — %s'e hücum etti." % [caster.display_name, target_a.display_name], "GAME")

	await _temporal_assassin_fight(caster, target_a, strike_weapon)
	caster.actions_taken.append("melee")

	var target_b = await CombatChoice.request_enemy_unit_pick(caster, "TEMPORAL_ASSASSIN_PICK2",
		UnitQuery.enemies_of(caster).filter(func(e): return e != target_a))
	if target_b == null or not is_instance_valid(target_b) or target_b.current_health <= 0 or target_b == target_a:
		GameLogger.log_info("[Temporal Assassin] %s ikinci hedef seçmedi — yetenek burada bitti." % caster.display_name, "GAME")
		return false

	var pos_near_b: Vector3 = _adjacent_point(map_rid, caster.global_position, target_b.global_position)
	caster.global_position = pos_near_b
	RpcHelper.sync(caster, "client_update_move", [pos_near_b])
	GameLogger.log_info("[Temporal Assassin] %s ışınlandı — %s'e ikinci saldırı." % [caster.display_name, target_b.display_name], "GAME")

	await _temporal_assassin_fight(caster, target_b, strike_weapon)
	return false

## `to` hedefinin 1m yanında, `from`'dan gelen yaklaşım yönüne göre bir nokta (normal Charge'ın
## varış-konumu hesabıyla AYNI desen — unit.gd::server_request_charge).
static func _adjacent_point(map_rid: RID, from: Vector3, to: Vector3) -> Vector3:
	var path: PackedVector3Array = NavigationServer3D.map_get_path(map_rid, from, to, true)
	var dir: Vector3
	if path.size() >= 2:
		dir = (to - path[path.size() - 2]).normalized()
	else:
		dir = (to - from).normalized()
	return to - dir * MovementHelper.BASE_CONTACT

## Temporal Assassin'in iki Fight action'ı için ortak çözümleyici (DRY).
static func _temporal_assassin_fight(caster, enemy, weapon: Resource) -> void:
	var dist: float = caster.global_position.distance_to(enemy.global_position)
	var atk_ctx: Dictionary = DicePoolBuilder.build_attack_context(caster, weapon, enemy, dist)
	var modifier: int = DicePoolBuilder.compute_success_modifier(atk_ctx)
	var roll_res: Array = await caster.perform_unit_success_roll(modifier)
	var total: int = roll_res[0]
	if total >= 7:
		var is_crit: bool = total >= 12
		await enemy.resolve_injury_roll(caster, is_crit, true, 0, 0, weapon)
	else:
		GameLogger.log_info("[Temporal Assassin] %s ıskaladı (%d)." % [caster.display_name, total], "GAME")
		RiskyRolls.apply_failure(caster, total, RiskyRolls.weapon_is_risky(weapon), "Zamanı Böl")
