extends Node

## HUD AÇILIŞ DUMAN TESTİ (üçüncü kapı) — `godot --headless res://tests/hud_smoke.tscn`
##
## NEDEN AYRI: Ana süit (`test_main.tscn`) test durumlarını SENKRON çağırır (`inst.run(t)`), bu
## yüzden `await` gerektiren hiçbir şeyi doğrulayamaz. Oysa bir sahnenin gerçekten AYAĞA KALKIP
## kalkmadığı ancak `add_child()` + birkaç kare beklenerek anlaşılır.
##
## METODOLOJİ UYARISI (bu projede bir kez yanlış alarma yol açtı): sahneyi izole `instantiate()`
## + hemen `free()` ile denemek YANLIŞTIR — o anda sinyal bağlantıları/`@onready` alanları henüz
## çözülmemiştir ve sağlam kod bile "bozuk" görünür. Gerçek boot akışını taklit et: add_child →
## kare bekle → denetle.
##
## Neyi doğrular:
##   1. `game_hud.tscn` hatasız kurulur (tüm `@onready` yolları ve sinyal bağlamaları geçerli).
##   2. `OverlayManager`in kayıtlı 9 overlay'inin hepsi bulunur (yol/isim kayması yok).
##   3. Hepsi `OverlayPanel` sözleşmesini sunar ve gerçekten AÇILIP KAPANIR (open_panel çökmez).
##
## Çıkış kodu 0 = geçti.

const OVERLAY_COUNT_EXPECTED := 9

func _ready() -> void:
	var failures: Array[String] = []

	var packed: PackedScene = load("res://scenes/ui/hud/game_hud.tscn")
	if packed == null:
		_finish(["game_hud.tscn yüklenemedi"])
		return

	var hud = packed.instantiate()
	add_child(hud)
	await get_tree().process_frame
	await get_tree().process_frame

	var om = hud.overlay_manager
	if om == null:
		_finish(["game_hud.overlay_manager kurulmadı"])
		return

	if om.overlays.size() != OVERLAY_COUNT_EXPECTED:
		failures.append("Kayıtlı overlay sayısı %d, beklenen %d" \
			% [om.overlays.size(), OVERLAY_COUNT_EXPECTED])

	for key in om.overlays:
		var o = om.overlays[key]
		if o == null:
			failures.append("'%s' overlay düğümü BULUNAMADI (isim/yol kayması)" % key)
			continue
		if not (o is OverlayPanel):
			failures.append("'%s' OverlayPanel türetmiyor" % key)
		if not o.has_method("open_panel"):
			failures.append("'%s' open_panel() sunmuyor" % key)

	# Her overlay'i gerçekten aç — `open_panel()` içindeki doldurma kodu çökerse burada patlar.
	for key in om.overlays:
		if om.overlays[key] == null:
			continue
		om.open_overlay(key)
		await get_tree().process_frame
	om.close_current_overlay()

	_finish(failures)

func _finish(failures: Array) -> void:
	if failures.is_empty():
		print("\n==== HUD DUMAN TESTİ: GEÇTİ (%d overlay açıldı/kapandı) ====" % OVERLAY_COUNT_EXPECTED)
		get_tree().quit(0)
	else:
		print("\n==== HUD DUMAN TESTİ: %d SORUN ====" % failures.size())
		for f in failures:
			print("   ✗ " + f)
		get_tree().quit(1)
