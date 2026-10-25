## LEFT-HAND PATH — Goetic Spell (Hunter of the Left Hand Path, Court)
##
## Yetenek handler'ı — sözleşme: `apply(ctx: AbilityContext) -> bool`, isteğe bağlı
## `validate(ctx) -> String`. Kayıt: `abilities/ability_registry.gd`.
extends RefCounted

## Compendium: "[Goetic] (2): You can cast this spell when the spellcaster takes a Move, Charge,
## Retreat or Dash Action and moves into contact with a terrain piece. If you do so, you can
## interrupt the spellcaster's move to remove them from the battlefield and then redeploy them in
## contact with another terrain piece and more than 1" from any enemy models..."
##
## Dijital uyarlama (hareketin ORTASINI kesmek bu motorda mümkün değil): büyü, model bir arazi
## parçasıyla TEMAS HÂLİNDEYKEN "Büyü" eylemi olarak yapılır — hareketini araziye değerek bitiren
## model büyüyü yapar, sonra haritada yeni noktayı seçer. Hedef: başka bir arazi parçasıyla temas
## ve düşmanlardan 1"ten uzak. Bedel 2 Kan İşareti. Hücum sırasındaki "hedefe yaklaşmalı" alt
## kuralı bu uyarlamada yoktur (büyü hücumun parçası değil).

## Yeni nokta mevcut konumdan en az bu kadar uzak olmalı ("ANOTHER terrain piece").
const MIN_JUMP := 2.0

static func validate(ctx: AbilityContext) -> String:
	var caster = ctx.caster
	if not TerrainContact.in_contact(caster.get_world_3d(), caster.global_position):
		GameEvents.ability_rejected.emit("LEFT_HAND_PATH_FAIL_NO_CONTACT")
		return "Model bir arazi parçasıyla temasta değil."
	var reason := _target_problem(caster, ctx.target)
	if reason != "":
		GameEvents.ability_rejected.emit(reason)
		return reason
	return ""

static func apply(ctx: AbilityContext) -> bool:
	var caster = ctx.caster
	var dest: Vector3 = _snap(caster, ctx.target)
	var paid: int = await AbilityExecutor.pay_goetic_cost(caster, 2, 2, "LEFT_HAND_PATH")
	if paid <= 0:
		return false
	caster.global_position = dest
	RpcHelper.sync(caster, "client_update_move", [dest])
	RpcHelper.sync(caster, "play_ability_feedback", ["buff"])
	GameLogger.log_info("[Left-Hand Path] %s arazi parçaları arasında yol aldı." % caster.display_name, "GAME")
	return false

static func _snap(caster, target) -> Vector3:
	var rid: RID = caster.get_world_3d().navigation_map
	return NavigationServer3D.map_get_closest_point(rid, target)

## "" = hedef geçerli; değilse ret nedeninin lokalizasyon anahtarı.
static func _target_problem(caster, target) -> String:
	if not (target is Vector3):
		return "LEFT_HAND_PATH_FAIL_TARGET"
	var dest: Vector3 = _snap(caster, target)
	if dest.distance_to(caster.global_position) < MIN_JUMP:
		return "LEFT_HAND_PATH_FAIL_SAME_PIECE"
	if not TerrainContact.in_contact(caster.get_world_3d(), dest):
		return "LEFT_HAND_PATH_FAIL_TARGET"
	for e in UnitQuery.enemies_of(caster):
		if e.global_position.distance_to(dest) <= GameState.ENGAGE_RANGE:
			return "LEFT_HAND_PATH_FAIL_ENEMY"
	return ""
