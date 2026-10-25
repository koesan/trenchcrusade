@tool
extends CanvasLayer

## Oyun içi HUD koordinatörü.
## Sıra bilgisi, birim panelleri, faksiyon seçimi ve üst-menü katmanlarını koordine eder.
## Trench Crusade kurallarına ve görsel evrenine uygundur.

# Kapsüllenmiş Alt Paneller (Sorumlulukları kendi scriptlerine devredildi)
@onready var top_bar = $MarginContainer/VBoxContainer/TopBar
var overlay_manager: OverlayManager

@onready var command_bar: CommandBar = %CommandBar
@onready var deploy_panel = $MarginContainer/VBoxContainer/BottomPanel/DeployPanel
@onready var unit_cards_container: UnitCardsContainer = %UnitCards
## Üst ortadaki duyuru sütunu: tur şeridi, inisiyatif sorusu ve uyarılar ALT ALTA dizilir —
## eskiden her biri kendi mutlak konumundaydı ve üst üste biniyordu.
@onready var notices: VBoxContainer = %Notices
@onready var notice_feed: NoticeFeed = %NoticeFeed
@onready var faction_panel = $FactionPanel
@onready var armoury_panel = $ArmouryPanel

@onready var resources_panel = %ResourcesPanel
@onready var objectives_panel = %ObjectivesPanel
@onready var game_end_overlay = %GameEndOverlay

const HUD_ACTION_BUTTON_SCENE = preload("res://scenes/ui/hud/action_panel/hud_action_button.tscn")

# Performans: Yerleşim kontrolü
var _last_deployer_id: int = -1
var _last_deploy_pool: int = -1
var _frame_counter: int = 0

const RECONNECT_OVERLAY_SCENE = preload("res://scenes/ui/overlays/reconnect/reconnect_overlay.tscn")
const SAVING_OVERLAY_SCENE = preload("res://scenes/ui/overlays/saving/saving_overlay.tscn")
const SCENARIO_PANEL_SCENE = preload("res://scenes/ui/scenario_select/scenario_selection_panel.tscn")
const INITIATIVE_PROMPT_SCENE = preload("res://scenes/ui/initiative/initiative_prompt.tscn")
const MARKER_OVERLAY_SCENE = preload("res://scenes/ui/combat_choice/marker_spend_overlay.tscn")
## P1-1: reaktif harita-seçim modu (Time Slip/Temporal Assassin) için ekranı kapatmayan bilgi kartı.
const INTERACTION_HINT_SCENE = preload("res://scenes/ui/combat_choice/interaction_hint_card.tscn")
const LOADOUT_PICKER_SCENE = preload("res://scenes/ui/deploy/loadout_picker_overlay.tscn")
## P1-1 (Mendelist Ammo Monk — Ammunition Sacrament): 3 seçenekli, tamamen yerel karar overlay'i
## (loadout_picker_overlay ile AYNI desen).
const SACRAMENT_PICKER_SCENE = preload("res://scenes/ui/hud/action_panel/ammunition_sacrament_picker.tscn")
## P1-1 (Court of the Seven-Headed Serpent — Slavemaster Goetic Spell): Yoke Fiend'e verilecek
## komutu (Move/Shoot/Fight/Sacrifice) seçtiren, tamamen yerel karar overlay'i (AYNI desen).
const SLAVEMASTER_PICKER_SCENE = preload("res://scenes/ui/hud/action_panel/slavemaster_command_picker.tscn")
## Faksiyon kurulum seçimi (Court → Seven Deadly Sins, Grail → The Order of the Fly).
## TEK genel bileşen sürer; yeni bir seçim eklemek yalnız FactionData'ya sabit sözlük ister.
const FACTION_CHOICE_SCENE = preload("res://scenes/ui/faction_select/faction_choice_overlay.tscn")
const SHOT_BREAKDOWN_SCENE = preload("res://scenes/ui/hud/shot_breakdown/shot_breakdown_card.tscn")
## TEK hover bilgi kartı — birim profili de, yetenek açıklaması da bunun farklı "şekilleridir"
## (kullanıcı isteği: "farklı farklı popuplar yapmaktansa tek popup yap"). İçeriği
## `InfoSpec` üretir; gecikme/konum/yükseklik kuralları kartın kendisindedir.
const INFO_POPUP_SCENE = preload("res://scenes/ui/shared/info_popup.tscn")

