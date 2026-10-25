class_name BattleEvents
extends RefCounted

## Savaş olaylarının TEK yayın noktası. Kural kodu sonucu belirlediği yerde `post` çağırır;
## olay ağ oyununda yalnız sunucudan çıkar ve herkese iletilir (çift kayıt olmaz).

const OUTCOME_KEYS := {
	InjuryResolver.Outcome.NO_EFFECT: "no_effect",
	InjuryResolver.Outcome.SCRATCH: "scratch",
	InjuryResolver.Outcome.DOWN: "down",
	InjuryResolver.Outcome.DOWN_ON_DOWN: "down",
	InjuryResolver.Outcome.OUT_OF_ACTION: "out",
	# Tough / Memento Mori / Golem: Savaş Dışı yerine yere serildi
	InjuryResolver.Outcome.NEGATED_MEMENTO_MORI: "down",
	InjuryResolver.Outcome.NEGATED_TOUGH: "down",
	InjuryResolver.Outcome.NEGATED_GOLEM: "down",
	# Broken on the Wheel: Savaş Dışı yerine etkisiz
	InjuryResolver.Outcome.NEGATED_BROKEN_ON_WHEEL: "no_effect",
}

static func post(kind: StringName, data: Dictionary) -> void:
	var mp := GameEvents.multiplayer
	if mp.has_multiplayer_peer() and not mp.is_server():
		return
	RpcHelper.sync(GameEvents, "rpc_battle_event", [kind, data])

static func hit(attacker, target, weapon_name: String, roll: int, crit: bool) -> void:
	post(&"hit", {"a": String(attacker.name), "t": String(target.name), "w": weapon_name,
		"roll": roll, "crit": crit})

static func miss(attacker, target, weapon_name: String, roll: int) -> void:
	post(&"miss", {"a": String(attacker.name), "t": String(target.name) if is_instance_valid(target) else "",
		"w": weapon_name, "roll": roll})

static func injury(target, outcome: int, markers_added: int) -> void:
	post(&"injury", {"t": String(target.name), "o": OUTCOME_KEYS.get(outcome, "no_effect"),
		"m": markers_added})

static func ability(caster, ability_name_key: String, success: bool) -> void:
	post(&"ability", {"a": String(caster.name), "k": ability_name_key, "ok": success})
