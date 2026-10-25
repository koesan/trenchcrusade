## ARAZİ TİPİ KURALLARI — Difficult / Dangerous terrain.
##
## COMPENDIUM (comprehensive-rules/keyword.md + moving-over-terrain.md):
##
##   DIFFICULT TERRAIN: "Every 1" a model is moved across terrain with this Keyword counts as 2"."
##
##   DANGEROUS TERRAIN: "If you Activate a model that is in terrain with this Keyword, **or if you
##     move a model into terrain with this Keyword during a move**, you must take a [Risky Success]
##     Roll for the model. If the roll is a Success or Critical Success, you can carry on with the
##     model's move, and you do not have to take any more [Risky Success] Rolls for the model if it
##     moves into any more terrain with this Keyword as part of that move. If the roll is a
##     Failure, you must make an Injury Roll for the model and its Activation ends. Sometimes
##     DANGEROUS TERRAIN will have one or more Keywords in brackets directly after it. Any Injury
##     Rolls caused by the DANGEROUS TERRAIN rule have those Keywords."
##
## KURAL BOŞLUĞU (2026-07-29 compendium denetimi): `MechanicsResolver.suffers_difficult_terrain`
## YAZILMIŞ ve TEST EDİLMİŞTİ ama hareket akışından HİÇ ÇAĞRILMIYORDU — Difficult Terrain'in
## oyunda hiçbir etkisi yoktu. Dangerous Terrain ise hiç uygulanmamıştı; yalnız ÖZEL bir hâli
## olan Mined (mayın) vardı. İkisi de artık mevcut `TerrainManager` altyapısı üzerinden GENEL
## olarak işliyor.
##
## ⚠ İÇERİK NOTU: bugün sahaya konan arazi parçaları yalnız `trench` ([Cover]) ve `mine`
## ([Mined]). Hiçbir parça `difficult`/`dangerous_terrain` keyword'ü TAŞIMIYOR, dolayısıyla bu
## kurallar şu an tetiklenmiyor. Kurallar hazır; bir arazi `.tres`ine keyword eklendiği anda
## KOD DEĞİŞİKLİĞİ OLMADAN çalışırlar (`assets/data/terrain/` altına yeni bir parça yeterli).
##
## BİLİNÇLİ BASİTLEŞTİRME (dokümante): proje arazi sorgularını YOL BOYUNCA değil, NOKTA bazlı
## yapar (`TerrainManager.has_keyword_at`). Bu yüzden "arazinin içinden geçilen mesafe" yerine
## HEDEF NOKTA değerlendirilir. Aynı basitleştirme [Cover] ve [Mined] için de geçerli — tutarlı.
class_name TerrainRules

## Difficult Terrain'in hareket çarpanı (RAW: 1" = 2", yani etkin menzil YARIYA iner).
const DIFFICULT_TERRAIN_FACTOR := 0.5

## Hedef nokta Difficult arazideyse etkin hareket menzilini düşürür.
## `unit_data` `[Negate Difficult Terrain]` taşıyorsa (War Wolf) muaftır.
static func effective_move_distance(unit_data: Resource, target_pos: Vector3,
		max_dist: float) -> float:
	if not MechanicsResolver.suffers_difficult_terrain(unit_data, target_pos):
		return max_dist
	return max_dist * DIFFICULT_TERRAIN_FACTOR

## Bu konum Dangerous arazi mi?
static func is_dangerous(pos: Vector3) -> bool:
	return TerrainManager.has_keyword_at(pos, &"dangerous_terrain")

