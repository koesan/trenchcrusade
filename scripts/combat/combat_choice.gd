extends Node

## Savaş sırasında oyuncu marker harcama kararlarını (Blessing/Blood/Bloodbath) yöneten autoload.
## Compendium: Blessing/Blood/Bloodbath harcaması oyuncu TERCİHİDİR (otomatik değil).
##
## Sunucu otoritesi resolve_injury_roll içinden `await request_*` çağırır; karar, ilgili marker'ın
## sahibi oyuncuya (offline'da yerel, MP'de o oyuncunun istemcisine) sorulur ve yanıt beklenir.
## GÜVENLİK: UI yoksa veya kayıtlı değilse anında varsayılan (harcama yok) döner — kilitlenme olmaz.

signal _response(req_id: int, value: int)

var _overlay = null
var _next_id: int = 0

## HUD, kendi marker-seçim overlay'ini burada kaydeder (her eş kendi overlay'ini kaydeder).
func set_overlay(o) -> void:
	_overlay = o

func _local_id() -> int:
	return NetworkManager.get_local_canonical_id() if multiplayer.has_multiplayer_peer() else 1

## Savunan oyuncuya Blessing harcamasını sorar (her biri -1 Injury Dice). Döner: harcanan adet.
func request_blessing_spend(defender, maxv: int) -> int:
	if maxv <= 0:
		return 0
	var v: int = await _ask(defender.owner_id, "blessing", defender.display_name, maxv, 0)
	return clampi(v, 0, maxv)

## Saldıran oyuncuya Blood harcamasını sorar. Döner: { spend:int, bloodbath:bool }.
## Değer -1 => Bloodbath seçildi; >=0 => o kadar Blood Marker harca (+injury dice).
func request_blood_spend(attacker, defender, maxv: int, bloodbath_cost: int) -> Dictionary:
	if maxv <= 0:
		return {"spend": 0, "bloodbath": false}
	var v: int = await _ask(attacker.owner_id, "blood", defender.display_name, maxv, bloodbath_cost)
	if v < 0:
		return {"spend": 0, "bloodbath": true}
	return {"spend": clampi(v, 0, maxv), "bloodbath": false}

## INFECTION MARKER (keyword.md, 2026-07-16 düzeltmesi): "INFECTION MARKERS can be used to
## modify dice rolls EXACTLY LIKE Blood Markers (i.e. Action rolls and injury rolls and used in
## Bloodbaths)." — request_blood_spend ile AYNI sözleşme, yalnız harcanan havuz infection_markers.
func request_infection_spend(attacker, defender, maxv: int, bloodbath_cost: int) -> Dictionary:
	if maxv <= 0:
		return {"spend": 0, "bloodbath": false}
	var v: int = await _ask(attacker.owner_id, "infection", defender.display_name, maxv, bloodbath_cost)
	if v < 0:
		return {"spend": 0, "bloodbath": true}
	return {"spend": clampi(v, 0, maxv), "bloodbath": false}

## P0-1: RAKİP oyuncuya, zar atan modelin Blood Marker'larını harcamayı sorar (her biri -1 Dice).
## Compendium (blood-markers.md): "your opponent can... add -1 Dice to the Success Roll."
## Bloodbath eşdeğeri YOK — Injury Roll'a özgü bir mekanik.
func request_blood_spend_on_success(roller, maxv: int) -> int:
	if maxv <= 0:
		return 0
	var opponent_id: int = TurnManager.get_opponent_id(roller.owner_id)
	var v: int = await _ask(opponent_id, "blood_success", roller.display_name, maxv, 0)
	return clampi(v, 0, maxv)

## Zar atan modelin RAKİBİNE Infection Marker harcamayı sorar (her biri -1 Dice).
##
## Compendium (keyword.md): "INFECTION MARKERS can be used to modify dice rolls **exactly like
## Blood Markers** (i.e. Action rolls and injury rolls and used in Bloodbaths)." Yani Kan
## İşareti gibi: rakip KAÇ TANE harcayacağını SEÇER ve harcananlar modelden SİLİNİR.
##
## ⚠ KURAL SAPMASI DÜZELTMESİ (compendium denetimi, Adım 3): Success Roll tarafında bu seçim
## YOKTU — `DicePoolBuilder` mevcut TÜM Infection Marker'ları koşulsuz -Dice olarak uyguluyor,
## üstelik onları HİÇ TÜKETMİYORDU. Sonuç: 6 işaretli bir model, sonsuza kadar HER Success
## Roll'unda -6 Dice yiyordu. RAW'da rakip bunları bir kez harcar ve işaretler biter.
## (Injury Roll tarafı zaten `request_infection_spend` ile doğruydu.)
func request_infection_spend_on_success(roller, maxv: int) -> int:
	if maxv <= 0:
		return 0
	var opponent_id: int = TurnManager.get_opponent_id(roller.owner_id)
	var v: int = await _ask(opponent_id, "infection_success", roller.display_name, maxv, 0)
	return clampi(v, 0, maxv)

