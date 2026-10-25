extends Node

## Ağ yöneticisi (Autoload).
## ENet çok oyunculu bağlantı yönetimi, oyuncu kaydı ve maç başlatma işlemlerini yönetir.
## Sunucu otoritesi prensibiyle çalışır — istemciler doğrudan durum değiştiremez.

signal players_updated
signal connection_status_changed(message: String)
signal game_started
signal game_ended

const DEFAULT_PORT = 10567
const DEFAULT_IP = "127.0.0.1"

var last_connected_ip: String = DEFAULT_IP
var last_connected_port: int = DEFAULT_PORT
var lobby_password: String = ""

## Oyuncu verisi: { id: int -> { name: String } }
var players = {}
## Boşsa lobi/ana bilgisayar kurulurken yerelleştirilmiş varsayılan ad kullanılır. Burada
## tr_t çağrılamaz: bu autoload LocalizationManager'dan ÖNCE yüklenir (anahtar döner).
var local_player_name: String = ""

## KÖK NEDEN DÜZELTMESİ: gerçek ENet peer id'si (host=1 sabit, istemci=ENet'in ürettiği rastgele
## 31-bit sayı, ASLA "2" değil — empirik doğrulandı) ile oyunun her yerinde kullandığı kanonik
## oyuncu numarası (1/2 — player_factions, player_deploy_pool, active_deployer_id, unit.owner_id,
## TurnManager.current_turn_player_id hep bu ikisini bekler) birbirine KARIŞTIRILIYORDU. Bu proje
## kesinlikle 2 oyunculu: host her zaman kanonik 1, TEK misafir her zaman kanonik 2. Bu tablo
## gerçek peer id'yi kanonik numaraya çevirir; reconnect'te peer id değişir ama kanonik numara
## SABİT kalır (bkz. register_player).
var canonical_of_peer: Dictionary = {}   # { real_peer_id: int -> canonical_id: 1|2 }

## "Ben kimim" (kanonik 1/2) — GameState/TurnManager/unit.owner_id ile karşılaştırmak için TEK
## doğru kaynak. Hotseat'te (peer yok) GameState.active_deployer_id kullanılır (mevcut davranış).
func get_local_canonical_id() -> int:
	if not multiplayer.has_multiplayer_peer():
		return GameState.active_deployer_id
	var raw := multiplayer.get_unique_id()
	return canonical_of_peer.get(raw, raw)

## Bir RPC göndereninin (get_remote_sender_id ile alınan HAM peer id) kanonik kimliğini döndürür.
func canonical_for_peer(real_peer_id: int) -> int:
	return canonical_of_peer.get(real_peer_id, real_peer_id)

## Kanonik oyuncu numarasının (1/2) o an bağlı GERÇEK peer id'sini döndürür — rpc_id(...) ile
## belirli bir oyuncuya adresli mesaj göndermek için ZORUNLU (rpc_id kanonik id'yi anlamaz).
func peer_for_canonical(canonical_id: int) -> int:
	if canonical_id == 1:
		return 1
	for real_id in canonical_of_peer:
		if canonical_of_peer[real_id] == canonical_id:
			return real_id
	return canonical_id

## Lobby / maç durumu ayrımı
var is_in_lobby: bool = true
var is_in_match: bool = false

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game(port: int = DEFAULT_PORT, player_name: String = "Host", password: String = "") -> Error:
	if player_name == "Host" or player_name == "Oyuncu":
		player_name = LocalizationManager.tr_t("PLAYER_HOST")
	local_player_name = player_name
	last_connected_port = port
	last_connected_ip = DEFAULT_IP
	lobby_password = password
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port)
	if error != OK:
		connection_status_changed.emit(LocalizationManager.tr_t("NET_ERR_SERVER_CREATE") % error)
		return error
	
	multiplayer.multiplayer_peer = peer
	# Sunucu relay'i kapat — istemciler birbirleriyle doğrudan konuşamasın
	multiplayer.server_relay = false
	
	players[1] = { "name": local_player_name }
	is_in_lobby = true
	is_in_match = false
	players_updated.emit()
	connection_status_changed.emit(LocalizationManager.tr_t("NET_SERVER_CREATED") % port)
	return OK

func join_game(ip: String = DEFAULT_IP, port: int = DEFAULT_PORT, player_name: String = "Katılımcı", password: String = "") -> Error:
	if player_name == "Katılımcı" or player_name == "Oyuncu" or player_name == "Client":
		player_name = LocalizationManager.tr_t("PLAYER_CLIENT")
	local_player_name = player_name
	last_connected_ip = ip
	last_connected_port = port
	lobby_password = password
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, port)
	if error != OK:
		connection_status_changed.emit(LocalizationManager.tr_t("NET_ERR_CLIENT_INIT") % error)
		return error
	
	multiplayer.multiplayer_peer = peer
	connection_status_changed.emit(LocalizationManager.tr_t("NET_CLIENT_CONNECTING") % [ip, port])
	return OK

func leave_game():
	# Diğer oyunculara ayrılma bildirimi gönder
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		if multiplayer.is_server():
			# Sunucu kapanıyorsa tüm istemcilere bildir
			rpc("notify_server_closing")
		else:
			# İstemci ayrılıyorsa sunucuya bildir
			rpc_id(1, "notify_player_leaving", local_player_name)
	
	multiplayer.multiplayer_peer = null
	players.clear()
	is_in_lobby = true
	is_in_match = false
	game_ended.emit()
	connection_status_changed.emit(LocalizationManager.tr_t("NET_CLIENT_DISCONNECTED"))

