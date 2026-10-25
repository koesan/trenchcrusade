extends RefCounted

## OVERLAY SÖZLEŞMESİ BEKÇİSİ.
##
## `OverlayManager` her açılışta `open_panel()` çağırır. Eskiden bu bir `has_method()` tahminiydi
## ve 9 overlay'den yalnız 3'ü uyguluyordu; uygulamayanlar içeriğini SADECE `_ready()`de (HUD
## kurulurken, hiçbir birim yerleştirilmeden ÖNCE) doldurup bir daha yenilemiyordu → "panel boş/
## bayat açılıyor" bug'ı bu projede DÖRT KEZ tekrarladı.
##
## Artık kanca `OverlayPanel` taban sınıfında. Bu test, kayıtlı her overlay'in gerçekten o taban
## sınıfı türettiğini ve sözleşmenin tamamını sunduğunu doğrular — böylece yeni bir overlay
## eklerken kancayı unutmak testte YAKALANIR.

## `OverlayManager._init()` içinde kayıtlı overlay'lerin sahne yolları.
## (Yönetici bir CanvasLayer ister; burada sahneleri doğrudan yükleyip denetliyoruz.)
const OVERLAY_SCENES := {
	"pause": "res://scenes/ui/overlays/pause/pause_overlay.tscn",
	"settings": "res://scenes/ui/overlays/settings/settings_overlay.tscn",
	"roster": "res://scenes/ui/overlays/roster/roster_overlay.tscn",
	"chronicles": "res://scenes/ui/overlays/chronicles/chronicles_overlay.tscn",
	"blessings": "res://scenes/ui/overlays/blessings/blessings_overlay.tscn",
	"keywords": "res://scenes/ui/overlays/keywords/keywords_overlay.tscn",
	"profile": "res://scenes/ui/overlays/profile/profile_overlay.tscn",
	"game_end": "res://scenes/ui/overlays/game_end/game_end_overlay.tscn",
	"guide": "res://scenes/ui/overlays/guide/guide_overlay.tscn",
}

## Sözleşmenin tamamı.
const CONTRACT := ["_bind_controls", "update_locale", "open_panel", "close_panel"]

func run(t) -> void:
	# Yönetici, kayıtlı anahtarları burada listelenenlerle AYNI tutmalı — biri eklenir de
	# teste eklenmezse sessizce denetimsiz kalır.
	var mgr_src := FileAccess.open("res://scenes/ui/overlays/overlay_manager.gd", FileAccess.READ)
	t.ok(mgr_src != null, "overlay_manager.gd okunabildi")
	if mgr_src != null:
		var txt := mgr_src.get_as_text()
		mgr_src.close()
		for key in OVERLAY_SCENES.keys():
			t.ok(txt.contains('"%s":' % key),
				"OverlayManager '%s' overlay'ini kaydediyor" % key)
		# Özel-durum dalı geri gelmemeli: yönetici TEK BİR panelin metodunu bilmemeli.
		# (Yorumda geçmesi serbest — burada aranan gerçek ÇAĞRI/`has_method` tahminidir.)
		t.ok(not txt.contains("overlay.populate_profile("),
			"OverlayManager panele-özel `populate_profile()` ÇAĞIRMIYOR")
		t.ok(not txt.contains('has_method("open_panel")'),
			"open_panel artık `has_method` tahmini değil, sözleşme")

	for key in OVERLAY_SCENES.keys():
		var path: String = OVERLAY_SCENES[key]
		t.ok(ResourceLoader.exists(path), "%s sahnesi mevcut" % key)
		var packed: PackedScene = load(path)
		if packed == null:
			continue
		var node: Node = packed.instantiate()

		# Kök düğüm OverlayPanel'i türetmeli — sözleşme böyle garanti altına alınır.
		t.ok(node is OverlayPanel, "%s kökü OverlayPanel türetiyor" % key)

		for fn in CONTRACT:
			t.ok(node.has_method(fn), "%s → %s() var" % [key, fn])

		# "Geri" sinyali taban sınıfta tanımlı; her overlay onu taşımalı.
		t.ok(node.has_signal("close_pressed"), "%s → close_pressed sinyali var" % key)

		node.free()
