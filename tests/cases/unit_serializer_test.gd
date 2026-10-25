extends RefCounted

## BİRİM SERİLEŞTİRME — kaydet/geri yükle gidiş-dönüş bütünlüğü.
##
## Bu testin varlık sebebi: `save_game()` alanları elle yazıyor, `restore_game_state()` elle
## okuyordu. Yeni bir alan eklerken birini unutmak SESSİZ veri kaybı üretiyordu — hata yok,
## yalnız yüklenen oyunda o durum kayboluyor. Gerçekten yaşandı: `chosen_loadout_index` hiç
## kaydedilmiyordu, yüklenen oyunda her birim VARSAYILAN Battlekit ile geri geliyordu.
##
## Artık tek kaynak `UnitSerializer.FIELDS`. Bu test, tablodaki HER alanın gerçekten gidip
## geldiğini ve `unit.gd` üzerinde var olduğunu doğrular.

## Sahte birim: `UnitSerializer`ın dokunduğu tüm alanları taşır.
class FakeUnit extends RefCounted:
	var display_name: String = ""
	var speed: float = 6.0
	var armour: int = 3
	var melee_dice_modifier: int = 0
	var ranged_dice_modifier: int = 0
	var current_health: int = 10
	var blood_markers: int = 0
	var blessing_markers: int = 0
	var infection_markers: int = 0
	var is_down: bool = false
	var has_moved: bool = false
	var stood_up_this_activation: bool = false
	var activation_started: bool = false
	var fireteam_partner_name: String = ""
	var fireteam_sworn: bool = false
	var joint_partner_name: String = ""
	var actions_taken: Array = []
	var is_dash_pending: bool = false
	var is_charge_pending: bool = false
	var charge_bonus: float = 0.0
	var has_non_assault_shot: bool = false
	var has_heavy_shot: bool = false
	var diving_charge_bonus_pending: bool = false
	var has_memento_mori_used: bool = false
	var has_tough_used: bool = false
	var is_hidden: bool = false
	var has_fortify_cover: bool = false
	var shadow_walker_active: bool = false
	var slashing_attack_active: bool = false
	var is_bounty_target: bool = false
	var current_element: StringName = &""

func run(t) -> void:
	# ── Tablodaki her alan GERÇEK unit.gd'de var mı? ──────────────────────
	# (Yanlış yazılmış bir alan adı sessizce hiçbir şey kaydetmezdi.)
	var unit_src := FileAccess.open("res://scenes/unit/unit.gd", FileAccess.READ)
	t.ok(unit_src != null, "unit.gd okunabildi")
	var unit_txt := unit_src.get_as_text() if unit_src != null else ""
	if unit_src != null:
		unit_src.close()
	for f in UnitSerializer.FIELDS:
		t.ok(unit_txt.contains("var %s" % f["name"]),
			"unit.gd'de '%s' alanı var" % f["name"])

	# ── GİDİŞ-DÖNÜŞ: değiştirilmiş her alan aynen geri gelir ──────────────
	var u := FakeUnit.new()
	u.display_name = "Sapper"
	u.speed = 7.5
	u.armour = 2
	u.melee_dice_modifier = 1
	u.ranged_dice_modifier = -1
	u.current_health = 4
	u.blood_markers = 3
	u.blessing_markers = 2
	u.infection_markers = 1
	u.is_down = true
	u.has_moved = true
	u.stood_up_this_activation = true
	u.actions_taken = ["move", "shoot"]
	u.is_dash_pending = true
	u.is_charge_pending = true
	u.charge_bonus = 4.5
	u.has_non_assault_shot = true
	u.has_heavy_shot = true
	u.diving_charge_bonus_pending = true
	u.has_memento_mori_used = true
	u.has_tough_used = true
	u.is_hidden = true
	u.has_fortify_cover = true
	u.shadow_walker_active = true
	u.slashing_attack_active = true
	u.is_bounty_target = true
	u.current_element = &"shrapnel"
	u.activation_started = true
	u.fireteam_partner_name = "Unit_1_Yeoman_2"
	u.fireteam_sworn = true
	u.joint_partner_name = "Unit_1_Yeoman_2"

	var snapshot: Dictionary = UnitSerializer.capture(u)
	t.eq(snapshot.size(), UnitSerializer.FIELDS.size(),
		"capture() tablodaki alan sayısı kadar anahtar üretir")

	# JSON turundan geçir — gerçek kayıt yolu bu (int'ler float'a, StringName String'e döner).
	var json_round: Dictionary = JSON.parse_string(JSON.stringify(snapshot))
	t.ok(json_round != null, "Anlık görüntü JSON'a yazılıp okunabiliyor")

	var restored := FakeUnit.new()
	UnitSerializer.apply(restored, json_round)

	for f in UnitSerializer.FIELDS:
		var key: String = f["name"]
		t.eq(restored.get(key), u.get(key), "Gidiş-dönüş korundu: %s" % key)

	# Tipler JSON turundan sonra da DOĞRU olmalı (float→int, String→StringName).
	t.ok(typeof(restored.armour) == TYPE_INT, "armour JSON turundan sonra int kaldı")
	t.ok(typeof(restored.current_element) == TYPE_STRING_NAME,
		"current_element JSON turundan sonra StringName'e döndü")
	t.ok(typeof(restored.charge_bonus) == TYPE_FLOAT, "charge_bonus float kaldı")

	# ── İLERİ UYUMLULUK: eski kayıt (eksik anahtarlar) varsayılana düşer ──
	var legacy := FakeUnit.new()
	UnitSerializer.apply(legacy, {"current_health": 5})
	t.eq(legacy.current_health, 5, "Eski kayıttaki alan okunur")
	t.eq(legacy.armour, 3, "Eksik alan tablodaki varsayılana düşer (eski kayıt bozulmaz)")
	var nulled := FakeUnit.new()
	UnitSerializer.apply(nulled, {"is_down": null, "joint_partner_name": null})
	t.ok(nulled.is_down == false and nulled.joint_partner_name == "", "null değer varsayılana düşer (çalışma hatası yok)")
	t.eq(legacy.current_element, &"", "Eksik StringName alan boş varsayılana düşer")
	t.eq(legacy.actions_taken, [], "Eksik dizi alan boş diziye düşer")

	# ── KAYIT DOSYASI YAPISAL ALANLARI ───────────────────────────────────
	# Battlekit seçimi (`loadout_index`) kaydediliyor ve geri yüklenirken init_unit'e
	# GEÇİRİLİYOR mu? Eskiden ikisi de eksikti → silahlar sessizce kayboluyordu.
	var sm := FileAccess.open("res://scripts/utils/save_manager.gd", FileAccess.READ)
	t.ok(sm != null, "save_manager.gd okunabildi")
	if sm != null:
		var txt := sm.get_as_text()
		sm.close()
		t.ok(txt.contains('"loadout_index": u.chosen_loadout_index'),
			"Kayıt: Battlekit seçimi yazılıyor")
		t.ok(txt.contains("init_unit(owner_id, unit_data_path, loadout_index, true)"),
			"Yükleme: Battlekit seçimi init_unit'e geçiriliyor")
		t.ok(txt.contains('"loadout_index": loadout_index,'),
			"Yükleme: Battlekit seçimi MultiplayerSpawner'a da geçiriliyor")
		t.ok(txt.contains("UnitSerializer.capture(u)") and txt.contains("UnitSerializer.apply(unit"),
			"Kaydetme ve geri yükleme AYNI tek kaynağı kullanıyor")