var reconnect_overlay_node: Control = null
var saving_overlay_node: Control = null
var scenario_panel: Control = null
var initiative_prompt: Control = null
var marker_overlay: Control = null
var interaction_hint_card: Control = null
var loadout_picker: Control = null
var sacrament_picker: Control = null
var slavemaster_picker: Control = null
var faction_choice_overlay: Control = null
var shot_breakdown_card: Control = null
## Yüzen bilgi kartı — birim kartları, yerleştirme kartları ve eylem butonları AYNI örneği
## kullanır. Aynı anda yalnız biri görünebilir; bu, iki kartın üst üste binmesini de engeller.
var info_popup: InfoPopup = null

# ─── GERİ GİTME (OVERLAY STACK) SİSTEMİ ─────────────────────────────────────
## Şu an ekranda açık olan üst-menü overlay'inin anahtarı ("" = hiçbiri açık değil).
var current_overlay: String:
	get:
		return overlay_manager.current_overlay if overlay_manager else ""

# Button highlighting is now managed by the HUDActionButton component

func _ready():
	overlay_manager = OverlayManager.new(self)
	
	if Engine.is_editor_hint():
		GothicThemeHelper.init_ui(self)
		return

	TurnManager.turn_changed.connect(_on_turn_changed)
	GameState.unit_selected.connect(_on_unit_selected)
	GameState.unit_deselected.connect(_on_unit_deselected)
	DiceManager.show_dice_bar_ui.connect(_on_show_dice_bar_ui)

	# Sinyaller
	GameState.faction_selected.connect(_on_faction_selected_signal)
	GameState.deploy_side_chosen.connect(func(_zone_a_owner): _update_hud_visibility())
	GameState.unit_deployed.connect(_on_unit_deployed_signal)
	GameState.deployment_completed.connect(_on_deployment_completed)
	if GameState.has_signal("active_deployer_changed"):
		GameState.active_deployer_changed.connect(_on_active_deployer_changed)
	
	# Oyun sonu
	GameEvents.game_over.connect(_on_game_over)

	# Yerleştirme/hareket/yetenek reddi → kısa toast (oyuncu NEDEN olmadığını görür)
	for sig in [GameEvents.deploy_rejected, GameEvents.move_rejected, GameEvents.ability_rejected]:
		sig.connect(_on_action_rejected)
	GameEvents.notice_posted.connect(_on_notice)
	
	# Dil
	LocalizationManager.locale_changed.connect(_on_locale_changed)
	
	# Alt panel olaylarının bağlanması (Decoupled signals)
	faction_panel.faction_selected.connect(_on_faction_selected_new)
	deploy_panel.unit_type_selected.connect(_on_deploy_unit_type_selected)
	deploy_panel.card_hover_started.connect(_on_deploy_button_hover_started)
	deploy_panel.card_hover_ended.connect(_on_deploy_button_hover_ended)
	deploy_panel.finish_deployment_pressed.connect(_on_finish_deployment_pressed)
	command_bar.end_turn_pressed.connect(_on_end_turn_pressed)
	# Kadro sütunu her zaman komuta panelinin ÜSTÜNDE biter.
	command_bar.resized.connect(func(): $RosterColumn.offset_bottom = -(command_bar.size.y + 40.0))
	
	# Dynamic overlay connections using overlay_manager
	var pause_overlay = overlay_manager.overlays["pause"]
	if pause_overlay:
		pause_overlay.resume_pressed.connect(overlay_manager.go_back)
		pause_overlay.settings_pressed.connect(func(): overlay_manager.open_overlay("settings"))
		pause_overlay.save_pressed.connect(_on_save_pressed)
		pause_overlay.exit_pressed.connect(_on_save_quit_pressed)
		
	var chronicles_overlay = overlay_manager.overlays["chronicles"]
	if chronicles_overlay:
		chronicles_overlay.roster_pressed.connect(func(): overlay_manager.open_overlay("roster"))
		chronicles_overlay.profile_pressed.connect(func(): overlay_manager.open_overlay("profile" if is_instance_valid(GameState.selected_unit) else "roster"))
		overlay_manager.overlays["roster"].unit_picked.connect(func(u): overlay_manager.overlays["profile"].focus_unit = u; overlay_manager.open_overlay("profile"))
		chronicles_overlay.blessings_pressed.connect(func(): overlay_manager.open_overlay("blessings"))
		chronicles_overlay.keywords_pressed.connect(func(): overlay_manager.open_overlay("keywords"))
		chronicles_overlay.lore_pressed.connect(func(): overlay_manager.open_overlay("guide"))
		
	# "Geri" düğmesi: `close_pressed` artık OverlayPanel taban sınıfında tanımlı, bu yüzden
	# KAYITLI HER overlay tek bir döngüde bağlanır (Guide dâhil — kökü artık sözleşmeye uyuyor,
	# eskiden alt düğümü olan CodexPanel ayrıca elle bağlanıyordu).
	for key in overlay_manager.overlays.keys():
		var overlay = overlay_manager.overlays.get(key)
		if overlay and overlay.has_signal("close_pressed"):
			if not overlay.close_pressed.is_connected(overlay_manager.go_back):
				overlay.close_pressed.connect(overlay_manager.go_back)
			
	var game_end_node = overlay_manager.overlays.get("game_end")
	if game_end_node:
		game_end_node.return_pressed.connect(_on_exit_pressed)
	
	# Senaryo seçim paneli (kod ile eklenir; SCENARIO_SELECT aşamasında gösterilir)
	scenario_panel = SCENARIO_PANEL_SCENE.instantiate()
	add_child(scenario_panel)
	scenario_panel.scenario_selected.connect(_on_scenario_selected)
	scenario_panel.visible = false
	GameState.game_phase_changed.connect(_on_game_phase_changed)

	# Initiative (öncelik) seçim istemi
	# İnisiyatif sorusu ekranın TAM ORTASINDA sabit yuvada (kullanıcı isteği: duyurularla aynı
	# sütundayken onlar belirip kayboldukça yukarı-aşağı kayıyordu).
	initiative_prompt = INITIATIVE_PROMPT_SCENE.instantiate()
	%ModalCenter.add_child(initiative_prompt)
	initiative_prompt.order_chosen.connect(_on_initiative_order_chosen)
	initiative_prompt.visible = false
	TurnManager.initiative_choice_required.connect(_on_initiative_choice_required)
	TurnManager.round_started.connect(func(_r): if is_instance_valid(initiative_prompt): initiative_prompt.visible = false)
	GameState.unit_selected.connect(func(_u): if is_instance_valid(initiative_prompt): initiative_prompt.visible = false)

	# Marker harcama seçim overlay'i (Blessing/Blood/Bloodbath) — CombatChoice'a kaydet
	marker_overlay = MARKER_OVERLAY_SCENE.instantiate()
	add_child(marker_overlay)
	CombatChoice.set_overlay(marker_overlay)

	# P1-1: harita-seçim bilgi kartı (Time Slip/Temporal Assassin) — GameState.pick_mode'u
	# doğrudan dinler, CombatChoice'a kayıt gerektirmez (marker_overlay'den farklı).
	interaction_hint_card = INTERACTION_HINT_SCENE.instantiate()
	add_child(interaction_hint_card)

	# FAZ 5 (P1-1): Battlekit/loadout seçim overlay'i — tamamen yerel (ağ round-trip'i yok).
	loadout_picker = LOADOUT_PICKER_SCENE.instantiate()
	add_child(loadout_picker)

	sacrament_picker = SACRAMENT_PICKER_SCENE.instantiate()
	add_child(sacrament_picker)

	slavemaster_picker = SLAVEMASTER_PICKER_SCENE.instantiate()
	add_child(slavemaster_picker)

	faction_choice_overlay = FACTION_CHOICE_SCENE.instantiate()
	add_child(faction_choice_overlay)

	# Atış Breakdown Kartı (attack eylemi + düşman hover'ında gösterilir)
	shot_breakdown_card = SHOT_BREAKDOWN_SCENE.instantiate()
	add_child(shot_breakdown_card)
	# Eylem/seçim değişince kartı gizle (yanıltıcı kalmasın)
	GameState.unit_deselected.connect(func(): hide_shot_breakdown())

	# TEK hover bilgi kartı. İçeriğe göre DİNAMİK boyutlanır, imlecin ÜSTÜNDE açılır ve
	# tıklama geçirgenliğini kendi yönetir — kurallar tek yerde (bkz. info_popup.gd).
	# CanvasLayer'a doğrudan eklenir: bir Container çocuğunun konumunu HER KAREDE ezer ve
	# kartı panelin dayattığı yere (sol üst) geri fırlatırdı.
	info_popup = INFO_POPUP_SCENE.instantiate()
	add_child(info_popup)
	if is_instance_valid(unit_cards_container):
		unit_cards_container.card_hover_started.connect(_on_unit_card_hover_started)
		unit_cards_container.card_hover_ended.connect(_on_unit_card_hover_ended)

	_update_hud_visibility()
	_update_locale()
	_on_turn_changed(TurnManager.current_turn_player_id)

	if SaveManager.is_waiting_for_reconnect:
		show_reconnect_overlay()

	GothicThemeHelper.init_ui(self)

