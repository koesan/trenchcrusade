extends RefCounted

## "Bu el hangi modeli oynatabilirim?" — ActivationCues durum kararı, grafik ön ayarları,
## açılış yükleme ekranı ve yönlendirici bildirim tonu.

class FakeUnit extends Node3D:
	var owner_id: int = 1
	var current_health: int = 1
	var has_moved: bool = false
	var activation_started: bool = false
	var actions_taken: Array = []
	var stood_up_this_activation: bool = false
	var unit_data: Resource = UnitData.new()
	var fireteam_partner = null
	var joint_partner = null
	var fireteam_sworn: bool = false
	var display_name: String = "Sahte"

func run(t) -> void:
	# ── Aktivasyon ipuçları ─────────────────────────────────────────────────
	var a := FakeUnit.new()
	var b := FakeUnit.new()
	var foe := FakeUnit.new()
	foe.owner_id = 2
	a.name = "a"
	for u in [a, b, foe]:
		t.add_child(u)
	var units := {"a": a, "b": b, "f": foe}
	t.eq(ActivationCues.state_of(a, units, 1, "", true), ActivationCues.READY, "Sırası gelen oyuncunun boştaki modeli hazır")
	t.eq(ActivationCues.state_of(foe, units, 1, "", true), ActivationCues.IDLE, "Rakibin modeli sıra beklerken normal")
	t.eq(ActivationCues.state_of(a, units, 1, "", false), ActivationCues.IDLE, "Ağ oyununda başkasının modeli vurgulanmaz")
	a.actions_taken = [&"march"]
	t.eq(ActivationCues.state_of(a, units, 1, "", true), ActivationCues.ACTIVE, "Eylem yapmış, bitmemiş model aktif")
	t.eq(ActivationCues.state_of(b, units, 1, "", true), ActivationCues.WAITING, "Başka model aktifken diğerleri bekler")
	a.has_moved = true
	t.eq(ActivationCues.state_of(a, units, 1, "", true), ActivationCues.SPENT, "Aktivasyonu biten model söner")
	t.eq(ActivationCues.state_of(b, units, 1, "", true), ActivationCues.READY, "Aktivasyon bitince sıradaki model hazır")
	a.has_moved = false
	a.actions_taken = []
	t.eq(ActivationCues.state_of(b, units, 1, "a", true), ActivationCues.WAITING, "Hold Your Fire: zorunlu model dışındakiler bekler")
	t.eq(ActivationCues.state_of(a, units, 1, "a", true), ActivationCues.READY, "Hold Your Fire: zorunlu model hazır")
	var shader := FileAccess.get_file_as_string("res://assets/shaders/team_ring.gdshader")
	t.ok(shader.contains("instance uniform float pulse"), "Takım halkası hazır/aktif durumunu çizer")
	var top := FileAccess.get_file_as_string("res://scenes/ui/hud/top_bar/top_bar.gd")
	t.ok(top.contains("STATUS_ACTIVE_UNIT") and top.contains("STATUS_READY_COUNT"), "Üst bar aktif modeli / hazır sayısını gösterir")

	# ── Grafik ön ayarları ──────────────────────────────────────────────────
	for q in [GraphicsSettings.LOW, GraphicsSettings.MEDIUM, GraphicsSettings.HIGH]:
		t.ok(GraphicsSettings.PRESETS.has(q), "Ön ayar tanımlı: %d" % q)
	t.ok(GraphicsSettings.PRESETS[GraphicsSettings.LOW]["scale"] < GraphicsSettings.PRESETS[GraphicsSettings.HIGH]["scale"],
		"Düşük ayar daha düşük 3B çözünürlükte çizer")
	t.ok(not GraphicsSettings.PRESETS[GraphicsSettings.LOW]["ssao"], "Düşük ayarda SSAO kapalı")
	t.eq(GraphicsSettings.FPS_LIMITS[0], 0, "İlk kare hızı seçeneği sınırsız")
	var saved_fps := Engine.max_fps
	GraphicsSettings.set_fps_index(99)
	t.eq(Engine.max_fps, GraphicsSettings.FPS_LIMITS[-1], "Geçersiz kare hızı indeksi sınırlanır")
	Engine.max_fps = saved_fps
	var proj := FileAccess.get_file_as_string("res://project.godot")
	t.ok(proj.contains("fallback_to_opengl3=true"), "Vulkan yoksa OpenGL 3'e düşer")
	for key in ["GRAPHICS_QUALITY", "FPS_LIMIT", "QUALITY_LOW", "QUALITY_MEDIUM", "QUALITY_HIGH", "FPS_UNLIMITED", "STATUS_ACTIVE_UNIT", "STATUS_READY_COUNT"]:
		t.ok(LocalizationManager.has_key(key), "Çeviri anahtarı var: %s" % key)

	# ── Açılış yükleme ekranı ───────────────────────────────────────────────
	t.ok(proj.contains("run/main_scene=\"res://scenes/ui/boot/boot.tscn\""), "Oyun açılış yükleme ekranıyla başlar")
	var boot := FileAccess.get_file_as_string("res://scenes/ui/boot/boot.gd")
	t.ok(boot.contains("LoadingManager.load_scene") and boot.contains("unit_model_paths()"),
		"Açılışta ana menü ve birim modelleri arka planda yüklenir")
	var lm := FileAccess.get_file_as_string("res://scripts/ui/loading_manager.gd")
	t.ok(lm.contains("total_model_progress += 1.0\n") and lm.contains("!= ResourceLoader.THREAD_LOAD_LOADED:\n\t\t\t\tcontinue"),
		"Bozuk model yüklemeyi kilitlemez, önbelleğe girmez")

	# ── Bildirim tonu ───────────────────────────────────────────────────────
	t.ok(not LocalizationManager.has_key("NOTICE_TITLE_WARN"), "Genel 'Yapılamaz' başlığı kaldırıldı")
	var feed := NoticeFeed.new()
	t.add_child(feed)
	feed.post("yönlendirme")
	var card: Control = feed.get_child(0)
	t.ok(not (card.get_node("%Title") as Label).visible, "Başlıksız bildirim tek satırlık yönlendirmedir")
	feed.free()
