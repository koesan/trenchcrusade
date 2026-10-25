class_name UIAnim
extends RefCounted

## ARAYÜZ HAREKETİ — tek ölçü, tek kaynak.
##
## Hareket yalnız oyuncunun eylemine CEVAP olarak kullanılır (panel açıldı, modal geldi); sürekli
## ya da dağınık efekt yoktur. Süreler kısa tutulur ki arayüz "ağır" hissettirmesin.
##   Modal/panel açılışı : 140 ms — saydamlık 0→1 + ölçek %97→%100
## `reduced_motion` açıkken (Ayarlar) her şey anında görünür.

const OPEN_SECONDS := 0.14
const OPEN_SCALE := 0.97

static var reduced_motion := false
static var _pref_loaded := false

## Kayıtlı tercih (Ayarlar → "Hareketi azalt") ilk kullanımda bir kez okunur; ayarlar paneli
## açılmamış olsa da oyunun başından geçerlidir.
static func _load_pref() -> void:
	_pref_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		reduced_motion = cfg.get_value("graphics", "reduced_motion", false)

## Kontrolü görünür yap ve yumuşakça "yerine otur". `target` ölçeklenecek iç panel (ör. overlay'in
## Panel düğümü); verilmezse yalnız saydamlık canlanır.
static func pop_in(root: Control, target: Control = null) -> void:
	root.visible = true
	if not _pref_loaded:
		_load_pref()
	if reduced_motion or not root.is_inside_tree():
		root.modulate.a = 1.0
		if target:
			target.scale = Vector2.ONE
		return
	root.modulate.a = 0.0
	var tw := root.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(root, "modulate:a", 1.0, OPEN_SECONDS)
	if target:
		target.pivot_offset = target.size * 0.5
		target.scale = Vector2.ONE * OPEN_SCALE
		tw.tween_property(target, "scale", Vector2.ONE, OPEN_SECONDS)