## Bu oyuncu senaryoyu seçebilir mi? MP'de host; çevrimdışı'da aktif oyuncu (1).
func _is_scenario_chooser() -> bool:
	if multiplayer and multiplayer.has_multiplayer_peer():
		return multiplayer.is_server()
	return GameState.active_deployer_id == 1

func _on_scenario_selected(scenario_id: StringName) -> void:
	var game_node = get_parent()
	if is_instance_valid(game_node) and game_node.has_method("request_select_scenario"):
		game_node.request_select_scenario(String(scenario_id))

func _on_game_phase_changed(_phase_idx: int) -> void:
	notice_feed.clear()
	_update_hud_visibility()

## Raund başında initiative sahibine ilk/ikinci seçimini sunar (yalnız o oyuncuya).
func _on_initiative_choice_required(winner_id: int) -> void:
	if not is_instance_valid(initiative_prompt):
		return
	var is_local_winner := true
	if multiplayer and multiplayer.has_multiplayer_peer():
		is_local_winner = NetworkManager.get_local_canonical_id() == winner_id
	initiative_prompt.visible = is_local_winner and GameState.game_phase == GameState.GamePhase.BATTLE

func _on_initiative_order_chosen(go_first: bool) -> void:
	if is_instance_valid(initiative_prompt):
		initiative_prompt.visible = false
	TurnManager.request_initiative_order(go_first)

