extends RefCounted

## ÇIRÇIR: sahadaki birimler `UnitQuery` üzerinden sorgulanır, ham döngüyle DEĞİL.
##
## `for u in GameState.units` deseni her çağrı yerinde `is_instance_valid` / `current_health > 0`
## / `owner_id` filtrelerinin ELLE tekrarlanmasını gerektiriyordu; birini unutmak sessiz bir bug
## üretiyordu (gerçek örnek: siper ölü düşmanlara bakıyordu). 68 çağrı yeri UnitQuery'ye taşındı.
##
## Bu test yeni ham döngü eklenmesini engeller. Gerçekten gerekiyorsa (örn. `_process` içinde
## ayırma yapmamak için) MUAF listesine gerekçesiyle ekle — sessizce geri gelmesin.

## Taranan klasörler.
const SCAN_DIRS := ["res://scripts", "res://scenes"]

## Ham döngüye İZİN VERİLEN dosyalar (yol → gerekçe).
const EXEMPT := {
	"res://scripts/rules/unit_query.gd": "API'nin kendisi — tek meşru ham erişim noktası",
}

func _scan(dir_path: String, out: Array) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		var full := dir_path.path_join(f)
		if d.current_is_dir():
			if not f.begins_with("."):
				_scan(full, out)
		elif f.ends_with(".gd"):
			out.append(full)
		f = d.get_next()
	d.list_dir_end()

func run(t) -> void:
	var files: Array = []
	for dir in SCAN_DIRS:
		_scan(dir, files)
	t.ok(files.size() > 100, "Tarama %d .gd dosyası buldu" % files.size())

	var offenders: Array = []
	for path in files:
		if EXEMPT.has(path):
			continue
		var fa := FileAccess.open(path, FileAccess.READ)
		if fa == null:
			continue
		var txt := fa.get_as_text()
		fa.close()
		# Yorum satırları sayılmaz — yalnız GERÇEK kod.
		for line in txt.split("\n"):
			var stripped := line.strip_edges()
			if stripped.begins_with("#"):
				continue
			if stripped.begins_with("for ") and stripped.contains("in GameState.units"):
				offenders.append("%s → %s" % [path.get_file(), stripped])

	t.eq(offenders.size(), 0,
		"Ham `for ... in GameState.units` döngüsü yok (UnitQuery kullan): %s" % str(offenders))

	# API'nin kendisi yerinde ve eksiksiz mi?
	var q := load("res://scripts/rules/unit_query.gd")
	t.ok(q != null, "unit_query.gd yüklenebiliyor")
	for fn in ["all", "alive", "enemies_of", "allies_of", "of_player", "roster_of",
			"within", "within_exclusive", "standing", "with_keyword", "where",
			"nearest", "any", "engaged_enemies", "enemies_within", "allies_within"]:
		t.ok(q.has_method(fn), "UnitQuery.%s() mevcut" % fn)
