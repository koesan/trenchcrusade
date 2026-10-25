extends RefCounted

## P1-1 (Anchorite Shrine — Broken on the Wheel): compendium — deploy-öncesi seçilen alternatif
## loadout aktifken Down→Minor Hit(Scratch), İLK Out of Action→No Effect (Kan İşaretleri silinir,
## TEK KEZ tükenir, sonra normal duruma — armour 3, Tough, Negate Shrapnel — geri döner).
## Deploy-zamanı loadout seçimi (LoadoutResolver/init_unit) headless test edilemez (NavigationServer/
## RPC'ye bağlı) — burada yalnız injury_resolver.gd'nin SAF state-makinesi testli.

const InjuryResolver = preload("res://scripts/rules/injury_resolver.gd")
const UnitData = preload("res://scripts/data/unit_data.gd")

class _Target:
	var unit_data
	var blood_markers: int = 0
	var infection_markers: int = 0
	var is_down: bool = false
	var display_name: String = "Anchorite Shrine"
	var armour: int = 0
	var broken_on_wheel_active: bool = false
	var has_tough_used: bool = false
	var has_memento_mori_used: bool = false

func _ud(kw: Dictionary, tough: bool) -> UnitData:
	var u := UnitData.new()
	u.keywords = kw
	u.has_tough = tough
	return u

func run(t) -> void:
	var O = InjuryResolver.Outcome

	# ── Aktif fazda Down → Scratch'e düşürülür (Steadfast ile aynı dal) ──
	var t1 := _Target.new()
	t1.unit_data = _ud({}, false)
	t1.broken_on_wheel_active = true
	var outcome1 := InjuryResolver.apply_outcome(O.DOWN, t1, null)
	t.eq(outcome1, O.SCRATCH, "Broken on the Wheel aktif: Down → Scratch")
	t.ok(not t1.is_down, "Broken on the Wheel aktif: is_down TRUE olmaz")

	# ── İlk Out of Action: No Effect'e negatize edilir, Kan İşaretleri silinir, normale döner ──
	var t2 := _Target.new()
	t2.unit_data = _ud({}, false)  # aktif fazda has_tough=false, negate_shrapnel yok
	t2.broken_on_wheel_active = true
	t2.blood_markers = 4
	var outcome2 := InjuryResolver.apply_outcome(O.OUT_OF_ACTION, t2, null)
	t.eq(outcome2, O.NEGATED_BROKEN_ON_WHEEL, "İlk OOA → NEGATED_BROKEN_ON_WHEEL")
	t.eq(t2.blood_markers, 0, "İlk OOA sonrası Kan İşaretleri silinir")
	t.eq(t2.armour, 3, "İlk OOA sonrası zırh normale döner (3)")
	t.ok(not t2.broken_on_wheel_active, "İlk OOA sonrası bayrak kapanır (tek kullanımlık)")
	t.ok(t2.unit_data.has_tough, "İlk OOA sonrası Tough geri kazanılır")
	t.ok(KeywordSystem.has(t2.unit_data, &"negate_shrapnel"), "İlk OOA sonrası Negate Shrapnel geri kazanılır")

	# ── İkinci Out of Action: compendium açıkça söylüyor — "the TOUGH Keyword will apply the NEXT
	# time" — yani flip sonrası kazanılan Tough, BİR SONRAKİ OOA'da devreye girer (Down'a çevirir).
	# Bayrak zaten kapalı (Broken on the Wheel tekrar tetiklenmez), NEGATED_TOUGH devreye girer.
	var outcome3 := InjuryResolver.apply_outcome(O.OUT_OF_ACTION, t2, null)
	t.eq(outcome3, O.NEGATED_TOUGH, "İkinci OOA: Broken on the Wheel tekrar tetiklenmez, flip sonrası kazanılan Tough devreye girer")

	# ── Broken on the Wheel aktif DEĞİLSE davranış değişmez (regresyon) ──
	var t3 := _Target.new()
	t3.unit_data = _ud({}, false)
	var outcome4 := InjuryResolver.apply_outcome(O.DOWN, t3, null)
	t.eq(outcome4, O.DOWN, "Broken on the Wheel aktif değil → normal Down")
