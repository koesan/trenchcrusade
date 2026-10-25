extends PanelContainer
class_name BattleLog

## SAVAŞ GÜNLÜĞÜ — açılır/kapanır panel (Hedefler/Kaynaklar ile aynı yerde, birbirini dışlar).
## Kapalıyken de kayıt tutar. Kaynaklar: GameEvents.battle_event (isabet/ıska/yara/yetenek),
## TurnManager.round_started (tur başı), TurnManager.player_shaken_changed (sarsılma).
## Yalnız son MAX_LINES satır tutulur; yeni satır gelince en alta kayar.

const MAX_LINES := 60

@onready var _title: Label = %Title
@onready var _scroll: ScrollContainer = %Scroll
@onready var _lines: RichTextLabel = %Lines

var _entries: Array[String] = []
var _col := {}

func _ready() -> void:
	for k in ["color_gold_bright", "color_dim_text", "color_status_danger", "color_status_warn",
			"color_status_caution", "color_parchment", "color_blood_vivid"]:
		_col[k] = GothicThemeHelper.color(k).to_html(false)
	_title.text = LocalizationManager.tr_t("BATTLE_LOG_TITLE")
	LocalizationManager.locale_changed.connect(func(_l): _title.text = LocalizationManager.tr_t("BATTLE_LOG_TITLE"))
	_lines.text = "[color=#%s]%s[/color]" % [_col["color_dim_text"], LocalizationManager.tr_t("BATTLE_LOG_EMPTY")]
	GameEvents.battle_event.connect(_on_event)
	TurnManager.round_started.connect(_on_round)
	TurnManager.player_shaken_changed.connect(func(pid, shaken): if shaken: _add(
		"[color=#%s]%s[/color]" % [_col["color_status_danger"],
		LocalizationManager.tr_t("LOG_SHAKEN") % PlayerLabel.name_of(pid)]))
	visibility_changed.connect(func(): if visible: _scroll_to_end())

## round_started aynı tur için birden çok kez yayılabiliyor (yerel başlatma + senkron) — bir kez yaz.
var _last_round := 0

func _on_round(r: int) -> void:
	if r == _last_round:
		return
	_last_round = r
	_add("[color=#%s]%s[/color]" % [_col["color_blood_vivid"], LocalizationManager.tr_t("ROUND_BANNER_FMT") % r])

func _name(unit_name: String) -> String:
	var u = GameState.units.get(unit_name)
	return u.display_name if is_instance_valid(u) else unit_name

func _on_event(kind: StringName, d: Dictionary) -> void:
	match kind:
		&"hit":
			var key := "LOG_CRIT" if d.get("crit", false) else "LOG_HIT"
			_add(LocalizationManager.tr_t(key) % [_name(d.a), _name(d.t),
				LocalizationManager.tr_t(d.w), int(d.roll)])
		&"miss":
			_add("[color=#%s]%s[/color]" % [_col["color_dim_text"], LocalizationManager.tr_t("LOG_MISS")
				% [_name(d.a), _name(d.get("t", "")), LocalizationManager.tr_t(d.w), int(d.roll)]])
		&"injury":
			var o: String = d.get("o", "no_effect")
			var col: String = {"no_effect": "color_dim_text", "scratch": "color_status_caution",
				"down": "color_status_warn", "out": "color_status_danger"}.get(o, "color_parchment")
			var line: String = LocalizationManager.tr_t("LOG_INJURY") % [_name(d.t),
				LocalizationManager.tr_t("FLOAT_INJURY_" + o.to_upper())]
			if int(d.get("m", 0)) > 0:
				line += LocalizationManager.tr_t("LOG_MARKERS") % int(d.m)
			_add("[color=#%s]%s[/color]" % [_col[col], line])
		&"ability":
			var key := "LOG_ABILITY" if d.get("ok", true) else "LOG_ABILITY_FAILED"
			_add(LocalizationManager.tr_t(key) % [_name(d.a), LocalizationManager.tr_t(d.k)])

func _add(line: String) -> void:
	_entries.append(line)
	if _entries.size() > MAX_LINES:
		_entries.pop_front()
	_lines.text = "\n".join(_entries)
	if visible:
		_scroll_to_end()

func _scroll_to_end() -> void:
	await get_tree().process_frame
	_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)
