## Senaryo davranış taban sınıfı. ScenarioData'yı okuyup senaryoya özgü kararları verir.
##
## Bu taban sınıf varsayılan davranışı sağlar (rect deployment + objective VP + kırım zaferi).
## Özel mekanik gerektiren senaryolar bu sınıfı TÜRETİR ve ilgili virtual metotları override eder
## (ScenarioData.logic_script ile bağlanır). Böylece yeni senaryolar mevcut kodu bozmadan eklenir.
##
## STATELESS DEĞİL: VP durumu burada tutulur (sunucu otoritesi; ScenarioManager senkronize eder).
class_name ScenarioLogic
extends RefCounted

var data: ScenarioData = null

## Oyuncu VP durumu. { player_id: int -> vp: int }
var player_vp: Dictionary = {1: 0, 2: 0}

## "Round kazanma" sayacı: bir round'da hangi oyuncu DİĞERİNDEN DAHA FAZLA VP kazandıysa
## (objective kontrolü vb.) o oyuncunun sayacı +1 artar; eşitlikte kimseninki artmaz. UI'nin
## (top bar köşe rozetleri) tek bakışta "kim önde gidiyor" gösterebilmesi için — compendium'un
## kendisinde ayrık bir "round kazananı" kuralı yok, bu tamamen UI'ye özgü türetilmiş bir sayaç.
var player_round_wins: Dictionary = {1: 0, 2: 0}

## İlk Morale Check'i geçen ordu (Glorious Deed: Hold Your Ground) — genişletme için iskele.
var first_morale_pass_player: int = 0

## Tamamlanan Glorious Deeds. { player_id: int -> Array[StringName] } — compendium (glorious-deeds.md):
## her Deed oyun başına YALNIZ BİR KEZ tamamlanır, ilk tamamlayan oyuncu kazanır. Taban sınıfa
## taşındı (P1-5) ki türetilmiş her senaryo `award_deed()` ile aynı deseni ücretsiz kullanabilsin.
var glorious_deeds: Dictionary = {1: [], 2: []}

## Kalıcı objective sahipliği: { objective_id: StringName -> player_id: int }
## Bir oyuncu objective'i alırsa ve sonra çekip giderse bayrak o oyuncuda KALIR.
## Yalnızca rakip bir faction birimi yarıçapa girip kontrolü DEVRALİNCE değişir.
var _objective_owner: Dictionary = {}

func setup(p_data: ScenarioData) -> void:
	data = p_data
	player_vp = {1: 0, 2: 0}
	player_round_wins = {1: 0, 2: 0}
	first_morale_pass_player = 0
	glorious_deeds = {1: [], 2: []}
	_objective_owner = {}
	_gather_knowledge_count = {1: 0, 2: 0}

## KAYIT/YÜKLEME: taban sınıfın oyuncu durumunu JSON-uyumlu bir sözlüğe serileştirir (save_manager.gd
## tarafından çağrılır). Alt sınıflar KENDİ ek alanları olduğunda bu iki metodu override eder,
## `super.save_state()`in döndürdüğü sözlüğe kendi anahtarlarını ekler / `super.load_state(d)`i
## çağırdıktan sonra kendi alanlarını okur (bkz. marked_for_death.gd, relic_hunt.gd).
func save_state() -> Dictionary:
	var deeds_out := {}
	for pid in glorious_deeds:
		var arr: Array = []
		for d in glorious_deeds[pid]:
			arr.append(String(d))
		deeds_out[str(pid)] = arr
	var owner_out := {}
	for oid in _objective_owner:
		owner_out[String(oid)] = _objective_owner[oid]
	return {
		"player_vp": {"1": player_vp.get(1, 0), "2": player_vp.get(2, 0)},
		"player_round_wins": {"1": player_round_wins.get(1, 0), "2": player_round_wins.get(2, 0)},
		"first_morale_pass_player": first_morale_pass_player,
		"glorious_deeds": deeds_out,
		"objective_owner": owner_out,
		"gather_knowledge_count": {"1": _gather_knowledge_count.get(1, 0), "2": _gather_knowledge_count.get(2, 0)},
	}

