extends RefCounted

## ORTAK AKTİVASYON (compendium denetimi, Adım 6) — Fireteam / Sworn Brethren / Faithful Followers.
## Compendium (warbands/new-antioch.md): "Models that are part of the same Fireteam can be
## Activated simultaneously... if the Activation of either member of the Fireteam ends (due to a
## failed Risky Success Roll for example), it immediately ends for the other model".
## Faithful Followers (trench-pilgrims.md): "...you can also Activate the Mendelist Monk... If the
## Activation of either model ends, the other model can carry on with its Activation normally."

class FakeUnit extends Node3D:
	var owner_id: int = 1
	var current_health: int = 1
	var has_moved: bool = false
	var activation_started: bool = false
	var actions_taken: Array = []
	var stood_up_this_activation: bool = false
	var unit_data: Resource = null
	var fireteam_partner = null
	var joint_partner = null
	var fireteam_sworn: bool = false
	var display_name: String = "Sahte"

var _host: Node = null

func _unit(kws: Array[StringName], abilities: Array = [], owner_id: int = 1) -> FakeUnit:
	var ud := UnitData.new()
	for kw in kws:
		ud.keywords[kw] = 1
	for ab_id in abilities:
		var ab := AbilityData.new()
		ab.ability_id = ab_id
		ud.abilities.append(ab)
	var u := FakeUnit.new()
	u.owner_id = owner_id
	u.unit_data = ud
	_host.add_child(u)
	return u

func _commit(u: FakeUnit) -> void:
	u.activation_started = true
	u.actions_taken = ["move"]

func run(t) -> void:
	_host = t

	# ── Fireteam: iki [New Antioch] modeli, oyuncu seçimiyle kurulur ─────────
	var a := _unit([&"new_antioch"])
	var b := _unit([&"new_antioch"])
	var c := _unit([&"new_antioch"])
	var d := _unit([&"new_antioch"])
	var e := _unit([&"new_antioch"])
	var f := _unit([&"new_antioch"])
	var all: Array = [a, b, c, d, e, f]
	_commit(a)
	t.eq(ActivationRules.joint_kind(a, b, all), ActivationRules.JOINT_FIRETEAM,
		"NA: aktif A ile eşsiz B ortak aktive edilebilir (yeni Fireteam)")
	t.eq(ActivationRules.fireteam_form(a, b, all), &"new_antioch", "Fireteam türü: new_antioch")
	ActivationRules.apply_link(a, b, &"new_antioch")
	t.ok(a.fireteam_partner == b and b.fireteam_partner == a, "Bağ kalıcı Fireteam olarak yazıldı")
	t.ok(a.joint_partner == b, "Ortak aktivasyon eşi kaydedildi")
	t.eq(ActivationRules.joint_kind(a, c, all), ActivationRules.JOINT_NONE,
		"Bir model aynı anda yalnız bir eşle ortak aktive olur")
	var units := {"A": a, "B": b, "C": c}
	t.eq(ActivationRules.selection_block_reason(units, b, ""), "",
		"Taahhüt edilmiş A varken Fireteam eşi B seçilebilir")
	t.ok(ActivationRules.selection_block_reason(units, c, "") != "",
		"Taahhüt edilmiş A varken eşi olmayan C seçilemez")

	# 2 Fireteam sınırı
	c.fireteam_partner = d
	d.fireteam_partner = c
	t.eq(ActivationRules.fireteam_form(e, f, all), &"",
		"New Antioch en fazla 2 Fireteam kurar — üçüncüsü reddedilir")
	var hl1 := _unit([&"heretic_legion"])
	var hl2 := _unit([&"heretic_legion"])
	t.eq(ActivationRules.fireteam_form(hl1, hl2, [hl1, hl2]), &"", "NA dışı modeller Fireteam kuramaz")

	# ── Bitiş sonuçları ─────────────────────────────────────────────────────
	b.activation_started = true
	b.actions_taken = ["shoot"]
	t.eq(ActivationRules.partner_outcome(a, false), &"end",
		"Fireteam: zorunlu bitiş (Risky başarısızlığı) eşin aktivasyonunu da bitirir")
	t.eq(ActivationRules.partner_outcome(a, true), &"continue",
		"Fireteam: A eylemlerini tüketti → başlamış eş B devam eder, sıra rakibe geçmez")
	b.actions_taken = []
	b.activation_started = false
	t.eq(ActivationRules.partner_outcome(a, true), &"none",
		"Eş hiç başlamadıysa doğal bitişte sıra normal devredilir")

	# ── Sworn Brethren: Mamluk + [Elite], NA sınırına sayılmaz ──────────────
	var mamluk := _unit([], [&"sworn_brethren"])
	var lieutenant := _unit([&"new_antioch", &"elite"])
	var grunt := _unit([&"new_antioch"])
	all.append_array([mamluk, lieutenant, grunt])
	_commit(mamluk)
	t.eq(ActivationRules.fireteam_form(mamluk, lieutenant, all), &"sworn",
		"Sworn Brethren: Mamluk + Elite → Fireteam (2 NA Fireteam dolu olsa da)")
	t.eq(ActivationRules.fireteam_form(mamluk, grunt, all), &"", "Mamluk Elite olmayanla eşleşemez")
	ActivationRules.apply_link(mamluk, lieutenant, &"sworn")
	t.ok(mamluk.fireteam_sworn and lieutenant.fireteam_sworn, "Sworn Brethren bayrağı iki modelde")

	# ── Faithful Followers: tek yönlü, 1" içinde, biri bitince diğeri sürer ──
	var monk := _unit([&"faithful_followers"])
	var pilgrim := _unit([])
	var far := _unit([])
	far.position = Vector3(5, 0, 0)
	monk.position = Vector3(0.5, 0, 0)
	_commit(pilgrim)
	t.eq(ActivationRules.joint_kind(pilgrim, monk, [monk, pilgrim]), ActivationRules.JOINT_FOLLOWERS,
		"Faithful Followers: 1\" içindeki modelin aktivasyonuna Monk katılabilir")
	_commit(far)
	t.eq(ActivationRules.joint_kind(far, monk, [monk, far]), ActivationRules.JOINT_NONE,
		"Faithful Followers: 1\" dışındaysa katılamaz")
	ActivationRules.apply_link(pilgrim, monk, &"")
	t.ok(pilgrim.fireteam_partner == null, "Faithful Followers kalıcı Fireteam kurmaz")
	monk.activation_started = true
	monk.actions_taken = ["shoot"]
	t.eq(ActivationRules.partner_outcome(pilgrim, false), &"continue",
		"Faithful Followers: zorunlu bitişte bile diğer model devam eder")

	# ── Kaynak: zorla partner geçişi kaldırıldı ─────────────────────────────
	var tm: String = FileAccess.get_file_as_string("res://scripts/turn_manager/turn_manager.gd")
	t.ok(not tm.contains("forced_next_activator = partner.name"), "Fireteam partneri artık ZORLA sıraya sokulmuyor")
	t.ok(not tm.contains("forced_next_activator = fu2.name"), "Faithful Followers artık zorunlu değil")
	t.ok(not FileAccess.get_file_as_string("res://scripts/rules/faction_rules.gd").contains("func setup_new_antioch_fireteams"),
		"Düğüm adı sırasına göre otomatik eşleştirme kaldırıldı")

	for u in all + [monk, pilgrim, far, hl1, hl2]:
		u.queue_free()
