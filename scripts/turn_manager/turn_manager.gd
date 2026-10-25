extends Node

## Tur yöneticisi (Autoload).
## Alternatif Aktivasyon (Alternating Activation) tabanlı tur döngüsünü yönetir.
## Sunucu otoritesi ile çalışır.

signal turn_changed(active_player_id: int)
signal round_started(round_number: int)
## Compendium: Initiative sahibi ilk mi ikinci mi aktive olacağını seçer. Raund başında yayılır.
signal initiative_choice_required(winner_id: int)
signal phase_changed(phase: int)

## Tur fazlari (ust-bar gostergesi icin). Compendium: Initiative -> Activation -> Morale.
const PHASE_INITIATIVE := 0
const PHASE_ACTIVATION := 1
const PHASE_MORALE := 2
var current_phase: int = PHASE_ACTIVATION

func set_phase(p: int) -> void:
	current_phase = p
	phase_changed.emit(p)

## Mevcut fazın localization anahtarı — tek kaynak (top_bar.gd'nin eski özel _phase_name()'i
## ile round_medallion.gd/phase_indicator.gd'nin AYNI anda ayrı ayrı tanımlamasını önler; UI
## yeniden tasarımı (2026-07-18) birden fazla bileşenin AYNI faz adını göstermesini gerektirdi.
func phase_display_key() -> String:
	match current_phase:
		PHASE_INITIATIVE: return "PHASE_INITIATIVE"
		PHASE_MORALE: return "PHASE_MORALE"
		_: return "PHASE_ACTIVATION"


var current_turn_player_id: int = 0
var current_round: int = 1
var activated_units: Array = []
var initiative_winner_id: int = 0

signal player_shaken_changed(player_id: int, is_shaken: bool)

var player_starting_unit_counts: Dictionary = {
	1: 0,
	2: 0
}

## AWAITED (Ecclesiastic Prisoner, P1-1): "does not count towards the number of models... taken
## Out of Action for Morale Checks" — Martyrdom Device ile öldüğünde, oyuncunun morale-taban
## sayısından (player_starting_unit_counts) 1 düşürülür; böylece bu model hiç var olmamış gibi
## sayılır (hem standing hem initial'dan aynı anda çıkmış olur — "OOA sayılmaz" tam olarak budur).
func exempt_from_morale_count(player_id: int) -> void:
	if player_starting_unit_counts.has(player_id) and player_starting_unit_counts[player_id] > 0:
		player_starting_unit_counts[player_id] -= 1
		GameLogger.log_info("[Awaited] Oyuncu %d'nin morale-taban sayısı 1 azaltıldı (%d)." \
			% [player_id, player_starting_unit_counts[player_id]], "TURN")
var player_consecutive_morale_failures: Dictionary = {
	1: 0,
	2: 0
}
var player_shaken_state: Dictionary = {
	1: false,
	2: false
}
var forced_next_activator: String = ""

## WHIP OF GOD (Castigator, Trench Pilgrims) gibi yeteneklerin biriktirdiği,
## bir sonraki Morale Check'e eklenecek bonus Dice sayısı.
var pending_morale_bonus_dice: Dictionary = {
	1: 0,
	2: 0
}

func start_turns():
	GameLogger.log_info("Sıralı aktivasyon döngüsü başlatıldı. Başlangıç birimleri kaydediliyor.", "TURN")
	if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
		current_round = 1
		activated_units.clear()
		player_starting_unit_counts[1] = get_total_unit_count(1)
		player_starting_unit_counts[2] = get_total_unit_count(2)
		player_consecutive_morale_failures[1] = 0
		player_consecutive_morale_failures[2] = 0
		player_shaken_state[1] = false
		player_shaken_state[2] = false
		if multiplayer.has_multiplayer_peer():
			rpc("sync_shaken_states", player_shaken_state)
		start_new_round()

