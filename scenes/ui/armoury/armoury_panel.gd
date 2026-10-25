extends PanelContainer
## Cephanelik (Armoury) satın alma ekranı.
##
## Yerleştirme bittikten sonra, savaş başlamadan önce açılır. Solda oyuncunun modelleri ve seçili
## modelin kartı (profil + takılı teçhizat), sağda faksiyonun teçhizat tablosu — compendium'daki
## gibi KATEGORİLERE ayrılmış. Her kalem: ad, kısa açıklama, ikonlu fiyat ve "Satın al".
## Alınabilen kalemler üstte; alınamayanlar soluk ve TEK satırlık sebebiyle altta.
##
## Bu dosya YALNIZCA çizim yapar. Neyin alınabileceğine `ArmouryRules` (saf), satın almanın
## kendisine `ArmouryManager` (autoload) karar verir — panel asla kendi kuralını uydurmaz.

signal finished

const ICON_DUCAT := preload("res://assets/ui/icons/ducat.svg")
const ICON_GLORY := preload("res://assets/ui/icons/glory.svg")

@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _ducats: Label = %Ducats
@onready var _glory: Label = %Glory
@onready var _finish_btn: Button = %FinishButton
@onready var _units_header: Label = %UnitsHeader
@onready var _unit_scroll: ScrollContainer = %UnitScroll
@onready var _unit_list: VBoxContainer = %UnitList
@onready var _sel_name: Label = %SelName
@onready var _sel_stats: Label = %SelStats
@onready var _equipped_header: Label = %EquippedHeader
@onready var _equipped_list: VBoxContainer = %EquippedList
@onready var _tabs: HBoxContainer = %CategoryTabs
@onready var _item_scroll: ScrollContainer = %ItemScroll
@onready var _item_list: VBoxContainer = %ItemList
@onready var _status: Label = %StatusLabel

const UNIT_ROW_HEIGHT := 36.0
## Kısa açıklama bu kadar karakterden uzunsa kısaltılır; tamamı satırın ipucunda durur.
const DESC_MAX_CHARS := 140

var _local_id: int = 1
var _selected_unit: String = ""
var _selected_category: int = ArmouryItem.Category.MELEE

func _ready() -> void:
	visible = false
	_finish_btn.pressed.connect(_on_finish_pressed)
	ArmouryManager.purchase_made.connect(_on_purchase_made)

func open_for(_ignored: int = 0) -> void:
	# Kimin alışveriş yaptığını ArmouryManager bilir: ağ oyununda "ben", tek makinede
	# sırası gelen oyuncu. Panel bunu kendi başına tahmin etmez.
	var shopper: int = ArmouryManager.current_shopper()
	if shopper != _local_id:
		_local_id = shopper
		_selected_unit = ""          # yeni oyuncunun modelleri gösterilecek
		_finish_btn.disabled = false
	visible = true
	if _selected_unit == "":
		var mine := _my_units()
		if not mine.is_empty():
			_selected_unit = String(mine[0].name)
	refresh()

func refresh() -> void:
	if not visible:
		return
	_title.text = LocalizationManager.tr_t("ARMOURY_TITLE")
	_subtitle.text = LocalizationManager.tr_t("ARMOURY_SUBTITLE")
	_units_header.text = LocalizationManager.tr_t("ARMOURY_UNITS_HEADER")
	_equipped_header.text = LocalizationManager.tr_t("ARMOURY_OWNED")
	_finish_btn.text = LocalizationManager.tr_t("ARMOURY_FINISH")
	_ducats.text = str(GameState.player_deploy_pool.get(_local_id, 0))
	_glory.text = str(GameState.player_glory_pool.get(_local_id, 0))
	_build_unit_list()
	_build_tabs()
	_build_item_list()
	_build_unit_card()

## Çocukları ANINDA ayırır. Yalnız `queue_free()` kullanılırsa düğümler kare sonuna dek
## ağaçta kalır; aynı karede iki kez tazelenen liste satırları üst üste binerdi.
func _clear(container: Node) -> void:
	for c in container.get_children():
		container.remove_child(c)
		c.queue_free()

# ── Sol sütun: modeller ─────────────────────────────────────────────────────
func _my_units() -> Array:
	# Armoury roster'ı: Savaş Dışı kalmış modeller de warband'e dâhildir.
	var out: Array = UnitQuery.where(UnitQuery.roster_of(_local_id),
		func(u): return u.unit_data != null)
	out.sort_custom(func(a, b): return String(a.name) < String(b.name))
	return out

## Modelin oyuncuya görünen adı (yerelleştirilmiş). Gerçek birimde `display_name` hazırdır.
func _unit_label(u: Node) -> String:
	var dn = u.get("display_name")
	if dn is String and dn != "":
		return dn
	return LocalizationManager.tr_t(u.unit_data.unit_name)

