extends CanvasLayer

## Küresel Yükleme Ekranı Yöneticisi (Autoload).
## Sahne geçişlerini asenkron (load_threaded_request) yaparak ana iş parçacığının
## donmasını engeller ve yükleme animasyonunun pürüzsüz çalışmasını sağlar.
## Ayrıca oyun sahnesine geçerken tüm faksiyonların 3D modellerini arka planda
## asenkron yükleyip önbelleğe alarak oyun içi takılmaları tamamen önler.

const LOADING_OVERLAY_SCENE = preload("res://scenes/ui/overlays/loading/loading_overlay.tscn")
var _overlay: Control = null
var _loading_scene_path: String = ""
var _is_loading: bool = false
var _models_to_preload: Array[String] = []

func _ready() -> void:
	# Diğer tüm CanvasLayer'ların (hud vb.) üstünde çizilmesi için yüksek katman
	layer = 120
	
	_overlay = LOADING_OVERLAY_SCENE.instantiate()
	add_child(_overlay)
	_overlay.visible = false
	set_process(false)
	GraphicsSettings.apply(get_tree())

## Godot, proje ayarındaki özel fare imlecinin (display/mouse_cursor/custom_image) dokusunu
## çıkışta serbest bırakmıyor → her kapanışta "Texture RID leaked" hatası. Ağaç kapanırken
## imleci temizlemek dokuyu bırakır (boş bir projede doğrulandı). Tüm çıkış yollarını kapsar.
## Aynı nedenle süren önizleme yüklemeleri de burada toplanır (bkz. UIPreviewHelper._pending).
func _exit_tree() -> void:
	Input.set_custom_mouse_cursor(null)
	UIPreviewHelper.flush_pending()

const GAME_SCENE := "res://scenes/game/game.tscn"
## Yükleme ekranının en kısa görünme süresi — çok hızlı geçişlerde ekran bir kare yanıp sönmesin.
const MIN_VISIBLE_SEC := 0.6
var _started_at: int = 0
var _fade: Tween = null

## Tüm faksiyonların birim modelleri (henüz önbellekte olmayanlar). Açılışta (boot) ve oyun
## sahnesine geçerken arka planda yüklenir — yerleştirme kartları ve savaş takılmadan açılır.
func unit_model_paths() -> Array[String]:
	var out: Array[String] = []
	for faction in GameState.available_factions:
		for ud in faction.available_units:
			if ud and not ud.model_scene_path.is_empty():
				var path: String = ud.model_scene_path
				if not out.has(path) and not UIPreviewHelper.model_cache.has(path):
					out.append(path)
	return out

## `scene_path`e yükleme ekranı arkasında geçer. `extra_preload`: geçişle birlikte arka planda
## ısıtılacak birim modelleri. Oyun sahnesi kendini hazır edince hide_loading() çağırır; diğer
## sahnelerde ekran sahne değişiminden sonra kendiliğinden solar.
func load_scene(scene_path: String, extra_preload: Array[String] = []) -> void:
	_loading_scene_path = scene_path
	_is_loading = true
	_started_at = Time.get_ticks_msec()
	_models_to_preload = extra_preload.duplicate()

	# Yükleme ekranını göster
	if is_instance_valid(_overlay):
		if _fade != null and _fade.is_valid():
			_fade.kill()
		_overlay.modulate.a = 1.0
		_overlay.visible = true
		if _overlay.has_method("update_locale"):
			_overlay.update_locale()

	if scene_path == GAME_SCENE:
		for path in unit_model_paths():
			if not _models_to_preload.has(path):
				_models_to_preload.append(path)
	for path in _models_to_preload:
		ResourceLoader.load_threaded_request(path)
	if not _models_to_preload.is_empty():
		GameLogger.log_info("Yükleme Ekranı: %d adet 3D model arka planda ön-yükleniyor." % _models_to_preload.size(), "SYSTEM")
	
	# Godot'un arka planda asenkron yüklemesini başlat
	var err = ResourceLoader.load_threaded_request(scene_path)
	if err != OK:
		GameLogger.log_error("Asenkron sahne yükleme başlatılamadı: %s" % scene_path, "SYSTEM")
		# Hata durumunda direkt senkron yükle (fallback)
		get_tree().change_scene_to_file(scene_path)
		hide_loading()
		return
		
	set_process(true)

## Yükleme ekranını yumuşakça (kısa solma) kapatır.
func hide_loading() -> void:
	_is_loading = false
	set_process(false)
	if not is_instance_valid(_overlay) or not _overlay.visible:
		return
	if _fade != null and _fade.is_valid():
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(_overlay, "modulate:a", 0.0, 0.35)
	_fade.tween_callback(func(): _overlay.visible = false)

func _process(_delta: float) -> void:
	if not _is_loading or _loading_scene_path.is_empty():
		return
		
	# İlerlemeyi kontrol et (Ana sahne)
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(_loading_scene_path, progress)
	var main_progress = progress[0] if progress.size() > 0 else 0.0
	
	# Model yüklemelerini kontrol et
	var total_model_progress = 0.0
	var all_models_loaded = true
	
	for path in _models_to_preload:
		var model_prog = []
		var model_status = ResourceLoader.load_threaded_get_status(path, model_prog)
		if model_status == ResourceLoader.THREAD_LOAD_LOADED:
			total_model_progress += 1.0
		elif model_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			all_models_loaded = false
			total_model_progress += model_prog[0] if model_prog.size() > 0 else 0.0
		else:
			# Bozuk/eksik model yüklemeyi KİLİTLEMEZ — atlanır (oyunda yedek görünüm kullanılır).
			total_model_progress += 1.0
			
	# Toplam ilerleme oranı (Ana sahne + Modeller)
	var total_items = 1.0 + _models_to_preload.size()
	var current_progress = (main_progress + total_model_progress) / total_items
	
	if is_instance_valid(_overlay) and _overlay.has_method("set_progress_value"):
		_overlay.set_progress_value(current_progress)
	
	if status == ResourceLoader.THREAD_LOAD_LOADED and all_models_loaded \
			and Time.get_ticks_msec() - _started_at >= int(MIN_VISIBLE_SEC * 1000.0):
		# Modelleri UIPreviewHelper cache'ine aktar
		for path in _models_to_preload:
			if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_LOADED:
				continue
			var model_scene = ResourceLoader.load_threaded_get(path)
			if model_scene:
				UIPreviewHelper.model_cache[path] = model_scene
				
		# Yükleme bitti, sahneye geç
		var packed_scene = ResourceLoader.load_threaded_get(_loading_scene_path)
		var path := _loading_scene_path
		_is_loading = false
		set_process(false)
		if packed_scene:
			get_tree().change_scene_to_packed(packed_scene)
		else:
			GameLogger.log_error("Sahne yüklenemedi: %s" % path, "SYSTEM")
		# Grafik ön ayarı yeni sahnenin ortamına da uygulanır. Oyun sahnesi hazır olunca yükleme
		# ekranını kendisi kapatır; diğer sahneler ilk karelerini çizince solar.
		await get_tree().process_frame
		GraphicsSettings.apply(get_tree())
		if path != GAME_SCENE or not packed_scene:
			await get_tree().process_frame
			hide_loading()
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		GameLogger.log_error("Asenkron sahne yükleme başarısız: %s" % _loading_scene_path, "SYSTEM")
		hide_loading()
