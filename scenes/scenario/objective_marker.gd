extends Node3D
class_name ObjectiveMarker

## Sahadaki bir görev noktasının (Objective) görsel temsili.
##
## KURAL KAYNAĞI (compendium: scenarios/claim-no-mans-land, "Controlling Objectives"):
##   "A player controls an Objective terrain piece if there are more friendly models
##    ON, IN, OR WITHIN 1" of the terrain piece than there are enemy models.
##    If one player has any models ON the terrain piece and their opponent does NOT,
##    then the player with models ON the terrain piece controls it even if their
##    opponent has more models within 1" of the Objective."
##
## Bu kural get_persistent_objective_controller() içinde uygulanır.
## Kalıcı sahiplik: unit sahadan çekilse dahi bayrak son alıcı faction'da KALIR;
## yalnızca rakip faction aktif birimlerle kontrolü DEVRALİNCE değişir.

var objective_id: StringName = &""
var _controller: int = 0          # 0 = nötr, 1 = Oyuncu 1, 2 = Oyuncu 2
var control_radius: float = 1.0   # Compendium "within 1 inch" — ScenarioObjective'den gelir

# ── GÖRSEL DÜĞÜMLER ─────────────────────────────────────────────────────────
var _flag_model: Node3D           # GLB bayrağı
var _flag_mat: StandardMaterial3D # Bayrak renk materyali
var _label: Label3D

# ── YAKALAMA ALANI GÖRSEL (ImmediateMesh — unit sınır tarzı, saydam) ─────────
var _zone_mesh_instance: MeshInstance3D
var _zone_mesh: ImmediateMesh
var _zone_mat_fill: StandardMaterial3D
var _zone_mat_ring: StandardMaterial3D

# ── RENK SABİTLERİ ──────────────────────────────────────────────────────────
const COL_NEUTRAL   := Color(0.86, 0.78, 0.6, 1.0)  # Parşömen → hiç alınmamış (saf beyaz harita üstünde "boş disk" gibi duruyordu)
const FILL_ALPHA    := 0.07   # Dolgu: çok hafif, rahat bakılır
const RING_ALPHA    := 0.28   # Halka kenar: hafifçe belli ama göz yormaz
const RING_SEGMENTS := 64     # Pürüzsüz çember

## Bayrak modelinin yolu (assets/models/scenario/ altında — proje yapısına uygun)
const FLAG_MODEL_PATH := "res://assets/models/scenario/objective_flag.glb"

## Bayrağın zemine göre Y ofseti — model zeminin içine gömülmesin, üstünde dursun.
## Harita Y koordinatları negatif olabileceğinden yeterince yüksek tutulur.
const FLAG_Y_OFFSET := 1.2