## P0-1: Zar atan modelin SAHİBİNE kendi Blessing Marker'larını harcamayı sorar (her biri +1 Dice).
## Compendium (blessing-markers.md): "you can... add +1 Dice to the Success Roll."
func request_blessing_spend_on_success(roller, maxv: int) -> int:
	if maxv <= 0:
		return 0
	var v: int = await _ask(roller.owner_id, "blessing_success", roller.display_name, maxv, 0)
	return clampi(v, 0, maxv)

## P1-1 (Sultanate Assassin — Time Slip): hedefe yapılan bir saldırı IRAKLADIĞINDA, hedefin
## sahibine "geleceğe kay" (6" içinde yeniden konuşlan) onayı sorar. Evet/Hayır — ikili.
func request_time_slip(target) -> bool:
	var v: int = await _ask(target.owner_id, "time_slip", target.display_name, 1, 0)
	return v >= 1

signal _pick_response(req_id: int, value)

## P1-1 (Time Slip): hedefin sahibine 3D haritada TIKLAYARAK yeniden konuşlanma noktası seçtirir.
## GameState.pick_mode="position" + map_input.gd üzerinden çözülür (bkz. GameState.start_position_pick).
## decider_id: kararı kimin vereceği (varsayılan -1 → unit.owner_id, mevcut davranış). Puppet
## Master (P1-1) gibi "hareket ettirilen model BAŞKASI ama kararı CASTER veriyor" durumları için
## AYRI verilebilir — menzil halkası yine `unit`in konumunda gösterilir, yalnız RPC yönlendirmesi
## değişir (bkz. _handle_force_move).
## Dönüş: Vector3 (seçilen ham nokta, sunucu tarafında hâlâ doğrulanır/clamp'lenir) veya null (iptal).
func request_position_pick(unit, radius: float, hint_key: String, decider_id: int = -1) -> Variant:
	_next_id += 1
	var rid: int = _next_id
	var decider: int = decider_id if decider_id >= 0 else unit.owner_id
	if not multiplayer.has_multiplayer_peer() or decider == _local_id():
		_present_position_pick(rid, unit, radius, hint_key)
	else:
		rpc_id(NetworkManager.peer_for_canonical(decider), "client_present_position_pick", rid, unit.name, radius, hint_key)
	var r = await _pick_response
	while r[0] != rid:
		r = await _pick_response
	return r[1]

@rpc("authority", "reliable")
func client_present_position_pick(rid: int, unit_name: String, radius: float, hint_key: String) -> void:
	if not GameState.units.has(unit_name):
		_reply_pick.call_deferred(rid, null)
		return
	_present_position_pick(rid, GameState.units[unit_name], radius, hint_key)

func _present_position_pick(rid: int, unit, radius: float, hint_key: String) -> void:
	GameState.start_position_pick(unit, radius, hint_key, func(v): _reply_pick(rid, v))

## P1-1 (Temporal Assassin — 2. hedef seçimi): unit'in sahibine haritada bir DÜŞMAN birim
## tıklatarak seçtirir. Dönüş: seçilen unit Node'u (yerel) veya null (iptal).
## candidates: tıklanabilir hedefler — haritada vurgulanır, diğerlerine tıklama reddedilir.
func request_enemy_unit_pick(unit, hint_key: String, candidates: Array = []) -> Variant:
	_next_id += 1
	var rid: int = _next_id
	var names: Array = candidates.filter(func(c): return is_instance_valid(c)).map(func(c): return String(c.name))
	if not multiplayer.has_multiplayer_peer() or unit.owner_id == _local_id():
		_present_enemy_pick(rid, unit, hint_key, names)
	else:
		rpc_id(NetworkManager.peer_for_canonical(unit.owner_id), "client_present_enemy_pick", rid, unit.name, hint_key, names)
	var r = await _pick_response
	while r[0] != rid:
		r = await _pick_response
	return r[1]

