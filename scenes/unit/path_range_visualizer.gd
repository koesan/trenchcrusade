extends MeshInstance3D
class_name PathRangeVisualizer

## NavMesh uyumlu dinamik hareket alanı görselleştirici.
## Birimden dışarıya doğru radyal yollar sorgulayarak engelleri ve yüksekliği hesaplar.
## Ulaşılabilecek sınırları ve bağlı yolları ImmediateMesh ile çizerek gösterir.
## Faksiyona göre renk değiştirir ve alanı doldurarak yüksek görünürlük sağlar.

@export var num_segments: int = 36
@export var vertical_offset: float = 0.05

var mesh_im: ImmediateMesh
var material_perimeter: StandardMaterial3D
var material_fill: StandardMaterial3D
var material_spokes: StandardMaterial3D
## Dikey erişim sınıfı → renk. ClimbingResolver'ın dört sonucuyla birebir eşleşir.
const VERTICAL_COLORS := {
	"walkover_up":   Color(0.42, 0.86, 0.45, 0.95),  # yeşil  — serbest çıkış
	"climb":         Color(0.98, 0.68, 0.22, 0.95),  # turuncu — Risky tırmanış
	"walkover_down": Color(0.40, 0.72, 0.98, 0.95),  # mavi   — serbest iniş
	"climb_down":    Color(0.95, 0.36, 0.30, 0.95),  # kırmızı — Risky iniş
}
## Dikey erişim BÖLGESİ: kenar boyunca uzanan, varış yüzeyine doğru sönen renkli şerit (eski ok
## işaretçileri haritada "tuhaf oklar" gibi duruyordu — kullanıcı bildirimi). Kenar çizgisi parlak,
## gövde yumuşak degrade; Risky (zar gerektiren) sınıflar daha belirgin çizilir.
const ZONE_DEPTH := 0.9        ## şeridin varış yüzeyine doğru derinliği
const ZONE_EDGE := 0.14        ## parlak kenar çizgisinin kalınlığı
const ZONE_JOIN_MAX := 2.2     ## komşu örnekler bu mesafeden yakınsa tek şeritte birleşir
const ZONE_LIFT := 0.06
const ZONE_SPOT_R := 0.55      ## tek başına kalan örnek için yuvarlak leke yarıçapı

var _vertical_materials: Dictionary = {}

## Menzil alanı görünümü: merkezde neredeyse saydam, kenarda belirgin (radyal degrade) ve
## kenarda 1px çizgi yerine kalın bir şerit. Eski görünüm düz, beyazımsı opak bir çokgendi —
## altındaki araziyi örtüyor ve "programcı çizimi" gibi duruyordu (2026-10-23 görsel denetim).
const FILL_CENTER_ALPHA := 0.0
const FILL_EDGE_ALPHA := 0.17
const EDGE_WIDTH := 0.14
var _fill_rgb: Color = Color.WHITE

var boundary_points: PackedVector3Array = PackedVector3Array()
var is_active: bool = false
var current_unit = null

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
	# Saydamlık köşe renginden gelir: merkez neredeyse görünmez, kenar belirgin (radyal degrade).
	material_fill.vertex_color_use_as_albedo = true
	material_perimeter.cull_mode = StandardMaterial3D.CULL_DISABLED
	
	material_spokes = StandardMaterial3D.new()
	material_spokes.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material_spokes.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
	material_spokes.no_depth_test = false

	# Dikey erişim bölgeleri — kenar boyunca renkli şerit (zemin hizasında, derinlik testli).
	# DÖRT AYRI SINIF — eskiden iki soluk gri ton vardı ve oyuncu "buraya bedava çıkabilir
	# miyim yoksa zar mı atacağım?" sorusunu göremiyordu (kullanıcı bildirimi: "bozuk").
	# Renkler ClimbingResolver'ın dört sonucuyla BİREBİR eşleşir:
	#   walkover_up   (yeşil)  → serbest çıkış, zar YOK
	#   climb         (turuncu)→ Risky Success gerekir
	#   walkover_down (mavi)   → serbest iniş, zar YOK
	#   climb_down    (kırmızı)→ Risky Success gerekir
	for key in VERTICAL_COLORS.keys():
		var m := StandardMaterial3D.new()
		m.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = StandardMaterial3D.CULL_DISABLED
		m.vertex_color_use_as_albedo = true  # renk + degrade saydamlık köşelerden
		m.albedo_color = Color.WHITE
		_vertical_materials[key] = m

