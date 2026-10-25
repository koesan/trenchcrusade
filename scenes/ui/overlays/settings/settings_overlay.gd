extends OverlayPanel


@onready var res_option = $Panel/Margin/VBox/TabContainer/Graphics/ResHBox/ResOption
@onready var screen_mode_option = $Panel/Margin/VBox/TabContainer/Graphics/ScreenModeHBox/ScreenModeOption
@onready var vsync_check = $Panel/Margin/VBox/TabContainer/Graphics/VsyncHBox/VsyncCheck
## "Hareketi azalt": arayüz açılış animasyonlarını kapatır (bkz. UIAnim).
@onready var motion_check: CheckBox = $Panel/Margin/VBox/TabContainer/Graphics/MotionHBox/MotionCheck
## Grafik kalitesi ön ayarı ve kare hızı sınırı (bkz. GraphicsSettings).
@onready var quality_option: OptionButton = $Panel/Margin/VBox/TabContainer/Graphics/QualityHBox/QualityOption
@onready var fps_option: OptionButton = $Panel/Margin/VBox/TabContainer/Graphics/FpsHBox/FpsOption

@onready var master_slider = $Panel/Margin/VBox/TabContainer/Audio/MasterHBox/MasterSlider
@onready var music_slider = $Panel/Margin/VBox/TabContainer/Audio/MusicHBox/MusicSlider
@onready var sfx_slider = $Panel/Margin/VBox/TabContainer/Audio/SfxHBox/SfxSlider
@onready var ambient_slider = $Panel/Margin/VBox/TabContainer/Audio/AmbientHBox/AmbientSlider

# Müzik oynatıcı kontrolleri
@onready var now_playing_label = $Panel/Margin/VBox/TabContainer/Audio/NowPlayingHBox/NowPlayingLabel
@onready var prev_btn = $Panel/Margin/VBox/TabContainer/Audio/PlayerControls/PrevBtn
@onready var next_btn = $Panel/Margin/VBox/TabContainer/Audio/PlayerControls/NextBtn
@onready var shuffle_check = $Panel/Margin/VBox/TabContainer/Audio/PlayerControls/ShuffleCheck
@onready var loop_check = $Panel/Margin/VBox/TabContainer/Audio/PlayerControls/LoopCheck

@onready var lang_option = $Panel/Margin/VBox/TabContainer/Language/LangHBox/LangOption
@onready var player_name_input: LineEdit = $Panel/Margin/VBox/TabContainer/Language/PlayerNameHBox/PlayerNameInput

const CONFIG_PATH = "user://settings.cfg"