func _build_unit_list() -> void:
	_clear(_unit_list)
	var mine := _my_units()
	for u in mine:
		var uname := String(u.name)
		var btn := Button.new()
		btn.toggle_mode = true
		btn.button_pressed = uname == _selected_unit
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size.y = UNIT_ROW_HEIGHT
		btn.text = _unit_label(u)
		btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		btn.clip_text = true
		# Takılı kalem sayısı: sağda küçük altın rozet (yalnız varsa).
		var owned: int = ArmouryManager.items_of(uname).size()
		if owned > 0:
			var badge := Label.new()
			badge.text = "%d ✦" % owned
			badge.theme_type_variation = &"LabelGoldAccent"
			badge.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
			badge.offset_left = -40
			badge.offset_right = -12
			badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(badge)
		btn.pressed.connect(func():
			_selected_unit = uname
			refresh())
		_unit_list.add_child(btn)
	# Liste kaç model olursa olsun taşmaz — sabit görünen satır sayısı, gerisi kaydırılır.
	UIScrollHelper.apply_max_visible(_unit_scroll, UNIT_ROW_HEIGHT, mine.size(),
		UIScrollHelper.MAX_VISIBLE_UNITS, 4)

## Seçili modelin kartı: adı, satın almayı etkileyen profil değerleri ve takılı teçhizatı.
func _build_unit_card() -> void:
	var unit: Node = GameState.units.get(_selected_unit)
	if unit == null or unit.unit_data == null:
		_sel_name.text = ""
		_sel_stats.text = ""
	else:
		var ud: Resource = unit.unit_data
		_sel_name.text = _unit_label(unit)
		var parts: Array[String] = [
			"%s %d\"" % [LocalizationManager.tr_t("PROFILE_SPEED"), int(ud.speed)],
			"%s %d" % [LocalizationManager.tr_t("PROFILE_ARMOUR"), int(ud.armour)],
		]
		if KeywordSystem.has(ud, &"elite"):
			parts.append(LocalizationManager.tr_t("ARMOURY_ELITE"))
		_sel_stats.text = "  ·  ".join(parts)
	_build_equipped_list()

func _build_equipped_list() -> void:
	_clear(_equipped_list)
	var ids: Array = ArmouryManager.items_of(_selected_unit)
	if ids.is_empty():
		var empty := Label.new()
		empty.text = LocalizationManager.tr_t("ARMOURY_EQUIPPED_NONE")
		empty.theme_type_variation = &"LabelMuted"
		_equipped_list.add_child(empty)
		return
	var table: Array = ArmouryRules.table_for(GameState.get_faction_for_player(_local_id))
	for id in ids:
		for item in table:
			if item.item_id == id:
				var l := Label.new()
				l.text = "✦  " + LocalizationManager.tr_t(item.name_key)
				l.theme_type_variation = &"LabelGoldBright"
				_equipped_list.add_child(l)
				break

# ── Sağ sütun: kategori sekmeleri + kalemler ────────────────────────────────
func _build_tabs() -> void:
	_clear(_tabs)
	var groups: Dictionary = ArmouryRules.by_category(GameState.get_faction_for_player(_local_id))
	for cat in range(ArmouryRules.CATEGORY_KEYS.size()):
		var count: int = (groups.get(cat, []) as Array).size()
		if count == 0:
			continue
		var btn := Button.new()
		btn.toggle_mode = true
		btn.button_pressed = cat == _selected_category
		btn.text = "%s (%d)" % [LocalizationManager.tr_t(ArmouryRules.CATEGORY_KEYS[cat]), count]
		var c_idx := cat
		btn.pressed.connect(func():
			_selected_category = c_idx
			refresh())
		_tabs.add_child(btn)

func _build_item_list() -> void:
	_clear(_item_list)
	var unit: Node = GameState.units.get(_selected_unit)
	if unit == null:
		_status.text = LocalizationManager.tr_t("ARMOURY_SELECT_UNIT")
		return
	_status.text = ""
	var groups: Dictionary = ArmouryRules.by_category(GameState.get_faction_for_player(_local_id))
	var items: Array = groups.get(_selected_category, [])
	if items.is_empty():
		var empty := Label.new()
		empty.text = LocalizationManager.tr_t("ARMOURY_NO_ITEMS")
		empty.theme_type_variation = &"LabelMuted"
		_item_list.add_child(empty)
		return
	# Alınabilenler önce, sonra ada göre — oyuncu listeyi taramadan neyi alabileceğini görsün.
	var blocked := {}
	var reasons := {}
	for it in items:
		var r := ArmouryManager.block_reason(_local_id, unit, it)
		blocked[it] = r != ""
		reasons[r] = true
	items.sort_custom(func(a, b):
		if blocked[a] != blocked[b]:
			return not blocked[a]
		return LocalizationManager.tr_t(a.name_key) < LocalizationManager.tr_t(b.name_key))
	# Hepsi aynı sebeple kapalıysa (ör. eli dolu) sebep her satırda değil, bir kez yazılır.
	var shared_reason: String = reasons.keys()[0] if reasons.size() == 1 else ""
	if shared_reason != "":
		_status.text = "✕  " + LocalizationManager.tr_t(shared_reason)
	for item in items:
		_item_list.add_child(_make_item_row(item, unit, shared_reason == ""))

