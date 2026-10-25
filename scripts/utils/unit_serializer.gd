## BİRİM DURUMU SERİLEŞTİRME — kaydedilen alanların TEK KAYNAĞI.
##
## SORUN: `save_game()` 20 alanı elle yazıyor, `restore_game_state()` aynı 20'yi elle okuyordu.
## Yeni bir alan eklerken İKİ yeri birden güncellemek gerekiyordu ve birini unutmak SESSİZ bir
## veri kaybı üretiyordu — hata vermeden, yalnız yüklenen oyunda o durum kayboluyordu.
##
## GERÇEK ÖRNEK (bu refaktörde bulundu): `chosen_loadout_index` HİÇ kaydedilmiyordu. Kayıt
## yüklenince her birim VARSAYILAN Battlekit ile geri geliyordu — yani seçilmiş silahlar
## sessizce kayboluyordu. Tek tablo sayesinde bu hata sınıfı yapısal olarak imkânsızlaştı:
## kaydedilen her alan aynı listeden geri yüklenir.
##
## Fireteam/ortak aktivasyon bağları AD olarak tutulduğu için (`fireteam_partner_name`,
## `joint_partner_name`) doğrudan kaydedilir. KAPSAM DIŞI (bilinçli): düğüm REFERANSI taşıyan
## alanlar — `devoured_unit`, `devoured_by`. Bunlar JSON'a yazılamaz; ada göre yeniden bağlama gerektirir ve bugün kayıt/
## yükleme bu ilişkileri zaten korumuyor. Eklenecekse ayrı bir "ilişki yeniden bağlama" adımı
## gerekir; sessizce yarım bir çözüm eklenmedi.
class_name UnitSerializer

## Kaydedilen/geri yüklenen birim alanları. `type` JSON'dan okurken dönüştürme için gerekli
## (JSON tüm sayıları float olarak döndürür; StringName ise String'e düşer).
const FIELDS := [
	# ── Profil (yükleme/terfi sonrası değerler; unit_data'dan türetilir ama runtime'da değişebilir)
	{"name": "display_name", "type": TYPE_STRING, "default": ""},
	{"name": "speed", "type": TYPE_FLOAT, "default": 6.0},
	{"name": "armour", "type": TYPE_INT, "default": 3},
	{"name": "melee_dice_modifier", "type": TYPE_INT, "default": 0},
	{"name": "ranged_dice_modifier", "type": TYPE_INT, "default": 0},

	# ── Sağlık ve işaretler
	{"name": "current_health", "type": TYPE_INT, "default": 10},
	{"name": "blood_markers", "type": TYPE_INT, "default": 0},
	{"name": "blessing_markers", "type": TYPE_INT, "default": 0},
	{"name": "infection_markers", "type": TYPE_INT, "default": 0},
	{"name": "is_down", "type": TYPE_BOOL, "default": false},

	# ── Aktivasyon durumu
	{"name": "has_moved", "type": TYPE_BOOL, "default": false},
	{"name": "stood_up_this_activation", "type": TYPE_BOOL, "default": false},
	{"name": "activation_started", "type": TYPE_BOOL, "default": false},
	{"name": "actions_taken", "type": TYPE_ARRAY, "default": []},
	{"name": "fireteam_partner_name", "type": TYPE_STRING, "default": ""},
	{"name": "fireteam_sworn", "type": TYPE_BOOL, "default": false},
	{"name": "joint_partner_name", "type": TYPE_STRING, "default": ""},
	{"name": "is_dash_pending", "type": TYPE_BOOL, "default": false},
	{"name": "is_charge_pending", "type": TYPE_BOOL, "default": false},
	{"name": "charge_bonus", "type": TYPE_FLOAT, "default": 0.0},
	# Aynı aileden ama eskiden KAYDEDİLMEYEN aktivasyon kilitleri — kayıt ortasında yüklenen
	# bir oyunda bu birimler yanlışlıkla yeniden ateş/hareket edebiliyordu.
	{"name": "has_non_assault_shot", "type": TYPE_BOOL, "default": false},
	{"name": "has_heavy_shot", "type": TYPE_BOOL, "default": false},
	{"name": "diving_charge_bonus_pending", "type": TYPE_BOOL, "default": false},

	# ── Bir kez kullanılan kurtarmalar
	{"name": "has_memento_mori_used", "type": TYPE_BOOL, "default": false},
	{"name": "has_tough_used", "type": TYPE_BOOL, "default": false},
	# Broken on the Wheel kurbanı tükendi mi (tükendiyse birim normal profile döner).
	{"name": "broken_on_wheel_active", "type": TYPE_BOOL, "default": false},

	# ── Kalıcı yetenek bayrakları (UnitStatusPanel rozetleri bunları gösterir)
	{"name": "is_hidden", "type": TYPE_BOOL, "default": false},
	{"name": "has_fortify_cover", "type": TYPE_BOOL, "default": false},
	{"name": "shadow_walker_active", "type": TYPE_BOOL, "default": false},
	{"name": "slashing_attack_active", "type": TYPE_BOOL, "default": false},

	# ── Senaryo/faksiyon durumu
	{"name": "is_bounty_target", "type": TYPE_BOOL, "default": false},
	# ELEMENTAL CHANGE / MASTERY OF THE ELEMENTS: silahın dinamik elementi hasar tipini belirler.
	{"name": "current_element", "type": TYPE_STRING_NAME, "default": &""},
]

## Birimin kaydedilecek durumunu sözlüğe alır (konum/kimlik HARİÇ — onlar yapısaldır,
## `save_manager` kendi yazar).
static func capture(unit) -> Dictionary:
	var out: Dictionary = {}
	for f in FIELDS:
		var value = unit.get(f["name"])
		match f["type"]:
			TYPE_ARRAY:
				out[f["name"]] = (value as Array).duplicate()
			TYPE_STRING_NAME:
				out[f["name"]] = String(value)
			_:
				out[f["name"]] = value
	return out

## Sözlükteki durumu birime uygular. Eksik anahtarlar için tablodaki VARSAYILAN kullanılır —
## böylece eski bir kayıt dosyası yeni alanlar yüzünden bozulmaz (ileri uyumluluk).
static func apply(unit, d: Dictionary) -> void:
	for f in FIELDS:
		var key: String = f["name"]
		var raw = d.get(key, f["default"])
		unit.set(key, _coerce(raw, f["type"], f["default"]))

static func _coerce(raw, type: int, fallback):
	if raw == null:
		return fallback  # bozuk/eksik değer — bool(null)/String(null) çalışma hatası verir
	match type:
		TYPE_INT:
			return int(raw)
		TYPE_FLOAT:
			return float(raw)
		TYPE_BOOL:
			return bool(raw)
		TYPE_STRING:
			return String(raw)
		TYPE_STRING_NAME:
			return StringName(raw)
		TYPE_ARRAY:
			return (raw as Array).duplicate() if raw is Array else fallback
		_:
			return raw
