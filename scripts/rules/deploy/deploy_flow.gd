## YERLEŞTİRME (DEPLOY) DOĞRULAMA ZİNCİRİ — 16 kapının TEK sahibi.
##
## `game.gd::request_deploy_unit` 292 satırlık tek bir prosedürdü: aşama, bütçe, roster üyeliği,
## Battlekit limiti, loadout geçerliliği, navigasyon, saha seçimi, Infiltrator/Automaton Destrier
## özel yerleşimleri, yakınlık, Court Wretched oranı, Legionnaire oranı, Elite tavanı, Order of
## the Fly, Availability... hepsi arka arkaya. Hangi kuralın hangi sırada çalıştığını görmek için
## 292 satırı okumak gerekiyordu ve hiçbir kapı izole test edilemiyordu.
##
## Artık `validate()` okunduğunda TÜM kural listesi ve SIRASI tek ekranda görünüyor; her kapı
## kendi adlandırılmış fonksiyonunda ve tek tek sınanabiliyor.
##
## KAPI SÖZLEŞMESİ: `_gate_*(req) -> String` — "" = geçerli, dolu = `DeployValidator.REASON_*`.
## Bazı kapılar `req`i KASITLI olarak değiştirir (konum hizalama, saha ataması); her biri
## kendi doküman satırında bunu belirtir.
##
## YENİ KURAL EKLEME: yeni bir `_gate_*` fonksiyonu yaz + `validate()`e 1 satır ekle.
## `game.gd`ye dokunulmaz.
class_name DeployFlow

## Navigasyon hizalamasının kabul ettiği azami sapma (inç). Bundan uzağa tıklamak = harita dışı.
const NAV_SNAP_TOLERANCE := 2.5
## Infiltrator / Automaton Destrier'in düşmana asgari uzaklığı (compendium).
const FREE_DEPLOY_MIN_ENEMY_DIST := 8.0
## Automaton Destrier'in "harita kenarı" şeridi (compendium: 1").
const EDGE_TOLERANCE := 1.0
## RAW'daki 1" şerit fare ile piksel-hassasiyeti gerektiriyordu (kullanıcı 3 kez üst üste ret
## alıp pes etti). Kural DEĞİŞMİYOR — yalnız tıklama toleransı, `resolve_nav_target`ın hareket
## hedefini en yakın geçerli noktaya hizalamasıyla AYNI ilkeyle genişletiliyor.
const EDGE_SNAP_RADIUS := 12.0
## İki model arasındaki asgari yerleşim mesafesi.
const MIN_UNIT_SPACING := 2.0

# ─────────────────────────────────────────────────────────────────────────────
#  GİRİŞ NOKTASI
# ─────────────────────────────────────────────────────────────────────────────

## İstek bağlamını kurar. Erken (kapılardan ÖNCE) reddedilirse ret sebebini `req` yerine
## doğrudan döndürür; `req` null kalır.
## Döner: { "req": DeployRequest|null, "reason": String }
static func build(sender_id: int, real_sender_id: int, unit_data_path: String,
		target_pos: Vector3, loadout_index: int, map_rid: RID) -> Dictionary:
	var req := DeployRequest.new()
	req.sender_id = sender_id
	req.real_sender_id = real_sender_id
	req.unit_data_path = unit_data_path
	req.target_pos = target_pos
	req.loadout_index = loadout_index
	req.map_rid = map_rid

	req.unit_data = load(unit_data_path)
	if req.unit_data == null:
		GameLogger.log_error("Geçersiz birim veri yolu: " + unit_data_path, "GAME")
		return {"req": null, "reason": DeployValidator.REASON_WRONG_FACTION}

	req.player_faction = GameState.get_faction_for_player(sender_id)
	return {"req": req, "reason": ""}

