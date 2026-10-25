## AlignmentRules — Faithful / Fallen hizalaması (STATELESS, saf).
##
## KURAL KAYNAĞI (warbands/starting-a-warband/choosing-a-faction.md):
##   "All Warbands in this book are either FAITHFUL or FALLEN. Faithful Warbands are
##    Heavenly-aligned and fight for the holy cause. Fallen Warbands are Hell-aligned and fight
##    for the unholy cause. The Mercenaries that can be hired for a Warband will also have
##    either Faithful or Fallen alignment. UNLESS STATED OTHERWISE, A WARBAND CANNOT INCLUDE
##    MODELS OF THE OPPOSING ALIGNMENT."
##
## Faithful : New Antioch, Trench Pilgrims, Iron Sultanate
## Fallen   : Heretic Legion, Cult of the Black Grail, Court of the Seven-Headed Serpent
##
## Bazı mercenary'ler her iki tarafa da hizmet eder (örn. Scripture Guardian — compendium onu
## HEM Sadık HEM Sapkın listelerinde sayar ve "holy (or desecrated) scroll" der). Bunlar
## `UNSET` bırakılır ve her warband'a girebilir.
class_name AlignmentRules

enum Alignment { UNSET, FAITHFUL, FALLEN }

## Faksiyon kimliği → hizalama. Roster verisi bozuk/eksikse buradan çözülür (tek kaynak).
const FACTION_ALIGNMENT := {
	&"new_antioch": Alignment.FAITHFUL,
	&"trench_pilgrims": Alignment.FAITHFUL,
	&"iron_sultanate": Alignment.FAITHFUL,
	&"heretic_legion": Alignment.FALLEN,
	&"cult_of_the_black_grail": Alignment.FALLEN,
	&"court_of_seven_headed_serpent": Alignment.FALLEN,
}

## Bir faksiyonun hizalaması.
static func of_faction(faction: Resource) -> Alignment:
	if faction == null:
		return Alignment.UNSET
	if "alignment" in faction and int(faction.alignment) != Alignment.UNSET:
		return int(faction.alignment) as Alignment
	return FACTION_ALIGNMENT.get(faction.faction_id, Alignment.UNSET)

## Bir birimin hizalaması. UNSET = her iki tarafa da hizmet eder (nötr mercenary).
static func of_unit(unit_data: Resource) -> Alignment:
	if unit_data == null:
		return Alignment.UNSET
	if "alignment" in unit_data:
		return int(unit_data.alignment) as Alignment
	return Alignment.UNSET

## Bu birim bu warband'a girebilir mi?
## Nötr (UNSET) birimler her warband'a girer; aksi hâlde hizalamalar eşleşmelidir.
static func compatible(faction: Resource, unit_data: Resource) -> bool:
	var u := of_unit(unit_data)
	if u == Alignment.UNSET:
		return true
	var f := of_faction(faction)
	if f == Alignment.UNSET:
		return true
	return u == f

## UI etiketi (lokalizasyon anahtarı) — metin ASLA koda gömülmez.
static func label_key(a: Alignment) -> String:
	match a:
		Alignment.FAITHFUL: return "ALIGNMENT_FAITHFUL"
		Alignment.FALLEN: return "ALIGNMENT_FALLEN"
		_: return "ALIGNMENT_NEUTRAL"
