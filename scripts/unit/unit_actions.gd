## UnitActions
## Birimin can_perform_action ve diğer eylem kurallarını yöneten alt sınıf.
class_name UnitActions
extends RefCounted

var unit: CharacterBody3D

func _init(p_unit: CharacterBody3D):
	unit = p_unit

## ANNIHILATOR/SIX-ARMED MONSTROSITY için: unit_data.attacks[]'teki MELEE silah sayısı (saf yardımcı).
static func _melee_weapon_count(unit_data: Resource) -> int:
	var n := 0
	for atk_res in unit_data.attacks:
		if atk_res != null and atk_res.attack_type == "MELEE":
			n += 1
	return n

## SIX-ARMED MONSTROSITY (Amalgam, P1-1) için: unit_data.attacks[]'teki RANGED silah sayısı.
## Annihilator'ın (Desecrated Saint) melee-tekrar deseninin RANGED simetriği — compendium: "An
## Amalgam can take 1 Shoot Action per Activation with each Ranged Weapon it is equipped with."
static func _ranged_weapon_count(unit_data: Resource) -> int:
	var n := 0
	for atk_res in unit_data.attacks:
		if atk_res != null and atk_res.attack_type == "RANGED":
			n += 1
	return n

## BARBED EMBRACE (Goetic Warlock, P1-1): 1" içinde &"barbed_embrace" taşıyan CANLI bir düşman var mı?
func _enemy_barbed_embrace_nearby() -> bool:
	return UnitQuery.any(UnitQuery.with_keyword(
		UnitQuery.engaged_enemies(unit), &"barbed_embrace"))

## GOETIC SPELL bedel-öncesi kontrolü (Burning Inferno/Shadow Walker/Slavemaster): kullanıcı
## bildirimi "Burning Inferno kullanıyorum ama çalışmıyor gibi." Sahada TEK Blood Marker yoksa
## (oyunun başında hep böyledir) bu büyüler HER ZAMAN sessizce (yalnız bir toast ile) başarısız
## oluyordu — buton tıklanabilir kalıyordu ama sonucu HER SEFERİNDE aynıydı. AbilityExecutor.
## pay_goetic_cost ile AYNI kaynak (MechanicsResolver.total_available_goetic_blood); artık buton
## bu durumda hiç ÜRETİLMİYOR ("ölü buton" felsefesiyle tutarlı, bkz. is_actionable_ability).
static func _goetic_min_cost(action_name: String) -> int:
	match action_name:
		"burning_inferno": return 1
		"slavemaster": return 1
		"shadow_walker": return 2
		_: return 0

func _has_enough_goetic_blood(min_cost: int) -> bool:
	var field_sources: Array = []
	for u in UnitQuery.alive():
		field_sources.append({"blood_markers": u.blood_markers, "unit_data": u.unit_data})
	return MechanicsResolver.total_available_goetic_blood(field_sources) >= min_cost

