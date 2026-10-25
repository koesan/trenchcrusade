extends MeshInstance3D

## Taktiksel menzil (saldırı/etki alanı) daire görselleştiricisi.
## Engelleri hesaba katmadan birimin etrafında tam bir çember çizer ve içini doldurur.
## Faksiyona göre renk değiştirir ve alanı doldurarak yüksek görünürlük sağlar.

@export var num_segments: int = 48
@export var vertical_offset: float = 0.04

var mesh_im: ImmediateMesh
var material_perimeter: StandardMaterial3D
var material_fill: StandardMaterial3D

var is_active: bool = false
var current_unit = null
var range_radius: float = 1.0

func _ready():
	# Top level yapıyoruz ki ünitenin rotasyon ve scale değişimlerinden bağımsız global koordinatları kullanabilelim
	top_level = true
	mesh_im = ImmediateMesh.new()
	mesh = mesh_im
	
	material_perimeter = StandardMaterial3D.new()
	material_perimeter.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material_perimeter.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	material_perimeter.no_depth_test = false
	
	material_fill = StandardMaterial3D.new()
	material_fill.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material_fill.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	material_fill.cull_mode = StandardMaterial3D.CULL_DISABLED
	material_fill.no_depth_test = false

func hide_visuals():
	is_active = false
	visible = false
	if mesh_im:
		mesh_im.clear_surfaces()

func show_visuals(unit_node, p_radius: float):
	current_unit = unit_node
	range_radius = p_radius
	is_active = true
	visible = true
	if is_instance_valid(current_unit):
		global_position = current_unit.global_position
	
	_update_colors()
	update_visuals()

func _process(_delta):
	if is_active and is_instance_valid(current_unit):
		global_position = current_unit.global_position

func _update_colors():
	var colors = GameVisualColors.get_colors()
	var color_to_use = colors.circle_default
			
	# Çevre sınırı (biraz daha belirgin)
	material_perimeter.albedo_color = Color(color_to_use.r, color_to_use.g, color_to_use.b, 0.45)
	# Dolgu alanı (hafif saydam ve açık renk)
	material_fill.albedo_color = Color(color_to_use.r, color_to_use.g, color_to_use.b, 0.12)

func update_visuals():
	if not is_active or not is_instance_valid(current_unit) or not current_unit.is_inside_tree():
		return
		
	mesh_im.clear_surfaces()
	
	var points = PackedVector3Array()
	for i in range(num_segments):
		var angle = (float(i) / num_segments) * TAU
		var dir = Vector3(cos(angle), 0, sin(angle))
		var pt = dir * range_radius
		pt.y = 0.0
		points.append(pt)
		
	# 1. Dolgu alanını (Filled Polygon) çiz
	if points.size() > 2:
		mesh_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material_fill)
		var center_pt = Vector3(0, vertical_offset, 0)
		for i in range(points.size()):
			var p1 = points[i] + Vector3(0, vertical_offset, 0)
			var p2 = points[(i + 1) % points.size()] + Vector3(0, vertical_offset, 0)
			mesh_im.surface_add_vertex(center_pt)
			mesh_im.surface_add_vertex(p1)
			mesh_im.surface_add_vertex(p2)
		mesh_im.surface_end()
		
		# 2. Dış sınırı (Perimeter Line Strip) çiz
		mesh_im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material_perimeter)
		for pt in points:
			mesh_im.surface_add_vertex(pt + Vector3(0, vertical_offset, 0))
		mesh_im.surface_add_vertex(points[0] + Vector3(0, vertical_offset, 0))
		mesh_im.surface_end()
