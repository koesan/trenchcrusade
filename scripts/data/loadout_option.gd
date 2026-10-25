## LoadoutOption — Trench Crusade Battlekit/Armoury seçim kalemi (FAZ 5, P1-1).
##
## Compendium (warband-battlekit.md): "When you recruit a model for your Warband, you can also
## purchase Battlekit for the model." Bu proje fixed-roster olduğu için tam Armoury satın alma
## sistemi yerine, birimin `UnitData.loadout_options` dizisi doluysa deploy öncesi oyuncu bunlardan
## BİRİNİ seçer (LoadoutResolver.resolve_loadout uygular). Boşsa mevcut davranış DEĞİŞMEZ.
class_name LoadoutOption
extends Resource

## Seçim panelinde gösterilecek yerelleştirme anahtarı.
@export var option_name_key: String = ""

## Doluysa UnitData.attacks'in YERİNE geçer (bu seçeneğin TAM silah listesi — birimin sabit
## silahları da dahil edilmeli, örn. Mamluk Faris'in her seçeneğinde Jezzail tekrar listelenir).
## Boşsa birimin mevcut attacks[]'i değişmeden kalır (örn. sadece bir terfi/ek maliyet seçeneği).
@export var attacks_override: Array[Resource] = []

## -1 = değiştirme; >=0 ise UnitData.armour'u bu değere değiştirir (örn. Kalkan +1 zırh seviyesi).
@export var armour_override: int = -1

## Bu seçenek seçilirse UnitData.melee_dice_modifier/ranged_dice_modifier'a EKLENİR (0 = değişiklik
## yok). Compendium'daki "+1 Dice to Ranged OR Melee Attacks, seçiminize göre" tarzı terfiler için
## (örn. Plague Knight'ın Knight Companion of the Fly'ı) İKİ ayrı LoadoutOption olarak modellenir —
## biri melee_dice_delta=1, diğeri ranged_dice_delta=1.
@export var melee_dice_delta: int = 0
@export var ranged_dice_delta: int = 0

## Bu seçenek seçilirse UnitData.cost'a eklenir (negatif de olabilir; compendium çoğu seçenekte 0).
@export var cost_delta: int = 0

## Bu seçenek seçilirse UnitData.keywords'e BİRLEŞTİRİLİR (üzerine yazar, silmez).
@export var extra_keywords: Dictionary = {}

## Bu seçenek seçilirse UnitData.abilities dizisine EKLENİR. Compendium'da SATIN ALINAN
## yetenekler için: Ecclesiastic Prisoner'ın Martyrdom Device'ı (35 , LIMIT 4) ve Court'un
## Goetic Power'ları (Slavemaster 10 , Burning Inferno 15 ). Bu yetenekler birime GÖMÜLÜ
## olmamalıdır — compendium onları ücretli ve sayısı sınırlı birer seçim olarak tanımlar.
@export var extra_abilities: Array[Resource] = []

## Warband genelinde bu seçeneğin (veya limit_group paylaşan seçeneklerin TOPLAMININ) en fazla
## kaç kez seçilebileceği. 999 = sınırsız (varsayılan).
@export var max_per_warband: int = 999

## Doluysa, aynı grup adını taşıyan TÜM seçenekler `max_per_warband` sayımında BİRLİKTE sayılır
## (örn. Yeoman'ın "Trench Mole" ve "Rifle + Trench Mole" seçenekleri aynı grubu paylaşır —
## hangisini seçerse seçsin toplam Trench Mole sayısı 2'yi geçemez). Boşsa yalnız kendi başına sayılır.
@export var limit_group: StringName = &""
