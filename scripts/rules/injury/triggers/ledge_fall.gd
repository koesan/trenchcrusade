## KENARDAN DÜŞME — Down olan model bir kenarın 1" içindeyse düşebilir
##
## RAW (core-rules/injuries.md): "A model that is within 1" of a ledge when it is taken down may
## Fall off the ledge. Take a Success Roll for the model before it is taken Down. If the roll is a
## Success, the model is taken Down but does not Fall off the ledge. If the roll is a Failure, the
## model Falls from the nearest ledge and is then taken Down."
##
## "Kenar": modelin tabanından 1" içinde zeminin CLIMB_FREE_MAX'ten (3", sheer surface eşiği) fazla
## alçaldığı nokta — daha alçak basamaklar Open terrain sayılır, düşme üretmez. Yalnız YENİ Down
## olan modeller (Down üstüne Down değil) zar atar; FLYING/LEVITATE düşmez.
extends RefCounted

const DIRECTIONS := 12

static func matches(ctx: InjuryContext) -> bool:
	var t = ctx.target
	if t.unit_data != null and (KeywordSystem.has(t.unit_data, &"flying") or KeywordSystem.has(t.unit_data, &"levitate")):
		return false
	return ctx.final_outcome in [InjuryResolver.Outcome.DOWN, InjuryResolver.Outcome.NEGATED_TOUGH,
		InjuryResolver.Outcome.NEGATED_GOLEM] and t.has_method("resolve_falling_injury")

static func apply(ctx: InjuryContext) -> void:
	var t = ctx.target
	var landing = nearest_drop(t)
	if landing == null:
		return
	var roll: Array = await t.perform_unit_success_roll(0)
	if not is_instance_valid(t):
		return
	if roll[0] >= 7:
		GameLogger.log_info("[Kenar] %s kenarda sendeledi ama düşmedi (%d)." % [t.display_name, roll[0]], "COMBAT")
		return
	var height: float = t.global_position.y - landing.y
	GameLogger.log_warn("[Kenar] %s Yere Serilirken kenardan düştü (%d, %.1f\")!" % [t.display_name, roll[0], height], "COMBAT")
	t.global_position = landing
	RpcHelper.sync(t, "client_update_move", [landing])
	await t.resolve_falling_injury(height)

## Modelin tabanından 1" içindeki en yakın kenarın altındaki iniş noktası (yoksa null).
static func nearest_drop(t):
	var space = t.get_world_3d().direct_space_state
	var excludes: Array = []
	for u in UnitQuery.all():
		excludes.append(u.get_rid())
	var origin: Vector3 = t.global_position
	for reach in [TerrainContact.BASE_RADIUS + 0.5, TerrainContact.BASE_RADIUS + 1.0]:
		for i in range(DIRECTIONS):
			var a: float = TAU * float(i) / float(DIRECTIONS)
			var p: Vector3 = origin + Vector3(cos(a), 0, sin(a)) * reach
			var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.5, 0), p + Vector3(0, -60, 0))
			q.exclude = excludes
			var hit: Dictionary = space.intersect_ray(q)
			if hit.is_empty() or origin.y - hit.position.y <= GameState.CLIMB_FREE_MAX:
				continue
			# Yalnız yürünebilir zemine (NavMesh) düşülür — harita dışı/alt geometriye değil.
			var nav: Vector3 = NavigationServer3D.map_get_closest_point(t.get_world_3d().navigation_map, hit.position)
			if nav.distance_to(hit.position) <= 0.6:
				return MovementHelper.keep_base_clearance(t, t.get_world_3d().navigation_map, nav)
	return null
