extends RefCounted

## Release-candidate QC turu (2026-07-18, 3. tur): tooltip denetiminde bulunan gerçek UX bug'ı —
## hud_tooltip_popup.gd, KEY_TOOLTIP_SUCCESS/FAILURE eksikse "Otomatik Başarı"/"Yok" gibi YANLIŞ
## bir varsayılana düşüyordu. 13 Riskli/zar gerektiren yetenek bu yüzden kendi açıklama metniyle
## ("Riskli...") ÇELİŞEN bir tooltip gösteriyordu. Bu test, o yeteneklerin artık gerçek SUCCESS/
## FAILURE metni taşıdığını kilitler (regresyon önleme).

## action_key'i AbilityData'dan gelen (yani hud_tooltip_popup.gd'nin "ACTION_"+action_key.upper()
## deseniyle ürettiği) TÜM Riskli veya zar-gerektiren yetenekler.
const RISKY_OR_ROLLED_ACTION_KEYS := [
	"defuse_mine", "hide", "fortify", "voice_of_god", "enforced_orthodoxy", "goetic_portal",
	"elemental_change", "divine_judgement", "ammunition_sacrament", "goetic_gaze", "set_mine",
	"purge", "ravenous_infection",
]

## Kendi AbilityData'sı olmayan (unit.gd'de hardcoded) ama zar gerektiren evrensel aksiyonlar.
const HARDCODED_ROLLED_ACTIONS := ["claim_reliquary", "fight_devourer"]

## Kullanıcı bildirimi (2026-07-18, 4. tur): "eylem butonlarının tooltip'i eski/açıklayıcı değil."
## requires_roll=false OLAN ama SUCCESS/FAILURE'ı hâlâ anlamlı olan (Goetic bedel ödemesi/otomatik
## tetiklenme gibi) 7 yetenek — önceden generic "Otomatik Başarı"/"Yok" fallback'ine düşüyorlardı,
## bu da özellikle bedel-ödemeli Goetic büyüleri için YANILTICI idi (aslında "başarısızlık" bedeli
## ödememe/hedef bulamama anlamına geliyor, zar başarısızlığı değil).
const NO_ROLL_BUT_DESCRIBED_ACTIONS := [
	"burning_inferno", "devour_the_guilty", "shadow_walker", "slavemaster",
	"trample", "trigger_martyrdom_device", "vengeful_scripture",
]

func run(t) -> void:
	for action_key in RISKY_OR_ROLLED_ACTION_KEYS:
		var ui_key: String = "ACTION_" + String(action_key).to_upper()
		t.ok(LocalizationManager.has_key(ui_key + "_TOOLTIP_SUCCESS"),
			"%s → gerçek TOOLTIP_SUCCESS var (Otomatik Başarı yanıltıcı varsayılanına düşmez)" % ui_key)
		t.ok(LocalizationManager.has_key(ui_key + "_TOOLTIP_FAILURE"),
			"%s → gerçek TOOLTIP_FAILURE var" % ui_key)
		# TR/EN aynı anahtarları taşımalı (LocalizationManager tek dosyadan okur ama ikisi de kilitlenir).
		var en_val = LocalizationManager.tr_t(ui_key + "_TOOLTIP_SUCCESS")
		t.ok(en_val != ui_key + "_TOOLTIP_SUCCESS", "%s SUCCESS metni boş/eksik değil" % ui_key)

	for action_key in HARDCODED_ROLLED_ACTIONS:
		var ui_key: String = "ACTION_" + String(action_key).to_upper()
		t.ok(LocalizationManager.has_key(ui_key + "_TOOLTIP_DESC"), "%s → TOOLTIP_DESC var" % ui_key)
		t.ok(LocalizationManager.has_key(ui_key + "_TOOLTIP_SUCCESS"), "%s → TOOLTIP_SUCCESS var" % ui_key)
		t.ok(LocalizationManager.has_key(ui_key + "_TOOLTIP_FAILURE"), "%s → TOOLTIP_FAILURE var" % ui_key)

	t.ok(LocalizationManager.has_key("ACTION_RAVENOUS_INFECTION_TOOLTIP_DESC"),
		"ACTION_RAVENOUS_INFECTION → TOOLTIP_DESC eksikti, eklendi")

	for action_key in NO_ROLL_BUT_DESCRIBED_ACTIONS:
		var ui_key: String = "ACTION_" + String(action_key).to_upper()
		t.ok(LocalizationManager.has_key(ui_key + "_TOOLTIP_SUCCESS"),
			"%s → gerçek TOOLTIP_SUCCESS var (generic 'Otomatik Başarı' fallback'ine düşmez)" % ui_key)
		t.ok(LocalizationManager.has_key(ui_key + "_TOOLTIP_FAILURE"),
			"%s → gerçek TOOLTIP_FAILURE var (generic 'Yok' fallback'ine düşmez)" % ui_key)

	# Sözlük eşitliği: her eklenen anahtar TR'de de mevcut olmalı (LocalizationManager doğrudan
	# tr.json/en.json'dan okuyor, ikisinin de dosya-seviyesinde var olduğunu ayrıca doğrula).
	var tr_file := FileAccess.get_file_as_string("res://assets/localization/tr.json")
	var en_file := FileAccess.get_file_as_string("res://assets/localization/en.json")
	var tr_json: Dictionary = JSON.parse_string(tr_file)
	var en_json: Dictionary = JSON.parse_string(en_file)
	for action_key in RISKY_OR_ROLLED_ACTION_KEYS + HARDCODED_ROLLED_ACTIONS + NO_ROLL_BUT_DESCRIBED_ACTIONS:
		var ui_key: String = "ACTION_" + String(action_key).to_upper()
		for suffix in ["_TOOLTIP_SUCCESS", "_TOOLTIP_FAILURE"]:
			var full_key: String = ui_key + suffix
			if tr_json.has(full_key) or en_json.has(full_key):
				t.ok(tr_json.has(full_key), "%s → tr.json'da var" % full_key)
				t.ok(en_json.has(full_key), "%s → en.json'da var" % full_key)
