extends Node
## ArmouryManager — Battlekit satın alma FAZININ durumu (autoload).
##
## NEDEN AYRI BİR AUTOLOAD?
## `game_state.gd` zaten yerleştirme, tur ve bütçe durumunu taşıyor. Satın alma durumunu da
## oraya koymak onu bir god-file'a çevirirdi. Kural mantığı `ArmouryRules`'ta (saf), faz durumu
## burada, ekran `armoury_panel.gd`'de — üç ayrı sorumluluk.
##
## KURAL YERİ (compendium): Battlekit, model işe alınırken satın alınır. Oyunda roster-builder
## yoktur; kurallara en uygun an yerleştirme bittikten SONRA, savaş başlamadan öncedir.
## Bu, kampanyadaki *Quartermaster Step*'in çatışma modu karşılığıdır.

## Satın alma yapıldığında yayılır (panel kendini tazeler).
signal purchase_made(player_id: int, unit_name: String, item_id: StringName)
## Bir oyuncu alışverişini bitirdiğinde yayılır.
signal player_finished(player_id: int)

## {birim_düğüm_adı: [item_id, ...]} — hangi modele ne takıldı
var unit_items: Dictionary = {}
## {oyuncu_id: {item_id: adet}} — `LIMIT: N` sayımı warband genelindedir
var warband_items: Dictionary = {}
## {oyuncu_id: bool}
var finished: Dictionary = {}

## SIRALI ALIŞVERİŞ (tek makinede iki oyuncu): yerleştirmedeki `active_deployer_id` ile aynı
## desen. Ağ oyununda her istemci kendi kimliğini kullanır, bu değer yok sayılır.
var active_shopper_id: int = 1

func reset() -> void:
	unit_items.clear()
	warband_items.clear()
	finished.clear()
	active_shopper_id = 1

## Şu an alışveriş yapan oyuncu. Ağ oyununda "ben"; tek makinede sırası gelen oyuncu.
func current_shopper() -> int:
	# `is_in_match` GERÇEK bir ağ maçını ayırt eder; `has_multiplayer_peer()` tek başına
	# yetmez (menü/lobi bağlantısı da bir peer'dır ve tek makinede sırayı bozardı).
	if NetworkManager.is_in_match:
		return NetworkManager.get_local_canonical_id()
	return active_shopper_id

## Bu modele takılı kalemlerin id listesi.
func items_of(unit_name: String) -> Array:
	return unit_items.get(unit_name, [])

## Bu oyuncunun warband'ında alınmış kalem sayıları. SİLAH kalemleri sahadaki modellerin
## profillerinden sayılır — hazır kitteki silahlar da `LIMIT: N`'e dahildir (örn. 3 MHI'nin
## hazır Machine Gun'ları); diğer kalemler satın alma kaydından gelir.
func counts_of(player_id: int) -> Dictionary:
	var counts: Dictionary = {}
	var bought: Dictionary = warband_items.get(player_id, {})
	var faction: Resource = GameState.get_faction_for_player(player_id)
	var weapon_ids: Dictionary = {}
	for it in ArmouryRules.table_for(faction):
		if not it.granted_attacks.is_empty():
			weapon_ids[it.item_id] = true
	for id in bought:
		if not weapon_ids.has(id):
			counts[id] = bought[id]
	var uds: Array = []
	for u in UnitQuery.roster_of(player_id):
		uds.append(u.unit_data)
	var wc: Dictionary = ArmouryRules.weapon_counts(uds, faction)
	for id in wc:
		counts[id] = wc[id]
	return counts

## "Bu oyuncu bu modele bu kalemi alabilir mi?" — panel de satın alma da bunu çağırır.
func block_reason(player_id: int, unit_node: Node, item: Resource) -> String:
	if unit_node == null or unit_node.unit_data == null:
		return ArmouryRules.REASON_NOT_IN_TABLE
	return ArmouryRules.check(item, unit_node.unit_data,
		GameState.get_faction_for_player(player_id),
		counts_of(player_id), items_of(String(unit_node.name)),
		GameState.player_deploy_pool.get(player_id, 0),
		GameState.player_glory_pool.get(player_id, 0))

## Satın alma isteği. Döndürür: "" = başarılı; dolu string = ret sebebi (lokalizasyon anahtarı).
func request_purchase(player_id: int, unit_name: String, item: Resource) -> String:
	var unit_node: Node = GameState.units.get(unit_name)
	var reason := block_reason(player_id, unit_node, item)
	if reason != "":
		return reason
	_apply(player_id, unit_name, item)
	RpcHelper.sync(self, "sync_purchase", [player_id, unit_name, String(item.resource_path)])
	return ""

@rpc("any_peer", "call_remote", "reliable")
func sync_purchase(player_id: int, unit_name: String, item_path: String) -> void:
	var item: Resource = load(item_path)
	if item != null:
		_apply(player_id, unit_name, item)

