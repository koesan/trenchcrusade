extends RefCounted

## Kullanıcı bildirimi: "sıralı faction seçiminde sorunlar var, ben Iron Sultanate ve New Antioch
## seçiyorum ama Heretic gibi otomatik atama durumları oluyor, sıra ile ise otomatik değil benim
## seçtiğim faksiyonların üniteleri sırayla yerleştirilsin." Kök neden: GameState.select_faction,
## çevrimdışı (hotseat) modda Oyuncu 1 seçer seçmez Oyuncu 2'ye available_factions'taki İLK
## eşleşmeyen faksiyonu OTOMATİK atıyordu — Oyuncu 2'nin kendi seçimi hiç sorulmuyordu. Bu proje
## AI/bot rakip içermiyor (her iki taraf her zaman insan), bu yüzden bu otomatik atamanın hiçbir
## geçerli kullanım senaryosu yoktu; kaldırıldı.

func run(t) -> void:
	var original_factions: Dictionary = GameState.player_factions.duplicate()

	GameState.player_factions = {1: null, 2: null}
	t.ok(GameState.available_factions.size() >= 2, "Test için en az 2 faksiyon mevcut olmalı")

	var faction_a: Resource = GameState.available_factions[0]
	var faction_b: Resource = GameState.available_factions[1]

	GameState.select_faction(1, faction_a)
	t.eq(GameState.get_faction_for_player(1), faction_a, "Oyuncu 1 kendi seçtiği faksiyonu aldı")
	t.eq(GameState.get_faction_for_player(2), null,
		"Oyuncu 1 seçince Oyuncu 2'ye HİÇBİR faksiyon otomatik atanmadı (regresyon kilidi)")

	GameState.select_faction(2, faction_b)
	t.eq(GameState.get_faction_for_player(2), faction_b, "Oyuncu 2 kendi seçtiği faksiyonu aldı (ezilmedi)")
	t.eq(GameState.get_faction_for_player(1), faction_a, "Oyuncu 1'in seçimi hâlâ korunuyor")

	GameState.player_factions = original_factions
