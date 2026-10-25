## DeployRules — Yerleştirme (deployment) özel kuralları (STATELESS, saf).
##
## Standart yerleşim `ScenarioData.p1/p2_deploy_zone` dikdörtgenleriyle sınırlıdır. Bazı
## birimler compendium'da bu sınırın DIŞINA çıkabilir; o istisnalar burada tanımlanır.
##
## Sayımı/ölçümü çağıran taraf (game.gd) yapar, kararı bu modül verir.
class_name DeployRules

# ── FORWARD POSITIONS (Sultanate Sapper) ─────────────────────────────────────
## Compendium (iron-sultanate.md):
##   "When you deploy a Sultanate Sapper for the first time in a game, you can deploy them
##    UP TO 6" AWAY from your deployment zone and IN CONTACT WITH a terrain piece that is
##    at least ½" high."
const FORWARD_POSITION_RANGE := 6.0

## Bu birim ileri konuşlanabilir mi?
## dist_beyond_zone: yerleşim bölgesinin kenarından ölçülen mesafe (inç)
## in_terrain_contact: en az ½" yükseklikte bir arazi parçasıyla temas var mı?
static func forward_position_allowed(unit_data: Resource, dist_beyond_zone: float,
		in_terrain_contact: bool) -> bool:
	if unit_data == null:
		return false
	if not KeywordSystem.has(unit_data, &"forward_positions"):
		return false
	if not in_terrain_contact:
		return false
	return dist_beyond_zone <= FORWARD_POSITION_RANGE

## Bu birim Forward Positions yeteneğine sahip mi? (deploy akışının ön filtresi)
static func has_forward_positions(unit_data: Resource) -> bool:
	return unit_data != null and KeywordSystem.has(unit_data, &"forward_positions")
