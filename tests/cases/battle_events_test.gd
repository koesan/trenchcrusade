extends RefCounted

## SAVAŞ OLAYLARI — savaş günlüğü ve yüzen yazılar bu akışa bağlı. Yayının tek makinede yerel
## sinyale dönüştüğünü ve sonuç anahtarlarının eksiksiz eşlendiğini kilitler.

var _got: Array = []

func _on_event(kind: StringName, data: Dictionary) -> void:
	_got.append([kind, data])

func run(t) -> void:
	GameEvents.battle_event.connect(_on_event)
	BattleEvents.post(&"miss", {"a": "X", "t": "Y", "w": "W", "roll": 5})
	GameEvents.battle_event.disconnect(_on_event)
	t.eq(_got.size(), 1, "post() tek makinede battle_event yayınlar")
	if _got.size() == 1:
		t.eq(_got[0][0], &"miss", "Olay türü korunur")
		t.eq(int(_got[0][1].get("roll", 0)), 5, "Olay verisi korunur")
	for o in InjuryResolver.Outcome.values():
		t.ok(BattleEvents.OUTCOME_KEYS.has(o),
			"Yara sonucu %d günlükte bir karşılığa sahip" % o)
	for p in ["res://scripts/unit/attack_flow.gd", "res://scripts/rules/injury/injury_pipeline.gd",
			"res://scripts/rules/ability_executor.gd"]:
		t.ok(FileAccess.get_file_as_string(p).contains("BattleEvents."), "%s olay yayınlıyor" % p.get_file())
