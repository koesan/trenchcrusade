## UnitModelLoader
## Birimin 3D model yükleme ve ölçeklendirme/normalizasyon işlemlerini yöneten alt sınıf.
class_name UnitModelLoader
extends RefCounted

var unit: CharacterBody3D

func _init(p_unit: CharacterBody3D):
	unit = p_unit

func load_model():
	if is_instance_valid(unit.model_node):
		unit.model_node.queue_free()
	
	if unit.unit_data == null or unit.unit_data.model_scene_path == "":
		return
		
	var model_path = unit.unit_data.model_scene_path
	
	# Check shared cache from UIPreviewHelper first to avoid synchronous disk loads
	var model_scene = null
	if UIPreviewHelper.model_cache.has(model_path):
		model_scene = UIPreviewHelper.model_cache[model_path]
		
	if not model_scene:
		if ResourceLoader.exists(model_path):
			model_scene = load(model_path)
			if model_scene:
				UIPreviewHelper.model_cache[model_path] = model_scene
				
	if model_scene:
		unit.model_node = model_scene.instantiate()
		unit.add_child(unit.model_node)
		_normalize_model_scale_and_position(unit.model_node, 2.0)

const BASE_RAW_MIN_Y: float = -0.362545
const BASE_RAW_MAX_Y: float = 0.314408
const BASE_RAW_XZ: float = 1.958358

func _normalize_model_scale_and_position(model_root: Node3D, target_height: float = 2.0):
	var aabb = _calculate_recursive_aabb(model_root, model_root)
	var base_top_y: float = 0.28
	
	if aabb.size.y > 0.001:
		var scale_factor = target_height / aabb.size.y
		model_root.scale = Vector3.ONE * scale_factor
		var bottom_y = aabb.position.y * scale_factor
		var model_width = max(aabb.size.x, aabb.size.z) * scale_factor
		
		# Kaide genişliğini modelin boyutuna göre dinamik ölçekle
		var base_diameter = clampf(model_width * 0.75, 0.8, 1.6)
		base_top_y = update_base_for_unit(base_diameter)
		
		# Modelin ayaklarını tam olarak kaidenin üst yüzeyine yerleştir
		model_root.position = Vector3(0, -bottom_y + base_top_y, 0)
	else:
		model_root.scale = Vector3.ONE
		base_top_y = update_base_for_unit(0.9)
		model_root.position = Vector3(0, base_top_y, 0)
		
	# Modellerin varsayılan olarak arkası dönük gelmesini engellemek için 180 derece döndür
	model_root.rotation.y = PI

func update_base_for_unit(base_diameter: float) -> float:
	var base_scale = base_diameter / BASE_RAW_XZ
	var base_pos_y = -BASE_RAW_MIN_Y * base_scale
	var base_top_y = BASE_RAW_MAX_Y * base_scale + base_pos_y
	
	if is_instance_valid(unit.mesh_instance):
		unit.mesh_instance.scale = Vector3(base_scale, base_scale, base_scale)
		unit.mesh_instance.position = Vector3(0, base_pos_y, 0)
		
	# Takım halkası: iç yarıçapı kaidenin biraz dışında (shader RING_INNER=0.5 → ölçek ≈ çap).
	var team_ring: Node3D = unit.get_node_or_null("TeamRing")
	if team_ring != null:
		var r := base_diameter * 1.08
		team_ring.scale = Vector3(r, 1.0, r)

	if is_instance_valid(unit.selection_ring):
		unit.selection_ring.position = Vector3(0, base_top_y, 0)
		var ring_scale = base_diameter / 1.5
		unit.selection_ring.scale = Vector3(ring_scale, 1.0, ring_scale)
		
	return base_top_y

func _calculate_recursive_aabb(node: Node, model_root: Node3D) -> AABB:
	var aabb = AABB()
	var found = false
	
	if node is MeshInstance3D and node.mesh:
		var local_aabb = node.mesh.get_aabb()
		var relative_transform = _get_relative_transform(node, model_root)
		aabb = relative_transform * local_aabb
		found = true
		
	for child in node.get_children():
		var child_aabb = _calculate_recursive_aabb(child, model_root)
		if child_aabb.size.length_squared() > 0.001:
			if not found:
				aabb = child_aabb
				found = true
			else:
				aabb = aabb.merge(child_aabb)
				
	return aabb

func _get_relative_transform(node: Node, ancestor: Node) -> Transform3D:
	var t = Transform3D.IDENTITY
	var curr = node
	while curr != ancestor and curr != null:
		if curr is Node3D:
			t = curr.transform * t
		curr = curr.get_parent()
	return t
