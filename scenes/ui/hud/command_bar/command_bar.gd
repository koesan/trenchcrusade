extends PanelContainer
class_name CommandBar

## KOMUTA PANELİ — savaşta ekranın alt ortası. Seçili birimin kimliği (kemerli niş portre, ad,
## faksiyon), masa oyunu kartındaki sırayla dört değeri (Hareket / Menzilli / Yakın / Zırh),
## işaretleri ve durumu; yanında yapabileceği eylemler ve "Aktivasyonu bitir".
##
## Birim seçili değilken panel tamamen gizlenir; ekranın altında yönerge plakası YOKTUR (kullanıcı
## isteği: sıra bilgisi zaten üstteki tur göstergesinde, alt ortadaki bildirim gereksizdi).
##
## KIPIRDAMA ÖNLEMİ: içerik yalnız DEĞİŞTİĞİNDE yazılır (`_set_text`, `_status_sig`). Eski HUD her
## 5 karede bütün kartların stil/renk geçersiz kılmalarını yeniden yazıyor, her yazma yerleşimi
## baştan hesaplatıp butonları oynatıyordu.

signal end_turn_pressed

## İşaret ikonları renklendirildiği için DÜZ (beyaz) sürüm kullanılır.
const ICON_DIR := "res://assets/ui/icons/flat/"

@onready var _portrait: Button = %Portrait
@onready var _preview_slot: CenterContainer = %PreviewSlot
@onready var _info: VBoxContainer = %Info
@onready var _name: Label = %Name
@onready var _sub: Label = %Sub
@onready var _status: HBoxContainer = %Status
@onready var _traits: HBoxContainer = %Traits
@onready var _target_hint: RichTextLabel = %TargetHint
## "Aktivasyonu bitir" panelin DIŞINDA — ekranın sağ alt köşesi, panelle aynı alt hizada (HUD alt
## satırında, esnek boşluk ardından). Panelin tüm genişliği eylemlere kalır. Görünürlüğü panel yönetir.
@export var end_turn_button: Button
var _end_turn: Button
@onready var actions: ActionButtonsPanel = %Actions
@onready var _stats := {
	"move": $Row/Info/Stats/Move, "ranged": $Row/Info/Stats/Ranged,
	"melee": $Row/Info/Stats/Melee, "armour": $Row/Info/Stats/Armour,
}

var _unit: Node = null
var _status_sig := ""

func _ready() -> void:
	_end_turn = end_turn_button
	_end_turn.pressed.connect(func(): end_turn_pressed.emit())
	# İnisiyatif seçimi beklenirken "Aktivasyonu bitir" gösterilmez (henüz kimse aktive olmuyor).
	TurnManager.initiative_choice_required.connect(_on_initiative_pending)
	TurnManager.turn_changed.connect(_on_initiative_resolved)
	GameState.unit_selected.connect(func(_u): _on_initiative_resolved(0))
	actions.action_selected.connect(func(_k): _update_target_hint())
	actions.attack_selected.connect(func(_i): _update_target_hint())
	LocalizationManager.locale_changed.connect(func(_l): _update_static_text())
	_update_static_text()

func _update_static_text() -> void:
	_end_turn.text = LocalizationManager.tr_t("END_ACTIVATION")
	_stats["move"].get_node("Caption").text = LocalizationManager.tr_t("PROFILE_SPEED")
	_stats["ranged"].get_node("Caption").text = LocalizationManager.tr_t("PROFILE_RANGED")
	_stats["melee"].get_node("Caption").text = LocalizationManager.tr_t("PROFILE_MELEE")
	_stats["armour"].get_node("Caption").text = LocalizationManager.tr_t("PROFILE_ARMOUR")
	if is_instance_valid(_unit):
		_fill_identity(_unit)

## Panelin oyun durumuna göre üç hâli (TEK karar yeri): seçili birim (kendi birimin → eylemleriyle;
## düşman → yalnız bilgisi), seçim yok ("bir model seç"), sıra rakipte ("sıranı bekle").
## Savaş dışındaki aşamalarda panel görünmez.
func sync() -> void:
	var my_turn: bool = TurnManager.is_my_turn()
	_end_turn.visible = GameState.game_phase == GameState.GamePhase.BATTLE and not _initiative_pending
	_end_turn.disabled = not my_turn
	if GameState.game_phase != GameState.GamePhase.BATTLE:
		visible = false
		return
	var unit = GameState.selected_unit
	if is_instance_valid(unit):
		visible = true
		show_unit(unit, my_turn)
	else:
		_unit = null
		_status_sig = ""
		actions.clear()
		visible = false

