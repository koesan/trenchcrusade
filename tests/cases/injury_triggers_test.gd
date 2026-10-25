extends RefCounted

## YARA ZARI TETİKLEYİCİLERİ — sözleşme + izole `matches()` davranışı.
##
## Bu testin varlık sebebi: bu 11 kural eskiden `unit.gd::resolve_injury_roll` içinde 306 satırlık
## bir gövdeye gömülüydü ve HİÇBİRİ tek başına test edilemiyordu (test etmek için gerçek bir zar
## atışı + oyuncu seçimi + ağ senkronu gerekiyordu). Artık her tetikleyicinin koşulu SAF bir
## `matches(ctx)` fonksiyonu — sahte bir bağlamla doğrudan sınanabiliyor.
##
## `apply()` gövdeleri BURADA çağrılmaz: hepsi RPC/senaryo/oyuncu-seçimi yan etkisi taşır ve
## canlı testte doğrulanır. Buradaki güvence "doğru koşulda tetiklenir, yanlış koşulda tetiklenmez".

const TRG := "res://scripts/rules/injury/triggers/"

class FakeUnit extends Node3D:
	var owner_id: int = 1
	var current_health: int = 1
	var is_down: bool = false
	var unit_data: Resource = null
	var blood_markers: int = 0
	var infection_markers: int = 0
	var blessing_markers: int = 0
	var display_name: String = "Sahte"
	var devoured_unit = null
	var fireteam_partner = null
	var stood_up_this_activation: bool = false

var _host: Node = null

func _ud(kws: Array[StringName]) -> UnitData:
	var ud := UnitData.new()
	for kw in kws:
		ud.keywords[kw] = true
	return ud

func _unit(kws: Array[StringName] = [], owner_id: int = 1) -> FakeUnit:
	var u := FakeUnit.new()
	_host.add_child(u)
	u.owner_id = owner_id
	u.unit_data = _ud(kws)
	return u

func _atk(kws: Array[StringName] = []) -> Resource:
	var a := AttackData.new()
	for kw in kws:
		a.keywords[kw] = true
	return a

func _ctx(attacker, target, atk: Resource = null) -> InjuryContext:
	var c := InjuryContext.new()
	c.attacker = attacker
	c.target = target
	c.atk = atk
	return c

