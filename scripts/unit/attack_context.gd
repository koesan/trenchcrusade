## Bir Saldırı Aksiyonunun (Shoot / Fight) tüm çözümleme durumu.
##
## `unit.gd::server_request_attack_action` 231 satırlık, erken-dönüşlerle dolu bir prosedürdü.
## Adımlar ayrı fonksiyonlara bölünürken aralarında taşınan durum bu nesnede toplandı — böylece
## her fazın imzası tek parametreye indi ve yeni bir faz eklemek çağrı zincirini değiştirmiyor.
class_name AttackContext
extends RefCounted

## Saldıran birim düğümü.
var attacker = null
## Hedef birim düğümü. Dost ateşi yönlendirmesi bunu DEĞİŞTİREBİLİR.
var enemy = null
## Kullanılan silah (AttackData).
var atk: Resource = null
## Yakın dövüş mü?
var is_melee: bool = false
## Saldırı anındaki mesafe (inç).
var dist: float = 0.0

## `DicePoolBuilder.build_attack_context()` çıktısı — Injury Roll'a `is_long_range`/`in_cover`
## bayraklarını taşımak için de kullanılır (Glorious Deeds).
var pool_ctx: Dictionary = {}
## Success Roll'a uygulanacak toplam DICE modifikatörü.
var modifier: int = 0
## Bu saldırı bir Diving Charge bonusu tüketti mi? (Yalnız melee; Injury'ye DEĞİL, Success'e etkir.)
var diving: bool = false

## Success Roll toplamı.
var total_roll: int = 0
## Kritik başarı mı? (Eşik silaha/hedefe göre değişir — bkz. Pain Amplifier.)
var is_crit: bool = false

## Bu saldırı için `actions_taken`e eklenen anahtar ("melee" / "shoot").
var action_key: String = ""
