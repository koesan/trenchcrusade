extends RefCounted

## Kullanıcı isteği: "Hareket'e basıyorum, bir düşmana/dosta tıklarsam o yöne doğru gitsin,
## menzil bitince dursun" — önceden Move/Retreat seçiliyken bir UNITE tıklamak hiçbir şey
## yapmıyordu (kod yalnızca boş harita noktalarını hedef olarak kabul ediyordu, unit tıklaması
## sessizce sadece o unit'i SEÇİYORDU). map_input.gd::_move_click_target artık düşman hedefte
## ENGAGE_RANGE'in biraz ötesinde (server_request_move_action'ın "düşmanın 1 inç yakınına
## giremez" reddine takılmayacak) bir nokta, dost hedefte ise doğrudan konumu döndürür.

func run(t) -> void:
	var map_input_script: GDScript = load("res://scripts/input/map_input.gd")
	var map_input = map_input_script.new()

	# global_position okuma/yazma is_inside_tree() gerektirir (orphan Node3D Transform3D() döner) —
	# test düğümleri (t, test_main.gd'nin kendisi) gerçek bir Node, sahte birimler ona eklenir.
	var mover := Node3D.new()
	t.add_child(mover)
	mover.global_position = Vector3(0, 0, 0)
	var enemy := Node3D.new()
	t.add_child(enemy)
	enemy.global_position = Vector3(10, 0, 0)
	var friendly := Node3D.new()
	t.add_child(friendly)
	friendly.global_position = Vector3(0, 0, 5)

	# Dost hedef: doğrudan konumuna doğru (kısıt yok).
	var friendly_target: Vector3 = map_input._move_click_target(mover, friendly, false)
	t.eq(friendly_target, friendly.global_position, "Dost unit tıklanınca hedef TAM konumu")

	# Düşman hedef: ENGAGE_RANGE'in biraz ötesinde durdurulmuş bir nokta, düşmandan UZAKLIKTA.
	var enemy_target: Vector3 = map_input._move_click_target(mover, enemy, true)
	var dist_to_enemy: float = enemy_target.distance_to(enemy.global_position)
	t.ok(dist_to_enemy >= GameState.ENGAGE_RANGE,
		"Düşman tıklanınca hedef, ENGAGE_RANGE (%.2f) kadar geride durdurulur (mesafe: %.2f)" \
			% [GameState.ENGAGE_RANGE, dist_to_enemy])
	# Hedef, mover ile düşman ARASINDA (doğru yönde) olmalı — mover'a düşmandan daha yakın değil.
	t.ok(enemy_target.distance_to(mover.global_position) < mover.global_position.distance_to(enemy.global_position),
		"Hedef nokta, mover'dan düşmana doğru İLERİ konumda (yönü doğru)")

	# Aynı konumdaysa (dist=0) çökmemeli, düşmanın kendi konumunu güvenli varsayılan olarak döner.
	var same_pos_target: Vector3 = map_input._move_click_target(mover, mover, true)
	t.eq(same_pos_target, mover.global_position, "Sıfır mesafe durumunda güvenli varsayılan (çökme yok)")

	mover.free()
	enemy.free()
	friendly.free()
	map_input.free()
