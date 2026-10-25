## DeployAvailability — "Bu birimi şu an yerleştirebilir miyim?" sorusunun TEK kaynağı.
##
## SORUN (kullanıcı bildirimi): yerleştirme paneli TÜM roster'ı gösteriyordu; kural motoru ise
## Availability, `[Elite]` tavanı, Order of the Fly, bütçe ve para birimine göre reddediyordu.
## Oyuncu bir birime tıklayana kadar NEDEN alamadığını göremiyordu ("bu faksiyona ait değil",
## "sınırlı ekleyemezsin" gibi kafa karıştırıcı hatalar).
##
## ÇÖZÜM: karar tek bir SAF fonksiyonda toplanır. Hem deploy doğrulaması (`game.gd`) hem
## yerleştirme kartı (`deploy_unit_card.gd`) AYNI fonksiyonu kullanır — görsel ile kural
## çelişemez ve sebep oyuncuya ÖNCEDEN gösterilir.
##
## Döndürür: "" = alınabilir; dolu string = ret sebebinin lokalizasyon anahtarı.
class_name DeployAvailability

## Sayımları çağıran taraf toplar (GameState'e bağımlılık yaratmamak için), karar burada verilir.
## counts: {
##   "same_type": int,   # bu birim tipinden sahada kaç tane var
##   "elite": int,       # sahadaki [Elite] sayısı
##   "lord": int, "knight": int,        # Order of the Fly sayımı
##   "demonic": int, "court_wretched": int,  # Court Wretched oranı
##   "leader_choice": StringName,
## }
const ARTILLERY_BATTERY_COST := 1000

static func check(unit_data: Resource, faction: Resource, ducat_pool: int, glory_pool: int,
		counts: Dictionary) -> String:
	if unit_data == null:
		return "DEPLOY_FAIL_NO_FACTION"
	if faction == null:
		return "DEPLOY_FAIL_NO_FACTION"

	# 1) Roster üyeliği — compendium'da bir faksiyonun listesi başka faksiyonun mercenary'sini
	#    meşru şekilde içerebilir, bu yüzden faction_id eşitliği DEĞİL üyelik denetlenir.
	if not (unit_data in faction.available_units):
		return "DEPLOY_FAIL_WRONG_FACTION"

	# 2) ALIGNMENT — "Unless stated otherwise, a Warband cannot include models of the opposing
	#    alignment." Mercenary'ler kendi alignment'larını taşır; nötr (UNSET) olanlar her
	#    warband'a girebilir.
	if not AlignmentRules.compatible(faction, unit_data):
		return "DEPLOY_FAIL_ALIGNMENT"

	# 3) Availability — "Availability: 0-2" gibi tavanlar
	var max_v: int = int(unit_data.availability_max)
	# ARTILLERY WITCH BATTERY (Heretic Legion): "0-2 Artillery Witches ... if the total cost of all of
	# the other models in the Warband adds up to 1,000 or more." (normalde 0-1)
	if unit_data.unit_name == "Artillery Witch" and int(counts.get("other_cost", 0)) >= ARTILLERY_BATTERY_COST:
		max_v = maxi(max_v, 2)
	if int(counts.get("same_type", 0)) >= max_v:
		return "DEPLOY_FAIL_AVAILABILITY"

	# 4) [Elite] tavanı (6) — TÜM faksiyonlar için geçerli global kural
	if KeywordSystem.has(unit_data, &"elite") \
			and not RosterRules.elite_cap_ok(int(counts.get("elite", 0)) + 1):
		return "DEPLOY_FAIL_ELITE_CAP"

	# 5) THE ORDER OF THE FLY (Cult of the Black Grail)
	if unit_data.faction_id == &"cult_of_the_black_grail":
		var lord: int = int(counts.get("lord", 0))
		var knight: int = int(counts.get("knight", 0))
		if unit_data.unit_name == "Lord of Tumours":
			lord += 1
		elif unit_data.unit_name == "Plague Knight":
			knight += 1
		if (unit_data.unit_name == "Lord of Tumours" or unit_data.unit_name == "Plague Knight") \
				and not RosterRules.order_of_the_fly_allowed(
					counts.get("leader_choice", &""), lord, knight):
			return "DEPLOY_FAIL_ORDER_OF_FLY"

	# 6) Court Wretched — "Must be outnumbered by models with the Keyword DEMONIC"
	if KeywordSystem.has(unit_data, &"outnumbered_by_demonic_required"):
		if not MechanicsResolver.court_wretched_deploy_allowed(
				int(counts.get("demonic", 0)), int(counts.get("court_wretched", 0)) + 1):
			return "DEPLOY_FAIL_RATIO"

	# 7) Bütçe — Glory ve ducat AYRI havuzlardır (EconomyRules)
	if not EconomyRules.can_afford(unit_data, ducat_pool, glory_pool):
		return "DEPLOY_FAIL_GLORY" if EconomyRules.is_glory(unit_data) else "DEPLOY_FAIL_BUDGET"

	return ""

## Bir oyuncunun sahadaki birimlerini `check()`'in beklediği biçimde sayar.
## GameState bir autoload olduğu için bu sayım da burada durabilir — `game.gd`'yi şişirmez.
static func collect_counts(player_id: int, unit_data: Resource) -> Dictionary:
	var faction = GameState.get_faction_for_player(player_id)
	var c := {
		"same_type": 0, "elite": 0, "lord": 0, "knight": 0,
		"demonic": 0, "court_wretched": 0, "other_cost": 0,
		"leader_choice": (faction.leader_choice if (faction != null and "leader_choice" in faction) else &""),
	}
	# ROSTER sayımı — Savaş Dışı modeller de warband'e dâhildir (bkz. UnitQuery.roster_of).
	for u in UnitQuery.roster_of(player_id):
		if u.unit_data == null:
			continue
		if unit_data != null and u.unit_data.unit_name == unit_data.unit_name:
			c["same_type"] += 1
		else:
			c["other_cost"] += int(u.unit_data.cost)
		if KeywordSystem.has(u.unit_data, &"elite"):
			c["elite"] += 1
		if KeywordSystem.has(u.unit_data, &"demonic"):
			c["demonic"] += 1
		if KeywordSystem.has(u.unit_data, &"outnumbered_by_demonic_required"):
			c["court_wretched"] += 1
		match u.unit_data.unit_name:
			"Lord of Tumours": c["lord"] += 1
			"Plague Knight": c["knight"] += 1
	return c

## Kısa yol: bir oyuncu için doğrudan ret sebebi. TEK KAYNAK — deploy doğrulaması ve
## yerleştirme kartı ikisi de bunu çağırır, böylece görsel kuralla asla çelişmez.
static func block_reason(player_id: int, unit_data: Resource) -> String:
	return check(unit_data,
		GameState.get_faction_for_player(player_id),
		GameState.player_deploy_pool.get(player_id, 0),
		GameState.player_glory_pool.get(player_id, 0),
		collect_counts(player_id, unit_data))
