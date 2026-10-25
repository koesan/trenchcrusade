## Bir senaryoda ÖNCEDEN yerleştirilmiş arazi parçası — Resource.
##
## `ScenarioData.terrain_placements` dizisinde kullanılır: senaryo yüklendiğinde
## `game.gd` bu listeyi gezip `TerrainManager.spawn_feature()` çağırır.
##
## Oyun sırasında OLUŞTURULAN arazi parçaları (örn. Sultanate Sapper'ın kurduğu mayın)
## bu Resource'u kullanmaz — doğrudan `TerrainManager.spawn_feature()` ile eklenir.
class_name TerrainPlacement
extends Resource

## Yerleştirilecek arazi tanımı (TerrainFeatureData).
@export var feature: Resource = null

## Sahadaki konum (XZ düzlemi; Y zemin yüksekliğine göre TerrainFeature tarafından ayarlanır).
@export var position: Vector3 = Vector3.ZERO

## Y ekseni etrafında dönüş (radyan) — siperlerin farklı yönlere bakması için.
@export var rotation_y: float = 0.0