## TÜM kapıları SIRAYLA çalıştırır. Döner: "" = yerleştirilebilir, dolu = `REASON_*`.
##
## SIRA ANLAMLIDIR: ucuz/kesin kontroller önce (aşama, bütçe), konum çözümlemesi ortada
## (sonraki kapılar hizalanmış `closest_pos`u okur), roster oranları sonda.
static func validate(req: DeployRequest) -> String:
	var gates: Array[Callable] = [
		_gate_phase,
		_gate_deploy_budget_remaining,
		_gate_faction_selected,
		_gate_roster_membership,
		_gate_loadout_availability,
		_gate_resolve_loadout,        # ← ÇÖZÜMLER: bundan sonrası resolved_data okur
		_gate_affordable,
		_gate_loadout_valid,
		_gate_kit_limits,
		_gate_nav_snap,               # ← HİZALAR: closest_pos'u yazar
		_gate_assign_deploy_side,     # ← YAN ETKİ: ilk yerleşim sahayı belirler, asla reddetmez
		_gate_placement,              # ← Infiltrator / Automaton Destrier / senaryo bölgesi
		_gate_unit_spacing,
		_gate_court_wretched_ratio,
		_gate_legionnaire_ratio,
		_gate_elite_cap,
		_gate_order_of_the_fly,
		_gate_availability_max,
	]
	for gate in gates:
		var reason: String = gate.call(req)
		if reason != "":
			return reason
	return ""

# ─────────────────────────────────────────────────────────────────────────────
#  KAPILAR — akış
# ─────────────────────────────────────────────────────────────────────────────

static func _gate_phase(req: DeployRequest) -> String:
	if GameState.game_phase == GameState.GamePhase.DEPLOYMENT:
		return ""
	GameLogger.log_warn("Oyuncu %d geçersiz aşamada yerleşim yapmaya çalıştı." % req.sender_id, "GAME")
	return DeployValidator.REASON_PHASE

static func _gate_deploy_budget_remaining(req: DeployRequest) -> String:
	if GameState.can_player_deploy_more(req.sender_id):
		return ""
	GameLogger.log_warn("Oyuncu %d yerleşim hakkı (puan/limit) dolmasına rağmen yerleşim yapmaya çalıştı." \
		% req.sender_id, "GAME")
	return DeployValidator.REASON_POINTS_FULL

static func _gate_faction_selected(req: DeployRequest) -> String:
	if req.player_faction != null:
		return ""
	GameLogger.log_warn("Oyuncu %d faksiyon seçmeden yerleşim yapmaya çalıştı." % req.sender_id, "GAME")
	return DeployValidator.REASON_NO_FACTION

## ROSTER ÜYELİĞİ — `unit_data.faction_id` eşitliği YETERLİ DEĞİLDİR: compendium'da bir
## faction'ın Armoury/roster listesi başka bir faction'a "ev sahipliği" yapan mercenary birimleri
## de meşru şekilde içerir (örn. Combat Biologist'in faction_id'si iron_sultanate ama New
## Antioch'un resmi Mercenaries listesinde). Tek doğru kaynak: `available_units` üyeliği.
static func _gate_roster_membership(req: DeployRequest) -> String:
	if req.unit_data in req.player_faction.available_units:
		return ""
	GameLogger.log_warn("Oyuncu %d kendi faksiyon rosterinde olmayan bir birimi yerleştirmeye çalıştı (%s)." \
		% [req.sender_id, req.unit_data.unit_name], "GAME")
	return DeployValidator.REASON_WRONG_FACTION

## Battlekit/loadout seçiminin warband-genelindeki adet limiti.
static func _gate_loadout_availability(req: DeployRequest) -> String:
	if GameState.can_deploy_loadout(req.sender_id, req.unit_data, req.loadout_index):
		return ""
	GameLogger.log_warn("Oyuncu %d bu Battlekit seçeneğinin warband limitini aştı (%s, loadout %d)." \
		% [req.sender_id, req.unit_data.unit_name, req.loadout_index], "GAME")
	return DeployValidator.REASON_AVAILABILITY

## ÇÖZÜMLER (kapı değil, adım): seçilen Battlekit uygulanmış tanımı `req.resolved_data`ya yazar.
## Bundan SONRAKİ tüm kapılar (bütçe/yerleşim/oran) `resolved_data` okumalıdır — seçilen ekipman
## keyword'leri değiştirebilir.
static func _gate_resolve_loadout(req: DeployRequest) -> String:
	req.resolved_data = LoadoutResolver.resolve_loadout(req.unit_data, req.loadout_index)
	return ""