func _bind_controls() -> void:
	# Signal connections for settings changes
	res_option.item_selected.connect(_on_res_option_selected)
	screen_mode_option.item_selected.connect(_on_screen_mode_selected)
	vsync_check.toggled.connect(_on_vsync_toggled)
	quality_option.item_selected.connect(func(i: int):
		GraphicsSettings.set_quality(i, get_tree())
		save_settings())
	fps_option.item_selected.connect(func(i: int):
		GraphicsSettings.set_fps_index(i)
		save_settings())
	motion_check.toggled.connect(func(v: bool):
		UIAnim.reduced_motion = v
		save_settings())
	
	master_slider.value_changed.connect(_on_master_slider_changed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	ambient_slider.value_changed.connect(func(v): _apply_volume("Ambient", v))

	master_slider.drag_ended.connect(func(_val_changed): save_settings())
	music_slider.drag_ended.connect(func(_val_changed): save_settings())
	sfx_slider.drag_ended.connect(func(_val_changed): save_settings())
	ambient_slider.drag_ended.connect(func(_val_changed): save_settings())

	# Müzik oynatıcı — AudioManager'a bağla (tek kaynak; UI yalnız kontrol eder).
	prev_btn.pressed.connect(AudioManager.prev_track)
	next_btn.pressed.connect(AudioManager.next_track)
	shuffle_check.toggled.connect(func(on): AudioManager.set_shuffle(on); save_settings())
	loop_check.toggled.connect(func(on): AudioManager.set_loop(on); save_settings())
	AudioManager.now_playing_changed.connect(_on_now_playing_changed)
	
	lang_option.item_selected.connect(_on_lang_option_selected)

	player_name_input.text_changed.connect(_on_player_name_changed)
	player_name_input.text_submitted.connect(func(_t): save_settings())
	player_name_input.focus_exited.connect(save_settings)
	
	$Panel/Margin/VBox/CloseSettingsBtn.pressed.connect(func():
		save_settings()
		close_pressed.emit()
	)
	
	if not Engine.is_editor_hint():
		load_settings()

func update_locale(_new_lang: String = "") -> void:
	$Panel/Margin/VBox/Title.text = LocalizationManager.tr_t("ORDINANCES")
	# İKON-ONLY BUTONLAR: ⏮/⏭ müzik kontrollerinin hiçbir etiketi ya da tooltip'i YOKTU —
	# ne yaptıkları yalnız tahmin edilebiliyordu. Tooltip metni lokalize olmak zorunda
	# olduğu için .tscn'e yazılamaz, burada atanır (top_bar'daki ikon butonlarla aynı desen).
	prev_btn.tooltip_text = LocalizationManager.tr_t("PREV_TRACK")
	next_btn.tooltip_text = LocalizationManager.tr_t("NEXT_TRACK")
	$Panel/Margin/VBox/CloseSettingsBtn.text = "✓ " + LocalizationManager.tr_t("APPLY_CHANGES")
	
	var tab_container = $Panel/Margin/VBox/TabContainer
	tab_container.set_tab_title(0, LocalizationManager.tr_t("TAB_GRAPHICS"))
	tab_container.set_tab_title(1, LocalizationManager.tr_t("TAB_AUDIO"))
	tab_container.set_tab_title(2, LocalizationManager.tr_t("TAB_LANGUAGE"))
	tab_container.set_tab_title(3, LocalizationManager.tr_t("TAB_CONTROLS"))
	
	$Panel/Margin/VBox/TabContainer/Graphics/ResHBox/Label.text = LocalizationManager.tr_t("RESOLUTION")
	$Panel/Margin/VBox/TabContainer/Graphics/ScreenModeHBox/Label.text = LocalizationManager.tr_t("SCREEN_MODE")
	$Panel/Margin/VBox/TabContainer/Graphics/VsyncHBox/Label.text = LocalizationManager.tr_t("VSYNC")
	$Panel/Margin/VBox/TabContainer/Graphics/MotionHBox/Label.text = LocalizationManager.tr_t("REDUCE_MOTION")
	$Panel/Margin/VBox/TabContainer/Graphics/QualityHBox/Label.text = LocalizationManager.tr_t("GRAPHICS_QUALITY")
	$Panel/Margin/VBox/TabContainer/Graphics/FpsHBox/Label.text = LocalizationManager.tr_t("FPS_LIMIT")
	for i in 3:
		quality_option.set_item_text(i, LocalizationManager.tr_t(["QUALITY_LOW", "QUALITY_MEDIUM", "QUALITY_HIGH"][i]))
	fps_option.set_item_text(0, LocalizationManager.tr_t("FPS_UNLIMITED"))
	
	screen_mode_option.set_item_text(0, LocalizationManager.tr_t("SCREEN_FULLSCREEN"))
	screen_mode_option.set_item_text(1, LocalizationManager.tr_t("SCREEN_WINDOWED"))
	
	$Panel/Margin/VBox/TabContainer/Audio/MasterHBox/Label.text = LocalizationManager.tr_t("MASTER_VOLUME")
	$Panel/Margin/VBox/TabContainer/Audio/MusicHBox/Label.text = LocalizationManager.tr_t("MUSIC")
	$Panel/Margin/VBox/TabContainer/Audio/SfxHBox/Label.text = LocalizationManager.tr_t("SFX")
	$Panel/Margin/VBox/TabContainer/Audio/AmbientHBox/Label.text = LocalizationManager.tr_t("AMBIENT")
	$Panel/Margin/VBox/TabContainer/Audio/NowPlayingHBox/Label.text = LocalizationManager.tr_t("NOW_PLAYING")
	shuffle_check.text = LocalizationManager.tr_t("SHUFFLE")
	loop_check.text = LocalizationManager.tr_t("LOOP")
	
	$Panel/Margin/VBox/TabContainer/Language/LangHBox/Label.text = LocalizationManager.tr_t("SELECT_LANGUAGE")
	$Panel/Margin/VBox/TabContainer/Language/PlayerNameHBox/Label.text = LocalizationManager.tr_t("PLAYER_NAME")
	player_name_input.placeholder_text = LocalizationManager.tr_t("PLAYER_NAME")
	
	# Keybindings Labels Translation
	var grid = $Panel/Margin/VBox/TabContainer/Controls/Grid
	grid.get_node("ForwardLbl").text = LocalizationManager.tr_t("KEY_CAM_FORWARD")
	grid.get_node("ForwardVal").text = LocalizationManager.tr_t("KEY_VAL_FORWARD")
	grid.get_node("BackLbl").text = LocalizationManager.tr_t("KEY_CAM_BACK")
	grid.get_node("BackVal").text = LocalizationManager.tr_t("KEY_VAL_BACK")
	grid.get_node("LeftLbl").text = LocalizationManager.tr_t("KEY_CAM_LEFT")
	grid.get_node("LeftVal").text = LocalizationManager.tr_t("KEY_VAL_LEFT")
	grid.get_node("RightLbl").text = LocalizationManager.tr_t("KEY_CAM_RIGHT")
	grid.get_node("RightVal").text = LocalizationManager.tr_t("KEY_VAL_RIGHT")
	grid.get_node("SelectLbl").text = LocalizationManager.tr_t("KEY_SELECT")
	grid.get_node("SelectVal").text = LocalizationManager.tr_t("KEY_VAL_CLICK")
	grid.get_node("OrbitLbl").text = LocalizationManager.tr_t("KEY_ORBIT")
	grid.get_node("OrbitVal").text = LocalizationManager.tr_t("KEY_VAL_DRAG")
	grid.get_node("RotateLbl").text = LocalizationManager.tr_t("KEY_ROTATE")
	grid.get_node("RotateVal").text = LocalizationManager.tr_t("KEY_VAL_ROTATE")
	grid.get_node("ZoomLbl").text = LocalizationManager.tr_t("KEY_ZOOM")
	grid.get_node("ZoomVal").text = LocalizationManager.tr_t("KEY_VAL_WHEEL")
	grid.get_node("FocusLbl").text = LocalizationManager.tr_t("KEY_FOCUS")
	grid.get_node("FocusVal").text = LocalizationManager.tr_t("KEY_VAL_FOCUS")
	
	_rebuild_language_list()

## Panel her açıldığında ayarları diskten TEKRAR okur — böylece panel, oyun sırasında
## başka bir yoldan değişmiş olabilecek değerleri (ör. ses seviyesi) bayat göstermez.
func open_panel() -> void:
	load_settings()

func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_PATH)
	
	if err == OK:
		var res_idx = config.get_value("graphics", "resolution", 1)
		res_option.selected = res_idx
		
		var mode_idx = config.get_value("graphics", "screen_mode", 1)
		screen_mode_option.selected = mode_idx
		# `_apply_screen_mode` her iki dalda da `_apply_resolution`ı çağırır → referans ölçek
		# oyun açılışında da uygulanmış olur (eskiden yalnız pencere boyutu ayarlanıyordu).
		_apply_screen_mode(mode_idx)
		
		var vsync = config.get_value("graphics", "vsync", true)
		vsync_check.button_pressed = vsync
		_apply_vsync(vsync)
		quality_option.select(GraphicsSettings.quality())
		fps_option.select(GraphicsSettings.fps_index())
		GraphicsSettings.apply(get_tree())
		var reduced: bool = config.get_value("graphics", "reduced_motion", false)
		motion_check.set_pressed_no_signal(reduced)
		UIAnim.reduced_motion = reduced
		
		var master_vol = config.get_value("audio", "master", 80.0)
		master_slider.value = master_vol
		_apply_volume("Master", master_vol)
		
		var music_vol = config.get_value("audio", "music", 60.0)
		music_slider.value = music_vol
		_apply_volume("Music", music_vol)
		
		var sfx_vol = config.get_value("audio", "sfx", 90.0)
		sfx_slider.value = sfx_vol
		_apply_volume("SFX", sfx_vol)

		var ambient_vol = config.get_value("audio", "ambient", 70.0)
		ambient_slider.value = ambient_vol
		_apply_volume("Ambient", ambient_vol)

		_init_music_player(
			config.get_value("audio", "shuffle", false),
			config.get_value("audio", "loop", true))

		var lang = config.get_value("language", "lang", "tr")
		LocalizationManager.set_language(lang)
		lang_option.selected = 0 if lang == "tr" else 1

		var saved_name: String = config.get_value("player", "name", "")
		player_name_input.text = saved_name
		if saved_name != "":
			NetworkManager.local_player_name = saved_name
	else:
		_apply_screen_mode(screen_mode_option.selected)
		_apply_vsync(vsync_check.button_pressed)
		quality_option.select(GraphicsSettings.quality())
		fps_option.select(GraphicsSettings.fps_index())
		GraphicsSettings.apply(get_tree())
		_apply_volume("Master", master_slider.value)
		_apply_volume("Music", music_slider.value)
		_apply_volume("SFX", sfx_slider.value)
		_apply_volume("Ambient", ambient_slider.value)
		_init_music_player(false, true)

		var lang = LocalizationManager.current_language
		lang_option.selected = 0 if lang == "tr" else 1
		save_settings()

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("graphics", "resolution", res_option.selected)
	config.set_value("graphics", "screen_mode", screen_mode_option.selected)
	config.set_value("graphics", "vsync", vsync_check.button_pressed)
	config.set_value("graphics", "reduced_motion", motion_check.button_pressed)
	config.set_value("graphics", "quality", GraphicsSettings.quality())
	config.set_value("graphics", "fps_limit", GraphicsSettings.fps_index())
	
	config.set_value("audio", "master", master_slider.value)
	config.set_value("audio", "music", music_slider.value)
	config.set_value("audio", "sfx", sfx_slider.value)
	config.set_value("audio", "ambient", ambient_slider.value)
	config.set_value("audio", "shuffle", shuffle_check.button_pressed)
	config.set_value("audio", "loop", loop_check.button_pressed)
	
	config.set_value("language", "lang", LocalizationManager.current_language)
	config.set_value("player", "name", player_name_input.text.strip_edges())
	config.save(CONFIG_PATH)

