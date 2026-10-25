extends RefCounted

## Kullanıcı bildirimi: "7 başlı yılan divanında Gotik büyü kısmı çalışmıyor gibi, Sapkın
## Büyücüde Yakıcı Cehennemi (Burning Inferno) kullanıyorum ama sanki çalışmıyor gibi."
##
## Canlı log analizi: mekanik ASLINDA doğru çalışıyordu (bedel ödenince büyü isabet edip patlama
## yapıyordu) — sorun, oyunun başında (kimse yara almadan) sahada HİÇ Blood Marker olmamasıydı;
## compendium'un Goetic Spell kuralı "sahada mevcut Blood Marker'ları harcarsın" der, kendi başına
## bir kaynak değildir. Bu yüzden Burning Inferno/Shadow Walker/Slavemaster ilk birkaç aktivasyonda
## HER ZAMAN başarısız oluyordu (rules-accurate) — ama buton yine de tıklanabilir kalıyordu, yalnız
## bir toast ile "hayır" diyordu, bu da "çalışmıyor gibi" hissi yaratıyordu.
##
## Düzeltme: bu 3 Goetic Spell butonu artık sahada yeterli Blood Marker YOKSA hiç üretilmiyor
## ("ölü buton" felsefesiyle tutarlı — bkz. is_actionable_ability'nin AYNI amacı).

const UnitActions = preload("res://scripts/unit/unit_actions.gd")

class FakeUnit:
	var current_health: int = 10
	var blood_markers: int = 0
	var unit_data: Resource = null
	func _init(hp: int, bm: int, ud: Resource) -> void:
		current_health = hp
		blood_markers = bm
		unit_data = ud

func run(t) -> void:
	t.eq(UnitActions._goetic_min_cost("burning_inferno"), 1, "Burning Inferno → min maliyet 1")
	t.eq(UnitActions._goetic_min_cost("slavemaster"), 1, "Slavemaster → min maliyet 1")
	t.eq(UnitActions._goetic_min_cost("shadow_walker"), 2, "Shadow Walker → min maliyet 2 (sabit)")
	t.eq(UnitActions._goetic_min_cost("move"), 0, "Temel eylemler (move) Goetic bedeli taşımaz → 0")

	var actions := UnitActions.new(null)
	var original_units: Dictionary = GameState.units.duplicate()

	var plain_ud := UnitData.new()

	# ── Sahada HİÇ Blood Marker yoksa (oyunun başı) → yetersiz ────────────────────────────
	GameState.units = {
		"u1": FakeUnit.new(10, 0, plain_ud),
		"u2": FakeUnit.new(10, 0, plain_ud),
	}
	t.ok(not actions._has_enough_goetic_blood(1),
		"Sahada 0 Blood Marker → Burning Inferno/Slavemaster (min 1) yetersiz")
	t.ok(not actions._has_enough_goetic_blood(2),
		"Sahada 0 Blood Marker → Shadow Walker (min 2) yetersiz")

	# ── Sahada 1 Blood Marker varsa (birisi yara aldı) ────────────────────────────────────
	GameState.units = {
		"u1": FakeUnit.new(10, 1, plain_ud),
		"u2": FakeUnit.new(10, 0, plain_ud),
	}
	t.ok(actions._has_enough_goetic_blood(1),
		"Sahada 1 Blood Marker → Burning Inferno/Slavemaster (min 1) yeterli")
	t.ok(not actions._has_enough_goetic_blood(2),
		"Sahada yalnız 1 Blood Marker → Shadow Walker (min 2) hâlâ yetersiz")

	# ── Demonic/Black Grail kaynak SAYILMAZ (compendium: bu Keyword'lere sahip modellerden
	# Blood Marker harcanamaz) ────────────────────────────────────────────────────────────
	var demonic_ud := UnitData.new()
	demonic_ud.keywords = {&"demonic": 1}
	GameState.units = {
		"u1": FakeUnit.new(10, 5, demonic_ud),
	}
	t.ok(not actions._has_enough_goetic_blood(1),
		"Yalnız Demonic bir modelde Blood Marker varsa → hâlâ yetersiz (geçerli kaynak değil)")

	GameState.units = original_units
