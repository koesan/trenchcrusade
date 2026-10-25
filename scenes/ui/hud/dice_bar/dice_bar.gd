extends PanelContainer
class_name DiceBarUI

## Controller for the Dice Bar component.
## Handles loading, configuring, animating, and destroying the dice result panel.

@onready var hbox: HBoxContainer = $VBoxContainer/DiceHBox
@onready var total_lbl: Label = $VBoxContainer/DiceHBox/TotalLabel
@onready var res_lbl: Label = $VBoxContainer/ResultLabel
@onready var caption_lbl: Label = $VBoxContainer/CaptionLabel

## Zar barının dikey yeri: üst bardaki faz/sıra yazısının ALTINDA (eskiden onun üstüne biniyordu).
const TOP_OFFSET := 182.0

const DICE_VALUE_LABEL_SCENE = preload("res://scenes/ui/hud/dice_bar/dice_value_label.tscn")

## PERFORMANS DÜZELTMESİ: kullanıcı bildirimi — "zar atıldıktan sonra eylem gerçekleşirken /
## üst bar gelirken kısa bir takılma oluyor, her eylemde fark ediliyor." Kök neden: bu panel
## önceden game_hud.gd tarafından HER ATIŞTA queue_free() edilip preload().instantiate() ile
## SIFIRDAN kuruluyordu — GothicThemeHelper.init_ui() de her seferinde perçin (rivet) düğümlerini
## yeniden yaratıyordu. DiceManager zaten AYNI sınıf sorunu ("her atışta instantiate GLB sahnesi
## donmaya yol açıyordu") zar HAVUZU ile çözmüştü (bkz. dice_manager.gd üst yorumu) — bu panel o
## düzeltmenin kapsamı DIŞINDA kalmıştı. Artık game_hud.gd panoyu BİR KEZ oluşturup TEKRAR
## KULLANIYOR; GothicThemeHelper.init_ui() de yalnız İLK kurulumda çalışır (_themed bayrağı).
var _themed: bool = false
## Üst üste hızlı atışlarda (ör. Multiple Melee Weapons zincirleme saldırıları) önceki çağrının
## 4 saniyelik "kendiliğinden kaybol" beklemesi hâlâ sürerken yeni bir atış gelirse, eski
## coroutine'in paneli ERKEN gizlemesini önler (yalnız KENDİ nesli hâlâ güncelse solmaya devam eder).
var _display_generation: int = 0
var _turn_player: int = 0

## Hangi zarın atıldığı ve kaçının sayıldığı — "3-4 zar attı, neden?" sorusunun cevabı barın
## kendisinde: ek zarlar (+/- Zar) atılır, en yüksek (cezada en düşük) 2'si sayılır.
static func caption_for(roll_type: String, dice_count: int, kept_count: int, keep_highest: bool) -> String:
	var key: String = "DICE_CAPTION_" + roll_type.to_upper()
	var caption: String = LocalizationManager.tr_t(key if LocalizationManager.has_key(key) else "DICE_CAPTION_BONUS_ROLL")
	if dice_count > kept_count and roll_type != "d6":
		caption += "  ·  " + LocalizationManager.tr_t("DICE_KEEP_HIGHEST" if keep_highest else "DICE_KEEP_LOWEST") % kept_count
	return caption

func _ready():
	# Sıra el değiştirince önceki aktivasyonun zar sonucu kapanır (sıra şeridiyle çakışmasın).
	# (turn_changed aynı oyuncu için de yayılabilir — yalnız gerçek el değişimi sayılır.)
	_turn_player = TurnManager.current_turn_player_id
	TurnManager.turn_changed.connect(func(p: int):
		if p != _turn_player:
			_turn_player = p
			_display_generation += 1
			visible = false)

	# Zar barı savaş alanının ÜZERİNDE durur ve yalnız BİLGİ gösterir; altındaki birimlere
	# tıklamayı engellememeli. CanvasLayer'daki bir Control fare olayını yakalarsa harita
	# tıklaması (`map_input._unhandled_input`) HİÇ tetiklenmez — bar açıkken o bölgedeki
	# birimler seçilemez hâle gelirdi.
	UIPlacement.make_click_through(self)
	resized.connect(func(): pivot_offset = size / 2.0)
	pivot_offset = size / 2.0