func start_new_round():
	if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
		# Her turun başında birimlerin has_moved ve eylemlerini temizle
		for u in UnitQuery.all():
			u.reset_turn_actions()
				
		activated_units.clear()
		
		# İnisiyatif belirle
		var init_winner = determine_initiative()
		initiative_winner_id = init_winner
		current_turn_player_id = init_winner
		
		# Hata Önleme: Eğer inisiyatifi kazanan oyuncunun hazır birimi yoksa sırayı diğerine devret
		var players = get_players()
		if players.size() >= 2:
			var p1 = players[0]
			var p2 = players[1]
			var ready_winner = get_ready_unit_count(current_turn_player_id)
			if ready_winner == 0:
				var other_player = p2 if current_turn_player_id == p1 else p1
				var ready_other = get_ready_unit_count(other_player)
				if ready_other > 0:
					GameLogger.log_info("[TurnManager] İnisiyatif kazanan oyuncu %d hazır birimi olmadığı için sıra oyuncu %d'ye geçti." % [current_turn_player_id, other_player], "TURN")
					current_turn_player_id = other_player
		
		GameLogger.log_info("Yeni raund başlatıldı: Raund %d | Aktif Sıra: Oyuncu %d | İnisiyatif Sahibi: Oyuncu %d" % [current_round, current_turn_player_id, initiative_winner_id], "TURN")
		RpcHelper.sync(self, "sync_round_state", [current_round, activated_units, current_turn_player_id, initiative_winner_id])

		# Compendium: Initiative sahibi ilk/ikinci seçer. Her iki oyuncunun da hazır birimi
		# varsa seçim sun (aksi halde otomatik devam eder).
		var pl := get_players()
		var both_ready: bool = pl.size() >= 2 and get_ready_unit_count(pl[0]) > 0 and get_ready_unit_count(pl[1]) > 0
		if both_ready:
			RpcHelper.sync(self, "sync_initiative_prompt", [initiative_winner_id])

@rpc("authority", "call_local", "reliable")
func sync_initiative_prompt(winner_id: int):
	initiative_choice_required.emit(winner_id)

## P0-1: Blood/Blessing Marker Success Roll harcaması hangi oyuncunun rakip olduğunu bilmeli
## (Blood Marker'ı SADECE rakip harcayabilir, bkz. combat_choice.gd).
func get_opponent_id(pid: int) -> int:
	return _other_player(pid)

func _other_player(pid: int) -> int:
	var pl := get_players()
	if pl.size() < 2:
		return pid
	return pl[1] if pid == pl[0] else pl[0]

## Initiative sahibi ilk/ikinci aktive olmayı seçer. go_first=false ise sıra rakibe geçer.
func request_initiative_order(go_first: bool):
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		rpc_id(1, "server_choose_initiative_order", go_first)
	else:
		server_choose_initiative_order(go_first)

@rpc("any_peer", "reliable")
func server_choose_initiative_order(go_first: bool):
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	# Yalnız raund başında (hiç aktivasyon yapılmadan) geçerli
	if not activated_units.is_empty():
		return
	var sender := initiative_winner_id
	if multiplayer.has_multiplayer_peer():
		var real_sender = multiplayer.get_remote_sender_id()
		if real_sender == 0:
			real_sender = 1
		sender = NetworkManager.canonical_for_peer(real_sender)
	if sender != initiative_winner_id:
		return
	var new_first: int = initiative_winner_id if go_first else _other_player(initiative_winner_id)
	if get_ready_unit_count(new_first) == 0:
		return
	current_turn_player_id = new_first
	GameLogger.log_info("[Initiative] Oyuncu %d %s aktive olmayı seçti." \
		% [initiative_winner_id, ("ilk" if go_first else "ikinci")], "TURN")
	RpcHelper.sync(self, "sync_round_state", [current_round, activated_units, current_turn_player_id, initiative_winner_id])

