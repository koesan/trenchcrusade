extends RefCounted

## UnitQuery — merkezî birim sorgu API'si.
##
## Bu API'nin VAROLUŞ SEBEBİ, `for u in GameState.units` döngülerinde tekrarlanan
## `is_instance_valid` / `current_health > 0` / `owner_id` filtrelerinin unutulmasıydı
## (gerçek bug: siper ölü düşmanlara bakıyordu). Bu yüzden testin ağırlığı "ölü/geçersiz
## birimler HER YOLDAN eleniyor mu" sorusunda.
##
## Sahte birimler `Node3D` üzerine kurulur (global_position gerekli). `source` parametresi
## sayesinde GameState.units'e HİÇ dokunulmaz — test izole.

const UnitQuery = preload("res://scripts/rules/unit_query.gd")

var _host: Node = null

func run(t) -> void:
	_host = t
	# ── Sahte birim kümesi ────────────────────────────────────────────────
	# p1: iki hayatta (biri Down), bir ölü.  p2: iki hayatta.
	var freed := _make(Vector3(99, 0, 99), 1)
	var a1 := _make(Vector3(0, 0, 0), 1)
	var a2 := _make(Vector3(2, 0, 0), 1, 1, true)          # Down ama hayatta
	var a_dead := _make(Vector3(1, 0, 0), 1, 0)            # Savaş Dışı
	var e1 := _make(Vector3(3, 0, 0), 2)
	var e2 := _make(Vector3(20, 0, 0), 2)
	var e_dead := _make(Vector3(1, 0, 0), 2, 0)

	var src := {
		"freed": freed, "a1": a1, "a2": a2, "a_dead": a_dead,
		"e1": e1, "e2": e2, "e_dead": e_dead,
	}

	# `freed` bilinçli olarak serbest bırakılır — sözlükte KALIR, geçersiz referans olur.
	freed.free()

	# ── all / alive ───────────────────────────────────────────────────────
	t.eq(UnitQuery.all(src).size(), 6, "all(): freed birim elenir, ölüler kalır")
	t.eq(UnitQuery.alive(src).size(), 4, "alive(): freed + 2 ölü elenir")
	t.ok(not UnitQuery.alive(src).has(a_dead), "alive(): Savaş Dışı birim yok")
	t.ok(UnitQuery.alive(src).has(a2), "alive(): Down birim SAHADA sayılır")

	# ── enemies_of / allies_of / of_player ────────────────────────────────
	var enemies := UnitQuery.enemies_of(a1, src)
	t.eq(enemies.size(), 2, "enemies_of(): yalnız hayatta düşmanlar")
	t.ok(enemies.has(e1) and enemies.has(e2), "enemies_of(): doğru birimler")
	t.ok(not enemies.has(e_dead), "enemies_of(): ölü düşman elenir")

	var allies := UnitQuery.allies_of(a1, false, src)
	t.eq(allies.size(), 1, "allies_of(): kendisi HARİÇ (varsayılan)")
	t.ok(allies.has(a2), "allies_of(): Down dost dâhil")
	t.eq(UnitQuery.allies_of(a1, true, src).size(), 2, "allies_of(include_self): kendisi dâhil")

	t.eq(UnitQuery.of_player(2, src).size(), 2, "of_player(): yalnız o oyuncunun hayatta birimleri")
	t.eq(UnitQuery.enemies_of(null, src).size(), 0, "enemies_of(null) → boş (çökmez)")
	t.eq(UnitQuery.allies_of(null, false, src).size(), 0, "allies_of(null) → boş (çökmez)")

	# ── within ────────────────────────────────────────────────────────────
	t.eq(UnitQuery.within(UnitQuery.alive(src), Vector3.ZERO, 3.0).size(), 3,
		"within(3\"): a1(0) + a2(2) + e1(3) — sınır DÂHİL")
	t.eq(UnitQuery.within(UnitQuery.alive(src), Vector3.ZERO, 1.0).size(), 1,
		"within(1\"): yalnız a1")
	t.eq(UnitQuery.within([], Vector3.ZERO, 100.0).size(), 0, "within(boş liste) → boş")

	# ── standing ──────────────────────────────────────────────────────────
	var standing := UnitQuery.standing(UnitQuery.of_player(1, src))
	t.eq(standing.size(), 1, "standing(): Down olan elenir")
	t.ok(standing.has(a1), "standing(): ayaktaki kalır")

	# ── with_keyword ──────────────────────────────────────────────────────
	var kw_unit := _make(Vector3(5, 0, 0), 1, 1, false, [&"elite"])
	var src2 := {"a1": a1, "kw": kw_unit}
	t.eq(UnitQuery.with_keyword(UnitQuery.alive(src2), &"elite").size(), 1,
		"with_keyword(): yalnız keyword taşıyan")
	t.eq(UnitQuery.with_keyword(UnitQuery.alive(src2), &"leader").size(), 0,
		"with_keyword(): olmayan keyword → boş")
	t.eq(UnitQuery.with_keyword([a1], &"elite").size(), 0,
		"with_keyword(): unit_data null olan birim elenir (çökmez)")

	# ── where ─────────────────────────────────────────────────────────────
	t.eq(UnitQuery.where(UnitQuery.alive(src), func(u): return u.owner_id == 2).size(), 2,
		"where(): özel predikat")

	# ── nearest ───────────────────────────────────────────────────────────
	t.eq(UnitQuery.nearest(UnitQuery.enemies_of(a1, src), a1.global_position), e1,
		"nearest(): en yakın düşman")
	t.eq(UnitQuery.nearest([], Vector3.ZERO), null, "nearest(boş) → null")

	# ── any ───────────────────────────────────────────────────────────────
	t.ok(UnitQuery.any(UnitQuery.alive(src)), "any(): dolu liste → true")
	t.ok(not UnitQuery.any([]), "any(): boş liste → false")

	# ── bileşik sorgular ──────────────────────────────────────────────────
	t.eq(UnitQuery.enemies_within(a1, 5.0, src).size(), 1, "enemies_within(5\"): yalnız e1")
	t.eq(UnitQuery.enemies_within(a1, 50.0, src).size(), 2, "enemies_within(50\"): ikisi de")
	t.eq(UnitQuery.allies_within(a1, 5.0, false, src).size(), 1, "allies_within(): a2")
	t.eq(UnitQuery.allies_within(a1, 5.0, true, src).size(), 2, "allies_within(include_self)")
	t.eq(UnitQuery.enemies_within(null, 5.0, src).size(), 0, "enemies_within(null) → boş")

	# ── zincirleme: sonuç YENİ dizi, kaynak bozulmaz ──────────────────────
	var base := UnitQuery.alive(src)
	var base_size := base.size()
	UnitQuery.within(base, Vector3.ZERO, 1.0)
	UnitQuery.standing(base)
	t.eq(base.size(), base_size, "Filtreler kaynak diziyi MUTASYONA UĞRATMAZ")

	for u in [a1, a2, a_dead, e1, e2, e_dead, kw_unit]:
		if is_instance_valid(u):
			u.free()

## Sahte birim üretici — UnitQuery'nin okuduğu tüm alanları taşır.
## `global_position` Godot'ta yalnız AĞAÇ İÇİNDE okunabilir (dışarıda hata basıp
## Transform3D() döner) — bu yüzden sahte birimler test düğümüne eklenir.
func _make(pos: Vector3, owner_id: int, hp: int = 1, down: bool = false,
		kws: Array[StringName] = []) -> Node3D:
	var n := FakeUnit.new()
	_host.add_child(n)
	n.global_position = pos
	n.owner_id = owner_id
	n.current_health = hp
	n.is_down = down
	if not kws.is_empty():
		var ud := UnitData.new()
		# UnitData.keywords bir SÖZLÜKTÜR (keyword → değer; BLESSED(2) gibi değerli
		# keyword'ler için). Bayrak niteliğindekilere `true` yazılır.
		for kw in kws:
			ud.keywords[kw] = true
		n.unit_data = ud
	return n

class FakeUnit extends Node3D:
	var owner_id: int = 1
	var current_health: int = 1
	var is_down: bool = false
	var unit_data: Resource = null