## BÜTÇE — Glory Point ve Dukat AYRI havuzlardır, biri diğerinin yerine GEÇMEZ
## (compendium: "Mercenaries cannot be purchased with Glory"). Karar `EconomyRules`ta.
static func _gate_affordable(req: DeployRequest) -> String:
	var ducats: int = GameState.player_deploy_pool[req.sender_id]
	var glory: int = GameState.player_glory_pool.get(req.sender_id, 0)
	if EconomyRules.can_afford(req.resolved_data, ducats, glory):
		return ""
	var is_glory: bool = EconomyRules.is_glory(req.resolved_data)
	GameLogger.log_warn("Oyuncu %d yetersiz kaynakla birim yerleştirmeye çalıştı (%s: %d %s, kalan: %d)." \
		% [req.sender_id, req.resolved_data.unit_name, req.resolved_data.cost,
			("Glory" if is_glory else "ducat"), (glory if is_glory else ducats)], "GAME")
	return DeployValidator.REASON_GLORY if is_glory else DeployValidator.REASON_BUDGET

static func _gate_loadout_valid(req: DeployRequest) -> String:
	var err: String = LoadoutResolver.validate_loadout(req.resolved_data)
	if err == "":
		return ""
	GameLogger.log_warn("Oyuncu %d geçersiz yüklemeli birim yerleştirmeye çalıştı (%s): %s" \
		% [req.sender_id, req.resolved_data.unit_name, err], "GAME")
	return DeployValidator.REASON_LOADOUT

## HAZIR KİT SİLAHLARI DA `LIMIT: N`'e TABİDİR (warband-battlekit.md: "Your Warband cannot have
## more than X pieces of the Battlekit"). Örn. New Antioch Machine Gun'u LIMIT: 2 — üçüncü
## hazır-MG'li MHI yerleştirilemez (önceden 3 MHI = 3 bedava MG'ydi).
static func _gate_kit_limits(req: DeployRequest) -> String:
	var uds: Array = [req.resolved_data]
	for u in UnitQuery.roster_of(req.sender_id):
		uds.append(u.unit_data)
	var counts: Dictionary = ArmouryRules.weapon_counts(uds, req.player_faction)
	for it in ArmouryRules.table_for(req.player_faction):
		if it.limit_per_warband > 0 and int(counts.get(it.item_id, 0)) > it.limit_per_warband:
			GameLogger.log_warn("Oyuncu %d: %s warband limiti (%d) aşılıyor." \
				% [req.sender_id, it.item_id, it.limit_per_warband], "GAME")
			return DeployValidator.REASON_AVAILABILITY
	return ""

## HİZALAR: tıklanan noktayı en yakın navigasyon noktasına oturtur (`closest_pos`).
## Sapma toleransı aşarsa harita dışına tıklanmıştır.
static func _gate_nav_snap(req: DeployRequest) -> String:
	req.closest_pos = NavigationServer3D.map_get_closest_point(req.map_rid, req.target_pos)
	if req.closest_pos.distance_to(req.target_pos) <= NAV_SNAP_TOLERANCE:
		return ""
	GameLogger.log_warn("Yerleşim başarısız: Oyuncu %d navigasyon alanı dışına tıklattı." \
		% req.sender_id, "GAME")
	return DeployValidator.REASON_NAV

## SAHA SEÇİMİ (kullanıcı isteği: ayrı bir "sahanı seç" adımı YOK): İLK yerleştirilen birim hangi
## bölgeye düşerse o oyuncunun sahası OTOMATİK o olur — deploy tıklaması AYNI ZAMANDA saha
## seçimidir. Hiçbir bölgeye düşmüyorsa (Infiltrator/Automaton Destrier'in serbest yerleşimi)
## saha ataması bu birimden ETKİLENMEZ, bir sonraki NORMAL yerleşimde belirlenir.
## ASLA REDDETMEZ — yalnız yan etki.
static func _gate_assign_deploy_side(req: DeployRequest) -> String:
	if GameState.zone_a_owner_id != 0 or ScenarioManager.active_scenario == null:
		return ""
	var pt := Vector2(req.closest_pos.x, req.closest_pos.z)
	if ScenarioManager.active_scenario.p1_deploy_zone.has_point(pt):
		RpcHelper.sync(GameState, "sync_deploy_side", [req.sender_id])
	elif ScenarioManager.active_scenario.p2_deploy_zone.has_point(pt):
		RpcHelper.sync(GameState, "sync_deploy_side", [2 if req.sender_id == 1 else 1])
	return ""