## İnisiyatif: kural `InitiativeRules` modülünde (saf + test edilebilir); burada yalnız sahadaki
## sayım okunur ve delege edilir.
func determine_initiative() -> int:
	# KÖK NEDEN DÜZELTMESİ: p1/p2 HER ZAMAN kanonik 1/2'dir — get_players()'ın gerçek ENet peer
	# id'sini "oyuncu 2" sanan eski dalı kaldırıldı (bkz. get_players() yorumu).
	var count1 := get_total_unit_count(1)
	var count2 := get_total_unit_count(2)
	var winner: int = InitiativeRules.from_counts(count1, count2)
	if winner == 0:
		return InitiativeRules.roll_off()
	GameLogger.log_info("[Initiative] Oyuncu %d daha az ayakta modeli olduğu için (%d < %d) inisiyatifi aldı." \
		% [winner, mini(count1, count2), maxi(count1, count2)], "TURN")
	return winner

## Moral sayımının tabanı: hayatta VE ayakta (Down olmayan) birimler.
func get_total_unit_count(player_id: int) -> int:
	return UnitQuery.standing(UnitQuery.of_player(player_id)).size()

## Bu turda henüz aktive edilmemiş (Down olsa bile) hayatta birimler.
func get_ready_unit_count(player_id: int) -> int:
	return UnitQuery.where(UnitQuery.of_player(player_id), func(u): return not u.has_moved).size()

## KÖK NEDEN DÜZELTMESİ: bu fonksiyon önceden çevrimiçi modda NetworkManager.players'taki GERÇEK
## ENet peer id'sini "oyuncu 2" olarak döndürüyordu (host=1 sabit ama istemcinin gerçek id'si
## rastgele büyük bir sayıdır, ASLA "2" değil — empirik doğrulandı). Proje kesinlikle 2 oyunculu ve
## GameState'in TÜM sözlükleri (player_factions, player_deploy_pool, vb.) zaten kanonik {1,2} ile
## başlatılıyor — bu fonksiyon da her zaman kanonik [1, 2] döndürmeli, hotseat/çevrimiçi farkı yok.
func get_players() -> Array:
	return [1, 2]

@rpc("authority", "call_local", "reliable")
func sync_round_state(p_round: int, p_activated: Array, p_current_player: int, p_init_winner: int):
	current_round = p_round
	activated_units = p_activated
	current_turn_player_id = p_current_player
	initiative_winner_id = p_init_winner
	
	# Tüm birimlerin has_moved durumunu senkronize et
	for u in UnitQuery.all():
		var was_activated: bool = activated_units.has(u.name)
		u.has_moved = was_activated
		if not was_activated:
			u.actions_taken.clear()
			u.is_dash_pending = false
				
	GameState.deselect_unit()
	set_phase(PHASE_ACTIVATION)
	turn_changed.emit(current_turn_player_id)
	round_started.emit(current_round)

## "Aktivasyonu Bitir": seçili (aktive-edilmemiş, aktif oyuncuya ait) birimin aktivasyonunu
## bitirir. Compendium: pas geçme YOKTUR — hazır birimin varsa aktive etmen gerekir. Bu yüzden
## seçili aktif birim yokken sıra keyfî olarak devredilmez; oyuncu birim seçmeye yönlendirilir.
## (Güvenlik: bu oyuncunun hiç hazır birimi kalmadıysa sıra otomatik devredilir — soft-lock önleme.)
func end_turn():
	if not is_my_turn():
		return
	var u = GameState.selected_unit
	if u != null and is_instance_valid(u) and u.owner_id == current_turn_player_id and not u.has_moved:
		end_unit_activation(u, true)
		return
	# Kullanıcı bildirimi: "bazen tur atla diyorum atlamıyor." Oyuncu bir birimi aktive ettikten
	# (en az 1 aksiyon aldıktan) sonra seçimi bırakmış/başka bir birime (ör. düşmanı incelemeye)
	# tıklamış olabilir — bu durumda yukarıdaki dal hiç eşleşmez ve önceden yalnız SESSİZCE bir
	# log satırı yazılıp hiçbir şey olmuyordu (oyuncuya görünmeyen bir mesaj). Artık hâlâ YARIDA
	# (en az 1 aksiyon almış ama resmi olarak bitirmemiş) bir birim varsa, yeniden seçtirmeye
	# ZORLAMADAN doğrudan onun aktivasyonu bitirilir.
	var stuck_unit = MechanicsResolver.find_stuck_activation_unit(GameState.units, current_turn_player_id)
	if stuck_unit != null:
		end_unit_activation(stuck_unit, true)
		return
	if get_ready_unit_count(current_turn_player_id) == 0:
		select_next_activator()
	else:
		GameLogger.log_info("[TurnManager] Aktivasyonu bitirmek için önce kendi (aktive edilmemiş) biriminizi seçin.", "TURN")


