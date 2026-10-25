## MedicActions — Medi-Kit "Treat" aksiyonunun yürütücüsü.
##
## KURAL KAYNAĞI (battlekit/equipment.md + new-antioch.md Combat Medic):
##   "Treat [Action]: take a [Risky Success] Roll for the model. If the roll is a Failure, the
##    model's Activation ENDS IMMEDIATELY. If it is a Success or a Critical Success, you can do
##    ONE OF THE FOLLOWING things:
##      - Remove [1 Blood Marker] from the model or a friendly model within 1" of the model.
##      - Stand up a friendly model that is Down and within 1" of the model."
##
## Önceki uygulama yalnız "stand_up" yapıyordu ve Risky DEĞİLdi (denetim bulgusu P1-NA-7);
## Combat Medic'in idame rolünün yarısı (Blood Marker temizleme) hiç yoktu.
##
## `ability_executor.gd` buraya YALNIZ delege eder (o dosya 1150+ satır — şişmemeli).
class_name MedicActions

## Başarılı bir Treat sonrası oyuncuya iki etkiden birini seçtirir ve uygular.
## Döndürür: end_activation (daima false — başarısızlık akışı execute() içinde yönetilir).
static func handle_treat(caster, target, roll_total: int) -> bool:
	if not is_instance_valid(target) or target.current_health <= 0:
		return false

	# GLUTTONY AURASI (Court, Desecrated Saint): 3" içindeki düşmanlar iyileştirilemez.
	if MechanicsResolver.is_in_demonic_aura(target, &"gluttony_aura"):
		GameLogger.log_warn("[Treat] %s Oburluk Aurasında — iyileştirilemez." % target.display_name, "GAME")
		GameEvents.ability_rejected.emit("TREAT_FAIL_GLUTTONY")
		return false

	var can_stand: bool = target.is_down
	var can_remove: bool = target.blood_markers > 0

	# Tek seçenek anlamlıysa sormaya gerek yok (gereksiz tıklama yaratma).
	var remove_blood: bool
	if can_remove and not can_stand:
		remove_blood = true
	elif can_stand and not can_remove:
		remove_blood = false
	elif not can_stand and not can_remove:
		GameLogger.log_info("[Treat] %s: uygulanacak bir etki yok (yara/Down yok)." \
			% target.display_name, "GAME")
		return false
	else:
		remove_blood = await CombatChoice.request_treat_choice(caster, target.display_name)

	if remove_blood:
		target.blood_markers = maxi(0, target.blood_markers - 1)
		GameLogger.log_info("[Treat] %s tedavi etti (%d): %s -1 Kan İşareti → %d." \
			% [caster.display_name, roll_total, target.display_name, target.blood_markers], "GAME")
	else:
		target.is_down = false
		GameLogger.log_info("[Treat] %s tedavi etti (%d): %s ayağa kalktı." \
			% [caster.display_name, roll_total, target.display_name], "GAME")

	CombatResolver.sync_target_health(target)
	RpcHelper.sync(target, "play_ability_feedback", ["heal"])
	return false
