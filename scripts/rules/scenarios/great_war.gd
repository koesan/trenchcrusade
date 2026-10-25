## "Great War" senaryo mantığı (compendium: scenarios/great-war).
##
## 5 tur. Objective YOK. VP = OOA edilen düşman modellerinin Cost'u/10 (yukarı yuvarla). Glorious
## Deeds YOK ("just victory or death!"). "To The Death!" — Moral Kontrolü hiç yapılmaz
## (ScenarioData.special_rules["skip_morale"] = true, turn_manager.gd okur).
class_name GreatWarLogic
extends ScenarioLogic

## Bir model Out of Action olduğunda çağrılır — VP'yi doğrudan player_vp'ye ekler (objective yok,
## taban sınıfın on_turn_end'i objectives=[] olduğu için zaten no-op).
func on_unit_out_of_action(attacker, target, _is_melee: bool, ctx: Dictionary = {}) -> void:
	# KASITLI: super.on_unit_out_of_action() (Gather Knowledge, taban sınıf) BİLEREK çağrılmıyor.
	# Battlefield Vivisection "add Gather Knowledge to those normally available in each scenario
	# you play" der, ama Great War'ın kendi metni AÇIK ve KOŞULSUZ: "There are no Glorious Deeds
	# in this scenario, just victory or death!" — bu senaryoda "normalde mevcut olanlar" kümesi
	# zaten boş, dolayısıyla eklenecek bir şey yok. QA denetiminde bu satırın yanlışlıkla eklendiği
	# (Gather Knowledge sayacının VP'ye hiç yansımasa da state biriktirdiği) tespit edildi, geri alındı.
	if not ctx.get("is_ooa", false) or attacker == null or not is_instance_valid(attacker):
		return
	if target == null or target.unit_data == null:
		return
	var vp: int = MechanicsResolver.great_war_vp_for_cost(target.unit_data.cost)
	if vp > 0:
		player_vp[attacker.owner_id] = player_vp.get(attacker.owner_id, 0) + vp
		GameLogger.log_info("[Great War] Oyuncu %d: +%d VP (%s OOA, Cost %d)." \
			% [attacker.owner_id, vp, target.unit_data.unit_name, target.unit_data.cost], "SCENARIO")