## `natural` = birim eylemlerini tüketti veya oyuncu bitirdi; false = kural zorla bitirdi (Risky
## başarısızlığı, Reload...). Ayrım yalnız Fireteam için önemli (bkz. ActivationRules.partner_outcome).
func end_unit_activation(unit_node, natural: bool = false):
	if multiplayer.has_multiplayer_peer():
		rpc_id(1, "server_end_unit_activation", unit_node.name, natural)
	else:
		server_end_unit_activation(unit_node.name, natural)

## Seçilen birim, aktivasyonu süren birimle ortak aktive ediliyorsa bağı kurar (Fireteam /
## Faithful Followers). İstemci isteği sunucuda doğrulanır ve herkese yayınlanır.
func link_joint_if_needed(unit) -> void:
	var c = ActivationRules.committed_unit(GameState.units.values(), unit.owner_id)
	if c == null or c == unit or c.joint_partner == unit:
		return
	# Aktivasyon başı konumu (Faithful Followers 1") yalnız seçen makinede kayıtlı → isteğe eklenir.
	var start_pos: Vector3 = c.activation_start_pos if c.activation_start_pos is Vector3 else c.global_position
	if multiplayer.has_multiplayer_peer():
		rpc_id(1, "server_link_joint", c.name, unit.name, start_pos)
	else:
		server_link_joint(c.name, unit.name, start_pos)

@rpc("any_peer", "reliable")
func server_link_joint(a_name: String, b_name: String, start_pos: Vector3):
	var a = GameState.units.get(a_name)
	var b = GameState.units.get(b_name)
	if not is_instance_valid(a) or not RpcHelper.validate_rpc_request(self, a.owner_id):
		return
	if not (a.activation_start_pos is Vector3):
		a.activation_start_pos = start_pos
	var all_units: Array = GameState.units.values()
	if ActivationRules.joint_kind(a, b, all_units) == ActivationRules.JOINT_NONE:
		return
	var form: StringName = &""
	if a.fireteam_partner != b and ActivationRules.joint_kind(a, b, all_units) == ActivationRules.JOINT_FIRETEAM:
		form = ActivationRules.fireteam_form(a, b, all_units)
	RpcHelper.sync(self, "sync_joint_link", [a_name, b_name, form])

@rpc("authority", "call_local", "reliable")
func sync_joint_link(a_name: String, b_name: String, form: StringName):
	var a = GameState.units.get(a_name)
	var b = GameState.units.get(b_name)
	if is_instance_valid(a) and is_instance_valid(b):
		ActivationRules.apply_link(a, b, form)

