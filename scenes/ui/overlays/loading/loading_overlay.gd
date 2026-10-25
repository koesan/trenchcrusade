extends ColorRect

## Yükleme ekranı: karartılmış menü sanatı, logo ve ince ilerleme çubuğu — başka hiçbir şey
## (kullanıcı isteği: yanıp sönen süs ve yazı kaldırıldı). Çubuk hedef değere yumuşakça ilerler.

var _target_progress: float = 0.0

@onready var progress_bar: ProgressBar = $Center/VBox/ProgressBar

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	visibility_changed.connect(_on_visibility_changed)
	set_process(visible)

func _on_visibility_changed() -> void:
	set_process(visible)
	if visible:
		_target_progress = 0.0
		progress_bar.value = 0.0

## LoadingManager çağırır (eski arayüz korunur; metin artık yok).
func update_locale(_new_lang: String = "") -> void:
	pass

func set_progress_value(p_val: float) -> void:
	_target_progress = clampf(p_val, 0.0, 1.0)

func _process(delta: float) -> void:
	progress_bar.value = lerp(progress_bar.value, _target_progress, 8.0 * delta)
