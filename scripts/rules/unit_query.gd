## MERKEZÎ BİRİM SORGU API'Sİ — sahadaki birimleri filtrelemenin TEK doğru yolu.
##
## NEDEN VAR: Bu kod tabanında sahadaki birimler onlarca yerde `for u in GameState.units`
## döngüsüyle elle taranıyordu ve her çağrı yeri `is_instance_valid(u)`, `u.current_health > 0`,
## `u.owner_id != ...` üçlüsünü YENİDEN yazıyordu. Bir tanesini unutmak sessiz bir bug üretir
## (gerçek örnek: `FortifyActions._facing_enemy` ölü düşmanları da hesaba katıyordu → kazılan
## siper yanlış yöne bakıyordu). Filtre mantığı burada TEK yerde durur; bir daha unutulamaz.
##
## KULLANIM — zincirlenebilir, hepsi saf (yan etkisiz):
##   UnitQuery.enemies_of(unit)                      # hayatta düşmanlar
##   UnitQuery.within(UnitQuery.allies_of(u), pos, 3.0)
##   UnitQuery.nearest(UnitQuery.enemies_of(u), u.global_position)
##   UnitQuery.standing(UnitQuery.of_player(1))
##
## TEST EDİLEBİLİRLİK: Her giriş noktası opsiyonel bir `source` sözlüğü alır. Boş bırakılırsa
## `GameState.units` okunur; testler sahte birim sözlüğü geçirerek autoload'sız çalışabilir.
##
## PERFORMANS NOTU: Bu fonksiyonlar yeni Array ayırır. Tüm çağrı yerleri olay-güdümlüdür
## (tıklama/aksiyon/tur geçişi) — `_process`/`_physics_process` içinde KULLANMA; oralarda
## elle döngü hâlâ doğru tercihtir.
class_name UnitQuery

# ─────────────────────────────────────────────────────────────────────────────
#  GİRİŞ NOKTALARI (GameState.units'ten okur)
# ─────────────────────────────────────────────────────────────────────────────

## Geçerli (freed olmamış) TÜM birimler — ölüler dâhil.
## Ölüleri de kapsadığı için nadiren doğrudan istenir; genelde `alive()` istenir.
static func all(source: Dictionary = {}) -> Array:
	var out: Array = []
	for key in _source(source):
		var u = _source(source)[key]
		if is_instance_valid(u):
			out.append(u)
	return out

## Sahada AYAKTA KALAN (canı > 0) birimler. "Down" olanlar dâhildir — Down bir birim
## hâlâ sahadadır, yalnız Savaş Dışı (`current_health <= 0`) olanlar elenir.
static func alive(source: Dictionary = {}) -> Array:
	var out: Array = []
	var src: Dictionary = _source(source)
	for key in src:
		var u = src[key]
		if is_instance_valid(u) and u.current_health > 0:
			out.append(u)
	return out

## `unit`in hayatta DÜŞMANLARI (kendisi hariç).
static func enemies_of(unit, source: Dictionary = {}) -> Array:
	if unit == null:
		return []
	var out: Array = []
	for u in alive(source):
		if u != unit and u.owner_id != unit.owner_id:
			out.append(u)
	return out

## `unit`in hayatta DOSTLARI. Varsayılan olarak kendisi HARİÇTİR.
static func allies_of(unit, include_self: bool = false, source: Dictionary = {}) -> Array:
	if unit == null:
		return []
	var out: Array = []
	for u in alive(source):
		if u.owner_id != unit.owner_id:
			continue
		if u == unit and not include_self:
			continue
		out.append(u)
	return out

## Belirli bir oyuncunun hayatta birimleri.
static func of_player(player_id: int, source: Dictionary = {}) -> Array:
	var out: Array = []
	for u in alive(source):
		if u.owner_id == player_id:
			out.append(u)
	return out

## Belirli bir oyuncunun ROSTER'ı — Savaş Dışı kalmış birimler DÂHİL.
##
## `of_player()` ile karıştırma: roster kuralları (Elite tavanı, Legionnaire oranı, Order of
## the Fly, Wretched/Demonic oranı) "warband'e KAÇ MODEL ALINDI" sorusunu sorar; bir modelin
## sahada ölmüş olması onu warband'den çıkarmaz. Sahadaki güç için `of_player()` kullan.
static func roster_of(player_id: int, source: Dictionary = {}) -> Array:
	var out: Array = []
	for u in all(source):
		if u.owner_id == player_id:
			out.append(u)
	return out

# ─────────────────────────────────────────────────────────────────────────────
#  FİLTRELER (hazır bir Array'i daraltır — zincirlenebilir)
# ─────────────────────────────────────────────────────────────────────────────

