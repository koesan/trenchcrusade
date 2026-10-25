extends Node

## Trench Crusade — Headless Test Runner
##
## Çalıştırma:  godot --headless res://tests/test_main.tscn
##
## NOT: Bir SAHNE olarak çalışır (`-s` ile DEĞİL) çünkü kural resolver'ları GameLogger/GameState
## gibi autoload'lara bağlı; autoload'lar yalnız normal SceneTree başlatıldığında yüklenir.
##
## Tüm test dosyaları `res://tests/cases/*.gd` altında toplanır. Her dosya:
##   extends RefCounted
##   func run(t) -> void:   # t: assert yardımcıları olan bu runner
## Assert API:
##   t.ok(cond, msg)                → koşul doğru mu
##   t.eq(actual, expected, msg)    → eşitlik
##   t.approx(a, b, msg, eps=0.001) → yaklaşık eşitlik (float)

## ASSERT TABANI (ÇIRÇIR) — bu sayının ALTINA düşmek başlı başına BAŞARISIZLIKTIR.
##
## NEDEN: Bir test dosyasının bağımlılığı derlenmezse (örn. yeni bir `class_name` henüz
## `--import` ile kaydedilmemişse) GDScript o dosyanın `run()`'ını ORTASINDA keser. Runner
## bunu bir "başarısız assert" olarak GÖREMEZ — yalnızca toplam sayı sessizce düşer ve
## süit "✓ TÜM TESTLER GEÇTİ" der. Bu gerçekten yaşandı (4378 → 4181, 197 assert sessizce
## kayboldu). Taban değeri, kapsam kalıcı olarak arttığında YÜKSELTİLİR; asla düşürülmez.
const MIN_ASSERTS := 4990

var _total := 0
var _failed := 0
var _current_case := ""
var _fail_lines: Array[String] = []

func _ready() -> void:
	_run_all()
	if _total < MIN_ASSERTS:
		_current_case = "test_main.gd"
		_fail("ASSERT TABANI: %d < %d — bir test dosyası sessizce yarıda kesildi (çoğu zaman derleme hatası). `godot --headless --import` çalıştırıp SCRIPT ERROR satırlarına bak." \
			% [_total, MIN_ASSERTS])
	print("\n==== SONUÇ: %d assert, %d başarısız ====" % [_total, _failed])
	if _failed == 0:
		print("✓ TÜM TESTLER GEÇTİ")
	else:
		print("✗ %d ASSERT BAŞARISIZ:" % _failed)
		for line in _fail_lines:
			print("   " + line)
	get_tree().quit(1 if _failed > 0 else 0)

func _run_all() -> void:
	print("\n==== Trench Crusade Test Suite ====")
	var dir := DirAccess.open("res://tests/cases")
	if dir == null:
		_fail("tests/cases klasörü açılamadı")
		return
	var files: Array[String] = []
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".gd") and not dir.current_is_dir():
			files.append(f)
		f = dir.get_next()
	dir.list_dir_end()
	files.sort()
	if files.is_empty():
		print("(tests/cases içinde test yok)")
	for file in files:
		_current_case = file
		var script: Resource = load("res://tests/cases/" + file)
		if script == null:
			_fail("YÜKLENEMEDİ: " + file)
			continue
		var inst = script.new()
		if not inst.has_method("run"):
			_fail(file + ": run(t) metodu yok")
			continue
		print("\n-- %s --" % file)
		inst.run(self)

# ── Assert API ───────────────────────────────────────────────────────────────
func ok(cond: bool, msg: String) -> void:
	_total += 1
	if cond:
		print("  ✓ " + msg)
	else:
		_fail(msg)

func eq(actual, expected, msg: String) -> void:
	_total += 1
	if actual == expected:
		print("  ✓ " + msg)
	else:
		_fail("%s (beklenen: %s, gelen: %s)" % [msg, str(expected), str(actual)])

func approx(a: float, b: float, msg: String, eps: float = 0.001) -> void:
	_total += 1
	if absf(a - b) <= eps:
		print("  ✓ " + msg)
	else:
		_fail("%s (beklenen ~%s, gelen %s)" % [msg, str(b), str(a)])

func _fail(msg: String) -> void:
	_failed += 1
	var line := "✗ [%s] %s" % [_current_case, msg]
	print("  " + line)
	_fail_lines.append(line)