func run(t) -> void:
	_host = t

	# ── SÖZLEŞME: kayıtlı her tetikleyici matches+apply sunuyor mu? ────────
	# Taban 12 (`resolve_injury_roll`dan çıkarılan blok sayısı). Yeni tetikleyici EKLEMEK
	# testi kırmaz; birinin sessizce KAYBOLMASI kırar.
	var all: Array = InjuryTriggers.all()
	t.ok(all.size() >= 12, "En az 12 tetikleyici kayıtlı (%d)" % all.size())
	for trg in all:
		t.ok(trg.has_method("matches"), "%s → matches(ctx) var" % trg.resource_path.get_file())
		t.ok(trg.has_method("apply"), "%s → apply(ctx) var" % trg.resource_path.get_file())

	# Fazlar birbirinden ayrık olmalı — aynı tetikleyici iki kez çalışmamalı.
	var seen: Array = []
	var dupes: Array = []
	for trg in all:
		if seen.has(trg):
			dupes.append(trg.resource_path.get_file())
		seen.append(trg)
	t.eq(dupes.size(), 0, "Bir tetikleyici birden fazla fazda değil: %s" % str(dupes))

	# ── SLASHING ATTACK ───────────────────────────────────────────────────
	var slashing: GDScript = load(TRG + "slashing_attack.gd")
	var a1 := _unit()
	var t1 := _unit([], 2)
	var dagger := _atk([&"slashing_attack"])
	var c := _ctx(a1, t1, dagger)
	c.is_melee = true
	c.blood_before_outcome = 0
	t1.blood_markers = 1
	t.ok(slashing.matches(c), "Slashing Attack: melee + Kan İşareti kondu → tetiklenir")
	c.is_melee = false
	t.ok(not slashing.matches(c), "Slashing Attack: MENZİLLİ saldırıda tetiklenmez")
	c.is_melee = true
	c.blood_before_outcome = 1  # bu saldırı yeni marker KOYMADI
	t.ok(not slashing.matches(c), "Slashing Attack: yeni Kan İşareti yoksa tetiklenmez")
	c.blood_before_outcome = 0
	c.atk = _atk([])
	t.ok(not slashing.matches(c), "Slashing Attack: keyword'süz silahta tetiklenmez")

	# ── WHIP OF GOD (yalnız DOST hedefi melee ile OOA edince) ─────────────
	var whip: GDScript = load(TRG + "whip_of_god.gd")
	var castigator := _unit([&"whip_of_god"], 1)
	var ally := _unit([], 1)
	var enemy := _unit([], 2)
	var cw := _ctx(castigator, ally)
	cw.is_melee = true
	cw.final_outcome = InjuryResolver.Outcome.OUT_OF_ACTION
	t.ok(whip.matches(cw), "Whip of God: dost hedef melee OOA → tetiklenir")
	cw.target = enemy
	t.ok(not whip.matches(cw), "Whip of God: DÜŞMAN hedefte tetiklenmez")
	cw.target = ally
	cw.is_melee = false
	t.ok(not whip.matches(cw), "Whip of God: menzilli saldırıda tetiklenmez")
	cw.is_melee = true
	cw.final_outcome = InjuryResolver.Outcome.NO_EFFECT
	t.ok(not whip.matches(cw), "Whip of God: OOA olmadan tetiklenmez")

	# ── DARK BLESSING (OOA + keyword) ─────────────────────────────────────
	var dark: GDScript = load(TRG + "dark_blessing.gd")
	var wretched := _unit([&"dark_blessing"], 1)
	var cd := _ctx(enemy, wretched)
	cd.final_outcome = InjuryResolver.Outcome.OUT_OF_ACTION
	t.ok(dark.matches(cd), "Dark Blessing: OOA + keyword → tetiklenir")
	cd.final_outcome = InjuryResolver.Outcome.DOWN
	t.ok(not dark.matches(cd), "Dark Blessing: yalnız Down olunca tetiklenmez")

	# ── DEVOUR RELEASE (OOA + yutulmuş model) ─────────────────────────────
	var devour: GDScript = load(TRG + "devour_release.gd")
	var sin_eater := _unit([], 1)
	var victim := _unit([], 2)
	var cv := _ctx(enemy, sin_eater)
	cv.final_outcome = InjuryResolver.Outcome.OUT_OF_ACTION
	t.ok(not devour.matches(cv), "Devour: yutulmuş model yoksa tetiklenmez")
	sin_eater.devoured_unit = victim
	t.ok(devour.matches(cv), "Devour: OOA + yutulmuş model → tetiklenir")
	cv.final_outcome = InjuryResolver.Outcome.NO_EFFECT
	t.ok(not devour.matches(cv), "Devour: OOA olmadan tetiklenmez")

	# ── INFLICT PAIN (kritik + OOA DEĞİL + hedef ARTIFICIAL değil) ────────
	var pain: GDScript = load(TRG + "inflict_pain.gd")
	var vivisector := _atk([&"inflict_pain"])
	var flesh := _unit([], 2)
	var cp := _ctx(a1, flesh, vivisector)
	cp.critical_hit = true
	cp.final_outcome = InjuryResolver.Outcome.DOWN
	t.ok(pain.matches(cp), "Inflict Pain: kritik + OOA değil → tetiklenir")
	cp.final_outcome = InjuryResolver.Outcome.OUT_OF_ACTION
	t.ok(not pain.matches(cp), "Inflict Pain: hedef OOA ise tetiklenmez")
	cp.final_outcome = InjuryResolver.Outcome.DOWN
	cp.critical_hit = false
	t.ok(not pain.matches(cp), "Inflict Pain: kritik olmayan isabette tetiklenmez")
	cp.critical_hit = true
	cp.target = _unit([&"artificial"], 2)
	t.ok(not pain.matches(cp), "Inflict Pain: ARTIFICIAL hedefte tetiklenmez")

	# ── ORACLE BEAST CLOAK (sonuç zaten NO_EFFECT değilse) ────────────────
	var oracle: GDScript = load(TRG + "oracle_beast_cloak.gd")
	var hunter := _unit([&"oracle_beast_cloak"], 1)
	var co := _ctx(enemy, hunter)
	co.raw_outcome = InjuryResolver.Outcome.OUT_OF_ACTION
	t.ok(oracle.matches(co), "Oracle Beast Cloak: kötü sonuçta tetiklenir")
	co.raw_outcome = InjuryResolver.Outcome.NO_EFFECT
	t.ok(not oracle.matches(co),
		"Oracle Beast Cloak: sonuç ZATEN No Effect ise boşuna Kan harcatmaz")

	# ── SERPENT MOON (yalnız keyword taşıyan HEDEFTE) ─────────────────────
	var serpent: GDScript = load(TRG + "serpent_moon.gd")
	var sorcerer := _unit([&"blessings_of_serpent_moon"], 1)
	t.ok(serpent.matches(_ctx(enemy, sorcerer)), "Serpent Moon: keyword'lü hedefte tetiklenir")
	t.ok(not serpent.matches(_ctx(enemy, _unit([], 1))),
		"Serpent Moon: keyword'süz hedefte tetiklenmez")

	# ── PARASITE HOST vs INFECTED PROBOSCIS ayrımı ────────────────────────
	# QA denetimi: ikisini AYNI kod yolunda birleştirmek hataydı — Infected Proboscis
	# compendium'da AÇIKÇA yalnız Blood Marker der, Infection'a DÜŞMEZ.
	var parasite: GDScript = load(TRG + "parasite_host.gd")
	var herald := _unit([&"infected_proboscis"], 1)
	var cpar := _ctx(herald, enemy)
	cpar.is_melee = true
	cpar.marker_placed_this_attack = true
	t.ok(parasite.matches(cpar), "Infected Proboscis: melee + marker kondu → tetiklenir")
	cpar.marker_placed_this_attack = false
	t.ok(not parasite.matches(cpar), "Infected Proboscis: marker konmadıysa tetiklenmez")

	# ── Bağlam yardımcıları ───────────────────────────────────────────────
	var ch := _ctx(a1, ally)
	ch.final_outcome = InjuryResolver.Outcome.OUT_OF_ACTION
	t.ok(ch.is_ooa(), "InjuryContext.is_ooa()")
	t.ok(ch.is_friendly_fire(), "InjuryContext.is_friendly_fire(): aynı sahip")
	ch.target = enemy
	t.ok(not ch.is_friendly_fire(), "InjuryContext.is_friendly_fire(): farklı sahip")
	t.ok(ch.attacker_data() != null, "InjuryContext.attacker_data()")
	t.eq(_ctx(null, null).attacker_data(), null, "attacker_data(null) → null (çökmez)")

	for u in [a1, t1, castigator, ally, enemy, wretched, sin_eater, victim, flesh,
			hunter, sorcerer, herald]:
		if is_instance_valid(u):
			u.free()