## Atış Breakdown Kartını gösterir (map_input hover'ından çağrılır).
func show_shot_breakdown(attacker, target) -> void:
	if is_instance_valid(shot_breakdown_card):
		shot_breakdown_card.show_for(attacker, target)
	get_tree().call_group("target_line", "show_for", attacker, target)

## Kullanıcı isteği: "yetenek seçince unit üstüne gelen popup'ta da aynı şekilde gerekli bilgiler
## olsun." Attack breakdown'ın AYNI kartı (aynı anda yalnız biri görünür), yetenek/Charge hedefleme
## sırasında da menzil + (yeteneğin) SUCCESS açıklamasını gösterir — bkz. shot_breakdown_card.gd.
func show_ability_breakdown(caster, target, ability: AbilityData, ability_label_key: String) -> void:
	if is_instance_valid(shot_breakdown_card):
		shot_breakdown_card.show_for_ability(caster, target, ability, ability_label_key)
	get_tree().call_group("target_line", "show_for", caster, target)

func show_charge_breakdown(attacker, target) -> void:
	if is_instance_valid(shot_breakdown_card):
		shot_breakdown_card.show_for_charge(attacker, target)

func hide_shot_breakdown() -> void:
	if is_instance_valid(shot_breakdown_card):
		shot_breakdown_card.hide_card()
	get_tree().call_group("target_line", "hide_line")

## Ammunition Sacrament 3-seçenek overlay'ini gösterir (map_input'un ability-hedefleme akışından
## çağrılır, hedef seçildikten SONRA — bkz. ammunition_sacrament_picker.gd).
func show_ammunition_sacrament_picker(target_display_name: String, callback: Callable) -> void:
	if is_instance_valid(sacrament_picker):
		sacrament_picker.show_prompt(target_display_name, callback)
	elif callback.is_valid():
		callback.call("")

## Slavemaster 4-komut overlay'ini gösterir (map_input'un ability-hedefleme akışından çağrılır,
## hedef Yoke Fiend seçildikten SONRA — bkz. slavemaster_command_picker.gd).
func show_slavemaster_command_picker(target_display_name: String, callback: Callable) -> void:
	if is_instance_valid(slavemaster_picker):
		slavemaster_picker.show_prompt(target_display_name, callback)
	elif callback.is_valid():
		callback.call("")

func _get_local_player_id() -> int:
	return NetworkManager.get_local_canonical_id()

func _update_hud_visibility():
	var local_id = _get_local_player_id()
	var faction = GameState.get_faction_for_player(local_id)

	# ── SENARYO SEÇİM AŞAMASI ────────────────────────────────────────────────
	if GameState.game_phase == GameState.GamePhase.SCENARIO_SELECT:
		if is_instance_valid(scenario_panel):
			if not scenario_panel.visible:
				UIAnim.pop_in(scenario_panel, scenario_panel.get_node_or_null("Panel"))
			scenario_panel.set_local_can_choose(_is_scenario_chooser())
		faction_panel.visible = false
		deploy_panel.visible = false
		command_bar.visible = false
		unit_cards_container.visible = false
		top_bar.apply_phase(GameState.game_phase)
		return
	elif is_instance_valid(scenario_panel):
		scenario_panel.visible = false

	top_bar.apply_phase(GameState.game_phase)
	if GameState.game_phase == GameState.GamePhase.DEPLOYMENT:
		command_bar.visible = false
		unit_cards_container.visible = false

		if faction == null:
			if not faction_panel.visible:
				UIAnim.pop_in(faction_panel, faction_panel.get_node_or_null("Panel"))
			if faction_panel.has_method("set_active_player"):
				faction_panel.set_active_player(local_id)
			deploy_panel.visible = false
		else:
			faction_panel.visible = false
			deploy_panel.visible = true
			_update_deploy_panel()
	elif GameState.game_phase == GameState.GamePhase.ARMOURY:
		# CEPHANELİK FAZI: yerleştirme bitti, savaş başlamadan önce Battlekit satın alınır.
		faction_panel.visible = false
		deploy_panel.visible = false
		command_bar.visible = false
		unit_cards_container.visible = false
		if is_instance_valid(armoury_panel):
			armoury_panel.open_for(local_id)
		return
	else:
		if is_instance_valid(armoury_panel):
			armoury_panel.visible = false
		faction_panel.visible = false
		deploy_panel.visible = false
		_rebuild_unit_cards()
		_refresh_command_bar()

