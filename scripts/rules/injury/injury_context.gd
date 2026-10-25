## Bir Yara Zarı (Injury Roll) çözümlemesinin TÜM durumu — tetikleyicilere geçirilen bağlam.
##
## NEDEN VAR: `unit.gd::resolve_injury_roll` 306 satırdı ve gövdesinin çoğu ARDIŞIK, birbirinden
## bağımsız ~11 özel kural bloğuydu (Slashing Attack, Inflict Pain, Whip of God, Prize Specimens,
## Dark Blessing, Beelzebub's Touch, Parasite Host, Law of Hell, Glorious Deeds…). Her yeni birim
## kuralı oraya bir `if KeywordSystem.has(...)` bloğu daha ekliyordu; hiçbiri tek başına test
## edilemiyordu ve dosya tavana dayanmıştı.
##
## Bu nesne, o blokların okuyup YAZDIĞI ortak durumu taşır. Alanların çoğu MUTABLE'dır —
## tetikleyiciler kasıtlı olarak bunları değiştirir (ör. Oracle Beast Cloak `raw_outcome`u
## NO_EFFECT'e çevirir, Serpent Moon `flat_mod`u düşürür).
class_name InjuryContext
extends RefCounted

# ── GİRDİLER (çözümleme boyunca değişmez) ────────────────────────────────────

## Saldıran birim düğümü.
var attacker = null
## Yarayı ALAN birim düğümü (eski koddaki `self`).
var target = null
## Kullanılan saldırı verisi (AttackData). `special_ammunition` gibi kurallar bunu
## `duplicate()` edip mutasyona uğratabilir — bu yüzden paylaşılan .tres olmayabilir.
var atk: Resource = null
## Success Roll Kritik miydi?
var critical_hit: bool = false
## Yakın dövüş mü?
var is_melee: bool = false

## >0 ise Bloodbath tespiti ATLANIR ve doğrudan bu kadar zar tutulur
## (ör. Martyrdom Device'ın kendi 4D6'sı). Marker harcama akışı da devre dışı kalır.
var forced_keep_count: int = 0

## Yalnız Glorious Deed değerlendirmesi için taşınan bayraklar (Sniper / Death From Above).
var deed_is_long_range: bool = false
var deed_in_cover: bool = false
var deed_is_diving_charge: bool = false

# ── ÇÖZÜMLEME SIRASINDA DOLAN / DEĞİŞEN ALANLAR ──────────────────────────────

## `DicePoolBuilder.build_injury_context()` çıktısı (modifier hesapları için).
var pool_ctx: Dictionary = {}

## Injury Dice modifikatörü (+/- ZAR sayısı). Tetikleyiciler değiştirebilir.
var dice_mod: int = 0
## Injury MODIFIER (+/- düz sayı, zar DEĞİL). Tetikleyiciler değiştirebilir.
var flat_mod: int = 0
## Tutulacak zar sayısı (2 normal, 3 Bloodbath, 4 Bloodbath+DEADLY).
var keep_count: int = 2
## Bloodbath'a çevrildi mi?
var is_bloodbath: bool = false

## Atılan zarın toplamı.
var total: int = 0

## Yara tablosunun HAM sonucu (`apply_outcome` çağrılmadan önce — tetikleyiciler değiştirebilir).
var raw_outcome: int = 0
## Yan etkileri uygulandıktan SONRAKİ kesin sonuç.
var final_outcome: int = 0

## `apply_outcome` ÖNCESİNDEKİ marker sayıları — "bu saldırı marker koydu mu" karşılaştırması için.
var blood_before_outcome: int = 0
var infection_before_outcome: int = 0
## Bu saldırı hedefe Kan VEYA Enfeksiyon İşareti koydu mu? (Beelzebub's Touch / Parasite Host)
var marker_placed_this_attack: bool = false

## Hedef Savaş Dışı mı kaldı? Tetikleyicilerin en sık sorduğu soru — kısayol.
func is_ooa() -> bool:
	return final_outcome == InjuryResolver.Outcome.OUT_OF_ACTION

## Saldıran ile hedef aynı oyuncunun mu? (Whip of God gibi dost-hedefli kurallar için.)
func is_friendly_fire() -> bool:
	return attacker != null and target != null and attacker.owner_id == target.owner_id

## `attacker.unit_data`ya güvenli erişim (null olabilir).
func attacker_data() -> Resource:
	return attacker.unit_data if attacker != null else null

## `target.unit_data`ya güvenli erişim (null olabilir).
func target_data() -> Resource:
	return target.unit_data if target != null else null