@rpc("any_peer", "reliable")
func server_end_unit_activation(unit_name: String, natural: bool = false):
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
		
	var sender_id = current_turn_player_id
	if multiplayer.has_multiplayer_peer():
		var real_sender_id = multiplayer.get_remote_sender_id()
		if real_sender_id == 0:
			real_sender_id = 1
		sender_id = NetworkManager.canonical_for_peer(real_sender_id)

	if sender_id != current_turn_player_id:
		return
		
	if GameState.units.has(unit_name):
		var u = GameState.units[unit_name]
		if is_instance_valid(u) and u.owner_id == sender_id:
			# İdempotentlik: erken bitirilmiş aktivasyon (Eye of God vb.) ikinci kez bitirilirse
			# select_next_activator iki kez çalışıp sırayı geri çevirmesin.
			if u.has_moved:
				return
			u.has_moved = true
			GameLogger.log_info("%s aktivasyonu sona erdi (Sıra: Oyuncu %d)." % [u.display_name, sender_id], "TURN")
			if not activated_units.has(unit_name):
				activated_units.append(unit_name)
			RpcHelper.sync(u, "sync_action_state", [true])
			
			if forced_next_activator == unit_name:
				forced_next_activator = ""
				if multiplayer.has_multiplayer_peer():
					rpc("sync_forced_activator", "")

			# FIRETEAM / FAITHFUL FOLLOWERS ortak aktivasyonu (ActivationRules.partner_outcome).
			var partner = u.joint_partner
			match ActivationRules.partner_outcome(u, natural):
				&"end":
					partner.has_moved = true
					if not activated_units.has(partner.name):
						activated_units.append(partner.name)
					RpcHelper.sync(partner, "sync_action_state", [true])
					GameLogger.log_info("[Fireteam] %s aktivasyonu bitti → ortak aktive edilen %s de bitti." \
						% [u.display_name, partner.display_name], "TURN")
				&"continue":
					GameLogger.log_info("[Ortak Aktivasyon] %s aktivasyonuna devam ediyor." % partner.display_name, "TURN")
					return
				_:
					if is_instance_valid(partner) and not partner.has_moved:  # başlamamış eş ayrı aktive olur
						RpcHelper.sync(self, "sync_joint_link_clear", [partner.name])

	select_next_activator()

func select_next_activator():
	var players = get_players()
	# HOLD YOUR FIRE: bir birim zorunlu aktivasyona kilitlendiyse sira o birimin sahibine
	# gecer. Birim gecersiz/Down/aktive olmussa kilit temizlenir (soft-lock onlenir).
	if forced_next_activator != "":
		var fu = GameState.units.get(forced_next_activator)
		if not is_instance_valid(fu) or fu.current_health <= 0 or fu.is_down or fu.has_moved:
			forced_next_activator = ""
			if multiplayer.has_multiplayer_peer():
				rpc("sync_forced_activator", "")
		else:
			current_turn_player_id = fu.owner_id
			RpcHelper.sync(self, "sync_round_state", [current_round, activated_units, current_turn_player_id, initiative_winner_id])
			return
	if players.size() < 2:
		var ready_count = get_ready_unit_count(current_turn_player_id)
		if ready_count == 0:
			await run_morale_checks_phase()
			ScenarioManager.process_turn_end(current_round)
			if ScenarioManager.is_final_turn_reached(current_round):
				_end_game_by_scenario()
				return
			current_round += 1
			start_new_round()
		return
		
	var p1 = players[0]
	var p2 = players[1]
	
	var next_player = p2 if current_turn_player_id == p1 else p1
	
	var next_ready = get_ready_unit_count(next_player)
	var current_ready = get_ready_unit_count(current_turn_player_id)
	
	if next_ready > 0:
		current_turn_player_id = next_player
	elif current_ready > 0:
		# Diğer oyuncunun hazır piyonu kalmadıysa, mevcut oyuncu devam eder
		pass
	else:
		# Her iki oyuncunun da piyonları bittiyse tur biter (Morale fazı → senaryo puanlaması)
		await run_morale_checks_phase()
		# Senaryo: tur sonu VP puanlaması (sunucu otoritesi)
		ScenarioManager.process_turn_end(current_round)
		# Senaryo: tur limiti dolduysa oyunu VP ile bitir
		if ScenarioManager.is_final_turn_reached(current_round):
			_end_game_by_scenario()
			return
		current_round += 1
		start_new_round()
		return

	RpcHelper.sync(self, "sync_round_state", [current_round, activated_units, current_turn_player_id, initiative_winner_id])

