extends Node

## Merkezî Ses Yöneticisi (Autoload) — VERİ-ODAKLI.
##
## İki alt sistem:
##  1) SFX EVENT REGISTRY: başlangıçta `assets/audio/sfx/**` taranır; dosyalar "altyol/temel-ad"
##     anahtarıyla gruplanır (ör. ui/click.ogg + ui/click_2.ogg → "ui/click" varyasyonları).
##     `play_sfx_event(&"ui/click")` rastgele varyasyon + pitch varyasyonu ile çalar.
##     YENİ SES = klasöre dosya at, KOD YOK.
##  2) MÜZİK PLAYLIST MOTORU: `music/menu` + `music/gameplay` taranır → iki playlist. Shuffle/loop/
##     next/prev/oto-geçiş/crossfade. `now_playing_changed(title)` sinyali.
##
## Bus'lar (default_bus_layout.tres): Master ← {Music, SFX, Ambient}. Ses seviyeleri Ayarlar'dan
## bus üzerinden ayarlanır (AudioManager volume bilmez — ayrım korunur).

signal now_playing_changed(title: String)
signal playlist_changed(playlist_name: String)

const SFX_ROOT := "res://assets/audio/sfx"
const MUSIC_ROOT := "res://assets/audio/music"
const AUDIO_EXTS := ["ogg", "wav", "mp3"]

@export var sfx_pool_size: int = 12

var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _move_player: AudioStreamPlayer  # döngülü birim hareket/sürükleme sesi
var _sfx_players: Array[AudioStreamPlayer] = []
var _current_sfx_index: int = 0
## Aktif crossfade tween'i (hud_toast.gd/hud_tooltip_popup.gd ile AYNI desen) — üst üste hızlı
## parça değişimi (ör. kullanıcı "İleri"ye art arda basarsa, ya da oto-geçiş + manuel tıklama aynı
## ana denk gelirse) İKİ tween'in AYNI ANDA volume_db'yi değiştirmesini (zipper/çatallanma sesi)
## önler — yeni bir crossfade başlarken ÖNCEKİ öldürülür.
var _crossfade_tween: Tween = null

## event anahtarı ("altyol/temel-ad") → Array[AudioStream] (varyasyonlar)
var _sfx_events: Dictionary = {}
## playlist adı ("menu"/"gameplay") → Array[{ "title": String, "stream": AudioStream }]
var _playlists: Dictionary = {}

# ── Müzik oynatma durumu ──────────────────────────────────────────────────────
var _active_playlist: String = ""
var _play_order: Array[int] = []   # _playlists[_active_playlist] içine indeksler (shuffle'da karışık)
var _order_cursor: int = -1
var shuffle: bool = false
var loop: bool = true

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS

	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = &"Music"
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)

	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "AmbientPlayer"
	_ambient_player.bus = &"Ambient"
	add_child(_ambient_player)

	_move_player = AudioStreamPlayer.new()
	_move_player.name = "MovePlayer"
	_move_player.bus = &"SFX"
	add_child(_move_player)

	for i in range(sfx_pool_size):
		var p := AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = &"SFX"
		add_child(p)
		_sfx_players.append(p)

	_scan_sfx()
	_scan_music()

	var track_total := 0
	for k in _playlists:
		track_total += _playlists[k].size()
	GameLogger.log_info("AudioManager: %d SFX event, %d müzik parçası (%d SFX oynatıcı)." \
		% [_sfx_events.size(), track_total, sfx_pool_size], "AUDIO")

# ══════════════════════════════════════════════════════════════════════════════
# SFX
# ══════════════════════════════════════════════════════════════════════════════