# ─────────────────────────────────────────────────────────────────────────────
#  KAPILAR — konum
# ─────────────────────────────────────────────────────────────────────────────

## Üç birbirini DIŞLAYAN yerleşim kuralından biri uygulanır:
##   • Infiltrator        → bölge dışı serbest, düşmandan 8"+, düşman Guard Dog'undan 12"+
##   • Automaton Destrier → bölge dışı serbest, harita kenarının 1" içi, düşmandan 8"+
##   • diğer herkes       → senaryonun kendi yerleşim bölgesi
static func _gate_placement(req: DeployRequest) -> String:
	# Senaryo Infiltrator istisnasını YASAKLAYABİLİR (örn. Claim No Man's Land: "Infiltrators
	# Not Allowed") — o zaman Infiltrator da sıradan birim gibi kendi bölgesine kurulur.
	var infiltrator_allowed: bool = ScenarioManager.active_scenario == null \
		or ScenarioManager.active_scenario.infiltrators_allowed

	if KeywordSystem.has(req.resolved_data, &"infiltrator") and infiltrator_allowed:
		return _placement_infiltrator(req)
	if KeywordSystem.has(req.resolved_data, &"automaton_destrier"):
		return _placement_automaton_destrier(req)
	if ScenarioManager.is_valid_deploy_position(req.sender_id, req.closest_pos):
		return ""
	GameLogger.log_warn("Yerleşim başarısız: Oyuncu %d senaryo yerleşim bölgesi dışına yerleşim denedi." \
		% req.sender_id, "GAME")
	return DeployValidator.REASON_ZONE

## Compendium: "set up anywhere... as long as it is out of line of sight of all enemies and is at
## least 8\" away from the closest enemy... Any INFILTRATORS that cannot be deployed in this way
## are instead deployed normally in their deployment zone." → kendi bölgesine normal yerleşim de
## her zaman geçerlidir. "Infiltrators are deployed after models that do not have this Keyword"
## → InfiltrationOrder (rakip normal modellerini bitirene kadar oyuncu bekler).
## YAN ETKİ: serbest yerleşim denemesi oyuncuyu Sızıcı aşamasına alır (InfiltrationOrder.mark_ready).
static func _placement_infiltrator(req: DeployRequest) -> String:
	if ScenarioManager.is_valid_deploy_position(req.sender_id, req.closest_pos):
		return ""
	if not InfiltrationOrder.may_infiltrate_now(req.sender_id):
		InfiltrationOrder.mark_ready(req.sender_id)
		GameLogger.log_info("Oyuncu %d normal modellerini bitirdi; Sızıcılar rakibin normal modellerinden sonra konuşlanır." \
			% req.sender_id, "GAME")
		return DeployValidator.REASON_INFILTRATOR_ORDER
	if not GameState.infiltration_ready.get(req.sender_id, false):
		InfiltrationOrder.mark_ready(req.sender_id)
	var enemies: Array = UnitQuery.where(UnitQuery.alive(),
		func(u): return u.owner_id != req.sender_id)
	var guard_dogs: Array = []
	for e in UnitQuery.with_keyword(enemies, &"guard_dog"):
		guard_dogs.append(e.global_position)

	# GUARD DOG (New Antioch): düşman Guard Dog'un 12" içine Infiltrator ile yerleşilemez.
	if MechanicsResolver.blocked_by_enemy_guard_dog(req.closest_pos, guard_dogs):
		GameLogger.log_warn("Yerleşim başarısız: düşman Guard Dog'un 12\" içine Infiltrator ile yerleşilemez.", "GAME")
		return DeployValidator.REASON_INFILTRATOR

	if not MechanicsResolver.infiltrator_placement_valid(
			req.closest_pos, req.enemy_positions(), FREE_DEPLOY_MIN_ENEMY_DIST):
		GameLogger.log_warn("Yerleşim başarısız: Infiltrator en yakın düşmana 8\" içine yerleşemez.", "GAME")
		return DeployValidator.REASON_INFILTRATOR
	if _seen_by_any(enemies, req.closest_pos):
		GameLogger.log_warn("Yerleşim başarısız: Infiltrator bir düşmanın görüş hattına yerleşemez.", "GAME")
		return DeployValidator.REASON_INFILTRATOR_LOS
	return ""

