extends RefCounted

## FAZ A-3: Aktif yetenek durumları (Hide/Fortify/Shadow Walker) seçili birim panelinde kalıcı
## rozetle gösterilir. Rozet metinleri iki dilde de karşılığı olmalı (aksi halde ham anahtar görünür).

const KEYS := ["BADGE_HIDDEN", "BADGE_FORTIFIED", "BADGE_SHADOW"]

func _load_json(path: String) -> Dictionary:
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	return data if data is Dictionary else {}

func run(t) -> void:
	var tr := _load_json("res://assets/localization/tr.json")
	var en := _load_json("res://assets/localization/en.json")
	for key in KEYS:
		t.ok(tr.has(key) and String(tr.get(key, "")) != "", "TR karşılığı var: " + key)
		t.ok(en.has(key) and String(en.get(key, "")) != "", "EN karşılığı var: " + key)
