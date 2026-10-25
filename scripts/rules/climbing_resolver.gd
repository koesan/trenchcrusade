class_name ClimbingResolver
extends RefCounted

## Dikey hareket (Climbing / Jumping Down / Falling) çözümleyici — STATELESS.
## Bir hareket hedefinin düz mü, yukarı serbest geçiş mi (trench wall ≤3"), sheer-surface
## tırmanma mı, yoksa aşağı atlama mı olduğunu compendium'a göre belirler ve izlenecek L-yolu üretir.
##
## Dönüş sözlüğü:
##   type: "flat" | "walkover_up" | "climb" | "walkover_down" | "climb_down" | "invalid"
##   path: PackedVector3Array (climb/walkover için L-yol)
##   needs_risky: bool (climb / climb_down için true — Risky Success gerekir)
##   reason: String (invalid için)
##
## İNME GÜVENLİDİR: iniş ≤3" serbest (walkover_down); >3" kontrollü tırmanarak iniş (climb_down,
## Risky). Gönüllü Move ARTIK "jump_down"+Falling Injury üretmez (compendium: sheer surface'ten
## kontrollü inme Risky ama düşmesiz). Falling Injury yalnız başarısız Diving Charge / zorunlu
## düşüş için ayrı akışlarda kalır.

## is_flying (FLYING keyword): dikey hareket "havadan" ölçülür — tırmanma Risky'si YOK ve düşme
## yarası YOK. Bu yüzden yukarı/aşağı her sheer geçiş serbest walkover olur (bütçe elverdiğince).
static func evaluate(unit, target: Vector3, max_dist: float, is_flying: bool = false) -> Dictionary:
	var start: Vector3 = unit.global_position
	var dy: float = target.y - start.y
	var horiz: float = Vector2(target.x - start.x, target.z - start.z).length()

	# Küçük yükseklik farkı → düz hareket (NavMesh hallediyor)
	if abs(dy) <= GameState.VERTICAL_STEP_MAX:
		return {"type": "flat"}

	if dy > 0.0:
		# ── YUKARI ──
		var base_pt: Vector3 = Vector3(target.x, start.y, target.z)  # hedefin dibi (duvar tabanı)
		var cost: float = horiz + dy  # yatay + yükseklik hareket bütçesine sayılır
		if cost > max_dist + 0.5:
			# Compendium: tırmanma için TÜM yüzeyi geçecek harekete sahip olunmalı (yarıda kalınamaz).
			return {"type": "invalid", "reason": "Yukarı çıkmak için yeterli hareket yok",
				"reason_key": "MOVE_FAIL_CLIMB_UP"}
		var up_path := PackedVector3Array([start, base_pt, target])
		if is_flying or dy <= GameState.CLIMB_FREE_MAX:
			# Trench wall / open (≤3") veya FLYING — serbest geçilir, roll yok
			return {"type": "walkover_up", "path": up_path}
		# Sheer surface (>3") — Risky Success (tırmanma)
		return {"type": "climb", "path": up_path, "needs_risky": true}

	# ── AŞAĞI — dikey serbest (yalnız yatay hareket bütçesine sayılır), İNİŞ GÜVENLİDİR ──
	if horiz > max_dist + 0.5:
		return {"type": "invalid", "reason": "Aşağı inmek için yeterli hareket yok",
			"reason_key": "MOVE_FAIL_CLIMB_DOWN"}
	var edge_pt: Vector3 = Vector3(target.x, start.y, target.z)  # kenar (hedefin üstü)
	var down_path := PackedVector3Array([start, edge_pt, target])
	if is_flying or -dy <= GameState.CLIMB_FREE_MAX:
		# ≤3" veya FLYING — serbest iniş (Open terrain), roll yok, düşme yok.
		return {"type": "walkover_down", "path": down_path}
	# >3" sheer surface — kontrollü tırmanarak iniş: Risky Success, düşme yarası YOK.
	return {"type": "climb_down", "path": down_path, "needs_risky": true}