## Seçilebilir çözünürlükler — ResOption öğeleriyle AYNI SIRADA olmalı (.tscn'deki popup metinleri).
const RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

## Çözünürlük seçimi artık HER MODDA etkilidir.
##
## KÖK NEDEN DÜZELTMESİ (kullanıcı bildirimi: "çözünürlük seçince hiçbir şey değişmiyor"):
## eski kod `window_set_size`i YALNIZ pencereli modda çağırıyordu — tam ekranda ayar tamamen
## no-op'tu. Pencereli modda bile yalnız pencere büyüyor, arayüz ölçeği aynı kalıyordu.
##
## Artık seçim ARAYÜZ REFERANSIDIR (bkz. display_scale.gd): mantıksal alan ondan türetilir, yani
## tam ekranda da arayüz gözle görülür şekilde ölçeklenir. Pencereli modda ayrıca pencere de o
## boyuta getirilir.
func _apply_resolution(idx: int) -> void:
	if idx < 0 or idx >= RESOLUTIONS.size():
		return
	var size: Vector2i = RESOLUTIONS[idx]
	if screen_mode_option.selected == 1:  # Pencereli
		DisplayServer.window_set_size(size)
		var screen := DisplayServer.window_get_current_screen()
		var screen_size := DisplayServer.screen_get_size(screen)
		DisplayServer.window_set_position((screen_size - size) / 2)
	DisplayScale.set_reference_size(size, get_window())

