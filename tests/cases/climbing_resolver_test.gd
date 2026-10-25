extends RefCounted

## ClimbingResolver.evaluate — dikey hareketin sınıflandırılması (compendium climbing-and-jumping).
## Kurallar:
##   • |dy| ≤ VERTICAL_STEP_MAX → "flat" (navmesh halleder).
##   • Yukarı ≤3" (CLIMB_FREE_MAX) → "walkover_up" (serbest, roll yok).
##   • Yukarı >3" (sheer) → "climb" (Risky Success gerekir).
##   • İniş ≤3" → "walkover_down" (serbest, roll yok, düşme YARASI YOK).
##   • İniş >3" (sheer) → "climb_down" (kontrollü Risky Success, düşme YARASI YOK).
##   • Gönüllü "jump_down"+Falling Injury normal Move'dan KALDIRILDI — iniş güvenlidir.
##   • Yatay hareket bütçesi yetmezse → "invalid".

const ClimbingResolver = preload("res://scripts/rules/climbing_resolver.gd")

class _Stub:
	var global_position: Vector3

func _u(pos: Vector3) -> _Stub:
	var s := _Stub.new()
	s.global_position = pos
	return s

func run(t) -> void:
	var step: float = GameState.VERTICAL_STEP_MAX
	var free: float = GameState.CLIMB_FREE_MAX  # 3"
	var u := _u(Vector3.ZERO)
	var maxd := 6.0

	# 1) Küçük yükseklik farkı → flat.
	t.eq(ClimbingResolver.evaluate(u, Vector3(0.5, step * 0.5, 0), maxd).get("type"), "flat",
		"Küçük dy → flat")

	# 2) Yukarı ≤3" → walkover_up (serbest, risky yok).
	var up_free := ClimbingResolver.evaluate(u, Vector3(1, 2, 0), maxd)
	t.eq(up_free.get("type"), "walkover_up", "Yukarı 2\" → walkover_up")
	t.ok(not up_free.get("needs_risky", false), "walkover_up risky gerektirmez")

	# 3) Yukarı >3" → climb (Risky).
	var up_climb := ClimbingResolver.evaluate(u, Vector3(1, 4, 0), maxd)
	t.eq(up_climb.get("type"), "climb", "Yukarı 4\" → climb")
	t.ok(up_climb.get("needs_risky", false), "climb Risky gerektirir")

	# 4) Yukarı, bütçe yetmiyor → invalid (+ ekranda gösterilecek sebep anahtarı).
	var up_bad := ClimbingResolver.evaluate(u, Vector3(5, 4, 0), maxd)
	t.eq(up_bad.get("type"), "invalid", "Yukarı cost>max → invalid")
	t.eq(up_bad.get("reason_key"), "MOVE_FAIL_CLIMB_UP", "tırmanma reddi reason_key taşır")

	# 5) İniş ≤3" → walkover_down (serbest, risky yok, DÜŞME YOK).
	var down_free := ClimbingResolver.evaluate(u, Vector3(1, -2, 0), maxd)
	t.eq(down_free.get("type"), "walkover_down", "İniş 2\" → walkover_down")
	t.ok(not down_free.get("needs_risky", false), "walkover_down risky gerektirmez")
	t.ok(not down_free.has("fall_height"), "walkover_down düşme yüksekliği taşımaz (yara yok)")

	# 6) İniş >3" → climb_down (kontrollü Risky, DÜŞME YARASI YOK).
	var down_climb := ClimbingResolver.evaluate(u, Vector3(1, -4, 0), maxd)
	t.eq(down_climb.get("type"), "climb_down", "İniş 4\" → climb_down")
	t.ok(down_climb.get("needs_risky", false), "climb_down kontrollü Risky gerektirir")
	t.ok(not down_climb.has("fall_height"), "climb_down düşme yüksekliği taşımaz (yara yok)")

	# 7) Gönüllü hareket ASLA jump_down üretmez (iniş güvenli).
	t.ok(ClimbingResolver.evaluate(u, Vector3(1, -4, 0), maxd).get("type") != "jump_down",
		"Gönüllü iniş jump_down üretmez")

	# 8) İniş, yatay bütçe yetmiyor → invalid (+ sebep anahtarı).
	var down_bad := ClimbingResolver.evaluate(u, Vector3(8, -2, 0), maxd)
	t.eq(down_bad.get("type"), "invalid", "İniş horiz>max → invalid")
	t.eq(down_bad.get("reason_key"), "MOVE_FAIL_CLIMB_DOWN", "iniş reddi reason_key taşır")

	# 12) Hareket ret sebep anahtarları iki dilde de karşılığı olmalı (toast ham anahtar göstermesin).
	var tr_f = FileAccess.open("res://assets/localization/tr.json", FileAccess.READ)
	var en_f = FileAccess.open("res://assets/localization/en.json", FileAccess.READ)
	var tr_d = JSON.parse_string(tr_f.get_as_text()) if tr_f else {}
	var en_d = JSON.parse_string(en_f.get_as_text()) if en_f else {}
	for key in ["MOVE_FAIL_CLIMB_UP", "MOVE_FAIL_CLIMB_DOWN", "MOVE_FAIL_OFF_GROUND", "MOVE_FAIL_GENERIC"]:
		t.ok(tr_d.has(key) and String(tr_d[key]) != "", "TR karşılığı var: " + key)
		t.ok(en_d.has(key) and String(en_d[key]) != "", "EN karşılığı var: " + key)

	# 9) Eşik tutarlılığı: "flat" sayılan her yükseklik (VERTICAL_STEP_MAX) navmesh'in
	#    bağladığı (NAV_AGENT_MAX_CLIMB) değerin altında olmalı — aksi halde 0.6/0.8 ölü
	#    bölgesi doğar (kodda flat ama navmesh geçemez → birim hareket etmez).
	t.ok(GameState.VERTICAL_STEP_MAX <= GameState.NAV_AGENT_MAX_CLIMB,
		"VERTICAL_STEP_MAX ≤ NAV_AGENT_MAX_CLIMB (ölü bölge yok)")

	# 10) FLYING (compendium): dikey hareket "havadan" ölçülür — tırmanma Risky'si YOK, düşme YOK.
	#     Yukarı >3" bile serbest walkover_up.
	var fly_up := ClimbingResolver.evaluate(u, Vector3(1, 4, 0), maxd, true)
	t.eq(fly_up.get("type"), "walkover_up", "Flying yukarı 4\" → walkover_up (Risky yok)")
	t.ok(not fly_up.get("needs_risky", false), "Flying yukarı Risky gerektirmez")

	# 11) FLYING: aşağı >3" serbest walkover_down (kontrollü climb_down/Risky değil).
	var fly_down := ClimbingResolver.evaluate(u, Vector3(1, -4, 0), maxd, true)
	t.eq(fly_down.get("type"), "walkover_down", "Flying iniş 4\" → walkover_down (Risky yok)")
	t.ok(not fly_down.get("needs_risky", false), "Flying iniş Risky gerektirmez")
