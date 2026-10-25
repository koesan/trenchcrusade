extends RefCounted

## AbilityExecutor.is_actionable_ability — panel + has_any_remaining_action TEK kaynak filtre (P2-7).
## Aktif buton üretebilen yetenek: action_key dolu, temel eylemle çakışmayan, uygulanmış.

const AbilityExecutor = preload("res://scripts/rules/ability_executor.gd")

class FakeAbility:
	extends Resource
	var action_key: String = ""
	var effect_type: String = ""
	var ability_id: StringName = &""

func _make(action_key: String, effect_type: String, ability_id: StringName) -> FakeAbility:
	var a := FakeAbility.new()
	a.action_key = action_key
	a.effect_type = effect_type
	a.ability_id = ability_id
	return a

func run(t) -> void:
	# null → aktif değil.
	t.ok(not AbilityExecutor.is_actionable_ability(null), "null yetenek aktif buton değil")

	# Pasif (action_key boş) → aktif değil.
	t.ok(not AbilityExecutor.is_actionable_ability(_make("", "buff_dice", &"x")), "Pasif (boş action_key) buton değil")

	# Temel eylemle çakışan (örn. shoot) → aktif değil.
	t.ok(not AbilityExecutor.is_actionable_ability(_make("shoot", "buff_dice", &"x")), "Temel eylem çakışması buton değil")

	# Uygulanmamış custom → aktif değil (yanıltıcı ölü buton olmasın).
	t.ok(not AbilityExecutor.is_actionable_ability(_make("mystery", "custom", &"not_implemented")), "Uygulanmamış custom buton değil")

	# Uygulanmış custom (AbilityRegistry.CUSTOM içinde) → aktif buton.
	t.ok(AbilityExecutor.is_actionable_ability(_make("fortify_action", "custom", &"fortify")), "Uygulanmış custom aktif buton")

	# Generic (custom olmayan) efekt + dolu action_key → aktif buton.
	t.ok(AbilityExecutor.is_actionable_ability(_make("aim_action", "buff_dice", &"aim")), "Generic efekt aktif buton")
