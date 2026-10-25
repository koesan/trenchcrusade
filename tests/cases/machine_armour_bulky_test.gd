extends RefCounted

## battlekit/armour.md — Machine Armour'ın "Bulky" özel kuralı: "Change the base size... to 40mm
## [BLOKE, bkz. plan.md — proje base_mm/model-taban-boyutu altyapısı içermiyor, kasıtlı hariç
## tutuldu, The High Ground istisnasıyla aynı desen]. In addition, a model with Machine Armour
## cannot be equipped with a Trench Shield and has a Charge Bonus of D3" instead of D6"."
##
## Bu proje Mechanized Heavy Infantry'nin Machine Armour'ını bir LOADOUT SEÇENEĞİ olarak modelliyor
## (assets/data/units/new_antioch_mechanized_heavy_infantry.tres, Loadout2) — bu yüzden Charge Bonus
## D3 kısıtı yalnız o loadout SEÇİLİNCE aktif olmalı, baz birimde (Loadout1: Reinforced Armour) DEĞİL.

const KeywordSystem = preload("res://scripts/rules/keyword_system.gd")
const MechanicsResolver = preload("res://scripts/rules/mechanics_resolver.gd")
const LoadoutResolver = preload("res://scripts/rules/loadout_resolver.gd")

func run(t) -> void:
	# ── Saf D6→D3 dönüşüm matematiği ────────────────────────────────────────
	var fake_ud_bulky = UnitData.new()
	fake_ud_bulky.keywords = {&"charge_bonus_d3": 1}
	t.eq(MechanicsResolver.apply_charge_bonus_d3(fake_ud_bulky, 1), 1, "D6=1 → D3=1")
	t.eq(MechanicsResolver.apply_charge_bonus_d3(fake_ud_bulky, 2), 1, "D6=2 → D3=1")
	t.eq(MechanicsResolver.apply_charge_bonus_d3(fake_ud_bulky, 3), 2, "D6=3 → D3=2")
	t.eq(MechanicsResolver.apply_charge_bonus_d3(fake_ud_bulky, 4), 2, "D6=4 → D3=2")
	t.eq(MechanicsResolver.apply_charge_bonus_d3(fake_ud_bulky, 5), 3, "D6=5 → D3=3")
	t.eq(MechanicsResolver.apply_charge_bonus_d3(fake_ud_bulky, 6), 3, "D6=6 → D3=3")

	var fake_ud_normal = UnitData.new()
	fake_ud_normal.keywords = {}
	t.eq(MechanicsResolver.apply_charge_bonus_d3(fake_ud_normal, 6), 6,
		"charge_bonus_d3 yoksa → D6 aynen korunur (regresyon yok)")
	t.eq(MechanicsResolver.apply_charge_bonus_d3(null, 6), 6, "null unit_data → güvenli varsayılan (D6)")

	# ── Mechanized Heavy Infantry: Loadout1 (Reinforced) normal D6, Loadout2 (Machine) D3 ────
	var base_ud = load("res://assets/data/units/new_antioch_mechanized_heavy_infantry.tres")
	t.ok(not KeywordSystem.has(base_ud, &"charge_bonus_d3"),
		"MHI baz birim (loadout uygulanmadan) → charge_bonus_d3 YOK")

	var reinforced: Resource = LoadoutResolver.resolve_loadout(base_ud, 0)
	t.ok(not KeywordSystem.has(reinforced, &"charge_bonus_d3"),
		"MHI Loadout1 (Reinforced Armour) → charge_bonus_d3 YOK, normal D6 hücum bonusu")
	t.eq(reinforced.armour, 2, "MHI Loadout1 → armour=2 (Reinforced, -2 Injury Modifier)")

	var machine: Resource = LoadoutResolver.resolve_loadout(base_ud, 1)
	t.ok(KeywordSystem.has(machine, &"charge_bonus_d3"),
		"MHI Loadout2 (Machine Armour) → Bulky'nin Charge Bonus D3 kısıtı aktif")
	t.ok(KeywordSystem.has(machine, &"steadfast"), "MHI Loadout2 → Steadfast (regresyon)")
	t.eq(machine.armour, 3, "MHI Loadout2 → armour=3 (Machine Armour, -3 Injury Modifier)")
