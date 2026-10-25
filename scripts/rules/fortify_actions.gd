## FortifyActions — Fortify ve Dug In'in arazi karşılığı (siper).
##
## KURAL KAYNAĞI:
##   Fortify (new-antioch.md Combat Engineer / iron-sultanate.md Sultanate Sapper):
##     "A Sultanate Sapper can take a Fortify [Action]. If they do so, take a [Risky Success]
##      Roll... If the roll is a Success or a Critical Success, the Sultanate Sapper has the
##      COVER Keyword UNTIL THEY MOVE AWAY FROM THEIR CURRENT POSITION."
##   Dug In (battlekit Shovel):
##     "A model equipped with a Shovel that STARTS THE GAME on Open terrain has the [Cover]
##      Keyword until it moves away from its starting position."
##
## Her ikisi de "modelin bulunduğu noktada bir mevzi kazılır" demektir. Bu yüzden sahaya
## GERÇEK bir siper arazi parçası (trench.glb) konur: `[Cover]` artık hem mekanik hem GÖRSEL
## olarak var olur ve rakip oyuncu neden −1 Dice yediğini sahada görebilir.
##
## ÖNEMLİ — Fortify YALNIZ [Cover] verir, mayın kurmaz. Mayın kurma (Set Mine) ayrı bir
## aksiyondur (MineActions). Compendium'da bu iki yetenek bağımsız tanımlanmıştır.
##
## Bu sınıf STATELESS'tır — durum `TerrainManager` (saha kaydı) ve `unit.has_fortify_cover`
## (hızlı bayrak) üzerinde tutulur.
class_name FortifyActions

const TRENCH_FEATURE := preload("res://assets/data/terrain/trench.tres")

## Kazılan mevzi DÜŞMANA BAKAR. Düşman modeli yoksa birimin kendi yönü kullanılır.
static func _facing_enemy(unit) -> float:
	var sum := Vector3.ZERO
	var n := 0
	for u in UnitQuery.enemies_of(unit):
		sum += u.global_position
		n += 1
	if n == 0:
		return unit.rotation.y
	var dir: Vector3 = (sum / float(n)) - unit.global_position
	if dir.length_squared() < 0.001:
		return unit.rotation.y
	return atan2(dir.x, dir.z)

## FORTIFY başarılı: birimin bulunduğu noktaya siper kaz, [Cover] bayrağını aç.
## Compendium: "the model has the COVER Keyword UNTIL THEY MOVE AWAY."
## Kazılan siper KALICIDIR — birim uzaklaşınca yalnız [Cover] avantajını kaybeder,
## siper sahada durur. Tekrar Fortify → sahaya YENİ siper eklenir, eskisi kalır.
## Döndürür: end_activation — false (Risky başarısızlığı `AbilityExecutor.execute()` yönetir).
static func apply_fortify(unit) -> bool:
	if unit == null:
		return false
	unit.has_fortify_cover = true
	_sync_flags(unit)
	TerrainManager.spawn_feature(TRENCH_FEATURE, unit.global_position,
		String(unit.name), _facing_enemy(unit))
	GameLogger.log_info("[Fortify] %s mevzi kazdı — [Cover] kazandı." % unit.display_name, "GAME")
	return false

## DUG IN: oyun başında Şovel taşıyan modele mevzi verir (zar YOK — pasif).
## Compendium: "A model equipped with a Shovel that starts the game on Open terrain
## has the [Cover] Keyword until it moves away from its starting position."
static func apply_dug_in(unit) -> void:
	if unit == null or not is_instance_valid(unit):
		return
	unit.has_fortify_cover = true
	_sync_flags(unit)
	TerrainManager.spawn_feature(TRENCH_FEATURE, unit.global_position,
		String(unit.name), _facing_enemy(unit))
	GameLogger.log_info("[Dug In] %s Şovel'iyle mevzilendi — [Cover]." % unit.display_name, "GAME")

## Bayrak değişimini tüm istemcilere yayar (ability_executor._handle_set_flag ile AYNI desen).
static func _sync_flags(unit) -> void:
	if unit.multiplayer.has_multiplayer_peer():
		unit.rpc("sync_ability_flags", unit.is_hidden, unit.has_fortify_cover,
			unit.shadow_walker_active, unit.slashing_attack_active)
