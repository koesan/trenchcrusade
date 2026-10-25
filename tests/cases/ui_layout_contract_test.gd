extends RefCounted

## UI YERLEŞİM SÖZLEŞMESİ — kullanıcı bildirimlerinden doğan kuralları kilitler.
##
## Bu testin her maddesi GERÇEK bir kullanıcı şikayetine karşılık gelir; ölçümle doğrulandı,
## burada geri gelmesi engelleniyor.

func _node_block(scene_text: String, node_name: String) -> String:
	var i: int = scene_text.find('[node name="%s"' % node_name)
	if i < 0:
		return ""
	var j: int = scene_text.find("\n[node ", i + 1)
	return scene_text.substr(i, (j - i) if j > 0 else -1)

func run(t) -> void:
	# ── HUD: sağ paneller SAĞA yaslı olmalı ───────────────────────────────
	# Şikayet: "ekranın ortasında, sağa yaslı değil, ekran içinde kalmış".
	# Ölçüm: Objectives/Resources sağ kenardan 520px İÇERİDEYDİ (her çözünürlükte).
	var hud := FileAccess.open("res://scenes/ui/hud/game_hud.tscn", FileAccess.READ)
	t.ok(hud != null, "game_hud.tscn okunabildi")
	if hud != null:
		var htxt := hud.get_as_text()
		hud.close()
		for panel in ["ObjectivesPanel", "ResourcesPanel"]:
			var blk := _node_block(htxt, panel)
			t.ok(blk != "", "%s bloğu bulundu" % panel)
			t.ok(blk.contains("anchor_right = 1.0"), "%s sağ kenara sabitli" % panel)
			# Sağ kenardan uzaklık = -offset_right; küçük bir pay olmalı (yüzlerce piksel DEĞİL).
			var m := RegEx.new()
			m.compile("offset_right = (-?[0-9.]+)")
			var res := m.search(blk)
			t.ok(res != null, "%s offset_right var" % panel)
			if res != null:
				var gap: float = absf(float(res.get_string(1)))
				t.ok(gap <= 40.0,
					"%s sağ kenardan %.0fpx (<= 40 olmalı; eskiden 520'ydi)" % [panel, gap])

		# 2026-10-24 YENİDEN TASARIM (kullanıcı onaylı yerleşim): kadro SOL SÜTUNDA, komuta
		# paneli ALT ORTADA, duyurular üst ortada TEK SÜTUNDA alt alta.
		var roster := _node_block(htxt, "RosterColumn")
		t.ok(roster.contains("anchor_bottom = 1.0") and not roster.contains("anchor_left = 1"),
			"Kadro listesi sol kenarda, dikey sütun")
		var cmd := _node_block(htxt, "CommandBar")
		t.ok(cmd != "" and cmd.contains('parent="MarginContainer/VBoxContainer/BottomPanel"'),
			"Komuta paneli alt satırda")
		var notices := _node_block(htxt, "Notices")
		t.ok(notices.contains('type="VBoxContainer"'),
			"Duyurular (tur şeridi, inisiyatif, uyarı) tek sütunda — üst üste binemez")
		t.ok(htxt.find('[node name="__vignette"') < htxt.find('[node name="MarginContainer"'),
			"Kenar karartması arayüzün ALTINDA çizilir (eskiden en üstteydi, panelleri karartıyordu)")
		# Yerleştirme şeridi ise EKRAN BOYUNCA uzamalı (kullanıcı isteği: "ekran boyunca
		# uzanabilsin, sağa kadar gitsin") — sağa yaslanırsa yarım kalır.
		var dep := _node_block(htxt, "DeployPanel")
		t.ok(dep.contains("size_flags_horizontal = 3"),
			"DeployPanel EKRAN BOYUNCA uzar (EXPAND — sağa yaslı DEĞİL)")
		t.ok(dep.contains("size_flags_vertical = 8"), "DeployPanel ALTA yaslı")

	# ── FAKSİYON SEÇİMİ: 6 kart TEK SIRADA ───────────────────────────────
	# Şikayet: "5'i üstte 1'i altta". Kart EXPAND ile 190px'e şişiyordu ve panel 20px dardı.
	var fac := FileAccess.open("res://scenes/ui/faction_select/faction_selection_panel.tscn",
		FileAccess.READ)
	t.ok(fac != null, "faction_selection_panel.tscn okunabildi")
	if fac != null:
		var ftxt := fac.get_as_text()
		fac.close()
		var m2 := RegEx.new()
		m2.compile("custom_minimum_size = Vector2\\(([0-9.]+), ")
		var r2 := m2.search(ftxt)
		t.ok(r2 != null, "Panel taban genişliği tanımlı")
		if r2 != null:
			var panel_w: float = float(r2.get_string(1))
			# 6 kart (6*160 + 5*12 = 1020) + panel iç payı (80) = 1100 asgari.
			t.ok(panel_w >= 1100.0,
				"Panel genişliği 6 kartı tek sırada tutuyor (%.0f >= 1100)" % panel_w)

	var card := FileAccess.open("res://scenes/ui/faction_select/faction_selection.tscn",
		FileAccess.READ)
	if card != null:
		var ctxt := card.get_as_text()
		card.close()
		t.ok(not ctxt.contains("size_flags_horizontal = 3"),
			"Faksiyon kartı GENİŞLEMİYOR (EXPAND kapalı — 160px sabit kalmalı)")

	# ── ŞERİT GENİŞLİĞİ EKRANA GÖRE (sabit kart tavanı YOK) ─────────────
	# Şikayet: "1920x1080'de ekranın yarısını kaplıyor ama scroll bar var, bu olmamalı."
	# Kök neden: görünür kart sayısı SABİT 4'tü, ekran genişliğine hiç bakmıyordu.
	t.eq(UIScrollHelper.fit_count(510.0, 120.0, 10.0), 4,
		"510px'e 4 kart sığar (4*120 + 3*10 = 510)")
	t.eq(UIScrollHelper.fit_count(800.0, 120.0, 10.0), 6, "800px'e 6 kart sığar")
	t.eq(UIScrollHelper.fit_count(100.0, 120.0, 10.0), 1, "Dar alanda en az 1 kart gösterilir")
	t.ok(UIScrollHelper.fit_count(1200.0, 120.0, 10.0) > UIScrollHelper.fit_count(600.0, 120.0, 10.0),
		"Geniş ekran DAHA ÇOK kart gösterir (sabit tavan yok)")

	var strip := FileAccess.open("res://scenes/ui/hud/unit_cards/unit_cards_container.gd",
		FileAccess.READ)
	if strip != null:
		var sttxt := strip.get_as_text()
		strip.close()
		# Kadro listesi dikey kaydırmalı; sabit satır tavanı yok (ekran yüksekliği ne kadar
		# izin verirse o kadar satır görünür).
		t.ok(not sttxt.contains("MAX_VISIBLE_UNIT_CARDS"), "Sabit kart tavanı kullanılmıyor")
		t.ok(sttxt.contains("_built_for"),
			"Kadro satırları her turda yıkılıp yeniden kurulmuyor (kıpırdama önlemi)")

	# ── POPUP SÖZLEŞMESİ ─────────────────────────────────────────────────
	# Şikayetler: "popup yüzünden butona tıklayamıyorum", "boş kısımlar olmasın",
	# "3 saniye çok uzun, 0.5 olsun", "maximum uzunluk ekran yüksekliğinin yarısı olsun",
	# "popup mausun YUKARISINDA olsun, aşağısına inmesin".
	t.approx(UIPlacement.HOVER_DELAY, 0.5, "Hover kartı 0.5 saniyede açılır")
	t.approx(UIPlacement.MAX_HEIGHT_RATIO, 0.5, "Kart en fazla ekranın YARISI kadar uzun")
	t.ok(UIPlacement.MAX_WIDTH_RATIO < 1.0, "Kart azami genişliği ekranın TAMAMI değil")
	var lim: Vector2 = UIPlacement.max_size_for(Vector2(1280, 720))
	t.ok(lim.x < 1280.0 and lim.y < 720.0, "Azami kart boyutu ekrandan küçük: %s" % str(lim))

	# TEK KART: birim profili ve yetenek açıklaması için AYRI sahneler OLMAMALI (kullanıcı
	# isteği: "farklı farklı popuplar yapmaktansa tek popup yap ve farklı şekillerde kullan").
	# Üç ayrı kart varken her düzeltme üçünde ayrı ayrı yapılmak zorundaydı ve senkron kalmıyordu.
	for gone in [
		"res://scenes/ui/hud/unit_panel/unit_status_panel.tscn",
		"res://scenes/ui/hud/tooltip/hud_tooltip_popup.tscn",
	]:
		t.ok(not ResourceLoader.exists(gone),
			"Ayrı hover kartı sahnesi kaldırıldı: %s" % gone.get_file())

	var pop := FileAccess.open("res://scenes/ui/shared/info_popup.gd", FileAccess.READ)
	t.ok(pop != null, "info_popup.gd okunabildi")
	if pop != null:
		var ptxt := pop.get_as_text()
		pop.close()
		t.ok(ptxt.contains("UIPlacement.make_click_through"),
			"InfoPopup fare olaylarına ŞEFFAF (altındaki butona tıklanabilir)")
		t.ok(ptxt.contains("custom_minimum_size = Vector2.ZERO"),
			"InfoPopup'ın SABİT asgari boyutu YOK (içeriğe göre küçülür — boş alan olmaz)")
		# SHOW_ALWAYS: taşma olduğunu zaten biliyoruz; çubuk "devamı var" sinyalidir
		# (kullanıcı isteği: "kaydırma çubukları da gözüksün ki devam ettiği anlaşılsın").
		t.ok(ptxt.contains("SCROLL_MODE_SHOW_ALWAYS"),
			"Azami yüksekliği aşan içerik KAYDIRILIR ve çubuk GÖRÜNÜR (bilgi kesilmez)")
		t.ok(ptxt.contains("UIPlacement.set_interactive(self, scrollable, _scroll)"),
			"Kaydırılabilir kartta İÇ KAYDIRICI da fare olaylarını alır (tekerlek çalışır)")
		t.ok(ptxt.contains("UIPlacement.place_near_mouse"),
			"Kart İMLECİN yanında açılır (sabit köşede değil)")
		t.ok(ptxt.contains("UIPlacement.set_interactive"),
			"Kaydırılabilir kart fare olaylarını alır (üstüne gelince açık kalır)")
		t.ok(ptxt.contains("modulate.a = 0.0"),
			"Kart ÖLÇÜM sırasında saydam (konumlanmamış hâlde sol üstte çizilmez)")
		t.ok(ptxt.contains("_set_wrap(false)"),
			"Genişlik ölçümü sarma KAPALI yapılır (autowrap tuzağı)")
		t.ok(ptxt.contains("hide_popup()") and ptxt.contains("func show_spec"),
			"Yeni kart açılmadan ÖNCE eskisi kapanır (eski konumda asılı kalmaz)")
		t.ok(ptxt.contains("func _settle"),
			"Boyut, yerleşim OTURDUKTAN sonra okunur (tek kare beklemek yetmiyordu)")
		# Künye ANAHTARLARI sarmaya açılmamalı: sarması açık Godot Label'ının asgari genişliği
		# 1 px'dir, GridContainer sütunu çöker ve harfler alt alta dizilir (kullanıcı bildirimi:
		# "japon yazısı gibi").
		t.ok(ptxt.contains("key_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF"),
			"Künye anahtarları SARMAZ (sütun 1 px'e çökmez)")

	# ── BİLGİ AMAÇLI TÜM ÖRTÜLER TIKLAMA GEÇİRGEN Mİ? ────────────────────
	# Savaş alanının/butonların ÜZERİNDE duran ve yalnız bilgi gösteren her bileşen fare
	# olaylarına şeffaf olmalı. CanvasLayer'daki bir Control olayı yakalarsa harita tıklaması
	# (`map_input._unhandled_input`) HİÇ tetiklenmez — o bölgedeki birimler seçilemez olur.
	# (Zar barı tam olarak bu yüzden birim seçimini engelliyordu.)
	for path in [
		"res://scenes/ui/shared/info_popup.gd",
		"res://scenes/ui/hud/shot_breakdown/shot_breakdown_card.gd",
		"res://scenes/ui/hud/dice_bar/dice_bar.gd",
	]:
		var f := FileAccess.open(path, FileAccess.READ)
		t.ok(f != null, "%s okunabildi" % path.get_file())
		if f == null:
			continue
		var txt := f.get_as_text()
		f.close()
		t.ok(txt.contains("UIPlacement.make_click_through"),
			"%s tıklama geçirgen (altındaki butona/birime tıklanabilir)" % path.get_file())

	# Gecikme sabitleri tek kaynakta.
	t.ok(UIPlacement.TOOLTIP_DELAY <= UIPlacement.HOVER_DELAY,
		"Küçük tooltip gecikmesi büyük karttan uzun değil")

	# ── POPUP KONUMU İMLECE GÖRE ────────────────────────────────────────
	# Şikayet: "popup hâlâ sol üste sabit duruyor."
	# KÖK NEDENLER (ikisi de ölçüldü): (1) kart Container'a ekleniyordu, Godot Container her
	# yerleşim geçişinde çocuğunun konumunu VE boyutunu zorlar (`top_level` bile engellemez);
	# (2) kart ekranın %72'si kadar BÜYÜKTÜ, imlecin yanına sığmayıp her seferinde ekran
	# köşesine kenetleniyordu.
	var vp := Vector2(1280, 720)
	var sz := Vector2(300, 200)
	# Ekranın ortasında: kutu imlecin ÜSTÜNDE ve yatayda ORTALANMIŞ olmalı.
	var mid := UIPlacement.position_near_point(Vector2(640, 400), sz, vp)
	t.approx(mid.x, 640.0 - 150.0, "İmlece yatayda ortalanır")
	t.approx(mid.y, 400.0 - 200.0 - UIPlacement.ANCHOR_GAP, "İmlecin ÜSTÜNDE açılır")
	# Kenarlarda ekrana kenetlenir, dışarı taşmaz.
	var left := UIPlacement.position_near_point(Vector2(5, 400), sz, vp)
	t.ok(left.x >= UIPlacement.SCREEN_MARGIN, "Sol kenarda ekran dışına taşmaz")
	var right := UIPlacement.position_near_point(Vector2(1275, 400), sz, vp)
	t.ok(right.x + sz.x <= vp.x - UIPlacement.SCREEN_MARGIN + 0.01,
		"Sağ kenarda ekran dışına taşmaz")

	# ── DİKEY YUVA: HER ZAMAN ÜSTTE, TAVAN EKRANIN YARISI ───────────────
	# Kullanıcı isteği: "popup mausun yukarısında olsun, aşağısına inmesin — tıklamada sorun
	# yaşatmaz." Tek istisna: imleç ekranın tepesindeyken üstte tek satır bile sığmaz.
	# ÇÖZÜNÜRLÜKTEN BAĞIMSIZ olmalı — oranlar görüntü alanına görelidir.
	for res in [Vector2(1280, 720), Vector2(1536, 864), Vector2(1920, 1080), Vector2(2560, 1440)]:
		var half: float = res.y * 0.5
		# İmleç ekranın alt yarısında: kart ÜSTTE ve tavan tam olarak ekranın yarısı.
		var low: Dictionary = UIPlacement.vertical_slot_for(res.y * 0.85, res)
		t.ok(low["above"], "%s: imleç aşağıdayken kart ÜSTTE açılır" % str(res))
		t.approx(low["max_height"], half, "%s: tavan ekranın yarısı" % str(res))
		# İmleç dikey ortada: yine üstte, tavan üstteki gerçek boşlukla sınırlı.
		var mid_slot: Dictionary = UIPlacement.vertical_slot_for(res.y * 0.5, res)
		t.ok(mid_slot["above"], "%s: imleç ortadayken kart ÜSTTE açılır" % str(res))
		t.ok(mid_slot["max_height"] <= half + 0.01,
			"%s: tavan yarıyı aşmaz (%.0f)" % [str(res), mid_slot["max_height"]])
		# İmleç ekranın en tepesinde: üstte kullanılabilir yer yok → tek istisna, alta düşer.
		var top_slot: Dictionary = UIPlacement.vertical_slot_for(20.0, res)
		t.ok(not top_slot["above"],
			"%s: imleç tepedeyken (üstte yer yok) kart ALTA düşer" % str(res))
		t.ok(top_slot["max_height"] > 0.0, "%s: alta düşen kartın yüksekliği var" % str(res))

	# İmleç GÖRÜNÜM koordinatından okunmalı — `CanvasItem.get_global_mouse_position()` canvas
	# dönüşümüne bağlıdır ve kenetleme uzayıyla (get_viewport_rect) uyuşmayabilir.
	var upl := FileAccess.open("res://scripts/ui/ui_placement.gd", FileAccess.READ)
	if upl != null:
		var utxt2 := upl.get_as_text()
		upl.close()
		t.ok(utxt2.contains("get_viewport().get_mouse_position()"),
			"İmleç konumu GÖRÜNÜM koordinatından okunuyor")
		t.ok(not utxt2.contains("popup.get_global_mouse_position()"),
			"Belirsiz canvas-uzayı imleç okuması kullanılmıyor")

	# Popup'lar Container'a EKLENMEMELİ (konumları ezilir).
	for path in [
		"res://scenes/ui/scenario_select/scenario_selection_panel.gd",
		"res://scenes/ui/faction_select/faction_selection_panel.gd",
	]:
		var f2 := FileAccess.open(path, FileAccess.READ)
		t.ok(f2 != null, "%s okunabildi" % path.get_file())
		if f2 == null:
			continue
		var t2 := f2.get_as_text()
		f2.close()
		t.ok(t2.contains("UIPlacement.attach_popup"),
			"%s popup'ı Container OLMAYAN bir ebeveyne ekliyor" % path.get_file())
		t.ok(not t2.contains("\tadd_child(_info_popup)"),
			"%s popup'ı doğrudan Container'a EKLEMİYOR" % path.get_file())

	# ── TUR ROZETLERİ EKRAN KENARLARINA YASLI ───────────────────────────
	# Şikayet: "sol ve sağ üstteki tur göstergeleri tam yaslı değil, biraz boşluk olsun."
	# Eski değerler bozuktu: sol rozetin GENİŞLİĞİ NEGATİFTİ (-14 → -489), sağ rozet ekranın
	# 17px DIŞINDAYDI.
	var tb := FileAccess.open("res://scenes/ui/hud/top_bar/top_bar.tscn", FileAccess.READ)
	t.ok(tb != null, "top_bar.tscn okunabildi")
	if tb != null:
		var tbtxt := tb.get_as_text()
		tb.close()
		var lb := _node_block(tbtxt, "RoundWinBadgeLeft")
		var rb := _node_block(tbtxt, "RoundWinBadgeRight")
		var rx := RegEx.new()
		rx.compile("offset_left = (-?[0-9.]+)\\noffset_top = [-0-9.]+\\noffset_right = (-?[0-9.]+)")
		var lm := rx.search(lb)
		t.ok(lm != null, "Sol rozet offsetleri okunabildi")
		if lm != null:
			var l0 := float(lm.get_string(1))
			var l1 := float(lm.get_string(2))
			t.ok(l1 > l0, "Sol rozetin genişliği POZİTİF (%.0f → %.0f)" % [l0, l1])
			t.ok(l0 > 0.0, "Sol rozet ekran kenarından İÇERİDE (pay var)")
		var rm := rx.search(rb)
		t.ok(rm != null, "Sağ rozet offsetleri okunabildi")
		if rm != null:
			var r0 := float(rm.get_string(1))
			var r1 := float(rm.get_string(2))
			t.ok(r1 > r0, "Sağ rozetin genişliği POZİTİF")
			t.ok(r1 < 0.0, "Sağ rozet ekran kenarının İÇİNDE (pay var)")

	# ── ÇÖZÜNÜRLÜK AYARI HER MODDA ETKİLİ Mİ? ────────────────────────────
	# Şikayet: "ayarlarda çözünürlük seçince hiçbir şey değişmiyor" — eski kod pencere boyutunu
	# YALNIZ pencereli modda değiştiriyordu, tam ekranda tamamen no-op'tu.
	var st := FileAccess.open("res://scenes/ui/overlays/settings/settings_overlay.gd", FileAccess.READ)
	t.ok(st != null, "settings_overlay.gd okunabildi")
	if st != null:
		var stxt := st.get_as_text()
		st.close()
		t.ok(stxt.contains("DisplayScale.set_reference_size"),
			"Çözünürlük seçimi ARAYÜZ REFERANSI olarak uygulanıyor (tam ekranda da etkili)")