## Anahtarla ses efekti çalar (registry'den rastgele varyasyon). Anahtar yoksa sessizce no-op.
func play_sfx_event(key: StringName, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	var variations = _sfx_events.get(String(key))
	if variations == null or variations.is_empty():
		return
	play_sfx(variations[randi() % variations.size()], pitch_scale, volume_db)

## Doğrudan bir AudioStream'i havuzdan çalar (round-robin + doğal pitch varyasyonu).
func play_sfx(stream: AudioStream, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	var p := _sfx_players[_current_sfx_index]
	p.stop()
	p.stream = stream
	p.pitch_scale = pitch_scale + randf_range(-0.05, 0.05)
	p.volume_db = volume_db
	p.play()
	_current_sfx_index = (_current_sfx_index + 1) % sfx_pool_size

func has_sfx_event(key: StringName) -> bool:
	return _sfx_events.has(String(key))

# ══════════════════════════════════════════════════════════════════════════════
# MÜZİK PLAYLIST
# ══════════════════════════════════════════════════════════════════════════════

## Bir playlist'i (menu/gameplay) çalmaya başlar. Aynı playlist zaten çalıyorsa dokunmaz.
func play_playlist(name: String, fade_time: float = 1.0) -> void:
	if _active_playlist == name and _music_player.playing:
		return
	var tracks = _playlists.get(name)
	if tracks == null or tracks.is_empty():
		_active_playlist = name
		return  # parça yok → sessiz (drop-in: klasöre dosya atınca çalışır)
	_active_playlist = name
	playlist_changed.emit(name)
	_rebuild_play_order()
	_order_cursor = 0
	_play_current(fade_time)

## Sıradaki parçaya geçer (playlist sonunda loop açıksa başa döner).
func next_track(fade_time: float = 0.6) -> void:
	if _play_order.is_empty():
		return
	var nxt := next_cursor(_order_cursor, _play_order.size(), loop)
	if nxt == -1:
		return
	_order_cursor = nxt
	if shuffle and _order_cursor == 0:
		_rebuild_play_order()  # her tam turda yeniden karıştır
	_play_current(fade_time)

## Önceki parçaya geçer.
func prev_track(fade_time: float = 0.6) -> void:
	if _play_order.is_empty():
		return
	_order_cursor = prev_cursor(_order_cursor, _play_order.size(), loop)
	_play_current(fade_time)

func set_shuffle(value: bool) -> void:
	if shuffle == value:
		return
	shuffle = value
	if _active_playlist != "":
		var current_track := _current_track_index()
		_rebuild_play_order()
		# çalan parçayı order'da bul, kesintisiz devam
		_order_cursor = max(0, _play_order.find(current_track))

func set_loop(value: bool) -> void:
	loop = value

func stop_music(fade_time: float = 1.0) -> void:
	_active_playlist = ""
	_play_order.clear()
	_order_cursor = -1
	if _crossfade_tween != null and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
	if not _music_player.playing:
		return
	if fade_time <= 0.0:
		_music_player.stop()
		return
	_crossfade_tween = create_tween()
	_crossfade_tween.tween_property(_music_player, "volume_db", -80.0, fade_time)
	_crossfade_tween.tween_callback(_music_player.stop)

func get_now_playing() -> String:
	var idx := _current_track_index()
	if idx < 0:
		return ""
	return _playlists[_active_playlist][idx]["title"]

func _current_track_index() -> int:
	if _order_cursor < 0 or _order_cursor >= _play_order.size():
		return -1
	return _play_order[_order_cursor]

func _rebuild_play_order() -> void:
	var n: int = _playlists.get(_active_playlist, []).size()
	_play_order.clear()
	for i in range(n):
		_play_order.append(i)
	if shuffle:
		_play_order.shuffle()

func _play_current(fade_time: float) -> void:
	var idx := _current_track_index()
	if idx < 0:
		return
	var entry = _playlists[_active_playlist][idx]
	_crossfade_to(entry["stream"], fade_time)
	now_playing_changed.emit(entry["title"])

func _on_music_finished() -> void:
	# Oto-geçiş: parça bitince sıradakine. Tek parça + loop ise aynı parça tekrar.
	next_track(0.0)

## Yumuşak geçişle yeni müzik akışına geç (eski davranış korunur).
func _crossfade_to(stream: AudioStream, fade_time: float) -> void:
	if _music_player.stream == stream and _music_player.playing:
		return
	# Önceki crossfade hâlâ sürüyorsa öldür — aksi halde iki tween aynı anda volume_db'yi
	# değiştirmeye çalışır (hızlı ardışık parça değişiminde duyulabilir zipper/çatallanma).
	if _crossfade_tween != null and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
	if fade_time <= 0.0:
		_music_player.stream = stream
		_music_player.volume_db = 0.0
		_music_player.play()
		return
	_crossfade_tween = create_tween()
	if _music_player.playing:
		_crossfade_tween.tween_property(_music_player, "volume_db", -80.0, fade_time * 0.5)
	_crossfade_tween.tween_callback(func():
		_music_player.stream = stream
		_music_player.volume_db = -80.0
		_music_player.play()
	)
	_crossfade_tween.tween_property(_music_player, "volume_db", 0.0, fade_time * 0.5)


# ══════════════════════════════════════════════════════════════════════════════
# AMBIENT
# ══════════════════════════════════════════════════════════════════════════════

## Döngülü ambient yatak sesi çalar (Ambient bus). null/boş → durdurur.
func play_ambient(key: StringName) -> void:
	var variations = _sfx_events.get(String(key))
	if variations == null or variations.is_empty():
		_ambient_player.stop()
		return
	_ambient_player.stream = variations[0]
	# Ambient yatak sesi sürekli döngüde olmalı (SFX registry loop=false ile yükler).
	if "loop" in _ambient_player.stream:
		_ambient_player.stream.loop = true
	_ambient_player.play()

func stop_ambient() -> void:
	_ambient_player.stop()

# ══════════════════════════════════════════════════════════════════════════════
# HAREKET / SÜRÜKLENME DÖNGÜSÜ (birim yol boyunca hareket ederken)
# ══════════════════════════════════════════════════════════════════════════════

## Birim hareket/sürükleme döngü sesini başlatır. Idempotent: zaten çalıyorsa dokunmaz
## (her frame güvenle çağrılabilir). İlgili .ogg yoksa sessiz no-op.
func start_move_loop(key: StringName = &"units/move_slide") -> void:
	if _move_player.playing:
		return
	var variations = _sfx_events.get(String(key))
	if variations == null or variations.is_empty():
		return
	var stream = variations[randi() % variations.size()]
	if "loop" in stream:
		stream.loop = true  # hareket sesi süreklidir (registry loop=false yükler)
	_move_player.stream = stream
	_move_player.play()

func stop_move_loop() -> void:
	if _move_player.playing:
		_move_player.stop()

# ══════════════════════════════════════════════════════════════════════════════
# TARAMA (klasör → registry)  +  SAF YARDIMCILAR (test edilebilir)
# ══════════════════════════════════════════════════════════════════════════════

func _scan_sfx() -> void:
	_sfx_events.clear()
	_scan_sfx_dir(SFX_ROOT, "")

func _scan_sfx_dir(dir_path: String, prefix: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	# alt klasörler (units/weapons/... ve daha derin)
	for sub in dir.get_directories():
		var sub_prefix := sub if prefix == "" else prefix + "/" + sub
		_scan_sfx_dir(dir_path + "/" + sub, sub_prefix)
	# ses dosyaları
	for res_path in _audio_files_in(dir_path, dir):
		var base := strip_variation(_basename_no_ext(res_path))
		var key := base if prefix == "" else prefix + "/" + base
		var stream = load(res_path)
		if stream == null:
			continue
		# SFX tek-sefer olmalı; import loop=true gelirse döngüde takılmasın (deterministik).
		if "loop" in stream:
			stream.loop = false
		if not _sfx_events.has(key):
			_sfx_events[key] = []
		_sfx_events[key].append(stream)

func _scan_music() -> void:
	_playlists.clear()
	for sub in ["menu", "gameplay"]:
		var list: Array = []
		var path: String = MUSIC_ROOT + "/" + String(sub)
		var dir := DirAccess.open(path)
		if dir != null:
			var files := _audio_files_in(path, dir)
			files.sort()  # belirleyici sıra (shuffle kapalıyken)
			for res_path in files:
				var stream = load(res_path)
				if stream == null:
					continue
				# Playlist oto-geçişi `finished` sinyaline dayanır → parça loop'suz olmalı.
				# (Playlist döngüsü `loop` değişkeni + next_cursor mantığıyla yönetilir.)
				if "loop" in stream:
					stream.loop = false
				list.append({ "title": _pretty_title(_basename_no_ext(res_path)), "stream": stream })
		_playlists[sub] = list

## Bir klasördeki ses kaynaklarının res:// yollarını döndürür (export'ta .import remap'ini de kapsar).
func _audio_files_in(dir_path: String, dir: DirAccess) -> Array:
	var out: Array = []
	var seen := {}
	for f in dir.get_files():
		var res_path := ""
		if _has_audio_ext(f):
			res_path = dir_path + "/" + f
		elif f.ends_with(".import"):
			var orig := f.substr(0, f.length() - ".import".length())
			if _has_audio_ext(orig):
				res_path = dir_path + "/" + orig
		if res_path != "" and not seen.has(res_path):
			seen[res_path] = true
			out.append(res_path)
	return out

func _has_audio_ext(fname: String) -> bool:
	return fname.get_extension().to_lower() in AUDIO_EXTS

func _basename_no_ext(res_path: String) -> String:
	return res_path.get_file().get_basename()

## "gothic_dirge_01" → "Gothic Dirge 01" (UI'da gösterim için).
func _pretty_title(stem: String) -> String:
	return stem.replace("_", " ").replace("-", " ").capitalize()

# ── Saf, test edilebilir yardımcılar ──────────────────────────────────────────

## Dosya temel adından varyasyon ekini soyar: "click_2"→"click", "click_alt"→"click",
## "melee_hit"→"melee_hit" (anlamlı isim korunur; yalnız `_<rakam>` ve `_alt` ekleri düşer).
static func strip_variation(base: String) -> String:
	var parts := base.split("_")
	if parts.size() <= 1:
		return base
	var last: String = parts[parts.size() - 1]
	if last == "alt" or last.is_valid_int():
		parts.remove_at(parts.size() - 1)
		return "_".join(parts)
	return base

## Sıradaki cursor: son elemanda loop açıksa 0'a döner, kapalıysa -1 (dur).
static func next_cursor(cursor: int, count: int, loop_on: bool) -> int:
	if count <= 0:
		return -1
	if cursor + 1 < count:
		return cursor + 1
	return 0 if loop_on else -1

## Önceki cursor: baştaysa loop açıksa sona sarar, kapalıysa 0'da kalır.
static func prev_cursor(cursor: int, count: int, loop_on: bool) -> int:
	if count <= 0:
		return -1
	if cursor - 1 >= 0:
		return cursor - 1
	return count - 1 if loop_on else 0
