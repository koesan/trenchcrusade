extends RefCounted

## Kullanıcı isteği: "logları incele, tüm logları analiz et, sorunları tespit et çöz." Canlı log
## incelemesinde bulunan: iki RULES-ACCURATE (beklenen) oyun olayı — Dost Ateşi (Friendly Fire) ve
## Sarsılmış bir ordunun Moral Kontrolünü kaybederek oyunu kaybetmesi — yanlışlıkla log_error()
## (yazılım hatası seviyesi) ile loglanıyordu. Bunlar birer bug DEĞİL, kurallara göre normal oyun
## sonuçları; log_warn()'a düşürüldü (ERROR seviyesi gerçek kod/mantık hatalarına ayrılmalı — log
## tarama/izleme araçlarının bu normal olayları yanlışlıkla bug sanmaması için).

func run(t) -> void:
	var combat_resolver_src := FileAccess.get_file_as_string("res://scripts/rules/combat_resolver.gd")
	t.ok(not combat_resolver_src.contains('GameLogger.log_error("Dost Ateşi gerçekleşti'),
		"Dost Ateşi (Friendly Fire) artık log_error() DEĞİL — rules-accurate bir oyun olayı")
	t.ok(combat_resolver_src.contains('GameLogger.log_warn("Dost Ateşi gerçekleşti'),
		"Dost Ateşi → log_warn() kullanıyor")

	var turn_manager_src := FileAccess.get_file_as_string("res://scripts/turn_manager/turn_manager.gd")
	t.ok(not turn_manager_src.contains('GameLogger.log_error("[Morale Check] Oyuncu %d Sarsılmışken'),
		"Sarsılmış ordunun kaybetmesi artık log_error() DEĞİL — rules-accurate bir oyun sonucu")
	t.ok(turn_manager_src.contains('GameLogger.log_warn("[Morale Check] Oyuncu %d Sarsılmışken'),
		"Sarsılmış ordu kaybı → log_warn() kullanıyor")
