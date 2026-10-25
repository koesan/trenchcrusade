## INFLICT PAIN (Combat Biologist'in Vivisector'ı)
##
## Kritik başarı + hedef Savaş Dışı DEĞİLSE + hedef ARTIFICIAL değilse → D3" doğrudan
## saldırgandan uzağa savrulur. Gövde `unit.gd::_apply_inflict_pain`de kalır: itme sırasında
## serbest melee vuruşları tetikleniyor ve bu, hedef düğümün kendi durumuna (`_inflict_pain_
## resolving` / `_inflict_pain_extra_dist` özyineleme koruması) sıkıca bağlı.
##
## Bilinçli basitleştirme: taban-boyutu şartı uygulanmadı (proje baz boyutu modellemiyor).
extends RefCounted

static func matches(ctx: InjuryContext) -> bool:
	return ctx.critical_hit and not ctx.is_ooa() and ctx.atk != null \
		and KeywordSystem.has(ctx.atk, &"inflict_pain") \
		and not (ctx.target_data() != null and KeywordSystem.has(ctx.target_data(), &"artificial"))

static func apply(ctx: InjuryContext) -> void:
	await ctx.target._apply_inflict_pain(ctx.attacker)