@rpc("authority", "reliable")
func client_present_enemy_pick(rid: int, unit_name: String, hint_key: String, names: Array = []) -> void:
	if not GameState.units.has(unit_name):
		_reply_pick.call_deferred(rid, null)
		return
	_present_enemy_pick(rid, GameState.units[unit_name], hint_key, names)

func _present_enemy_pick(rid: int, unit, hint_key: String, names: Array = []) -> void:
	var cands: Array = []
	for n in names:
		if GameState.units.has(n):
			cands.append(GameState.units[n])
	GameState.start_enemy_unit_pick(unit, hint_key, func(v): _reply_pick(rid, v), cands)

## GOETIC SPELL (Court of the Seven-Headed Serpent, P1-1): caster'ın sahibine, maliyeti
## karşılayana kadar haritada Blood Marker'lı modellere (dost/düşman, Demonic/Black Grail hariç)
## tıklattırır. Dönüş: {unit_name:String -> alınan marker sayısı} (Dictionary) veya null (iptal).
func request_blood_drain(caster, cost: int, hint_key: String) -> Variant:
	_next_id += 1
	var rid: int = _next_id
	if not multiplayer.has_multiplayer_peer() or caster.owner_id == _local_id():
		_present_blood_drain(rid, caster, cost, hint_key)
	else:
		rpc_id(NetworkManager.peer_for_canonical(caster.owner_id), "client_present_blood_drain", rid, caster.name, cost, hint_key)
	var r = await _pick_response
	while r[0] != rid:
		r = await _pick_response
	return r[1]

@rpc("authority", "reliable")
func client_present_blood_drain(rid: int, unit_name: String, cost: int, hint_key: String) -> void:
	if not GameState.units.has(unit_name):
		_reply_pick.call_deferred(rid, null)
		return
	_present_blood_drain(rid, GameState.units[unit_name], cost, hint_key)

func _present_blood_drain(rid: int, caster, cost: int, hint_key: String) -> void:
	GameState.start_blood_drain_pick(caster, cost, hint_key, func(v): _reply_pick(rid, v))

## GOETIC SPELL (P1-1): değişken maliyetli büyüler için ("Cost 1-3" gibi) ödenecek Blood Marker
## sayısını sorar — RAW: "you must choose how many Blood Markers you will pay before the spell is
## cast." min_cost==max_cost ise çağıran taraf bunu hiç sormamalı (sabit maliyet). Dönüş: seçilen
## maliyet, veya 0 (iptal — büyü hiç yapılmaz).
func request_goetic_cost(caster, min_cost: int, max_cost: int, spell_key: String) -> int:
	var v: int = await _ask(caster.owner_id, "goetic_cost_" + spell_key, spell_key, max_cost, min_cost)
	return v if v >= min_cost else 0

## GOETIC SPELL (P1-1): reaktif büyüler (Blessings of the Serpent Moon, Blood Magic, Oracle Beast
## Cloak, Shadow Walker) için "cast etmek ister misin?" onayı — Evet/Hayır.
func request_goetic_cast_confirm(caster, spell_key: String) -> bool:
	var v: int = await _ask(caster.owner_id, "goetic_cast_confirm_" + spell_key, spell_key, 1, 0)
	return v >= 1

func _reply_pick(rid: int, value) -> void:
	if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
		_pick_response.emit(rid, value)
	elif value is Node:
		rpc_id(1, "server_receive_pick_reply_name", rid, value.name)
	elif value is Dictionary:
		# GOETIC SPELL (P1-1): blood_drain sonucu {unit_name:String -> alınan marker sayısı}.
		rpc_id(1, "server_receive_pick_reply_drain", rid, value)
	else:
		rpc_id(1, "server_receive_pick_reply_pos", rid, value)

@rpc("any_peer", "reliable")
func server_receive_pick_reply_pos(rid: int, pos) -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	_pick_response.emit(rid, pos)

@rpc("any_peer", "reliable")
func server_receive_pick_reply_name(rid: int, unit_name: String) -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	_pick_response.emit(rid, GameState.units.get(unit_name, null))

@rpc("any_peer", "reliable")
func server_receive_pick_reply_drain(rid: int, sources: Dictionary) -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	_pick_response.emit(rid, sources)

## EYE OF GOD (Observer, P1-1): başarısız bir Success/Risky Roll'u reroll etme onayı — Evet/Hayır.
func request_eye_of_god_reroll(unit) -> bool:
	var v: int = await _ask(unit.owner_id, "eye_of_god", unit.display_name, 1, 0)
	return v >= 1

