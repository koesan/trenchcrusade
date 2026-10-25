class_name TargetLine
extends MeshInstance3D

## HEDEF ÇİZGİSİ — saldırı/yetenek hedeflenirken saldıranın tabanından hedefin tabanına, ZEMİN
## hizasında uzanan şerit; iki taban da kendi renginde halkayla çevrilir (saldıran: yaldız,
## hedef: kan kırmızısı) — kimin kime saldırdığı bir bakışta okunur.
## Şeridin rengi görüş durumunu söyler: açık → kemik beyazı, örtü (kısmi) → amber, kapalı →
## kül grisi ve kesik. Oyuncu neden ateş edemeyeceğini hata mesajını beklemeden haritada görür.
## Zar dökümü kartıyla birlikte açılır/kapanır (game_hud → "target_line" grubu).

const LIFT := 0.05           ## zemin üstü pay (z-fighting olmasın)
const WIDTH := 0.14
const DASH := 0.35
const RING_IN := 0.68
const RING_OUT := 0.8
const HALO_OUT := 0.98
const SEGMENTS := 48

var _line_mat := _make_mat()
var _attacker_mat := _make_mat()
var _target_mat := _make_mat()
var _halo_a := _make_mat()
var _halo_t := _make_mat()

func _ready() -> void:
	add_to_group("target_line")
	mesh = ImmediateMesh.new()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	top_level = true
	visible = false

static func _make_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func show_for(attacker: Node3D, target: Node3D) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target) or not attacker.has_method("get_line_of_sight_status"):
		hide_line()
		return
	var los: Dictionary = attacker.get_line_of_sight_status(target)
	var blocked: bool = los.get("is_blocked", false)
	var line_col := "color_parchment"
	if blocked:
		line_col = "color_dim_text"
	elif los.get("in_cover", false):
		line_col = "color_status_caution"
	_line_mat.albedo_color = Color(GothicThemeHelper.color(line_col), 0.9)
	var gold: Color = GothicThemeHelper.color("color_gold_bright")
	var red: Color = GothicThemeHelper.color("color_alert_red")
	_attacker_mat.albedo_color = Color(gold, 0.95)
	_target_mat.albedo_color = Color(red, 0.95)
	_halo_a.albedo_color = Color(gold, 0.22)
	_halo_t.albedo_color = Color(red, 0.22)
	_build(attacker.global_position, target.global_position, blocked)
	visible = true

func hide_line() -> void:
	visible = false

func _build(a: Vector3, b: Vector3, dashed: bool) -> void:
	var im := mesh as ImmediateMesh
	im.clear_surfaces()
	var flat := Vector3(b.x - a.x, 0.0, b.z - a.z)
	if flat.length() < 0.01:
		return
	var dir := flat.normalized()
	_ring(im, a, RING_IN, RING_OUT, _attacker_mat)
	_ring(im, a, RING_OUT, HALO_OUT, _halo_a)
	_ring(im, b, RING_IN, RING_OUT, _target_mat)
	_ring(im, b, RING_OUT, HALO_OUT, _halo_t)
	# Şerit halkaların dış kenarından başlar ve biter — tabandan tabana.
	var start := a + dir * RING_OUT
	var end := b - dir * RING_OUT
	var span := end - start
	var length := span.length()
	if length < 0.05 or Vector3(span.x, 0, span.z).dot(dir) <= 0.0:
		return
	var step := span / length
	var side := dir.cross(Vector3.UP).normalized() * WIDTH * 0.5
	var up := Vector3.UP * LIFT
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _line_mat)
	var t := 0.0
	while t < length:
		var t2 := minf(length, t + (DASH if dashed else length))
		var p1 := start + step * t + up
		var p2 := start + step * t2 + up
		for v in [p1 - side, p1 + side, p2 + side, p1 - side, p2 + side, p2 - side]:
			im.surface_add_vertex(v)
		t = t2 + (DASH * 0.6 if dashed else 0.0)
	im.surface_end()

## Tabanın çevresinde düz halka (zemin hizasında).
func _ring(im: ImmediateMesh, center: Vector3, r_in: float, r_out: float, mat: Material) -> void:
	var c := center + Vector3.UP * LIFT
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, mat)
	for i in range(SEGMENTS):
		var a0 := TAU * float(i) / SEGMENTS
		var a1 := TAU * float(i + 1) / SEGMENTS
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		for v in [c + d0 * r_in, c + d0 * r_out, c + d1 * r_out, c + d0 * r_in, c + d1 * r_out, c + d1 * r_in]:
			im.surface_add_vertex(v)
	im.surface_end()
