extends RefCounted

## TEMA VARYASYONU KAPSAMI — sahnede/kodda kullanılan her `theme_type_variation` temada tanımlı mı?
##
## NEDEN: Godot tanımsız bir varyasyonu HATA VERMEDEN temel türe (Label/Button) düşürür.
## LabelSmall/LabelMuted/LabelBody bu yüzden aylarca tanımsız kaldı ve kart adları, armoury
## açıklamaları rastgele varsayılan boyutta görünüyordu (2026-10-23 UI denetimi).

const THEME_PATH := "res://assets/themes/gothic_theme.tres"
const ROOTS := ["res://scenes", "res://scripts"]

func _collect(dir_path: String, out: Array) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	for f in d.get_files():
		if f.ends_with(".tscn") or f.ends_with(".gd"):
			out.append(dir_path.path_join(f))
	for sub in d.get_directories():
		_collect(dir_path.path_join(sub), out)

func run(t) -> void:
	var theme: Theme = load(THEME_PATH)
	t.ok(theme != null, "Tema yüklendi")
	if theme == null:
		return
	var known := {}
	for type_name in theme.get_type_list():
		known[String(type_name)] = true
	var re := RegEx.create_from_string("theme_type_variation\\s*=\\s*&\"([A-Za-z]+)\"")
	var files: Array = []
	for r in ROOTS:
		_collect(r, files)
	var missing := {}
	for path in files:
		if String(path).ends_with("gothic_theme_builder.gd"):
			continue
		var src := FileAccess.get_file_as_string(path)
		for m in re.search_all(src):
			var v := m.get_string(1)
			if not known.has(v):
				missing[v] = String(path).get_file()
	t.eq(missing.size(), 0, "Kullanılan tüm tema varyasyonları tanımlı %s" % str(missing))
