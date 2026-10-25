extends Node3D
class_name RelicMarker

## Relic Hunt senaryosundaki bir Reliquary'nin görsel temsili.
##
## KURAL KAYNAĞI (compendium: scenarios/relic-hunt, "Reliquary Markers"):
##   "A model that is within 1" of a Reliquary, can take a Claim Reliquary Action... If the roll
##    is a Success or Critical Success, the Reliquary is claimed by the model... At the end of
##    Turn 1, remove Reliquaries 1 and 2, and at the end of turn 2, remove Reliquaries 3 and 4."
##
## objective_marker.gd (Claim No Man's Land bayrağı) ile AYNI görsel dil (renkli halka + tonlu
## model) kullanılır — ama FARKLI 3D modeller (Reliquary sandık/rölik asset'leri, ObjectiveMarker
## ile PAYLAŞILMAZ, unit_model_uniqueness_test'in kapsamı yalnız unit modelleri) ve claim/kaldırma
## durumuna göre GİZLENEBİLİR (set_removed) olması gerekir — proximity-tabanlı ObjectiveMarker'da
## bu kavram yok.

var objective_id: StringName = &""
var _controller: int = 0
var control_radius: float = 1.0

var _relic_model: Node3D
var _relic_mat: StandardMaterial3D
var _label: Label3D

var _zone_mesh_instance: MeshInstance3D
var _zone_mesh: ImmediateMesh
var _zone_mat_ring: StandardMaterial3D

const COL_NEUTRAL := Color(0.85, 0.78, 0.55, 1.0)   # Kutsal/altın nötr ton
const RING_ALPHA := 0.35
const RING_SEGMENTS := 48

## Bayrak/kutsal-emanet modelinin dikeyde ne kadar yukarı kaldırılacağı (zemine gömülmesin).
const RELIC_Y_OFFSET := 0.15

func _process(_delta: float) -> void:
	if _zone_mesh_instance != null and is_inside_tree():
		_zone_mesh_instance.global_position = global_position

func _ready() -> void:
	_build_zone_visual()
	_build_label()

func _build_zone_visual() -> void:
	_zone_mesh_instance = MeshInstance3D.new()
	_zone_mesh_instance.top_level = true
	add_child(_zone_mesh_instance)
	_zone_mesh = ImmediateMesh.new()
	_zone_mesh_instance.mesh = _zone_mesh

	_zone_mat_ring = StandardMaterial3D.new()
	_zone_mat_ring.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	_zone_mat_ring.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	_zone_mat_ring.no_depth_test = false

func _draw_zone() -> void:
	if _zone_mesh == null:
		return
	_zone_mesh_instance.global_position = global_position
	var c: Color = COL_NEUTRAL if _controller == 0 else _get_faction_color(_controller)
	_zone_mesh.clear_surfaces()
	var y_off := 0.06
	var pts := PackedVector3Array()
	for i in range(RING_SEGMENTS):
		var angle := (float(i) / RING_SEGMENTS) * TAU
		pts.append(Vector3(cos(angle) * control_radius, y_off, sin(angle) * control_radius))
	_zone_mat_ring.albedo_color = Color(c.r, c.g, c.b, RING_ALPHA)
	_zone_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _zone_mat_ring)
	for pt in pts:
		_zone_mesh.surface_add_vertex(pt)
	_zone_mesh.surface_add_vertex(pts[0])
	_zone_mesh.surface_end()

func _build_label() -> void:
	_label = WorldLabel.make(2.0)
	add_child(_label)

func _build_relic(model_path: String) -> void:
	var packed: PackedScene = load(model_path) if model_path != "" else null
	if packed == null:
		push_warning("[RelicMarker] GLB yüklenemedi: " + model_path)
		return
	_relic_model = packed.instantiate()
	_relic_model.position = Vector3(0.0, RELIC_Y_OFFSET, 0.0)
	add_child(_relic_model)

	_relic_mat = StandardMaterial3D.new()
	_relic_mat.albedo_color = COL_NEUTRAL
	_relic_mat.roughness = 0.55
	_relic_mat.metallic = 0.2
	_apply_material_to_all_meshes(_relic_model)

func _apply_material_to_all_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		node.material_override = _relic_mat
	for child in node.get_children():
		_apply_material_to_all_meshes(child)

# ── DIŞ API (game.gd tarafından, ObjectiveMarker ile AYNI imza) ─────────────────────────────

## Reliquary verisinden marker'ı kur. model_path: bu Reliquary'nin hangi glb'yi kullanacağı
## (3 relic asset'i 4 marker arasında paylaşılır — compendium buna izin veriyor, gerçek fiziksel
## kopyalar farklı gösterilir).
func setup(obj: ScenarioObjective, model_path: String) -> void:
	objective_id = obj.objective_id
	control_radius = obj.control_radius
	global_position = obj.position
	_build_relic(model_path)
	if _label != null:
		_label.text = LocalizationManager.tr_t(obj.label_key)
	_draw_zone()

## ObjectiveMarker ile aynı API — game.gd'nin genel _update_objective_markers döngüsü değişmeden
## Relic Hunt'ta da çalışsın diye.
func set_controller(pid: int) -> void:
	if pid == _controller:
		return
	_controller = pid
	_apply_controller_color()

## Reliquary sahadan kaldırıldığında (tur 1/2 sonu) çağrılır — marker'ı görünmez yapar.
func set_removed(is_removed: bool) -> void:
	visible = not is_removed

func _get_faction_color(player_id: int) -> Color:
	var faction = GameState.get_faction_for_player(player_id)
	if faction == null or not ("team_color" in faction):
		return COL_NEUTRAL
	return faction.team_color

func _apply_controller_color() -> void:
	var c: Color = COL_NEUTRAL if _controller == 0 else _get_faction_color(_controller)
	if _relic_mat != null:
		_relic_mat.albedo_color = c
	_draw_zone()
	if _label != null:
		_label.modulate = c.lightened(0.3) if _controller != 0 else WorldLabel.text_color()
