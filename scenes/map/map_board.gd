extends Node3D

signal collision_generation_completed

@export var map_scale: Vector3 = Vector3(50.0, 50.0, 50.0)


func _ready():
	scale = map_scale
	# Harita modeli yüklendiğinde otomatik olarak collision oluştur
	_create_collision_for_meshes(self)
	collision_generation_completed.emit()

func _create_collision_for_meshes(node: Node):
	if node is MeshInstance3D:
		var has_collision = false
		var sb: StaticBody3D = null
		for child in node.get_children():
			if child is StaticBody3D:
				has_collision = true
				sb = child
				break
		if not has_collision:
			# Godot'nun trimesh collision oluşturma fonksiyonunu çağırıyoruz
			node.create_trimesh_collision()
			for child in node.get_children():
				if child is StaticBody3D:
					sb = child
					break
					
		# Harita çarpışmalarının hem Birimler (Layer 1) hem de Zarlar (Layer 2) ile etkileşmesini sağla
		if sb:
			sb.collision_layer = 1 | 2 # Layer 1 & 2
			sb.collision_mask = 1 | 2
			
	for child in node.get_children():
		_create_collision_for_meshes(child)