func hide_visuals():
	is_active = false
	visible = false
	if mesh_im:
		mesh_im.clear_surfaces()

func show_visuals(unit_node):
	current_unit = unit_node
	is_active = true
	visible = true
	
	# Faksiyona göre renkleri güncelle
	_update_colors()
	update_visuals()

func _update_colors():
	var colors = GameVisualColors.get_colors()
	var color_to_use = colors.path_default
			
	# Çevre sınırı (kalın ve belirgin şerit)
	material_perimeter.albedo_color = Color(color_to_use.r, color_to_use.g, color_to_use.b, 0.9)
	# Dolgu: rengi beyaz, ton+saydamlık köşe renginden (bkz. update_visuals FILL_* sabitleri)
	material_fill.albedo_color = Color.WHITE
	_fill_rgb = color_to_use
	# Yollar/Spokes — yalnızca çok hafif bir doku; eskiden alanı beyaz bir "örümcek ağına" çeviriyordu
	material_spokes.albedo_color = Color(color_to_use.r, color_to_use.g, color_to_use.b, 0.06)

func update_visuals():
	if not is_active or not is_instance_valid(current_unit) or not current_unit.is_inside_tree():
		return
		
	var start_pos = current_unit.global_position
	var movement_range = current_unit.movement_range
	var map_rid = current_unit.get_world_3d().navigation_map
	
	boundary_points.clear()
	mesh_im.clear_surfaces()
	
	var paths_to_draw = []
	
	for i in range(num_segments):
		var angle = (float(i) / num_segments) * TAU
		var dir = Vector3(cos(angle), 0, sin(angle))
		var target_test_pos = start_pos + dir * movement_range
		
		# NavMesh üzerinden yolu sorgula
		var path = NavigationServer3D.map_get_path(map_rid, start_pos, target_test_pos, true)
		
		if path.size() < 2:
			var fallback_point = start_pos + dir * 0.1
			fallback_point.y = start_pos.y
			boundary_points.append(fallback_point)
			paths_to_draw.append([start_pos, fallback_point])
			continue
			
		var accumulated_dist = 0.0
		var limited_path = [path[0]]
		
		for j in range(path.size() - 1):
			var p1 = path[j]
			var p2 = path[j+1]
			var dist = p1.distance_to(p2)
			
			if accumulated_dist + dist >= movement_range:
				var remaining = movement_range - accumulated_dist
				var limit_pos = p1 + (p2 - p1).normalized() * remaining
				limited_path.append(limit_pos)
				accumulated_dist = movement_range
				break
			else:
				accumulated_dist += dist
				limited_path.append(p2)
				
		var end_point = limited_path[limited_path.size() - 1]
		boundary_points.append(end_point)
		paths_to_draw.append(limited_path)
		
	# 1. Dolgu Alanını (Filled Polygon - Triangles) çiz
	if boundary_points.size() > 2:
		mesh_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material_fill)
		var center_pt = start_pos + Vector3(0, vertical_offset, 0)
		var c_center := Color(_fill_rgb, FILL_CENTER_ALPHA)
		var c_edge := Color(_fill_rgb, FILL_EDGE_ALPHA)
		for i in range(boundary_points.size()):
			var p1 = boundary_points[i] + Vector3(0, vertical_offset, 0)
			var p2 = boundary_points[(i + 1) % boundary_points.size()] + Vector3(0, vertical_offset, 0)
			mesh_im.surface_set_color(c_center)
			mesh_im.surface_add_vertex(center_pt)
			mesh_im.surface_set_color(c_edge)
			mesh_im.surface_add_vertex(p1)
			mesh_im.surface_set_color(c_edge)
			mesh_im.surface_add_vertex(p2)
		mesh_im.surface_end()
		
	# 2. Radyal yolları çiz (İnce destek çizgileri)
	mesh_im.surface_begin(Mesh.PRIMITIVE_LINES, material_spokes)
	for path in paths_to_draw:
		for j in range(path.size() - 1):
			var p1 = path[j] + Vector3(0, vertical_offset, 0)
			var p2 = path[j+1] + Vector3(0, vertical_offset, 0)
			mesh_im.surface_add_vertex(p1)
			mesh_im.surface_add_vertex(p2)
	mesh_im.surface_end()
	
	# 3. Çevre sınır hattını çiz (Belirgin kenar çizgisi)
	# Kenar, merkeze doğru içe uzanan EDGE_WIDTH genişliğinde bir üçgen şerididir — çizgi
	# primitifleri GPU'da hep 1px çizilir ve uzaktan kaybolur.
	if boundary_points.size() > 2:
		mesh_im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, material_perimeter)
		var lift := Vector3(0, vertical_offset + 0.01, 0)
		for k in range(boundary_points.size() + 1):
			var pt: Vector3 = boundary_points[k % boundary_points.size()]
			var inward: Vector3 = start_pos - pt
			inward.y = 0.0
			var inner: Vector3 = pt + inward.limit_length(EDGE_WIDTH)
			mesh_im.surface_add_vertex(pt + lift)
			mesh_im.surface_add_vertex(inner + lift)
		mesh_im.surface_end()

	# 4. Dikey erişim bölgeleri (tırmanma / aşağı atlama) — kullanıcı nereye çıkıp
	#    inebileceğini görsün. Düz haritada hiç işaret çıkmaz.
	_draw_vertical_access()

