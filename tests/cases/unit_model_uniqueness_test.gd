extends RefCounted

## VERİ BÜTÜNLÜĞÜ KİLİDİ: bir faction'ın DEPLOY EDİLEBİLİR (model_scene_path dolu) rosterinde
## iki FARKLI İSİMLİ unit AYNI 3D modeli PAYLAŞMAMALI — aksi halde deploy ekranında görsel olarak
## birbirinden ayırt edilemeyen "kopya" birimler oluşur (kullanıcı bildirimi, 2026-07-15).
##
## Kendi 3D modeli olmayan varyant birimler (compendium'da gerçek/ayrı stat bloğu olsa da,
## henüz kendi asset'i yoksa) model_scene_path="" ile veri/arka planda kalır — deploy_panel.gd
## bunları otomatik gizler (kod değişikliği gerekmeden, model eklenince görünür olurlar).
##
## NOT: AYNI isimli bir unit'in (ör. Scripture Guardian, Combat Biologist) mercenary olarak
## BİRDEN ÇOK faction'ın rosterinde listelenmesi NORMALDİR ve burada denetlenmez — sorun yalnız
## bir faction rosterinde FARKLI isimli iki unit'in aynı modeli taşımasıdır.

const FACTION_DIR := "res://assets/data/factions/"

func run(t) -> void:
	var dir := DirAccess.open(FACTION_DIR)
	t.ok(dir != null, "faksiyon klasörü açılır")
	if dir == null:
		return

	var checked_factions := 0
	for file in dir.get_files():
		if not file.ends_with(".tres"):
			continue
		var faction = load(FACTION_DIR + file)
		if faction == null or not (faction is FactionData):
			continue
		checked_factions += 1

		# Bu faction içinde: model_scene_path -> bu modeli taşıyan FARKLI unit_name'ler kümesi.
		var model_to_names: Dictionary = {}
		for ud in faction.available_units:
			if ud == null or ud.model_scene_path == "":
				continue
			if not model_to_names.has(ud.model_scene_path):
				model_to_names[ud.model_scene_path] = []
			if not model_to_names[ud.model_scene_path].has(ud.unit_name):
				model_to_names[ud.model_scene_path].append(ud.unit_name)

		for model_path in model_to_names:
			var names: Array = model_to_names[model_path]
			t.ok(names.size() <= 1,
				"%s/%s: birden fazla FARKLI isimli unit aynı modeli paylaşmıyor (%s)" \
				% [file, model_path.get_file(), str(names)])

	t.ok(checked_factions >= 6, "en az 6 faksiyon denetlendi (denetlenen: %d)" % checked_factions)
