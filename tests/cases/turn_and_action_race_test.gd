extends RefCounted

## Kullanıcı bildirimi (2 ayrı sorun):
## 1. "bazen tur atla diyorum atlamıyor" — TurnManager.end_turn() önceden SADECE seçili birim
##    tam olarak GameState.selected_unit'e eşitse çalışıyordu; oyuncu aktive ettiği birimi bırakıp
##    başka bir şeye (ör. düşmanı incelemeye) tıklarsa, buton sessizce hiçbir şey yapmıyordu.
##    Artık MechanicsResolver.find_stuck_activation_unit ile YARIDA kalan (en az 1 aksiyon almış
##    ama has_moved=false) birim otomatik bulunuyor.
## 2. "yetenek kullanıyorum sonra tekrar kullanabiliyorum" — server_request_ability/dash/move/
##    retreat İSTEMCİNİN ön-kontrolüne güveniyordu, sunucu tarafında can_perform_action TEKRAR
##    kontrol edilmiyordu. Hızlı çift-tıklama/ağ gecikmesiyle aynı aksiyon iki kez sunucuya
##    ulaşırsa, ikinci RPC etkiyi ikinci kez uygulardı. Bu, canlı/RPC gerektiren bir davranış
##    olduğundan (bkz. court_goetic_test.gd'deki async notu) burada yalnızca KAYNAK KONTROLÜ
##    (regresyon kilidi) yapılıyor — dört fonksiyonun da server-side can_perform_action guard'ı var mı.

class FakeUnit:
	var owner_id: int = 1
	var current_health: int = 10
	var has_moved: bool = false
	var actions_taken: Array = []
	func _init(p_owner: int, p_health: int, p_has_moved: bool, p_actions: Array) -> void:
		owner_id = p_owner
		current_health = p_health
		has_moved = p_has_moved
		actions_taken = p_actions

func run(t) -> void:
	# ── find_stuck_activation_unit: SAF mantık ──────────────────────────────────
	var units: Dictionary = {
		"idle_unit": FakeUnit.new(1, 10, false, []),           # hiç aksiyon almamış — "yarıda" DEĞİL
		"stuck_unit": FakeUnit.new(1, 10, false, ["move"]),     # aksiyon aldı ama bitirmedi — YARIDA
		"finished_unit": FakeUnit.new(1, 10, true, ["move"]),   # zaten bitirmiş (has_moved=true)
		"enemy_unit": FakeUnit.new(2, 10, false, ["charge"]),   # rakip oyuncuya ait, sayılmamalı
		"dead_unit": FakeUnit.new(1, 0, false, ["dash"]),       # ölü, sayılmamalı
	}
	var found = MechanicsResolver.find_stuck_activation_unit(units, 1)
	t.ok(found != null, "Yarıda kalan (aksiyon almış ama bitirmemiş) birim bulundu")
	t.eq(found.actions_taken, ["move"], "Bulunan birim gerçekten 'stuck_unit' (doğru actions_taken)")

	var no_stuck: Dictionary = {
		"idle_unit": FakeUnit.new(1, 10, false, []),
		"finished_unit": FakeUnit.new(1, 10, true, ["move"]),
	}
	t.eq(MechanicsResolver.find_stuck_activation_unit(no_stuck, 1), null,
		"Yarıda kalan birim yoksa null döner (regresyon: hiçbir şeyi yanlışlıkla 'bitir' etmez)")

	t.eq(MechanicsResolver.find_stuck_activation_unit(units, 2).actions_taken, ["charge"],
		"Oyuncu 2 için kendi yarıda kalan birimi bulunur (allegiance karışmaz)")

	# ── Sunucu-otoriter yeniden doğrulama: kaynak kontrolü (regresyon kilidi) ───
	var unit_src := FileAccess.get_file_as_string("res://scenes/unit/unit.gd")
	var guard_count := 0
	var search_from := 0
	while true:
		var idx: int = unit_src.find("SUNUCU-OTORİTER YENİDEN DOĞRULAMA", search_from)
		if idx == -1:
			break
		guard_count += 1
		search_from = idx + 1
	t.eq(guard_count, 4,
		"server_request_dash/move_action/retreat/ability → hepsinde sunucu-taraf can_perform_action guard'ı var (4 nokta)")
