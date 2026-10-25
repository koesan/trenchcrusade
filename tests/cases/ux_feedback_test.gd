extends RefCounted

## Oynanış geri bildirimi turu: model tabanları iç içe girmez, harita seçiminde tıklanabilir
## adaylar, bildirim akışı, zar barı başlığı, lider rozeti, kenardan düşmede NavMesh doğrulaması.

class FakeUnit extends Node3D:
	var owner_id: int = 1
	var current_health: int = 1

func run(t) -> void:
	# ── Tabanlar iç içe girmez ──────────────────────────────────────────────
	var saved_units: Dictionary = GameState.units
	var mover := FakeUnit.new()
	var other := FakeUnit.new()
	t.add_child(mover)
	t.add_child(other)
	mover.global_position = Vector3(0, 0, 3)
	other.global_position = Vector3(0, 0, 0)
	GameState.units = {"m": mover, "o": other}
	var target: Vector3 = MovementHelper.keep_base_clearance(mover, RID(), Vector3(0, 0, 0.3))
	t.ok(Vector2(target.x, target.z).length() >= MovementHelper.BASE_CONTACT,
		"Başka modelin tabanına giren varış noktası taban temasına itilir")
	t.ok(target.z > 0.0, "İtme modelin geldiği yöne doğru")
	var free_spot: Vector3 = MovementHelper.keep_base_clearance(mover, RID(), Vector3(5, 0, 0))
	t.ok(free_spot.is_equal_approx(Vector3(5, 0, 0)), "Boş yerdeki hedef değişmez")
	var other_level: Vector3 = MovementHelper.keep_base_clearance(mover, RID(), Vector3(0, 4, 0))
	t.ok(other_level.is_equal_approx(Vector3(0, 4, 0)), "Farklı kattaki model çakışma sayılmaz")
	var u := FileAccess.get_file_as_string("res://scenes/unit/unit.gd")
	t.ok(u.contains("normalized() * MovementHelper.BASE_CONTACT)"),
		"Hücum düşmanın tabanına temas noktasında biter (eskiden 1.0 → bazlar iç içe)")

	# ── Harita seçimi: tıklanabilir adaylar ─────────────────────────────────
	var foe := FakeUnit.new()
	foe.owner_id = 2
	t.add_child(foe)
	GameState.pick_unit = mover
	GameState.pick_candidates = [foe]
	t.ok(UnitQuery.is_pick_candidate(foe), "Aday listesindeki düşman tıklanabilir")
	t.ok(not UnitQuery.is_pick_candidate(other), "Listede olmayan model tıklanamaz")
	GameState.pick_candidates = []
	t.ok(UnitQuery.is_pick_candidate(foe) and not UnitQuery.is_pick_candidate(other),
		"Liste boşsa seçimi isteyenin her canlı düşmanı")
	GameState.pick_unit = null
	var mi := FileAccess.get_file_as_string("res://scripts/input/map_input.gd")
	t.ok(mi.contains("_pick_candidate_at(mouse_pos, hit)"),
		"Çite/duvara takılan tıklama da ekrandaki en yakın adayı seçer")
	var hint := FileAccess.get_file_as_string("res://scenes/ui/combat_choice/interaction_hint_card.tscn")
	t.ok(hint.contains("anchor_top = 0.62") and hint.contains("[node name=\"Panel\" type=\"PanelContainer\" parent=\"Center\"]\ncustom_minimum_size = Vector2(460, 0)\nlayout_mode = 2\nmouse_filter = 2"),
		"Seçim ipucu kartı ekran ortasında değil ve tıklamaları geçirir")
	var chains := FileAccess.get_file_as_string("res://scripts/unit/unit_attack_chains.gd")
	t.ok(chains.contains("request_enemy_unit_pick(unit, hint_key, alive)"), "İkinci el/Cleave adayları seçime aktarılır")

	# ── Bildirim akışı ──────────────────────────────────────────────────────
	var feed := NoticeFeed.new()
	t.add_child(feed)
	for i in 6:
		feed.post("uyarı %d" % i)
	t.eq(feed.get_child_count(), NoticeFeed.MAX_CARDS, "En fazla MAX_CARDS kart görünür (en eskisi düşer)")
	feed.post("uyarı 5")
	t.eq(feed.get_child_count(), NoticeFeed.MAX_CARDS, "Aynı metin yeni kart açmaz, mevcut kart yenilenir")
	feed.post_key("ROSTER_FAIL_LEADER")
	var last: Node = feed.get_child(feed.get_child_count() - 1)
	t.eq(last.get_node("%Title").text, LocalizationManager.tr_t("ROSTER_FAIL_LEADER_TITLE"),
		"Anahtarın _TITLE karşılığı kart başlığı olur (\"Lider eksik\")")
	feed.queue_free()
	var block := ActivationRules.selection_block_reason({}, mover, "")
	t.eq(block, "", "Engel yoksa boş")
	var gs := FileAccess.get_file_as_string("res://scripts/game_state/game_state.gd")
	t.ok(gs.contains("GameEvents.notice_posted.emit(block, \"warn\", \"\")"),
		"Seçim engeli oyuncuya bildirim olarak gösterilir (eskiden yalnız log)")
	t.ok(mi.contains("NOTICE_TURN_ORDER") and mi.contains("NOTICE_ALREADY_ACTIVATED"),
		"Sıralı aktivasyon ve zaten aktive olmuş model açıklanır")

	# ── Zar barı başlığı ────────────────────────────────────────────────────
	t.eq(DiceBarUI.caption_for("injury", 2, 2, true), LocalizationManager.tr_t("DICE_CAPTION_INJURY"),
		"İki zarlı Yaralanma Zarı yalnız adını gösterir")
	t.ok(DiceBarUI.caption_for("success", 4, 2, true).contains(LocalizationManager.tr_t("DICE_KEEP_HIGHEST") % 2),
		"Ek zarlı atış: en yüksek 2 zarın sayıldığını söyler")
	t.ok(DiceBarUI.caption_for("success", 3, 2, false).contains(LocalizationManager.tr_t("DICE_KEEP_LOWEST") % 2),
		"Cezalı atış: en düşük 2 zarın sayıldığını söyler")
	t.eq(DiceBarUI.caption_for("bilinmeyen", 1, 1, true), LocalizationManager.tr_t("DICE_CAPTION_BONUS_ROLL"),
		"Tanınmayan atış türü nötr başlık alır")

	# ── Lider rozeti ────────────────────────────────────────────────────────
	var lt: Resource = load("res://assets/data/units/new_antioch_lieutenant.tres")
	var spec: Dictionary = InfoSpec.for_unit_data(lt)
	t.ok(spec["facts"].any(func(f): return f["label"] == LocalizationManager.tr_t("DEPLOY_LEADER_BADGE")),
		"Lider modelin bilgi kartında lider satırı var")
	var card := FileAccess.get_file_as_string("res://scenes/ui/hud/deploy/deploy_unit_card.gd")
	t.ok(card.contains("leader_badge.visible"), "Yerleştirme kartında lider rozeti")

	# ── Kenardan düşme: iniş NavMesh üstünde olmalı ─────────────────────────
	var lf := FileAccess.get_file_as_string("res://scripts/rules/injury/triggers/ledge_fall.gd")
	t.ok(lf.contains("NavigationServer3D.map_get_closest_point"),
		"Kenardan düşen model yürünebilir zemine iner (harita altına değil)")

	GameState.units = saved_units
	for n in [mover, other, foe]:
		n.free()
