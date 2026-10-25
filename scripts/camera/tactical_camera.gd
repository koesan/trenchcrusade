extends Node3D

## Taktiksel masa oyunu kamerası.
## Gimbal sistemi ile yatay orbit, dikey tilt ve yumuşak zoom sağlar.
## Kamera kontrolleri Input Map üzerinden tanımlanır (project.godot → [input]).

@export var move_speed: float = 45.0
@export var rotate_speed: float = 0.005
@export var zoom_speed: float = 2.5
@export var min_zoom: float = 1.0
@export var max_zoom: float = 50.0

var _gimbal_h: Node3D
var _gimbal_v: Node3D
var _camera: Camera3D

var _target_zoom: float = 20.0
var _current_zoom: float = 20.0

## Q/E ile dönüş hızı (radyan/sn).
@export var key_rotate_speed: float = 1.8
## Kamera pivotu savaş alanı sınırlarının bu kadar dışına çıkabilir (inç). Eskiden sınır yoktu;
## WASD ile harita tamamen ekrandan kaçırılabiliyordu.
@export var bounds_margin: float = 6.0
## Arazi parçası kamerayla pivot arasına girerse kamera bu kadar önüne çekilir.
const OCCLUSION_PADDING := 0.6
## F: seçili birime yumuşak kayış. Hedef yoksa NAN.
var _focus_target: Vector3 = Vector3(NAN, NAN, NAN)
const FOCUS_LERP := 8.0

func _ready():
	# Eğer alt düğümler sahne ağacında oluşturulmamışsa dinamik olarak oluşturuyoruz
	if get_child_count() == 0:
		_gimbal_h = Node3D.new()
		_gimbal_h.name = "GimbalH"
		add_child(_gimbal_h)
		
		_gimbal_v = Node3D.new()
		_gimbal_v.name = "GimbalV"
		_gimbal_h.add_child(_gimbal_v)
		# Taktiksel masaüstü oyun açısı (45 derece eğik)
		_gimbal_v.rotation.x = deg_to_rad(-45.0)
		
		_camera = Camera3D.new()
		_camera.name = "Camera3D"
		_gimbal_v.add_child(_camera)
		_camera.position.z = _target_zoom
	else:
		_gimbal_h = get_child(0)
		_gimbal_v = _gimbal_h.get_child(0)
		_camera = _gimbal_v.get_child(0)
		_target_zoom = _camera.position.z

func _unhandled_input(event):
	# F: seçili birime odaklan (oyuncu birimini haritada kaybettiğinde)
	if event.is_action_pressed("camera_focus") and is_instance_valid(GameState.selected_unit):
		focus_on(GameState.selected_unit.global_position)

	# Fare tekerleği ile yakınlaşma/uzaklaşma
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_target_zoom = clamp(_target_zoom - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_target_zoom = clamp(_target_zoom + zoom_speed, min_zoom, max_zoom)

	# Fare orta tuşu veya sağ tuşu ile sürüklerken kamerayı döndürme
	if event is InputEventMouseMotion:
		var is_rotating = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)
		if is_rotating:
			_gimbal_h.rotate_y(-event.relative.x * rotate_speed)
			_gimbal_v.rotate_x(-event.relative.y * rotate_speed)
			# Kamera açısını yerin altına veya tepe taklak olmasını engellemek için sınırla
			_gimbal_v.rotation.x = clamp(_gimbal_v.rotation.x, deg_to_rad(-85.0), deg_to_rad(-5.0))

func _process(delta):
	# Input Map action'ları ile kamerayı kaydırma (WASD + yön tuşları)
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("camera_right"):
		input_dir.x += 1
	if Input.is_action_pressed("camera_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("camera_back"):
		input_dir.z += 1
	if Input.is_action_pressed("camera_forward"):
		input_dir.z -= 1

	input_dir = input_dir.normalized()

	# Hareket yönünü kameranın baktığı yöne göre hesapla
	var camera_forward = -_gimbal_h.global_transform.basis.z
	var camera_right = _gimbal_h.global_transform.basis.x
	
	# Yalnızca yatay düzlemde (XZ) hareket etmek için Y bileşenini sıfırla
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	camera_right.y = 0.0
	camera_right = camera_right.normalized()

	var current_speed = move_speed * clamp(_current_zoom / 20.0, 0.4, 2.5)
	var move_vector = (camera_forward * -input_dir.z + camera_right * input_dir.x)
	if move_vector != Vector3.ZERO:
		_focus_target = Vector3(NAN, NAN, NAN)   # elle kaydırma odak kayışını iptal eder
	global_translate(move_vector * current_speed * delta)

	# Q/E: yatay dönüş (sağ tık sürüklemeye klavye alternatifi)
	var rot := Input.get_action_strength("camera_rotate_right") - Input.get_action_strength("camera_rotate_left")
	if rot != 0.0:
		_gimbal_h.rotate_y(-rot * key_rotate_speed * delta)

	if not is_nan(_focus_target.x):
		global_position = global_position.lerp(_focus_target, clampf(FOCUS_LERP * delta, 0.0, 1.0))
		if global_position.distance_to(_focus_target) < 0.05:
			_focus_target = Vector3(NAN, NAN, NAN)

	_clamp_to_battlefield()

	# Yumuşak yakınlaşma geçişi
	_current_zoom = lerp(_current_zoom, _target_zoom, 10.0 * delta)
	_camera.position.z = _occlusion_safe_distance(_current_zoom)

## Pivotu savaş alanının yatay sınırları (+ pay) içinde tutar. Sınırlar NavMesh pişince
## GameState.battlefield_bounds'a yazılır; o ana kadar (boş AABB) kısıt uygulanmaz.
func _clamp_to_battlefield() -> void:
	var b: AABB = GameState.battlefield_bounds
	if b.size.x <= 0.0 or b.size.z <= 0.0:
		return
	var p := global_position
	p.x = clampf(p.x, b.position.x - bounds_margin, b.end.x + bounds_margin)
	p.z = clampf(p.z, b.position.z - bounds_margin, b.end.z + bounds_margin)
	global_position = p

## Pivot ile kamera arasında ARAZİ (StaticBody) varsa kamerayı engelin önüne çeker —
## yakınlaşınca kameranın bir binanın/duvarın içine girip ekranı kaplaması bunu önler.
## Birimler (CharacterBody) engel sayılmaz.
func _occlusion_safe_distance(desired: float) -> float:
	if not is_inside_tree():
		return desired
	var space := get_world_3d().direct_space_state
	if space == null:
		return desired
	var from: Vector3 = _gimbal_v.global_position
	var dir: Vector3 = _gimbal_v.global_transform.basis.z.normalized()
	var to: Vector3 = from + dir * desired
	var q := PhysicsRayQueryParameters3D.create(from, to)
	var excluded: Array[RID] = []
	for _i in 4:
		q.exclude = excluded
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return desired
		if hit.collider is StaticBody3D:
			return maxf(min_zoom, from.distance_to(hit.position) - OCCLUSION_PADDING)
		excluded.append(hit.rid)
	return desired

## Kamera pivotunu yumuşakça bir noktaya kaydırır (yükseklik de hedefe uyar).
func focus_on(world_pos: Vector3) -> void:
	_focus_target = world_pos

func get_camera_3d() -> Camera3D:
	return _camera
