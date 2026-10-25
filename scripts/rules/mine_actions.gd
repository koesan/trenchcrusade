## MineActions — Set Mine / Defuse Mine / Detonating Mines aksiyonlarının YÜRÜTÜCÜSÜ.
##
## Kural KARARLARI `MineResolver`'da (saf/testli), sahadaki KAYIT `TerrainManager`'da.
## Bu modül yalnız ikisini birbirine bağlar ve zar/efekt akışını sürer.
##
## `ability_executor.gd` bu handler'lara YALNIZ delege eder (o dosya 1150+ satır — şişmemeli).
class_name MineActions

## Mayın patlaması için kullanılan saldırı verisi ([Shrapnel] Injury Roll).
const ATK_MINE_DETONATION := preload("res://assets/data/attacks/mine_detonation.tres")
## Sahaya konulacak mayın tanımı.
const MINE_FEATURE := preload("res://assets/data/terrain/mine.tres")

# ── SET MINE ─────────────────────────────────────────────────────────────────
## Compendium: "take a Success Roll for the model and add [+2 Dice] to the roll. If the roll is
## a Failure, NOTHING HAPPENS. If Success or Critical Success, the terrain piece gains [Mined]."
## Risky DEĞİLdir → başarısızlıkta aktivasyon bitmez.
## Döndürür: end_activation (daima false).
static func handle_set_mine(caster) -> bool:
	if caster == null or caster.unit_data == null:
		return false
	var pos: Vector3 = caster.global_position
	if not MineResolver.can_set_mine(caster.unit_data,
			TerrainManager.has_keyword_at(pos, &"mined")):
		GameLogger.log_warn("[Set Mine] %s: burada zaten bir mayın var." % caster.display_name, "GAME")
		GameEvents.ability_rejected.emit("MINE_FAIL_ALREADY_MINED")
		return false

	var res: Array = await caster.perform_unit_success_roll(MineResolver.set_mine_bonus_dice())
	var total: int = res[0]
	if total < MineResolver.set_mine_threshold():
		GameLogger.log_info("[Set Mine] %s başarısız (%d). Hiçbir şey olmaz." \
			% [caster.display_name, total], "GAME")
		# Sarsılmış ordu / Maddening Buzzing altında bu da Risky bir Success Roll'dur.
		return RiskyRolls.apply_failure(caster, total, false, "Set Mine")

	TerrainManager.spawn_feature(MINE_FEATURE, pos, String(caster.name),
		FortifyActions._facing_enemy(caster))
	GameLogger.log_info("[Set Mine] %s mayın kurdu (%d)." % [caster.display_name, total], "GAME")
	RpcHelper.sync(caster, "play_ability_feedback", ["buff"])
	return false

# ── DEFUSE MINE ──────────────────────────────────────────────────────────────
## Compendium: "take a [Risky Success] Roll. If Failure the mine DETONATES and the model's
## Activation ends. If Success or Critical Success, the mine does not detonate and the terrain
## piece loses [Mined]. A model that SETS a mine can defuse it AUTOMATICALLY (do not take a Roll)."
## Döndürür: end_activation.
static func handle_defuse_mine(caster) -> bool:
	if caster == null or caster.unit_data == null:
		return false
	var pos: Vector3 = caster.global_position
	if not TerrainManager.has_keyword_at(pos, &"mined"):
		GameLogger.log_warn("[Defuse Mine] %s: burada mayın yok." % caster.display_name, "GAME")
		GameEvents.ability_rejected.emit("MINE_FAIL_NO_MINE")
		return false

	# Kendi kurduğu mayın → zar YOK, otomatik etkisizleştirme.
	if MineResolver.defuse_is_automatic(TerrainManager.setter_of(pos), String(caster.name)):
		TerrainManager.defuse_at(pos)
		GameLogger.log_info("[Defuse Mine] %s kendi mayınını otomatik etkisizleştirdi (zar yok)." \
			% caster.display_name, "GAME")
		return false

	var res: Array = await caster.perform_unit_success_roll(0)
	var total: int = res[0]
	if total < 7:
		GameLogger.log_warn("[Defuse Mine] %s başarısız (%d) — mayın patlıyor!" \
			% [caster.display_name, total], "GAME")
		await _detonate(caster, pos)
		return true  # Risky: aktivasyon biter
	TerrainManager.defuse_at(pos)
	GameLogger.log_info("[Defuse Mine] %s mayını etkisizleştirdi (%d)." % [caster.display_name, total], "GAME")
	RpcHelper.sync(caster, "play_ability_feedback", ["buff"])
	return false

# ── DETONATING MINES ─────────────────────────────────────────────────────────
## Compendium: "When a model moves into contact with a Mined terrain piece, the mine will
## detonate UNLESS the model is the one that set the mine, or has the Defuse Mine ability.
## Make an Injury Roll with the [Shrapnel] Keyword... The terrain piece is then no longer Mined."
##
## Hareket TAMAMLANDIĞINDA çağrılır (unit_movement.gd). FLYING modeller yalnız hareketi
## mayının üzerinde bitirirse tetikler — bu çağrı zaten hareket sonunda yapıldığı için
## `is_move_end = true` geçilir.
static func check_step_on_mine(unit) -> void:
	if unit == null or unit.unit_data == null or unit.current_health <= 0:
		return
	var pos: Vector3 = unit.global_position
	if not TerrainManager.has_keyword_at(pos, &"mined"):
		return
	if not MineResolver.flying_triggers(unit.unit_data, true):
		return
	if not MineResolver.detonates_for(unit.unit_data, TerrainManager.setter_of(pos), String(unit.name)):
		GameLogger.log_info("[Mayın] %s mayını tetiklemedi (kuran kendisi veya [Negate Mined])." \
			% unit.display_name, "COMBAT")
		return
	await _detonate(unit, pos)

## Patlamayı çözer: [Shrapnel] Injury Roll + parçayı sahadan kaldır.
static func _detonate(victim, pos: Vector3) -> void:
	GameLogger.log_warn("[Mayın] %s mayına bastı — patlıyor!" % victim.display_name, "COMBAT")
	TerrainManager.consume_at(pos)
	await victim.resolve_injury_roll(victim, false, false, 0, 0, ATK_MINE_DETONATION)
