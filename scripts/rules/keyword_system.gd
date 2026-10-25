## KeywordSystem — Generic Keyword Sözlüğü Okuyucu
##
## Bu sınıf STATELESS'tır.
## UnitData/AttackData'daki adlandırılmış boolean flag'lerin (has_tough, is_assault vb.)
## kapsamadığı her yeni compendium keyword'ü, script değişikliği gerektirmeden
## `keywords: Dictionary` alanına eklenip buradan okunur.
##
## Kullanım:
##   if KeywordSystem.has(attack_data, &"shotgun"): ...
##   var x := KeywordSystem.value(unit_data, &"blessed", 0)
class_name KeywordSystem

## Keyword flag olarak mevcut mu? (X-değerli keyword'ler için de true döner, değer > 0 ise)
static func has(data: Resource, kw: StringName) -> bool:
	if data == null or not ("keywords" in data):
		return false
	var kws: Dictionary = data.keywords
	return kws.has(kw) and int(kws[kw]) != 0

## X-değerli keyword'ün değerini döndürür (yoksa default).
static func value(data: Resource, kw: StringName, default: int = 0) -> int:
	if data == null or not ("keywords" in data):
		return default
	var kws: Dictionary = data.keywords
	if not kws.has(kw):
		return default
	return int(kws[kw])

## Bir modelin belirtilen "negate" etkisine sahip olup olmadığını döndürür.
## Doğrudan negate_X keyword'ünün yanı sıra onu BAHŞEDEN keyword'leri de hesaba katar
## (compendium keyword.md: STRONG→Negate Heavy, DEMONIC→Negate Fire,
## GOLEM→Negate Fear + Negate Gas). Tek noktadan okunması, bu grant ilişkilerinin
## motorun her yerinde tutarlı uygulanmasını sağlar.
static func negates(data: Resource, effect: StringName) -> bool:
	if data == null:
		return false
	if has(data, StringName("negate_" + String(effect))):
		return true
	match effect:
		&"heavy":
			return has(data, &"strong")
		&"fire":
			return has(data, &"demonic")
		&"fear", &"gas":
			return has(data, &"golem")
		_:
			return false

## "Kutsanmamış" hedef kontrolü (Divine Judgement, Found Guilty vb.):
## DEMONIC, BLACK GRAIL veya HERETIC keyword'lerinden birine sahip mi?
static func is_unholy(data: Resource) -> bool:
	return has(data, &"demonic") or has(data, &"black_grail") or has(data, &"heretic")