func load_state(d: Dictionary) -> void:
	var vp = d.get("player_vp", {})
	player_vp = {1: int(vp.get("1", 0)), 2: int(vp.get("2", 0))}
	var rw = d.get("player_round_wins", {})
	player_round_wins = {1: int(rw.get("1", 0)), 2: int(rw.get("2", 0))}
	first_morale_pass_player = int(d.get("first_morale_pass_player", 0))
	var deeds_in = d.get("glorious_deeds", {})
	glorious_deeds = {1: [], 2: []}
	for pid_str in deeds_in:
		var arr: Array = []
		for s in deeds_in[pid_str]:
			arr.append(StringName(s))
		glorious_deeds[int(pid_str)] = arr
	_objective_owner.clear()
	var owner_in = d.get("objective_owner", {})
	for oid_str in owner_in:
		_objective_owner[StringName(oid_str)] = int(owner_in[oid_str])
	var gk = d.get("gather_knowledge_count", {})
	_gather_knowledge_count = {1: int(gk.get("1", 0)), 2: int(gk.get("2", 0))}

## Bir Glorious Deed'i oyuncuya vermeye çalışır. Zaten HERHANGİ bir oyuncu tarafından tamamlanmışsa
## (kendisi dahil) hiçbir şey yapmaz — "ilk tamamlayan kazanır, bir kez" kuralı. Dönüş: yeni verildi mi?
func award_deed(player_id: int, deed_id: StringName) -> bool:
	if player_id <= 0:
		return false
	for pid in glorious_deeds.keys():
		if glorious_deeds[pid].has(deed_id):
			return false
	var list: Array = glorious_deeds.get(player_id, [])
	list.append(deed_id)
	glorious_deeds[player_id] = list
	GameLogger.log_info("[Glorious Deed] Oyuncu %d: '%s' tamamlandı." % [player_id, deed_id], "SCENARIO")
	return true

# ── DEPLOYMENT ───────────────────────────────────────────────────────────────

## Verilen konum, oyuncunun yerleşim bölgesi içinde mi? (XZ Rect2 kontrolü.)
## SAHA SEÇİMİ: hangi oyuncunun p1_deploy_zone ("Zone A") mı p2_deploy_zone ("Zone B") mi
## kullandığı artık sabit player_id==1 DEĞİL, GameState.zone_a_owner_id (oyuncunun haritada
## tıklayarak seçtiği taraf) — bkz. game.gd::request_select_side. Henüz seçilmediyse (0)
## hiçbir konum geçerli sayılmaz (game.gd zaten bunu erken reddediyor, bu ikinci bir güvenlik ağı).
func is_valid_deploy_position(player_id: int, pos: Vector3) -> bool:
	if data == null:
		return true
	if GameState.zone_a_owner_id == 0:
		return false
	var zone: Rect2 = data.p1_deploy_zone if GameState.zone_a_owner_id == player_id else data.p2_deploy_zone
	return zone.has_point(Vector2(pos.x, pos.z))

# ── OBJECTIVE KONTROL & PUANLAMA ─────────────────────────────────────────────

