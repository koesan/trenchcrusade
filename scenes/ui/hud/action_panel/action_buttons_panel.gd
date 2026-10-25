extends HFlowContainer
class_name ActionButtonsPanel

## Seçili birimin yapabileceği eylemleri (yürüyüş, hücum, yetenekler, silahlar) ikonlu butonlar
## olarak üreten bileşen — komuta panelinin (command_bar.tscn) eylem bölümü.
## HANGİ eylemin uygun olduğu kararı birim/kural motorundadır (can_perform_action,
## can_use_attack); bu sınıf yalnız SUNAR.
##
## YERLEŞİM: yatay akış; sığmayan butonlar ikinci satıra geçer (eski dikey liste + kaydırma
## çubuğu yerine). Butonlar 1-9 kısayol tuşuyla numaralanır (press_hotkey).

signal action_selected(action_key: String)
signal attack_selected(attack_index: int)

const HUD_ACTION_BUTTON_SCENE = preload("res://scenes/ui/hud/action_panel/hud_action_button.tscn")

## Butonların kabı — panelin kendisi (HFlowContainer).
@onready var buttons: HFlowContainer = self
## Sıradaki butona verilecek kısayol numarası (her rebuild'de 1'den başlar).
var _next_hotkey := 1

func rebuild(unit) -> void:
	# HUD üzerindeki tooltip'i kapat
	var hud = _get_hud()
	if hud:
		hud.hide_tooltip()
		
	# Eski butonları temizle
	_next_hotkey = 1
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
		
	# Geçersiz birim veya ölü durumunda gizle
	if not is_instance_valid(unit) or unit.current_health <= 0:
		visible = false
		return
		
	var is_my_turn_unit = unit.owner_id == TurnManager.current_turn_player_id
	var is_local_valid = not multiplayer or not multiplayer.has_multiplayer_peer() or unit.owner_id == NetworkManager.get_local_canonical_id()

	if is_my_turn_unit and is_local_valid and not unit.has_moved:
		visible = true

		# Buton ekleme yardımcı lambda fonksiyonu
		var add_action_btn = func(text_key: String, is_highlighted: bool, pressed_cb: Callable,
				icon_name: String = "", spec: Dictionary = {}) -> void:
			var btn = HUD_ACTION_BUTTON_SCENE.instantiate()
			buttons.add_child(btn)
			btn.setup_action(LocalizationManager.tr_t(text_key), is_highlighted, pressed_cb, text_key,
				icon_name, _take_hotkey())
			btn.tooltip_spec = spec

		# DEVOUR THE GUILTY (Sin Eater, P1-1): yutulmuş bir model "cannot... carry out any
		# Actions except" Sin Eater'a saldırmak — TEK buton, diğer HİÇBİRİ (Move/Charge/Fight/
		# yetenek) üretilmez.
		if unit.devoured_by != null:
			if unit.can_perform_action("fight_devourer"):
				add_action_btn.call(
					"ACTION_FIGHT_DEVOURER",
					false,
					func():
						unit.request_fight_devourer_action()
						rebuild(unit)
				)
			return

		# 1. HAREKET BUTONU (MARCH)
		if unit.can_perform_action("move") or unit.is_dash_pending:
			add_action_btn.call(
				"ACTION_MARCH", 
				GameState.selected_action == "move" or unit.is_dash_pending,
				func():
					GameState.selected_action = "move"
					rebuild(unit)
					action_selected.emit("move")
			)
			
		# 2. HÜCUM (CHARGE) BUTONU
		if unit.can_perform_action("charge"):
			add_action_btn.call(
				"ACTION_ONSLAUGHT_CHARGE",
				GameState.selected_action == "charge",
				func():
					GameState.selected_action = "charge"
					rebuild(unit)
					action_selected.emit("charge")
			)
			
		# 3. GERİ ÇEKİL (RETREAT) BUTONU
		if unit.can_perform_action("retreat"):
			add_action_btn.call(
				"ACTION_RETREAT",
				GameState.selected_action == "retreat",
				func():
					GameState.selected_action = "retreat"
					rebuild(unit)
					action_selected.emit("retreat")
			)
			
		# 4. HIZLI KOŞ (DASH) BUTONU
		if unit.can_perform_action("dash"):
			add_action_btn.call(
				"ACTION_HASTE_RISKY",
				false,
				func():
					unit.request_dash_action()
					rebuild(unit)
					action_selected.emit("dash")
			)
			
		# CLAIM RELIQUARY (Relic Hunt senaryosu) — birim-özel bir yetenek DEĞİL, aktif senaryoya
		# bağlı evrensel bir eylem; bu yüzden temel eylemlerle (Move/Charge/Retreat/Dash) aynı
		# hardcoded desende, abilities[] döngüsünden ÖNCE üretilir.
		if unit.can_perform_action("claim_reliquary"):
			add_action_btn.call(
				"ACTION_CLAIM_RELIQUARY",
				false,
				func():
					unit.request_claim_reliquary_action()
					rebuild(unit)
			)

		# NOT: "Nişan Al (Aim)" butonu kaldırıldı — TC'de Aim ortak eylemi yoktur.
		# Faksiyona/Birime Özel Yetenekler (Data-Driven)
		if unit.unit_data and unit.unit_data.abilities:
			for ability_res in unit.unit_data.abilities:
				var ab: AbilityData = ability_res as AbilityData
				# TEK kaynak filtre (has_any_remaining_action ile aynı): pasif/temel-çakışan/
				# uygulanmamış custom yetenekler buton üretmez (yanıltıcı ölü buton olmasın).
				if not AbilityExecutor.is_actionable_ability(ab):
					continue
				if unit.can_perform_action(ab.action_key):
					var text_key = "ACTION_" + ab.action_key.to_upper()
					var action_key = ab.action_key
					
					var ab_icon := icon_for_ability(ab)
					var ab_spec := InfoSpec.for_ability(ab)
					if ab.target_type == "none" or ab.target_type == "self":
						add_action_btn.call(
							text_key,
							false,
							func():
								unit.request_ability_action(action_key)
								rebuild(unit)
								action_selected.emit(action_key),
							ab_icon, ab_spec
						)
					else:
						add_action_btn.call(
							text_key,
							GameState.selected_action == action_key,
							func():
								GameState.selected_action = action_key
								rebuild(unit)
								action_selected.emit(action_key),
							ab_icon, ab_spec
						)

		# 7. SALDIRI / SİLAH BUTONLARI
		if unit.unit_data and unit.unit_data.attacks.size() > 0:
			# Aynı isme sahip saldırıları numaralandır (ör. Amalgam: 3× Legionary Dagger)
			var _atk_name_count: Dictionary = {}
			for _a in unit.unit_data.attacks:
				var _n = _a.attack_name if _a != null else ""
				_atk_name_count[_n] = _atk_name_count.get(_n, 0) + 1
			var _atk_name_seen: Dictionary = {}

			for i in range(unit.unit_data.attacks.size()):
				var atk = unit.unit_data.attacks[i]
				# can_use_attack: angaje/tekrar + Assault etkileşim kuralı (hücum sonrası Fight
				# her zaman serbest; Shoot yalnız Assault) — sunucu ile tek ortak kaynak.
				var can_atk = unit.can_use_attack(atk)

				if can_atk:
					var l_name = LocalizationManager.tr_t(atk.attack_name)
					# Aynı isimdeki saldırılara numara ekle
					var an = atk.attack_name
					_atk_name_seen[an] = _atk_name_seen.get(an, 0) + 1
					if _atk_name_count.get(an, 1) > 1:
						l_name = "%s #%d" % [l_name, _atk_name_seen[an]]
					# Masa oyunu dili: menzil inç (") ile; yakın dövüş silahında menzil sayısı anlamsız.
					# Butonda yalnız silahın adı — menzil bilgi kartında ve hedef yönergesinde
					# ("Menzildeki bir düşmana tıkla (24")"). Dar butonda "Ad · 24"" üç satıra kırılıyordu.
					var btn_text: String = l_name
						
					var idx = i
					var is_highlighted = GameState.selected_action == "attack" and idx == unit.selected_attack_index
					
					var btn = HUD_ACTION_BUTTON_SCENE.instantiate()
					buttons.add_child(btn)
					btn.setup_action(btn_text, is_highlighted, func():
						unit.selected_attack_index = idx
						GameState.selected_action = "attack"
						rebuild(unit)
						GameState.update_all_unit_indicators()
						attack_selected.emit(idx)
					, atk.attack_name, "melee" if atk.attack_type == "MELEE" else "shoot", _take_hotkey())
	else:
		visible = false