## Compendium: Shaken orduda tum Success Roll'lar Risky sayilir.
func is_shaken(player_id: int) -> bool:
	return player_shaken_state.get(player_id, false)

## Senaryo tur limiti dolduğunda oyunu VP kazananıyla bitirir (0 = beraberlik).
func _end_game_by_scenario():
	var result: Dictionary = ScenarioManager.evaluate_end_of_game()
	var winner: int = result.get("winner", 0)
	GameLogger.log_info("[Scenario] Tur limiti (%d) doldu. Kazanan: Oyuncu %d | VP: %s" \
		% [ScenarioManager.get_turn_limit(), winner, str(result.get("vp", {}))], "TURN")
	if GameState.multiplayer.has_multiplayer_peer():
		GameState.rpc("sync_game_over", winner)
	else:
		GameState.sync_game_over(winner)

func is_my_turn() -> bool:
	if not multiplayer.has_multiplayer_peer():
		return true
	return NetworkManager.get_local_canonical_id() == current_turn_player_id

func perform_morale_check_roll(dice_modifier: int) -> int:
	var roll_res = await DiceRoller.perform_trench_roll(self, dice_modifier, 0, "morale")
	return roll_res[0]

## Compendium (Morale Phase): bir warband Morale Check yapmak ZORUNDADIR eğer
##   (a) modellerinin en az YARISI (yukarı yuvarlanmış) Down/OOA ise  → ayakta <= floor(N/2), VEYA
##   (b) ordu ZATEN Shaken ise (Shaken ordu ertesi tur, eşiğin altında olmasa bile yeniden test edilir).
## SAF fonksiyon (test edilebilir).
static func morale_must_check(initial: int, standing: int, was_shaken: bool) -> bool:
	if was_shaken:
		return true
	if initial <= 0:
		return false
	var threshold: int = initial - int(ceil(initial / 2.0))
	return standing <= threshold

## Black Grail faction kuralı: "Cult of the Black Grail'e karşı savaşmak dehşet vericidir —
## rakip, warband'ı Court VEYA Black Grail DEĞİLSE tüm Morale Check'lerine −1 DICE ekler."
## SAF fonksiyon (test edilebilir). checker_faction: kontrolü yapan oyuncunun faction_id'si;
## opponent_factions: rakip oyuncu(lar)ın faction_id'leri. Dönüş: morale dice modifikatörü (0 veya −1).
static func morale_fear_penalty(checker_faction: StringName, opponent_factions: Array) -> int:
	# Court ve Black Grail bu korkudan MUAFtır.
	if checker_faction == &"cult_of_the_black_grail" or checker_faction == &"court_of_seven_headed_serpent":
		return 0
	for f in opponent_factions:
		if f == &"cult_of_the_black_grail":
			return -1
	return 0

## Bir oyuncunun faction_id'sini döndürür. QA denetimi (2026-07-16): önceki sürüm bunu oyuncunun
## İLK birimi bulunan `unit_data.faction_id`'sinden TAHMİN EDİYORDU — paylaşılan mercenary
## birimlerinin (Combat Biologist/Communicant ATH/Mamluk Faris vb.) kendi `.tres`'lerindeki
## faction_id'si genelde "ev sahibi" faction'a hardcoded'dır (örn. combat_biologist.tres →
## iron_sultanate), o mercenary'yi BAŞKA bir faction (New Antioch gibi) deploy ettiğinde ve o
## oyuncunun ROSTERDE İLK birimi o mercenary ise yanlış faction dönerdi (Dread of the Plague gibi
## faction-scoped kuralları bozardı). Artık tek doğru kaynak: GameState.player_factions (oyuncunun
## faction-seçim ekranında seçtiği FactionData) — hiçbir birime bağımlı değil.
func _player_faction_id(player_id: int) -> StringName:
	var f = GameState.get_faction_for_player(player_id)
	if f != null and "faction_id" in f:
		return f.faction_id
	return &""