## `pos`a yerleşecek bir model, `enemies`ten herhangi birinin görüş hattında mı (5 örnek ışından
## en az biri açık)? Ateş etmedeki LoS ölçümüyle aynı (UnitCombat.blocked_samples).
static func _seen_by_any(enemies: Array, pos: Vector3) -> bool:
	if enemies.is_empty():
		return false
	var space = enemies[0].get_world_3d().direct_space_state
	var excludes: Array = []
	for u in UnitQuery.all():
		excludes.append(u.get_rid())
	for e in enemies:
		if UnitCombat.blocked_samples(space, e.global_position, pos, excludes) < UnitCombat.SAMPLE_COUNT:
			return true
	return false

## HİZALAYABİLİR: tıklama kenara makul yakınsa `closest_pos`u en yakın kenar şeridine oturtur.
static func _placement_automaton_destrier(req: DeployRequest) -> String:
	var enemies: Array = req.enemy_positions()
	if MechanicsResolver.automaton_destrier_placement_valid(
			req.closest_pos, GameState.battlefield_bounds, EDGE_TOLERANCE,
			enemies, FREE_DEPLOY_MIN_ENEMY_DIST):
		return ""

	var snapped = MechanicsResolver.automaton_destrier_snap_edge_position(
		req.closest_pos, GameState.battlefield_bounds, EDGE_TOLERANCE, EDGE_SNAP_RADIUS)
	if snapped != null:
		var snapped_nav: Vector3 = NavigationServer3D.map_get_closest_point(req.map_rid, snapped)
		if snapped_nav.distance_to(snapped) <= NAV_SNAP_TOLERANCE \
				and MechanicsResolver.automaton_destrier_placement_valid(
					snapped_nav, GameState.battlefield_bounds, EDGE_TOLERANCE,
					enemies, FREE_DEPLOY_MIN_ENEMY_DIST):
			req.closest_pos = snapped_nav
			return ""

	GameLogger.log_warn("Yerleşim başarısız: Automaton Destrier harita kenarının 1\" içine ve düşmandan 8\"+ uzağa yerleşmeli.", "GAME")
	return DeployValidator.REASON_AUTOMATON_DESTRIER

static func _gate_unit_spacing(req: DeployRequest) -> String:
	var occupied: Array = []
	for u in UnitQuery.all():
		occupied.append(u.global_position)
	if not DeployValidator.too_close_to_any(req.spawn_position(), occupied, MIN_UNIT_SPACING):
		return ""
	GameLogger.log_warn("Yerleşim başarısız: Başka bir birime çok yakın konum.", "GAME")
	return DeployValidator.REASON_PROXIMITY

# ─────────────────────────────────────────────────────────────────────────────
#  KAPILAR — roster oranları
#  (Hepsi ROSTER sayar: Savaş Dışı modeller de warband'e dâhildir — bkz. UnitQuery.roster_of.)
# ─────────────────────────────────────────────────────────────────────────────

## COURT WRETCHED: "Availability: Must be outnumbered by models with the Keyword DEMONIC."
## Bu birim yerleşince DEMONIC sayısı Wretched sayısını KESİN aşmalı (eşitlik yetmez).
## Yalnız `unit_name` string eşleşmesine güvenmemek için jenerik bir keyword ile işaretli.
static func _gate_court_wretched_ratio(req: DeployRequest) -> String:
	if not KeywordSystem.has(req.resolved_data, &"outnumbered_by_demonic_required"):
		return ""
	var roster: Array = UnitQuery.roster_of(req.sender_id)
	var demonic: int = UnitQuery.with_keyword(roster, &"demonic").size()
	var wretched: int = UnitQuery.with_keyword(roster, &"outnumbered_by_demonic_required").size()
	if MechanicsResolver.court_wretched_deploy_allowed(demonic, wretched + 1):
		return ""
	GameLogger.log_warn("Yerleşim başarısız: Wretched, Demonic modellerce sayıca aşılmalı (Demonic: %d, Wretched (bu dahil): %d)." \
		% [demonic, wretched + 1], "GAME")
	return DeployValidator.REASON_RATIO

