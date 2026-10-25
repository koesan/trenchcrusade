extends RefCounted

## P0-1: Blood/Blessing Marker'ın Success Roll tarafı. Compendium (blood-markers.md/
## blessing-markers.md): RAKİP oyuncu Blood Marker harcayıp -1 Dice/marker, model SAHİBİ
## Blessing Marker harcayıp +1 Dice/marker ekler. Async RPC/UI orkestrasyonu (CombatChoice) ve
## TurnManager.get_opponent_id (multiplayer.has_multiplayer_peer()'a bağlı — bu headless test
## sahnesinde motor/ortam kaynaklı nedenlerle her zaman true dönüyor, GERÇEK oyunda değil)
## headless test edilemez; CombatChoice.request_blood_spend/request_blessing_spend (Injury Roll
## tarafı) zaten aynı deseni kullanıp canlı doğrulanmıştı — burada yalnız SAF zar formülü testli.

const DicePoolBuilder = preload("res://scripts/rules/dice_pool_builder.gd")

func run(t) -> void:
	# ── apply_success_marker_spend: işaret yönü kilitlensin (Blood -, Blessing +) ──
	t.eq(DicePoolBuilder.apply_success_marker_spend(0, 0, 0), 0, "Harcama yok → mod değişmez")
	t.eq(DicePoolBuilder.apply_success_marker_spend(0, 2, 0), -2, "2 Kan İşareti → -2 Dice")
	t.eq(DicePoolBuilder.apply_success_marker_spend(0, 0, 3), 3, "3 Nimet İşareti → +3 Dice")
	t.eq(DicePoolBuilder.apply_success_marker_spend(1, 2, 3), 2, "Taban mod + Nimet - Kan bileşik")
