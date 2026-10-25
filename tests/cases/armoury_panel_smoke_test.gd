extends RefCounted

## ARMOURY EKRANI — DUMAN TESTİ.
##
## NEDEN: `codex_panel.gd` vakasında olduğu gibi, UI kodundaki bir alan/metot hatası headless
## kural testlerine YAKALANMAZ; ancak ekran gerçekten çizilirken patlar. Bu test paneli kurar,
## sahte bir birimle doldurur ve TÜM kategorileri gezerek her satırı çizdirir.

class _FakeUnit:
	extends Node3D
	var owner_id: int = 1
	var unit_data: Resource = null
	func apply_unit_data() -> void: pass
	func update_indicators() -> void: pass

func run(t) -> void:
	# Test koşucusu `_ready` içinde çalıştığı için `tree.root` o an çocuk eklemeye KAPALIDIR.
	# Zaten ağaçta ve meşgul olmayan bir autoload düğümünü geçici ebeveyn olarak kullanırız.
	var holder: Node = GameState
	var na: Resource = load("res://assets/data/factions/new_antioch.tres")

	# ── sahte oyun durumu ──────────────────────────────────────────────────
	var prev_units: Dictionary = GameState.units.duplicate()
	var prev_faction: Resource = GameState.get_faction_for_player(1)
	var prev_ducat := GameState.player_deploy_pool.duplicate()
	var prev_glory := GameState.player_glory_pool.duplicate()
	ArmouryManager.reset()

	var unit := _FakeUnit.new()
	unit.name = "SmokeYeoman"
	unit.unit_data = load("res://assets/data/units/new_antioch_yeoman.tres").duplicate(true)
	holder.add_child(unit)
	GameState.units = {"SmokeYeoman": unit}
	GameState.player_factions[1] = na   # panel faksiyonun Armoury tablosunu buradan okur
	GameState.player_deploy_pool[1] = 700
	GameState.player_glory_pool[1] = 10

	var scene: PackedScene = load("res://scenes/ui/armoury/armoury_panel.tscn")
	t.ok(scene != null, "Armoury ekranı yüklendi")
	var panel: Control = scene.instantiate()
	holder.add_child(panel)

	panel.open_for(1)
	t.ok(panel.visible, "open_for() paneli görünür yapar")

	# Her kategori gerçekten çizilebilmeli — kalem satırları burada inşa edilir
	var groups: Dictionary = ArmouryRules.by_category(na)
	for cat in groups.keys():
		panel._selected_category = int(cat)
		panel.refresh()
		var rows: int = panel._item_list.get_child_count()
		t.ok(rows > 0, "Kategori %d en az bir kalem satırı çizdi (%d)" % [cat, rows])
	t.eq(panel._unit_list.get_child_count(), _my_unit_count(),
		"Sol sütun oyuncunun sahadaki her modelini listeledi")

	# ── gerçek bir satın alma akışı ────────────────────────────────────────
	var helmet: Resource = null
	for it in ArmouryRules.table_for(na):
		if it.item_id == &"combat_helmet":
			helmet = it
			break
	t.ok(helmet != null, "Muharebe Miğferi New Antioch tablosunda")
	var reason := ArmouryManager.request_purchase(1, "SmokeYeoman", helmet)
	t.eq(reason, "", "Muharebe Miğferi satın alındı")
	t.eq(GameState.player_deploy_pool[1], 700 - helmet.cost,
		"Ödeme ducat havuzundan düştü, Şan havuzuna dokunmadı")
	t.eq(GameState.player_glory_pool[1], 10, "Şan havuzu değişmedi")
	t.ok(KeywordSystem.has(unit.unit_data, &"negate_shrapnel"),
		"Satın alınan miğfer modele [Şarapneli Engelle] verdi")
	t.eq(ArmouryManager.items_of("SmokeYeoman").size(), 1, "Kalem modele kaydedildi")
	t.eq(int(ArmouryManager.counts_of(1).get(&"combat_helmet", 0)), 1,
		"Kalem warband sayımına (LIMIT) işlendi")

	# İkinci kez alınamaz ve panel bunu ÇİZERKEN gösterir
	t.eq(ArmouryManager.request_purchase(1, "SmokeYeoman", helmet),
		ArmouryRules.REASON_ALREADY_OWNED, "Aynı kalem ikinci kez alınamaz")
	panel.refresh()
	t.ok(panel._equipped_list.get_child_count() >= 1, "Takılı kalemler listesi güncellendi")

	# ── "Alışverişi Bitir" AKIŞI ───────────────────────────────────────────
	# Kullanıcı bildirimi: "alışverişi bitir deyince alışveriş penceresi kapanmıyor."
	# Tek makinede sıra rakibe geçmeli; iki taraf da bitirince faz kapanmalı.
	var prev_phase = GameState.game_phase
	GameState.game_phase = GameState.GamePhase.ARMOURY
	GameState.player_deploy_pool[2] = 700
	ArmouryManager.active_shopper_id = 1
	t.eq(ArmouryManager.current_shopper(), 1, "Sıra 1. oyuncuda")

	panel._on_finish_pressed()
	t.eq(ArmouryManager.current_shopper(), 2, "1. oyuncu bitirdi -> sıra 2. oyuncuya geçti")
	t.eq(GameState.game_phase, GameState.GamePhase.ARMOURY,
		"Tek taraf bitirince faz HÂLÂ ARMOURY")
	t.ok(panel.visible, "Sıra devredildiği için panel açık kalır (yeni oyuncu için)")
	t.eq(panel._local_id, 2, "Panel artık 2. oyuncunun modellerini gösteriyor")

	panel._on_finish_pressed()
	t.eq(GameState.game_phase, GameState.GamePhase.BATTLE,
		"İki taraf da bitirince SAVAŞ başlar")
	t.eq(panel.visible, false, "Faz kapanınca alışveriş penceresi KAPANIR")
	GameState.game_phase = prev_phase
	GameState.player_deploy_pool.erase(2)

	# ── temizlik ───────────────────────────────────────────────────────────
	panel.free()
	unit.free()
	GameState.units = prev_units
	GameState.player_factions[1] = prev_faction
	GameState.player_deploy_pool = prev_ducat
	GameState.player_glory_pool = prev_glory
	ArmouryManager.reset()

## Panelden bağımsız sayım — panelin listesi bununla birebir eşleşmeli.
func _my_unit_count() -> int:
	var n := 0
	for k in GameState.units:
		var u = GameState.units[k]
		if is_instance_valid(u) and u.owner_id == 1 and u.unit_data != null:
			n += 1
	return n