## Bir dikey geçişi ClimbingResolver ile AYNI eşiklere göre sınıflandırır. SAF fonksiyon —
## sahne kurmadan test edilir (bkz. vertical_access_test.gd).
##   dy         : hedef yüksekliği − birim yüksekliği (+ yukarı, − aşağı)
##   horiz_dist : birimden hedefe yatay mesafe
##   move_range : birimin kalan hareket bütçesi
## Döndürür: "walkover_up" | "climb" | "walkover_down" | "climb_down" | "" (gösterilmez)
static func classify_vertical(dy: float, horiz_dist: float, move_range: float) -> String:
	if absf(dy) <= GameState.VERTICAL_STEP_MAX:
		return ""  # düz zemin — dikey işaret yok
	if dy > 0.0:
		# YUKARI: compendium — tırmanışta yatay + yükseklik birlikte bütçeye sayılır.
		if horiz_dist + dy > move_range + 0.5:
			return ""
		return "walkover_up" if dy <= GameState.CLIMB_FREE_MAX else "climb"
	# AŞAĞI: dikey serbest, yalnız yatay mesafe bütçeye sayılır.
	if horiz_dist > move_range + 0.5:
		return ""
	return "walkover_down" if -dy <= GameState.CLIMB_FREE_MAX else "climb_down"

## Birimin çevresinde radyal örnekleme yaparak tırmanılabilir duvar / inilebilir kenar
## noktalarını bulur; aynı sınıftaki komşu noktalar kenar boyunca tek bir renkli şeritte birleşir.
## Düz haritada hiçbir şey çizilmez.
func _draw_vertical_access():
	var start = current_unit.global_position
	var move_range = current_unit.movement_range
	var world = current_unit.get_world_3d()
	if world == null:
		return
	var space = world.direct_space_state
	var map_rid: RID = world.navigation_map

	# Birimleri hariç tut (yalnız arazi yüksekliği örneklensin)
	var excludes: Array = []
	for u in UnitQuery.all():
		excludes.append(u.get_rid())

	var sample_dist: float = 0.8
	var max_steps: int = int(move_range / sample_dist) + 2
	# Yön başına ilk dikey geçiş: {kind, p (varış yüzeyi), dir} ya da null
	var samples: Array = []
	samples.resize(num_segments)
	for i in range(num_segments):
		var angle = (float(i) / num_segments) * TAU
		var dir = Vector3(cos(angle), 0, sin(angle))
		var last_flat: Vector3 = start
		for step in range(1, max_steps):
			var d = step * sample_dist
			if d > move_range + 0.5:
				break
			var sxz = start + dir * d
			# Modelin seviyesinde yürünebilir zemin (NavMesh) varsa düzdür — çarpışması olmayan
			# tahta geçitlerde ışın alttaki siper tabanına inip her yönde sahte "iniş" üretiyordu.
			var level: Vector3 = NavigationServer3D.map_get_closest_point(map_rid, sxz)
			if Vector2(level.x - sxz.x, level.z - sxz.z).length() < 0.3 \
					and absf(level.y - start.y) <= GameState.VERTICAL_STEP_MAX:
				last_flat = level
				continue
			var q = PhysicsRayQueryParameters3D.create(
				Vector3(sxz.x, start.y + 20.0, sxz.z),
				Vector3(sxz.x, start.y - 20.0, sxz.z))
			q.exclude = excludes
			var res = space.intersect_ray(q)
			if res.is_empty():
				continue
			var dy = res.position.y - start.y
			if absf(dy) <= GameState.VERTICAL_STEP_MAX:
				last_flat = res.position
				continue  # düz — bu yönde aramaya devam
			var kind := classify_vertical(dy, d, move_range)
			if kind == "":
				break
			if dy > 0.0:
				# Çıkış: bölge varılan yüzeyin kenarında, platformun üstüne doğru söner.
				samples[i] = {"kind": kind, "p": Vector3(sxz.x, res.position.y, sxz.z), "dir": dir}
			else:
				# İniş: bölge modelin bulunduğu seviyede kenar dudağında, modele doğru söner — alt
				# zemin siper duvarlarının arkasında kalıp görünmüyordu.
				samples[i] = {"kind": kind, "p": last_flat + dir * (sample_dist * 0.5), "dir": -dir}
			break  # bu yönde ilk dikey engel bulundu

	for kind in VERTICAL_COLORS.keys():
		var col: Color = VERTICAL_COLORS[kind]
		var strong: bool = kind == "climb" or kind == "climb_down"
		var body_a: float = 0.42 if strong else 0.3
		var drew := false
		for i in range(num_segments):
			var s = samples[i]
			if s == null or s["kind"] != kind:
				continue
			if not drew:
				mesh_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _vertical_materials[kind])
				drew = true
			var nxt = samples[(i + 1) % num_segments]
			var prv = samples[(i - 1 + num_segments) % num_segments]
			var joins_next: bool = _zone_joins(s, nxt)
			if joins_next:
				_zone_band(s, nxt, col, body_a)
			elif not _zone_joins(prv, s):
				_zone_spot(s["p"], col, body_a)
		if drew:
			mesh_im.surface_end()

