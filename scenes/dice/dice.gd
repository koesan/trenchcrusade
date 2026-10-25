extends Node3D

signal stopped(value: int)

@export var value_up: int = 1
@export var value_down: int = 6
@export var value_right: int = 4
@export var value_left: int = 3
@export var value_back: int = 2
@export var value_forward: int = 5

var target_value: int = 1
var has_target_value: bool = false
var random_y_angle: float = 0.0
var dice_index: int = 0
var total_dice: int = 1
var target_land_position: Vector3 = Vector3.ZERO

var mesh_node: MeshInstance3D = null
var _initial_basis: Basis
var _target_basis: Basis
var _tweens: Array = []
var _throw_id: int = 0

func _ready():
	# Sadece mesh referansını al — fırlatma artık throw() ile (havuzdan tekrar tekrar) yapılır.
	mesh_node = _find_mesh_instance(self)

## Havuzdan yeniden fırlatma için: durumu sıfırla ve deterministik animasyonu başlat.
## (Görsel akış eskisiyle birebir aynı; yalnızca yeniden kullanılabilir hale getirildi.)
func throw() -> void:
	_throw_id += 1
	_kill_tweens()
	scale = Vector3.ONE
	visible = true
	random_y_angle = randf() * TAU
	if mesh_node == null:
		mesh_node = _find_mesh_instance(self)
	_animate_throw()

## Zarı sahnede tutar ama gizler (havuzda beklemeye alır).
func park() -> void:
	_kill_tweens()
	visible = false

func _kill_tweens() -> void:
	for t in _tweens:
		if t != null and t.is_valid():
			t.kill()
	_tweens.clear()

func _animate_throw():
	var my_id: int = _throw_id
	# Zarların çakışmasını önlemek için önceden hesaplanmış iniş pozisyonunu kullan
	var land_pos = target_land_position
	if land_pos == Vector3.ZERO:
		var offset_angle = (dice_index * (TAU / max(1, total_dice))) + randf_range(-0.15, 0.15)
		var radius = 1.0 if total_dice > 1 else 0.0
		land_pos = Vector3(
			cos(offset_angle) * radius + randf_range(-0.2, 0.2),
			0.25,
			sin(offset_angle) * radius + randf_range(-0.2, 0.2)
		)

	var start_pos = Vector3(
		land_pos.x + randf_range(-0.4, 0.4),
		land_pos.y + randf_range(2.5, 3.5),
		land_pos.z + randf_range(-0.4, 0.4)
	)

	global_position = start_pos

	var start_rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
	global_transform.basis = Basis.from_euler(start_rotation)

	_initial_basis = global_transform.basis
	_target_basis = _get_basis_for_value(target_value)

	var pos_tween = create_tween()
	pos_tween.tween_property(self, "global_position:y", land_pos.y, 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_tweens.append(pos_tween)

	var plane_tween = create_tween()
	plane_tween.set_parallel(true)
	plane_tween.tween_property(self, "global_position:x", land_pos.x, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	plane_tween.tween_property(self, "global_position:z", land_pos.z, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tweens.append(plane_tween)

	var rot_tween = create_tween()
	rot_tween.tween_method(_tween_rotation, 0.0, 1.0, 1.0)
	_tweens.append(rot_tween)

	# NOT: pos_tween'in "finished" sinyalini beklemek yerine SABİT bir zamanlayıcı kullanılıyor
	# (süre zaten aynı sabit 1.0). Havuzdan erken yeniden fırlatma (bir sonraki atış bu zarı tekrar
	# throw() ederse) ÖNCEKİ tween'leri _kill_tweens() ile kill() eder; kill() edilen bir Tween'in
	# "finished" sinyali ASLA ateşlenmez → await sonsuza dek asılı kalır, bu zar hiç "stopped" emit
	# etmez ve atış watchdog'a (zorla yayın) kalır. Sabit zamanlayıcı iptalden etkilenmediği için
	# her zaman ilerler; aşağıdaki _throw_id kontrolü zaten üstelenen (bayat) çağrıyı eler.
	await get_tree().create_timer(1.0).timeout

	# Bu fırlatma hâlâ geçerli mi? (yeniden fırlatıldıysa eski emit'i bastır)
	if my_id != _throw_id:
		return
	await get_tree().create_timer(0.15).timeout
	if my_id != _throw_id:
		return
	stopped.emit(target_value)

# Rotasyon interpolasyonu için ayrık yardımcı fonksiyon
func _tween_rotation(t: float):
	if t < 0.6:
		var spin_angle = t * 15.0
		var spin_basis = Basis(Vector3(1, 1, 0).normalized(), spin_angle)
		global_transform.basis = _initial_basis * spin_basis
	else:
		var blend = (t - 0.6) / 0.4
		var spun_basis = _initial_basis * Basis(Vector3(1, 1, 0).normalized(), 0.6 * 15.0)
		global_transform.basis = spun_basis.slerp(_target_basis, blend)

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var res = _find_mesh_instance(child)
		if res:
			return res
	return null

func _get_mesh_relative_transform() -> Transform3D:
	if is_instance_valid(mesh_node):
		return _get_relative_transform(mesh_node, self)
	return Transform3D.IDENTITY

func _get_basis_for_value(val: int) -> Basis:
	var mesh_local_up = Vector3.UP
	match val:
		1: mesh_local_up = Vector3.UP
		6: mesh_local_up = Vector3.DOWN
		4: mesh_local_up = Vector3.RIGHT
		3: mesh_local_up = Vector3.LEFT
		2: mesh_local_up = Vector3.BACK
		5: mesh_local_up = Vector3.FORWARD

	var mesh_to_body = _get_mesh_relative_transform()
	var body_local_up = (mesh_to_body.basis * mesh_local_up).normalized()

	var align_rotation = Quaternion(body_local_up, Vector3.UP)
	var target_basis = Basis(align_rotation)

	var y_rot = Basis(Vector3.UP, random_y_angle)
	return y_rot * target_basis

func _get_relative_transform(node: Node, ancestor: Node) -> Transform3D:
	var t = Transform3D.IDENTITY
	var curr = node
	while curr != ancestor and curr != null:
		if curr is Node3D:
			t = curr.transform * t
		curr = curr.get_parent()
	return t
