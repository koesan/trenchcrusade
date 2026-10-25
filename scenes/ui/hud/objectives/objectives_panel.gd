extends PanelContainer
class_name ObjectivesPanel

## Oyun içi görev hedeflerini ve VP durumunu gösteren bağımsız bileşen.
## ScenarioManager'a bağlanır: aktif senaryonun objective kontrol durumu + oyuncu VP'leri.

@onready var title_lbl: Label = $Margin/VBox/Title
@onready var vbox: VBoxContainer = $Margin/VBox
## MİMARİ DÜZELTME (kullanıcı isteği): VP etiketi SABİT/tek bir yapı — artık .tscn'de tanımlı,
## kod yalnız metnini/görünürlüğünü günceller (yok edip yeniden yaratmıyor). Objective satırları
## (_obj_rows) senaryoya göre DEĞİŞKEN SAYIDA olduğundan kod ile üretilmeye devam ediyor.
@onready var _vp_lbl: Label = $Margin/VBox/VPLabel

var _obj_rows: Array = []

func _ready():
	if Engine.is_editor_hint():
		return
	LocalizationManager.locale_changed.connect(update_locale)

	# Sahnedeki statik placeholder satırlarını kaldır (dinamik üretilecek)
	for n in ["Obj1", "Obj2"]:
		var c = vbox.get_node_or_null(n)
		if c:
			c.queue_free()

	ScenarioManager.scenario_changed.connect(_on_scenario_changed)
	ScenarioManager.vp_updated.connect(_on_vp_updated)
	TurnManager.turn_changed.connect(_on_turn_changed)

	_rebuild()
	update_locale()

func update_locale(_new_lang: String = ""):
	if is_instance_valid(title_lbl):
		title_lbl.text = LocalizationManager.tr_t("OBJECTIVES")
	_refresh()

func _on_scenario_changed(_s):
	_rebuild()

func _on_vp_updated(_vp):
	_refresh()

func _on_turn_changed(_p):
	_refresh()

## Senaryo değişiminde satırları yeniden kurar.
func _rebuild():
	for r in _obj_rows:
		if is_instance_valid(r):
			r.queue_free()
	_obj_rows.clear()

	var objs: Array = ScenarioManager.get_objectives_state()
	for _o in objs:
		var lbl := Label.new()
		lbl.theme_type_variation = &"LabelParchmentTan"
		vbox.add_child(lbl)
		_obj_rows.append(lbl)

	_refresh()

## Güncel VP ve kontrol durumunu etiketlere yazar.
func _refresh():
	if is_instance_valid(_vp_lbl):
		var vp: Dictionary = ScenarioManager.player_vp
		_vp_lbl.text = "%s  %s %d — %s %d" % [LocalizationManager.tr_t("VICTORY_POINTS"),
			PlayerLabel.name_of(1), vp.get(1, 0), PlayerLabel.name_of(2), vp.get(2, 0)]
		_vp_lbl.visible = ScenarioManager.uses_vp_victory()

	var objs: Array = ScenarioManager.get_objectives_state()
	for i in range(_obj_rows.size()):
		if i >= objs.size():
			break
		var o: Dictionary = objs[i]
		var ctrl: int = o.get("controller", 0)
		var ctrl_txt: String = LocalizationManager.tr_t("CONTROL_NEUTRAL")
		if ctrl == 1 or ctrl == 2:
			ctrl_txt = PlayerLabel.name_of(ctrl)
		if is_instance_valid(_obj_rows[i]):
			_obj_rows[i].text = "%s: %s" % [LocalizationManager.tr_t(o.get("label_key", "OBJECTIVE")), ctrl_txt]
