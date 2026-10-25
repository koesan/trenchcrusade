## Bir yetenek çalıştırılırken handler'lara geçirilen TİP GÜVENLİ bağlam.
##
## Eskiden her handler kendi imzasını taşıyordu — kimi `(ability, caster, target, roll_total)`,
## kimi `(caster, roll_total)`, kimi `(caster, target, extra_param)`. Dispatcher (`match`) her
## dalda hangi argümanların hangi sırada geçtiğini bilmek zorundaydı; yeni bir handler eklemek
## dispatcher'ı DEĞİŞTİRMEYİ gerektiriyordu. Tek bir bağlam nesnesiyle imza sabitlendi:
##
##     static func apply(ctx: AbilityContext) -> bool     # döner: end_activation
##     static func validate(ctx: AbilityContext) -> String # opsiyonel; "" = geçerli
##
## Böylece yeni bir yetenek = `abilities/custom/` altına 1 dosya + registry'ye 1 satır.
class_name AbilityContext
extends RefCounted

## Çalıştırılan yetenek tanımı (AbilityData .tres).
var ability: Resource = null

## Yeteneği kullanan birim düğümü.
var caster = null

## Hedef — birim düğümü, `Vector3` (teleport/konum hedefli) ya da null (self/none).
var target = null

## Başarı zarı toplamı. `requires_roll == false` ise 0.
var roll_total: int = 0

## Başarı zarı Kritik miydi?
var is_crit: bool = false

## Yeteneğe özgü yerel ön-seçim (ör. Ammunition Sacrament'ın seçilen mühimmatı).
## Çoğu yetenek için boş string.
var extra_param: String = ""

static func create(p_ability: Resource, p_caster, p_target = null,
		p_roll_total: int = 0, p_is_crit: bool = false,
		p_extra_param: String = "") -> AbilityContext:
	var ctx := AbilityContext.new()
	ctx.ability = p_ability
	ctx.caster = p_caster
	ctx.target = p_target
	ctx.roll_total = p_roll_total
	ctx.is_crit = p_is_crit
	ctx.extra_param = p_extra_param
	return ctx
