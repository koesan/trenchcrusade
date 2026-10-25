extends RefCounted

## UI redesign (2026-07-18) — top bar'ın çok turlu yeniden tasarımı. Canlı raycast/tema-render
## gerektiren görsel doğrulama bu projenin genel kuralıyla tutarlı şekilde burada yapılamıyor
## (headless test edilemez) — SAF mantık (phase_display_key) ve yapısal kaynak-kontrolleri
## (regresyon kilidi) burada kilitleniyor.
##
## 6. tur: "top bardaki TÜM öğeleri istediğim gibi büyütüp küçültüp konumlandırabileyim, şu an
## sabit duruyor." KÖK NEDEN: Container tipi düğümler (VBoxContainer/HBoxContainer/PanelContainer)
## çocuklarının konum/boyutunu HER layout geçişinde ZORLA ayarlar. Çözüm: top_bar.tscn'deki TÜM
## Container'lar kaldırıldı; kök artık düz bir Control, her öğe onun DOĞRUDAN çocuğu.
##
## 7. tur (kullanıcı isteği): "üst barı kaldırsak... ortada sadece RoundMedallion, kanatlarında
## Menü/Nizamlar/Gazavat Hedefleri butonları ve faz yazısı olur." Dolgulu tam-genişlik banner
## (TopBarPanel) ve ayrı TurnLabel/ChroniclesButton/MenuButton düğümleri kaldırıldı — bu üç buton
## ve faz etiketi artık RoundMedallion'ın kendi kanatlarında yaşıyor. Ayrıca game_hud.tscn'deki
## eski bağımsız "⚔ OBJECTIVES" butonu kaldırılıp aynı işlev RoundMedallion'ın 3. kanat butonuna
## taşındı (top_bar'ın yeni objectives_pressed sinyali üzerinden).