## Görsel çember: compendium'daki iki zone'u gösterir.
## İÇ halka = terrain piece sınırı (control_radius = 1")
## DIŞ halka = "within 1\" of terrain piece" (outer_radius = control_radius + 1.0)
## İki zone arasındaki dolgu daha açık, terrain piece içi biraz daha belirgin.
func _draw_zone() -> void:
	if _zone_mesh == null or _zone_mesh_instance == null:
		return

	_zone_mesh_instance.global_position = global_position

	var c: Color = COL_NEUTRAL if _controller == 0 else _get_faction_color(_controller)
	var inner_r: float = control_radius          # terrain piece sınırı
	var outer_r: float = control_radius + 1.0   # "within 1 inch of terrain piece"

	_zone_mesh.clear_surfaces()

	var y_off := 0.06   # Z-fighting önleme (zeminden hafif yukarı)

	# Nokta dizilerini oluştur
	var pts_inner := PackedVector3Array()
	var pts_outer := PackedVector3Array()
	for i in range(RING_SEGMENTS):
		var angle := (float(i) / RING_SEGMENTS) * TAU
		var ca := cos(angle)
		var sa := sin(angle)
		pts_inner.append(Vector3(ca * inner_r, y_off, sa * inner_r))
		pts_outer.append(Vector3(ca * outer_r, y_off, sa * outer_r))

	# 1. Terrain piece iç dolgu (biraz daha belirgin — oyuncu orada duruyor mu?)
	var inner_fill_mat := _zone_mat_fill.duplicate() as StandardMaterial3D
	inner_fill_mat.albedo_color = Color(c.r, c.g, c.b, FILL_ALPHA * 1.8)

	_zone_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, inner_fill_mat)
	var center := Vector3(0.0, y_off, 0.0)
	for i in range(pts_inner.size()):
		_zone_mesh.surface_add_vertex(center)
		_zone_mesh.surface_add_vertex(pts_inner[i])
		_zone_mesh.surface_add_vertex(pts_inner[(i + 1) % pts_inner.size()])
	_zone_mesh.surface_end()

	# 2. İç halka (terrain piece sınırı — belirgin, ince çizgi)
	_zone_mat_ring.albedo_color = Color(c.r, c.g, c.b, RING_ALPHA)
	_zone_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _zone_mat_ring)
	for pt in pts_inner:
		_zone_mesh.surface_add_vertex(pt)
	_zone_mesh.surface_add_vertex(pts_inner[0])
	_zone_mesh.surface_end()

	# 3. Dış dolgu halkası (iç ile dış arasındaki "within 1 inch" bölgesi — çok hafif)
	var outer_fill_mat := _zone_mat_fill.duplicate() as StandardMaterial3D
	outer_fill_mat.albedo_color = Color(c.r, c.g, c.b, FILL_ALPHA * 0.6)
	_zone_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, outer_fill_mat)
	for i in range(RING_SEGMENTS):
		var i_next := (i + 1) % RING_SEGMENTS
		# Quad olarak iki üçgen: iç[i], dış[i], iç[i+1] ve dış[i], dış[i+1], iç[i+1]
		_zone_mesh.surface_add_vertex(pts_inner[i])
		_zone_mesh.surface_add_vertex(pts_outer[i])
		_zone_mesh.surface_add_vertex(pts_inner[i_next])
		_zone_mesh.surface_add_vertex(pts_outer[i])
		_zone_mesh.surface_add_vertex(pts_outer[i_next])
		_zone_mesh.surface_add_vertex(pts_inner[i_next])
	_zone_mesh.surface_end()

	# 4. Dış halka (within 1" sınırı — daha soluk, ince)
	var outer_ring_mat := _zone_mat_ring.duplicate() as StandardMaterial3D
	outer_ring_mat.albedo_color = Color(c.r, c.g, c.b, RING_ALPHA * 0.55)
	_zone_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, outer_ring_mat)
	for pt in pts_outer:
		_zone_mesh.surface_add_vertex(pt)
	_zone_mesh.surface_add_vertex(pts_outer[0])
	_zone_mesh.surface_end()

func _process(_delta: float) -> void:
	# Zone mesh'i bayrak konumuna kilitle (top_level=true nedeniyle manuel sync gerekir)
	if _zone_mesh_instance != null and is_inside_tree():
		_zone_mesh_instance.global_position = global_position

func _ready() -> void:
	_build_zone_visuals()
	_build_flag()
	_build_label()
	_apply_controller_color()

# ── İNŞA ────────────────────────────────────────────────────────────────────

func _build_zone_visuals() -> void:
	_zone_mesh_instance = MeshInstance3D.new()
	_zone_mesh_instance.top_level = true   # Üst düğüm rotation/scale'inden bağımsız
	add_child(_zone_mesh_instance)

	_zone_mesh = ImmediateMesh.new()
	_zone_mesh_instance.mesh = _zone_mesh

	# Dolgu materyali — çok saydam, göz yormaz
	_zone_mat_fill = StandardMaterial3D.new()
	_zone_mat_fill.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	_zone_mat_fill.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	_zone_mat_fill.cull_mode = StandardMaterial3D.CULL_DISABLED
	_zone_mat_fill.no_depth_test = false
	_zone_mat_fill.depth_draw_mode = StandardMaterial3D.DEPTH_DRAW_DISABLED

	# Halka kenar materyali — hafifçe daha belirgin
	_zone_mat_ring = StandardMaterial3D.new()
	_zone_mat_ring.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	_zone_mat_ring.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	_zone_mat_ring.no_depth_test = false

