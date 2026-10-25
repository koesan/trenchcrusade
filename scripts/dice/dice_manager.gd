extends Node

## Zar yöneticisi. Zarları OBJE HAVUZU ile yönetir: her atışta yeni zar instantiate ETMEZ
## (eski davranış her atışta GLB sahnesini instantiate edip stutter'a yol açıyordu). Bunun yerine
## zarlar bir kez oluşturulur, sahnede tutulur ve her atışta yeniden fırlatılır. Görsel akış aynıdır.
## Güvenilirlik: bir watchdog, animasyon takılsa bile sonucun daima yayılmasını (akışın asılmamasını)
## garanti eder; çift-tamamlama koruması vardır.

signal dice_roll_started(num_dice: int)
## roll_id sonda eklendi (mevcut d6_res[0]/[1] kullanan çağrı yerlerini bozmamak için) — örtüşen
## iki atış (ör. bir yeteneğin d6'sı + eşzamanlı bir Success Roll) DiceRoller.perform_trench_roll'un
## yanlış atışın sonucunu almasını önler (bkz. dice_roller.gd expected_roll_id filtresi).
signal dice_roll_completed(total_value: int, individual_values: Array, roll_id: int)
signal show_dice_bar_ui(sorted_vals: Array, kept_count: int, keep_highest: bool, flat_modifier: int, total_result: int, roll_type: String)

var dice_scene = preload("res://scenes/dice/dice.tscn")

## Yeniden kullanılan zar havuzu (aktif sahnede tutulur, atışlar arası gizlenir).
var _pool: Array = []
## Bu atışta kullanılan zarlar (havuzun ilk N'i).
var active_dice: Array = []
var stopped_dice_count: int = 0
var rolled_values: Array = []
var current_roll_id: int = 0
var _completed_for_id: int = -1

## Zamanlama merkezi config'ten (game_config.json → timing). Buradaki sayı güvenli varsayılan.
var WATCHDOG_SECONDS: float = GameConfig.f("timing/dice_watchdog_seconds", 3.0)
var HOLD_SECONDS: float = GameConfig.f("timing/dice_hold_seconds", 4.5)

func roll_dice(num_dice: int):
	GameLogger.log_info("Zar atma isteği başlatıldı. Adet: %d" % num_dice, "DICE")
	if multiplayer.has_multiplayer_peer():
		if multiplayer.is_server():
			var values = []
			for i in range(num_dice):
				values.append(randi_range(1, 6))
			rpc("client_roll_dice", values)
	else:
		var values = []
		for i in range(num_dice):
			values.append(randi_range(1, 6))
		roll_dice_with_values(values)

@rpc("authority", "call_local", "reliable")
func client_roll_dice(values: Array):
	roll_dice_with_values(values)

## Oyun sahnesi yüklenirken (game.gd::_prewarm_shaders ile aynı adımda) çağrılır: havuzu
## PRATİKTE karşılaşılabilecek en yüksek zar sayısına kadar önceden doldurur. Bunsuz, havuz
## yalnız GEREKTİĞİNDE (ilk 3D6/4D6 Bloodbath, ilk Overwhelming Horde yığılması vb.) büyür —
## her büyüme anı GLB sahnesi instantiate+add_child maliyeti yüzünden kısa bir donma (hitch)
## yaratır ("bir anda donuyor sonra devam ediyor" — kullanıcı bildirimi). Tek seferlik ön-ısınma
## bu donmaları oyunun ortasından oyun başlangıcına (yükleme ekranına) taşır.
const PREWARM_POOL_SIZE: int = 10
func prewarm_pool(scene: Node) -> void:
	_ensure_pool(PREWARM_POOL_SIZE, scene)
	for d in _pool:
		if is_instance_valid(d) and d.has_method("park"):
			d.park()

## Havuzun en az n geçerli (aktif sahnede) zar içermesini sağlar; eksikse oluşturur.
func _ensure_pool(n: int, scene: Node) -> void:
	# Geçersiz veya farklı sahnedeki (sahne değişmiş) zarları at
	var valid: Array = []
	for d in _pool:
		if is_instance_valid(d) and d.get_parent() == scene:
			valid.append(d)
	_pool = valid
	while _pool.size() < n:
		var d = dice_scene.instantiate()
		scene.add_child(d)
		if d.has_method("park"):
			d.park()
		_pool.append(d)

