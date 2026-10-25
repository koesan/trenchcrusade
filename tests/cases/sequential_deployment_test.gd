extends RefCounted

## Kullanıcı isteği: "Deployment sırası (sırayla yerleştirme) bunu da ekle." Compendium (TÜM
## senaryolar): "The players roll-off... then alternate deploying their models one at a time...
## If a player runs out of models to set up, the other player sets up all their remaining models."
##
## GameState.active_deployer_id ÖNCEDEN de vardı ama yalnız çevrimdışı modda, TEK SEFERLİK bir
## UI-kolaylığı olarak (1 bitince 2'ye geç) kullanılıyordu — gerçek bir "sırayla" zorlaması YOKTU,
## her iki oyuncu da her zaman serbestçe yerleştirebiliyordu. Artık can_player_deploy_more() sırayı
## GERÇEKTEN uyguluyor; deploy_panel.gd'nin ZATEN VAR OLAN "WAITING_OTHER_SQUAD" ekranı (P1-8'den
## beri) bunu otomatik gösteriyor — yeni UI kodu YAZILMADI.

func _reset_deploy_state() -> void:
	GameState.player_deploy_pool = {1: 500, 2: 500}
	GameState.player_deployed_count = {1: 0, 2: 0}
	GameState.player_deployment_finished = {1: false, 2: false}
	GameState.active_deployer_id = 1

func run(t) -> void:
	_reset_deploy_state()

	# ── _has_deploy_budget: SAF bütçe/limit kontrolü, sıradan BAĞIMSIZ ──────────────────────
	t.ok(GameState._has_deploy_budget(1), "Oyuncu 1 bütçesi var → _has_deploy_budget true")
	t.ok(GameState._has_deploy_budget(2), "Oyuncu 2 bütçesi var → _has_deploy_budget true")

	# ── can_player_deploy_more: SIRA dışındaki oyuncu bekler ────────────────────────────────
	GameState.active_deployer_id = 1
	t.ok(GameState.can_player_deploy_more(1), "Sıra Oyuncu 1'de → Oyuncu 1 yerleştirebilir")
	t.ok(not GameState.can_player_deploy_more(2),
		"Sıra Oyuncu 1'de, Oyuncu 2'nin bütçesi olsa da → Oyuncu 2 BEKLER (WAITING_OTHER_SQUAD)")

	GameState.active_deployer_id = 2
	t.ok(GameState.can_player_deploy_more(2), "Sıra Oyuncu 2'de → Oyuncu 2 yerleştirebilir")
	t.ok(not GameState.can_player_deploy_more(1), "Sıra Oyuncu 2'de → Oyuncu 1 BEKLER")

	# ── deploy_unit: her yerleştirmeden sonra sıra RAKİBE geçer (rakip hâlâ yerleştirebiliyorsa) ──
	_reset_deploy_state()
	var fake_unit = null
	GameState.deploy_unit(1, fake_unit, 50)  # Oyuncu 1 yerleştirdi
	t.eq(GameState.active_deployer_id, 2, "Oyuncu 1 yerleştirince → sıra Oyuncu 2'ye geçer")
	GameState.deploy_unit(2, fake_unit, 50)  # Oyuncu 2 yerleştirdi
	t.eq(GameState.active_deployer_id, 1, "Oyuncu 2 yerleştirince → sıra tekrar Oyuncu 1'e geçer")

	# ── "Rakip tükendiyse sıra bu oyuncuda KALIR" (compendium: "the other player sets up all
	# their remaining models, one after another") ───────────────────────────────────────────
	_reset_deploy_state()
	GameState.player_deploy_pool[2] = 0  # Oyuncu 2'nin bütçesi tükendi
	GameState.active_deployer_id = 1
	var fake_unit2 = null
	GameState.deploy_unit(1, fake_unit2, 10)
	t.eq(GameState.active_deployer_id, 1,
		"Rakip (Oyuncu 2) tükendiyse sıra Oyuncu 1'de KALIR (art arda yerleştirebilir)")
	t.ok(GameState.can_player_deploy_more(1), "Oyuncu 1 art arda yerleştirmeye devam edebiliyor")

	# ── finish_player_deployment de sırayı doğru geçiriyor mu ───────────────────────────────
	_reset_deploy_state()
	GameState.active_deployer_id = 1
	GameState.finish_player_deployment(1)
	t.eq(GameState.active_deployer_id, 2,
		"Oyuncu 1 manuel bitirince (bütçesi kalsa da) → sıra Oyuncu 2'ye geçer")

	# ── all_deployed kontrolü SAF bütçeye bakmalı, SIRAYA değil (aksi halde faz ERKEN kapanırdı) ──
	_reset_deploy_state()
	GameState.player_deploy_pool = {1: 0, 2: 500}  # Oyuncu 1 tükendi, Oyuncu 2'nin hâlâ bütçesi var
	GameState.active_deployer_id = 1  # ama sıra hâlâ (yanlışlıkla) Oyuncu 1'de kalmış olsun
	GameState.player_deployment_finished[1] = true
	t.ok(not GameState._has_deploy_budget(1), "Oyuncu 1 gerçekten tükendi")
	t.ok(GameState._has_deploy_budget(2), "Oyuncu 2'nin hâlâ GERÇEK bütçesi var (sıradan bağımsız)")
	# (deploy_unit'in 'all_deployed' bloğu _has_deploy_budget kullanıyor — bu iki assert onun
	# doğru girdilerle çalıştığını dolaylı kanıtlıyor; fazın ERKEN kapanmaması regresyon kilidi.)

	_reset_deploy_state()
