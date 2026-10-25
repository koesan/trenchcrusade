extends RefCounted

## AbilityExecutor.resolve_target — serialize edilmiş yetenek hedefini gerçek nesneye çözer.
## REGRESYON: Node.name bir StringName'dir ve `x is String` bir StringName'i YAKALAMAZ. Eski
## server_request_ability `if serialized is String` kullandığı için YEREL oyunda birim-hedefli
## yeteneklerin hedefi hiç çözülmüyordu → "Geçerli hedef yok" → "butona basınca bir şey olmuyor".
## Bu test hem StringName (asıl bug) hem String yolunu kilitler.

const AbilityExecutor = preload("res://scripts/rules/ability_executor.gd")

func run(t) -> void:
	var stub := RefCounted.new()
	GameState.units[&"__test_unit__"] = stub

	# StringName (Node.name'in gerçek türü) → birim çözülmeli. ESKİ BUG BURADAYDI.
	t.eq(AbilityExecutor.resolve_target(StringName("__test_unit__")), stub,
		"StringName hedef adı birime çözülür")

	# String de çözülmeli (MP tel serileştirmesi String'e dönüştürebilir).
	t.eq(AbilityExecutor.resolve_target("__test_unit__"), stub,
		"String hedef adı birime çözülür")

	# Bilinmeyen ad → null.
	t.eq(AbilityExecutor.resolve_target(&"__yok__"), null, "Bilinmeyen ad → null")

	# Vector3 (position hedefli yetenek, örn. shadow_step) aynen döner.
	var v := Vector3(1, 2, 3)
	t.eq(AbilityExecutor.resolve_target(v), v, "Vector3 konum aynen döner")

	# null aynen döner.
	t.eq(AbilityExecutor.resolve_target(null), null, "null aynen döner")

	GameState.units.erase(&"__test_unit__")
