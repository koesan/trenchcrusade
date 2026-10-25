## Arazi parçası (terrain piece) tanımı — Resource.
##
## Compendium (comprehensive-rules/terrain.md) arazi parçalarını KEYWORD'lerle tanımlar:
## `[Cover]`, `[Mined]`, `[Impassable]` vb. Bu Resource, sahaya yerleştirilebilen her arazi
## nesnesinin görselini, etki yarıçapını ve taşıdığı keyword'leri TEK yerde tutar.
##
## Yeni bir arazi tipi eklemek script düzenlemesi gerektirmez — yalnız yeni bir `.tres`
## (UnitData / AttackData / AbilityData ile aynı veri-güdümlü desen).
##
## Keyword'ler `KeywordSystem.has()` ile okunur; sorgular `TerrainManager` üzerinden yapılır.
class_name TerrainFeatureData
extends Resource

## Benzersiz kimlik (örn. &"mine", &"trench").
@export var feature_id: StringName = &""

# ── SUNUM ────────────────────────────────────────────────────────────────────
@export_group("Presentation")

## Yerelleştirme anahtarları — metin ASLA koda/veriye gömülmez.
@export var display_name_key: String = ""
@export var desc_key: String = ""

## 3B model (.glb) yolu. Boşsa yalnız yarıçap halkası çizilir.
@export var model_path: String = ""

## Modelin ölçeği (GLB'ler farklı birim ölçeklerinde gelebilir).
@export var model_scale: float = 1.0

## Zemine göre Y ofseti — model zemine gömülmesin / havada durmasın.
@export var y_offset: float = 0.0

## Sahada gösterilecek etki halkası rengi.
@export var ring_color: Color = Color(0.85, 0.75, 0.35, 1.0)

# ── KURAL ────────────────────────────────────────────────────────────────────
@export_group("Rules")

## Etki yarıçapı (inç). Compendium'da arazi parçaları "on, in or within 1\"" mantığıyla
## ölçülür; bu yarıçap "bu parçanın üzerinde/içinde sayılır" alanını tanımlar.
@export var radius: float = 1.0

## Keyword deposu: &"mined", &"cover", &"impassable"... KeywordSystem.has() ile okunur.
## Yeni bir arazi kuralı eklemek yalnız buraya bir anahtar eklemeyi gerektirir.
@export var keywords: Dictionary = {}

## Bu parça tetiklendiğinde (örn. mayın patlaması) tüketilip sahadan kalkar mı?
@export var is_consumed_on_trigger: bool = false
