## Senaryo Objective (görev noktası) tanımı — Resource.
## Her objective marker için bir .tres (veya ScenarioData içinde gömülü) oluşturulur.
## Compendium (Claim No Man's Land): objective, bir arazi parçasını temsil eder; kontrol,
## o parçanın 1" içindeki dost/düşman model sayısına göre belirlenir.
class_name ScenarioObjective
extends Resource

## Benzersiz kimlik (VP takibi ve senkron için).
@export var objective_id: StringName = &""

## Yerelleştirme anahtarı (objectives panelinde gösterilir).
@export var label_key: String = "OBJECTIVE"

## Sahadaki konum (XZ düzlemi; Y genelde 0). Objective marker bu noktaya yerleştirilir.
@export var position: Vector3 = Vector3.ZERO

## Kontrol yarıçapı (dünya birimi). Compendium'daki "arazi parçası + 1 inç"in dijital
## karşılığı. Bu yarıçap içindeki modeller kontrol sayımına dahil edilir.
@export var control_radius: float = 3.0

## Kontrol eden oyuncunun her tur sonunda kazandığı Zafer Puanı (VP).
@export var vp_per_turn: int = 2