func _apply(player_id: int, unit_name: String, item: Resource) -> void:
	var unit_node: Node = GameState.units.get(unit_name)
	if unit_node == null or unit_node.unit_data == null:
		return

	# Modelin verisini KOPYA üzerinden güncelle — paylaşılan .tres asla mutasyona uğramaz.
	unit_node.unit_data = ArmouryRules.apply(unit_node.unit_data, item)
	if unit_node.has_method("apply_unit_data"):
		unit_node.apply_unit_data()      # zırh/istatistik göstergelerini tazeler
	if unit_node.has_method("update_indicators"):
		unit_node.update_indicators()

	var owned: Array = unit_items.get(unit_name, [])
	owned.append(item.item_id)
	unit_items[unit_name] = owned

	var counts: Dictionary = warband_items.get(player_id, {})
	counts[item.item_id] = int(counts.get(item.item_id, 0)) + 1
	warband_items[player_id] = counts

	# Ödeme DOĞRU havuzdan düşer — Glory ve ducat birbirinin yerine geçmez (EconomyRules ilkesi).
	if item.cost_currency == ArmouryItem.Currency.GLORY:
		GameState.player_glory_pool[player_id] = \
			int(GameState.player_glory_pool.get(player_id, 0)) - item.cost
	else:
		GameState.player_deploy_pool[player_id] = \
			int(GameState.player_deploy_pool.get(player_id, 0)) - item.cost

	purchase_made.emit(player_id, unit_name, item.item_id)

## KAYITTAN GERİ YÜKLEME: satın almaları ÖDEMESİZ yeniden uygular (bütçeler kayıttan gelir).
## `saved_units`: {birim_adı: [item_id, ...]}. Birimler zaten kurulmuş olmalı (init_unit sonrası).
## Sunucu kendi tarafında çağırır; yeniden bağlanan istemciye de RPC ile gönderilir.
@rpc("authority", "call_remote", "reliable")
func restore_state(saved_units: Dictionary, saved_warband: Dictionary) -> void:
	unit_items.clear()
	warband_items.clear()
	for pid_key in saved_warband:
		var counts: Dictionary = {}
		for id in saved_warband[pid_key]:
			counts[StringName(id)] = int(saved_warband[pid_key][id])
		warband_items[int(pid_key)] = counts
	for unit_name in saved_units:
		var unit_node: Node = GameState.units.get(String(unit_name))
		if unit_node == null or unit_node.unit_data == null:
			continue
		var table: Array = ArmouryRules.table_for(GameState.get_faction_for_player(unit_node.owner_id))
		var owned: Array = []
		for id in saved_units[unit_name]:
			for item in table:
				if item.item_id == StringName(id):
					unit_node.unit_data = ArmouryRules.apply(unit_node.unit_data, item)
					owned.append(item.item_id)
					break
		unit_items[String(unit_name)] = owned
		unit_node.apply_unit_data()

## Oyuncu alışverişini bitirir; iki taraf da bitirince savaş başlar.
##
## TEK MAKİNEDE: sıra rakibe geçer, aksi hâlde rakip hiçbir zaman "bitirdi" sayılmaz ve
## ekran açık kalırdı (kullanıcı bildirimi: "alışverişi bitir deyince pencere kapanmıyor").
func finish_player(player_id: int) -> void:
	# KENDİNİ ONARAN AKIŞ: "zaten bitmiş" durumunda ESKİDEN sessizce ERKEN DÖNÜLÜYORDU —
	# sıra devri ve faz kontrolü hiç çalışmıyor, ekran kilitli kalıyordu. Artık işaret zaten
	# konmuşsa bile devir + kontrol YİNE de yürütülür, böylece tutarsız bir durumdan
	# (ör. senkron kaybı) çıkış mümkün olur.
	finished[player_id] = true
	RpcHelper.sync(self, "sync_finished", [player_id])
	# Sırayı koşulsuz devret: ağ oyununda `current_shopper()` zaten yerel kimliği döndürdüğü
	# için bu değer yok sayılır, tek makinede ise ekranı rakibe açan tek şey budur.
	for pid in GameState.player_deploy_pool:
		if not finished.get(pid, false):
			active_shopper_id = int(pid)
			break
	player_finished.emit(player_id)
	_check_all_finished()

@rpc("any_peer", "call_remote", "reliable")
func sync_finished(player_id: int) -> void:
	finished[player_id] = true
	player_finished.emit(player_id)
	_check_all_finished()

func _check_all_finished() -> void:
	for pid in GameState.player_deploy_pool:
		if not finished.get(pid, false):
			return
	if GameState.game_phase == GameState.GamePhase.ARMOURY:
		RpcHelper.sync(GameState, "sync_game_phase", [GameState.GamePhase.BATTLE])
