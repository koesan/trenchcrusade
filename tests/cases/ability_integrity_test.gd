extends RefCounted

## FAZ A-5: YETENEK VERİ BÜTÜNLÜĞÜ KİLİDİ.
## "Doğru unitler doğru yetenekler; yanlış/ölü yetenek almasınlar."
##
## Her unit .tres'inin abilities[] girdisi için:
##   1. yüklenir + ability_id ve display_name boş değil.
##   2. AKTİF (butonlu) yetenekse — action_key temel-eylem değil VE target_type aktif tür
##      (self/friendly/enemy/position) — İŞLEVSEL olmalı: generic effect_type YA DA
##      AbilityRegistry.implemented_ids(). Aksi halde oyuncu tıklar, hiçbir şey olmaz (ölü buton).
##   Pasifler (action_key boş) muaftır — onlar KeywordSystem/aura ile bağlanır.
##
## Ayrıca: orphan yetenek dosyaları (hiçbir unit kullanmıyor) yalnız bilinen allow-list'te olabilir.

const AbilityExecutor = preload("res://scripts/rules/ability_executor.gd")
const UNIT_DIR := "res://assets/data/units/"
const ABILITY_DIR := "res://assets/data/abilities/"

## AbilityExecutor._apply_effect()'in match dallarıyla AYNI olmalı — buradaki her effect_type
## "butonu basınca gerçekten bir şey olur" garantisi taşır.
const GENERIC := ["blessing", "remove_blood", "stand_up", "treat_choice", "move_allies",
	"force_activation", "force_move", "teleport", "buff_dice", "add_blood", "add_infection", "set_flag"]
const ACTIVE_TARGETS := ["self", "friendly", "enemy", "position"]

## Bilinen, kabul edilen orphan'lar (bir unit'e bağlı değil ama geçerli veri).
## arise_and_be_healed/death_wail/ravenous_infection: kullanıcı isteğiyle kendi 3D modeli olmayan
## varyant birimler (Lector/Barbed Wire Banshee/Ravenous ailesi) silindi (2026-07-15), ama bu
## yetenek altyapısı BİLİNÇLİ KORUNDU — ileride aynı isimli/benzer birimler gerçek modelle
## eklenince kod değişikliği gerekmeden yeniden kullanılabilir.
const ALLOWED_ORPHANS := ["alchemical_brew", "arise_and_be_healed", "death_wail", "ravenous_infection"]

## Bilinçli ERTELENMİŞ aktif yetenekler — eksik ALT SİSTEM gerektirir:
##   - set_mine/defuse_mine: Mined terrain-piece sistemi (harita/terrain işi — bilinçli olarak
##     şimdilik ES GEÇİLDİ, kullanıcı isteğiyle).
## devour_the_guilty (Sin Eater) artık TAM UYGULANDI (2026-07-16): "sahada değil ama hayatta"
## birim durumu (devoured_by/devoured_unit, unit.gd) inşa edildi — Fight-from-within, her
## aktivasyonda +1 Kan İşareti/6'da OOA, Sin Eater OOA'da serbest bırakma, Purge Action hepsi
## çalışıyor. Left-Hand Path (Court Hunter) de terrain-piece contact sistemine bağımlı ve
## uygulanmadı (harita işi, ES GEÇİLDİ), ama action_key="" (reaktif/pasif) olduğu için
## is_active_intent'e hiç girmiyor, bu listede OLMASINA gerek yok. Şu an is_actionable_ability
## bunları GİZLER (buton çıkmaz → ölü buton yok), ama unit verisinde bulunurlar. Bu liste
## boşluğu AÇIK ve KİLİTLİ tutar: yeni bir implement edilmemiş
## aktif yetenek eklenirse (bu listede değilse) test PATLAR. İlgili plan.md FAZ D / alt-sistem
## mini-projeleri.
const KNOWN_DEFERRED := ["set_mine", "defuse_mine"]

func _list(dir_path: String, suffix: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir_path)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(suffix):
			out.append(f)
	return out

func run(t) -> void:
	var referenced := {}   # ability_id-file-basename -> true
	var unit_files := _list(UNIT_DIR, ".tres")
	t.ok(unit_files.size() >= 40, "yeterli unit dosyası bulundu (%d)" % unit_files.size())

	for uf in unit_files:
		var ud = load(UNIT_DIR + uf)
		if ud == null or not ("abilities" in ud):
			continue
		# Birimin yetenekleri iki yerden gelebilir:
		#   1) abilities[]                     → doğuştan sahip olduğu yetenekler
		#   2) loadout_options[].extra_abilities → SATIN ALINAN yetenekler (compendium'da ücretli
		#      ve sayısı sınırlı olanlar: Martyrdom Device 35 /LIMIT 4, Court'un Goetic Power'ları
		#      Slavemaster 10 / Burning Inferno 15 ). Bunlar birime GÖMÜLÜ olmamalıdır.
		var all_abilities: Array = []
		for ab0 in ud.abilities:
			all_abilities.append(ab0)
		for opt in ud.loadout_options:
			if opt == null or not ("extra_abilities" in opt):
				continue
			for ab1 in opt.extra_abilities:
				if ab1 != null and not all_abilities.has(ab1):
					all_abilities.append(ab1)
		for ab in all_abilities:
			t.ok(ab != null, "%s: null yetenek girdisi yok" % uf)
			if ab == null:
				continue
			referenced[ab.resource_path.get_file()] = true
			t.ok(ab.ability_id != &"", "%s: '%s' ability_id boş değil" % [uf, ab.resource_path.get_file()])
			t.ok(ab.display_name != "", "%s: '%s' display_name boş değil" % [uf, String(ab.ability_id)])

			# Aktif (butonlu) yetenek mi?
			var is_active_intent: bool = ab.action_key != "" \
				and not (ab.action_key in AbilityExecutor._BASE_ACTIONS) \
				and (ab.target_type in ACTIVE_TARGETS)
			if is_active_intent:
				var functional: bool = ab.effect_type in GENERIC \
					or AbilityRegistry.is_implemented(ab.ability_id)
				var deferred: bool = String(ab.ability_id) in KNOWN_DEFERRED
				t.ok(functional or deferred, "AKTİF yetenek işlevsel VEYA bilinçli-ertelenmiş: %s [%s] (unit %s)" \
					% [String(ab.ability_id), ab.effect_type, uf])

	# Orphan denetimi
	for af in _list(ABILITY_DIR, ".tres"):
		if referenced.has(af):
			continue
		var stem: String = String(af).get_basename()
		t.ok(stem in ALLOWED_ORPHANS, "orphan yetenek yalnız allow-list'te olabilir: " + String(af))
