extends Control
class_name RoundWinBadge

## UI redesign (2026-07-18) — kullanıcı isteği: "Top Bar'ın en sağ ve en sol ALTINDA (içinde
## değil) küçük iki panel oluştur. Her faction'ın kazandığı round sayısını göstersin." "Round
## kazanma" tanımı (kullanıcı onaylı): bir round'da hangi oyuncu DİĞERİNDEN DAHA FAZLA VP
## kazandıysa (objective kontrolü) o oyuncunun sayacı +1 — bkz. ScenarioLogic.player_round_wins /
## round_wins_test.gd. Kullanıcının sağladığı gerçek asset (round_win_banner.png) kullanılıyor —
## PanelContainer yerine düz Control kökü (round_medallion.gd'deki "devasa büyüme" bug'ıyla AYNI
## kök nedenden kaçınmak için, bkz. o dosyadaki not).

@onready var name_label: Label = %NameLabel
@onready var count_label: Label = %CountLabel

var player_id: int = 1

func _ready() -> void:
	if not Engine.is_editor_hint():
		# BUG (canlı log, 2026-07-18): locale_changed String argümanıyla emit ediliyor; _refresh()
		# parametresiz olduğundan doğrudan bağlanınca hata veriyordu — round_medallion.gd'deki
		# AYNI düzeltme (lambda ile sarmalama).
		LocalizationManager.locale_changed.connect(func(_l): _refresh())
		GameState.faction_selected.connect(func(_pid, _f): _refresh_name())
		ScenarioManager.round_wins_updated.connect(func(_rw): _refresh_count())
		ScenarioManager.scenario_changed.connect(func(_s): _refresh_count())
		_refresh()

func set_player(pid: int) -> void:
	player_id = pid
	_refresh()

func _refresh() -> void:
	_refresh_name()
	_refresh_count()

func _refresh_name() -> void:
	if not is_instance_valid(name_label):
		return
	name_label.text = PlayerLabel.name_of(player_id)

func _refresh_count() -> void:
	if not is_instance_valid(count_label):
		return
	count_label.text = str(ScenarioManager.player_round_wins.get(player_id, 0))
