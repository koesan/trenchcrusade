extends RefCounted

## Kullanıcı isteği: "yetenek seçince unit üstüne gelen sağ ortada açılan popup ekranında da aynı
## şekilde gerekli bilgiler olsun — o unite kullanılacaksa ne kadar zar atılacak, karşı tarafın
## durumunu etkiler vb. net şekilde açıklansın, hangi düşman/dost unit olduğu da net olsun."
##
## Önceden "Atış Breakdown Kartı" (shot_breakdown_card.gd) YALNIZ "attack" eylemi seçiliyken
## çalışıyordu — Charge veya herhangi bir data-driven yetenek (Vengeful Scripture, Slavemaster,
## Puppet Master vb.) seçiliyken imlecin altındaki hedefe dair HİÇBİR bilgi kartı yoktu. Artık
## show_for_ability (yeteneğin Task 3'te eklenen TOOLTIP_SUCCESS metni + menzil) ve show_for_charge
## (mesafe + olası hücum menzili aralığı) aynı kartı paylaşıyor.
##
## Fare/kamera/fizik raycast gerektiren canlı kısım (bu projenin genel canlı-doğrulama kuralıyla
## tutarlı) test edilemez; burada SAF/yapısal parçalar kilitleniyor.

func run(t) -> void:
	var card_src := FileAccess.get_file_as_string("res://scenes/ui/hud/shot_breakdown/shot_breakdown_card.gd")
	t.ok(card_src.contains("func show_for_ability("), "shot_breakdown_card.gd → show_for_ability tanımlı")
	t.ok(card_src.contains("func show_for_charge("), "shot_breakdown_card.gd → show_for_charge tanımlı")
	t.ok(card_src.contains("ability_label_key + \"_TOOLTIP_SUCCESS\""),
		"show_for_ability → yeteneğin kendi TOOLTIP_SUCCESS metnini kullanıyor (Task 3 ile aynı kaynak)")

	var hud_src := FileAccess.get_file_as_string("res://scenes/ui/hud/game_hud.gd")
	t.ok(hud_src.contains("func show_ability_breakdown("), "game_hud.gd → show_ability_breakdown sarmalayıcı var")
	t.ok(hud_src.contains("func show_charge_breakdown("), "game_hud.gd → show_charge_breakdown sarmalayıcı var")

	var map_input_src := FileAccess.get_file_as_string("res://scripts/input/map_input.gd")
	t.ok(map_input_src.contains("show_ability_breakdown"),
		"map_input.gd → hover sırasında yetenek breakdown'ı gerçekten çağrılıyor")
	t.ok(map_input_src.contains("show_charge_breakdown"),
		"map_input.gd → hover sırasında charge breakdown'ı gerçekten çağrılıyor")

	# Regresyon kilidi: eylem tamamlanınca (_refresh_hud) kart artık HEMEN kapanıyor mu (önceki
	# turda bu çağrı eksikti — kart ekranda takılı kalabilirdi).
	var refresh_hud_idx: int = map_input_src.find("func _refresh_hud(")
	t.ok(refresh_hud_idx != -1, "_refresh_hud tanımlı")
	if refresh_hud_idx != -1:
		var body: String = map_input_src.substr(refresh_hud_idx, 500)
		t.ok(body.contains("hide_shot_breakdown"),
			"_refresh_hud → hide_shot_breakdown çağırıyor (kart eylem bitince hemen kapanır)")