## Yeteneğin ikonu VERİSİNDEN seçilir (hedef türü + etki) — 100 yeteneğe tek tek ikon atamak
## yerine anlamı okunur bir sınıflama: oyuncu butona bakınca kime/neye yöneldiğini anlar.
static func icon_for_ability(ab: AbilityData) -> String:
	match ab.effect_type:
		"blessing", "remove_blood", "stand_up", "treat_choice":
			return "blessing"
		"add_blood", "add_infection", "force_activation", "force_move":
			return "curse"
		"teleport":
			return "teleport"
		"move_allies":
			return "rally"
		"set_flag":
			return "armour"
	match ab.target_type:
		"enemy":
			return "curse"
		"friendly":
			return "blessing"
		"position":
			return "teleport"
	return "ability"

## 1-9 kısayolu: sıradaki butonun numarası (9'dan sonrası numarasız).
func _take_hotkey() -> int:
	var n := _next_hotkey
	_next_hotkey += 1
	return n if n <= 9 else 0

## Klavye kısayolu: n. eylem butonuna basar. Basıldıysa true.
func press_hotkey(n: int) -> bool:
	if not visible:
		return false
	var i := 0
	for c in buttons.get_children():
		if c is HUDActionButton:
			i += 1
			if i == n and not c.disabled:
				c.emit_signal("pressed")
				return true
	return false

func clear() -> void:
	var hud = _get_hud()
	if hud:
		hud.hide_tooltip()
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	visible = false

func _get_hud() -> Node:
	var p = get_parent()
	while p:
		if p.has_method("show_tooltip"):
			return p
		p = p.get_parent()
	return null