## Sahada anlık kim kontrol ediyor: 0 = kimse/çekişmeli, 1/2 = oyuncu.
##
## KURAL (compendium "Controlling Objectives" — claim-no-mans-land.md):
##   ZONE A (terrain piece üzerinde, control_radius içi):
##     Eğer bir oyuncunun ZONE A'da birimi varsa ve rakibin YOKSA →
##     dış bölgedeki (within 1") sayı ne olursa olsun, o oyuncu kontrol eder.
##   ZONE B (terrain piece dışı, control_radius + 1" içi):
##     ZONE A eşit veya boşsa ZONE B sayısı karşılaştırılır.
##   Her iki zone'da da eşit veya kimse yoksa → 0 (kimse kontrol etmiyor).
##
## Bu metod YALNIZCA anlık sayım yapar — kalıcılık için get_persistent_objective_controller() kullanın.
func get_objective_controller(obj: ScenarioObjective) -> int:
	# Compendium: "within 1 inch of the terrain piece" = terrain piece sınırından 1" dışı
	# control_radius = terrain piece sınırı (oyunumuzda 1.0 = 1 inch)
	# outer_radius = terrain piece sınırından +1" dışına kadar (toplamda control_radius + 1.0)
	var outer_radius: float = obj.control_radius + 1.0

	# Sayaçlar: on = terrain piece ÜSTÜNDE, out = dışındaki 1" halkada
	var on_1: int = 0    # P1, zone A (terrain piece üstünde)
	var on_2: int = 0    # P2, zone A
	var out_1: int = 0   # P1, zone B (within 1" of terrain piece, dışarı)
	var out_2: int = 0   # P2, zone B

	# Objective'in XZ konumu (Y yoksayılır — compendium yatay mesafeyi esas alır)
	var obj_xz := Vector2(obj.position.x, obj.position.z)

	# Ölü veya Down birimler kontrol sayımına KATILMAZ (compendium: "models on the terrain piece").
	# NOT: mesafe burada YATAY (XZ) ölçülür — UnitQuery.within 3B ölçtüğü için kullanılmıyor.
	for u in UnitQuery.standing(UnitQuery.alive()):
		# XZ yatay mesafe (Y farkı kontrol yarıçapını bozmasın — farklı yükseklikteki birimler)
		var u_xz := Vector2(u.global_position.x, u.global_position.z)
		var dist: float = obj_xz.distance_to(u_xz)

		if dist <= obj.control_radius:
			# Zone A: terrain piece üstünde
			if u.owner_id == 1:
				on_1 += 1
			elif u.owner_id == 2:
				on_2 += 1
		elif dist <= outer_radius:
			# Zone B: terrain piece dışında ama 1" içinde
			if u.owner_id == 1:
				out_1 += 1
			elif u.owner_id == 2:
				out_2 += 1

	# ÖZEL KURAL: Terrain piece üstünde biri var, rakibinde yoksa → terrain sahibi kazanır
	# (dış bölgedeki sayı fark etmez — compendium açık hüküm)
	if on_1 > 0 and on_2 == 0:
		return 1
	if on_2 > 0 and on_1 == 0:
		return 2

	# Genel kural: tüm friendly (on + out) vs enemy (on + out) — toplam karşılaştırması
	var total_1: int = on_1 + out_1
	var total_2: int = on_2 + out_2
	if total_1 > total_2:
		return 1
	elif total_2 > total_1:
		return 2
	return 0   # Eşit veya kimse yok

## Kalıcı objective kontrolcüsünü döndürür (görsel ve UI için birincil kaynak).
## Kural: Yarıçapta aktif birimlere göre anlık kontrol belirlenir; eğer yarıçapta kimse yoksa
## son alıcı faction sahipliği KORUR. Rakip faction devralınca sahiplik değişir.
func get_persistent_objective_controller(obj: ScenarioObjective) -> int:
	var instant := get_objective_controller(obj)
	if instant != 0:
		# Anlık kontrol var — sahipliği güncelle ve döndür
		_objective_owner[obj.objective_id] = instant
		return instant
	# Yarıçapta kimse yok — kalıcı sahibi döndür (0 = hiç alınmamış)
	return _objective_owner.get(obj.objective_id, 0)

## Tur sonunda çağrılır (Morale fazından sonra). Objective VP'lerini işler.
func on_turn_end(round_number: int) -> void:
	if data == null or data.victory_type != ScenarioData.VictoryType.OBJECTIVE_VP:
		return
	var vp_before: Dictionary = player_vp.duplicate()
	for obj_res in data.objectives:
		var obj := obj_res as ScenarioObjective
		if obj == null:
			continue
		# VP hesabı için kalıcı sahibi kullan (tur sonu boşken önceki sahibi sayılmalı)
		var controller := get_persistent_objective_controller(obj)
		if controller != 0:
			player_vp[controller] = player_vp.get(controller, 0) + obj.vp_per_turn
			GameLogger.log_info("[Scenario] Tur %d: Oyuncu %d '%s' objectivesini kontrol etti (+%d VP)." \
				% [round_number, controller, obj.objective_id, obj.vp_per_turn], "SCENARIO")

	# ROUND KAZANANI (UI rozetleri için): bu round içinde DAHA FAZLA VP kazanan oyuncu +1 alır.
	# Eşitlikte (ikisi de 0 kazandı ya da eşit kazandı) kimsenin sayacı artmaz.
	var gain_1: int = player_vp.get(1, 0) - vp_before.get(1, 0)
	var gain_2: int = player_vp.get(2, 0) - vp_before.get(2, 0)
	if gain_1 > gain_2:
		player_round_wins[1] = player_round_wins.get(1, 0) + 1
	elif gain_2 > gain_1:
		player_round_wins[2] = player_round_wins.get(2, 0) + 1