func _build_flag() -> void:
	var packed: PackedScene = load(FLAG_MODEL_PATH)
	if packed == null:
		push_warning("[ObjectiveMarker] GLB yüklenemedi: " + FLAG_MODEL_PATH + " — fallback kullanılıyor.")
		_build_fallback_flag()
		return

	_flag_model = packed.instantiate()
	# Modeli zemine göre yukarı kaldır (içe gömülmesin)
	_flag_model.position = Vector3(0.0, FLAG_Y_OFFSET, 0.0)
	add_child(_flag_model)

	# Renk tonu için materyal — GLB'nin tüm mesh yüzeylerini override et
	_flag_mat = StandardMaterial3D.new()
	_flag_mat.albedo_color = COL_NEUTRAL
	_flag_mat.roughness = 0.65
	_flag_mat.metallic = 0.08
	_apply_material_to_all_meshes(_flag_model)

func _apply_material_to_all_meshes(node: Node) -> void:
	## GLB ağacındaki tüm MeshInstance3D'lere renk materyalini ata.
	if node is MeshInstance3D:
		node.material_override = _flag_mat
	for child in node.get_children():
		_apply_material_to_all_meshes(child)

func _build_fallback_flag() -> void:
	## GLB yüklenemezse minimal prosedürel bayrak (hata ayıklama için).
	_flag_model = Node3D.new()
	_flag_model.position.y = FLAG_Y_OFFSET
	add_child(_flag_model)

	# Direk
	var pole := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.05
	cyl.bottom_radius = 0.05
	cyl.height = 2.0
	pole.mesh = cyl
	pole.position.y = 1.0
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.22, 0.18, 0.14)
	pole_mat.roughness = 0.8
	pole.material_override = pole_mat
	_flag_model.add_child(pole)

	# Bayrak bezi
	var banner := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.85, 0.5)
	banner.mesh = quad
	banner.position = Vector3(0.44, 1.88, 0.0)
	_flag_mat = StandardMaterial3D.new()
	_flag_mat.cull_mode = StandardMaterial3D.CULL_DISABLED
	_flag_mat.albedo_color = COL_NEUTRAL
	_flag_mat.roughness = 0.7
	banner.material_override = _flag_mat
	_flag_model.add_child(banner)

func _build_label() -> void:
	_label = WorldLabel.make(3.2)   # bayrak modelinin üstünde
	add_child(_label)

# ── DIŞ API ─────────────────────────────────────────────────────────────────

## Objective verisinden marker'ı kur. game.gd'den, add_child(marker) sonrası çağrılır.
func setup(obj: ScenarioObjective) -> void:
	objective_id = obj.objective_id
	control_radius = obj.control_radius
	global_position = obj.position
	if _label != null:
		_label.text = LocalizationManager.tr_t(obj.label_key)
	# Zone mesh'i doğru boyutla çiz
	_draw_zone()

## Kontrolcüyü güncelle (game.gd veya ScenarioLogic tarafından çağrılır).
func set_controller(pid: int) -> void:
	if pid == _controller:
		return
	_controller = pid
	_apply_controller_color()

# ── RENK UYGULAMA ────────────────────────────────────────────────────────────

func _get_faction_color(player_id: int) -> Color:
	## FactionData.team_color — GameState'ten player_id'ye göre alır.
	var faction = GameState.get_faction_for_player(player_id)
	if faction == null or not ("team_color" in faction):
		return COL_NEUTRAL
	return faction.team_color

func _apply_controller_color() -> void:
	var c: Color = COL_NEUTRAL if _controller == 0 else _get_faction_color(_controller)

	# Bayrak rengi
	if _flag_mat != null:
		_flag_mat.albedo_color = c

	# Zone çemberi yeniden çiz
	_draw_zone()

	# Etiket rengi
	if _label != null and objective_id != &"":
		_label.modulate = c.lightened(0.3) if _controller != 0 else WorldLabel.text_color()

