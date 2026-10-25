extends RefCounted

## FAZ C-1: Merkezi config (GameConfig) TEK KAYNAK doğrulaması.
##   1. GameConfig yüklendi ve DEFAULTS anahtarları çözülebiliyor.
##   2. game_state / dice_manager / dice_pool_builder değerleri GameConfig ile AYNI (drift yok).
##   3. Bilinmeyen anahtar → güvenli fallback (default) döner (bozuk JSON çökertmez).

const DicePoolBuilder = preload("res://scripts/rules/dice_pool_builder.gd")
const GameConfigScript = preload("res://scripts/game_config.gd")

func run(t) -> void:
	# 1. Autoload yüklendi mi?
	t.ok(GameConfig != null, "GameConfig autoload mevcut")

	# 2. Tek-kaynak tutarlılığı: kod okuduğu değer = GameConfig değeri.
	t.eq(GameState.ENGAGE_RANGE, GameConfig.f("balance/engage_range", -1.0), "ENGAGE_RANGE = config")
	t.eq(GameState.ATTACK_RANGE_TOLERANCE, GameConfig.f("balance/attack_range_tolerance", -1.0), "ATTACK_RANGE_TOLERANCE = config")
	t.eq(GameState.CHARGE_REACH_TOLERANCE, GameConfig.f("balance/charge_reach_tolerance", -1.0), "CHARGE_REACH_TOLERANCE = config")
	t.eq(GameState.NAV_AGENT_MAX_CLIMB, GameConfig.f("balance/nav_agent_max_climb", -1.0), "NAV_AGENT_MAX_CLIMB = config")
	t.eq(GameState.VERTICAL_STEP_MAX, GameConfig.f("balance/vertical_step_max", -1.0), "VERTICAL_STEP_MAX = config")
	t.eq(GameState.CLIMB_FREE_MAX, GameConfig.f("balance/climb_free_max", -1.0), "CLIMB_FREE_MAX = config")
	t.eq(GameState.DIVING_CHARGE_MIN_HEIGHT, GameConfig.f("balance/diving_charge_min_height", -1.0),
		"DIVING_CHARGE_MIN_HEIGHT = config")
	t.eq(GameState.NAV_MOVE_TOLERANCE, GameConfig.f("balance/nav_move_tolerance", -1.0), "NAV_MOVE_TOLERANCE = config")
	t.eq(DicePoolBuilder.aura_range(), GameConfig.f("balance/aura_range", -1.0), "aura_range() = config")
	t.eq(DiceManager.WATCHDOG_SECONDS, GameConfig.f("timing/dice_watchdog_seconds", -1.0), "dice watchdog = config")
	t.eq(DiceManager.HOLD_SECONDS, GameConfig.f("timing/dice_hold_seconds", -1.0), "dice hold = config")

	# 3. Tüm DEFAULTS anahtarları çözülebilir (şema bütünlüğü).
	for group in GameConfigScript.DEFAULTS.keys():
		for key in GameConfigScript.DEFAULTS[group].keys():
			var path: String = "%s/%s" % [group, key]
			var got: float = GameConfig.f(path, -99999.0)
			t.ok(got != -99999.0, "config anahtarı çözülür: " + path)

	# 4. Bilinmeyen anahtar → güvenli fallback (JSON bozuksa/eksikse çökme yok).
	t.eq(GameConfig.f("balance/does_not_exist", 42.5), 42.5, "bilinmeyen anahtar → default")
	t.eq(GameConfig.f("nonsense/path", 7.0), 7.0, "bilinmeyen grup → default")
	t.eq(GameConfig.i("timing/dice_watchdog_seconds", 0), 3, "i() sayısal okur")
