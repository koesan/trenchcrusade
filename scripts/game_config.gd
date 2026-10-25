extends Node

## GameConfig — oyunun DENGE ve ZAMANLAMA ayarlarının TEK KAYNAĞI.
##
## Dil dosyaları (tr.json/en.json) mantığıyla: tüm ayar sayıları tek bir düzenlenebilir JSON'da
## (`assets/data/config/game_config.json`) toplanır. Kod, değerleri buradan okur; ayar için kod
## düzenlemeye gerek yoktur — sadece JSON'u değiştir.
##
## GÜVENİLİRLİK: JSON yüklenirken DOĞRULANIR. Eksik/yanlış-tipli/typo anahtar loglanır ve koddaki
## GÜVENLİ VARSAYILANA düşülür (DEFAULTS). Böylece bozuk/eksik JSON oyunu çökertmez.
##
## GÖRSEL RENKLER burada DEĞİL: tip güvenli `GameVisualColors` .tres kaynağında düzenlenir
## (bkz. balance JSON'daki "_notes"). İki kaynak/drift olmasın diye renkler JSON'a kopyalanmadı.
##
## Autoload sırası: GameLogger'dan SONRA, GameState'ten ÖNCE (project.godot). Böylece GameState'in
## sabit-değerleri (member-init) GameConfig hazırken okunur.

const CONFIG_PATH := "res://assets/data/config/game_config.json"

## Şema + güvenli varsayılanlar. JSON bu ağacı geçersiz kılar; eksik anahtar → buradaki değer.
## Doğrulama bunu referans alır (JSON'daki fazladan/typo anahtar uyarılır).
const DEFAULTS := {
	"balance": {
		"engage_range": 1.3,
		"attack_range_tolerance": 1.2,
		"charge_reach_tolerance": 0.8,
		"nav_agent_max_climb": 0.8,
		"vertical_step_max": 0.8,
		"climb_free_max": 3.0,
		"diving_charge_min_height": 3.0,
		"nav_move_tolerance": 2.5,
		"aura_range": 8.0,
		"time_slip_radius": 6.0,
		"charge_distance_cap": 12.0,
	},
	"timing": {
		"dice_watchdog_seconds": 3.0,
		"dice_hold_seconds": 4.5,
	},
}

var _data: Dictionary = {}
var _loaded: bool = false

func _ready() -> void:
	_load()

## JSON'u yükle + doğrula. Belleğe alınmış _data'yı doldurur.
func _load() -> void:
	_data = _deep_copy(DEFAULTS)
	var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		_log_warn("GameConfig: '%s' bulunamadı — tüm değerler koddaki varsayılana düştü." % CONFIG_PATH)
		_loaded = true
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary):
		_log_warn("GameConfig: JSON çözümlenemedi — varsayılanlar kullanılıyor.")
		_loaded = true
		return

	var applied := 0
	var warned := 0
	for group in parsed.keys():
		if str(group).begins_with("_"):
			continue  # "_notes" gibi yorum anahtarları
		if not DEFAULTS.has(group):
			_log_warn("GameConfig: bilinmeyen grup '%s' yok sayıldı." % str(group)); warned += 1; continue
		var gval = parsed[group]
		if not (gval is Dictionary):
			_log_warn("GameConfig: '%s' grubu sözlük değil, yok sayıldı." % str(group)); warned += 1; continue
		for key in gval.keys():
			if not DEFAULTS[group].has(key):
				_log_warn("GameConfig: bilinmeyen anahtar '%s/%s' yok sayıldı (typo?)." % [str(group), str(key)]); warned += 1; continue
			var def = DEFAULTS[group][key]
			var v = gval[key]
			# Tip uyumu: sayısal alanlar float/int kabul eder.
			if (def is float or def is int) and (v is float or v is int):
				_data[group][key] = v
				applied += 1
			elif typeof(v) == typeof(def):
				_data[group][key] = v
				applied += 1
			else:
				_log_warn("GameConfig: '%s/%s' tipi yanlış (beklenen %s), varsayılan korundu." \
					% [str(group), str(key), type_string(typeof(def))]); warned += 1
	_loaded = true
	_log_info("GameConfig: %d ayar uygulandı, %d uyarı. Kaynak: %s" % [applied, warned, CONFIG_PATH])

func _ensure_loaded() -> void:
	if not _loaded:
		_load()

func _lookup(path: String, default):
	_ensure_loaded()
	var parts := path.split("/")
	var node = _data
	for p in parts:
		if node is Dictionary and node.has(p):
			node = node[p]
		else:
			return default
	return node

## "group/key" yolundan float değer (yoksa default).
func f(path: String, default: float) -> float:
	var v = _lookup(path, default)
	return float(v) if (v is float or v is int) else default

## "group/key" yolundan int değer (yoksa default).
func i(path: String, default: int) -> int:
	var v = _lookup(path, default)
	return int(v) if (v is float or v is int) else default

## "group/key" yolundan bool değer (yoksa default).
func b(path: String, default: bool) -> bool:
	var v = _lookup(path, default)
	return bool(v) if v is bool else default

func _deep_copy(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d.keys():
		out[k] = _deep_copy(d[k]) if d[k] is Dictionary else d[k]
	return out

## NOT: GameConfig, GameState'in ÜYE-INIT'i sırasında (henüz ağaçta değilken) lazily yüklenebilir.
## O anda mutlak-path get_node() "aktif sahne ağacı dışında" HATASI basar. is_inside_tree() koruması
## bu spam'i önler (ağaç dışıysa doğrudan print/push_warning'e düşülür — davranış aynı, hata yok).
func _log_info(msg: String) -> void:
	if is_inside_tree() and get_node_or_null("/root/GameLogger") != null:
		GameLogger.log_info(msg, "SYSTEM")
	else:
		print(msg)

func _log_warn(msg: String) -> void:
	if is_inside_tree() and get_node_or_null("/root/GameLogger") != null:
		GameLogger.log_warn(msg, "SYSTEM")
	else:
		push_warning(msg)