func _update_deploy_panel():
	var local_id = _get_local_player_id()
	var faction = GameState.get_faction_for_player(local_id)
	if faction == null:
		return
		
	var pool = GameState.player_deploy_pool.get(local_id, 0)
	if not GameState.can_player_deploy_more(local_id):
		GameState.selected_deploy_unit_type = ""
		GameState.selected_loadout_index = -1

	# FAZ 5 (P1-1): seçili bir Battlekit varsa kısa etiketini panelde göster (oyuncu neyi
	# seçtiğini haritaya tıklamadan ÖNCE görsün — "başarılı ama görünmüyor" hatasına düşme).
	var loadout_label := ""
	if GameState.selected_deploy_unit_type != "" and GameState.selected_loadout_index >= 0:
		var sel_ud = load(GameState.selected_deploy_unit_type)
		if sel_ud != null and GameState.selected_loadout_index < sel_ud.loadout_options.size():
			var opt = sel_ud.loadout_options[GameState.selected_loadout_index]
			if opt != null:
				loadout_label = LocalizationManager.tr_t(opt.option_name_key)

	deploy_panel.update_panel(faction, pool, GameState.selected_deploy_unit_type, local_id, loadout_label)

func _on_deploy_unit_type_selected(res_path: String):
	# FAZ 5 (P1-1): Birden fazla Battlekit/loadout seçeneği taşıyan birimler için önce seçim
	# overlay'i gösterilir; sonuç GameState.selected_loadout_index'e yazılır.
	var ud = load(res_path)
	if ud != null and "loadout_options" in ud and ud.loadout_options.size() > 0:
		var unit_display_name: String = LocalizationManager.tr_t(
			ud.unit_name.to_upper().replace(" ", "_").replace("-", "_"))
		loadout_picker.show_prompt(unit_display_name, ud.loadout_options, func(idx: int):
			if idx < 0:
				GameState.selected_deploy_unit_type = ""
				GameState.selected_loadout_index = -1
			else:
				GameState.selected_deploy_unit_type = res_path
				GameState.selected_loadout_index = idx
			_update_deploy_panel()
		)
	else:
		GameState.selected_deploy_unit_type = res_path
		GameState.selected_loadout_index = -1
		_update_deploy_panel()

func _on_finish_deployment_pressed():
	var local_id = _get_local_player_id()
	if GameState.game_phase == GameState.GamePhase.DEPLOYMENT and GameState.can_player_deploy_more(local_id):
		var parent = get_parent()
		if is_instance_valid(parent) and parent.has_method("request_finish_deployment"):
			parent.request_finish_deployment()

func _on_faction_selected_signal(player_id, faction):
	_update_hud_visibility()

func _on_unit_deployed_signal(_player_id, _unit_node):
	_last_deploy_pool = -1
	_update_hud_visibility()

func _on_deployment_completed():
	_update_hud_visibility()
	_on_turn_changed(TurnManager.current_turn_player_id)

func _on_active_deployer_changed(_new_id: int):
	_update_hud_visibility()

func _on_turn_changed(_active_player_id: int):
	_rebuild_unit_cards()
	_refresh_command_bar()
	if is_instance_valid(top_bar):
		top_bar.update_top_bar()

func _on_unit_selected(_unit):
	_refresh_command_bar()

func _rebuild_action_buttons(_unit):
	_refresh_command_bar()

func _on_unit_deselected():
	_refresh_command_bar()

func _refresh_command_bar() -> void:
	command_bar.sync()

func _on_end_turn_pressed():
	TurnManager.end_turn()

func _on_exit_pressed():
	NetworkManager.leave_game()
	GameState.clear_state()
	LoadingManager.load_scene("res://scenes/ui/main_menu/main_menu.tscn")