## Bir birimi göster ve eylemlerini kur. Aynı birim tekrar verilirse portre yeniden KURULMAZ.
func show_unit(unit: Node, my_turn: bool) -> void:
	if unit != _unit:
		_unit = unit
		_status_sig = ""
		_fill_identity(unit)
		_set_portrait(unit)
		_fill_traits(unit)
	refresh_state()
	actions.rebuild(unit)
	_end_turn.disabled = not my_turn
	_update_target_hint()

## İşaret ve durum satırı. Her çağrıda değil, yalnız değer değişince yeniden kurulur.
func refresh_state() -> void:
	if not is_instance_valid(_unit):
		return
	var u := _unit
	var state_key: String = String(u.get_fighter_state()) if u.has_method("get_fighter_state") else "STATE_ACTIVE"
	if u.has_moved and state_key == "STATE_ACTIVE":
		state_key = "STATE_EXHAUSTED"
	var sig := "%d|%d|%d|%s" % [u.blood_markers, u.blessing_markers, u.infection_markers, state_key]
	if sig == _status_sig:
		return
	_status_sig = sig
	for c in _status.get_children():
		_status.remove_child(c)
		c.queue_free()
	_status.add_child(_state_chip(state_key))
	if u.blood_markers > 0:
		_status.add_child(_marker_chip("blood", u.blood_markers, "color_status_danger"))
	if u.blessing_markers > 0:
		_status.add_child(_marker_chip("blessing", u.blessing_markers, "color_gold_bright"))
	if u.infection_markers > 0:
		_status.add_child(_marker_chip("infection", u.infection_markers, "color_status_good"))

func _fill_identity(unit: Node) -> void:
	_name.text = unit.display_name
	var faction = GameState.get_faction_for_player(unit.owner_id)
	_sub.text = PlayerLabel.faction_name(faction) if faction != null else ""
	_stats["move"].get_node("Value").text = "%.0f\"" % unit.speed
	_stats["ranged"].get_node("Value").text = LocalizationManager.tr_t("DICE_MOD_FMT") % unit.ranged_dice_modifier
	_stats["melee"].get_node("Value").text = LocalizationManager.tr_t("DICE_MOD_FMT") % unit.melee_dice_modifier
	_stats["armour"].get_node("Value").text = str(unit.armour)

func _set_portrait(unit: Node) -> void:
	for c in _preview_slot.get_children():
		c.queue_free()
	if unit.unit_data and unit.unit_data.model_scene_path != "":
		_preview_slot.add_child(UIPreviewHelper.create_3d_preview(unit.unit_data.model_scene_path, Vector2(84, 102)))

func _state_chip(state_key: String) -> Label:
	var l := Label.new()
	l.text = LocalizationManager.tr_t(state_key)
	l.theme_type_variation = &"LabelGoldAccent"
	var col := "color_status_good"
	match state_key:
		"STATE_DOWN": col = "color_status_warn"
		"STATE_EXHAUSTED": col = "color_muted"
	l.add_theme_color_override("font_color", GothicThemeHelper.color(col))
	return l

func _marker_chip(icon_name: String, count: int, color_name: String) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := TextureRect.new()
	ic.texture = load(ICON_DIR + icon_name + ".svg")
	ic.custom_minimum_size = Vector2(16, 16)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.modulate = GothicThemeHelper.color(color_name)
	box.add_child(ic)
	var n := Label.new()
	n.text = str(count)
	box.add_child(n)
	return box

## ÖZELLİK ŞERİDİ: birimin BÜTÜN yetenekleri (pasifler dâhil) küçük etiketler hâlinde; üzerine
## gelince yeteneğin kendi açıklaması açılır. Aktif yetenekler ayrıca eylem butonu olarak yanda.
## Böylece her birimin kendine özgü kimliği (Infernal Brand, Fireteam…) tek bakışta okunur.
func _fill_traits(unit: Node) -> void:
	for c in _traits.get_children():
		_traits.remove_child(c)
		c.queue_free()
	if unit.unit_data == null:
		return
	for ab in unit.unit_data.abilities:
		if ab == null:
			continue
		var chip := Button.new()
		chip.text = LocalizationManager.tr_t(ab.display_name)
		chip.theme_type_variation = &"ButtonGhost"
		# Küçük etiket → Garamond (12 pt blackletter okunmaz)
		chip.add_theme_font_override("font", GothicThemeHelper.THEME.get_font("font", "LabelGoldAccent"))
		chip.add_theme_font_size_override("font_size", 13)
		chip.focus_mode = Control.FOCUS_NONE
		var spec := InfoSpec.for_ability(ab)
		chip.mouse_entered.connect(func(): _hud_call("show_info", [chip, spec]))
		chip.mouse_exited.connect(func(): _hud_call("hide_tooltip", []))
		_traits.add_child(chip)
	_fit_traits.call_deferred()

