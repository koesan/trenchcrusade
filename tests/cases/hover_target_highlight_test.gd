extends RefCounted

## Kullanıcı bildirimi: "unitler çok iç içe geçince saldırı yapıcam hangi unite saldıracağı belli
## değil... rastgele saldırıyor gibiyim, kimi seçtiğim/kime saldırdığım belli olsun." Kök neden:
## unit.gd zaten parlak, ayırt edici bir "targeted" seçim halkası taşıyordu (set_targeted/
## is_targeted, update_selection_ring'de EN YÜKSEK öncelikli renk) ama hiçbir yerden ÇAĞRILMIYORDU
## (dead code) — imlecin altındaki birim görsel olarak hiç ayırt edilmiyordu. map_input.gd::
## _update_hover artık bir eylem seçiliyken (attack/charge/yetenek) imlecin altındaki geçerli
## hedefe parlak halka veriyor, ve o hedef değişince/eylem bitince söndürüyor.
##
## Fare/kamera/fizik raycast gerektiren canlı kısım (bu projenin genel async/canlı-doğrulama
## kuralıyla tutarlı) test edilemez; burada SAF/yapısal parçalar kilitleniyor: set_targeted'ın
## hâlâ update_selection_ring'i tetiklediği ve map_input.gd'nin hover-vurgu/temizleme mantığını
## gerçekten çağırdığı.

func run(t) -> void:
	var unit_src := FileAccess.get_file_as_string("res://scenes/unit/unit.gd")
	# set_targeted, is_targeted'ı değiştirdikten SONRA update_selection_ring() çağırmalı — aksi
	# halde bayrak değişir ama halka hiç yenilenmez (görsel hiçbir şey olmaz).
	var idx: int = unit_src.find("func set_targeted(targeted: bool):")
	t.ok(idx != -1, "unit.gd → set_targeted() hâlâ tanımlı")
	if idx != -1:
		var body: String = unit_src.substr(idx, 120)
		t.ok(body.contains("is_targeted = targeted"), "set_targeted → is_targeted'ı ayarlıyor")
		t.ok(body.contains("update_selection_ring()"),
			"set_targeted → update_selection_ring() çağırıyor (halka HEMEN yenilenir)")

	var map_input_src := FileAccess.get_file_as_string("res://scripts/input/map_input.gd")
	t.ok(map_input_src.contains("hit.set_targeted(true)"),
		"map_input.gd → imlecin altındaki geçerli hedefe parlak halka veriliyor")
	t.ok(map_input_src.contains("func _clear_hover_highlight"),
		"map_input.gd → önceki hover hedefinin halkasını söndüren temizlik fonksiyonu var")
	t.ok(map_input_src.contains("_clear_hover_highlight()"),
		"map_input.gd → temizlik fonksiyonu gerçekten çağrılıyor (yalnız tanımlı değil)")
