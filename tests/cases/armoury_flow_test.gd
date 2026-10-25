extends RefCounted

## ARMOURY (Cephanelik) FAZ AKIŞI — "Alışverişi Bitir" kilitlenmesi.
##
## KULLANICI BİLDİRİMİ: "alışverişi bitir deyince 'rakip alışverişini bitiriyor' diyor ve
## bitirilmiyor". Manager mantığı her birim sayısında DOĞRU çalışıyordu; kök neden başkaydı:
##
##   `ArmouryManager.reset()` HİÇBİR YERDEN ÇAĞRILMIYORDU. `finished` sözlüğü oyunlar arasında
##   hayatta kalıyordu → İKİNCİ oyunda `finish_player()` daha ilk basışta "zaten bitmiş" diye
##   ERKEN DÖNÜYOR, sıra devri ve faz kontrolü hiç çalışmıyordu. Panel de bu durumda
##   "Rakip alışverişini bitiriyor..." yazıp butonu kilitliyordu. Satın alınan kalemler
##   (`warband_items`) da taşınıp LIMIT sayımını bozuyordu.
##
## Bu test ARDIŞIK OYUNLARI simüle eder — tek bir oyunu test etmek bugu KAÇIRIRDI.

func run(t) -> void:
	var backup_units: Dictionary = GameState.units.duplicate()
	var backup_phase = GameState.game_phase

	for game_no in [1, 2, 3]:
		GameState.clear_state()
		GameState.game_phase = GameState.GamePhase.ARMOURY
		GameState.player_deploy_pool = {1: 500, 2: 500}

		# Oyuncu 1 bitirir → sıra rakibe geçmeli, faz HENÜZ değişmemeli.
		ArmouryManager.finish_player(1)
		t.eq(ArmouryManager.current_shopper(), 2,
			"Oyun %d: P1 bitirince sıra P2'ye geçer" % game_no)
		t.eq(GameState.game_phase, GameState.GamePhase.ARMOURY,
			"Oyun %d: tek taraf bitince faz ARMOURY kalır" % game_no)

		# Oyuncu 2 bitirir → savaş başlamalı.
		ArmouryManager.finish_player(2)
		t.eq(GameState.game_phase, GameState.GamePhase.BATTLE,
			"Oyun %d: iki taraf da bitince faz BATTLE olur" % game_no)

	# ── `clear_state` ARMOURY durumunu gerçekten temizliyor mu? ───────────
	GameState.clear_state()
	t.eq(ArmouryManager.finished.size(), 0,
		"clear_state: `finished` temizlendi (oyunlar arası sızmaz)")
	t.eq(ArmouryManager.warband_items.size(), 0,
		"clear_state: satın alınan kalemler temizlendi (LIMIT sayımı bozulmaz)")
	t.eq(ArmouryManager.unit_items.size(), 0, "clear_state: model ekipmanları temizlendi")
	t.eq(ArmouryManager.active_shopper_id, 1, "clear_state: sıra 1. oyuncuya döner")

	# Kaynak bağlantısı gerçekten kurulu mu? (Asıl bulgu buydu: fonksiyon vardı, çağrı yoktu.)
	var src := FileAccess.open("res://scripts/game_state/game_state.gd", FileAccess.READ)
	t.ok(src != null, "game_state.gd okunabildi")
	if src != null:
		var txt := src.get_as_text()
		src.close()
		t.ok(txt.contains("ArmouryManager.reset()"),
			"clear_state ArmouryManager.reset() ÇAĞIRIYOR")

	# Kendini onaran akış: zaten bitmiş bir oyuncuyu tekrar bitirmek AKIŞI DURDURMAMALI.
	GameState.game_phase = GameState.GamePhase.ARMOURY
	GameState.player_deploy_pool = {1: 500, 2: 500}
	ArmouryManager.finish_player(1)
	ArmouryManager.finish_player(1)   # tekrar — eskiden sessizce erken dönerdi
	t.eq(ArmouryManager.current_shopper(), 2,
		"Aynı oyuncuyu tekrar bitirmek sıra devrini BOZMAZ (kendini onaran akış)")

	GameState.clear_state()
	GameState.units = backup_units
	GameState.game_phase = backup_phase