func setup_dice_bar(sorted_vals: Array, kept_count: int, keep_highest: bool, flat_modifier: int, total_result: int, roll_type: String) -> void:
	_display_generation += 1
	var my_generation := _display_generation

	# Calculate which indices are kept
	var vals = sorted_vals.duplicate()
	var kept_indices = []
	
	if roll_type == "d6" and vals.size() <= 1:
		kept_indices = [0]
	else:
		vals.sort()
		if keep_highest:
			for i in range(vals.size() - kept_count, vals.size()):
				if i >= 0:
					kept_indices.append(i)
		else:
			for i in range(0, kept_count):
				if i < vals.size():
					kept_indices.append(i)
					
	# Clear any previous value labels from DiceHBox (leaving only TotalLabel)
	for child in hbox.get_children():
		if child != total_lbl:
			child.queue_free()
			
	# Instantiate value labels
	for i in range(vals.size()):
		var val = vals[i]
		var face_lbl = DICE_VALUE_LABEL_SCENE.instantiate()
		var is_kept = (i in kept_indices)
		face_lbl.setup_dice(val, is_kept)
		
		hbox.add_child(face_lbl)
		# Dinamik eklenen etiketler de fare olaylarına şeffaf olmalı (bkz. _ready'deki not) —
		# aksi hâlde bar her atışta yeniden tıklama engeli üretirdi.
		face_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Move the face label before the TotalLabel
		hbox.move_child(face_lbl, hbox.get_child_count() - 2)
		
	var flat_str = ""
	if flat_modifier > 0:
		flat_str = " (+%d)" % flat_modifier
	elif flat_modifier < 0:
		flat_str = " (%d)" % flat_modifier
		
	total_lbl.text = "  =  %d%s" % [total_result, flat_str]
	total_lbl.add_theme_color_override("font_color", GothicThemeHelper.color("color_parchment"))
	
	# Sonuç metni ANAHTARI: DiceRoller.result_text_key SAF fonksiyonu (Node'suz test edilebilir,
	# bkz. dice_result_text_test.gd) — burada yalnız renk/görsel eşleme kalır.
	var text_key := DiceRoller.result_text_key(roll_type, total_result)
	var success_text := LocalizationManager.tr_t(text_key)
	match text_key:
		"ROLL_SUCCESS_OK", "ROLL_ENEMY_HIT":
			res_lbl.add_theme_color_override("font_color", GothicThemeHelper.color("color_gold_bright"))
		"ROLL_SUCCESS_FAIL", "ROLL_INJURY_OUT", "ROLL_FRIENDLY_FIRE":
			res_lbl.add_theme_color_override("font_color", GothicThemeHelper.color("color_status_danger"))
		"ROLL_INJURY_NONE":
			res_lbl.add_theme_color_override("font_color", GothicThemeHelper.color("color_muted"))
		"ROLL_INJURY_SCRATCH":
			res_lbl.add_theme_color_override("font_color", GothicThemeHelper.color("color_status_caution"))
		"ROLL_INJURY_DOWN":
			res_lbl.add_theme_color_override("font_color", GothicThemeHelper.color("color_status_warn"))
		_:
			res_lbl.add_theme_color_override("font_color", GothicThemeHelper.color("color_parchment"))

	res_lbl.text = success_text
	caption_lbl.text = caption_for(roll_type, sorted_vals.size(), kept_count, keep_highest)
	
	# Layout settings
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	offset_top = TOP_OFFSET
	offset_bottom = TOP_OFFSET + 70.0
	
	if not _themed:
		GothicThemeHelper.init_ui(self)
		_themed = true

	# Entrance animation
	visible = true
	modulate.a = 1.0
	scale = Vector2(0.8, 0.8)
	pivot_offset = size / 2.0
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Bir süre sonra kendiliğinden solup gizlenir (artık queue_free DEĞİL — panel game_hud.gd
	# tarafından TEKRAR KULLANILIYOR, bkz. yukarıdaki performans notu).
	await get_tree().create_timer(4.0).timeout
	if not is_instance_valid(self) or my_generation != _display_generation:
		return
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	fade_tween.tween_callback(func():
		if my_generation == _display_generation:
			visible = false)
