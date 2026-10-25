extends RefCounted

## HAZIR TEÇHİZAT FİYATLANDIRMASI (compendium denetimi, Adım 2).
##
## Compendium'da çoğu birim "can have any Battlekit from the Armoury Tables" der: profil Cost'u
## ÇIPLAK modelin fiyatıdır, silahlar cephanelikten AYRICA alınır. Oyun bu birimleri hazır bir
## silah takımıyla sunar; takımın faction cephaneliğindeki fiyatı `kit_cost` olarak maliyete
## eklenir. Önceden bu silahlar BEDAVAYDI (örn. 3 MHI = 3 bedava Machine Gun, Amalgam'a ~84
## ducat'lık bedava silah).
##
## Bu test her NATİF birimin (mercenary'ler "always has" kitleriyle gelir, fiyata dâhildir):
##   1) `kit_cost`unun taban silahlarının cephanelik fiyat toplamına eşit olduğunu,
##   2) silah değiştiren her loadout'un `cost_delta`sının fiyat farkına (+ varsa yükseltme) eşit
##      olduğunu,
##   3) her hazır silahın o faction'ın cephaneliğinde gerçekten bulunduğunu (uydurma silah yok)
## doğrular.

## "Always has" — compendium'un birime dâhil ettiği (ayrıca ödenmeyen) silahlar.
const FREE := {
	"war_wolf_assault_beast": ["chainsaw_mouth", "shredding_claws"],
	"shrine_anchorite": ["catherine_wheel", "bonebreaker_mace"],
	"artillery_witch": ["infernal_bomb"],
	"sultanate_sapper": ["sapper_shovel"],
	"new_antioch_combat_engineer": ["sapper_shovel"],
	"new_antioch_combat_medic": ["misericordia"],
	"court_hunter_of_the_left_hand_path": ["bow_of_lethe"],
}

## Compendium'un indirimli fiyatı: "A Yeoman may be recruited with a Bolt-Action Rifle for a
## reduced cost of 5."
const PRICE_OVERRIDE := {
	"new_antioch_yeoman": {"bolt_action_rifle": 5},
}

## Silah değiştiren loadout'lardaki silah DIŞI compendium yükseltme bedeli (örn. Hound'un
## "Infested Carcasses - 5" yükseltmesi Teeth and Claws'ı enfekte profille değiştirir).
const UPGRADE := {
	"HOUND_LOADOUT_INFESTED": 5,
	# Plague Knight "must have a suit of Armour" — Belcher seçeneği Standard Armour (15) ile gelir.
	"PLAGUE_KNIGHT_LOADOUT_BELCHER": 15,
}

const FACTIONS := ["new_antioch", "heretic_legion", "trench_pilgrims", "iron_sultanate",
	"cult_of_the_black_grail", "court_of_seven_headed_serpent"]

func _price(faction: Resource, file: String, attacks: Array, errors: Array) -> int:
	var total := 0
	for a in attacks:
		if a == null:
			continue
		var atk_id: String = a.resource_path.get_file().get_basename()
		if KeywordSystem.has(a, &"innate"):
			continue
		if a.attack_type == "MELEE" and KeywordSystem.has(a, &"pistol"):
			continue  # tabancanın yakın dövüş profili — aynı kalem, ranged tarafında ödendi
		if atk_id in FREE.get(file, []):
			continue
		if PRICE_OVERRIDE.get(file, {}).has(atk_id):
			total += int(PRICE_OVERRIDE[file][atk_id])
			continue
		var found := false
		for it in faction.armoury:
			if it == null or it.cost_currency != ArmouryItem.Currency.DUCAT:
				continue
			for g in it.granted_attacks:
				if g != null and g.resource_path == a.resource_path:
					total += it.cost
					found = true
					break
			if found:
				break
		if not found:
			errors.append("%s: '%s' %s cephaneliğinde ducat fiyatıyla yok" % [file, atk_id, faction.faction_id])
	return total

func run(t) -> void:
	var errors: Array = []
	var checked := 0
	for fid in FACTIONS:
		var f: Resource = load("res://assets/data/factions/%s.tres" % fid)
		for ud in f.available_units:
			if ud == null or ud.cost_currency != UnitData.Currency.DUCAT:
				continue  # mercenary — kendi kiti fiyata dâhil
			var file: String = ud.resource_path.get_file().get_basename()
			var base_price: int = _price(f, file, ud.attacks, errors)
			if ud.kit_cost != base_price:
				errors.append("%s: kit_cost %d, cephanelik toplamı %d" % [file, ud.kit_cost, base_price])
			for opt in ud.loadout_options:
				if opt == null or opt.attacks_override.is_empty():
					continue
				var diff: int = _price(f, file, opt.attacks_override, errors) - base_price \
					+ int(UPGRADE.get(opt.option_name_key, 0))
				if opt.cost_delta != diff:
					errors.append("%s[%s]: cost_delta %d, fiyat farkı %d" % [file, opt.option_name_key, opt.cost_delta, diff])
			checked += 1
	t.ok(checked >= 40, "Natif birimlerin hepsi denetlendi (%d)" % checked)
	t.eq(errors.size(), 0, "Hazır teçhizat compendium cephanelik fiyatıyla birebir — sapmalar: %s" % [errors])

	# Örnek: MHI artık Machine Gun + Sword/Axe'ın bedelini öder (85 + 50 + 4).
	var mhi: Resource = load("res://assets/data/units/new_antioch_mechanized_heavy_infantry.tres")
	t.eq(mhi.cost, 139, "MHI hazır kitiyle 139 ducat (85 profil + 54 teçhizat)")
	t.eq(mhi.cost - mhi.kit_cost, 85, "MHI profil maliyeti compendium'la aynı (85)")
