extends Node

## TerrainManager — sahadaki arazi parçalarının TEK kaydı (autoload).
##
## `GameState.units`in arazi karşılığıdır, ama AYRI bir dosyada: GameState zaten 590+ satır
## ve bir "god file"a dönüşmemeli. Bu sınıf yalnız KAYIT TUTAR ve SORGULAR; kural kararları
## `MineResolver` / `DeployRules` / `DicePoolBuilder` tarafında verilir.
##
## Sahaya iki yoldan parça gelir:
##   1. Senaryo yüklenirken — `ScenarioData.terrain_placements` (game.gd)
##   2. Oyun sırasında — Sultanate Sapper / Combat Engineer'ın Set Mine aksiyonu (MineActions)

const TERRAIN_FEATURE_SCENE := preload("res://scenes/scenario/terrain_feature.tscn")

## Sahadaki aktif arazi parçaları (TerrainFeature node'ları).
var features: Array[Node] = []

## Parçaların ekleneceği konteyner. Boşsa aktif sahneye eklenir.
var container: Node = null

func clear_all() -> void:
	for f in features:
		if is_instance_valid(f):
			f.queue_free()
	features.clear()

func feature_count() -> int:
	var n := 0
	for f in features:
		if is_instance_valid(f) and f.is_active:
			n += 1
	return n

## Sahaya yeni bir arazi parçası koyar ve node'unu döndürür.
## setter_name: mayını kuran birimin node adı ("" = senaryo yerleşimi).
func spawn_feature(data: Resource, pos: Vector3, setter_name: String = "", rotation_y: float = 0.0) -> Node:
	if data == null:
		return null
	var node: Node3D = TERRAIN_FEATURE_SCENE.instantiate()
	var parent: Node = container if is_instance_valid(container) else get_tree().current_scene
	if parent == null:
		parent = self
	parent.add_child(node)
	# Konumu HARİTA YÜZEYINE oturt: NavigationServer'ın en yakın noktasını al —
	# bu, birimin ayak pozisyonundan daha güvenilirdir (birim eğimli zeminde durabilir
	# ve Y ekseni haritanın iç yüzeyine denk gelebilir).
	# Güvenlik: NavMesh yoksa (headless test, senaryo yüklenmemiş) map_get_closest_point
	# sıfır/saçma bir konum döner — yalnız aktif NavMesh varken uygula.
	if get_tree() and get_tree().root:
		var w3d: World3D = get_tree().root.get_world_3d()
		if w3d:
			var map_rid: RID = w3d.navigation_map
			if map_rid.is_valid() and NavigationServer3D.map_get_regions(map_rid).size() > 0:
				var nav_pos: Vector3 = NavigationServer3D.map_get_closest_point(map_rid, pos)
				pos = nav_pos
	node.global_position = pos
	node.rotation.y = rotation_y
	node.setup(data, setter_name)
	features.append(node)
	GameLogger.log_info("[Terrain] '%s' yerleştirildi: %s%s" \
		% [String(data.feature_id), str(pos),
		(" (kuran: %s)" % setter_name) if setter_name != "" else ""], "GAME")
	return node

## Verilen konumdaki (yarıçap içindeki) AKTİF parçaları döndürür.
func features_at(pos: Vector3) -> Array[Node]:
	var out: Array[Node] = []
	for f in features:
		if not is_instance_valid(f) or not f.is_active or f.feature_data == null:
			continue
		if f.global_position.distance_to(pos) <= f.feature_data.radius:
			out.append(f)
	return out

## Bu konumda verilen keyword'ü taşıyan bir arazi parçası var mı?
## Örn. `has_keyword_at(unit.global_position, &"cover")` → siperde mi?
func has_keyword_at(pos: Vector3, kw: StringName) -> bool:
	for f in features_at(pos):
		if KeywordSystem.has(f.feature_data, kw):
			return true
	return false

## Bu konumdaki ilk parçayı kuran birimin adı ("" = yok / senaryo yerleşimi).
func setter_of(pos: Vector3) -> String:
	for f in features_at(pos):
		return f.setter_unit_name
	return ""

## Bu konumdaki (ilk) parçayı tüketir — mayın patladığında/etkisizleştirildiğinde.
## `is_consumed_on_trigger` false olan parçalar (siper) tüketilmez.
func consume_at(pos: Vector3) -> void:
	for f in features_at(pos):
		if f.feature_data != null and not f.feature_data.is_consumed_on_trigger:
			continue
		features.erase(f)
		f.consume()
		return

## Bu konumdaki parçadan yalnız `[Mined]` bayrağını kaldırır (Defuse Mine).
## Compendium: "the Marker or terrain piece LOSES the [Mined] Keyword" — parça yerinde kalır.
func defuse_at(pos: Vector3) -> bool:
	for f in features_at(pos):
		if f.feature_data == null or not KeywordSystem.has(f.feature_data, &"mined"):
			continue
		features.erase(f)
		f.consume()
		return true
	return false
