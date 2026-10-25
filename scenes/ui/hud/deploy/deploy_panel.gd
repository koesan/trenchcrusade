extends PanelContainer

## YERLEŞTİRME PANELİ — ekranın altı, yalnız yerleştirme aşamasında.
##   Başlık satırı: faksiyon adı (blackletter) + oyuncu ve yönerge · bütçe (duka, şan) · Bitir
##   Kart sırası : faksiyonun birimleri, kemerli niş kartlarda (3B model, ad, fiyat)
##
## KIPIRDAMA ÖNLEMİ: kartlar yalnız faksiyon ya da gösterilen oyuncu DEĞİŞİNCE yeniden kurulur;
## bütçe/seçim değişince mevcut kartların durumu yerinde güncellenir (refresh_deploy_state).
## Eskiden her yerleştirmede bütün kartlar 3B önizlemeleriyle yıkılıp yeniden kuruluyordu.

signal unit_type_selected(res_path: String)
signal card_hover_started(ud: Resource, btn: Button)
signal card_hover_ended
signal finish_deployment_pressed

const DEPLOY_CARD_SCENE = preload("res://scenes/ui/hud/deploy/deploy_unit_card.tscn")

@onready var info_label: Label = $MarginContainer/VBoxContainer/HeaderHBox/TitleBox/DeployInfoLabel
@onready var _title: Label = %Title
@onready var _ducats: Label = %Value
@onready var _glory: Label = $MarginContainer/VBoxContainer/HeaderHBox/Glory/Value
@onready var _finish: Button = %FinishDeployButton
@onready var buttons_container: HBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/DeployButtons
@onready var scroll_container: ScrollContainer = $MarginContainer/VBoxContainer/ScrollContainer
@onready var waiting_label: Label = $MarginContainer/VBoxContainer/WaitingLabel

## Kartların kimin için kurulduğu: "<faksiyon_id>:<oyuncu>"
var _built_for := ""

func _ready() -> void:
	# Sürükleyerek kaydırma (bkz. scripts/ui/drag_scroll.gd)
	DragScroll.attach(scroll_container)
	_finish.pressed.connect(func(): finish_deployment_pressed.emit())

func update_panel(faction: Resource, pool: int, selected_type: String, local_player_id: int, loadout_label: String = "") -> void:
	if faction == null:
		return
	# Ağ oyununda panel hep yerel oyuncuyu, aynı makinede sırası gelen oyuncuyu gösterir.
	var shown_pid: int = local_player_id
	if not (multiplayer and multiplayer.has_multiplayer_peer()):
		shown_pid = GameState.active_deployer_id

	_title.text = PlayerLabel.faction_name(faction)
	var info := LocalizationManager.tr_t("DEPLOY_SUBTITLE") % PlayerLabel.generic(shown_pid)
	# Seçili Battlekit varyantı — oyuncu neyi yerleştireceğini haritaya tıklamadan görsün.
	if loadout_label != "":
		info += "  ·  " + loadout_label
	info_label.text = info
	# İKİ HAVUZ: duka (normal kadro) ve şan (paralı asker) birbirinin yerine geçmez.
	_ducats.text = str(pool)
	_glory.text = str(GameState.player_glory_pool.get(local_player_id, 0))
	_finish.text = LocalizationManager.tr_t("FINISH_DEPLOYMENT")

	if not GameState.can_player_deploy_more(local_player_id):
		scroll_container.visible = false
		waiting_label.visible = true
		waiting_label.text = LocalizationManager.tr_t("WAITING_OTHER_SQUAD")
		return
	scroll_container.visible = true
	waiting_label.visible = false

	var key := "%s:%d" % [faction.faction_id, shown_pid]
	if key != _built_for:
		_built_for = key
		_build_cards(faction, selected_type)
	else:
		for btn in buttons_container.get_children():
			if btn.unit_data_res != null:
				btn.refresh_deploy_state(selected_type == btn.unit_data_res.resource_path)

func _build_cards(faction: Resource, selected_type: String) -> void:
	for child in buttons_container.get_children():
		buttons_container.remove_child(child)
		child.queue_free()
	for ud in faction.available_units:
		# 3B modeli henüz olmayan birimler veride kalır ama listede gösterilmez (model
		# eklenince kod değişikliği olmadan seçilebilir hâle gelir).
		if ud.model_scene_path == "":
			continue
		var btn = DEPLOY_CARD_SCENE.instantiate()
		buttons_container.add_child(btn)
		btn.setup_for_deployment(ud, selected_type == ud.resource_path)
		var unit_res_path = ud.resource_path
		btn.pressed.connect(func(): unit_type_selected.emit(unit_res_path))
		btn.mouse_entered.connect(func(): card_hover_started.emit(ud, btn))
		btn.mouse_exited.connect(func(): card_hover_ended.emit())
	GothicThemeHelper.init_ui(self)
