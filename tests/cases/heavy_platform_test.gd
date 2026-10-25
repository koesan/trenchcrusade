extends RefCounted

## `[Strong]` + `[Negate Heavy]` keyword çiftinin TEK işlevi ağır silah taşımaktır:
##   STRONG      → "can use a 2-Handed Melee Weapon in one hand" + Negate Heavy
##   NEGATE HEAVY→ "[Heavy] silahın hareket cezasını yok sayar"
## Bu keyword'leri taşıyan bir birimin elinde `[Heavy]` silah yoksa ikisi de ÖLÜ keyword olur
## (denetim bulgusu S-2 — beş faksiyonu birden vuran tekrarlayan hata).
##
## Ayrıca `annihilator` (Six-Armed Monstrosity / Desecrated Saint) "her silahla ayrı saldırı"
## demektir; bunu taşıyan birime tek silah vermek yeteneği tamamen atıl bırakır.

## Ağır silah platformu birimleri → beklenen minimum ağır silah sayısı
const HEAVY_PLATFORMS := [
	"new_antioch_mechanized_heavy_infantry",
	"anointed_heavy_infantry",
	"brazen_bull",
	"amalgams",
	"court_desecrated_saint",
]

## `annihilator` taşıyan birimler → en az kaç FARKLI silah taşımalı
const ANNIHILATOR_MIN_DISTINCT := {
	"amalgams": 4,               # compendium: "up to six Ranged or Melee Weapons"
	"court_desecrated_saint": 3, # compendium: "up to three 1-Handed Melee Weapons"
}

## Bir faksiyonun birimi BAŞKA faksiyonun imza silahını taşımamalı (denetim bulgusu S-3).
const FORBIDDEN_PREFIX := {
	"anointed_heavy_infantry": ["templar_"],       # Templar = New Antioch terminolojisi
	"court_desecrated_saint": ["plague_sword"],    # plague_sword = Cult of the Black Grail
	"amalgams": ["legionary_"],                    # legionary_ = Heretic Legion
}

func _all_weapons(ud: Resource) -> Array:
	var out: Array = []
	for a in ud.attacks:
		if a != null and not out.has(a):
			out.append(a)
	for opt in ud.loadout_options:
		if opt == null:
			continue
		for a in opt.attacks_override:
			if a != null and not out.has(a):
				out.append(a)
	return out

func run(t) -> void:
	for name in HEAVY_PLATFORMS:
		var ud: Resource = load("res://assets/data/units/%s.tres" % name)
		t.ok(ud != null, "%s yüklendi" % name)
		if ud == null:
			continue

		# Keyword çifti gerçekten var mı? (veri doğruluğu — denetimde zaten doğruydu)
		t.ok(KeywordSystem.has(ud, &"strong"), "%s → [Strong]" % name)
		t.ok(KeywordSystem.has(ud, &"negate_heavy"), "%s → [Negate Heavy]" % name)

		# Asıl kontrol: taşıyabileceği bir [Heavy] silah var mı?
		var weapons := _all_weapons(ud)
		var heavy_names: Array[String] = []
		for w in weapons:
			if KeywordSystem.has(w, &"heavy"):
				heavy_names.append(String(w.resource_path).get_file())
		t.ok(heavy_names.size() >= 1,
			"%s → en az 1 [Heavy] silaha erişimi var (bulunan: %s)" % [name, str(heavy_names)])

	for name in ANNIHILATOR_MIN_DISTINCT.keys():
		var ud: Resource = load("res://assets/data/units/%s.tres" % name)
		if ud == null:
			continue
		t.ok(KeywordSystem.has(ud, &"annihilator"), "%s → annihilator taşıyor" % name)
		# FARKLI silah sayısı — aynı silahın kopyaları saymaz (compendium "a vast combination
		# of DIFFERENT Ranged and Melee Weapons" der).
		var distinct: Array[String] = []
		for a in ud.attacks:
			if a != null:
				var p := String(a.resource_path)
				if not distinct.has(p):
					distinct.append(p)
		var need: int = ANNIHILATOR_MIN_DISTINCT[name]
		t.ok(distinct.size() >= need,
			"%s → en az %d FARKLI silah (mevcut: %d)" % [name, need, distinct.size()])

	for name in FORBIDDEN_PREFIX.keys():
		var ud: Resource = load("res://assets/data/units/%s.tres" % name)
		if ud == null:
			continue
		for a in _all_weapons(ud):
			var p := String(a.resource_path)
			for bad in FORBIDDEN_PREFIX[name]:
				t.ok(not p.contains(bad),
					"%s → '%s' silahını taşımıyor (%s)" % [name, bad, p.get_file()])

	# Mechanized Heavy Infantry ve Anointed Heavy Infantry Ranged +1D'dir; ağır silahları
	# MENZİLLİ olmalı (compendium: "wield the heavy weaponry of the company").
	for name in ["new_antioch_mechanized_heavy_infantry", "anointed_heavy_infantry"]:
		var ud: Resource = load("res://assets/data/units/%s.tres" % name)
		if ud == null:
			continue
		t.eq(ud.ranged_dice_modifier, 1, "%s → Ranged +1D (compendium)" % name)
		var has_heavy_ranged := false
		for w in _all_weapons(ud):
			if w.attack_type == "RANGED" and KeywordSystem.has(w, &"heavy"):
				has_heavy_ranged = true
		t.ok(has_heavy_ranged, "%s → MENZİLLİ [Heavy] silah taşıyor" % name)
