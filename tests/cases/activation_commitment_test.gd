extends RefCounted

## AKTİVASYON TAAHHÜDÜ (compendium denetimi, Adım 1) — bkz. scripts/rules/activation_rules.gd.

class FakeUnit extends RefCounted:
	var owner_id: int = 1
	var display_name: String = "Sahte"
	var has_moved: bool = false
	var current_health: int = 1
	var activation_started: bool = false
	var stood_up_this_activation: bool = false
	var actions_taken: Array = []

func run(t) -> void:
	var a := FakeUnit.new()
	var b := FakeUnit.new()
	var enemy := FakeUnit.new()
	enemy.owner_id = 2
	var all := [a, b, enemy]

	t.ok(not ActivationRules.is_committed(a), "Hiç seçilmemiş birim taahhütlü değil")
	a.activation_started = true
	t.ok(not ActivationRules.is_committed(a), "Seçilip hiçbir şey yapmayan birim taahhütlü değil (yanlış tıklama kilitlemez)")
	t.ok(ActivationRules.can_select(all, b), "Boş seçimden sonra başka birime geçilebilir")

	a.actions_taken.append("move")
	t.ok(ActivationRules.is_committed(a), "Eylem yapan birim taahhütlü")
	t.ok(not ActivationRules.can_select(all, b), "A yarıda iken aynı oyuncu B'yi seçemez")
	t.ok(ActivationRules.can_select(all, a), "Taahhütlü birimin kendisi yeniden seçilebilir")
	t.ok(ActivationRules.can_select(all, enemy), "Rakibin seçimini etkilemez")

	a.has_moved = true
	t.ok(ActivationRules.can_select(all, b), "A'nın aktivasyonu bitince B seçilebilir")

	var c := FakeUnit.new()
	c.activation_started = true
	c.stood_up_this_activation = true
	t.ok(ActivationRules.is_committed(c), "Ayağa kalkan birim (aktivasyonun ilk adımı) taahhütlü")
	c.current_health = 0
	t.ok(not ActivationRules.is_committed(c), "Savaş dışı kalan birim kilit tutmaz (soft-lock yok)")

	# Kaynak kodu: aktivasyon-başı etkileri round başına bir kez.
	var src := FileAccess.get_file_as_string("res://scenes/unit/unit.gd")
	t.ok(src.contains("not has_moved and not activation_started:\n\t\tactivation_started = true"),
		"set_selected aktivasyon-başı etkilerini activation_started bayrağıyla bir kez çalıştırıyor")
	t.ok(src.contains("stood_up_this_activation = false\n\tactivation_started = false"),
		"reset_turn_actions activation_started'ı sıfırlıyor")
	var gs := FileAccess.get_file_as_string("res://scripts/game_state/game_state.gd")
	t.ok(gs.contains("ActivationRules.selection_block_reason"), "GameState.select_unit taahhüdü uyguluyor")