func start_match():
	if multiplayer.is_server():
		is_in_lobby = false
		is_in_match = true
		rpc("start_game")

func _on_peer_connected(id: int):
	# Maç zaten başladıysa yeni bağlantıları reddet
	if is_in_match and multiplayer.is_server():
		if not SaveManager.is_waiting_for_reconnect:
			GameLogger.log_warn("Maç sırasında yeni bağlantı reddedildi: %d" % id, "NETWORK")
			return
		else:
			GameLogger.log_info("Yeniden bağlanma talebi kabul edildi: %d" % id, "NETWORK")
	
	# Kendi bilgimizi yeni bağlanana gönderiyoruz
	rpc_id(id, "register_player", local_player_name, lobby_password)

func _on_peer_disconnected(id: int):
	if players.has(id):
		var p_name = players[id].name
		players.erase(id)
		players_updated.emit()
		connection_status_changed.emit(LocalizationManager.tr_t("NET_CLIENT_PEER_DISCONNECTED") % [p_name, id])
		GameEvents.player_left.emit(id, p_name)

func _on_connected_to_server():
	var local_id = multiplayer.get_unique_id()
	players[local_id] = { "name": local_player_name }
	connection_status_changed.emit(LocalizationManager.tr_t("NET_CLIENT_CONNECTED_TO_SERVER") % local_id)
	# Sunucuya kendimizi kaydediyoruz
	rpc_id(1, "register_player", local_player_name, lobby_password)

func _on_connection_failed():
	multiplayer.multiplayer_peer = null
	connection_status_changed.emit(LocalizationManager.tr_t("NET_CLIENT_CONN_FAILED"))

func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	is_in_lobby = true
	is_in_match = false
	game_ended.emit()
	connection_status_changed.emit(LocalizationManager.tr_t("NET_CLIENT_SERVER_LOST"))

## Oyuncu kaydı — sunucu tarafı doğrulama ile.
@rpc("any_peer", "reliable")
func register_player(p_name: String, client_password: String = ""):
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
		
	# Şifre kontrolü
	if multiplayer.is_server() and sender_id != 1:
		if lobby_password != "" and client_password != lobby_password:
			GameLogger.log_warn("Bağlantı şifre uyuşmazlığı nedeniyle reddedildi! İstemci ID: %d" % sender_id, "NETWORK")
			rpc_id(sender_id, "auth_failed", "NET_ERR_WRONG_PASSWORD")
			# İstemciyi kes
			multiplayer.multiplayer_peer.disconnect_peer(sender_id)
			return
	
	# Güvenlik: Oyuncu adı doğrulaması
	var safe_name = p_name.strip_edges().left(32) # Maks 32 karakter
	if safe_name.is_empty():
		safe_name = "%s_%d" % [LocalizationManager.tr_t("PLAYER_DEFAULT"), sender_id]

	players[sender_id] = { "name": safe_name }
	players_updated.emit()
	connection_status_changed.emit(LocalizationManager.tr_t("NET_CLIENT_PEER_JOINED") % [safe_name, sender_id])
	GameEvents.player_joined.emit(sender_id, safe_name)

	# KANONİK ATAMA: sunucu her zaman kanonik 1'dir (kendisiyle eş, tabloya girmesi bile gerekmez).
	# Tek misafir her zaman kanonik 2 — reconnect'te gerçek peer id DEĞİŞİR, bu yüzden önce eski
	# "2" eşlemesi(leri) silinir, sonra bu YENİ gerçek id "2"ye atanır (kanonik numara sabit kalır).
	if multiplayer.is_server() and sender_id != 1:
		var stale_peer_ids: Array = []
		for real_id in canonical_of_peer:
			if canonical_of_peer[real_id] == 2:
				stale_peer_ids.append(real_id)
		for real_id in stale_peer_ids:
			canonical_of_peer.erase(real_id)
		canonical_of_peer[sender_id] = 2
		rpc("sync_canonical_ids", canonical_of_peer)

	# Eğer sunucuysak, güncel oyuncu listesini herkese senkronize ederiz
	if multiplayer.is_server():
		for pid in players:
			rpc("sync_player", pid, players[pid].name)

@rpc("authority", "call_local", "reliable")
func sync_canonical_ids(mapping: Dictionary) -> void:
	canonical_of_peer = mapping

@rpc("authority", "reliable")
func auth_failed(reason_key: String):
	connection_status_changed.emit(LocalizationManager.tr_t(reason_key))
	multiplayer.multiplayer_peer = null
	players.clear()
	is_in_lobby = true
	is_in_match = false
	game_ended.emit()

@rpc("authority", "reliable")
func sync_player(id: int, p_name: String):
	players[id] = { "name": p_name }
	players_updated.emit()

@rpc("authority", "call_local", "reliable")
func start_game():
	is_in_lobby = false
	is_in_match = true
	game_started.emit()

## Sunucu kapanma bildirimi
@rpc("authority", "reliable")
func notify_server_closing():
	connection_status_changed.emit(LocalizationManager.tr_t("NET_SERVER_CLOSING"))

## Oyuncu ayrılma bildirimi (sunucuya gönderilir)
@rpc("any_peer", "reliable")
func notify_player_leaving(p_name: String):
	var sender_id = multiplayer.get_remote_sender_id()
	if players.has(sender_id):
		players.erase(sender_id)
		players_updated.emit()
		connection_status_changed.emit(LocalizationManager.tr_t("NET_CLIENT_PEER_LEFT") % p_name)