func _make_item_row(item: Resource, unit: Node, show_reason := true) -> Control:
	var reason := ArmouryManager.block_reason(_local_id, unit, item)
	var row := PanelContainer.new()
	row.theme_type_variation = &"PanelInset"
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	row.add_child(margin)

	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 14)
	margin.add_child(line)

	# Sol: ad + kısa açıklama + kısıt/LIMIT + (alınamıyorsa) sebep
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 1)
	line.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = LocalizationManager.tr_t(item.name_key)
	name_lbl.theme_type_variation = &"LabelGoldBright"
	info.add_child(name_lbl)

	var full_desc := LocalizationManager.tr_t(item.desc_key)
	var desc := Label.new()
	desc.text = full_desc if full_desc.length() <= DESC_MAX_CHARS \
		else full_desc.substr(0, DESC_MAX_CHARS).rstrip(" ,.") + "…"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.theme_type_variation = &"LabelMuted"
	info.add_child(desc)
	row.tooltip_text = full_desc

	var notes := _restriction_line(item)
	if notes != "":
		var note_lbl := Label.new()
		note_lbl.text = notes
		note_lbl.theme_type_variation = &"LabelGrayLight"
		info.add_child(note_lbl)

	if reason != "" and show_reason:
		var why := Label.new()
		why.text = "✕  " + LocalizationManager.tr_t(reason)
		why.theme_type_variation = &"LabelSmall"
		why.add_theme_color_override("font_color", GothicThemeHelper.color("color_status_danger"))
		info.add_child(why)

	# Sağ: ikonlu fiyat + Satın al
	var price_box := HBoxContainer.new()
	price_box.add_theme_constant_override("separation", 5)
	price_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(price_box)
	var icon := TextureRect.new()
	icon.texture = ICON_GLORY if item.cost_currency == ArmouryItem.Currency.GLORY else ICON_DUCAT
	icon.custom_minimum_size = Vector2(16, 16)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	price_box.add_child(icon)
	var price := Label.new()
	price.text = str(item.cost)
	price.custom_minimum_size.x = 28
	price.theme_type_variation = &"LabelGoldBright"
	price_box.add_child(price)

	var buy := Button.new()
	buy.text = LocalizationManager.tr_t("ARMOURY_BUY")
	buy.theme_type_variation = &"ButtonSecondary"
	buy.custom_minimum_size = Vector2(104, 34)
	buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buy.disabled = reason != ""
	var it := item
	buy.pressed.connect(func(): _try_buy(it))
	line.add_child(buy)

	# Alınamayan kalem bütünüyle solar; sebep kartın üstünde yazılı kalır.
	if reason != "":
		info.modulate.a = 0.55
		price_box.modulate.a = 0.55
	return row

## Kısıt + LIMIT satırı. Tüm metinler lokalizasyondan gelir.
func _restriction_line(item: Resource) -> String:
	var parts: Array[String] = []
	if item.restriction_key != "":
		parts.append(LocalizationManager.tr_t(item.restriction_key))
	if item.limit_per_warband > 0:
		var used: int = int(ArmouryManager.counts_of(_local_id).get(item.item_id, 0))
		parts.append(LocalizationManager.tr_t("ARMOURY_LIMIT_LEFT")
			% max(0, item.limit_per_warband - used))
	return "   ·   ".join(parts)

# ── Eylemler ────────────────────────────────────────────────────────────────
func _try_buy(item: Resource) -> void:
	var reason := ArmouryManager.request_purchase(_local_id, _selected_unit, item)
	if reason != "":
		_status.text = LocalizationManager.tr_t(reason)

func _on_purchase_made(_pid: int, _uname: String, _iid: StringName) -> void:
	refresh()

func _on_finish_pressed() -> void:
	ArmouryManager.finish_player(_local_id)
	finished.emit()
	if GameState.game_phase != GameState.GamePhase.ARMOURY:
		visible = false          # iki taraf da bitirdi -> savaş başladı, ekran kapanır
		return
	var next: int = ArmouryManager.current_shopper()
	if next != _local_id:
		open_for()               # tek makinede sıra rakibe geçti
	else:
		_status.text = LocalizationManager.tr_t("ARMOURY_WAITING")
		_finish_btn.disabled = true
