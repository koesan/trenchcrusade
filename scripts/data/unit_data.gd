## Birim istatistikleri Resource sınıfı.
## Her birim türü için ayrı .tres dosyası oluşturulur.
## Yeni birim eklemek script düzenlemesi gerektirmez — sadece yeni bir .tres dosyası oluşturun.
## FAZ 1: Unit keyword flag'leri ve abilities array'i eklendi.
class_name UnitData
extends Resource

@export var unit_name: String = ""
@export var faction_id: StringName = &""

## Warband puan bütçesinden düşülen maliyet (compendium: "Cost"). Varsayılan 0 —
## puan ekonomisi bu birimi ücretsiz sayar (kullanıcı gerçek değeri elle girecek).
@export var cost: int = 0

## `cost`'un içindeki HAZIR TEÇHİZAT payı (compendium denetimi, Adım 2). Compendium "can have any
## Battlekit" diyen birimlerin silahlarını AYRICA cephanelik fiyatından satın aldırır; oyun bu
## birimleri hazır bir silah takımıyla sunduğu için o takımın faction cephaneliğindeki fiyatı
## `cost`'a eklenir. Yani `cost - kit_cost` = compendium profilindeki "Cost". "Always has"
## (kendi teçhizatı fiyata dâhil) birimlerde 0'dır. Bkz. tests/cases/kit_pricing_test.gd.
@export var kit_cost: int = 0

## BİRİME ÖZEL BATTLEKIT KISITI (compendium her birimin "Battlekit" paragrafı). Boş = faction
## cephaneliğinden her şey alınabilir. Anahtarlar (`ArmouryRules.battlekit_rule_reason` okur):
##   "none": true            → hiçbir Battlekit alamaz ("cannot have any (other) Battlekit")
##   "categories": [int]     → yalnız bu ArmouryItem.Category'ler (anahtar varsa liste boş da olabilir)
##   "items": [StringName]   → kategori kısıtına rağmen alınabilen istisnalar (örn. Wind Amulet)
##   "ranged_only": [id]     → menzilli silah olarak yalnız bunlar
##   "grenade_only": [id]    → el bombası olarak yalnız bunlar
##   "forbid": [id]          → bu kalemler alınamaz
##   "max_cost": int         → kalem fiyatı en fazla bu kadar (Wretched: 10)
##   "max_ranged": int, "ranged_max_cost": int → menzilli silah adedi/fiyat tavanı (Yoke Fiend)
##   "heavy_weapons_only": true → silahlar [Heavy] taşımalı (Brazen Bull)
##   "melee_hand_budget": int → yakın dövüş el bütçesi (Hunter: Bow of Lethe bir eli hep tutar)
@export var battlekit_rules: Dictionary = {}

## Maliyetin PARA BİRİMİ. Compendium (recruit-your-warband.md): "Some models and pieces of
## Battlekit cost Glory Points () INSTEAD OF ()" ve "Mercenaries... cannot be purchased
## with ". İki havuz birbirinin yerine GEÇMEZ; kural mantığı EconomyRules'tadır.
## Mercenary birimlerin Cost'u GLORY, normal roster birimlerinin DUCAT'tır.
enum Currency { DUCAT, GLORY }
@export var cost_currency: Currency = Currency.DUCAT

## HİZALAMA — yalnız MERCENARY birimlerde anlamlıdır (normal roster birimleri zaten
## faksiyonlarının hizalamasını taşır). 0 = nötr (her iki tarafa da hizmet eder),
## 1 = FAITHFUL, 2 = FALLEN. Kural mantığı AlignmentRules'ta.
@export var alignment: int = 0

## G4.2: Warband'da bu birim tipinden en fazla kaç adet bulunabilir (compendium "Availability").
## 999 = Unlimited. Deploy sırasında GameState.can_deploy_unit_type() ile denetlenir.
@export var availability_max: int = 999

@export var movement_range: float = 6.0
@export var speed: float = 6.0

## Zırh seviyesi. Injury Roll'a flat modifier olarak uygulanır.
## 0 = Zırhsız (No Armour), 1 = Hafif (-1), 2 = Orta (-2), 3 = Ağır (-3)
@export var armour: int = 0

@export var melee_dice_modifier: int = 0
@export var ranged_dice_modifier: int = 0
@export var model_scene_path: String = ""

# ── BİRİM KEYWORD FLAGS ──────────────────────────────────────────────────────
@export_group("Unit Keywords")

## CAPTAIN ELIGIBILITY: Bu birim warband kaptanı olarak seçilebilir.
## [Leader] keyword efekti (+1 Morale Dice) keywords sözlüğünde ayrıca tanımlanır.
@export var is_leader: bool = false

## TOUGH: İlk Out of Action sonucunu Down olarak alır (bir kez kullanılabilir).
@export var has_tough: bool = false

## MEMENTO MORI: İlk Out of Action sonucunu etkisiz sayar (War Prophet'e özgü).
@export var has_memento_mori: bool = false

## UNDEAD FORTITUDE: Ateş hasarı olmayan saldırılarda Injury Roll'a -1 INJURY DICE.
@export var has_undead_fortitude: bool = false

## FEAR: Bu birim, başarısız moral testinde düşmanı etkiler (ileriki fazda kullanılacak).
@export var has_fear: bool = false

## REGENERATION: Aktivasyon başında 1 Blood Marker kaldırır (Communicant).
@export var has_regeneration: bool = false

## DISEASE CARRIER: 1\" yakınında aktive olan düşmanlar +1 Infection Marker alır.
@export var is_disease_carrier: bool = false




# ── ÖZEL YETENEKLERİ ─────────────────────────────────────────────────────────
@export_group("Abilities & Attacks")

## Birime ait özel yetenek Resource'ları. Her biri bir AbilityData .tres dosyasıdır.
## Yeni yetenek eklemek için sadece bu array'e .tres ekle.
@export var abilities: Array[Resource] = []

## Birime ait saldırılar. Her biri bir AttackData .tres dosyasıdır.
@export var attacks: Array[Resource] = []

## FAZ 5 (P1-1): Opsiyonel Battlekit/loadout seçenekleri (LoadoutOption). Doluysa deploy öncesi
## oyuncu bunlardan birini seçer (LoadoutResolver.resolve_loadout). Boşsa mevcut sabit attacks[]/
## armour davranışı DEĞİŞMEZ — geriye dönük tam uyumlu.
@export var loadout_options: Array[Resource] = []

# ── GENEL KEYWORD SÖZLÜĞÜ ────────────────────────────────────────────────────
@export_group("Generic Keywords")

## Yukarıdaki adlandırılmış flag'lerin kapsamadığı her keyword için genel depo.
## Anahtar: keyword adı (örn. &"armour_piercing", &"skirmisher", &"strong").
## Değer: int — flag-tipi keyword'ler için 1, X-değerli keyword'ler için X
## (örn. BLESSED(2) → keywords[&"blessed"] = 2). KeywordSystem.has()/value() ile okunur.
@export var keywords: Dictionary = {}
