extends RefCounted

## P0-4 regresyon kilidi: paylaşılan Armoury silahları (Polearm/Jezzail) fazladan bonus
## VERMEMELİ — Lightning Speed (Cleave 2) sadece Observer'a, Martial Prowess (Assault) sadece
## Mamluk Faris'e özgü olmalı; diğer birimler (Mamluk Faris'in Polearm+Shield seçeneği, Janissary,
## Azeb) vanilla silahı kullanmalı.

func run(t) -> void:
	var vanilla_polearm = load("res://assets/data/attacks/polearm.tres")
	t.eq(bool(vanilla_polearm.has_cleave), false, "Vanilla Polearm → Cleave YOK (sadece Observer'a özgü)")
	t.eq(int(vanilla_polearm.cleave_count), 1, "Vanilla Polearm → cleave_count=1")

	var lightning_polearm = load("res://assets/data/attacks/polearm_lightning_speed.tres")
	t.eq(bool(lightning_polearm.has_cleave), true, "Observer'ın Lightning Speed Polearm'ı → Cleave VAR")
	t.eq(int(lightning_polearm.cleave_count), 2, "Observer'ın Lightning Speed Polearm'ı → Cleave 2")

	var vanilla_jezzail = load("res://assets/data/attacks/jezzail.tres")
	t.eq(bool(vanilla_jezzail.is_assault), false, "Vanilla Jezzail → Assault YOK (Janissary/Azeb için)")

	var mamluk_jezzail = load("res://assets/data/attacks/mamluk_jezzail.tres")
	t.eq(bool(mamluk_jezzail.is_assault), true, "Mamluk Faris'in Martial Prowess Jezzail'i → Assault VAR")

	# Observer artık lightning_speed varyantını kullanıyor
	var observer = load("res://assets/data/units/observer.tres")
	var observer_has_cleave_polearm := false
	for a in observer.attacks:
		if a != null and a.attack_type == "MELEE" and a.has_cleave and a.cleave_count == 2:
			observer_has_cleave_polearm = true
	t.ok(observer_has_cleave_polearm, "Observer.tres → Cleave 2 Polearm kullanıyor")

	# Mamluk Faris'in varsayılan + loadout Jezzail'leri Assault taşımalı
	var mamluk = load("res://assets/data/units/mamluk_faris.tres")
	var mamluk_default_assault := false
	for a in mamluk.attacks:
		if a != null and a.attack_type == "RANGED" and a.is_assault:
			mamluk_default_assault = true
	t.ok(mamluk_default_assault, "Mamluk Faris varsayılan silahları → Jezzail Assault taşıyor")

	var loadout_names_with_assault: Array[String] = []
	for lo in mamluk.loadout_options:
		for a in lo.attacks_override:
			if a != null and a.attack_type == "RANGED" and a.is_assault:
				loadout_names_with_assault.append(lo.option_name_key)
	t.ok(loadout_names_with_assault.size() >= 2,
		"Mamluk Faris'in Jezzail içeren loadout seçenekleri (Polearm+Shield, Greatsword) → Assault taşıyor")

	# Mamluk Faris'in Polearm+Shield loadout'u Observer'ın Cleave 2'sini ALMAMALI
	var mamluk_polearm_has_cleave := false
	for lo in mamluk.loadout_options:
		if lo.option_name_key == "MAMLUK_LOADOUT_POLEARM_SHIELD":
			for a in lo.attacks_override:
				if a != null and a.has_cleave:
					mamluk_polearm_has_cleave = true
	t.eq(mamluk_polearm_has_cleave, false,
		"Mamluk Faris'in Polearm+Shield loadout'u → Cleave YOK (Lightning Speed Observer'a özgü)")

	# Janissary ve Azeb vanilla (Assault'suz) Jezzail kullanmalı
	var janissary = load("res://assets/data/units/janissary.tres")
	var janissary_has_assault_ranged := false
	for a in janissary.attacks:
		if a != null and a.attack_type == "RANGED" and a.is_assault:
			janissary_has_assault_ranged = true
	t.eq(janissary_has_assault_ranged, false, "Janissary → Jezzail'i Assault taşımıyor (yalnız Mamluk Faris'e özgü)")

	var azeb = load("res://assets/data/units/azebs.tres")
	var azeb_has_assault_ranged := false
	for a in azeb.attacks:
		if a != null and a.attack_type == "RANGED" and a.is_assault:
			azeb_has_assault_ranged = true
	t.eq(azeb_has_assault_ranged, false, "Azeb → Jezzail'i Assault taşımıyor (yalnız Mamluk Faris'e özgü)")
