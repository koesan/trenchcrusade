extends RefCounted

## P1-1 (Ecclesiastic Prisoner — Awaited): Martyrdom Device ile Savaş Dışı kalırsa Morale
## sayımına girmez. TurnManager.exempt_from_morale_count saf-ish davranışı (gerçek autoload
## state'ini kullanır, test sonunda geri alınır). Martyrdom Device'in kendisi (execute_martyrdom_
## device) async/RPC dice-roll'a bağlı, headless test edilemez.

func run(t) -> void:
	var before: int = TurnManager.player_starting_unit_counts.get(1, 0)
	TurnManager.player_starting_unit_counts[1] = 10
	TurnManager.exempt_from_morale_count(1)
	t.eq(TurnManager.player_starting_unit_counts[1], 9, "Awaited: morale-taban sayısı 1 azalır")

	TurnManager.player_starting_unit_counts[1] = 0
	TurnManager.exempt_from_morale_count(1)
	t.eq(TurnManager.player_starting_unit_counts[1], 0, "Awaited: 0'ın altına inmez (negatif olmaz)")

	TurnManager.player_starting_unit_counts[1] = before