static func _zone_joins(a, b) -> bool:
	return a != null and b != null and a["kind"] == b["kind"] \
		and a["p"].distance_to(b["p"]) <= ZONE_JOIN_MAX

## İki komşu örnek arasında şerit: kenarda parlak çizgi, varış yüzeyine doğru sönen gövde.
func _zone_band(a: Dictionary, b: Dictionary, col: Color, body_a: float) -> void:
	var up := Vector3(0, ZONE_LIFT, 0)
	var a0: Vector3 = a["p"] + up
	var b0: Vector3 = b["p"] + up
	var a1: Vector3 = a0 + a["dir"] * ZONE_EDGE
	var b1: Vector3 = b0 + b["dir"] * ZONE_EDGE
	var a2: Vector3 = a0 + a["dir"] * ZONE_DEPTH
	var b2: Vector3 = b0 + b["dir"] * ZONE_DEPTH
	_quad(a0, b0, b1, a1, Color(col, 0.95), Color(col, 0.95), Color(col, 0.85), Color(col, 0.85))
	_quad(a1, b1, b2, a2, Color(col, body_a), Color(col, body_a), Color(col, 0.0), Color(col, 0.0))

## Tek başına kalan örnek: ortası dolgun, kenarı sönen yuvarlak leke.
func _zone_spot(p: Vector3, col: Color, body_a: float) -> void:
	var c := p + Vector3(0, ZONE_LIFT, 0)
	var n := 16
	for k in range(n):
		var d0 := Vector3(cos(TAU * k / n), 0, sin(TAU * k / n)) * ZONE_SPOT_R
		var d1 := Vector3(cos(TAU * (k + 1) / n), 0, sin(TAU * (k + 1) / n)) * ZONE_SPOT_R
		mesh_im.surface_set_color(Color(col, body_a + 0.25))
		mesh_im.surface_add_vertex(c)
		mesh_im.surface_set_color(Color(col, 0.0))
		mesh_im.surface_add_vertex(c + d0)
		mesh_im.surface_set_color(Color(col, 0.0))
		mesh_im.surface_add_vertex(c + d1)

func _quad(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, c0: Color, c1: Color, c2: Color, c3: Color) -> void:
	for pair in [[p0, c0], [p1, c1], [p2, c2], [p0, c0], [p2, c2], [p3, c3]]:
		mesh_im.surface_set_color(pair[1])
		mesh_im.surface_add_vertex(pair[0])