## SOUNDING THE RETREAT (morale-phase-comprehensive.md): "If a Morale Check for your Warband is a
## Failure, you can choose to immediately flee and lose the game instead of becoming Shaken."
## Evet/Hayır, başarısız olan oyuncuya sorulur. UI yoksa güvenli varsayılan: kaçma (Shaken olur).
func request_sound_retreat(player_id: int) -> bool:
	var v: int = await _ask(player_id, "sound_retreat", "", 1, 0)
	return v >= 1

## SKIRMISHER: hücum hedefi seçilen modelin sahibine "kaçmak istiyor musun?" sorulur.
func request_skirmisher_evade(target, charger_name: String) -> bool:
	var v: int = await _ask(target.owner_id, "skirmisher_evade", charger_name, 1, 0)
	return v >= 1

## BODYGUARD (P1-1): Pilgrim Bodyguard (Communicant) / Black Grail Bodyguard (Corpse Guard) — dost
## bir hedefe isabet eden saldırıyı yakındaki muhafızın üstlenmesi onayı, hedefin sahibine sorulur.
## guardian_name: kartta gösterilecek muhafızın adı (Communicant/Corpse Guard vb. — dinamik).
func request_pilgrim_bodyguard(target, guardian_name: String) -> bool:
	var v: int = await _ask(target.owner_id, "pilgrim_bodyguard", guardian_name, 1, 0)
	return v >= 1

## BOW OF LETHE (Hunter of the Left Hand Path, P1-1): "Before making an Injury Roll for an attack
## made with a Bow of Lethe, you must choose if the roll will have the +2 Injury Dice Keyword or
## the Ignore Armour Keyword." Döner: true → +2 Injury Dice, false → Ignore Armour.
func request_special_ammunition_choice(attacker, target_name: String) -> bool:
	var v: int = await _ask(attacker.owner_id, "special_ammunition", target_name, 1, 0)
	return v >= 1

## TREAT (Medi-Kit) — compendium: başarıda oyuncu İKİ etkiden BİRİNİ seçer:
##   "Remove [1 Blood Marker] from the model or a friendly model within 1"" VEYA
##   "Stand up a friendly model that is Down and within 1""
## Döner: true = Blood Marker kaldır, false = ayağa kaldır.
func request_treat_choice(caster, target_name: String) -> bool:
	var v: int = await _ask(caster.owner_id, "treat_choice", target_name, 1, 0)
	return v >= 1

## MASTERY OF THE ELEMENTS (Jabirean Alchemist) — ilk yerleşimde silahlara verilecek elementi
## seçtirir. Döner: 0 = Fire, 1 = Gas, 2 = Shrapnel.
func request_element_choice(caster) -> int:
	return await _ask(caster.owner_id, "element_choice", caster.display_name, 2, 0)

func _ask(decider_id: int, kind: String, target_name: String, maxv: int, extra: int) -> int:
	_next_id += 1
	var rid: int = _next_id
	if not multiplayer.has_multiplayer_peer() or decider_id == _local_id():
		_present(rid, kind, target_name, maxv, extra)
	else:
		rpc_id(NetworkManager.peer_for_canonical(decider_id), "client_present_prompt", rid, kind, target_name, maxv, extra)
	var r = await _response
	while r[0] != rid:
		r = await _response
	return r[1]

@rpc("authority", "reliable")
func client_present_prompt(rid: int, kind: String, target_name: String, maxv: int, extra: int) -> void:
	_present(rid, kind, target_name, maxv, extra)

func _present(rid: int, kind: String, target_name: String, maxv: int, extra: int) -> void:
	# UI yoksa güvenli varsayılan (harcama yok) — akış asla kilitlenmez.
	# ÖNEMLİ: yanıt call_deferred ile verilir; aksi halde _ask'teki `await _response`
	# kaydolmadan önce sinyal yayılır ve kaçırılır (kilitlenme). Deferred, await'ten sonraya bırakır.
	if _overlay == null or not is_instance_valid(_overlay) or not _overlay.is_inside_tree():
		_reply.call_deferred(rid, 0)
		return
	_overlay.show_prompt(kind, target_name, maxv, extra, func(value: int): _reply(rid, value))

func _reply(rid: int, value: int) -> void:
	if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
		_response.emit(rid, value)
	else:
		rpc_id(1, "server_receive_reply", rid, value)

@rpc("any_peer", "reliable")
func server_receive_reply(rid: int, value: int) -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	_response.emit(rid, value)
