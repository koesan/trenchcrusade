## GRAFİK KALİTESİ ve KARE HIZI — farklı donanımlarda akıcı çalışma.
##
## Üç ön ayar (Düşük / Orta / Yüksek) 3B çözünürlük ölçeğini (FSR ile büyütme), kenar
## yumuşatmayı, gölge çözünürlüğünü/yumuşaklığını ve ortam efektlerini (SSAO, parlama) birlikte
## ayarlar. Ayar ilk açılışta ekran kartı türüne göre seçilir (tümleşik kart → Orta, yazılım/sanal
## → Düşük, harici → Yüksek); oyuncu Ayarlar → Grafik'ten değiştirebilir. Kare hızı sınırı pil ve
## ısınma için ayrıca seçilebilir.
##
## Ayar `user://settings.cfg` [graphics] altında tutulur. Sahne değişince (LoadingManager) yeni
## sahnedeki WorldEnvironment'lara yeniden uygulanır.
class_name GraphicsSettings
extends RefCounted

const LOW := 0
const MEDIUM := 1
const HIGH := 2
const CONFIG_PATH := "user://settings.cfg"
## Kare hızı sınırı seçenekleri (0 = sınırsız). Ayarlar menüsündeki sırayla aynı.
const FPS_LIMITS := [0, 30, 60, 120, 144]

## Ön ayar → değerler. scale: 3B çözünürlük oranı (UI keskin kalır, yalnız sahne ölçeklenir).
const PRESETS := {
	LOW: {"scale": 0.67, "msaa": Viewport.MSAA_DISABLED, "fxaa": true, "shadow_atlas": 2048,
		"soft": RenderingServer.SHADOW_QUALITY_HARD, "ssao": false, "glow": false},
	MEDIUM: {"scale": 0.85, "msaa": Viewport.MSAA_DISABLED, "fxaa": true, "shadow_atlas": 4096,
		"soft": RenderingServer.SHADOW_QUALITY_SOFT_LOW, "ssao": false, "glow": true},
	HIGH: {"scale": 1.0, "msaa": Viewport.MSAA_2X, "fxaa": false, "shadow_atlas": 4096,
		"soft": RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM, "ssao": true, "glow": true},
}

static var _quality: int = -1
static var _fps_index: int = -1

## Ekran kartına göre önerilen ön ayar (ilk açılış).
static func recommended_quality() -> int:
	match RenderingServer.get_video_adapter_type():
		RenderingDevice.DEVICE_TYPE_DISCRETE_GPU:
			return HIGH
		RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU:
			return MEDIUM
		RenderingDevice.DEVICE_TYPE_OTHER:
			return MEDIUM
	return LOW  # sanal / yazılım (CPU) çizici

static func quality() -> int:
	if _quality < 0:
		_load()
	return _quality

static func fps_index() -> int:
	if _fps_index < 0:
		_load()
	return _fps_index

static func _load() -> void:
	var cfg := ConfigFile.new()
	var ok := cfg.load(CONFIG_PATH) == OK
	_quality = clampi(int(cfg.get_value("graphics", "quality", recommended_quality())) if ok else recommended_quality(), LOW, HIGH)
	_fps_index = clampi(int(cfg.get_value("graphics", "fps_limit", 0)) if ok else 0, 0, FPS_LIMITS.size() - 1)

static func set_quality(q: int, tree: SceneTree) -> void:
	_quality = clampi(q, LOW, HIGH)
	apply(tree)

static func set_fps_index(i: int) -> void:
	_fps_index = clampi(i, 0, FPS_LIMITS.size() - 1)
	Engine.max_fps = FPS_LIMITS[_fps_index]

## Geçerli ön ayarı kök görünüme, gölge sunucusuna ve sahnedeki tüm ortamlara uygular.
static func apply(tree: SceneTree) -> void:
	if tree == null or DisplayServer.get_name() == "headless":
		return
	var p: Dictionary = PRESETS[quality()]
	var vp: Viewport = tree.root
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if p["scale"] < 1.0 else Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = p["scale"]
	vp.msaa_3d = p["msaa"]
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if p["fxaa"] else Viewport.SCREEN_SPACE_AA_DISABLED
	RenderingServer.directional_shadow_atlas_set_size(p["shadow_atlas"], true)
	RenderingServer.directional_soft_shadow_filter_set_quality(p["soft"])
	Engine.max_fps = FPS_LIMITS[fps_index()]
	for node in tree.root.find_children("*", "WorldEnvironment", true, false):
		var env: Environment = (node as WorldEnvironment).environment
		if env != null:
			env.ssao_enabled = p["ssao"]
			env.glow_enabled = p["glow"]
