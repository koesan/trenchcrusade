extends RefCounted

## Kullanıcı isteği: "In-game keyword sözlüğü". Ability/silah açıklamalarında "[Blast]",
## "[Cleave]" gibi terimler tanımsız kullanılıyordu; Chronicles hub'ından açılan yeni bir
## KeywordsOverlay bu sözlüğü sağlıyor (keywords_overlay.gd/.tscn). Bu test, sözlüğün TR/EN
## localization kapsamının eksiksiz olduğunu ve overlay'in doğru kaydedildiğini kilitler.

const KEYWORD_IDS := [
	"ASSAULT", "AUTOMATIC", "BLAST", "BLESSING_MARKER", "BLOCK", "BLOOD_MARKER", "CLEAVE",
	"COVER", "CRITICAL", "CUMBERSOME", "DEADLY", "ELITE", "FEAR", "FIRE", "FLAMETHROWER",
	"FLYING", "GAS", "GOLEM", "HEAVY", "IGNORE_ARMOUR", "IGNORE_X", "INFECTION_MARKER",
	"INFILTRATOR", "LEADER", "NEGATE_X", "PISTOL", "REGENERATE", "RELOAD", "RISKY", "SCATTER",
	"SHOTGUN", "SHRAPNEL", "SKIRMISHER", "STRONG", "TOUGH",
]

func run(t) -> void:
	var tr_file := FileAccess.get_file_as_string("res://assets/localization/tr.json")
	var en_file := FileAccess.get_file_as_string("res://assets/localization/en.json")
	var tr_json: Dictionary = JSON.parse_string(tr_file)
	var en_json: Dictionary = JSON.parse_string(en_file)

	t.ok(tr_json.has("KEYWORDS_GLOSSARY"), "KEYWORDS_GLOSSARY → tr.json'da var")
	t.ok(en_json.has("KEYWORDS_GLOSSARY"), "KEYWORDS_GLOSSARY → en.json'da var")

	for kw_id in KEYWORD_IDS:
		var name_key: String = "KEYWORD_" + kw_id
		var desc_key: String = name_key + "_DESC"
		t.ok(tr_json.has(name_key), "%s → tr.json'da var" % name_key)
		t.ok(en_json.has(name_key), "%s → en.json'da var" % name_key)
		t.ok(tr_json.has(desc_key), "%s → tr.json'da var" % desc_key)
		t.ok(en_json.has(desc_key), "%s → en.json'da var" % desc_key)
		t.ok(String(tr_json.get(name_key, "")).length() > 0, "%s TR metni boş değil" % name_key)
		t.ok(String(en_json.get(name_key, "")).length() > 0, "%s EN metni boş değil" % name_key)
		t.ok(String(tr_json.get(desc_key, "")).length() > 0, "%s TR metni boş değil" % desc_key)
		t.ok(String(en_json.get(desc_key, "")).length() > 0, "%s EN metni boş değil" % desc_key)

	# Overlay betiği yüklenebiliyor ve glossary listesi tam mı (sahne tree'ye ihtiyaç duymadan).
	var overlay_script: GDScript = load("res://scenes/ui/overlays/keywords/keywords_overlay.gd")
	t.ok(overlay_script != null, "keywords_overlay.gd yüklenebiliyor")
	var script_keyword_ids: Array = overlay_script.KEYWORD_IDS
	t.eq(script_keyword_ids.size(), KEYWORD_IDS.size(),
		"keywords_overlay.gd::KEYWORD_IDS bu testle aynı kapsamda")
	for kw_id in KEYWORD_IDS:
		t.ok(script_keyword_ids.has(kw_id), "%s → keywords_overlay.gd listesinde var" % kw_id)

	# Chronicles → Keywords wiring: overlay_manager.gd rotayı ve düğüm haritasını taşıyor mu.
	var manager_src := FileAccess.get_file_as_string("res://scenes/ui/overlays/overlay_manager.gd")
	t.ok(manager_src.contains("\"keywords\": \"chronicles\""),
		"NAVIGATION_MAP: keywords → chronicles kaydı var")
	t.ok(manager_src.contains("%KeywordsOverlay"),
		"overlays sözlüğünde %%KeywordsOverlay kaydı var")

	var hud_gd_src := FileAccess.get_file_as_string("res://scenes/ui/hud/game_hud.gd")
	t.ok(hud_gd_src.contains("chronicles_overlay.keywords_pressed"),
		"game_hud.gd → keywords_pressed sinyali bağlanmış")

	var hud_tscn_src := FileAccess.get_file_as_string("res://scenes/ui/hud/game_hud.tscn")
	t.ok(hud_tscn_src.contains("name=\"KeywordsOverlay\""),
		"game_hud.tscn → KeywordsOverlay düğümü kayıtlı")
