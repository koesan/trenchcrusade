extends RefCounted

## UI METİN HİJYENİ — oyuncuya görünen metinlere VERİ sızmasın.
##
## NEDEN (2026-10-23 ekran görüntüsü denetimi): 23 silah adı fiyatını adının içinde taşıyordu
## ("Machine Gun [50 Ducats]"). Ad, eylem butonuna ve armoury satırına olduğu gibi gidiyor;
## armoury fiyatı zaten ayrı sütunda yazdığı için ekranda "Greatsword / Axe [12 Ducats] … 12 ducats"
## gibi çift fiyat, savaş butonunda ise anlamsız bir fiyat görünüyordu. Fiyat VERİdir, addan ayrı
## gösterilir.
##
## Ayrıca oyuncu adı tek kaynaktan (PlayerLabel) gelmeli — eski dört farklı biçim
## ("Commander 1", "Squad 2", "Sacred Squad 2") geri dönmesin.

const PRICE_IN_NAME := "\\[\\d+\\s*(Ducats?|duka|dukat)\\]"

func run(t) -> void:
	var re := RegEx.create_from_string("(?i)" + PRICE_IN_NAME)
	for lang in ["en", "tr"]:
		var f := FileAccess.open("res://assets/localization/%s.json" % lang, FileAccess.READ)
		t.ok(f != null, "%s.json açılabildi" % lang)
		if f == null:
			continue
		var data: Dictionary = JSON.parse_string(f.get_as_text())
		var leaks: Array = []
		for key in data:
			if String(key).begins_with("ATTACK_") and re.search(String(data[key])) != null:
				leaks.append(key)
		t.eq(leaks.size(), 0, "%s: silah adlarında fiyat yok %s" % [lang, str(leaks)])

	for p in [
		"res://scenes/ui/hud/top_bar/top_bar.gd",
		"res://scenes/ui/hud/top_bar/round_medallion.gd",
		"res://scenes/ui/hud/top_bar/round_win_badge.gd",
		"res://scenes/ui/hud/deploy/deploy_panel.gd",
		"res://scenes/ui/faction_select/faction_selection_panel.gd",
	]:
		var src := FileAccess.get_file_as_string(p)
		t.ok(not src.contains("\"SACRED_SQUAD\"") and not src.contains("\"COMMANDER\""),
			"%s oyuncu adını PlayerLabel'dan alıyor" % p.get_file())