func _on_save_pressed():
	show_saving_overlay()
	# Görüntünün ekrana çizilmesi için bir kare bekle
	await get_tree().create_timer(0.25).timeout
	
	if SaveManager.save_game():
		GameLogger.log_info("Sefer başarıyla hıfzedildi (Kaydedildi).", "SYSTEM")
	else:
		GameLogger.log_error("Sefer hıfzedilemedi!", "SYSTEM")
	
	hide_saving_overlay()

func _on_save_quit_pressed():
	SaveManager.save_game()
	_on_exit_pressed()

func show_reconnect_overlay():
	if reconnect_overlay_node != null:
		return
	reconnect_overlay_node = RECONNECT_OVERLAY_SCENE.instantiate()
	add_child(reconnect_overlay_node)

func hide_reconnect_overlay():
	if reconnect_overlay_node != null:
		reconnect_overlay_node.queue_free()
		reconnect_overlay_node = null

func show_saving_overlay():
	if saving_overlay_node != null:
		return
	saving_overlay_node = SAVING_OVERLAY_SCENE.instantiate()
	add_child(saving_overlay_node)

func hide_saving_overlay():
	if saving_overlay_node != null:
		saving_overlay_node.queue_free()
		saving_overlay_node = null

func _process(delta):
	if Engine.is_editor_hint():
		return
		
	_frame_counter += 1
	if _frame_counter % 5 == 0:
		# Her ikisi de YALNIZ değişen değeri yazar (yerleşim yeniden hesaplanmaz, kıpırdama yok).
		_update_unit_cards_realtime()
		command_bar.refresh_state()
		_update_top_bar_stats()
	
	if GameState.game_phase == GameState.GamePhase.DEPLOYMENT:
		var current_deployer = GameState.active_deployer_id
		var local_id = _get_local_player_id()
		var current_pool = GameState.player_deploy_pool.get(local_id, 0)
		
		if current_deployer != _last_deployer_id or current_pool != _last_deploy_pool:
			_last_deployer_id = current_deployer
			_last_deploy_pool = current_pool
			_update_hud_visibility()

func _update_top_bar_stats():
	top_bar.set_activation_summary(ActivationCues.refresh_all())  # halka nabzı + "aktif model" satırı
	#  Dukat  = yerel oyuncunun SAHADAKI warband değeri (UnitData.cost toplamı)
	#  Faith  = yerel oyuncunun toplam Nimet (Blessing) İşareti
	#  Blood  = DÜŞMAN modellerindeki toplam Kan İşareti (saldırırken harcanabilir)
	var local_id = _get_local_player_id()
	var warband_value = 0
	var faith_markers = 0
	var enemy_blood = 0

	for unit in UnitQuery.alive():
		if unit.owner_id == local_id:
			if unit.unit_data:
				warband_value += unit.unit_data.cost
			faith_markers += unit.blessing_markers
		else:
			enemy_blood += unit.blood_markers

	if is_instance_valid(resources_panel):
		resources_panel.update_resources(warband_value, faith_markers, enemy_blood)
# Deploy (yerleştirme) kartı hover'ı: birim henüz sahada YOK → UnitData'dan statik profil.
func _on_deploy_button_hover_started(ud: Resource, btn: Button = null):
	if ud == null:
		return
	var spec := InfoSpec.for_unit_data(ud)
	# Alınamayan kartın NEDENİ (bütçe, sınır, oran…) kartta kırmızı rozet olarak yazar.
	var reason: String = btn.get_meta("block_reason", "") if is_instance_valid(btn) else ""
	if reason != "":
		spec["badges"] = [{"text": LocalizationManager.tr_t(reason), "color": GothicThemeHelper.color("color_status_danger")}]
	_show_info_popup(btn, spec)

func _on_deploy_button_hover_ended():
	_maybe_hide_hover_card()

# Battle unit kartı hover'ı: sahadaki birim → tam (runtime durum dahil) zengin profil.
func _on_unit_card_hover_started(unit, card: Control) -> void:
	if not is_instance_valid(unit):
		return
	_show_info_popup(card, InfoSpec.for_unit(unit))

func _on_unit_card_hover_ended() -> void:
	_maybe_hide_hover_card()

## Kapatma kararı kartın KENDİSİNE aittir (kaydırılabilir + fare üstündeyse açık kalır —
## kullanıcı isteği: "üstüne gidince açık kalsın ki kaydırabilsin").
func _maybe_hide_hover_card() -> void:
	if is_instance_valid(info_popup):
		info_popup.request_hide()