# ── ZAFER ────────────────────────────────────────────────────────────────────

## Tur limiti dolduysa oyun bitmeli mi? round_number = biten tur numarası.
func is_final_turn_reached(round_number: int) -> bool:
	if data == null:
		return false
	return data.turn_limit > 0 and round_number >= data.turn_limit

## Oyun sonunda kazananı belirler. Dönüş: { winner: int (0=beraberlik), reason: String }.
func evaluate_end_of_game() -> Dictionary:
	if data == null or data.victory_type == ScenarioData.VictoryType.ELIMINATION:
		return {"winner": 0, "reason": "elimination"}
	var v1: int = player_vp.get(1, 0)
	var v2: int = player_vp.get(2, 0)
	var winner: int = 0
	if v1 > v2:
		winner = 1
	elif v2 > v1:
		winner = 2
	return {"winner": winner, "reason": "vp", "vp": {1: v1, 2: v2}}

# ── UI DURUMU ────────────────────────────────────────────────────────────────

## Objectives panelinin göstereceği güncel durum.
func get_objectives_state() -> Array:
	var out: Array = []
	if data == null:
		return out
	for obj_res in data.objectives:
		var obj := obj_res as ScenarioObjective
		if obj == null:
			continue
		out.append({
			"id": obj.objective_id,
			"label_key": obj.label_key,
			"controller": get_persistent_objective_controller(obj),
			"position": obj.position,
		})
	return out

# ── GENİŞLETME HOOK'LARI (Glorious Deeds vb. — türetilmiş senaryolar override eder) ──
# Taban sınıf hook'ları no-op/minimal; türetilmiş senaryolar (örn. ClaimNoMansLandLogic) bunları
# override edip award_deed() ile kendi Glorious Deeds koşullarını değerlendirir.

## Warband'da bir Combat Biologist olan oyuncu başına, Gather Knowledge için sayılan OOA adedi.
var _gather_knowledge_count: Dictionary = {1: 0, 2: 0}

## Bir model Out of Action olduğunda (attacker/target unit node, is_melee bool, ctx: ek bağlam).
## ctx anahtarları (hepsi opsiyonel, çağıran doldurur): is_long_range, in_cover (Sniper için),
## attacker_began_down (Resist and Bite için).
## GATHER KNOWLEDGE (Combat Biologist, P1-1): compendium "Whenever a Combat Biologist is part of
## your Warband, add the Gather Knowledge Glorious Deed to those normally available in each
## scenario you play" — bu yüzden TÜM senaryolarda geçerli, taban sınıfta yaşıyor. Türetilmiş
## senaryolar KENDİ on_unit_out_of_action'larında `super.on_unit_out_of_action(...)` çağırarak
## bunu miras alır (ClaimNoMansLand/FieldsOfGlory/GreatWar/TheHighGround hepsi çağırıyor).
func on_unit_out_of_action(attacker, target, _is_melee: bool, ctx: Dictionary = {}) -> void:
	if attacker == null or not is_instance_valid(attacker) or not ctx.get("is_ooa", false):
		return
	if target == null or not is_instance_valid(target):
		return
	var pid: int = attacker.owner_id
	# NOT: ölü birimler de sayılır (orijinal davranış) — bu yüzden `all()` üzerinden filtrelenir.
	var vivisectors: Array = UnitQuery.within(
		UnitQuery.with_keyword(
			UnitQuery.where(UnitQuery.all(), func(u): return u.owner_id == pid),
			&"battlefield_vivisection"),
		target.global_position, GameState.ENGAGE_RANGE)
	if not vivisectors.is_empty():
		_gather_knowledge_count[pid] = _gather_knowledge_count.get(pid, 0) + 1
		if _gather_knowledge_count[pid] >= 3:
			award_deed(pid, &"gather_knowledge")

## Bir ordu ilk kez Morale Check geçtiğinde (Hold Your Ground).
func on_morale_check_passed(player_id: int) -> void:
	if first_morale_pass_player == 0:
		first_morale_pass_player = player_id

## Bir model başarılı bir Charge sonunda kaç düşmanla angaje (1" içinde) oldu (Suicidal Bravery).
func on_successful_charge(_charger, _engaged_enemy_count: int) -> void:
	pass