## HERETIC LEGIONNAIRE: "You cannot upgrade a Heretic Trooper if doing so would result in there
## being more Heretic Legionnaires in your Warband than there are Heretic Troopers."
static func _gate_legionnaire_ratio(req: DeployRequest) -> String:
	if not KeywordSystem.has(req.resolved_data, &"legionnaire_upgrade"):
		return ""
	var same_name: Array = UnitQuery.where(UnitQuery.roster_of(req.sender_id),
		func(u): return u.unit_data != null and u.unit_data.unit_name == req.unit_data.unit_name)
	var legionnaires: int = UnitQuery.with_keyword(same_name, &"legionnaire_upgrade").size()
	var troopers: int = same_name.size() - legionnaires
	if MechanicsResolver.heretic_legionnaire_upgrade_allowed(troopers, legionnaires + 1):
		return ""
	GameLogger.log_warn("Yerleşim başarısız: Legionnaire sayısı Trooper sayısını aşamaz (Trooper: %d, Legionnaire (bu dahil): %d)." \
		% [troopers, legionnaires + 1], "GAME")
	return DeployValidator.REASON_LEGIONNAIRE_RATIO

## MAXIMUM ELITES (recruit-your-warband.md): "A Warband can never include more than 6 models with
## the [Elite] Keyword." TÜM faksiyonlar için geçerli GLOBAL kural. Karar `RosterRules`ta.
static func _gate_elite_cap(req: DeployRequest) -> String:
	if not KeywordSystem.has(req.resolved_data, &"elite"):
		return ""
	var elites: int = UnitQuery.with_keyword(UnitQuery.roster_of(req.sender_id), &"elite").size()
	if RosterRules.elite_cap_ok(elites + 1):
		return ""
	GameLogger.log_warn("Yerleşim başarısız: [Elite] tavanı aşıldı (max %d, bu dahil %d)." \
		% [RosterRules.ELITE_MAX, elites + 1], "GAME")
	return DeployValidator.REASON_ELITE_CAP

## THE ORDER OF THE FLY (cult-of-the-black-grail.md): seçilen liderlik dalı Lord of Tumours /
## Plague Knight adet tavanlarını belirler.
static func _gate_order_of_the_fly(req: DeployRequest) -> String:
	if req.unit_data.faction_id != &"cult_of_the_black_grail":
		return ""
	var name: String = req.unit_data.unit_name
	if name != "Lord of Tumours" and name != "Plague Knight":
		return ""

	var roster: Array = UnitQuery.where(UnitQuery.roster_of(req.sender_id),
		func(u): return u.unit_data != null)
	var lords: int = UnitQuery.where(roster,
		func(u): return u.unit_data.unit_name == "Lord of Tumours").size()
	var knights: int = UnitQuery.where(roster,
		func(u): return u.unit_data.unit_name == "Plague Knight").size()
	if name == "Lord of Tumours":
		lords += 1
	else:
		knights += 1

	var choice: StringName = req.player_faction.leader_choice \
		if ("leader_choice" in req.player_faction) else &""
	if RosterRules.order_of_the_fly_allowed(choice, lords, knights):
		return ""
	GameLogger.log_warn("Yerleşim başarısız: Order of the Fly tavanı aşıldı (dal: %s, Lord: %d, Knight: %d)." \
		% [String(choice), lords, knights], "GAME")
	return DeployValidator.REASON_ORDER_OF_FLY

## Bu birim tipinden warband'da en fazla `availability_max` adet.
static func _gate_availability_max(req: DeployRequest) -> String:
	if GameState.can_deploy_unit_type(req.sender_id, req.unit_data):
		return ""
	GameLogger.log_warn("Yerleşim başarısız: '%s' için Availability limiti aşıldı (max %d)." \
		% [req.unit_data.unit_name, req.unit_data.availability_max], "GAME")
	return DeployValidator.REASON_AVAILABILITY
