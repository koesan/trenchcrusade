## DiceRoller
## Trench Roll zar atma mantığını merkezileştiren yardımcı sınıf.
class_name DiceRoller

## roll_type + toplam sonuca göre dice_bar.gd'nin göstereceği sonuç mesajı ANAHTARINI döndürür
## (SAF fonksiyon — Node'suz test edilebilir). Tüm perform_trench_roll/show_dice_bar_ui.emit
## çağrı yerlerinin roll_type'ları burada TANINMALI — aksi halde o atışın sonuç metni boş kalır
## ("bazı zar atışlarında sonuç metni görünmüyor" bug sınıfı, bkz. be7125e + bu oturum).
static func result_text_key(roll_type: String, total_result: int) -> String:
	match roll_type:
		"success", "morale":
			return "ROLL_SUCCESS_OK" if total_result >= 7 else "ROLL_SUCCESS_FAIL"
		"injury":
			if total_result <= 1:
				return "ROLL_INJURY_NONE"
			elif total_result <= 6:
				return "ROLL_INJURY_SCRATCH"
			elif total_result <= 8:
				return "ROLL_INJURY_DOWN"
			else:
				return "ROLL_INJURY_OUT"
		"d6":
			return "ROLL_FRIENDLY_FIRE" if total_result <= 3 else "ROLL_ENEMY_HIT"
		_:
			# "bonus_roll" (mesafe/bonus atışları — başarı/başarısızlık yargısı yok) ve tanınmayan
			# her roll_type için nötr bir tamamlanma mesajı; ASLA boş dönmez.
			return "ROLL_BONUS_DISTANCE"

## Trench Roll zar havuzunu atar ve sonuçları hesaplar.
## keep_count: normal Success/Injury Roll için 2 (varsayılan). BLOODBATH ROLL için 3
## (veya silah DEADLY ise 4) — kural kitabı: "3D6 (ya da 4D6), en yüksek/düşük 3 (4) tutulur".
## Geri döndürür: [total_score, is_critical, sorted_values]
static func perform_trench_roll(node: Node, dice_modifier: int, flat_modifier: int = 0, roll_type: String = "success", keep_count: int = 2) -> Array:
	var num_dice = max(keep_count, keep_count + abs(dice_modifier))

	var has_mp = node.multiplayer.has_multiplayer_peer()
	# Bu eş atışı BİZZAT başlatıyor mu? (offline HER ZAMAN, MP'de yalnız sunucu). Öyleyse hangi
	# roll_id'nin bize ait olduğunu biliriz ve örtüşen başka bir atışın (ör. reaktif bir yeteneğin
	# eşzamanlı d6'sı) sonucunu YANLIŞLIKLA almayız — CombatChoice._ask'teki rid deseniyle aynı
	# güvenlik. MP istemcisi kendi atışını BAŞLATMAZ (sunucudan RPC ile gelir), roll_id'yi önceden
	# bilemez; o durumda eski (filtresiz) davranışta kalır — regresyon değil, mevcut sınır.
	var is_roll_owner: bool = not has_mp or node.multiplayer.is_server()
	if is_roll_owner:
		DiceManager.roll_dice(num_dice)

	var expected_roll_id: int = DiceManager.current_roll_id if is_roll_owner else -1
	var roll_data = await DiceManager.dice_roll_completed
	while is_roll_owner and roll_data[2] != expected_roll_id:
		roll_data = await DiceManager.dice_roll_completed
	var vals = roll_data[1] as Array

	if vals.size() < keep_count:
		vals = []
		for i in range(num_dice):
			vals.append(randi_range(1, 6))

	vals.sort()

	var kept_dice = []
	if dice_modifier >= 0:
		kept_dice = vals.slice(vals.size() - keep_count, vals.size())
	else:
		kept_dice = vals.slice(0, keep_count)

	var kept_sum = 0
	var has_double_six = false
	for i in range(kept_dice.size()):
		kept_sum += kept_dice[i]
		if kept_dice[i] == 6:
			for j in range(i + 1, kept_dice.size()):
				if kept_dice[j] == 6:
					has_double_six = true
	var total = kept_sum + flat_modifier
	var is_crit = has_double_six or kept_sum >= 12

	# Dice UI bar sinyalini tetikle
	var keep_highest = dice_modifier >= 0
	DiceManager.show_dice_bar_ui.emit(vals, keep_count, keep_highest, flat_modifier, total, roll_type)

	return [total, is_crit, vals]
