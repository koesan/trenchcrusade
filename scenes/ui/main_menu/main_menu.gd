@tool
extends Control

## Ana Menü koordinatör sınıfı.
## Lobi ve ağ bağlantıları LobbyPanel'e devredildi. Bu sınıf sadece sayfa/menü yönlendirmelerini yönetir.

@onready var lobby_panel: LobbyPanel = %LobbyPanel
@onready var settings_panel = %SettingsPanel
@onready var background: TextureRect = $Background

## Kullanıcı isteği (2026-07-19): "arka plan resmi için bir klasör oluştur, her açıldığında o
## klasördeki rastgele bir resmi seçsin... müzikteki gibi olsun" — AudioManager'ın müzik
## klasörünü tarama deseniyle (bkz. audio_manager.gd _scan_music/_audio_files_in) AYNI mantık:
## bu klasöre resim eklenip çıkarılabilir, kod hiç değişmez. Klasör BOŞSA tscn'deki varsayılan
## texture (Background node'unun ExtResource'u) olduğu gibi kalır — sessiz/güvenli fallback
## (AudioManager'ın playlist boş kalınca sessiz kalmasıyla AYNI desen).
const MENU_BACKGROUNDS_DIR := "res://assets/textures/ui/menu_backgrounds"
const _IMAGE_EXTS := ["png", "jpg", "jpeg", "webp"]

@onready var play_btn = $Margin/HBox/LeftColumn/MenuButtons/PlayButton
@onready var continue_btn = $Margin/HBox/LeftColumn/MenuButtons/ContinueButton
@onready var multiplayer_btn = $Margin/HBox/LeftColumn/MenuButtons/MultiplayerButton
@onready var settings_btn = $Margin/HBox/LeftColumn/MenuButtons/SettingsButton
@onready var quit_btn = $Margin/HBox/LeftColumn/MenuButtons/QuitButton

func _ready():
	if Engine.is_editor_hint():
		GothicThemeHelper.init_ui(self)
		return

	# Menü müziği (menu playlist'i başlangıçta taranır; parça yoksa sessiz).
	AudioManager.play_playlist("menu")

	_pick_random_background()

	# Panel Sinyal Bağlantıları
	settings_panel.close_pressed.connect(_on_close_settings_pressed)
	lobby_panel.closed.connect(_on_close_lobby_pressed)
	
	# Yerelleştirme Sinyali
	LocalizationManager.locale_changed.connect(_update_locale)
	
	# Başlangıç Durumu (Paneller gizli)
	lobby_panel.visible = false
	settings_panel.visible = false
	continue_btn.visible = SaveManager.has_save_game()

	_wire_menu_hints()
	_update_locale()
	GothicThemeHelper.init_ui(self)

func _pick_random_background() -> void:
	var dir := DirAccess.open(MENU_BACKGROUNDS_DIR)
	if dir == null:
		return
	var files := _image_files_in(MENU_BACKGROUNDS_DIR, dir)
	if files.is_empty():
		return
	files.sort()  # belirleyici sıra (tek dosya varsa her zaman AYNI dosya seçilsin)
	var chosen: String = files[randi() % files.size()]
	var tex := load(chosen)
	if tex is Texture2D:
		background.texture = tex
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

## AudioManager._audio_files_in ile AYNI desen (bkz. audio_manager.gd) — export'ta .import
## remap'ini de kapsar, klasöre resim ekleyip çıkarmak kod değişikliği gerektirmez.
func _image_files_in(dir_path: String, dir: DirAccess) -> Array:
	var out: Array = []
	var seen := {}
	for f in dir.get_files():
		var res_path := ""
		if _has_image_ext(f):
			res_path = dir_path + "/" + f
		elif f.ends_with(".import"):
			var orig := f.substr(0, f.length() - ".import".length())
			if _has_image_ext(orig):
				res_path = dir_path + "/" + orig
		if res_path != "" and not seen.has(res_path):
			seen[res_path] = true
			out.append(res_path)
	return out