## Yüzen bilgi kartını açar. Boyutlandırma, konumlandırma ve gecikme kartın KENDİ
## sorumluluğudur (bkz. info_popup.gd + scripts/ui/ui_placement.gd); burada yalnız delege edilir.
func _show_info_popup(anchor: Control, spec: Dictionary) -> void:
	if is_instance_valid(info_popup) and is_instance_valid(anchor):
		info_popup.show_spec(anchor, spec)

func _rebuild_unit_cards():
	if is_instance_valid(unit_cards_container):
		unit_cards_container.rebuild()

func _update_unit_cards_realtime():
	if is_instance_valid(unit_cards_container):
		unit_cards_container.update_realtime()

func _unhandled_input(event):
	if Engine.is_editor_hint():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		# 1-9: komuta panelindeki eylem butonları (numaraları butonların köşesinde yazar)
		if event.keycode >= KEY_1 and event.keycode <= KEY_9 \
				and GameState.game_phase == GameState.GamePhase.BATTLE and overlay_manager.current_overlay == "":
			if command_bar.actions.press_hotkey(event.keycode - KEY_0):
				get_viewport().set_input_as_handled()
				return
		if event.keycode == KEY_I:
			overlay_manager.toggle_overlay("roster")
		elif event.keycode == KEY_C:
			overlay_manager.toggle_overlay("profile")
		elif event.keycode == KEY_O:
			overlay_manager.toggle_overlay("settings")
		elif event.is_action_pressed("ui_cancel"):
			if SaveManager.is_waiting_for_reconnect:
				return
			if current_overlay == "":
				overlay_manager.open_overlay("pause")
			else:
				overlay_manager.go_back()

func _on_chronicles_triggered():
	overlay_manager.toggle_overlay("chronicles")

func _on_pause_triggered():
	overlay_manager.toggle_overlay("pause")

func _on_game_over(winner_id: int):
	overlay_manager.close_current_overlay()
	var local_id = _get_local_player_id()
	
	if is_instance_valid(game_end_overlay):
		if multiplayer and multiplayer.has_multiplayer_peer():
			game_end_overlay.setup(winner_id == local_id)
		else:
			game_end_overlay.setup(winner_id == 1, true, winner_id)
		overlay_manager.open_overlay("game_end")

func _update_locale():
	# Top bar labels
	if is_instance_valid(top_bar):
		top_bar.update_top_bar()
	
	# Kaynaklar/Gazavat Hedefleri/Menü/Nizamlar butonları artık top_bar.tscn'in kendi düğümleri
	# (bkz. top_bar.gd) — kendi tooltip_text'lerini orada (_ready() içinde) ayarlıyorlar.
	if is_instance_valid(resources_panel):
		resources_panel.update_locale()
	if is_instance_valid(objectives_panel):
		objectives_panel.update_locale()
	
	# Rebuild values
	_on_turn_changed(TurnManager.current_turn_player_id)

func _on_locale_changed(_new_lang: String):
	_update_locale()

## Faksiyon seçildikten SONRA, compendium'un o faksiyon için zorunlu kıldığı bir kurulum
## seçimi varsa önce onu sorar (Court → Seven Deadly Sins, Grail → The Order of the Fly).
## Seçim yapılınca request_select_faction çağrılır; iptal = faksiyon seçimi iptal.
const _FACTION_SETUP_CHOICES := {
	&"court_of_seven_headed_serpent": {
		"field": "selected_sin",
		"desc_field": "demonic_aura_desc",
		"title_key": "SIN_SELECTION_TITLE",
		"desc_key": "SIN_SELECTION_DESC",
		"log_tag": "Seven Deadly Sins",
	},
	&"cult_of_the_black_grail": {
		"field": "leader_choice",
		"desc_field": "desc",
		"title_key": "LEADER_CHOICE_TITLE",
		"desc_key": "LEADER_CHOICE_DESC",
		"log_tag": "The Order of the Fly",
	},
}

func _on_faction_selected_new(faction: Resource):
	var setup = _FACTION_SETUP_CHOICES.get(faction.faction_id)
	if setup != null and is_instance_valid(faction_choice_overlay):
		var choices: Dictionary = (FactionData.SEVEN_DEADLY_SINS \
			if setup["field"] == "selected_sin" else FactionData.LEADER_CHOICES)
		faction_choice_overlay.show_prompt(func(choice_id: StringName):
			if choice_id == &"":
				# İptal — faksiyon seçim panelini tekrar aç
				_update_hud_visibility()
				return
			faction.set(setup["field"], choice_id)
			GameLogger.log_info("[%s] Seçim: %s" % [setup["log_tag"],
				LocalizationManager.tr_t(choices[choice_id]["display_name"])], "GAME")
			_confirm_faction_selection(faction)
		, choices, setup["desc_field"], setup["title_key"], setup["desc_key"])
		return
	_confirm_faction_selection(faction)

