extends RefCounted

## Kullanıcı bildirimi: "hala bir unit kullanıyorum ama sonra tekrar kullanabiliyorum" — canlı log
## incelemesinde (2026-07-18) bulunan kök neden: check_activation_complete() bir saldırının birden
## çok aşamasında (doğrulama → zar → yara) HER aşamada çağrılıyordu, ve has_any_remaining_action()
## zaten has_moved=true iken false döndüğü için, aktivasyon ZATEN bitmiş olsa bile "yapılabilecek
## başka aksiyon kalmadı, aktivasyon sona eriyor." log satırı VE TurnManager.end_unit_activation()
## çağrısı TEKRAR TEKRAR tetikleniyordu. İşlevsel bir çift-kullanım YOKTU (server_end_unit_
## activation zaten "if u.has_moved: return" ile idempotent) — ama bu log gürültüsü, aynı
## aktivasyonun "iki kez bittiği" izlenimi vererek kullanıcıyı "tekrar kullanabiliyorum" sanmaya
## itiyordu. check_activation_complete artık has_moved iken erkenden çıkıyor (log de basılmıyor).

func run(t) -> void:
	var unit_src := FileAccess.get_file_as_string("res://scenes/unit/unit.gd")
	var idx: int = unit_src.find("func check_activation_complete():")
	t.ok(idx != -1, "check_activation_complete tanımlı")
	if idx != -1:
		var body: String = unit_src.substr(idx, 1200)
		t.ok(body.contains("if has_moved:\n\t\treturn"),
			"check_activation_complete → has_moved iken erkenden çıkıyor (yinelenen log/çağrı yok)")
		# has_moved kontrolü, has_any_remaining_action() ÇAĞRISINDAN ÖNCE olmalı (aksi halde
		# yine de en az bir kez fazladan has_any_remaining_action() çalışırdı — küçük ama gereksiz).
		var moved_check_pos: int = body.find("if has_moved:")
		var remaining_action_pos: int = body.find("has_any_remaining_action()")
		t.ok(moved_check_pos != -1 and remaining_action_pos != -1 and moved_check_pos < remaining_action_pos,
			"has_moved kontrolü has_any_remaining_action() çağrısından ÖNCE yapılıyor")