## Sığmayan özellik etiketleri yarıda kesilmek yerine gizlenir; sona "+N" eklenir. "+N"in üzerine
## gelince gizlenenlerin adları bilgi kartında listelenir.
func _fit_traits() -> void:
	await get_tree().process_frame
	var limit: float = _traits.get_parent().size.x
	var hidden: Array[String] = []
	var reserve := 34.0  # "+N" için yer
	for c in _traits.get_children():
		if c.position.x + c.size.x > limit - reserve or not hidden.is_empty():
			c.visible = false
			hidden.append(c.text)
	if hidden.is_empty():
		return
	var more := Button.new()
	more.text = "+%d" % hidden.size()
	more.theme_type_variation = &"ButtonGhost"
	more.focus_mode = Control.FOCUS_NONE
	more.add_theme_font_override("font", GothicThemeHelper.THEME.get_font("font", "LabelGoldAccent"))
	more.add_theme_font_size_override("font_size", 13)
	var spec := {"title": LocalizationManager.tr_t("TRAITS_HEADING"), "body": "\n".join(hidden)}
	more.mouse_entered.connect(func(): _hud_call("show_info", [more, spec]))
	more.mouse_exited.connect(func(): _hud_call("hide_tooltip", []))
	_traits.add_child(more)

## HEDEF YÖNERGESİ: tıklama bekleyen bir eylem seçiliyken eylemlerin altında ne yapılacağını
## söyler ("Düşman bir modele tıkla · menzil 12"). Eskiden oyuncu butona basınca ne olacağını
## bilmiyordu.
func _update_target_hint() -> void:
	var text := ""
	if is_instance_valid(_unit) and actions.visible:
		var sel: String = GameState.selected_action
		match sel:
			"", "none":
				text = ""
			"move", "retreat":
				text = LocalizationManager.tr_t("TARGET_HINT_MOVE") + "   " + _climb_legend()
			"charge":
				text = LocalizationManager.tr_t("TARGET_HINT_CHARGE")
			"attack":
				var atk = _unit.unit_data.attacks[_unit.selected_attack_index] \
					if _unit.unit_data and _unit.selected_attack_index < _unit.unit_data.attacks.size() else null
				if atk != null and atk.attack_type == "MELEE":
					text = LocalizationManager.tr_t("TARGET_HINT_MELEE")
				elif atk != null:
					text = LocalizationManager.tr_t("TARGET_HINT_ATTACK") % int(atk.attack_range)
			_:
				var ab = _ability_by_key(sel)
				if ab != null:
					var key := "TARGET_HINT_" + String(ab.target_type).to_upper()
					if LocalizationManager.has_key(key):
						text = LocalizationManager.tr_t(key)
						if ab.range_meters > 0.0:
							text += LocalizationManager.tr_t("TARGET_HINT_RANGE") % int(ab.range_meters)
	# Satır hep YER TUTAR (boşken de) — metin gelip gidince eylem butonları kaymasın.
	_target_hint.text = text

## Hareket alanındaki dikey erişim oklarının açıklaması — renkler okları çizen kaynaktan
## (PathRangeVisualizer.VERTICAL_COLORS), böylece çizim ile açıklama hiç ayrışmaz.
func _climb_legend() -> String:
	var parts: Array[String] = []
	for kind in ["walkover_up", "climb", "walkover_down", "climb_down"]:
		var c: Color = PathRangeVisualizer.VERTICAL_COLORS[kind]
		parts.append("[color=#%s]●[/color] %s" % [c.to_html(false), LocalizationManager.tr_t("CLIMB_LEGEND_" + kind.to_upper())])
	return "  ".join(parts)

func _ability_by_key(action_key: String) -> Resource:
	if not is_instance_valid(_unit) or _unit.unit_data == null:
		return null
	for ab in _unit.unit_data.abilities:
		if ab != null and ab.action_key == action_key:
			return ab
	return null

func _hud_call(method: String, args: Array) -> void:
	var p := get_parent()
	while p:
		if p.has_method(method):
			p.callv(method, args)
			return
		p = p.get_parent()

var _initiative_pending := false

func _on_initiative_pending(_winner_id: int) -> void:
	_initiative_pending = true
	sync()

func _on_initiative_resolved(_player_id: int) -> void:
	if _initiative_pending:
		_initiative_pending = false
		sync()

## BOŞLUK: aktivasyonu bitir — yalnız savaşta, sıra sendeyken, panel açıkken ve hiçbir menü
## (overlay) açık değilken.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE):
		return
	if not _end_turn.visible or _end_turn.disabled:
		return
	var p := get_parent()
	while p and not ("overlay_manager" in p):
		p = p.get_parent()
	if p and p.overlay_manager.current_overlay != "":
		return
	get_viewport().set_input_as_handled()
	end_turn_pressed.emit()

