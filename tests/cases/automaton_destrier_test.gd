extends RefCounted

## P1-1 (Mamluk Faris — Automaton Destrier): compendium — harita kenarının 1" içine VE en yakın
## düşmandan 8"+ uzağa serbest yerleşim. SAF predikat testi (deploy RPC akışı headless test edilemez).

const MechanicsResolver = preload("res://scripts/rules/mechanics_resolver.gd")

func run(t) -> void:
	var bounds := AABB(Vector3(0, 0, 0), Vector3(40, 0, 30))  # 40x30 saha

	# ── Bounds hesaplanmamışsa (size=ZERO) her zaman geçersiz ──
	t.ok(not MechanicsResolver.automaton_destrier_placement_valid(
		Vector3(0.5, 0, 15), AABB(), 1.0, [], 8.0), "Bounds hesaplanmamış → geçersiz")

	# ── Kenara 1" içi, düşman yok → geçerli ──
	t.ok(MechanicsResolver.automaton_destrier_placement_valid(
		Vector3(0.5, 0, 15), bounds, 1.0, [], 8.0), "Sol kenara 0.5\" → geçerli")
	t.ok(MechanicsResolver.automaton_destrier_placement_valid(
		Vector3(39.5, 0, 15), bounds, 1.0, [], 8.0), "Sağ kenara 0.5\" → geçerli")
	t.ok(MechanicsResolver.automaton_destrier_placement_valid(
		Vector3(20, 0, 0.2), bounds, 1.0, [], 8.0), "Üst kenara 0.2\" → geçerli")

	# ── Kenardan uzak (merkez) → geçersiz ──
	t.ok(not MechanicsResolver.automaton_destrier_placement_valid(
		Vector3(20, 0, 15), bounds, 1.0, [], 8.0), "Saha ortası → geçersiz (kenara yakın değil)")

	# ── Kenara yakın ama düşmana < 8" → geçersiz ──
	t.ok(not MechanicsResolver.automaton_destrier_placement_valid(
		Vector3(0.5, 0, 15), bounds, 1.0, [Vector3(2, 0, 15)], 8.0),
		"Kenara yakın ama düşman 3\" içinde → geçersiz")

	# ── Kenara yakın, düşman yeterince uzak → geçerli ──
	t.ok(MechanicsResolver.automaton_destrier_placement_valid(
		Vector3(0.5, 0, 15), bounds, 1.0, [Vector3(30, 0, 15)], 8.0),
		"Kenara yakın, düşman uzak → geçerli")

	# ── SNAP: tıklama toleransı (kullanıcı canlı bildirimi — 1" şerit fare ile yakalanamıyordu) ──
	# Snap radius (12) dışında → null (normal ret mesajı gösterilmeli).
	t.ok(MechanicsResolver.automaton_destrier_snap_edge_position(
		Vector3(20, 0, 15), bounds, 1.0, 12.0) == null, "Saha ortası, snap yarıçapı dışında → null")

	# Sol kenara 5" mesafede (snap yarıçapı 12 içinde) → sol kenara hizalanır, Z korunur.
	var snapped_left = MechanicsResolver.automaton_destrier_snap_edge_position(
		Vector3(5.0, 0, 15), bounds, 1.0, 12.0)
	t.ok(snapped_left != null, "Sol kenara 5\" → snap null DEĞİL")
	t.ok(is_equal_approx(snapped_left.x, 0.5), "Sol kenara hizalanmış x=0.5 (edge_tolerance*0.5)")
	t.ok(is_equal_approx(snapped_left.z, 15.0), "Kenar boyunca eksen (z) korunur")

	# Sağ kenara yakın → sağ kenara hizalanır.
	var snapped_right = MechanicsResolver.automaton_destrier_snap_edge_position(
		Vector3(35.0, 0, 15), bounds, 1.0, 12.0)
	t.ok(snapped_right != null and is_equal_approx(snapped_right.x, 39.5), "Sağ kenara hizalanmış x=39.5")

	# Snap edildikten sonra düşman mesafesi hâlâ ihlal ediliyorsa (çağıran taraf) geçersiz kalmalı —
	# bu fonksiyon SADECE geometriyi hizalar, düşman kontrolünü YAPMAZ (çağıran ayrıca doğrular).
	t.ok(not MechanicsResolver.automaton_destrier_placement_valid(
		snapped_left, bounds, 1.0, [Vector3(1, 0, 15)], 8.0),
		"Hizalanmış konum yine de düşmana yakınsa placement_valid geçersiz döner")
