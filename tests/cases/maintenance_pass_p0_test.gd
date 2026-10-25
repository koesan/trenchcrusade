extends RefCounted

## Genel bakım/iyileştirme turu (2026-07-18): kullanıcının bildirdiği 3 somut hatanın kilidi.

const LoadoutResolver = preload("res://scripts/rules/loadout_resolver.gd")

func run(t) -> void:
	_test_war_wolf_deployable(t)
	_test_observer_available_to_trench_pilgrims(t)
	_test_chalice_slave_and_fly_slave_are_distinct(t)

## P0-1: War Wolf Assault Beast (Heretic Legion) "Geçersiz silah ve teçhizat yüklemesi" ile
## deploy edilemiyordu — Chainsaw Mouth(1H)+Shredding Claws(2H) = 3 el, standart 2-el limitini
## aşıyordu. RAW: bu silahlar modele ait, kaybedilemez/değiştirilemez, Battlekit DEĞİL —
## LoadoutResolver artık fixed_weapon_loadout keyword'üyle bu limitten muaf tutuyor.
func _test_war_wolf_deployable(t) -> void:
	var war_wolf_ud = load("res://assets/data/units/war_wolf_assault_beast.tres")
	t.eq(LoadoutResolver.validate_loadout(war_wolf_ud), "",
		"War Wolf Assault Beast artık yerleştirilebilir (loadout hatası vermiyor)")

	# Aynı kök nedenden etkilenen gizli bug: Amalgam (Black Grail) 3 silahlı (Six-Armed
	# Monstrosity) ama fixed_weapon_loadout eklenmeden önce de reddedilirdi.
	var amalgam_ud = load("res://assets/data/units/amalgams.tres")
	t.eq(LoadoutResolver.validate_loadout(amalgam_ud), "",
		"Amalgam artık yerleştirilebilir (Six-Armed Monstrosity'nin 3 silahı el-limitinden muaf)")

## P0-2 (2026-07-28 GERİ ALINDI — bkz. denetim bulgusu P0-TP-2):
## Bu madde eskiden Observer'ı Trench Pilgrims roster'ından ÇIKARIYORDU ve test bunu
## kilitliyordu. Faksiyon sadakat denetiminde bu kararın KAYNAKSIZ olduğu tespit edildi:
##
##   trench_compendium/warbands/trench-pilgrims.md → "## Mercenaries" bölümü
##     Observer — Cost: 3 (Glory Point), Availability: 0-1, Movement 8"/Infantry
##   Birimin compendium'daki görseli bile `procession-of-the-sacred-affliction` etiketli,
##   yani doğrudan bir Trench Pilgrims variant'ına ait.
##
## Observer, Trench Pilgrims'in 6 mercenary'sinden biridir ve fraksiyonun "toplu hücum"
## ekseniyle mekanik olarak da uyumludur (Voice of God ile Loudspeakers hücumuna kalkan bir
## Nun/Communicant sıra dışı aktive edilebilir). Roster'a geri eklendi.
func _test_observer_available_to_trench_pilgrims(t) -> void:
	var tp_faction = load("res://assets/data/factions/trench_pilgrims.tres")
	var observer_ud = load("res://assets/data/units/observer.tres")
	t.ok(observer_ud in tp_faction.available_units,
		"Observer, Trench Pilgrims roster'ında (compendium Mercenaries: 3 GP, 0-1)")

	var na_faction = load("res://assets/data/factions/new_antioch.tres")
	t.ok(observer_ud in na_faction.available_units,
		"Observer, New Antioch roster'ında da mevcut (compendium: iki faksiyonun da mercenary'si)")

## P0-3: Chalice Slave (Grail Thrall) / Fly Slave (Fly Thrall) incelendi — compendium'da İKİ
## AYRI, meşru birim (cult-of-the-black-grail.md satır 382-472: "Thralls come in two varieties").
## BİRLEŞTİRİLMEDİ (aynı birim değiller: Grail Thrall Undead Fortitude+5" hareket taşır, Fly Thrall
## Flying+6" hareket taşır, ikisi de aynı Overwhelming Horde yeteneğini paylaşır — RAW'a birebir
## uygun). Fly Thrall'ın model_scene_path'i BİLEREK boş bırakıldı: henüz kendi 3D asset'i yok ve
## proje standart deseni (unit_model_uniqueness_test, 2026-07-15) FARKLI birimlerin aynı modeli
## paylaşmasını YASAKLIYOR (görsel "kopya birim" bug'ı) — bu yüzden Grail Thrall'ın modelini ödünç
## almak yerine, tıpkı diğer henüz-modelsiz birimler gibi, deploy_panel.gd otomatik gizliyor
## (model eklenince kod değişikliği gerekmeden görünür olacak).
func _test_chalice_slave_and_fly_slave_are_distinct(t) -> void:
	var fly_thrall_ud = load("res://assets/data/units/fly_thrall.tres")
	var grail_thrall_ud = load("res://assets/data/units/grail_thrall.tres")
	t.ok(fly_thrall_ud.has_undead_fortitude != grail_thrall_ud.has_undead_fortitude,
		"Fly Thrall ve Grail Thrall mekanik olarak FARKLI (Undead Fortitude ayrımı, RAW-doğru)")
	t.ok(KeywordSystem.has(fly_thrall_ud, &"flying") and not KeywordSystem.has(grail_thrall_ud, &"flying"),
		"Fly Thrall FLYING taşıyor, Grail Thrall taşımıyor (compendium ayrımı korundu)")
	t.eq(fly_thrall_ud.movement_range, 6.0, "Fly Thrall → 6\" hareket (compendium)")
	t.eq(grail_thrall_ud.movement_range, 5.0, "Grail Thrall → 5\" hareket (compendium)")
	t.eq(fly_thrall_ud.model_scene_path, "",
		"Fly Thrall model_scene_path bilerek boş (henüz asset yok; Grail Thrall'ı ÖDÜNÇ ALMADI — " \
		+ "proje deseni farklı birimlerin aynı model paylaşmasını yasaklıyor)")

const KeywordSystem = preload("res://scripts/rules/keyword_system.gd")
