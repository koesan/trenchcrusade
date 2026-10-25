## MovementHelper
## Yol mesafe hesaplamalarını ve hareket kısıtlamalarını yöneten yardımcı sınıf (stateless).
class_name MovementHelper

## Retreat bitiş konumunu TÜM düşmanlardan > ENGAGE_RANGE olacak şekilde ayarlar (best-effort).
## Compendium: retreat, tüm düşmanlardan 1"+ uzakta bitmeli; hâlâ angaje ise en yakın düşmandan
## uzağa itip NavMesh'e clamp'ler (en çok 4 iterasyon). (P2-7: unit.gd'den çıkarıldı.)
static func enforce_retreat_clearance(unit, map_rid, target: Vector3, max_dist: float) -> Vector3:
	var adjusted: Vector3 = target
	for _i in range(4):
		# Hâlâ angaje olunan (denenen konumun ENGAGE_RANGE'i içindeki) en yakın düşman.
		# Mesafe `unit`in mevcut yerine göre DEĞİL, denenen `adjusted` konumuna göre ölçülür.
		var nearest = UnitQuery.nearest(
			UnitQuery.within(UnitQuery.enemies_of(unit), adjusted, GameState.ENGAGE_RANGE),
			adjusted)
		if nearest == null:
			break
		var dir: Vector3 = adjusted - nearest.global_position
		if dir.length() < 0.01:
			dir = unit.global_position - nearest.global_position
		dir = dir.normalized()
		var pushed: Vector3 = nearest.global_position + dir * (GameState.ENGAGE_RANGE + 0.3)
		adjusted = get_clamped_target(map_rid, unit.global_position, pushed, max_dist)
	return adjusted

## Model tabanları (yarıçap ≈0.6) iç içe giremez: varış noktası başka bir canlı modelin tabanına
## giriyorsa (merkezler arası < BASE_CONTACT) o modelden dışa, taban temasına itilip NavMesh'e
## oturtulur. Farklı kattaki (dikey fark > 1.5) modeller çakışma sayılmaz.
const BASE_CONTACT: float = 1.2
static func keep_base_clearance(mover, map_rid: RID, target: Vector3) -> Vector3:
	var adjusted: Vector3 = target
	for _i in range(4):
		var blocker = null
		for u in UnitQuery.alive():
			if u != mover and absf(u.global_position.y - adjusted.y) <= 1.5 \
					and _flat(u.global_position - adjusted).length() < BASE_CONTACT - 0.01:
				blocker = u
				break
		if blocker == null:
			break
		var away: Vector3 = _flat(adjusted - blocker.global_position)
		if away.length() < 0.01:
			away = _flat(mover.global_position - blocker.global_position)
		if away.length() < 0.01:
			away = Vector3.RIGHT
		var pushed: Vector3 = blocker.global_position + away.normalized() * (BASE_CONTACT + 0.02)
		pushed.y = adjusted.y
		adjusted = NavigationServer3D.map_get_closest_point(map_rid, pushed) if map_rid.is_valid() else pushed
	return adjusted

static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)

## Belirtilen yolun (path) toplam uzunluğunu hesaplar.
static func get_path_length(path: PackedVector3Array) -> float:
	var total_dist := 0.0
	if path.size() < 2:
		return total_dist
	for i in range(path.size() - 1):
		total_dist += path[i].distance_to(path[i + 1])
	return total_dist

## Hareket hedefini NavMesh'e HİZALAR (STATELESS).
## `snapped`: NavigationServer3D.map_get_closest_point ile bulunan en yakın navigasyon noktası.
## `raw`: oyuncunun ham raycast tıklama noktası (bir duvar YÜZÜNE, siper tabanına ya da boşluğa
## denk gelebilir).
## Hedef HER ZAMAN `snapped`'e hizalanır: birim asla duvarın ortasına konmaz — en yakın geçerli
## zemine gider (üst kenar ya da siper tabanı; hangisi yakınsa). Ham tıklama YATAYDA çok uzaksa
## (gerçekten harita dışı / boşluk) hareket reddedilir. Böylece hem "duvar ortası", hem "sipere
## inemiyor", hem eski "haritadan düşme" tek noktada çözülür.
## Dönüş: { "valid": bool, "target": Vector3 } — geçerliyse target = navigasyona hizalı snapped.
static func resolve_nav_target(snapped: Vector3, raw: Vector3, tolerance: float) -> Dictionary:
	var horiz: float = Vector2(raw.x - snapped.x, raw.z - snapped.z).length()
	if horiz > tolerance:
		return {"valid": false, "target": snapped}
	return {"valid": true, "target": snapped}

## Hedef konumu, maksimum hareket mesafesine (max_dist) göre sınırlandırıp doğrular.
static func get_clamped_target(map_rid: RID, start_pos: Vector3, click_pos: Vector3, max_dist: float) -> Vector3:
	var click_dir = (click_pos - start_pos).normalized()
	var target_test_pos = start_pos + click_dir * max_dist
	var path = NavigationServer3D.map_get_path(map_rid, start_pos, target_test_pos, true)
	
	if path.size() < 2:
		return start_pos
		
	var verified_target = start_pos
	var accumulated_dist = 0.0
	for i in range(path.size() - 1):
		var seg = path[i].distance_to(path[i+1])
		if accumulated_dist + seg > max_dist:
			var rem = max_dist - accumulated_dist
			verified_target = path[i] + (path[i+1] - path[i]).normalized() * rem
			break
		else:
			accumulated_dist += seg
			verified_target = path[i+1]
			
	var direct_path = NavigationServer3D.map_get_path(map_rid, start_pos, click_pos, true)
	if direct_path.size() >= 2:
		var direct_dist = get_path_length(direct_path)
		if direct_dist <= max_dist + 0.3:
			verified_target = click_pos
			
	return verified_target
