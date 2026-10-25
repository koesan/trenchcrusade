extends RefCounted

## MİMARİ BEKÇİSİ — god-file'ların yeniden büyümesini ve ölü alanların geri gelmesini engeller.
##
## Bu test bilinçli olarak KATIdır ve bir CIRCIR (ratchet) görevi görür: bir dosya tavanı aşarsa
## yeni mantık oraya değil, kendi modülüne gitmelidir. Bir dosya küçüldükçe tavanı da düşürülür.
##
## Proje kuralı: 400 satırı geçen bir dosyaya yeni sorumluluk EKLENMEZ.
##
## 2026-07-29 MİMARİ TURU — bu tavanların geldiği yer:
## Tur başında ALTI dosyanın ALTISI da tavanının %95-99'undaydı, yani pratikte YENİ ÖZELLİK
## EKLENEMEZ durumdaydı. Kök neden dosya boyutu değil, UZATMA NOKTASI (seam) yokluğuydu: her
## yeni kural gidecek tek yeri mevcut dev fonksiyonun İÇİ buluyordu. Üç seam açıldı —
## `AbilityRegistry` (yetenekler), `InjuryTriggers` (yara kuralları), `DeployFlow` (yerleşim
## kapıları) — ve `UnitQuery` sorgu tekrarını kaldırdı.
##     unit.gd 2191 → 1642 | ability_executor 1187 → 290 | game.gd 786 → 554
## Bu tavanlar o kazanımı KİLİTLER. Bir dosya yeniden büyüyorsa, eklenen şey yanlış yerdedir.

## dosya → izin verilen en fazla satır (mevcut değerin biraz üstü = büyümeye kapalı)
const SIZE_LIMITS := {
	"res://scenes/unit/unit.gd": 1660,
	"res://scripts/rules/ability_executor.gd": 305,
	"res://scenes/game/game.gd": 570,
	"res://scenes/ui/hud/game_hud.gd": 715,
	"res://scripts/game_state/game_state.gd": 630,
	"res://scripts/turn_manager/turn_manager.gd": 590,
}

## Yeni çıkarılan sorumluluk modülleri — bunlar KÜÇÜK kalmalı.
const MODULE_LIMIT := 400

## Yetenek handler'ları TEK BİR yeteneği uygular; büyümeleri "handler çok iş yapıyor" demektir.
const ABILITY_HANDLER_DIR := "res://scripts/rules/abilities/custom"
const ABILITY_HANDLER_LIMIT := 150

## Yara tetikleyicileri TEK bir özel kuralı uygular — büyümeleri sınır kaymasıdır.
const INJURY_TRIGGER_DIR := "res://scripts/rules/injury/triggers"
const INJURY_TRIGGER_LIMIT := 60
const MODULES := [
	"res://scripts/rules/unit_query.gd",
	"res://scripts/rules/abilities/ability_context.gd",
	"res://scripts/rules/abilities/ability_registry.gd",
	"res://scripts/rules/injury/injury_context.gd",
	"res://scripts/rules/injury/injury_pipeline.gd",
	"res://scripts/rules/injury/injury_marker_spend.gd",
	"res://scripts/rules/injury/injury_triggers.gd",
	"res://scripts/unit/attack_context.gd",
	"res://scripts/rules/deploy/deploy_request.gd",
	"res://scripts/utils/unit_serializer.gd",
	"res://scripts/ui/display_scale.gd",
	"res://scripts/ui/ui_placement.gd",
	"res://scripts/rules/risky_rolls.gd",
	"res://scripts/rules/terrain_rules.gd",
	"res://scenes/ui/shared/info_popup.gd",
	"res://scripts/unit/unit_attack_chains.gd",
	"res://scripts/rules/fortify_actions.gd",
	"res://scripts/rules/mine_actions.gd",
	"res://scripts/rules/mine_resolver.gd",
	"res://scripts/rules/medic_actions.gd",
	"res://scripts/rules/economy_rules.gd",
	"res://scripts/rules/roster_rules.gd",
	"res://scripts/rules/deploy_rules.gd",
	"res://scripts/scenario/terrain_manager.gd",
]

