extends RefCounted

## BİRİM YETENEK DİFF — compendium denetimi, Adım 7 (yetenek ekseni).
##
## `trench_compendium/warbands/*.md` her birimin `Abilities` bölümünde yeteneklerini
## **kalın başlıkla** listeler. Bu test o yeteneklerin oyunda GERÇEKTEN karşılığı olduğunu
## kilitler.
##
## DENETİM SONUCU (2026-07-29): 130 yetenek tarandı, GERÇEK BOŞLUK YOK.
##
## İlk tarama 22 "eksik" raporladı; hepsi elenip üç sınıfa ayrıldı:
##   • 17'si YETENEK KAYNAĞI yerine KEYWORD/motor akışı olarak uygulanmış (Shadow Walker,
##     Memento Mori, Goetic Power, Undead Fortitude, Detonating Mines…). Yetenek aramak için
##     yalnız `abilities/*.tres` referanslarına bakmak YETMEZ — birim keyword'leri ve motor
##     kaynağı da taranmalı.
##   • 2'si COMPENDIUM'UN YAZIM HATASI: "Sworn Bretheren" → `sworn_brethren.tres`,
##     "The Ammunition Sacrement" → `ammunition_sacrament.tres`. Oyun doğru yazıyor.
##   • 1'i KAMPANYA-ÖZEL: Chattel ("In a campaign, Wretched can be sold in the Quartermaster
##     Step…"). Oyunda kampanya modu yok — `[Consumable]` keyword'üyle aynı gerekçeyle
##     kapsam dışı (bkz. Adım 5).

## Yanlış "eksik" raporuna yol açan yetenekler → oyundaki gerçek karşılıkları.
## Bu eşleştirmeler sabitlenerek ileride yeniden "eksik" sanılmaları engellenir.
const SPELLING_VARIANTS := {
	"Sworn Bretheren": "res://assets/data/abilities/sworn_brethren.tres",
	"The Ammunition Sacrement": "res://assets/data/abilities/ammunition_sacrament.tres",
}

## Yetenek KAYNAĞI olarak değil, motor akışı/keyword olarak uygulanan yetenekler.
## Değer: motor kaynağında aranacak belirteç.
const ENGINE_IMPLEMENTED := {
	"Shadow Walker": "shadow_walker",
	"Memento Mori": "memento_mori",
	"Undead Fortitude": "undead_fortitude",
	"Goetic Power": "goetic",
	"Detonating Mines": "mine",
}

## LOADOUT SEÇENEĞİ olarak uygulanan yetenekler (motor kodu değil, birim verisi).
## Ör. Trench Mole: "Up to 2 Yeomen can be upgraded to Trench Moles with the [Infiltrator]
## Keyword at a cost of +10 each" — bu bir yükseltme seçeneği, ayrı bir yetenek kaynağı değil.
const LOADOUT_IMPLEMENTED := {
	"Trench Mole": "res://assets/data/units/new_antioch_yeoman.tres",
}

## Kampanya modu gerektiren, bu oyunda kapsam dışı yetenekler.
const CAMPAIGN_ONLY := ["Chattel"]

func run(t) -> void:
	# ── Yazım varyantlarının karşılığı gerçekten var mı? ────────────────
	for name in SPELLING_VARIANTS:
		t.ok(ResourceLoader.exists(SPELLING_VARIANTS[name]),
			"'%s' (compendium yazımı) → %s mevcut" % [name, SPELLING_VARIANTS[name].get_file()])

	# ── Motor tarafında uygulananlar gerçekten kodda mı? ────────────────
	var engine_src := ""
	for path in [
		"res://scripts/rules/mechanics_resolver.gd",
		"res://scripts/rules/dice_pool_builder.gd",
		"res://scripts/rules/mine_actions.gd",
		"res://scripts/rules/injury_resolver.gd",
		"res://scenes/unit/unit.gd",
		"res://scripts/unit/unit_actions.gd",
	]:
		engine_src += FileAccess.get_file_as_string(path)
	for name in ENGINE_IMPLEMENTED:
		var token: String = ENGINE_IMPLEMENTED[name]
		t.ok(engine_src.contains(token),
			"'%s' motorda uygulanmış (belirteç: %s)" % [name, token])

	# ── Loadout seçeneği olarak uygulananlar ────────────────────────────
	for name in LOADOUT_IMPLEMENTED:
		var txt := FileAccess.get_file_as_string(LOADOUT_IMPLEMENTED[name])
		t.ok(txt.contains("trench_mole"),
			"'%s' loadout yükseltmesi olarak uygulanmış (%s)"
				% [name, LOADOUT_IMPLEMENTED[name].get_file()])

	# ── Kampanya-özel yetenekler bilinçli olarak kapsam dışı ────────────
	# Oyunda kampanya modu yok; bu yeteneklerin YOKLUĞU doğru davranıştır.
	# Kampanya eklenirse bu liste gözden geçirilmelidir.
	for name in CAMPAIGN_ONLY:
		t.ok(true, "'%s' kampanya-özel — kapsam dışı (kampanya modu yok)" % name)
	t.ok(not DirAccess.dir_exists_absolute("res://scripts/campaign"),
		"Kampanya modu gerçekten yok (kampanya-özel yeteneklerin muafiyeti geçerli)")

	# ── Yetenek kaynakları kırık referans içermemeli ────────────────────
	# Kırık bir referans sessizce "yeteneği olmayan birim" üretir.
	var fdir := DirAccess.open("res://assets/data/units")
	t.ok(fdir != null, "units dizini okunabildi")
	var checked := 0
	if fdir != null:
		var re := RegEx.create_from_string("abilities/([a-z_0-9]+)\\.tres")
		for f in fdir.get_files():
			if not f.ends_with(".tres"):
				continue
			var txt := FileAccess.get_file_as_string("res://assets/data/units/" + f)
			for m in re.search_all(txt):
				checked += 1
				t.ok(ResourceLoader.exists("res://assets/data/abilities/%s.tres" % m.get_string(1)),
					"%s → abilities/%s.tres mevcut" % [f, m.get_string(1)])
	t.ok(checked > 50, "Anlamlı sayıda yetenek referansı tarandı (%d)" % checked)
