extends Control

## P1-1: reaktif harita-seçim modu (Time Slip yeniden konuşlanma / Temporal Assassin 2. hedef)
## aktifken gösterilen KÜÇÜK, EKRANI KAPATMAYAN bilgi kartı — GameState.pick_mode'u dinler.
## marker_spend_overlay'in aksine "Dim" arka planı yok, tüm ekranla etkileşim serbest kalır;
## oyuncu haritaya tıklayarak seçimini yapar, kart yalnız NASIL yapılacağını anlatır. Kart alt
## eylem panelinin hemen üstünde durur ve (İptal hariç) tıklamaları geçirir — ekran ortasındaki
## hedefin üstünü kapatıp seçimi engellemez.

@onready var title: Label = $Center/Panel/Margin/VBox/Title
@onready var info: Label = $Center/Panel/Margin/VBox/Info
@onready var progress: Label = $Center/Panel/Margin/VBox/Progress
@onready var countdown: Label = $Center/Panel/Margin/VBox/Footer/Countdown
@onready var cancel_button: Button = $Center/Panel/Margin/VBox/Footer/CancelButton

var _time_left: float = 0.0
const AUTO_SECONDS: float = 30.0
var _ringed_unit = null
var _is_blood_drain: bool = false

func _ready() -> void:
	visible = false
	set_process(false)
	cancel_button.text = LocalizationManager.tr_t("HINT_CANCEL")
	cancel_button.pressed.connect(func(): GameState.cancel_pick())
	GameState.pick_mode_started.connect(_on_pick_started)
	GameState.pick_mode_ended.connect(_on_pick_ended)
	GameState.blood_drain_progress.connect(_on_blood_drain_progress)

func _on_pick_started(kind: String, hint_key: String) -> void:
	title.text = LocalizationManager.tr_t(hint_key + "_TITLE")
	info.text = LocalizationManager.tr_t(hint_key + "_INFO")

	var unit = GameState.pick_unit
	if kind == "position" and is_instance_valid(unit) and unit.attack_range_indicator:
		_ringed_unit = unit
		unit.attack_range_indicator.show_visuals(unit, GameState.pick_radius)

	# GOETIC SPELL (P1-1): "blood_drain" modunda toplanan/gereken Blood Marker sayısı ilerleme
	# satırında canlı gösterilir (kind'e özgü, diğer pick türlerinde gizli).
	_is_blood_drain = kind == "blood_drain"
	progress.visible = _is_blood_drain
	if _is_blood_drain:
		_update_progress_text()

	GothicThemeHelper.init_ui(self)
	_time_left = AUTO_SECONDS
	countdown.text = LocalizationManager.tr_t("HINT_AUTO_CANCEL") % int(_time_left)
	visible = true
	set_process(true)
	_refresh_target_rings()

func _on_pick_ended() -> void:
	visible = false
	set_process(false)
	if is_instance_valid(_ringed_unit) and _ringed_unit.attack_range_indicator:
		_ringed_unit.attack_range_indicator.hide_visuals()
	_ringed_unit = null
	_refresh_target_rings()

## "enemy_unit" seçiminde tıklanabilir adaylar halkayla vurgulanır (UnitMovement okur).
func _refresh_target_rings() -> void:
	get_tree().call_group("units", "update_indicators")

func _on_blood_drain_progress(_collected: int, _needed: int) -> void:
	if _is_blood_drain:
		_update_progress_text()

func _update_progress_text() -> void:
	progress.text = LocalizationManager.tr_t("GOETIC_DRAIN_PROGRESS") \
		% [GameState.pick_blood_drain_collected, GameState.pick_blood_drain_needed]

func _process(delta: float) -> void:
	_time_left -= delta
	countdown.text = LocalizationManager.tr_t("HINT_AUTO_CANCEL") % maxi(0, int(ceil(_time_left)))
	if _time_left <= 0.0:
		GameState.cancel_pick()