## UnitData'da BULUNMAMASI gereken alanlar.
## max_health / willpower : Trench Crusade'de hit point ve Willpower YOKTUR
## has_blast / base_color : motorda hiç okunmuyordu (ölü veri)
## is_chorister           : Chorister'ın gerçek kuralı `unholy_hymns` keyword'ü ile işliyor
const DEAD_UNIT_FIELDS := ["max_health", "willpower", "has_blast", "base_color", "is_chorister"]

func _line_count(path: String) -> int:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return -1
	var n := 0
	while not f.eof_reached():
		f.get_line()
		n += 1
	f.close()
	return n

func run(t) -> void:
	for path in SIZE_LIMITS.keys():
		var n := _line_count(path)
		t.ok(n > 0, "%s okunabildi" % path.get_file())
		if n <= 0:
			continue
		t.ok(n <= SIZE_LIMITS[path],
			"%s: %d <= %d satır — aşarsa yeni mantık kendi modülüne gitmeli" \
				% [path.get_file(), n, SIZE_LIMITS[path]])

	for path in MODULES:
		t.ok(ResourceLoader.exists(path), "%s mevcut" % path.get_file())
		var n2 := _line_count(path)
		if n2 <= 0:
			continue
		t.ok(n2 <= MODULE_LIMIT,
			"%s: %d <= %d satır (sorumluluk modülleri küçük kalmalı)" \
				% [path.get_file(), n2, MODULE_LIMIT])

	# Her custom yetenek handler'ı KÜÇÜK kalmalı ve sözleşmeyi sunmalı.
	var hd := DirAccess.open(ABILITY_HANDLER_DIR)
	t.ok(hd != null, "abilities/custom klasörü açılabildi")
	if hd != null:
		hd.list_dir_begin()
		var hf := hd.get_next()
		var handler_count := 0
		while hf != "":
			if hf.ends_with(".gd"):
				handler_count += 1
				var hp := ABILITY_HANDLER_DIR.path_join(hf)
				var hn := _line_count(hp)
				t.ok(hn > 0 and hn <= ABILITY_HANDLER_LIMIT,
					"%s: %d <= %d satır (bir handler tek yeteneği uygular)" \
						% [hf, hn, ABILITY_HANDLER_LIMIT])
			hf = hd.get_next()
		hd.list_dir_end()
		t.ok(handler_count >= 16, "%d yetenek handler'ı bulundu" % handler_count)

	# Her yara tetikleyicisi KÜÇÜK kalmalı (bir kural = bir dosya).
	var td := DirAccess.open(INJURY_TRIGGER_DIR)
	t.ok(td != null, "injury/triggers klasörü açılabildi")
	if td != null:
		td.list_dir_begin()
		var tf := td.get_next()
		var trigger_count := 0
		while tf != "":
			if tf.ends_with(".gd"):
				trigger_count += 1
				var tn := _line_count(INJURY_TRIGGER_DIR.path_join(tf))
				t.ok(tn > 0 and tn <= INJURY_TRIGGER_LIMIT,
					"%s: %d <= %d satır (bir tetikleyici tek kuralı uygular)" \
						% [tf, tn, INJURY_TRIGGER_LIMIT])
			tf = td.get_next()
		td.list_dir_end()
		t.ok(trigger_count >= 12, "%d yara tetikleyicisi bulundu" % trigger_count)

	var u := UnitData.new()
	for field in DEAD_UNIT_FIELDS:
		t.ok(not (field in u), "UnitData → ölü alan yok: %s" % field)

	# Zombi kod bekçisi: tanımlı ama HİÇ ÇAĞRILMAYAN bilinen fonksiyonlar geri gelmemeli.
	var combat_src := FileAccess.open("res://scripts/unit/unit_combat.gd", FileAccess.READ)
	var combat_txt := combat_src.get_as_text() if combat_src != null else ""
	if combat_src != null:
		combat_src.close()
	t.ok(not combat_txt.contains("is_near_enemy_chorister"),
		"is_near_enemy_chorister geri gelmedi (Unholy Hymns keyword'ü zaten uyguluyor)")