func run(t) -> void:
	# ── TurnManager.phase_display_key(): tek kaynak, top_bar.gd + round_medallion.gd paylaşıyor ──
	var original_phase: int = TurnManager.current_phase
	TurnManager.current_phase = TurnManager.PHASE_INITIATIVE
	t.eq(TurnManager.phase_display_key(), "PHASE_INITIATIVE", "Initiative fazı → doğru anahtar")
	TurnManager.current_phase = TurnManager.PHASE_MORALE
	t.eq(TurnManager.phase_display_key(), "PHASE_MORALE", "Morale fazı → doğru anahtar")
	TurnManager.current_phase = TurnManager.PHASE_ACTIVATION
	t.eq(TurnManager.phase_display_key(), "PHASE_ACTIVATION", "Activation fazı → doğru anahtar")
	TurnManager.current_phase = original_phase

	for key in ["PHASE_INITIATIVE", "PHASE_MORALE", "PHASE_ACTIVATION"]:
		t.ok(LocalizationManager.has_key(key), "%s → localization anahtarı mevcut" % key)
	t.ok(LocalizationManager.has_key("OBJECTIVES"), "OBJECTIVES → localization anahtarı mevcut (Gazavat Hedefleri butonu)")

	# ── top_bar.gd yapısal kontroller ───────────────────────────────────────────
	var top_bar_src := FileAccess.get_file_as_string("res://scenes/ui/hud/top_bar/top_bar.gd")
	t.ok(top_bar_src.contains("round_medallion"), "top_bar.gd → RoundMedallion referansı var")
	t.ok(top_bar_src.begins_with("extends Control"),
		"top_bar.gd → kök artık düz Control (hiçbir Container DEĞİL — serbest sürükleme için)")
	t.ok(top_bar_src.contains("round_win_badge_left.set_player(1)"), "top_bar.gd → sol rozet Oyuncu 1'e atanmış")
	t.ok(top_bar_src.contains("round_win_badge_right.set_player(2)"), "top_bar.gd → sağ rozet Oyuncu 2'ye atanmış")
	t.ok(top_bar_src.contains("func set_round_indicators_visible"),
		"top_bar.gd → rozet+madalyon görünürlük yardımcı fonksiyonu var (public — game_hud.gd dışarıdan çağırıyor)")

	# 9. tur (kullanıcı isteği, 2026-07-19): Menü/Nizamlar/Gazavat Hedefleri/Kaynaklar artık
	# RoundMedallion'ın İÇİNDE değil — top_bar.tscn'in KENDİ düz çocukları (MenuButton/
	# ChroniclesButton/ObjectivesButton/ResourcesButton), diğer her şey gibi serbestçe
	# sürüklenebilir/boyutlandırılabilir. top_bar.gd artık bunların pressed sinyallerini
	# DOĞRUDAN dinliyor (RoundMedallion'ın forward ettiği sinyaller üzerinden DEĞİL).
	t.ok(top_bar_src.contains("signal objectives_pressed") and top_bar_src.contains("signal resources_pressed"),
		"top_bar.gd → objectives_pressed VE yeni resources_pressed sinyalleri var")
	t.ok(top_bar_src.contains("menu_btn.pressed.connect(") \
			and top_bar_src.contains("chronicles_btn.pressed.connect(") \
			and top_bar_src.contains("objectives_btn.pressed.connect(") \
			and top_bar_src.contains("resources_btn.pressed.connect("),
		"top_bar.gd → 4 butonun (menu/chronicles/objectives/resources) pressed sinyalini DOĞRUDAN dinliyor")

	var hud_src := FileAccess.get_file_as_string("res://scenes/ui/hud/game_hud.gd")
	t.ok(not hud_src.contains("round_win_badge_left"),
		"game_hud.gd → artık round_win_badge_left'a DOĞRUDAN referansı yok (top_bar.gd'ye taşındı)")
	t.ok(hud_src.contains("top_bar.apply_phase("),
		"game_hud.gd → top_bar'ın public metodunu (aşamaya göre görünürlük) çağırıyor")
	t.ok(hud_src.contains("func _on_objectives_toggle_pressed"),
		"game_hud.gd → objectives toggle mantığı hâlâ mevcut (artık top_bar'ın objectives_pressed sinyaliyle tetikleniyor)")

	var badge_src := FileAccess.get_file_as_string("res://scenes/ui/hud/top_bar/round_win_badge.gd")
	t.ok(badge_src.contains("ScenarioManager.player_round_wins"), "round_win_badge.gd → gerçek round-kazanma verisini okuyor")

	# ── round_medallion.gd: yalnız round rakamı + faz metni (butonlar artık top_bar.tscn'de) ──
	var medallion_src := FileAccess.get_file_as_string("res://scenes/ui/hud/top_bar/round_medallion.gd")
	t.ok(medallion_src.contains("TurnManager.current_round"), "round_medallion.gd → gerçek round numarasını okuyor")
	t.ok(medallion_src.contains("phase_display_key()"), "round_medallion.gd → tek-kaynak faz fonksiyonunu kullanıyor")
	# 9. tur: 3 kanat-buton sinyali (menu/chronicles/objectives) round_medallion.gd'den KALDIRILDI
	# — bu butonlar artık top_bar.tscn'in kendi düğümleri (bkz. yukarıdaki top_bar.gd kontrolü).
	t.ok(not medallion_src.contains("signal menu_pressed") and not medallion_src.contains("signal chronicles_pressed") \
			and not medallion_src.contains("signal objectives_pressed"),
		"round_medallion.gd → kanat-buton sinyalleri artık YOK (top_bar.tscn'e taşındı)")
	t.ok(medallion_src.contains("phase_label.text = phase_txt"),
		"round_medallion.gd → faz metni artık PhaseLabel'da SÜREKLİ görünür (yalnız tooltip'te değil)")

	# ── Sahne dosyaları var mı (yeni bileşenler gerçekten oluşturulmuş) ─────────────────
	t.ok(ResourceLoader.exists("res://scenes/ui/hud/top_bar/round_medallion.tscn"),
		"round_medallion.tscn mevcut")
	t.ok(ResourceLoader.exists("res://scenes/ui/hud/top_bar/round_win_badge.tscn"),
		"round_win_badge.tscn mevcut")

	# ── Canlı bildirim (2026-07-18) düzeltmeleri — regresyon kilidi ────────────────────
	t.ok(not medallion_src.contains("locale_changed.connect(_refresh)"),
		"round_medallion.gd → locale_changed artık DOĞRUDAN _refresh'e bağlanmıyor (çökme kilidi)")
	t.ok(medallion_src.contains("locale_changed.connect(func(_l): _refresh())"),
		"round_medallion.gd → locale_changed lambda ile sarmalı")
	t.ok(not badge_src.contains("locale_changed.connect(_refresh)"),
		"round_win_badge.gd → locale_changed artık DOĞRUDAN _refresh'e bağlanmıyor (çökme kilidi)")
	t.ok(badge_src.contains("locale_changed.connect(func(_l): _refresh())"),
		"round_win_badge.gd → locale_changed lambda ile sarmalı")

	t.ok(medallion_src.begins_with("extends Control"), "round_medallion.gd → Control kökü (PanelContainer DEĞİL)")
	t.ok(badge_src.begins_with("extends Control"), "round_win_badge.gd → Control kökü (PanelContainer DEĞİL)")

	var medallion_tscn := FileAccess.get_file_as_string("res://scenes/ui/hud/top_bar/round_medallion.tscn")
	t.ok(medallion_tscn.contains("round_medallion_banner.png"), "round_medallion.tscn → gerçek banner asset'i kullanıyor")
	# 8. tur (kaymışlık düzeltmesi, 2026-07-18): top_level=true KALDIRILDI — top_bar.tscn artık
	# PanelContainer değil düz Control olduğundan gerekmiyordu, üstelik RoundMedallion'ı TopBar'ın
	# gerçek ekran konumundan (MarginContainer kenar boşluğu kadar) kopararak kaymaya yol açıyordu.
	t.ok(not medallion_tscn.contains("top_level = true"),
		"round_medallion.tscn → top_level artık YOK (TopBar'ın gerçek konumundan kopup kaymasın diye kaldırıldı)")
	var badge_tscn := FileAccess.get_file_as_string("res://scenes/ui/hud/top_bar/round_win_badge.tscn")
	t.ok(badge_tscn.contains("round_win_banner.png"), "round_win_badge.tscn → gerçek banner asset'i kullanıyor")

	# 9. tur: butonlar round_medallion.tscn'den kaldırıldı — yalnız PhaseLabel kaldı burada.
	t.ok(medallion_tscn.contains('name="PhaseLabel"'), "round_medallion.tscn → PhaseLabel var")
	for removed_name in ["MedallionMenuButton", "MedallionChroniclesButton", "MedallionObjectivesButton"]:
		t.ok(not medallion_tscn.contains('name="%s"' % removed_name),
			"round_medallion.tscn → %s artık burada DEĞİL (top_bar.tscn'e taşındı)" % removed_name)

	# ── KÖK NEDEN (6. tur): top_bar.tscn'de ARTIK hiçbir Container tipi (VBoxContainer/
	# HBoxContainer/PanelContainer) YOK; tüm etkileşimli öğeler kökün DOĞRUDAN çocuğu. ─────────
	var top_bar_tscn := FileAccess.get_file_as_string("res://scenes/ui/hud/top_bar/top_bar.tscn")
	# NOT: Godot editörü sahneyi kaydettiğinde her düğüme bir "unique_id=..." attribute'u ekliyor
	# (örn. '[node name="TopBar" type="Control" unique_id=...]') — bu yüzden burada ve aşağıda
	# tam satır eşleşmesi yerine substring kontrolü kullanılıyor (editör-kaynaklı format
	# değişikliklerine dayanıklı olsun diye).
	t.ok(top_bar_tscn.contains('[node name="TopBar" type="Control"'),
		"top_bar.tscn → kök artık düz Control")
	# 8. tur (editör kaymışlık düzeltmesi, 2026-07-18): kök genişliği artık 0 DEĞİL — sahne tek
	# başına açıldığında editör tuvali gerçek çalışma zamanı genişliğiyle (MarginContainer'ın
	# 15+15 kenar boşluğu düşülmüş 1250px) eşleşsin diye gerçekçi bir boyut kilitlendi.
	t.ok(top_bar_tscn.contains("custom_minimum_size = Vector2(1250, 150)"),
		"top_bar.tscn → kök gerçekçi bir boyutla kilitli (editörde WYSIWYG sürükle-bırak için)")
	t.ok(not top_bar_tscn.contains("VBoxContainer") and not top_bar_tscn.contains("HBoxContainer") \
			and not top_bar_tscn.contains("PanelContainer"),
		"top_bar.tscn → HİÇBİR Container tipi kalmadı (VBox/HBox/PanelContainer) — serbest sürükleme kilidi")
	# 7. tur: dolgulu tam-genişlik banner (TopBarPanel) ve eski ayrı TurnLabel kaldırıldı.
	t.ok(not top_bar_tscn.contains('[node name="TopBarPanel"'),
		"top_bar.tscn → TopBarPanel (dolgulu tam-genişlik banner) kaldırıldı")
	t.ok(not top_bar_tscn.contains('name="TurnLabel"'),
		"top_bar.tscn → TurnLabel artık burada değil")

	# 9. tur: Menü/Nizamlar/Gazavat Hedefleri/Kaynaklar butonları RoundMedallion'dan buraya
	# (top_bar.tscn'in kendi düz çocukları) taşındı.
	# (2026-10-24: EndTurnButton komuta paneline taşındı — bkz. command_bar.tscn)
	var top_bar_nodes := ["StatusLabel", "RoundMedallion", "RoundWinBadgeLeft",
		"RoundWinBadgeRight", "MenuButton", "ChroniclesButton", "ObjectivesButton", "ResourcesButton"]
	for node_name in top_bar_nodes:
		t.ok(top_bar_tscn.contains('parent="."') and top_bar_tscn.contains('name="%s"' % node_name),
			"top_bar.tscn → %s var" % node_name)
	# Bu öğelerin HEPSİ kökün (".") DOĞRUDAN çocuğu olmalı — nested bir Container'ın İÇİNDE değil.
	var direct_child_count := 0
	for line in top_bar_tscn.split("\n"):
		if not line.begins_with("[node "):
			continue
		for node_name in top_bar_nodes:
			if line.contains('name="%s"' % node_name) and line.contains('parent="."'):
				direct_child_count += 1
	t.eq(direct_child_count, top_bar_nodes.size(),
		"top_bar.tscn → etkileşimli öğelerin HEPSİ kökün DOĞRUDAN çocuğu (serbest sürüklenebilir)")

	# game_hud.tscn artık RoundWinRow'u BARINDIRMIYOR (top_bar.tscn'e taşındı) ve eski bağımsız
	# "⚔ OBJECTIVES" butonu kaldırıldı (RoundMedallion'ın 3. kanat butonuna taşındı).
	var hud_tscn := FileAccess.get_file_as_string("res://scenes/ui/hud/game_hud.tscn")
	t.ok(not hud_tscn.contains('[node name="RoundWinRow"'),
		"game_hud.tscn → RoundWinRow artık burada DEĞİL (top_bar.tscn'e taşındı)")
	t.ok(not hud_tscn.contains('[node name="ObjectivesToggleBtn"'),
		"game_hud.tscn → eski bağımsız ObjectivesToggleBtn kaldırıldı (RoundMedallion'a taşındı)")
	t.ok(hud_tscn.contains('signal="objectives_pressed"') and hud_tscn.contains('method="_on_objectives_toggle_pressed"'),
		"game_hud.tscn → TopBar'ın yeni objectives_pressed sinyali _on_objectives_toggle_pressed'e bağlı")
