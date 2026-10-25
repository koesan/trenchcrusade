## Senaryo tanımı — Resource. Bir senaryonun TÜM bilgisini tutar.
##
## Yeni senaryo eklemek için: yeni bir .tres oluştur (script düzenlemesi gerekmez). Farklı
## senaryolar farklı tur limiti, deployment bölgeleri, görevler, zafer koşulları ve — özel
## mekanik gerekiyorsa — bir `logic_script` (ScenarioLogic türevi) tanımlayabilir.
##
## Bkz. scripts/rules/scenario_logic.gd (davranış) ve scripts/scenario/scenario_manager.gd (yönetim).
class_name ScenarioData
extends Resource

## Zafer koşulu tipi. ELIMINATION = yalnız kırım/kaçış; OBJECTIVE_VP = tur sonu objective VP'si.
enum VictoryType { ELIMINATION, OBJECTIVE_VP }

# ── KİMLİK & SUNUM ───────────────────────────────────────────────────────────
@export var scenario_id: StringName = &""
## Senaryo adı yerelleştirme anahtarı (seçim kartında ve HUD'da gösterilir).
@export var scenario_name_key: String = "SCENARIO"
## Senaryo açıklaması yerelleştirme anahtarı.
@export var scenario_desc_key: String = "SCENARIO_DESC"
## Seçim kartı görseli (opsiyonel).
@export var banner: Texture2D = null

# ── OYUN KURALLARI ───────────────────────────────────────────────────────────
@export_group("Game Rules")
## Toplam tur sayısı. 0 = sınırsız (yalnız kırım/kaçış ile biter).
@export var turn_limit: int = 4
## Bu senaryo için warband puan bütçesi (GameState.points_budget'i geçersiz kılar).
## Compendium (warbands/starting-a-warband.md): "Usually you will have 700 Ducats to spend."
@export var points_budget: int = 700
## Bu senaryo için Glory Point bütçesi. Compendium (recruit-your-warband.md): "Generally,
## Warbands don't have access to when they are first created" (kampanya varsayımı). Kampanya
## olmadığından mercenary'lere erişim için senaryolar küçük bir bütçe (10) verir.
@export var glory_budget: int = 0
## Sızıcı (Infiltrator) özel yerleşimi bu senaryoda serbest mi?
@export var infiltrators_allowed: bool = false

# ── DEPLOYMENT BÖLGELERİ (XZ düzlemi Rect2) ──────────────────────────────────
@export_group("Deployment Zones")
## Oyuncu 1 yerleşim bölgesi. Rect2(x=minX, y=minZ, size=(genişlikX, derinlikZ)).
## Bir konum geçerli sayılır ancak (pos.x, pos.z) bu dikdörtgenin içindeyse.
@export var p1_deploy_zone: Rect2 = Rect2(-40, -40, 38, 80)
## Oyuncu 2 yerleşim bölgesi.
@export var p2_deploy_zone: Rect2 = Rect2(2, -40, 38, 80)

# ── GÖREVLER & ZAFER ─────────────────────────────────────────────────────────
@export_group("Objectives & Victory")
@export var victory_type: VictoryType = VictoryType.ELIMINATION
## ScenarioObjective listesi. Objective marker'ları bu listeye göre sahaya yerleştirilir.
@export var objectives: Array[Resource] = []

## TerrainPlacement listesi — senaryoda ÖNCEDEN yerleştirilmiş arazi parçaları (siper vb.).
## game.gd senaryo yüklenirken bu listeyi gezip TerrainManager.spawn_feature() çağırır.
## Oyun sırasında oluşturulan parçalar (Set Mine) bu listeye girmez.
@export var terrain_placements: Array[Resource] = []

# ── GENİŞLETİLEBİLİRLİK ──────────────────────────────────────────────────────
@export_group("Extensibility")
## Opsiyonel özel senaryo mantığı (ScenarioLogic türevi bir Script). Boşsa taban
## ScenarioLogic kullanılır. Özel mekanikler (Glorious Deeds, özel kazanma vb.) burada tanımlanır.
@export var logic_script: Script = null
## Serbest biçimli özel kural bayrakları — senaryoya özgü mekanikler için (data-driven).
@export var special_rules: Dictionary = {}