func can_perform_action(action_name: String) -> bool:
	if unit.has_moved:
		return false
	if unit.owner_id != TurnManager.current_turn_player_id:
		return false
	# DEVOUR THE GUILTY (Sin Eater, P1-1): yutulmuş bir model "cannot be affected in any way or
	# carry out any Actions except as described" — YALNIZ "fight_devourer" (Sin Eater'a saldırı)
	# yapabilir, başka HİÇBİR aksiyon (Move/Charge/Retreat/Dash/normal Fight/Shoot/yetenek) YOK.
	if unit.devoured_by != null:
		return action_name == "fight_devourer" and not unit.actions_taken.has("fight_devourer") \
			and is_instance_valid(unit.devoured_by) and unit.devoured_by.current_health > 0
	if unit.actions_taken.has(action_name):
		# ANNIHILATOR (Desecrated Saint) / SIX-ARMED MONSTROSITY (Amalgam, P1-1, aynı keyword'ü
		# paylaşır): "1 Fight Action per Melee Weapon" VE (Amalgam'a özgü) "1 Shoot Action per
		# Ranged Weapon" — tek-kullanım kilidi taşıdığı silah sayısına kadar gevşer. Desecrated
		# Saint'in ranged silahı YOK, bu yüzden "shoot" dalı onun için hep no-op (regresyon yok).
		var is_annihilator_extra_fight: bool = action_name == "melee" and unit.unit_data != null \
			and KeywordSystem.has(unit.unit_data, &"annihilator") \
			and unit.actions_taken.count("melee") < _melee_weapon_count(unit.unit_data)
		var is_annihilator_extra_shoot: bool = action_name == "shoot" and unit.unit_data != null \
			and KeywordSystem.has(unit.unit_data, &"annihilator") \
			and unit.actions_taken.count("shoot") < _ranged_weapon_count(unit.unit_data)
		if not is_annihilator_extra_fight and not is_annihilator_extra_shoot:
			return false

	# HOLD YOUR FIRE: bir birim zorunlu aktivasyona kilitlendiyse, o oyuncu YALNIZCA o
	# birimi aktive edebilir (baska birimiyle eylem yapamaz).
	if TurnManager.forced_next_activator != "" and TurnManager.forced_next_activator != unit.name:
		var forced = GameState.units.get(TurnManager.forced_next_activator)
		if is_instance_valid(forced) and forced.owner_id == unit.owner_id:
			return false

	# Down birim: Diğer tüm eylemler engellenir
	if unit.is_down:
		return false

	# NO RETREAT (Red Brigade: Crimson Communicant, Attack/Guard/Mercy/Trench Dog): bu birimler
	# hiçbir zaman Retreat eylemi yapamaz (compendium: "cannot take a Retreat Action unless a
	# special rule forces them to do so").
	if action_name == "retreat" and unit.unit_data != null and KeywordSystem.has(unit.unit_data, &"no_retreat"):
		return false

	# BARBED EMBRACE (Goetic Warlock, P1-1): "An enemy model within 1" of a Goetic Warlock cannot
	# take a Retreat Action."
	if action_name == "retreat" and _enemy_barbed_embrace_nearby():
		return false

	# DEMONIC AURA — LUST (Court, Desecrated Saint): "Düşman modeller 3\" içinde Charge yapamaz."
	if action_name == "charge" and MechanicsResolver.is_in_demonic_aura(unit, &"lust_aura"):
		return false

	# DEMONIC AURA — GLUTTONY (Court, Desecrated Saint): "Düşman modeller 3\" içinde iyileşme alamaz."
	# Treat/Laying on Hands TEDAVi yapan birimleri değil, HEDEFİ engeller — bu kontrol hedef
	# tarafında (ability_executor._validate) uygulanmalı, buradan değil. Ama hedef için ayrı
	# bir can_be_healed() fonksiyonu yok, o yüzden ability_executor'da uygulanacak.

	# WRATH KISITLAMASI (Court, Praetor): "Praetors from a Warband dedicated to Wrath can have
	# only 1 Goetic Power." Praetor'un (is_leader + Court) 2. Goetic Power'ı (Burning Inferno)
	# Wrath'ta engellenir — sadece Slavemaster (10 puan) kalır.
	if action_name == "burning_inferno" and unit.unit_data != null \
			and unit.unit_data.is_leader \
			and unit.unit_data.faction_id == &"court_of_seven_headed_serpent":
		var faction = GameState.get_faction_for_player(unit.owner_id)
		if faction != null and faction.selected_sin == &"wrath":
			return false

	# GOETIC SPELL bedel-öncesi kontrolü (bkz. yukarıdaki _has_enough_goetic_blood notu):
	# oyunun başında (kimse yara almadan) sahada hiç Blood Marker yoksa bu büyüler HER ZAMAN
	# başarısız olurdu — buton artık bu durumda hiç üretilmiyor.
	var goetic_min_cost: int = _goetic_min_cost(action_name)
	if goetic_min_cost > 0 and not _has_enough_goetic_blood(goetic_min_cost):
		return false

	# DIGNIFIED CONDUCT (Witchburner): "This model cannot take a Dash Action."
	if action_name == "dash" and unit.unit_data != null and KeywordSystem.has(unit.unit_data, &"dignified_conduct"):
		return false

	var engaged: bool = unit.is_engaged()

	# Angaje durumu kısıtlamaları — temel eylemler
	if engaged:
		# UNSTOPPABLE (Amalgam, P1-1): "an Amalgam can take a Move or Charge Action if all enemy
		# models within 1" of it are mounted on bases of 32mm or less." Basitleştirme (dokümante,
		# Pin/Six-Armed Monstrosity ile AYNI aile): taban-boyutu şartı taşınmıyor — Unstoppable
		# taşıyan bir birim için bu istisna KOŞULSUZ uygulanır (32mm filtresi olmadan).
		var unstoppable_exempt: bool = (action_name == "move" or action_name == "charge") \
			and unit.unit_data != null and KeywordSystem.has(unit.unit_data, &"unstoppable")
		# SLASHING ATTACK (Assassin's Dagger): "the Assassin can use a Dash Action to Retreat in the
		# same Activation" — bu Aktivasyonda saldırısı hedefe Kan İşareti koyduysa, angaje olsa bile
		# Dash isteyebilir VE onu izleyen kaçış hareketini ("move", is_dash_pending) yapabilir.
		var slashing_dash_exempt: bool = unit.slashing_attack_active \
			and (action_name == "dash" or (action_name == "move" and unit.is_dash_pending))
		if action_name in ["move", "charge", "dash", "shoot"] and not unstoppable_exempt and not slashing_dash_exempt:
			return false
	else:
		if action_name in ["retreat", "melee"]:
			return false

	# HEAVY (P0-5): bu aktivasyonda bir HEAVY Ranged/Grenade saldırısı yapıldıysa Move/Charge/
	# Retreat/Dash artık yapılamaz — kısıt simetriktir (bkz. CombatResolver.heavy_blocks_move_action).
	if CombatResolver.heavy_blocks_move_action(unit.has_heavy_shot, action_name):
		return false

	# Compendium (actions.md, Charge): Assault OLMAYAN bir Shoot yapıldıysa aynı aktivasyonda
	# Charge yapılamaz (bkz. CombatResolver.charge_blocked_by_shot — kısıt eskiden yalnız Fight
	# yönünde uygulanıyordu).
	if action_name == "charge" and CombatResolver.charge_blocked_by_shot(unit.has_non_assault_shot):
		return false

	# Birincil hareket (Move/Charge/Retreat): aktivasyon başına yalnızca BİRİ yapılabilir.
	# Dash BUNLARDAN BAĞIMSIZDIR (compendium Actions: "A Dash can be carried out in addition to…
	# a Move, Charge, or Retreat") ve ek bir hareket sağlar; bu yüzden mutex grubunda değildir
	# (kendi "aktivasyon başına bir" kuralı en üstteki actions_taken.has(action_name) ile sağlanır).
	var primary_moves := ["move", "charge", "retreat"]
	if action_name in primary_moves:
		for act in primary_moves:
			if unit.actions_taken.has(act):
				# Dash bekleyen "move" isteği = dash hareketi; normal move slotundan bağımsız izinli.
				if action_name == "move" and unit.is_dash_pending:
					continue
				return false

	# TEMPORAL ASSASSIN (Sultanate Assassin, P1-1): normal Charge'ın YERİNE geçer — hem
	# birincil-hareket slotunu (move/charge/retreat) hem Fight'ı (melee) tüketir, bu yüzden
	# ikisi de HENÜZ kullanılmamış olmalı (compendium: "has not already carried out a Fight
	# Action in its Activation").
	if action_name == "temporal_assassin":
		for act in ["move", "charge", "retreat", "melee"]:
			if unit.actions_taken.has(act):
				return false

	# CLAIM RELIQUARY (Relic Hunt senaryosu, scenarios/relic-hunt): "A model that is within 1" of
	# a Reliquary can take a Claim Reliquary Action." Bu, tek bir birimin abilities[]'ine değil,
	# AKTİF SENARYOYA bağlı evrensel bir eylem — bu yüzden abilities[] döngüsünden ÖNCE, ayrı bir
	# özel-durum olarak ele alınır (temporal_assassin ile aynı desen).
	if action_name == "claim_reliquary":
		if not (ScenarioManager.logic is RelicHuntLogic):
			return false
		return ScenarioManager.logic.find_claimable_reliquary(unit.global_position) != &""

	# ── FAKSİYON YETENEKLERİ (Dinamik — AbilityData.abilities[]) ────────────
	# Eğer action_name temel eylemlerden biri değilse, UnitData.abilities[]'i kontrol et.
	var base_actions := ["move", "charge", "retreat", "dash", "melee", "shoot"]
	if action_name not in base_actions:
		if unit.unit_data == null or unit.unit_data.abilities.is_empty():
			return false  # Bu birim hiç yetenek tanımlamamış
		for ability_res in unit.unit_data.abilities:
			var ab: AbilityData = ability_res as AbilityData
			if ab == null:
				continue
			if ab.action_key == action_name:
				# Yeteneğe özgü angaje kısıtlaması
				if ab.requires_not_engaged and engaged:
					return false
				if ab.requires_engaged and not engaged:
					return false
				return true
		return false  # Yetenek bu birimde tanımlı değil

	return true
