## RosterRules — Warband İNŞA kuralları (STATELESS).
##
## Bu sınıf, bir warband'ın compendium'a göre GEÇERLİ kurulup kurulmadığına karar verir.
## Saldırı/yara mantığından bağımsızdır ve tamamen SAF fonksiyonlardan oluşur — sahne
## kurmadan test edilebilir (MechanicsResolver / EconomyRules ile aynı desen).
##
## Sayımları çağıran taraf (game.gd) yapar; karar burada verilir. Böylece game.gd bir
## "god file"a dönüşmez ve kurallar tek yerde denetlenebilir kalır.
class_name RosterRules

# ── GLOBAL: MAXIMUM ELITES ───────────────────────────────────────────────────
## Compendium (warbands/starting-a-warband/recruit-your-warband.md):
##   "A Warband can never include more than 6 models with the [Elite] Keyword. This limit
##    applies AT ALL TIMES, not just when the Warband is first recruited, and includes new
##    models or Mercenaries that are recruited during a Campaign, and any models that are
##    promoted to [Elite] status during a Campaign."
const ELITE_MAX := 6

## Bu kadar [Elite] model içeren bir warband geçerli mi? (tavan DAHİL)
static func elite_cap_ok(elite_count: int) -> bool:
	return elite_count <= ELITE_MAX

# ── CULT OF THE BLACK GRAIL: THE ORDER OF THE FLY ────────────────────────────
## Compendium (warbands/cult-of-the-black-grail.md, "## Faction Rules"):
##   "When your warband is created, you must choose whether it will be led by a Lord of
##    Tumours or a Plague Knight.
##     - Lord of Tumours: Your warband MUST include a Lord of Tumours when it is created.
##       Your warband may include up to ONE Lord of Tumours and up to TWO Plague Knights.
##     - Plague Knight: Your warband MUST include a Plague Knight when it is created and
##       may include up to THREE."
const ORDER_LORD := &"lord"
const ORDER_KNIGHT := &"knight"

const ORDER_LIMITS := {
	ORDER_LORD:   {"lord_max": 1, "knight_max": 2},
	ORDER_KNIGHT: {"lord_max": 0, "knight_max": 3},
}

## Seçilen dala göre bu Lord/Knight sayıları izinli mi?
## leader_choice: &"lord" veya &"knight". Boş/bilinmeyen ise (henüz seçilmemiş) izin verilir —
## seçim zorunluluğu warband_ready() tarafından ayrıca denetlenir.
static func order_of_the_fly_allowed(leader_choice: StringName, lord_count: int, knight_count: int) -> bool:
	if not ORDER_LIMITS.has(leader_choice):
		return true
	var lim: Dictionary = ORDER_LIMITS[leader_choice]
	return lord_count <= int(lim["lord_max"]) and knight_count <= int(lim["knight_max"])

# ── COURT OF THE SEVEN-HEADED SERPENT: NOBLES OF THE COURT ───────────────────
## Compendium (warbands/court-of-the-seven-headed-serpent.md, "## Faction Rules"):
##   "Your warband MUST include a Praetor OR a Sorcerer as your leader when it is created.
##    If you select a Praetor as your leader you may include up to one Sorcerer in your
##    warband and vice versa."
static func nobles_of_the_court_satisfied(praetor_count: int, sorcerer_count: int) -> bool:
	return (praetor_count + sorcerer_count) >= 1

const MANDATORY_LEADER_FACTIONS := [&"new_antioch", &"heretic_legion", &"trench_pilgrims", &"iron_sultanate"]

# ── YERLEŞİMİ BİTİRME ÖN KOŞULU ──────────────────────────────────────────────
## Warband sahaya çıkmaya HAZIR mı? Boş string = hazır; dolu string = eksiğin lokalizasyon
## anahtarı (oyuncuya toast olarak gösterilir).
##
## counts sözlüğü çağıran tarafça doldurulur:
##   Court : {"praetor": int, "sorcerer": int}
##   Grail : {"leader_choice": StringName, "lord": int, "knight": int}
## Kuralı olmayan faksiyonlar için daima "" döner.
static func warband_ready(faction_id: StringName, counts: Dictionary) -> String:
	# ZORUNLU LİDER: compendium bu dört faction'ın liderine "Availability: 1" verir (diğer
	# birimler "0-N") — Lieutenant, Heretic Priest, War Prophet, Yüzbaşı warband'da BULUNMALIDIR.
	if faction_id in MANDATORY_LEADER_FACTIONS and int(counts.get("leader", 0)) < 1:
		return "ROSTER_FAIL_LEADER"
	match faction_id:
		&"court_of_seven_headed_serpent":
			if not nobles_of_the_court_satisfied(
					int(counts.get("praetor", 0)), int(counts.get("sorcerer", 0))):
				return "ROSTER_FAIL_NOBLES_OF_THE_COURT"
		&"cult_of_the_black_grail":
			var choice: StringName = counts.get("leader_choice", &"")
			var lord: int = int(counts.get("lord", 0))
			var knight: int = int(counts.get("knight", 0))
			# "must include a Lord of Tumours / a Plague Knight when it is created"
			if choice == ORDER_LORD and lord < 1:
				return "ROSTER_FAIL_ORDER_OF_THE_FLY"
			if choice == ORDER_KNIGHT and knight < 1:
				return "ROSTER_FAIL_ORDER_OF_THE_FLY"
			# Dal hiç seçilmemişse: en az birini içermek yine de zorunludur.
			if choice != ORDER_LORD and choice != ORDER_KNIGHT and lord < 1 and knight < 1:
				return "ROSTER_FAIL_ORDER_OF_THE_FLY"
	return ""
