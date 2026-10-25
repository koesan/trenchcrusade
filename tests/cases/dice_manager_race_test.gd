extends RefCounted

## Kullanıcı bildirimi: "bazen zar atılıyor ama animasyon olmuyor, zar düşüyor ve bir anda yok
## oluyor. sistem çalışıyor sadece animasyon sorunu var." Kök neden: bir üst katman önceki atışın
## animasyonu bitmeden (dice_roll_completed ateşlenmeden) YENİ bir atış tetiklerse,
## roll_dice_with_values baştaki "havuzu beklemeye al" adımıyla önceki atışın hâlâ havada olan
## zarlarını ANINDA gizler/öldürür — VE watchdog artık current_roll_id ilerlediği için o eski
## atışı asla tamamlamaz (roll_id != current_roll_id → no-op), böylece onu bekleyen çağıran ya
## sonsuza dek asılı kalır ya da (roll_id filtresi yoksa) BAŞKA bir atışın sonucunu yanlışlıkla alır.
##
## Düzeltme: roll_dice_with_values artık yeni atışı başlatmadan ÖNCE, yarıda kalan önceki atışı
## (varsa) zaten planlanmış target_value'larla ZORLA tamamlıyor — hem sinyal hep ateşlenir hem de
## doğru (rastgele değil, gerçekten o zara atanmış) değerler kullanılır.

class FakeDie:
	var target_value: int = 0
	func _init(v: int) -> void:
		target_value = v

func run(t) -> void:
	var captured: Array = []
	var conn := func(total, values, roll_id): captured.append([total, values, roll_id])
	DiceManager.dice_roll_completed.connect(conn)

	# Önceki atışı "yarıda kalmış" gibi simüle et: roll_id=42, 2 zar bekleniyordu, yalnız 1'i durdu.
	DiceManager.current_roll_id = 42
	DiceManager._completed_for_id = -1
	DiceManager.active_dice = [FakeDie.new(3), FakeDie.new(5)]
	DiceManager.stopped_dice_count = 1

	# Yeni bir atış tetiklenince (roll_dice_with_values), yarıda kalan önceki atış (roll_id=42)
	# ZORLA tamamlanmalı — planlanmış target_value'larla (3, 5), rastgele değil.
	DiceManager.roll_dice_with_values([2])

	DiceManager.dice_roll_completed.disconnect(conn)
	DiceManager.clear_dice()  # test sahnesindeki gerçek zar havuzunu temiz bırak

	var forced: Array = captured.filter(func(c): return c[2] == 42)
	t.eq(forced.size(), 1, "Yarıda kalan önceki atış (roll_id=42) ZORLA tamamlandı, kaybolmadı")
	if forced.size() > 0:
		t.eq(forced[0][1], [3, 5], "Zorla tamamlanan atış, zarlara ÖNCEDEN atanmış target_value'ları kullandı")
		t.eq(forced[0][0], 8, "Zorla tamamlanan atışın toplamı doğru (3+5=8)")

	# Zaten tamamlanmış bir atış (stopped_dice_count == active_dice.size()) tekrar ZORLA
	# tamamlanmaya ÇALIŞILMAMALI (çift-tamamlama/yanlış-pozitif olmamalı — regresyon kilidi).
	captured.clear()
	DiceManager.dice_roll_completed.connect(conn)
	DiceManager.current_roll_id = 99
	DiceManager._completed_for_id = 99
	DiceManager.active_dice = [FakeDie.new(4)]
	DiceManager.stopped_dice_count = 1
	DiceManager.roll_dice_with_values([2])
	DiceManager.dice_roll_completed.disconnect(conn)
	DiceManager.clear_dice()

	var stale: Array = captured.filter(func(c): return c[2] == 99)
	t.eq(stale.size(), 0, "Zaten tamamlanmış bir atış (_completed_for_id eşleşiyor) tekrar zorlanmadı")
