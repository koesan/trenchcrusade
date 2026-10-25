extends RefCounted

## Faz 2 (P0-B) regresyon kilidi: bu turda görünür/işlevsel hale getirilen aktif yetenekler,
## panelde GÖRÜNMEZ (custom + uygulanmamış) durumuna geri düşmemeli.
## Bir aktif yetenek "işlevsel" sayılır: effect_type generic İSE ya da ability_id AbilityRegistry.CUSTOM'te.

const AbilityExecutor = preload("res://scripts/rules/ability_executor.gd")
const GENERIC := ["blessing", "remove_blood", "stand_up", "move_allies",
	"force_activation", "force_move", "teleport", "buff_dice", "add_blood", "set_flag"]

func _functional(t, path: String) -> void:
	var ab = load(path)
	t.ok(ab != null, "yüklenir: " + path.get_file())
	if ab == null:
		return
	var ok: bool = ab.effect_type in GENERIC or AbilityRegistry.is_implemented(ab.ability_id)
	t.ok(ok, "%s işlevsel (eff=%s)" % [String(ab.ability_id), ab.effect_type])

func run(t) -> void:
	# Re-tag edilenler
	var aim = load("res://assets/data/abilities/aim.tres")
	t.eq(aim.effect_type, "buff_dice", "aim → buff_dice")
	t.eq(aim.effect_amount, 2, "aim +2 DICE")
	t.eq(aim.buff_is_melee, false, "aim yalnız menzilli")
	var portal = load("res://assets/data/abilities/goetic_portal.tres")
	t.eq(portal.effect_type, "teleport", "goetic_portal → teleport")
	t.eq(portal.target_type, "position", "goetic_portal hedefi konum")

	# C2a: custom → generic add_blood migrasyonu (kod yerine veri)
	var gaze = load("res://assets/data/abilities/goetic_gaze.tres")
	t.eq(gaze.effect_type, "add_blood", "goetic_gaze → add_blood")
	t.eq(gaze.effect_amount, 1, "goetic_gaze +1 Kan")
	t.eq(gaze.feedback_kind, "curse", "goetic_gaze feedback curse")
	var judge = load("res://assets/data/abilities/divine_judgement.tres")
	t.eq(judge.effect_type, "add_blood", "divine_judgement → add_blood")
	t.eq(judge.blood_bonus_vs_unholy, 1, "divine_judgement unholy'ye +1 (toplam 2)")
	# Artık custom değiller → AbilityRegistry.CUSTOM'te OLMAMALILAR (ölü kod kalmasın)
	t.ok(not AbilityRegistry.is_implemented(&"goetic_gaze"), "goetic_gaze custom listesinden çıktı")
	t.ok(not AbilityRegistry.is_implemented(&"divine_judgement"), "divine_judgement custom listesinden çıktı")

	# C2a: hide → generic set_flag (is_hidden) migrasyonu; artık custom DEĞİL
	var hide = load("res://assets/data/abilities/hide.tres")
	t.eq(hide.effect_type, "set_flag", "hide → set_flag")
	t.eq(hide.flag_name, "is_hidden", "hide flag_name is_hidden")
	t.ok(not AbilityRegistry.is_implemented(&"hide"), "hide custom listesinden çıktı")

	# Hâlâ custom kalan handler'lar AbilityRegistry.CUSTOM'te olmalı
	for aid in ["voice_of_god", "fortify", "shadow_walker"]:
		t.ok(AbilityRegistry.is_implemented(StringName(aid)), aid + " uygulanmış listede")

	# Bu turda işlevsel hale gelen tüm aktif yetenekler
	# NOT: shadow_walker yeteneği (tarihsel nedenle) shadow_step.tres dosyasında saklanıyor.
	for f in ["aim", "goetic_portal", "voice_of_god", "hide", "fortify", "shadow_step"]:
		_functional(t, "res://assets/data/abilities/%s.tres" % f)
