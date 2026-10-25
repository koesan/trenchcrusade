extends RefCounted

## Uzayabilen listeler SINIRSIZ büyümemeli — belirli bir öğe sayısından sonra kaydırma devreye
## girmeli. Aksi hâlde panel diğer HUD öğelerinin üstüne biner (kullanıcı bildirimi:
## "unit eylem butonları ne kadar çoksa o kadar uzuyor, farklı UI kısımlarının üstüne geliyor").

func run(t) -> void:
	# ── Saf hesap ──────────────────────────────────────────────────────────
	t.approx(UIScrollHelper.content_height(36.0, 5, 5.0), 200.0,
		"5 buton × 36px + 4 boşluk × 5px = 200px")
	t.approx(UIScrollHelper.content_height(36.0, 1, 5.0), 36.0, "Tek öğe → boşluk yok")
	t.approx(UIScrollHelper.content_height(36.0, 0, 5.0), 0.0, "Sıfır öğe → 0")

	# ── Tavan ──────────────────────────────────────────────────────────────
	t.approx(UIScrollHelper.capped_height(36.0, 12, 5, 5.0), 200.0,
		"12 buton → yükseklik 5 butonda SABİTLENİR (gerisi kaydırma)")
	t.approx(UIScrollHelper.capped_height(36.0, 3, 5, 5.0), 118.0,
		"3 buton → tavana ulaşılmadı, gerçek yükseklik (36×3 + 5×2)")
	t.approx(UIScrollHelper.capped_height(36.0, 5, 5, 5.0), 200.0, "Tam tavan sayısı")

	# ── Yatay şerit (birim kartları) tam karta oturmalı ───────────────────
	t.approx(UIScrollHelper.snap_to_whole_items(120.0, 4, 4, 10.0), 510.0,
		"4 kart × 120px + 3 boşluk × 10px = 510px (yarım kart YOK)")
	t.approx(UIScrollHelper.snap_to_whole_items(120.0, 9, 4, 10.0), 510.0,
		"9 kart → genişlik 4 kartta sabitlenir")
	t.approx(UIScrollHelper.snap_to_whole_items(120.0, 2, 4, 10.0), 250.0,
		"2 kart → tavana ulaşılmadı")

	# ── Sözleşme sabitleri ─────────────────────────────────────────────────
	# Eylem butonu tavanı artık SABİT DEĞİL: ekran yüksekliğinin yarısına kaç buton sığıyorsa o.
	# (Sabit 5 tavanı çözünürlüğü hiç görmüyordu.)
	t.approx(UIScrollHelper.HALF_SCREEN, 0.5, "Birim şeridi tavanı ekranın YARISI")
	# Eylem butonu paneli DAHA DAR bir tavanda: ekran yüksekliğinin ÜÇTE BİRİ (kullanıcı isteği:
	# "butonları yarıdan üçte bire düşür"). Sağ altta dikey duran panel, yarım ekran
	# yüksekliğinde savaş alanının görünür kısmını fazla kapatıyordu.
	t.approx(UIScrollHelper.ACTION_PANEL_RATIO, 1.0 / 3.0,
		"Eylem butonu paneli tavanı ekranın ÜÇTE BİRİ")
	t.ok(UIScrollHelper.ACTION_PANEL_RATIO < UIScrollHelper.HALF_SCREEN,
		"Buton paneli, birim şeridinden DAHA DAR bir tavana sahip")
	t.eq(UIScrollHelper.fit_count_ratio(720.0, 36.0, 5.0, UIScrollHelper.ACTION_PANEL_RATIO), 5,
		"720p'de ekranın üçte birine 5 eylem butonu sığar")
	t.ok(UIScrollHelper.fit_count_ratio(1440.0, 36.0, 5.0, UIScrollHelper.ACTION_PANEL_RATIO)
		> UIScrollHelper.fit_count_ratio(720.0, 36.0, 5.0, UIScrollHelper.ACTION_PANEL_RATIO),
		"Yüksek çözünürlükte DAHA ÇOK buton sığar (tavan orana bağlı)")
	# Şerit/panel iki tavanla da sınırlıdır: gerçek boşluk VE ekranın yarısı — küçük olan kazanır.
	t.approx(UIScrollHelper.cap_to_half(1226.0, 1536.0), 768.0,
		"Ölçülen boşluk ekranın yarısını aşarsa YARIYA kırpılır")
	t.approx(UIScrollHelper.cap_to_half(400.0, 1536.0), 400.0,
		"Boşluk zaten yarının altındaysa dokunulmaz")
	# Birim kartı şeridinin SABİT tavanı (`MAX_VISIBLE_UNIT_CARDS = 4`) kaldırıldı: ekranın
	# yarısına kaç TAM kart sığıyorsa o kadar gösterilir, gerisi kaydırmayla gelir.
	t.eq(UIScrollHelper.fit_count_half(1280.0, 120.0, 10.0), 5,
		"1280px genişlikte ekranın yarısına (640px) 5 birim kartı sığar")
	t.eq(UIScrollHelper.fit_count_half(1920.0, 120.0, 10.0), 7,
		"1920px genişlikte ekranın yarısına 7 birim kartı sığar")
	t.ok(UIScrollHelper.MAX_VISIBLE_UNITS >= 4, "Faksiyon birim listesi tavanı >= 4")

	# ── Uzayabilen listeler sınırlı kalmalı ───────────────────────────────
	# 2026-10-24 yeniden tasarım: eylem paneli komuta panelinde YATAY AKIŞ (HFlowContainer) —
	# butonlar ikinci satıra geçer, dikey liste + kaydırma çubuğu yerine. Kadro listesi sol
	# sütunda, içindeki ScrollContainer ile dikey kaydırılır.
	var action_scene: PackedScene = load("res://scenes/ui/hud/action_panel/action_buttons_panel.tscn")
	t.ok(action_scene != null, "action_buttons_panel.tscn yüklendi")
	if action_scene != null:
		t.eq(action_scene.get_state().get_node_type(0), "HFlowContainer",
			"Eylem paneli satır kaydıran yatay akış (taşınca alt satıra geçer)")

	var cards_scene: PackedScene = load("res://scenes/ui/hud/unit_cards/unit_cards_container.tscn")
	if cards_scene != null:
		var cst := cards_scene.get_state()
		var has_scroll := false
		for i in range(cst.get_node_count()):
			if cst.get_node_type(i) == "ScrollContainer":
				has_scroll = true
		t.ok(has_scroll, "Kadro listesi kaydırılabilir (uzun kadrolar ekrandan taşmaz)")

	# ── VERİ ODAKLI SEÇİM PANELLERİ ──────────────────────────────────────
	# Bu iki panelin içeriği artık KOD DIŞINDAN geliyor: faksiyonlar `factions_manifest.tres`ten,
	# senaryolar `assets/data/scenarios/` DİZİN TARAMASINDAN. Yani içerik eklemek kart sayısını
	# otomatik artırıyor ve eskiden tavan YOKTU — yeterince içerik eklendiğinde paneller ekranın
	# dışına taşıp alttaki/sağdaki kartları TIKLANAMAZ hale getirirdi. Bu, projede daha önce
	# tekrarlayan "içerik ekle → UI sessizce bozul" hata sınıfının aynısı.
	# NOT: FAKSİYON seçimi bilinçli olarak bu listede DEĞİL. Kullanıcı "faction ekranı yarım
	# gözüküyor, aşağı kaydırma OLMASIN, tam gözüksün" dedi — orada kartlar `HFlowContainer`da:
	# hepsi aynı anda görünür, sığmazsa kaydırma yerine ALT SATIRA sarar. Faksiyon sayısı hiçbir
	# zaman çok yükselmeyeceği için sarma yeterli ve kaydırmadan okunaklı. (Bkz. aşağıdaki
	# ayrı doğrulama.)
	for entry in [
		{"path": "res://scenes/ui/scenario_select/scenario_selection_panel.tscn",
		 "scroll": "CardsScroll", "list": "Cards", "label": "Senaryo seçimi"},
	]:
		var scene: PackedScene = load(entry["path"])
		t.ok(scene != null, "%s sahnesi yüklendi" % entry["label"])
		if scene == null:
			continue
		var st2 := scene.get_state()
		var scroll_idx := -1
		var list_parented_under_scroll := false
		for i in range(st2.get_node_count()):
			if st2.get_node_name(i) == entry["scroll"]:
				scroll_idx = i
				t.eq(st2.get_node_type(i), "ScrollContainer",
					"%s → %s bir ScrollContainer" % [entry["label"], entry["scroll"]])
			if st2.get_node_name(i) == entry["list"]:
				# Godot sahne durumunda ebeveyn yolu NodePath olarak tutulur.
				list_parented_under_scroll = String(st2.get_node_path(i)).contains(entry["scroll"])
		t.ok(scroll_idx >= 0, "%s → kaydırma konteyneri mevcut" % entry["label"])
		t.ok(list_parented_under_scroll,
			"%s → kart listesi kaydırma konteynerinin İÇİNDE" % entry["label"])

		# Panel gerçekten kurulabiliyor mu? (@onready yolları kaydırma sarmalamasıyla değişti —
		# yanlış bir yol sessizce null bırakır ve panel çalışmaz.)
		var inst := scene.instantiate()
		t.ok(inst != null, "%s örneklenebiliyor" % entry["label"])
		if inst != null:
			t.ok(inst.get_node_or_null(entry["scroll"] if scroll_idx == 0 else "") != null \
				or inst.find_child(entry["scroll"], true, false) != null,
				"%s → %s düğümü örnekte bulunabiliyor" % [entry["label"], entry["scroll"]])
			inst.free()

	# ── FAKSİYON SEÇİMİ: kaydırma DEĞİL, sarma ───────────────────────────
	var fac: PackedScene = load("res://scenes/ui/faction_select/faction_selection_panel.tscn")
	t.ok(fac != null, "Faksiyon seçimi sahnesi yüklendi")
	if fac != null:
		var fst := fac.get_state()
		var has_flow := false
		var has_scroll := false
		for i in range(fst.get_node_count()):
			if fst.get_node_type(i) == "HFlowContainer":
				has_flow = true
			if fst.get_node_type(i) == "ScrollContainer":
				has_scroll = true
		t.ok(has_flow, "Faksiyon kartları HFlowContainer'da (sığmazsa alt satıra sarar)")
		t.ok(not has_scroll,
			"Faksiyon seçiminde kaydırma YOK — kullanıcı isteği: tüm kartlar tam görünsün")
