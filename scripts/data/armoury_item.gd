## ArmouryItem — Compendium'daki bir **Battlekit** kaleminin veri tanımı.
##
## KURAL KAYNAĞI (warbands/*/#Armoury tabloları + battlekit/*.md kural blokları):
## Her faksiyonun kendi Armoury Tablosu vardır. Bir kalem yalnızca modelin faksiyonunun
## tablosunda listeleniyorsa satın alınabilir; tabloda ayrıca fiyat, `LIMIT: N` (warband
## başına üst sınır) ve "Elite only" / "<Birim> only" gibi kısıtlar yer alır.
##
## Bu kaynak SADECE VERİ tutar — karar mantığı `ArmouryRules` içindedir (saf, durumsuz).
class_name ArmouryItem
extends Resource

## UI'daki sekmeler bu sıraya göre çizilir (compendium tablo sırası).
enum Category { MELEE, RANGED, GRENADE, ARMOUR, SHIELD, EQUIPMENT }

## Compendium: "Some pieces of Battlekit cost Glory Points instead of ducats."
enum Currency { DUCAT, GLORY }

@export var item_id: StringName = &""

## Lokalizasyon anahtarları — metin ASLA koda gömülmez.
## Silahlarda bunlar doğrudan `AttackData.attack_name` / `.description` anahtarlarıdır,
## böylece aynı silahın adı iki yerde ayrı ayrı çevrilmez.
@export var name_key: String = ""
@export var desc_key: String = ""

@export var category: Category = Category.EQUIPMENT
@export var cost: int = 0
@export var cost_currency: Currency = Currency.DUCAT

## Compendium'daki `LIMIT: N`. 0 = sınırsız.
@export var limit_per_warband: int = 0

## "Elite only" kısıtı — model `[Elite]` anahtar kelimesini taşımalı.
@export var elite_only: bool = false

## "Janissary only", "Brazen Bull only" gibi birim adına bağlı kısıtlar (boşsa kısıt yok).
@export var required_unit_names: Array[String] = []

## "BAYONET LUG only" gibi, modelin sahip olması gereken anahtar kelimeler.
@export var required_keywords: Array[StringName] = []

## "Machine Armour only" gibi, önce alınmış olması gereken başka bir Armoury kalemi.
@export var required_item_id: StringName = &""

## HEADGEAR (warband-battlekit.md): "A model cannot have more than one piece of Headgear (even if
## it has more than one head!)." Compendium dışa aktarımı "(Headgear)" işaretini taşımadığından
## kafaya giyilen kalemler (miğfer, gaz maskesi, taç, kapirot) adlarından işaretlendi.
@export var is_headgear: bool = false

## Kısıtın oyuncuya gösterilecek hâli (lokalizasyon anahtarı; kısıt yoksa boş).
@export var restriction_key: String = ""

@export_group("Effect")
## Silah kalemleri: modele eklenen saldırı profilleri (AttackData).
@export var granted_attacks: Array[Resource] = []
## Zırh/kalkan kalemleri: `[-N Injury Modifier]` → modelin `armour` değeri.
@export var armour_value: int = 0
## Teçhizat kalemleri: modele eklenen anahtar kelimeler (KeywordSystem okur).
@export var granted_keywords: Dictionary = {}
## Kalemin işgal ettiği el sayısı (silahlar için LoadoutResolver el bütçesini denetler).
@export var hands: int = 0