func _has_image_ext(fname: String) -> bool:
	return fname.get_extension().to_lower() in _IMAGE_EXTS

func _update_locale(_new_lang: String = ""):
	if Engine.is_editor_hint():
		return

	# Sol Sütun Etiketleri
	# Buton metni NE YAPTIĞINI söyler; atmosfer, üzerine gelince alıntı satırında görünen
	# açıklamada (bkz. _wire_menu_hints). Eski "HOLY CAMPAIGN (HOLY CONCLAVE)" gibi etiketler
	# çok oyunculu modu kampanya modu sanmaya yol açıyordu.
	for btn in _menu_hint_keys:
		btn.text = LocalizationManager.tr_t(_menu_hint_keys[btn])
	
	$Margin/HBox/LeftColumn/YearLabel.text = LocalizationManager.tr_t("YEAR_TEXT")
	$Margin/HBox/LeftColumn/FooterHBox/CopyrightLabel.text = LocalizationManager.tr_t("COPYRIGHT")
	$Margin/HBox/LeftColumn/FooterHBox/VersionLabel.text = LocalizationManager.tr_t("VERSION")
	$Margin/HBox/LeftColumn/QuoteLabel.text = LocalizationManager.tr_t("QUOTE_TEXT")

## Buton → lokalizasyon anahtarı. Açıklama anahtarı aynı adın `_DESC` ekli halidir.
var _menu_hint_keys: Dictionary = {}

## ÜZERİNE GELİNCE AÇIKLAMA: alıntı satırı (QuoteLabel) geçici olarak butonun açıklamasını
## gösterir, ayrılınca alıntıya döner. Yeni bir panel/yerleşim EKLEMEZ — var olan satırı kullanır.
func _wire_menu_hints() -> void:
	_menu_hint_keys = {
		continue_btn: "MENU_CONTINUE",
		play_btn: "MENU_LOCAL",
		multiplayer_btn: "MENU_ONLINE",
		settings_btn: "MENU_SETTINGS",
		quit_btn: "MENU_QUIT",
	}
	var quote: Label = $Margin/HBox/LeftColumn/QuoteLabel
	for btn in _menu_hint_keys:
		var desc_key: String = _menu_hint_keys[btn] + "_DESC"
		btn.mouse_entered.connect(func(): quote.text = LocalizationManager.tr_t(desc_key))
		btn.focus_entered.connect(func(): quote.text = LocalizationManager.tr_t(desc_key))
		btn.mouse_exited.connect(func(): quote.text = LocalizationManager.tr_t("QUOTE_TEXT"))

func _on_continue_pressed():
	GameLogger.log_info("Devam Et butonuna basıldı. Kaydedilen sefer yükleniyor.", "UI")
	SaveManager.load_game()

func _on_local_pressed():
	GameLogger.log_info("Yerel Savaş başlatılıyor.", "UI")
	NetworkManager.leave_game()
	if is_inside_tree() and has_node("/root/LoadingManager"):
		get_node("/root/LoadingManager").load_scene("res://scenes/game/game.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func _on_quit_pressed():
	GameLogger.log_info("Oyundan Çıkış butonuna basıldı.", "UI")
	get_tree().quit()

func _on_multiplayer_pressed():
	GameLogger.log_info("Çok Oyunculu (Lobi) paneli açılıyor.", "UI")
	if lobby_panel.visible:
		lobby_panel.visible = false
	else:
		settings_panel.visible = false
		lobby_panel.visible = true

func _on_settings_pressed():
	GameLogger.log_info("Ayarlar paneli açılıyor.", "UI")
	if settings_panel.visible:
		settings_panel.visible = false
	else:
		lobby_panel.visible = false
		settings_panel.visible = true
		settings_panel.load_settings()

func _on_close_lobby_pressed():
	GameLogger.log_info("Lobi kapatıldı, ana menüye dönüldü.", "UI")
	lobby_panel.visible = false

func _on_close_settings_pressed():
	GameLogger.log_info("Ayarlar kapatıldı, ana menüye dönüldü.", "UI")
	settings_panel.visible = false