func roll_dice_with_values(values: Array):
	var current_scene = get_tree().current_scene
	if not is_instance_valid(current_scene):
		return

	# NADIR YARIŞ DURUMU: bir üst katman öncekini beklemeden ikinci bir atış tetiklerse (ör. iki
	# yetenek/aksiyonun üst üste bindiği bir çağrı sırası), önceki atış henüz tamamlanmamış
	# olabilir. Aşağıdaki "havuzu beklemeye al" adımı o zarları animasyon YARIDAYKEN
	# görünmez yapar ("zar düşüyor, bir anda kayboluyor" bildirimi) VE watchdog artık
	# current_roll_id ilerlediği için o atışı asla tamamlamaz (roll_id != current_roll_id → no-op) —
	# bu da onu bekleyen çağıranın (varsa roll_id filtresi yoksa) YANLIŞ bir sonraki atışın
	# sonucunu almasına ya da sonsuza dek asılı kalmasına yol açar. Bunu önlemek için önceki atış
	# ZORLA (o zar için zaten planlanmış target_value'larla) tamamlanır — atış vazgeçilmiş sayılmaz.
	if current_roll_id > 0 and _completed_for_id != current_roll_id and stopped_dice_count < active_dice.size():
		var pending_values: Array = []
		for d in active_dice:
			if is_instance_valid(d) and "target_value" in d:
				pending_values.append(d.target_value)
		if pending_values.size() > 0:
			GameLogger.log_warn(
				"[DICE] Yeni bir atış öncekini (henüz animasyonu bitmemiş) kesti — önceki atış zorla tamamlanıyor.",
				"DICE")
			_complete_roll(current_roll_id, pending_values)

	current_roll_id += 1
	var this_roll_id = current_roll_id

	# Önceki atışın zarlarını beklemeye al (gizle) — instantiate/free yok
	for d in _pool:
		if is_instance_valid(d) and d.has_method("park"):
			d.park()

	stopped_dice_count = 0
	rolled_values.clear()
	active_dice.clear()

	var num_dice = values.size()
	dice_roll_started.emit(num_dice)

	# Çakışmasız iniş koordinatları (harita merkezi etrafında)
	var target_center = Vector3(0, 0.15, 0)
	var land_positions = []
	var radius = 0.4 + 0.12 * num_dice
	for i in range(num_dice):
		var angle = i * (TAU / num_dice)
		land_positions.append(target_center + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius))

	_ensure_pool(num_dice, current_scene)

	for i in range(num_dice):
		var dice = _pool[i]
		dice.target_value = values[i]
		dice.has_target_value = true
		dice.dice_index = i
		dice.total_dice = num_dice
		if "target_land_position" in dice:
			dice.target_land_position = land_positions[i]
		# Eski bağlantıları temizle, tek seferlik yeni bağlantı kur
		for conn in dice.stopped.get_connections():
			dice.stopped.disconnect(conn.callable)
		dice.stopped.connect(func(val): _on_dice_stopped(dice, val, num_dice, this_roll_id), CONNECT_ONE_SHOT)
		active_dice.append(dice)
		dice.throw()

	_run_watchdog(this_roll_id, num_dice, values.duplicate())

## Güvenilirlik ağı: animasyon takılırsa sonucu zorla yayınlar (akış asla asılmaz).
func _run_watchdog(roll_id: int, num_dice: int, values: Array) -> void:
	await get_tree().create_timer(WATCHDOG_SECONDS).timeout
	if roll_id != current_roll_id:
		return
	if stopped_dice_count < num_dice and _completed_for_id != roll_id:
		GameLogger.log_warn("[DICE] Watchdog: zarlar zamanında durmadı, sonuç zorla yayınlanıyor.", "DICE")
		_complete_roll(roll_id, values)

func _on_dice_stopped(dice, value: int, total_dice: int, roll_id: int):
	if roll_id != current_roll_id:
		return
	rolled_values.append(value)
	stopped_dice_count += 1
	if stopped_dice_count == total_dice:
		_complete_roll(roll_id, rolled_values.duplicate())

## Sonucu tek sefer yayınlar (çift-tamamlama korumalı), sonra zarları beklemede tutup soldurur.
func _complete_roll(roll_id: int, values: Array) -> void:
	if roll_id != current_roll_id or _completed_for_id == roll_id:
		return
	_completed_for_id = roll_id
	var total = 0
	for v in values:
		total += v
	GameLogger.log_info("Tüm zarlar durdu. Sonuç Değerleri: %s (Toplam: %d)" % [str(values), total], "DICE")
	dice_roll_completed.emit(total, values.duplicate(), roll_id)

	await get_tree().create_timer(HOLD_SECONDS).timeout
	if roll_id == current_roll_id:
		_fade_and_park()

func clear_dice():
	for d in _pool:
		if is_instance_valid(d) and d.has_method("park"):
			d.park()
	active_dice.clear()
	stopped_dice_count = 0
	rolled_values.clear()

func _fade_and_park():
	var dice_to_clear = active_dice.duplicate()
	active_dice.clear()
	for d in dice_to_clear:
		if is_instance_valid(d):
			var tween = d.create_tween()
			tween.tween_property(d, "scale", Vector3.ZERO, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			tween.tween_callback(func():
				if is_instance_valid(d) and d.has_method("park"):
					d.park())
