## Saldırı/silah tanımı Resource sınıfı.
## Her saldırı türü için ayrı .tres dosyası oluşturulur.
## Inspector üzerinden kolayca düzenlenebilir.
## FAZ 1: Tüm silah keyword'leri boolean flag olarak eklendi.
## String karşılaştırma yerine bu flag'ler kullanılmalıdır.
class_name AttackData
extends Resource

@export var attack_name: String = ""
@export var attack_range: float = 2.0
@export var description: String = ""
## MELEE dışındaki her değer (RANGED, AREA) dice_pool_builder.gd'de menzilli saldırı
## olarak işlenir (is_melee = attack_type == "MELEE"). AREA, gerçek BLAST davranışı için
## is_blast=true + blast_radius > 0 ile birlikte kullanılmalıdır (unit.gd request_attack_action
## bu iki alana bakar, attack_type'a değil). Yer (boş nokta) hedefleme UI'ı henüz yok —
## AREA saldırılar şu an sadece bir birim hedeflenerek kullanılabilir.
@export_enum("MELEE", "RANGED", "AREA") var attack_type: String = "MELEE"

## Silahın kaç el gerektirdiği. LoadoutResolver (scripts/rules/loadout_resolver.gd) bu alana
## göre bir unit'in aynı anda taşıyabileceği silah sayısını doğrular (1x2H veya 2x1H per kategori).
@export_enum("1H", "2H") var hands: String = "1H"

# ── TEMEL KEYWORD FLAGS ─────────────────────────────────────────────────────
@export_group("Weapon Keywords")

## ASSAULT: Hücum (Charge) sonrası kullanılabilir; ayrıca angaje iken ateş edilebilir.
@export var is_assault: bool = false

## IGNORE COVER: Siper (-1 DICE) cezasını yok sayar.
@export var ignore_cover: bool = false

## IGNORE ARMOUR: Hedefin Armour modifikatörünü yok sayar.
@export var ignore_armour: bool = false

## SNIPER: Uzun menzil (-1 DICE) cezasını yok sayar.
@export var is_sniper: bool = false

## DEADLY: Bloodbath Roll sırasında 4D6 atılır (normal 3D6 yerine).
@export var is_deadly: bool = false

## CUMBERSOME: Bu silahla aynı aktivasyonda Dash aksiyonu yapılamaz.
@export var is_cumbersome: bool = false

## BLAST: Patlama silahı. Hedef ve yarıçaptaki diğer modeller etkilenir.
@export var is_blast: bool = false

## BLAST yarıçapı (inç cinsinden). is_blast=true ise geçerli.
@export var blast_radius: float = 0.0

## CLEAVE: İsabet sonrası ek yakın dövüş saldırısı hakkı kazandırır.
@export var has_cleave: bool = false

## CLEAVE(X) değeri — kaç adet ek hedef saldırılabilir.
@export var cleave_count: int = 1

## Bu silaha özgü Success Roll DICE modifikatörü (birim istatistiklerine ek olarak).
## Örnek: Feeble Flailing (silahsız yumruk) = -1. Çoğu silahta 0.
@export var dice_modifier: int = 0

# ── HASAR MODİFİKATÖRLERİ ───────────────────────────────────────────────────
@export_group("Injury Modifiers")

## Bu silahla yapılan saldırılarda Injury Roll'a eklenen +/- INJURY DICE.
## Örnek: Sniper Rifle = +1, Musket = -1, Anti-Tank Hammer = +2
@export var injury_dice_modifier: int = 0

# ── ATEŞ TIPI ────────────────────────────────────────────────────────────────
@export_group("Damage Type")

## FIRE: Yangın hasarı. Undead Fortitude'u atlar, bazı özel birimlere ek etki.
@export var is_fire: bool = false

## POISON/GAS: Zehir veya gaz hasarı. Özel kurallar için.
@export var is_poison: bool = false

# ── GENEL KEYWORD SÖZLÜĞÜ ────────────────────────────────────────────────────
@export_group("Generic Keywords")

## Yukarıdaki adlandırılmış flag'lerin kapsamadığı her silah keyword'ü için genel depo.
## Anahtar: keyword adı (örn. &"armour_piercing", &"automatic", &"shotgun").
## Değer: int — flag-tipi keyword'ler için 1, X-değerli keyword'ler için X
## (örn. AUTOMATIC(3) → keywords[&"automatic"] = 3). KeywordSystem.has()/value() ile okunur.
@export var keywords: Dictionary = {}
