extends RefCounted

## FAZ A-2: Yerleştirme reddi sebepleri TEK KAYNAK (DeployValidator) + her sebep iki dilde de
## karşılığı olmalı. Aksi halde toast ham anahtar ("DEPLOY_FAIL_ZONE") gösterir. Bu test, deploy
## reddinin daima okunabilir bir mesaj üreteceğini kilitler. Ayrıca too_close_to_any saf predikatı.

const DeployValidator = preload("res://scripts/rules/deploy_validator.gd")

func _load_json(path: String) -> Dictionary:
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	return data if data is Dictionary else {}

func run(t) -> void:
	var tr := _load_json("res://assets/localization/tr.json")
	var en := _load_json("res://assets/localization/en.json")
	t.ok(not tr.is_empty(), "tr.json yüklendi")
	t.ok(not en.is_empty(), "en.json yüklendi")

	t.ok(DeployValidator.ALL_REASONS.size() >= 11, "en az 11 ret sebebi tanımlı")
	for key in DeployValidator.ALL_REASONS:
		t.ok(tr.has(key) and String(tr.get(key, "")) != "", "TR karşılığı var: " + key)
		t.ok(en.has(key) and String(en.get(key, "")) != "", "EN karşılığı var: " + key)

	# too_close_to_any: saf çakışma predikatı
	var occupied := [Vector3(0, 0, 0), Vector3(5, 0, 0)]
	t.ok(DeployValidator.too_close_to_any(Vector3(1, 0, 0), occupied, 2.0), "1m mesafe → çok yakın")
	t.ok(not DeployValidator.too_close_to_any(Vector3(2.5, 0, 0), occupied, 2.0), "2.5m mesafe → uygun")
	t.ok(not DeployValidator.too_close_to_any(Vector3(0, 0, 0), [], 2.0), "boş harita → uygun")
