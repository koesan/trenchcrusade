## "Marked for Death" (Ölüm Damgası) — ÖZGÜN senaryo (kullanıcı isteğiyle, mevcut mekaniklerle
## uyumlu, harita/terrain gereksinimi YOK — herhangi bir sahada oynanabilir).
##
## TEMA: Her savaşta bir ordu için EN ÖNEMLİ olan model (Cost'u en yüksek, sahadaki en değerli
## ekipman/eğitim) doğal olarak öncelikli bir hedeftir. Bu senaryo bunu AÇIK bir oyun mekaniğine
## çevirir: her iki oyuncunun sahadaki en pahalı modeli PUBLIC (gizli değil — kart oyunlarındaki
## "secret Mark" mekaniklerinin aksine, bu proje ağ-üzerinden gizli bilgi akışı gerektirmeyen bir
## tasarım tercihi) "Bounty Target" (Ödül Hedefi) olarak işaretlenir; düşman onu öldürürse büyük
## ödül kazanır, o düşerse ordunun bir sonraki en pahalı canlı modeli otomatik olarak yeni hedef
## olur — oyun ilerledikçe "kelle avı" sürer. Kendi Bounty Target'ını hayatta tutmak da ayrı bir
## ödül kaynağıdır (savunma/saldırı arasında sürekli gerilim).
##
## KURALLAR:
##   - 4 tur, standart yerleşim (özel harita/terrain gerektirmez — herhangi bir arketipte oynanır).
##   - Infiltrator serbest (Great War/Fields of Glory ile aynı, bu senaryonun kısıtlaması yok).
##   - Standart Moral kuralları GEÇERLİ (skip_morale YOK — Great War/Relic Hunt'tan farklı, bilinçli
##     çeşitlilik: bu senaryoda hesaplı risk teması var, kör "sonuna kadar savaş" değil).
##   - Bounty Target belirleme: deployment bitince (game.gd::establish_bounty_targets çağırır) her
##     oyuncunun sahadaki EN YÜKSEK Cost'lu modeli işaretlenir (berabere ise unit adı alfabetik en
##     küçük — deterministik). Görsel: UnitStatusPanel'de ☠ rozet (is_bounty_target, set_bounty_target).
##   - Bir Bounty Target Out of Action olunca: saldırana +3 VP (ANLIK) + o oyuncunun ordusundaki bir
##     SONRAKİ en pahalı canlı model otomatik yeni Bounty Target olur (sahada kimse kalmadıysa boş).
##   - Turn sonunda: bir oyuncunun ORİJİNAL (oyun başındaki) Bounty Target'ı hâlâ hayattaysa +1 VP.
##   - Oyun sonu: Glorious Deed başına +1 VP (standart desen).
class_name MarkedForDeathLogic
extends ScenarioLogic

## player_id -> o anki Bounty Target'ın unit node adı (String, GameState.units anahtarı). "" = yok.
var bounty_target: Dictionary = {1: "", 2: ""}
## player_id -> OYUN BAŞINDAKİ (deployment sonrası ilk belirlenen, hiç değişmeyen) Bounty Target.
var original_bounty_target: Dictionary = {1: "", 2: ""}
## attacker.name -> bu oyun boyunca OOA ettiği FARKLI Bounty Target'ların listesi (Head Hunter deed'i).
var _bounty_kills_seen: Dictionary = {}

func setup(p_data: ScenarioData) -> void:
	super.setup(p_data)
	bounty_target = {1: "", 2: ""}
	original_bounty_target = {1: "", 2: ""}
	_bounty_kills_seen = {}

## KAYIT/YÜKLEME: bkz. scenario_logic.gd::save_state. bounty_target/original_bounty_target
## birim NODE ADI (String) taşır — restore_game_state birimleri AYNI adlarla yeniden spawn
## ettiğinden (bkz. save_manager.gd), bu string referanslar reload sonrası geçerliliğini korur.
func save_state() -> Dictionary:
	var d := super.save_state()
	d["bounty_target"] = {"1": bounty_target.get(1, ""), "2": bounty_target.get(2, "")}
	d["original_bounty_target"] = {"1": original_bounty_target.get(1, ""), "2": original_bounty_target.get(2, "")}
	d["bounty_kills_seen"] = _bounty_kills_seen.duplicate(true)
	return d

func load_state(d: Dictionary) -> void:
	super.load_state(d)
	var bt = d.get("bounty_target", {})
	bounty_target = {1: String(bt.get("1", "")), 2: String(bt.get("2", ""))}
	var obt = d.get("original_bounty_target", {})
	original_bounty_target = {1: String(obt.get("1", "")), 2: String(obt.get("2", ""))}
	_bounty_kills_seen = d.get("bounty_kills_seen", {}).duplicate(true)

## En yüksek Cost'lu SAHADAKİ (canlı) modeli bulur. Berabere ise unit.name alfabetik en küçük
## (deterministik — hem test hem de ağ-senkron açısından öngörülebilir olmalı).
func _highest_cost_living_unit(player_id: int) -> String:
	var best_name := ""
	var best_cost := -1
	for u in UnitQuery.of_player(player_id):
		if u.unit_data == null:
			continue
		var c: int = u.unit_data.cost
		var name_str: String = String(u.name)
		if c > best_cost or (c == best_cost and (best_name == "" or name_str < best_name)):
			best_cost = c
			best_name = name_str
	return best_name

