extends RefCounted

## ZOMBİ VARLIK BEKÇİSİ — her silah varlığının bir TÜKETİCİSİ olmalı.
##
## Bir silah `.tres`'i hiçbir birimin sabit silahı, hiçbir LoadoutOption'ı, hiçbir Armoury
## kaleminin verdiği saldırı ve motorun doğrudan kullandığı özel bir saldırı değilse, oyunda
## ASLA görünmez: bakımı yapılan ama ölü bir veridir. (Kullanıcı isteği: "ölü zombi kod da olmasın".)
##
## ARMOURY: Battlekit satın alma ekranı (P3-4) üçüncü bir ulaşılabilirlik yoludur — oyuncu bir
## silahı hiçbir birimin başlangıç yüklemesinde olmasa bile satın alabilir.

## Motor tarafından KODDAN kullanılan saldırılar — bir birime bağlı değiller, bu bilinçli.
const ENGINE_USED := [
	"trample_attack",            # MechanicsResolver — Trample aksiyonu
	"vengeful_scripture_attack", # AbilityExecutor — Scripture Guardian
	"martyrdom_device",          # MechanicsResolver — Ecclesiastic Prisoner
	"burning_inferno_attack",    # AbilityExecutor — Court Goetic Spell
	"mine_detonation",           # MineActions — mayın patlaması
	"unarmed",                   # LoadoutResolver.with_unarmed — yakın dövüş silahı olmayan model
	"devoured_bare_hands",       # unit.gd — Sin Eater'ın içinden saldırı
	"crushing_blows",            # Lord of Tumours — silahsız Cleave 2
	"iron_clawed_hands_attack",  # Goetic Warlock — silahsız Cleave 2
	"iron_fists",                # Communicant ATH — silahsız Cleave 2
	"feeble_flailing",           # Ecclesiastic Prisoner / Thrall — silahsız saldırı
	"teeth_and_claws",           # Lion of Jabir / Hound — silahsız saldırı
	"teeth_and_claws_infested",  # Hound (Infested Carcasses yükseltmesi)
	"poison_stingers",           # Pit Locust — silahsız Cleave 2
	"infected_proboscis",        # Herald of Beelzebub — silahsız enfeksiyon saldırısı
]

func run(t) -> void:
	# Birimlerin (sabit + loadout) kullandığı tüm silahları topla
	var used := {}
	var udir := DirAccess.open("res://assets/data/units")
	t.ok(udir != null, "units klasörü açıldı")
	if udir == null:
		return
	udir.list_dir_begin()
	var fn := udir.get_next()
	while fn != "":
		if fn.ends_with(".tres"):
			var ud: Resource = load("res://assets/data/units/" + fn)
			if ud != null:
				for a in ud.attacks:
					if a != null:
						used[String(a.resource_path).get_file().get_basename()] = true
				for opt in ud.loadout_options:
					if opt == null:
						continue
					for a2 in opt.attacks_override:
						if a2 != null:
							used[String(a2.resource_path).get_file().get_basename()] = true
		fn = udir.get_next()
	udir.list_dir_end()

	# Armoury kalemlerinin verdiği silahlar da ulaşılabilirdir (satın alınabilir)
	var armoury_weapons := 0
	var mdir := DirAccess.open("res://assets/data/armoury")
	t.ok(mdir != null, "armoury klasörü açıldı")
	if mdir != null:
		mdir.list_dir_begin()
		var mf := mdir.get_next()
		while mf != "":
			if mf.ends_with(".tres"):
				var item: Resource = load("res://assets/data/armoury/" + mf)
				if item != null:
					for a3 in item.granted_attacks:
						if a3 != null:
							used[String(a3.resource_path).get_file().get_basename()] = true
							armoury_weapons += 1
			mf = mdir.get_next()
		mdir.list_dir_end()
	t.ok(armoury_weapons > 0, "Armoury tabloları silah kalemleri içeriyor (%d bağ)" % armoury_weapons)

	var orphans: Array[String] = []
	var adir := DirAccess.open("res://assets/data/attacks")
	adir.list_dir_begin()
	var af := adir.get_next()
	while af != "":
		if af.ends_with(".tres"):
			var base := af.get_basename()
			if not used.has(base) and not ENGINE_USED.has(base):
				orphans.append(base)
		af = adir.get_next()
	adir.list_dir_end()
	orphans.sort()
	t.eq(orphans.size(), 0,
		"Ulaşılamayan (zombi) silah varlığı yok — %d yetim: %s" % [orphans.size(), str(orphans.slice(0, 12))])

	# ENGINE_USED listesindeki her varlık gerçekten var olmalı (liste bayatlamasın)
	for name in ENGINE_USED:
		t.ok(ResourceLoader.exists("res://assets/data/attacks/%s.tres" % name),
			"Motor-kullanımlı varlık mevcut: %s" % name)