func _apply_screen_mode(idx: int) -> void:
	if idx == 0:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		# Tam ekranda da seçili çözünürlük arayüz referansı olarak geçerlidir.
		_apply_resolution(res_option.selected)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_apply_resolution(res_option.selected)

func _apply_vsync(enabled: bool) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED)

func _apply_volume(bus_name: String, val: float) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(val / 100.0))
		AudioServer.set_bus_mute(idx, val == 0.0)

## Müzik oynatıcı kontrollerini AudioManager durumuyla eşitler (tek kaynak AudioManager).
func _init_music_player(shuffle_on: bool, loop_on: bool) -> void:
	shuffle_check.button_pressed = shuffle_on
	loop_check.button_pressed = loop_on
	AudioManager.set_shuffle(shuffle_on)
	AudioManager.set_loop(loop_on)
	_on_now_playing_changed(AudioManager.get_now_playing())

func _on_now_playing_changed(title: String) -> void:
	if is_instance_valid(now_playing_label):
		now_playing_label.text = title if title != "" else "—"

# Option changes listeners
func _on_res_option_selected(index: int) -> void:
	_apply_resolution(index)
	save_settings()

func _on_screen_mode_selected(index: int) -> void:
	_apply_screen_mode(index)
	save_settings()

func _on_vsync_toggled(button_pressed: bool) -> void:
	_apply_vsync(button_pressed)
	save_settings()

func _on_master_slider_changed(value: float) -> void:
	_apply_volume("Master", value)

func _on_music_slider_changed(value: float) -> void:
	_apply_volume("Music", value)

func _on_sfx_slider_changed(value: float) -> void:
	_apply_volume("SFX", value)

func _on_player_name_changed(new_text: String) -> void:
	var trimmed := new_text.strip_edges()
	if trimmed != "":
		NetworkManager.local_player_name = trimmed

## Dil listesini KEŞFEDİLEN dillerden kurar — sabit bir tr/en listesi YOKTUR.
##
## Kullanıcı isteği: "bir kişi json'u farklı dile çevirip klasöre ekleyince oyun arayüzünde
## otomatik görünsün". Menü bu yüzden `LocalizationManager.available_languages`ten üretilir;
## her dilin adı kendi dosyasındaki `LANGUAGE_NAME` anahtarından gelir.
func _rebuild_language_list() -> void:
	lang_option.clear()
	var langs: Array = LocalizationManager.available_languages
	for i in langs.size():
		var code: String = langs[i]
		lang_option.add_item(LocalizationManager.language_display_name(code), i)
		# Kod, seçim işlendiğinde geri okunmak üzere öğeye iliştirilir — sıraya güvenilmez.
		lang_option.set_item_metadata(i, code)
		if code == LocalizationManager.current_language:
			lang_option.selected = i

func _on_lang_option_selected(index: int) -> void:
	var code = lang_option.get_item_metadata(index)
	if code == null:
		return
	LocalizationManager.set_language(String(code))
	save_settings()
