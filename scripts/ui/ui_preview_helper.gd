class_name UIPreviewHelper
extends Node

## Helper utility for creating 3D model previews inside 2D UI elements.
## Deduplicates viewport, camera, environment, and model normalization logic.

static var model_cache: Dictionary = {}

## Arka planda yüklenen modeller: {yol: [WeakRef(viewport), ...]}. Aynı model için TEK istek açılır;
## sonucu bekleyen her önizleme listeye eklenir. Yükleyici düğüm önizlemeye DEĞİL ağacın köküne
## bağlıdır: kart yükleme bitmeden yok edilse bile sonuç alınır (alınmayan threaded yükleme
## ResourceLoader'da asılı kalır ve çıkışta "ObjectDB instances leaked" uyarısı üretiyordu).
static var _pending: Dictionary = {}

class AsyncModelLoader extends Node:
	var model_path: String

	func _process(_delta: float) -> void:
		match ResourceLoader.load_threaded_get_status(model_path):
			ResourceLoader.THREAD_LOAD_LOADED:
				var scene: PackedScene = ResourceLoader.load_threaded_get(model_path)
				if scene:
					UIPreviewHelper.model_cache[model_path] = scene
					for wr in UIPreviewHelper._pending.get(model_path, []):
						var vp: Node = wr.get_ref()
						if is_instance_valid(vp):
							var model: Node3D = scene.instantiate()
							vp.add_child(model)
							UIPreviewHelper._normalize_preview_model(model, 1.1)
				UIPreviewHelper._pending.erase(model_path)
				queue_free()
			ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				push_error("AsyncModelLoader: Failed to load model at: " + model_path)
				UIPreviewHelper._pending.erase(model_path)
				queue_free()

## Modeli arka planda ister; aynı yol zaten yükleniyorsa yalnız bekleyen listesine ekler.
static func _request_async(model_path: String, viewport: SubViewport) -> bool:
	if _pending.has(model_path):
		_pending[model_path].append(weakref(viewport))
		return true
	if ResourceLoader.load_threaded_request(model_path) != OK:
		return false
	_pending[model_path] = [weakref(viewport)]
	var loader := AsyncModelLoader.new()
	loader.model_path = model_path
	(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(loader)
	return true

## Çıkışta hâlâ süren yüklemeleri toplar (bloklar — yalnız kapanışta çağrılır).
static func flush_pending() -> void:
	for path in _pending:
		ResourceLoader.load_threaded_get(path)
	_pending.clear()

static func create_3d_preview(model_path: String, viewport_size: Vector2 = Vector2(70, 70)) -> SubViewportContainer:

	var container = SubViewportContainer.new()
	container.custom_minimum_size = viewport_size
	container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	container.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var viewport = SubViewport.new()
	viewport.size = viewport_size
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	
	var world = World3D.new()
	viewport.world_3d = world
	
	var light = DirectionalLight3D.new()
	light.light_energy = 2.6
	light.rotation_degrees = Vector3(-35, 45, 0)
	viewport.add_child(light)
	
	var fill_light = DirectionalLight3D.new()
	fill_light.light_energy = 1.6
	fill_light.rotation_degrees = Vector3(35, -135, 0)
	viewport.add_child(fill_light)
	
	var env = Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.65)
	env.ambient_light_energy = 2.0
	
	var env_node = WorldEnvironment.new()
	env_node.environment = env
	viewport.add_child(env_node)
	
	var camera = Camera3D.new()
	camera.position = Vector3(0, 0.55, 1.6)
	camera.rotation_degrees = Vector3(-10, 0, 0)
	camera.fov = 40.0
	viewport.add_child(camera)
	
	if model_cache.has(model_path):
		var model_scene = model_cache[model_path]
		if model_scene:
			var model = model_scene.instantiate()
			viewport.add_child(model)
			_normalize_preview_model(model, 1.1)
	else:
		if ResourceLoader.exists(model_path):
			if not _request_async(model_path, viewport):
				var model_scene = load(model_path)
				if model_scene:
					model_cache[model_path] = model_scene
					var model = model_scene.instantiate()
					viewport.add_child(model)
					_normalize_preview_model(model, 1.1)
		elif model_path != "":
			# Boş yol (henüz 3D modeli eklenmemiş birim) beklenen/bilinen bir durum — uyarı basma.
			# Deploy listesi bu birimleri zaten filtreliyor (deploy_panel.gd); Guide/Codex ise TÜM
			# roster'ı gösterdiği için burada boş bir önizleme alanıyla sessizce devam eder.
			push_warning("UIPreviewHelper: Model path does not exist: %s" % model_path)
		
	return container

## Modeli ölçekler ve KAMERAYI ona göre çerçeveler — her birim penceresinin tam ortasında,
## aynı doluluk oranında görünür.
##
## ESKİ SORUN (kullanıcı bildirimi: "unit görselleri tam ortaya denk gelmiyor"): model sınır
## kutusunun merkezi dünya merkezine taşınıyor, kamera ise SABİT konumda ve 10° aşağı bakıyordu.
## Kamera merkeze bakmadığı ve boy/en oranları farklı olduğu için iri birimler kenara, ince
## birimler aşağı kayıyordu. Artık: ayaklar zeminde (y=0), yatayda tam ortada; kamera modelin
## yarı boyuna bakar ve uzaklığı hem dikey hem yatay görüş açısına göre seçilir (sığmayan yön belirler).
static func _normalize_preview_model(model_root: Node3D, target_height: float = 1.1) -> void:
	var aabb = _calculate_recursive_aabb(model_root, model_root)
	if aabb.size.y <= 0.001:
		model_root.scale = Vector3.ONE
		model_root.position = Vector3.ZERO
		return
	var s: float = target_height / aabb.size.y
	model_root.scale = Vector3.ONE * s
	var c: Vector3 = aabb.get_center() * s
	model_root.position = Vector3(-c.x, -aabb.position.y * s, -c.z)

	var viewport := model_root.get_parent() as SubViewport
	var cam: Camera3D = null
	if viewport:
		for n in viewport.get_children():
			if n is Camera3D:
				cam = n
	if cam == null:
		return
	var h: float = aabb.size.y * s
	var w: float = maxf(aabb.size.x, aabb.size.z) * s
	var aspect: float = float(viewport.size.x) / maxf(1.0, float(viewport.size.y))
	var vfov: float = deg_to_rad(cam.fov)
	var hfov: float = 2.0 * atan(tan(vfov * 0.5) * aspect)
	var margin := 1.04
	var dist: float = maxf((h * 0.5) / tan(vfov * 0.5), (w * 0.5) / tan(hfov * 0.5)) * margin
	cam.position = Vector3(0.0, h * 0.5, dist + aabb.size.z * s * 0.5)
	cam.rotation = Vector3.ZERO

static func _calculate_recursive_aabb(node: Node, model_root: Node3D) -> AABB:
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

static func _get_relative_transform(node: Node, ancestor: Node) -> Transform3D:
	var t = Transform3D.IDENTITY
	var curr = node
	while curr != ancestor and curr != null:
		if curr is Node3D:
			t = curr.transform * t
		curr = curr.get_parent()
	return t
