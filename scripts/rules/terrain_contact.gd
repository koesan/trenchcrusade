class_name TerrainContact
extends RefCounted

## "Bir arazi parçasıyla TEMAS" — haritanın sabit geometrisine (duvar, kaya, siper kenarı, rampa)
## değme kontrolü. Compendium'daki "in contact with a terrain piece" kuralları için ortak ölçü
## (Left-Hand Path; ileride Forward Positions / Set Mine da kullanabilir).
##
## Yöntem — tabanın çevresinde 12 yönde, iki ölçü (biri yeterli):
##   1. DUVAR: tabandan yarım inç yukarıda kısa yatay ışın sabit geometriye (StaticBody3D) çarpar.
##   2. KENAR: tabanın hemen dışında zemin yüksekliği yarım inçten fazla değişir (siper kenarı,
##      yükselti, plato sınırı). Bu haritada çarpışması olan tek gövde zeminin kendisi; siperler ve
##      platolar ancak yükseklik farkıyla ayırt edilir — yalnız 1. ölçü hiçbir noktada temas
##      bulamıyordu (ölçüldü: 122 örnek noktada 0).
## Diğer modeller (CharacterBody3D) arazi sayılmaz. Savaş alanı dışı (zemin yok) temas sayılmaz.

const RAY_COUNT := 12
## Taban yarıçapı (unit.tscn çarpışma silindiri) + temas payı (inç). Pay 1": navigasyon ağı modelleri
## duvarlardan 0.6 uzakta tutar, duvara "değen" model ölçüde sınırda kalıyordu (ENGAGE_RANGE ile aynı gerekçe).
const BASE_RADIUS := 0.6
const CONTACT_REACH := 1.0
## Işın yüksekliği: zemindeki küçük pürüzler "arazi" sayılmasın.
const RAY_HEIGHT := 0.5

static func in_contact(world: World3D, pos: Vector3) -> bool:
	if world == null:
		return false
	var space := world.direct_space_state
	var from := pos + Vector3(0, RAY_HEIGHT, 0)
	for i in RAY_COUNT:
		var a := TAU * float(i) / float(RAY_COUNT)
		var to := from + Vector3(cos(a), 0, sin(a)) * (BASE_RADIUS + CONTACT_REACH)
		var q := PhysicsRayQueryParameters3D.create(from, to)
		var hit := space.intersect_ray(q)
		if not hit.is_empty() and hit.collider is StaticBody3D:
			return true
		# Kenar: tabanın dışındaki zemin yüksekliği
		var probe := Vector3(to.x, pos.y + 4.0, to.z)
		var down := space.intersect_ray(PhysicsRayQueryParameters3D.create(probe, probe - Vector3(0, 12.0, 0)))
		if not down.is_empty() and down.collider is StaticBody3D \
				and absf(down.position.y - pos.y) >= RAY_HEIGHT:
			return true
	return false
