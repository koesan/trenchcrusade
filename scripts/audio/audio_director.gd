extends Node

## AudioDirector (Autoload) — OYUN OLAYLARI → SES eşleme katmanı.
##
## AudioManager saf oynatma motorudur (oyunu bilmez). Bu director, oyun sinyallerini dinleyip
## uygun SFX event'ini çalar → eşleme TEK YERDE, dağınık değil. Sesler AudioManager'daki
## veri-odaklı registry'den gelir (ilgili .ogg klasörde yoksa sessizce no-op).
##
## Ayrıca: TÜM butonlara otomatik click/hover sesi bağlar (get_tree().node_added) — tek buton
## bile elle kodlanmaz. Bir buton türü ses istemiyorsa ilgili .ogg'yi klasörden çıkar (drop-in).
##
## Autoload sırası: AudioManager + GameState + GameEvents + TurnManager'dan SONRA (project.godot).

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	if Engine.is_editor_hint():
		return

	# 1) Otomatik UI sesi — mevcut + gelecekteki tüm butonlar.
	get_tree().node_added.connect(_on_node_added)
	_bind_existing_buttons(get_tree().root)

	# 2) Oyun olayları → SFX (yalnız mevcut+yayılan sinyallere bağlanır; oynanış mantığı değişmez).
	GameState.unit_selected.connect(_on_unit_selected)
	GameState.unit_deployed.connect(_on_unit_deployed)
	GameEvents.deploy_rejected.connect(_on_reject)
	GameEvents.move_rejected.connect(_on_reject)
	GameEvents.game_over.connect(_on_game_over)
	TurnManager.turn_changed.connect(_on_turn_changed)
	DiceManager.dice_roll_started.connect(_on_dice_roll_started)

# ── Otomatik buton sesi ───────────────────────────────────────────────────────

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_bind_button(node)

func _bind_existing_buttons(root: Node) -> void:
	if root is BaseButton:
		_bind_button(root)
	for child in root.get_children():
		_bind_existing_buttons(child)

func _bind_button(btn: BaseButton) -> void:
	if not btn.pressed.is_connected(_on_button_pressed):
		btn.pressed.connect(_on_button_pressed.bind(btn))
	if not btn.mouse_entered.is_connected(_on_button_hover):
		btn.mouse_entered.connect(_on_button_hover.bind(btn))

func _on_button_pressed(btn: BaseButton) -> void:
	if is_instance_valid(btn) and btn.disabled:
		return
	AudioManager.play_sfx_event(&"ui/click")

func _on_button_hover(btn: BaseButton) -> void:
	if is_instance_valid(btn) and btn.disabled:
		return
	AudioManager.play_sfx_event(&"ui/hover", 1.0, -8.0)  # hover belirgin ama bastırılmış

# ── Oyun olayları → SFX ───────────────────────────────────────────────────────

func _on_unit_selected(_unit) -> void:
	AudioManager.play_sfx_event(&"units/select")

func _on_unit_deployed(_player_id, _unit) -> void:
	AudioManager.play_sfx_event(&"ui/confirm")

func _on_reject(_reason_key: String) -> void:
	AudioManager.play_sfx_event(&"ui/error")

func _on_game_over(_winner_id: int) -> void:
	AudioManager.play_sfx_event(&"environment/bell")

func _on_turn_changed(_active_player_id: int) -> void:
	# Tur geçişi — bastırılmış çan tokması (atmosfer; sıklık orta). İstenmezse bell .ogg'yi çıkar.
	AudioManager.play_sfx_event(&"environment/bell", 1.0, -10.0)

func _on_dice_roll_started(_num_dice: int) -> void:
	# Zar atma sesi (genel bakım turu, 2026-07-18) — DiceManager.dice_roll_started daha önce hiç
	# dinlenmiyordu, projede HİÇ zar sesi yoktu. sfx/dice/throw_* (3 varyasyon, Kenney Casino Audio).
	AudioManager.play_sfx_event(&"dice/throw")
