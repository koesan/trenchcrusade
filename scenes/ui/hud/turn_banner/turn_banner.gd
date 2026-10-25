extends Control

## SIRA DUYURUSU: aktivasyon sırası karşı tarafa geçince ya da yeni tur başlayınca ekranın üst
## kısmında kısa süre beliren şerit ("New Antioch — Sıra sende" / "2. Tur").
##
## NEDEN: sıra değişimi yalnız üst bardaki küçük "Sıra: X" yazısıyla belli oluyordu; aynı
## makinede oynayan iki oyuncu (ve ağ oyununda rakibini bekleyen oyuncu) bunu kolayca kaçırıyordu.
## Tıklamayı ENGELLEMEZ (mouse_filter=ignore) ve kendiliğinden kaybolur — kalıcı HUD öğesi değil.
## Kendi sinyallerini kendisi dinler; HUD kodunda ek kablolama gerektirmez.

const HOLD_SECONDS := 1.1
const FADE_SECONDS := 0.45

@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle

var _last_player: int = 0
var _tween: Tween = null

func _ready() -> void:
	# YER TUTAR: şerit hiç "gizlenmez", yalnız saydamlaşır. Duyuru sütununda altındaki öğeler
	# (uyarılar) şerit belirip kaybolurken yukarı-aşağı KAYMASIN (kullanıcı bildirimi).
	visible = true
	modulate.a = 0.0
	if Engine.is_editor_hint():
		return
	TurnManager.turn_changed.connect(_on_turn_changed)
	TurnManager.round_started.connect(_on_round_started)

func _on_turn_changed(player_id: int) -> void:
	# turn_changed aynı oyuncu için birden çok kez yayılabiliyor (HUD tazelemeleri) — yalnız
	# sıra GERÇEKTEN el değiştirdiğinde duyur.
	if player_id == _last_player or player_id <= 0:
		return
	_last_player = player_id
	if GameState.game_phase != GameState.GamePhase.BATTLE:
		return
	_show(PlayerLabel.name_of(player_id), _subtitle_for(player_id), _team_color(player_id))

func _on_round_started(round_number: int) -> void:
	_last_player = 0   # yeni turun ilk aktivasyonu her zaman duyurulsun
	_show(LocalizationManager.tr_t("ROUND_BANNER_FMT") % round_number,
		LocalizationManager.tr_t("ROUND_BANNER_SUB"), GothicThemeHelper.color("color_blood_vivid"))

func _subtitle_for(player_id: int) -> String:
	var networked: bool = multiplayer != null and multiplayer.has_multiplayer_peer() \
		and multiplayer.multiplayer_peer is not OfflineMultiplayerPeer
	if not networked:
		return LocalizationManager.tr_t("TURN_BANNER_ACTIVATION")
	if player_id == NetworkManager.get_local_canonical_id():
		return LocalizationManager.tr_t("TURN_BANNER_YOURS")
	return LocalizationManager.tr_t("TURN_BANNER_ENEMY")

func _team_color(player_id: int) -> Color:
	var faction = GameState.get_faction_for_player(player_id)
	if faction != null and "team_color" in faction:
		return (faction.team_color as Color).lightened(0.35)
	return GothicThemeHelper.color("color_gold_bright")

func _show(title: String, subtitle: String, color: Color) -> void:
	_title.text = title
	_title.add_theme_color_override("font_color", color)
	_subtitle.text = subtitle
	modulate.a = 0.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.18)
	_tween.tween_interval(HOLD_SECONDS)
	_tween.tween_property(self, "modulate:a", 0.0, FADE_SECONDS)
