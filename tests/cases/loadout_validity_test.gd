extends RefCounted

## KALICI BEKÇİ — her birimin TABAN silahları ve HER loadout seçeneği `validate_loadout`'tan
## geçmeli. Aksi hâlde oyuncu o birimi/seçeneği sahaya koyamaz ve "Geçersiz silah ve teçhizat
## yüklemesi" hatası alır (kullanıcı bildirimi).
##
## Bu test, Armoury genişledikçe eklenen her yeni loadout'u otomatik kapsar.

func run(t) -> void:
	var bad: Array[String] = []
	var checked := 0
	var dir := DirAccess.open("res://assets/data/units")
	t.ok(dir != null, "units klasörü açıldı")
	if dir == null:
		return
	dir.list_dir_begin()
	var fn := dir.get_next()
	while fn != "":
		if fn.ends_with(".tres"):
			var ud: Resource = load("res://assets/data/units/" + fn)
			if ud != null:
				checked += 1
				var base_err := LoadoutResolver.validate_loadout(ud)
				if base_err != "":
					bad.append("%s[taban] %s" % [fn.get_basename(), base_err])
				for i in range(ud.loadout_options.size()):
					var opt = ud.loadout_options[i]
					var resolved := LoadoutResolver.resolve_loadout(ud, i)
					var err := LoadoutResolver.validate_loadout(resolved)
					if err != "":
						bad.append("%s[%s] %s" % [fn.get_basename(),
							opt.option_name_key if opt != null else str(i), err])
		fn = dir.get_next()
	dir.list_dir_end()

	t.ok(checked >= 50, "Yeterli birim tarandı (%d)" % checked)
	bad.sort()
	t.eq(bad.size(), 0,
		"Tüm taban ve loadout kombinasyonları yerleştirilebilir — %d bozuk: %s" \
			% [bad.size(), str(bad.slice(0, 8))])

	# ── PISTOL EL SAYIMI ───────────────────────────────────────────────────
	# Compendium (battlekit/ranged.md): Pistol "Range 12" / Melee", "Hands: 1 Hands (Ranged)".
	# TEK bir kalemdir ve melee'de de kullanılabilir. Projede iki AttackData ile modelleniyor
	# (RANGED + MELEE eşi); el bütçesine YALNIZ BİR KEZ sayılmalıdır.
	var ud_lt: Resource = load("res://assets/data/units/new_antioch_lieutenant.tres")
	t.eq(LoadoutResolver.validate_loadout(ud_lt), "",
		"Lieutenant (Pistol çifti + Trench Knife) → geçerli; tabanca çift el saymaz")

	# Doğrudan kural: MELEE + [Pistol] el harcamaz
	var pistol_melee: Resource = load("res://assets/data/attacks/pistol_melee.tres")
	t.eq(pistol_melee.attack_type, "MELEE", "pistol_melee MELEE tipinde")
	t.ok(KeywordSystem.has(pistol_melee, &"pistol"), "pistol_melee → [Pistol] keyword'ü")
	t.eq(LoadoutResolver.melee_hand_cost(pistol_melee, false), 0,
		"[Pistol] melee saldırısı melee el bütçesi HARCAMAZ (ranged tarafında sayıldı)")
	var knife: Resource = load("res://assets/data/attacks/trench_knife.tres")
	t.eq(LoadoutResolver.melee_hand_cost(knife, false), 1, "Normal 1H melee → 1 el")
	var maul: Resource = load("res://assets/data/attacks/great_hammer_maul.tres")
	t.eq(LoadoutResolver.melee_hand_cost(maul, false), 2, "2H melee → 2 el")
	t.eq(LoadoutResolver.melee_hand_cost(maul, true), 1, "[Strong] → 2H melee tek elde")
