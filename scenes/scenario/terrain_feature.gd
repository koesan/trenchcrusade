extends Node3D
class_name TerrainFeature

## Sahadaki bir arazi parçasının (Mayın, Siper) 3B görsel temsili.
##
## ObjectiveMarker deseninin birebir ikizi: GLB modeli yükler, zemine oturtur ve etki
## yarıçapını saydam bir halka + dolgu ile çizer. Tüm kural mantığı DIŞARIDADIR
## (TerrainManager sorgular, MineResolver karar verir) — bu sahne yalnız GÖSTERİR.

## Bu parçanın veri tanımı (TerrainFeatureData).
var feature_data: Resource = null

## Mayını KURAN birimin node adı ("" = senaryo tarafından önceden yerleştirilmiş).
## Compendium: "A model that sets a mine can defuse it automatically" + "the mine will
## detonate unless the model is the one that set the mine".
var setter_unit_name: String = ""

## Tüketilmiş (patlamış/etkisizleştirilmiş) parçalar sorgulara dahil edilmez.
var is_active: bool = true

# ── GÖRSEL DÜĞÜMLER ─────────────────────────────────────────────────────────
var _model: Node3D
var _label: Label3D
var _ring_instance: MeshInstance3D
var _ring_mesh: ImmediateMesh
var _mat_fill: StandardMaterial3D
var _mat_ring: StandardMaterial3D

const FILL_ALPHA := 0.07
const RING_ALPHA := 0.30
const RING_SEGMENTS := 48

func setup(data: Resource, setter_name: String = "") -> void:
	feature_data = data
	setter_unit_name = setter_name
	if feature_data == null:
		return
	_build_model()
	_build_ring()
	_build_label()

func _build_model() -> void:
	var path: String = feature_data.model_path
	if path == "" or not ResourceLoader.exists(path):
		return
	var packed: Resource = load(path)
	if packed == null or not (packed is PackedScene):
		return
	_model = (packed as PackedScene).instantiate()
	add_child(_model)
	var s: float = maxf(feature_data.model_scale, 0.01)
	_model.scale = Vector3(s, s, s)
	# GLB'lerin yerel orijini merkezlerinde olabilir; sabit bir y_offset'e güvenmek modeli
	# haritanın İÇİNE gömüyordu (kullanıcı bildirimi). Gerçek sınır kutusundan tabanı
	# bulup parçayı zemine OTURTUYORUZ — hangi model gelirse gelsin doğru durur.
	var bottom: float = _lowest_point(_model)
	# `bottom * s` = ölçeklenmiş en alt nokta; bunu YUKARı kaydırarak taban zemine oturur.
	_model.position.y = feature_data.y_offset - bottom * s

## Modelin (alt düğümleri dâhil) en alçak yerel noktası. Bulunamazsa 0 döner.
## ESKİ KOD `m.transform * aabb` kullanıyordu — Transform3D * AABB, dönüştürülmüş AABB
## veriyor ama `position.y` alttaki köşe DEĞİL, yeni AABB'nin orijinini verir ve dönüşümde
## kayıp oluyor. Doğru yaklaşım: AABB'nin 8 köşesini mesh'in yerel transform'una geçirip
## minimum Y'yi bulmak.
func _lowest_point(root: Node) -> float:
	var lowest := INF
	for m in _mesh_instances(root):
		var aabb: AABB = m.get_aabb()
		if m == root:
			# Kök düğümün kendi koordinatında — doğrudan AABB min Y.
			lowest = minf(lowest, aabb.position.y)
		else:
			# Alt düğüm — tüm ara düğümlerin transform zincirini biriktir.
			var t: Transform3D = Transform3D.IDENTITY
			var current: Node = m
			while current != root and current != null:
				if current is Node3D:
					t = (current as Node3D).transform * t
				current = current.get_parent()
			for corner_idx in 8:
				var corner := Vector3(
					aabb.position.x + aabb.size.x * float(corner_idx & 1),
					aabb.position.y + aabb.size.y * float((corner_idx >> 1) & 1),
					aabb.position.z + aabb.size.z * float((corner_idx >> 2) & 1),
				)
				var world_corner: Vector3 = t * corner
				lowest = minf(lowest, world_corner.y)
	return 0.0 if is_inf(lowest) else lowest

func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		out.append(node)
	for c in node.get_children():
		out.append_array(_mesh_instances(c))
	return out

## Etki yarıçapını saydam bir daire + kenar halkası olarak çizer (ObjectiveMarker ile aynı
## görsel dil: göz yormayan düşük alfa, düzgün çember).
func _build_ring() -> void:
	_ring_mesh = ImmediateMesh.new()
	_ring_instance = MeshInstance3D.new()
	_ring_instance.mesh = _ring_mesh
	_ring_instance.position.y = 0.03
	add_child(_ring_instance)

	var col: Color = feature_data.ring_color
	_mat_fill = StandardMaterial3D.new()
	_mat_fill.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_fill.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_fill.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_fill.albedo_color = Color(col.r, col.g, col.b, FILL_ALPHA)

	_mat_ring = StandardMaterial3D.new()
	_mat_ring.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_ring.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_ring.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_ring.albedo_color = Color(col.r, col.g, col.b, RING_ALPHA)

	_redraw_ring()

func _redraw_ring() -> void:
	if _ring_mesh == null:
		return
	_ring_mesh.clear_surfaces()
	var r: float = feature_data.radius

	# Dolgu — Godot 4'te PRIMITIVE_TRIANGLE_FAN YOKTUR; ObjectiveMarker ile aynı yaklaşım:
	# merkezden dilim dilim üçgenler (PRIMITIVE_TRIANGLES).
	_ring_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _mat_fill)
	for i in range(RING_SEGMENTS):
		var a0: float = TAU * float(i) / float(RING_SEGMENTS)
		var a1: float = TAU * float(i + 1) / float(RING_SEGMENTS)
		_ring_mesh.surface_add_vertex(Vector3.ZERO)
		_ring_mesh.surface_add_vertex(Vector3(cos(a0) * r, 0.0, sin(a0) * r))
		_ring_mesh.surface_add_vertex(Vector3(cos(a1) * r, 0.0, sin(a1) * r))
	_ring_mesh.surface_end()

	# Kenar halkası
	_ring_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _mat_ring)
	for i in range(RING_SEGMENTS + 1):
		var a2: float = TAU * float(i) / float(RING_SEGMENTS)
		_ring_mesh.surface_add_vertex(Vector3(cos(a2) * r, 0.0, sin(a2) * r))
	_ring_mesh.surface_end()

func _build_label() -> void:
	# Küçük, sabit ekran boyutlu not (eskiden dünya boyutundaydı: yakın planda devasa "Trench"
	# yazısı birimin üstüne biniyordu). Rengi arazi türünün halka renginden, hafif sönük.
	_label = WorldLabel.make(feature_data.y_offset + 1.4, 13)
	var c: Color = feature_data.ring_color
	_label.modulate = Color(c.r, c.g, c.b, 0.8)
	_label.text = LocalizationManager.tr_t(feature_data.display_name_key)
	add_child(_label)

## Parça tüketildi (mayın patladı / etkisizleştirildi): görselden kaldır.
func consume() -> void:
	is_active = false
	queue_free()
