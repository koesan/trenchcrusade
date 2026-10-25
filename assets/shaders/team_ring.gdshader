shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, shadows_disabled;

// TAKIM HALKASI: her birimin altında zemine yatık, faksiyon renginde, hafif ışıltılı halka.
// NEDEN: genel görünümde 2" boyundaki modeller koyu arazide kayboluyordu; masa oyunundaki
// boyalı kaide kenarının dijital karşılığı. Renk ve sönüklük birim başınadır (instance uniform)
// — tüm birimler TEK materyali paylaşır.
instance uniform vec4 team_color : source_color = vec4(0.8, 0.65, 0.3, 1.0);
// 1.0 = hazır; düşük değer = bu turda aktive olmuş (sönük).
instance uniform float vigor = 1.0;
// Aktivasyon ipucu (ActivationCues): 0 = yok, 1 = şimdi aktive edilebilir (yumuşak nabız),
// 2 = aktivasyonu sürüyor (halkanın dışında yavaşça dönen kesikli çember).
instance uniform float pulse = 0.0;

const float RING_INNER = 0.50;
const float RING_OUTER = 0.66;
const float GLOW_OUTER = 1.0;

void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	float ring = smoothstep(RING_INNER - 0.04, RING_INNER, r) * (1.0 - smoothstep(RING_OUTER, RING_OUTER + 0.04, r));
	float glow = (1.0 - smoothstep(RING_OUTER, GLOW_OUTER, r)) * step(RING_INNER, r) * 0.35;
	float beat = 0.5 + 0.5 * sin(TIME * 3.2);
	float ready = step(0.5, pulse) * (1.0 - step(1.5, pulse));
	float active = step(1.5, pulse);
	glow *= 1.0 + ready * beat * 1.4;
	float ang = atan(UV.y - 0.5, UV.x - 0.5);
	float dash = smoothstep(-0.25, 0.25, sin(ang * 10.0 - TIME * 1.6));
	float outer = smoothstep(0.76, 0.79, r) * (1.0 - smoothstep(0.88, 0.91, r)) * dash * active;
	float a = max(max(ring * 0.95, glow), outer * (0.75 + 0.25 * beat));
	vec3 lit = team_color.rgb * (1.35 + ready * beat * 0.35);
	ALBEDO = mix(team_color.rgb * 0.45, lit, max(ring, outer));
	ALPHA = a * team_color.a * mix(0.35, 1.0, vigor);
}