## `center` etrafında `radius` inç içindekiler. Mesafe 3B'dir (yükseklik dâhil) —
## projenin geri kalanı da `global_position.distance_to` kullanır.
static func within(units: Array, center: Vector3, radius: float) -> Array:
	var out: Array = []
	for u in units:
		if is_instance_valid(u) and u.global_position.distance_to(center) <= radius:
			out.append(u)
	return out

## `within` ile aynı, ama sınır HARİÇ (kesin `<`). Hareket kuralları "düşmanın 1 inç
## YAKININA giremez" derken tam 1.0" mesafeyi GEÇERLİ sayar — angaje sayımı (`within`,
## `<=`) ile karıştırılmamalı. İki ayrı fonksiyon, çünkü fark kural düzeyinde anlamlı.
static func within_exclusive(units: Array, center: Vector3, radius: float) -> Array:
	var out: Array = []
	for u in units:
		if is_instance_valid(u) and u.global_position.distance_to(center) < radius:
			out.append(u)
	return out

## AYAKTA olanlar (Down olmayanlar).
static func standing(units: Array) -> Array:
	var out: Array = []
	for u in units:
		if is_instance_valid(u) and not u.is_down:
			out.append(u)
	return out

## `unit_data`sında verilen keyword'ü TAŞIYANLAR. `unit_data` null olan birimler elenir.
static func with_keyword(units: Array, kw: StringName) -> Array:
	var out: Array = []
	for u in units:
		if is_instance_valid(u) and u.unit_data != null and KeywordSystem.has(u.unit_data, kw):
			out.append(u)
	return out

## Verilen predikatı geçenler. `pred` tek bir birim alıp bool döndürmeli.
## Yukarıdaki hazır filtrelerin karşılamadığı tek-kullanımlık şartlar için.
static func where(units: Array, pred: Callable) -> Array:
	var out: Array = []
	for u in units:
		if is_instance_valid(u) and pred.call(u):
			out.append(u)
	return out

# ─────────────────────────────────────────────────────────────────────────────
#  İNDİRGEYİCİLER
# ─────────────────────────────────────────────────────────────────────────────

## `pos`a en yakın birim; liste boşsa `null`.
static func nearest(units: Array, pos: Vector3):
	var best = null
	var best_dist: float = INF
	for u in units:
		if not is_instance_valid(u):
			continue
		var d: float = u.global_position.distance_to(pos)
		if d < best_dist:
			best_dist = d
			best = u
	return best

## Listede en az bir birim var mı? (`not q.is_empty()` ile aynı — okunurluk için.)
static func any(units: Array) -> bool:
	return not units.is_empty()

# ─────────────────────────────────────────────────────────────────────────────
#  SIK KULLANILAN BİLEŞİK SORGULAR
# ─────────────────────────────────────────────────────────────────────────────

## `unit` ile ANGAJE (ENGAGE_RANGE içindeki) hayatta düşmanlar — projedeki en sık desen.
static func engaged_enemies(unit, source: Dictionary = {}) -> Array:
	if unit == null:
		return []
	return within(enemies_of(unit, source), unit.global_position, GameState.ENGAGE_RANGE)

## `unit`in `radius` inç içindeki hayatta düşmanları. Model-model mesafesi TABANDAN TABANA
## ölçülür: merkez mesafesine iki taban yarıçapı (GameState.ATTACK_RANGE_TOLERANCE) eklenir.
static func enemies_within(unit, radius: float, source: Dictionary = {}) -> Array:
	if unit == null:
		return []
	return within(enemies_of(unit, source), unit.global_position, radius + GameState.ATTACK_RANGE_TOLERANCE)

## `unit`in `radius` inç içindeki hayatta dostları (kendisi hariç), tabandan tabana.
static func allies_within(unit, radius: float, include_self: bool = false,
		source: Dictionary = {}) -> Array:
	if unit == null:
		return []
	return within(allies_of(unit, include_self, source), unit.global_position, radius + GameState.ATTACK_RANGE_TOLERANCE)

# ─────────────────────────────────────────────────────────────────────────────

static func _source(source: Dictionary) -> Dictionary:
	return source if not source.is_empty() else GameState.units

## GameState "enemy_unit" seçim modunda bu modele tıklanabilir mi? (Aday listesi boşsa seçimi
## isteyen modelin her canlı düşmanı.) Vurgu (UnitMovement) ve tıklama (MapInput) aynı kaynağı okur.
static func is_pick_candidate(u) -> bool:
	var picker = GameState.pick_unit
	if not is_instance_valid(u) or u.current_health <= 0 or not is_instance_valid(picker):
		return false
	if not GameState.pick_candidates.is_empty():
		return u in GameState.pick_candidates
	return u.owner_id != picker.owner_id
