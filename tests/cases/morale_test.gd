extends RefCounted

## TurnManager.morale_must_check — Morale Check tetikleme kuralı (compendium morale-phase).
## Eşik: ayakta <= floor(N/2) (yani modellerin en az yarısı, yukarı yuvarlanmış, Down/OOA).
## Ayrıca: zaten Shaken ordu, eşiğin ÜSTÜNDE olsa bile her tur yeniden test edilir.

const TurnManager = preload("res://scripts/turn_manager/turn_manager.gd")

func run(t) -> void:
	var M = TurnManager.morale_must_check

	# N=5: yarısı (yukarı yuvarlanmış) = 3 Down/OOA → ayakta <= 2 tetikler.
	t.ok(not M.call(5, 3, false), "5 modelde 3 ayakta → kontrol YOK")
	t.ok(M.call(5, 2, false), "5 modelde 2 ayakta (3 düştü) → kontrol VAR")

	# N=4: floor(4/2)=2 → ayakta <= 2 tetikler.
	t.ok(not M.call(4, 3, false), "4 modelde 3 ayakta → kontrol YOK")
	t.ok(M.call(4, 2, false), "4 modelde 2 ayakta → kontrol VAR")

	# N=1: floor(1/2)=0 → ayakta 0 tetikler.
	t.ok(not M.call(1, 1, false), "1 model ayakta → kontrol YOK")
	t.ok(M.call(1, 0, false), "tek model düştü → kontrol VAR")

	# Shaken ordu: eşiğin üstünde bile OLSA yeniden test (P1-2 düzeltmesi).
	t.ok(M.call(5, 5, true), "Shaken ordu tam kadro olsa da yeniden test edilir")
	t.ok(M.call(10, 9, true), "Shaken ordu eşik üstünde de test edilir")

	# initial=0 (kenar) → kontrol yok (Shaken değilse).
	t.ok(not M.call(0, 0, false), "initial=0 → kontrol YOK")

	# ── Black Grail Morale korkusu (faction rule): rakip Black Grail ise −1 DICE,
	#    ama kontrolü yapan warband Court VEYA Black Grail ise MUAF. ──
	var F = TurnManager.morale_fear_penalty
	t.eq(F.call(&"iron_sultanate", [&"cult_of_the_black_grail"]), -1,
		"Sultanate vs Black Grail → −1 Morale")
	t.eq(F.call(&"trench_pilgrims", [&"new_antioch"]), 0,
		"Black Grail olmayan rakip → ceza yok")
	t.eq(F.call(&"court_of_seven_headed_serpent", [&"cult_of_the_black_grail"]), 0,
		"Court, Black Grail'e karşı MUAF")
	t.eq(F.call(&"cult_of_the_black_grail", [&"cult_of_the_black_grail"]), 0,
		"Black Grail kendisi MUAF")
	t.eq(F.call(&"heretic_legion", [&"iron_sultanate", &"cult_of_the_black_grail"]), -1,
		"Rakiplerden biri Black Grail → −1")