func run_morale_checks_phase():
	set_phase(PHASE_MORALE)
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return

	# P1-6: senaryo "moral testi yok" bayrağı (örn. Great War/Relic Hunt "To The Death!").
	# ScenarioData.special_rules — daha önce hiç okunmuyordu.
	if ScenarioManager.active_scenario != null \
			and bool(ScenarioManager.active_scenario.special_rules.get(&"skip_morale", false)):
		GameLogger.log_info("[Morale] Senaryo moral testini devre dışı bıraktı (skip_morale).", "TURN")
		return

	var players = get_players()
	for player_id in players:
		var total_standing = 0
		var total_initial = player_starting_unit_counts.get(player_id, 0)

		# Initial count not recorded yet, set it now
		if total_initial == 0:
			total_initial = get_total_unit_count(player_id)
			player_starting_unit_counts[player_id] = total_initial

		# Count alive units that are NOT Down
		total_standing = get_total_unit_count(player_id)

		var pct: int = int(float(total_standing) / float(total_initial) * 100.0) if total_initial > 0 else 0
		GameLogger.log_info("[Morale] Oyuncu %d — Ayakta: %d/%d (%%%d)" % [player_id, total_standing, total_initial, pct], "TURN")

		var was_shaken: bool = player_shaken_state.get(player_id, false)

		# Eşik altında DEĞİL ve zaten Shaken DEĞİLSE bu tur bir şey olmaz (durum korunur).
		if not morale_must_check(total_initial, total_standing, was_shaken):
			continue

		if was_shaken:
			GameLogger.log_warn("[Morale Phase] Oyuncu %d Sarsılmış (Shaken) — bu tur yeniden Moral Kontrolü zorunlu." % player_id, "TURN")
		else:
			GameLogger.log_warn("[Morale Phase] Oyuncu %d için Moral Kontrolü gerekli! (Kalan Ayakta: %d/%d)" % [player_id, total_standing, total_initial], "TURN")

		# Lider sahada mı? (+1 DICE) — FAZ 1: unit_data.is_leader flag'i
		var leader_alive: bool = UnitQuery.any(UnitQuery.where(
			UnitQuery.with_keyword(
				UnitQuery.standing(UnitQuery.of_player(player_id)), &"leader"),
			func(u): return u.unit_data.is_leader))

		var dice_mod = 0
		if leader_alive:
			dice_mod += 1
			GameLogger.log_info("[Morale Check] Lider sahada! Moral Kontrolüne +1 DICE eklendi.", "TURN")

		var bonus_dice: int = pending_morale_bonus_dice.get(player_id, 0)
		if bonus_dice > 0:
			dice_mod += bonus_dice
			GameLogger.log_info("[Morale Check] Whip of God: +%d DICE (biriktirilmiş) eklendi." % bonus_dice, "TURN")
		pending_morale_bonus_dice[player_id] = 0

		# DEMONIC AURA — PRIDE (Court of the Seven-Headed Serpent): "3\" içindeki düşman modellerin Willpower değeri 1 azalır."
		var in_pride_aura: bool = UnitQuery.any(UnitQuery.where(
			UnitQuery.standing(UnitQuery.of_player(player_id)),
			func(u): return MechanicsResolver.is_in_demonic_aura(u, &"pride_aura")))
		if in_pride_aura:
			dice_mod -= 1
			GameLogger.log_info("[Morale Check] Kibir (Pride) Aurası: -1 DICE.", "TURN")

		# BLACK GRAIL faction kuralı: rakip Black Grail ise (ve bu oyuncu Court/Black Grail değilse) −1 DICE.
		var checker_faction: StringName = _player_faction_id(player_id)
		var opp_factions: Array = []
		for pid in players:
			if pid != player_id:
				var of: StringName = _player_faction_id(pid)
				if of != &"":
					opp_factions.append(of)
		var fear_pen: int = morale_fear_penalty(checker_faction, opp_factions)
		if fear_pen != 0:
			dice_mod += fear_pen
			GameLogger.log_info("[Morale Check] Black Grail korkusu: %d DICE." % fear_pen, "TURN")

		var total_roll = await perform_morale_check_roll(dice_mod)

		if total_roll >= 7:
			player_consecutive_morale_failures[player_id] = 0
			player_shaken_state[player_id] = false
			if was_shaken:
				GameLogger.log_info("[Morale Check] Oyuncu %d Moral Kontrolünü GEÇTİ (%d) — artık Sarsılmış değil." % [player_id, total_roll], "TURN")
			else:
				GameLogger.log_info("[Morale Check] Oyuncu %d Moral Kontrolünü BAŞARIYLA GEÇTİ (%d >= 7)!" % [player_id, total_roll], "TURN")
			# GLORIOUS DEEDS (P1-5, Hold Your Ground): ilk geçen ordu.
			if ScenarioManager.logic != null:
				ScenarioManager.logic.on_morale_check_passed(player_id)
		elif was_shaken:
			# Compendium: Shaken bir ordu tekrar başarısız olursa KAÇAR ve oyunu anında kaybeder.
			# NOT: Bu kurallara-uygun, beklenen bir oyun sonucudur — bir yazılım hatası DEĞİLDİR.
			# log_error() yerine log_warn() (ERROR seviyesi gerçek kod/mantık hatalarına ayrılmalı).
			GameLogger.log_warn("[Morale Check] Oyuncu %d Sarsılmışken tekrar başarısız oldu (%d) — ordu kaçtı, oyun kaybedildi!" % [player_id, total_roll], "TURN")
			var winner_id: int = _other_player(player_id)
			if GameState.multiplayer.has_multiplayer_peer():
				GameState.rpc("sync_game_over", winner_id)
			else:
				GameState.sync_game_over(winner_id)
			return
		else:
			# SOUNDING THE RETREAT: oyuncu Shaken olmak yerine hemen kaçıp oyunu kaybetmeyi seçebilir.
			if await CombatChoice.request_sound_retreat(player_id):
				GameLogger.log_warn("[Morale Check] Oyuncu %d geri çekilme borusunu çaldı — ordu kaçtı, oyun kaybedildi." % player_id, "TURN")
				var flee_winner: int = _other_player(player_id)
				if GameState.multiplayer.has_multiplayer_peer():
					GameState.rpc("sync_game_over", flee_winner)
				else:
					GameState.sync_game_over(flee_winner)
				return
			# İlk başarısızlık → Sarsılmış (Shaken). Kayıp bir sonraki başarısızlıkta.
			player_shaken_state[player_id] = true
			player_consecutive_morale_failures[player_id] += 1
			GameLogger.log_warn("[Morale Check] Oyuncu %d Moral Kontrolünü BAŞARAMADI (%d < 7)! Ordu Sarsıldı (Shaken)." % [player_id, total_roll], "TURN")

	RpcHelper.sync(self, "sync_shaken_states", [player_shaken_state])


@rpc("authority", "call_local", "reliable")
func sync_shaken_states(p_shaken: Dictionary):
	player_shaken_state = p_shaken
	for pid in player_shaken_state:
		player_shaken_changed.emit(pid, player_shaken_state[pid])

@rpc("authority", "call_local", "reliable")
func sync_joint_link_clear(unit_name: String):
	var p = GameState.units.get(unit_name)
	if is_instance_valid(p):
		p.joint_partner = null

@rpc("authority", "call_local", "reliable")
func sync_forced_activator(p_forced: String):
	forced_next_activator = p_forced