## Faksiyon seçimini sunucuya bildirir ve deploy panelini hazırlar (kurulum seçimi varsa
## ondan SONRA, yoksa doğrudan çağrılır — iki yolun ortak sonu).
func _confirm_faction_selection(faction: Resource) -> void:
	var game_node = get_tree().current_scene
	if game_node and game_node.has_method("request_select_faction"):
		game_node.request_select_faction(faction.faction_id)
	if faction.available_units.size() > 0:
		GameState.selected_deploy_unit_type = faction.available_units[0].resource_path
	_update_deploy_panel()

var active_dice_bar: PanelContainer = null

## PERFORMANS DÜZELTMESİ (kullanıcı bildirimi: "zar atıldıktan sonra üst bar gelirken kısa bir
## takılma"): panel artık HER ATIŞTA yok edilip yeniden kurulmuyor — bir kez oluşturulur, sonraki
## atışlarda AYNI örnek yeniden kullanılır (bkz. dice_bar.gd'nin üst yorumu — DiceManager'ın zar
## havuzuyla AYNI kök nedene aynı çözüm).
func _on_show_dice_bar_ui(sorted_vals: Array, kept_count: int, keep_highest: bool, flat_modifier: int, total_result: int, roll_type: String):
	if not is_instance_valid(active_dice_bar):
		active_dice_bar = preload("res://scenes/ui/hud/dice_bar/dice_bar.tscn").instantiate()
		add_child(active_dice_bar)

	active_dice_bar.setup_dice_bar(sorted_vals, kept_count, keep_highest, flat_modifier, total_result, roll_type)

## Kullanıcı isteği (2026-07-19): "ObjectivesButton ve ResourcesButton'a basınca açılan kısım
## ekranın ortasında değil, aralarında çok kısa (bir çizgi gibi) bir boşlukla bunların SOLUNDA
## açılsın." (MenuButton/ChroniclesButton'ın kendi overlay'leri — Pause/Chronicles — ekranın
## ortasında açılması zaten doğru/istenen davranış, DOKUNULMADI.) Panel konumu top_bar.tscn'deki
## butonun O ANKİ gerçek ekran konumundan HESAPLANIYOR (statik/sabit piksel DEĞİL) — böylece
## kullanıcı butonu editörde tekrar sürüklese bile panel onu otomatik takip eder.
const _PANEL_BUTTON_GAP := 2.0

func _position_panel_left_of_button(panel: Control, btn: Control) -> void:
	if not is_instance_valid(panel) or not is_instance_valid(btn):
		return
	var btn_rect: Rect2 = btn.get_global_rect()
	panel.position = Vector2(btn_rect.position.x - _PANEL_BUTTON_GAP - panel.size.x, btn_rect.position.y)

## Açılır paneller (Hedefler, Kaynaklar, Savaş Günlüğü — "hud_drawer" grubu) aynı yerde açılır, birbirini DIŞLAR.
func _on_objectives_toggle_pressed(): _toggle_drawer(objectives_panel, top_bar.objectives_btn)
func _on_resources_toggle_pressed(): _toggle_drawer(resources_panel, top_bar.resources_btn)
func _on_log_toggle_pressed(): _toggle_drawer(%BattleLog, top_bar.log_btn)

func _toggle_drawer(panel: Control, button: Control) -> void:
	var open_now: bool = not panel.visible
	for d in get_tree().get_nodes_in_group("hud_drawer"):
		d.visible = false
	if open_now:
		_position_panel_left_of_button(panel, button)
		panel.visible = true

## Eylem/yetenek butonu açıklaması — birim kartıyla AYNI popup'ın farklı bir "şekli".
## (Eskiden bu iş ayrı bir `HUDTooltipPopup` sahnesindeydi; gecikme ve konum kuralları orada
## bağımsızca yazılmıştı ve düzeltmeler senkron kalmıyordu.)
func show_tooltip(target_control: Control, key: String) -> void:
	_show_info_popup(target_control, InfoSpec.for_action(key))

func show_info(target_control: Control, spec: Dictionary) -> void: _show_info_popup(target_control, spec)

func hide_tooltip() -> void:
	_maybe_hide_hover_card()

## Eylem reddi (anahtar) / kural motorunun hazır metni → sağ üstteki bildirim akışı (NoticeFeed).
func _on_action_rejected(reason_key: String) -> void:
	notice_feed.post_key(reason_key)

func _on_notice(text: String, kind: String, title: String) -> void:
	notice_feed.post(text, kind, title)