## Deployment bitince game.gd tarafından ÇAĞRILMALI (sunucu otoritesi) — her iki oyuncunun ilk
## Bounty Target'ını belirler + görsel rozeti senkronize eder.
func establish_bounty_targets() -> void:
	for pid in [1, 2]:
		var name_str: String = _highest_cost_living_unit(pid)
		bounty_target[pid] = name_str
		original_bounty_target[pid] = name_str
		_sync_badge(name_str, true)

## Bir Bounty Target düşünce (öldüğünde) çağrılır — sıradaki en pahalı canlıyı yeni hedef yapar.
func _reassign_bounty_target(player_id: int) -> void:
	var old_name: String = bounty_target.get(player_id, "")
	if old_name != "":
		_sync_badge(old_name, false)
	var new_name: String = _highest_cost_living_unit(player_id)
	bounty_target[player_id] = new_name
	if new_name != "":
		_sync_badge(new_name, true)

func _sync_badge(unit_name: String, is_target: bool) -> void:
	if unit_name == "" or not GameState.units.has(unit_name):
		return
	var u = GameState.units[unit_name]
	if is_instance_valid(u) and u.has_method("set_bounty_target"):
		RpcHelper.sync(u, "set_bounty_target", [is_target])

func on_unit_out_of_action(attacker, target, is_melee: bool, ctx: Dictionary = {}) -> void:
	super.on_unit_out_of_action(attacker, target, is_melee, ctx)  # Gather Knowledge (taban sınıf)
	if not ctx.get("is_ooa", false) or target == null or not is_instance_valid(target):
		return

	var target_owner: int = target.owner_id
	var target_key: String = String(target.name)
	var was_bounty: bool = bounty_target.get(target_owner, "") == target_key and target_key != ""

	if was_bounty:
		_reassign_bounty_target(target_owner)
		if attacker != null and is_instance_valid(attacker):
			var pid: int = attacker.owner_id
			player_vp[pid] = player_vp.get(pid, 0) + 3
			GameLogger.log_info("[Marked for Death] Oyuncu %d: Bounty Target avlandı (+3 VP, %s)." \
				% [pid, target.display_name if "display_name" in target else target_key], "SCENARIO")
			var akey: String = attacker.name
			var seen: Array = _bounty_kills_seen.get(akey, [])
			if not seen.has(target_key):
				seen.append(target_key)
				_bounty_kills_seen[akey] = seen
				if MechanicsResolver.head_hunter_triggers(seen.size()):
					award_deed(pid, &"head_hunter")

	if attacker == null or not is_instance_valid(attacker):
		return
	var pid2: int = attacker.owner_id

	# SNIPER (reused, standart predikat)
	var target_is_elite: bool = target.unit_data != null and KeywordSystem.has(target.unit_data, &"elite")
	if MechanicsResolver.sniper_deed_triggers(is_melee, ctx.get("is_long_range", false), ctx.get("in_cover", false), target_is_elite):
		award_deed(pid2, &"sniper")

	# BLOODLETTING (OOA koşulu yok, ama zaten bu fonksiyonun içindeyiz — hâlâ geçerli, alttaki kontrol OOA'ya bakmaz)
	if MechanicsResolver.bloodletting_triggers(ctx.get("blood_before", 0), ctx.get("blood_after", 0)):
		award_deed(pid2, &"bloodletting")

	# RESIST AND BITE
	if ctx.get("attacker_began_down", false):
		award_deed(pid2, &"resist_and_bite")

func on_successful_charge(charger, engaged_enemy_count: int) -> void:
	if is_instance_valid(charger) and MechanicsResolver.suicidal_bravery_triggers(engaged_enemy_count):
		award_deed(charger.owner_id, &"suicidal_bravery")

## Turn sonu: objective VP yok (taban sınıfın on_turn_end'i no-op, objectives=[]) — yalnız "orijinal
## Bounty Target hayatta mı" +1 VP kontrolü.
func on_turn_end(round_number: int) -> void:
	super.on_turn_end(round_number)
	for pid in [1, 2]:
		var orig: String = original_bounty_target.get(pid, "")
		if orig == "" or not GameState.units.has(orig):
			continue
		var u = GameState.units[orig]
		if is_instance_valid(u) and u.current_health > 0:
			player_vp[pid] = player_vp.get(pid, 0) + 1
			GameLogger.log_info("[Marked for Death] Oyuncu %d: orijinal Bounty Target hayatta (+1 VP, Tur %d)." \
				% [pid, round_number], "SCENARIO")

## UNTOUCHABLE (Dokunulmaz): oyun sonunda kontrol edilir — orijinal Bounty Target hiç OOA olmadan
## (canlı) oyunu bitirdi mi? (award_deed burada, evaluate_end_of_game'de tetiklenir — deed VP'si
## de aynı çağrıda hesaba katılır, aşağıdaki toplam bunu içerir.)
func evaluate_end_of_game() -> Dictionary:
	for pid in [1, 2]:
		var orig: String = original_bounty_target.get(pid, "")
		if orig == "" or not GameState.units.has(orig):
			continue
		var u = GameState.units[orig]
		if is_instance_valid(u) and u.current_health > 0:
			award_deed(pid, &"untouchable")

	var base := super.evaluate_end_of_game()
	var v1: int = player_vp.get(1, 0) + glorious_deeds.get(1, []).size()
	var v2: int = player_vp.get(2, 0) + glorious_deeds.get(2, []).size()
	var winner: int = 0
	if v1 > v2:
		winner = 1
	elif v2 > v1:
		winner = 2
	base["winner"] = winner
	base["vp"] = {1: v1, 2: v2}
	return base
