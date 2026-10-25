extends PanelContainer
class_name LobbyPanel

## Çok oyunculu oyun lobisi yönetim paneli.
## main_menu.gd üzerindeki tüm lobi/ağ bağlantı mantığı bu sınıfa kapsüllendi.

signal closed

@onready var ip_input = $Margin/VBox/Grid/IPInput
@onready var port_input = $Margin/VBox/Grid/PortInput
@onready var name_input = $Margin/VBox/Grid/NameInput
@onready var password_input = $Margin/VBox/Grid/PasswordInput
@onready var status_label = $Margin/VBox/StatusLabel
@onready var player_list = $Margin/VBox/PlayerList
@onready var start_match_btn = $Margin/VBox/StartMatchButton
@onready var host_btn = $Margin/VBox/ButtonsHBox/HostButton
@onready var join_btn = $Margin/VBox/ButtonsHBox/JoinButton
@onready var close_lobby_btn = $Margin/VBox/CloseLobbyButton

# Yerelleştirme etiketleri
@onready var title_lbl = $Margin/VBox/LobbyTitle
@onready var name_lbl = $Margin/VBox/Grid/NameLabel
@onready var ip_lbl = $Margin/VBox/Grid/IPLabel
@onready var port_lbl = $Margin/VBox/Grid/PortLabel
@onready var password_lbl = $Margin/VBox/Grid/PasswordLabel
@onready var player_list_lbl = $Margin/VBox/PlayerListLabel

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# Ayarlar menüsünde kalıcı bir kullanıcı adı girildiyse (bkz. settings_overlay.gd) burayı
	# önceden doldur — her seferinde yeniden yazmak zorunda kalınmasın.
	if NetworkManager.local_player_name != "":
		name_input.text = NetworkManager.local_player_name

	# Ağ sinyal bağlantıları
	NetworkManager.connection_status_changed.connect(_on_status_changed)
	NetworkManager.players_updated.connect(_on_players_updated)
	NetworkManager.game_started.connect(_on_game_started)
	
	# Buton sinyal bağlantıları
	host_btn.pressed.connect(_on_host_pressed)
	join_btn.pressed.connect(_on_join_pressed)
	start_match_btn.pressed.connect(_on_start_match_pressed)
	close_lobby_btn.pressed.connect(_on_close_lobby_pressed)
	
	# Yerelleştirme sinyali
	LocalizationManager.locale_changed.connect(update_locale)
	
	# Başlangıç durumu
	start_match_btn.visible = false
	_on_players_updated()
	update_locale()

func update_locale(_new_lang: String = "") -> void:
	if Engine.is_editor_hint():
		return
		
	title_lbl.text = LocalizationManager.tr_t("HOLY_CAMPAIGN")
	name_lbl.text = LocalizationManager.tr_t("SQUAD_NAME")
	ip_lbl.text = LocalizationManager.tr_t("IP_ADDRESS")
	port_lbl.text = LocalizationManager.tr_t("PORT")
	password_lbl.text = LocalizationManager.tr_t("PASSWORD_LBL")
	password_input.placeholder_text = LocalizationManager.tr_t("PASSWORD_PLACEHOLDER")
	name_input.placeholder_text = LocalizationManager.tr_t("NAME_PLACEHOLDER")
	player_list_lbl.text = LocalizationManager.tr_t("SQUADS_ON_FRONT")
	host_btn.text = LocalizationManager.tr_t("HOST_GAME")
	join_btn.text = LocalizationManager.tr_t("JOIN_GAME")
	close_lobby_btn.text = LocalizationManager.tr_t("BACK")
	start_match_btn.text = LocalizationManager.tr_t("START_BATTLE")
	
	# Godot 4'te varsayılan peer OfflineMultiplayerPeer'dır → has_multiplayer_peer() hep TRUE.
	var peer := NetworkManager.multiplayer.multiplayer_peer
	if peer == null or peer is OfflineMultiplayerPeer:
		status_label.text = LocalizationManager.tr_t("STATUS_DEFAULT")

func _on_status_changed(message: String):
	if not is_inside_tree():
		return
	status_label.text = message

func _on_players_updated():
	if Engine.is_editor_hint() or not is_inside_tree():
		return
	player_list.clear()
	for pid in NetworkManager.players:
		var p_info = NetworkManager.players[pid]
		var suffix = " [" + LocalizationManager.tr_t("ROLE_GUARDIAN") + "]" if pid == 1 else " [" + LocalizationManager.tr_t("ROLE_SOLDIER") + "]"
		player_list.add_item(p_info.name + suffix)
		
	# Sadece sunucu (host) maçı başlatabilir ve en az bir diğer oyuncu bağlı olmalıdır
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server() and NetworkManager.players.size() > 1:
		start_match_btn.visible = true
	else:
		start_match_btn.visible = false

func _on_host_pressed():
	var p_name = name_input.text.strip_edges()
	if p_name.is_empty():
		p_name = LocalizationManager.tr_t("SQUAD_LEADER")
	var port = int(port_input.text)
	var password = password_input.text.strip_edges()
	
	GameLogger.log_info("Oyun Kurma butonuna basıldı. Port: %d, İsim: %s" % [port, p_name], "UI")
	var err = NetworkManager.host_game(port, p_name, password)
	if err == OK:
		GameLogger.log_info("Oyun kurma başarılı. Lobi bekleniyor.", "NETWORK")
		host_btn.disabled = true
		join_btn.disabled = true
	else:
		GameLogger.log_error("Oyun kurma başarısız oldu! Hata kodu: %d" % err, "NETWORK")

func _on_join_pressed():
	var p_name = name_input.text.strip_edges()
	if p_name.is_empty():
		p_name = LocalizationManager.tr_t("TRENCH_FIGHTER")
	var ip = ip_input.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	var port = int(port_input.text)
	var password = password_input.text.strip_edges()
	
	GameLogger.log_info("Oyuna Katılma butonuna basıldı. IP: %s, Port: %d, İsim: %s" % [ip, port, p_name], "UI")
	var err = NetworkManager.join_game(ip, port, p_name, password)
	if err == OK:
		GameLogger.log_info("Oyuna bağlantı isteği gönderildi.", "NETWORK")
		host_btn.disabled = true
		join_btn.disabled = true
	else:
		GameLogger.log_error("Bağlantı başlatılamadı! Hata kodu: %d" % err, "NETWORK")

func _on_start_match_pressed():
	GameLogger.log_info("Maçı Başlat butonuna basıldı (Sunucu).", "UI")
	NetworkManager.start_match()

func _on_game_started():
	if not is_inside_tree():
		return
	GameLogger.log_info("Oyun başladı! Sahne yükleniyor.", "NETWORK")
	if has_node("/root/LoadingManager"):
		get_node("/root/LoadingManager").load_scene("res://scenes/game/game.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func _on_close_lobby_pressed():
	GameLogger.log_info("Lobi Geri butonuna basıldı.", "UI")
	NetworkManager.leave_game()
	host_btn.disabled = false
	join_btn.disabled = false
	visible = false
	closed.emit()
