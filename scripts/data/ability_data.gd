## Faksiyon yeteneği tanımı Resource sınıfı.
## Her özel yetenek için ayrı .tres dosyası oluşturulur.
## Yeni yetenek eklemek script düzenlemesi gerektirmez — sadece .tres ekle.
## FAZ 3: AbilityExecutor bu resource'u okuyarak tüm mantığı çalıştırır.
class_name AbilityData
extends Resource

## Yeteneğin benzersiz kimliği. AbilityExecutor bu ID ile hangi efekti uygulayacağını bilir.
## Örnek: &"loudspeakers", &"treat", &"shadow_step", &"enforced_orthodoxy"
@export var ability_id: StringName = &""

## Kullanıcıya gösterilen ad.
@export var display_name: String = ""

## Yeteneğin açıklaması (UI tooltip için).
@export var description: String = ""

# ── EYLEM MALİYETİ ───────────────────────────────────────────────────────────
@export_group("Action Rules")

## can_perform_action() için anahtar. Bu string actions_taken'a eklenir.
@export var action_key: String = ""

## Başarısızlıkta aktivasyon biter mi? (Risky Ability)
@export var is_risky: bool = true

## Bu yeteneği kullanmak için birim angaje (1" içinde düşman) OLMAMALI.
@export var requires_not_engaged: bool = true

## Bu yeteneği kullanmak için birim angaje OLMALI.
@export var requires_engaged: bool = false

## Bu yeteneği kullanmak için birim Down OLMAMALI. (True = Down birim kullanamaz)
@export var requires_standing: bool = true

# ── BAŞARI ZARI ──────────────────────────────────────────────────────────────
@export_group("Roll")

## Başarı Zarı gerekiyor mu? False ise otomatik başarı.
@export var requires_roll: bool = true

## Başarı eşiği. Varsayılan Trench Crusade standardı: 7.
@export var success_threshold: int = 7

## Saldırı zarı modifikasyonu. Birimin stat'larına ek olarak uygulanır.
@export var dice_modifier: int = 0

# ── HEDEF KURALLARI ──────────────────────────────────────────────────────────
@export_group("Targeting")

## Hedef türü.
## "none"     = Hedef gerektirmez (örn: loudspeakers, alchemical_brew)
## "friendly" = Dost bir birim seçilmeli
## "enemy"    = Düşman bir birim seçilmeli
## "position" = Koordinat seçilmeli (örn: shadow_step)
## "self"     = Sadece kendine uygulanır
@export_enum("none", "friendly", "enemy", "position", "self") var target_type: String = "none"

## Hedefin maksimum mesafesi (metre). 0.0 = sınırsız.
@export var range_meters: float = 0.0

## Hedef hayatta ve Down değil olmalı.
@export var target_must_be_alive: bool = true

## Hedef aynı faksiyon mu olmalı?
@export var target_same_faction: bool = true

# ── EFEKTLERİ ────────────────────────────────────────────────────────────────
@export_group("Effects")

## Efekt tipi — AbilityExecutor bu değere göre doğru mantığı çalıştırır.
##
## "blessing"          → Hedef birime +1 Blessing Marker
## "remove_blood"      → Hedef birimin Blood Marker'larını azaltır
## "stand_up"          → Hedef birimi Down'dan kaldırır
## "move_allies"       → Tüm dost birimler düşmana doğru hareket eder (Loudspeakers)
## "force_activation"  → Düşman birimi bir sonraki tur aktive olmak zorunda kalır
## "force_move"        → Düşman birim zorla hareket ettirilir (Puppet Master)
## "teleport"          → Birim belirtilen konuma ışınlanır (Shadow Step)
## "buff_dice"         → Hedef birime +N DICE bonus verir (Alchemical Brew)
## "add_blood"         → Düşman hedefe +N Kan İşareti (Goetic Gaze, Divine Judgement)
## "set_flag"          → Caster'da bir durum bayrağını açar (Hide/Fortify/Shadow Walker)
## "custom"            → Yetenek özel mantığı — ability_id ile eşleştirilir
@export_enum(
	"blessing",
	"remove_blood",
	"stand_up",
	"treat_choice",
	"move_allies",
	"force_activation",
	"force_move",
	"teleport",
	"buff_dice",
	"add_blood",
	"set_flag",
	"custom"
) var effect_type: String = "custom"

## Efektle eklenen/silinen miktar. (örn: remove_blood için 1, crit'te 3)
@export var effect_amount: int = 1

## Kritik başarıda (12+) efekt miktarı farklı mı?
@export var crit_amount: int = 1

## Buff birimin yakın dövüş zarasına mı (true) yoksa menzilli zarasına mı (false) uygulanır?
@export var buff_is_melee: bool = true

## Buff menzilli zarasına da uygulanır mı?
@export var buff_also_ranged: bool = false

## Teleport/force_move maksimum mesafe.
@export var max_distance: float = 0.0

## add_blood: hedef "unholy" (Demonic/Black Grail/Heretic) ise Kan İşaretine eklenecek EK miktar.
## Örn. Divine Judgement: effect_amount=1, blood_bonus_vs_unholy=1 → unholy hedefe 2.
@export var blood_bonus_vs_unholy: int = 0

## set_flag: caster üzerinde açılacak bool bayrağın adı (örn. "is_hidden", "has_fortify_cover",
## "shadow_walker_active"). Handler bunu true yapar ve tüm istemcilerde senkronlar.
@export var flag_name: String = ""

## Efekt başarıyla uygulandığında oynatılacak görsel feedback türü:
## "bless"/"heal"/"buff" → hedef hafifçe zıplar (bob); "curse"/"debuff" → hedef titrer (shake).
## Boş bırakılırsa efekt tipine göre makul varsayılan seçilir.
@export var feedback_kind: String = ""