## AKTİVASYON BAŞI Dangerous Terrain kontrolü.
##
## ⚠ KURAL BOŞLUĞU (compendium denetimi, Adım 2): RAW iki AYRI tetikleyici tanımlar —
##   (a) "If you **Activate** a model that is in terrain with this Keyword"
##   (b) "**or** if you move a model into terrain with this Keyword during a move"
## Oyunda yalnız (b) uygulanıyordu. Sonuç: dikenli tele/mayın tarlasına giren model giriş anında
## bir kez zar atıyor, ardından ORADA SONSUZA KADAR risksiz durabiliyordu. Ayrıca araziden
## ÇIKARKEN de kontrol yapılmıyordu (hedef nokta tehlikeli değil) — oysa RAW aktivasyonun
## kendisini tetikleyici sayar, model nereye giderse gitsin.
##
## Aktivasyon başına BİR KEZ çalışır (`activation_terrain_checked` bayrağı `reset_turn_actions`
## ile her turda sıfırlanır) — RAW'ın "you do not have to take any more [Risky Success] Rolls
## for the model ... as part of that move" maddesiyle aynı ruh.
##
## Döner: aktivasyon bitirildi mi? (true ise çağıran kendi akışını da SONLANDIRMALIDIR.)
static func check_activation_start(unit) -> bool:
	if unit == null or not is_instance_valid(unit):
		return false
	if unit.activation_terrain_checked:
		return false
	unit.activation_terrain_checked = true
	if not is_dangerous(unit.global_position):
		return false
	GameLogger.log_warn("[Tehlikeli Arazi] %s tehlikeli arazide AKTİVE oldu — Risky Success Roll." \
		% unit.display_name, "MOVEMENT")
	return await _resolve_dangerous_roll(unit)

## DANGEROUS TERRAIN kontrolü — model bu konuma girdiğinde (ya da orada aktive olduğunda).
##
## Risky Success: başarısızlıkta Injury Roll + aktivasyon biter. Arazi parçasının TAŞIDIĞI
## element keyword'leri (Fire/Gas/Shrapnel) Injury Roll'a geçirilir — RAW'ın "any Injury Rolls
## caused by the DANGEROUS TERRAIN rule have those Keywords" maddesi.
##
## Döner: aktivasyon bitirildi mi?
static func check_dangerous_terrain(unit) -> bool:
	if unit == null or not is_instance_valid(unit) or unit.current_health <= 0:
		return false
	if not is_dangerous(unit.global_position):
		return false
	# Aktivasyon başında zaten atıldıysa tekrar atılmaz (RAW: "you do not have to take any more
	# [Risky Success] Rolls for the model if it moves into any more terrain with this Keyword").
	if unit.activation_terrain_checked:
		return false
	unit.activation_terrain_checked = true
	GameLogger.log_warn("[Tehlikeli Arazi] %s tehlikeli araziye girdi — Risky Success Roll." \
		% unit.display_name, "MOVEMENT")
	return await _resolve_dangerous_roll(unit)

## Risky Success + başarısızlıkta Injury Roll ve aktivasyon sonu. İki tetikleyici (aktivasyon
## başı / araziye giriş) AYNI çözümü paylaşır.
static func _resolve_dangerous_roll(unit) -> bool:
	if unit == null or not is_instance_valid(unit) or unit.current_health <= 0:
		return false
	var pos: Vector3 = unit.global_position
	var roll: Array = await unit.perform_unit_success_roll(0)
	var total: int = roll[0]
	if total >= RiskyRolls.SUCCESS_THRESHOLD:
		GameLogger.log_info("[Tehlikeli Arazi] %s güvenle geçti (%d)." \
			% [unit.display_name, total], "MOVEMENT")
		return false

	GameLogger.log_warn("[Tehlikeli Arazi] %s başarısız (%d) — Injury Roll + aktivasyon biter." \
		% [unit.display_name, total], "MOVEMENT")
	# Arazinin element keyword'ü (varsa) Injury Roll'a taşınır.
	await unit.resolve_injury_roll(unit, false, false, 0, 0, _terrain_injury_source(pos))
	if is_instance_valid(unit):
		TurnManager.end_unit_activation(unit)
	return true

## Tehlikeli arazinin doğurduğu Injury Roll'un "silahı" — parçanın Fire/Gas/Shrapnel gibi
## element keyword'lerini taşıyan geçici bir AttackData. Parça element taşımıyorsa null
## (düz Injury Roll).
static func _terrain_injury_source(pos: Vector3) -> Resource:
	for kw in [&"fire", &"gas", &"shrapnel"]:
		if TerrainManager.has_keyword_at(pos, kw):
			var atk := AttackData.new()
			atk.attack_name = "DANGEROUS_TERRAIN"
			atk.keywords[kw] = true
			return atk
	return null
