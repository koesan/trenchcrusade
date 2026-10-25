extends Node
## POPUP AÇILIŞ KAPISI (beşinci kapı) — `godot --headless res://tests/popup_gate.tscn`
##
## Hover bilgi kartları GERÇEKTEN açılıyor mu, doğru ebeveyne mi ekleniyor, içeriğe göre mi
## boyutlanıyor ve İMLECİN YANINA mı yerleşiyor? Ana süit senkron çalıştığı için `await`
## gerektiren bu akışı doğrulayamıyor (bkz. hud_smoke.gd'deki aynı gerekçe).
##
## NEDEN AYRI BİR KAPI: üç kez üst üste "popup açılmıyor / sol üste sabit" bildirimi geldi ve
## üçü de ancak çalışma zamanında görülebilen nedenlerdi:
##   1. Container'ın konumu her karede EZMESİ.
##   2. autowrap'in asgari genişliği "en uzun kelime" yapması → 156x4140 px'lik şerit.
##   3. Kartın ekranın %72'si kadar BÜYÜK olması → imlecin yanına sığmayıp her seferinde
##      ekran köşesine kenetlenmesi. Konum matematiği doğruydu, kart fazla büyüktü.
##
## ⚠ SENTETİK İMLEÇ: `Input.warp_mouse` headless'ta çalışmaz (imleç (0,0)'da kalır) ve bu, 3.
## hatayı bu kapının GÖZDEN KAÇIRMASINA yol açtı — imleç zaten sol üstteydi, kart da sol üste
## kenetlenmişti, kontrol "yakın" diye geçiyordu. `Input.parse_input_event` ile beslenen bir
## `InputEventMouseMotion` ise `Viewport.get_mouse_position()`ı gerçekten günceller (ölçüldü).

## İmlecin taşınacağı noktalar — üstte yer VARKEN ve YOKKEN davranış ayrı ayrı denetlenir.
const MOUSE_SPOTS := [
	{"at": Vector2(640, 620), "name": "ekran altı (üstte bol yer var)", "expect_above": true},
	{"at": Vector2(300, 80), "name": "ekran üstü (üstte yer yok)", "expect_above": false},
]

var _fail := 0

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	DisplayScale.set_reference_size(Vector2i(1280, 720), get_window())
	await get_tree().process_frame

	var layer := CanvasLayer.new()
	add_child(layer)

	for entry in [
		{"p": "res://scenes/ui/scenario_select/scenario_selection_panel.tscn", "n": "Senaryo",
		 "list": "cards", "show": "_show_details"},
		{"p": "res://scenes/ui/faction_select/faction_selection_panel.tscn", "n": "Faksiyon",
		 "list": "cards_container", "show": "_show_faction_info"},
	]:
		var panel = load(entry["p"]).instantiate()
		layer.add_child(panel)
		for _i in 6: await get_tree().process_frame

		var container = panel.get(entry["list"])
		var n: int = container.get_child_count() if container else -1
		var first = container.get_child(0) if n > 0 else null
		print("\n### %s — kart=%d" % [entry["n"], n])
		if first == null:
			print("   ✗ HİÇ KART YOK"); _fail += 1; continue

		# ⚠ TETİKLEYİCİ İMLECİN ALTINDA OLMALI. Kart imlecin ÜSTÜNDE açılır, yani imleç kartın
		# İÇİNDE değildir; gerçek oyunda imleç TETİKLEYİCİNİN üstündedir ve kart bu yüzden açık
		# kalır. Izgaradaki gerçek kartlar sabit konumlu olduğu için, imlecin taşındığı her
		# noktada o noktayı KAPSAYAN sentetik bir tetikleyici kullanılır — böylece kapının
		# kurgusu gerçek hover'la aynı olur.
		var probe := Button.new()
		probe.top_level = true
		probe.size = Vector2(60, 40)
		layer.add_child(probe)
		for spot in MOUSE_SPOTS:
			probe.global_position = Vector2(spot["at"]) - probe.size * 0.5
			await get_tree().process_frame
			await _check_at(panel, probe, entry, spot)
		probe.queue_free()

		panel.queue_free()
		await get_tree().process_frame

	await _check_unit_hover_card()

	if _fail == 0:
		print("\n==== POPUP KAPISI: GEÇTİ ====")
		get_tree().quit(0)
	else:
		print("\n==== POPUP KAPISI: %d SORUN ====" % _fail)
		get_tree().quit(1)

## Fareyi `spot`a taşır, popup'ı tetikler ve konumunu/boyutunu denetler.
func _check_at(panel, anchor: Control, entry: Dictionary, spot: Dictionary) -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	await _move_mouse(spot["at"])
	var mouse: Vector2 = get_viewport().get_mouse_position()

	if entry["n"] == "Senaryo":
		panel._show_details(anchor, ScenarioManager.available_scenarios[0])
	else:
		panel._show_faction_info(anchor, GameState.available_factions[0])
	await get_tree().create_timer(UIPlacement.HOVER_DELAY + 0.3).timeout
	for _i in 4: await get_tree().process_frame

	var pop = panel.get("_info_popup")
	print("  · imleç %s — %s" % [str(mouse), spot["name"]])
	if pop == null:
		print("     ✗ POPUP OLUŞMADI"); _fail += 1; return
	var r: Rect2 = pop.get_global_rect()
	print("     ebeveyn=%s(Container:%s) konum=%s boyut=%s" % [pop.get_parent().get_class(),
		str(pop.get_parent() is Container), str(r.position), str(r.size)])

	if pop.get_parent() is Container:
		print("     ✗ Container'a eklenmiş — konumu EZİLİR"); _fail += 1
	if not pop.visible:
		print("     ✗ Popup GÖRÜNMÜYOR"); _fail += 1
	if pop.modulate.a < 0.99:
		print("     ✗ Popup SAYDAM kaldı (ölçüm bitince opak olmalı)"); _fail += 1
	if r.size.x < 100.0 or r.size.y < 40.0:
		print("     ✗ Popup ÇÖKMÜŞ boyutta (autowrap tuzağı)"); _fail += 1
	if pop.get_node("%TitleLabel").text.strip_edges() == "":
		print("     ✗ Başlık BOŞ"); _fail += 1

	# EKRAN İÇİNDE: kart hiçbir kenardan taşmamalı — taşan içerik kart İÇİNDE kaydırılır.
	if r.position.x < 0.0 or r.position.y < 0.0 or r.end.x > vp.x + 0.5 or r.end.y > vp.y + 0.5:
		print("     ✗ Popup ekran DIŞINA taşıyor (ekran %s)" % str(vp)); _fail += 1

	# İMLECE YAKINLIK: kart imlecin ÜSTÜNDE/ALTINDA ve yatayda ona ortalanmış olmalı.
	# Bu, "her zaman sol üst köşeye kenetleniyor" hatasının doğrudan denetimi.
	var dx: float = absf(r.get_center().x - mouse.x)
	if dx > r.size.x * 0.5 + 1.0:
		print("     ✗ Popup imleçten YATAYDA uzak (dx=%.0f) — köşeye kenetlenmiş" % dx); _fail += 1
	if spot["expect_above"]:
		if r.end.y > mouse.y + 0.5:
			print("     ✗ Üstte yer varken kart imlecin ÜSTÜNE açılmadı (alt=%.0f > imleç=%.0f)"
				% [r.end.y, mouse.y]); _fail += 1
	else:
		if r.position.y < mouse.y - 0.5:
			print("     ✗ Üstte yer yokken kart ALTA düşmedi (üst=%.0f < imleç=%.0f)"
				% [r.position.y, mouse.y]); _fail += 1

	# AZAMİ YÜKSEKLİK: ekranın YARISINI aşmamalı (kullanıcı isteği).
	if r.size.y > vp.y * UIPlacement.MAX_HEIGHT_RATIO + 1.0:
		print("     ✗ Kart ekranın yarısından uzun (%.0f > %.0f)"
			% [r.size.y, vp.y * UIPlacement.MAX_HEIGHT_RATIO]); _fail += 1

	_check_facts_readable(pop)
	_check_scrollable(pop)
	await _check_stays_open_on_hover(pop)

## KAYDIRMA GERÇEKTEN ÇALIŞIYOR MU?
##
## KÖK NEDEN (kullanıcı bildirimi: "popuplardaki kaydırma işe yaramıyor, aşağı kaydıramıyorum"):
## `make_click_through` kartın TÜM alt düğümlerini — ScrollContainer dâhil — IGNORE yapıyordu.
## Yalnız KÖKÜ STOP'a çevirmek yetmiyor: tekerlek olayı kökte tükeniyor, kaydırıcıya HİÇ
## ulaşmıyordu. Çubuk görünüyor ama hiçbir şey kaydırmıyordu — "çubuk var" görsel denetimi bu
## yüzden yanıltıcıydı; burada kaydırma GERÇEKTEN uygulanıp sonucu okunuyor.
func _check_scrollable(pop: Control) -> void:
	var sc: ScrollContainer = pop.get_node("Margin/Scroll")
	if sc.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
		return   # içerik sığıyor; kaydırılacak bir şey yok
	if sc.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		print("     ✗ İç kaydırıcı fare olaylarını ALMIYOR — tekerlek kaydırmaz"); _fail += 1
	if sc.get_node_or_null("DragScroll") == null:
		print("     ✗ Sürükleyerek kaydırma takılı DEĞİL (sol/orta tuşla kaydırılamaz)"); _fail += 1
	if not sc.get_v_scroll_bar().visible:
		print("     ✗ Dikey kaydırma çubuğu GÖRÜNMÜYOR (devamı olduğu anlaşılmaz)"); _fail += 1
	var before: int = sc.scroll_vertical
	sc.scroll_vertical = before + 100
	if sc.scroll_vertical <= before:
		print("     ✗ Kaydırma UYGULANMIYOR (%d → %d)" % [before, sc.scroll_vertical]); _fail += 1
	sc.scroll_vertical = before

## KART, ÜSTÜNE GİDİNCE AÇIK KALIYOR MU?
##
## KÖK NEDEN (kullanıcı bildirimi: "popupların üstüne gidince otomatik kapanıyor, bu yüzden
## aşağı kaydıramıyorum"): kapanma `mouse_exited` sinyaline bağlıydı. Kartın kökü STOP iken
## içindeki ScrollContainer da STOP olur; imleç kökten çocuğa geçtiği anda Godot köke
## `mouse_exited` gönderiyor, kart oyuncu ÜSTÜNE GELİR GELMEZ kendini kapatıyordu. Ayrıca eski
## koruma imleci CANVAS uzayından okuyordu ve `content_scale` altında kartın dikdörtgeniyle
## eşleşmiyordu.
##
## Kaydırılabilir kart, imleç ÜSTÜNDEYKEN kapanmamalı; imleç UZAKLAŞINCA kapanmalı.
func _check_stays_open_on_hover(pop) -> void:
	var sc: ScrollContainer = pop.get_node("Margin/Scroll")
	if sc.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
		return
	# İmleci tetikleyiciden ÇIKARIP kartın TAM ORTASINA taşı — gerçek oyuncu hareketi budur.
	await _move_mouse(pop.get_global_rect().get_center())
	pop.request_hide()
	for _i in 3:
		pop._process(0.1)
	if not pop.visible:
		print("     ✗ İmleç kartın ÜSTÜNDEYKEN kart KAPANDI — kaydırmak imkânsız"); _fail += 1
	else:
		print("     ✓ imleç kartın üstünde → kart açık kaldı")
	# İmleç uzaklaşınca kapanmalı (aksi hâlde kart ekranda asılı kalır).
	await _move_mouse(Vector2(20, 20))
	for _i in 6:
		pop._process(0.1)
	if pop.visible:
		print("     ✗ İmleç uzaklaştı ama kart KAPANMADI (ekranda asılı kalır)"); _fail += 1

## KÜNYE IZGARASI OKUNABİLİR Mİ: anahtar sütunu çökmüş olmamalı.
##
## KÖK NEDEN (kullanıcı bildirimi: "zafer koşulları bir cümle oluşturması gerekirken harfler
## alt alta olmuş, japon yazısı gibi"): sarması AÇIK bir Godot Label'ının ASGARİ GENİŞLİĞİ
## 1 px'dir. Künye ANAHTARLARI da sarmaya açılınca `GridContainer` sol sütuna 1 px veriyor ve
## metin karakter başına bir satıra iniyordu (ölçüldü: "Zafer koşulu:" → size=(1, 257)).
func _check_facts_readable(pop: Control) -> void:
	var grid: GridContainer = pop.get_node("%FactsGrid")
	if not grid.visible:
		return
	for c in grid.get_children():
		if not (c is Label):
			continue
		var lbl := c as Label
		# Anahtar sütunu (SHRINK_BEGIN) — genişliği metnine yetmeli.
		if lbl.size_flags_horizontal == Control.SIZE_SHRINK_BEGIN and lbl.size.x < 20.0:
			print("     ✗ Künye anahtarı '%s' ÇÖKMÜŞ genişlikte (%.0f px) — harfler alt alta"
				% [lbl.text, lbl.size.x]); _fail += 1
		# Hiçbir künye etiketi dikey bir şerite dönüşmemeli.
		if lbl.size.y > 120.0 and lbl.size.x < 40.0:
			print("     ✗ Künye etiketi '%s' dikey şerite dönüşmüş (%.0fx%.0f)"
				% [lbl.text, lbl.size.x, lbl.size.y]); _fail += 1

## Birim profili — AYNI kartın farklı bir "şekli" (kullanıcı isteği: tek popup).
##
## Denetlenenler:
##   • Kart gecikme dolmadan GÖRÜNMEZ. (KÖK NEDEN: eski `UnitStatusPanel.update_unit` içerik
##     doldururken `visible = true` yapıyordu; kart konumlanana kadar (0,0)'da — ekranın sol
##     üstünde — çiziliyordu. Kullanıcı bunu "üstüne gelir gelmez sol üstte açılan popup"
##     olarak bildirdi.)
##   • Yetenekler TEK bir Label'a yığılmaz, her biri kendi başlık + gövde satırında olur.
func _check_unit_hover_card() -> void:
	print("\n### Birim profili (aynı kartın 'birim' şekli)")
	var pop: InfoPopup = load("res://scenes/ui/shared/info_popup.tscn").instantiate()
	add_child(pop)
	for _i in 3: await get_tree().process_frame

	# YETENEĞİ OLAN bir birim seçilir — metin yığını hatası ancak yetenek varken görünür,
	# yeteneksiz bir birimle denetim boş yere "geçer".
	var ud: Resource = null
	for f in GameState.available_factions:
		for u in f.available_units:
			if u != null and u.abilities != null and u.abilities.size() >= 2:
				ud = u
				break
		if ud != null:
			break
	if ud == null:
		print("   ✗ En az 2 yetenekli UnitData bulunamadı"); _fail += 1; return
	var spec: Dictionary = InfoSpec.for_unit_data(ud)
	print("   denek=%s (%d yetenek)" % [ud.unit_name, ud.abilities.size()])

	var anchor := Button.new()
	anchor.custom_minimum_size = Vector2(80, 40)
	add_child(anchor)
	await _move_mouse(Vector2(700, 640))
	pop.show_spec(anchor, spec)
	await get_tree().process_frame
	if pop.visible:
		print("   ✗ Kart GECİKME DOLMADAN göründü — konumlanmadan sol üstte çizilir"); _fail += 1

	await get_tree().create_timer(UIPlacement.HOVER_DELAY + 0.3).timeout
	for _i in 4: await get_tree().process_frame
	var sections: VBoxContainer = pop.get_node("%Sections")
	print("   görünür=%s boyut=%s yetenek_satırı=%d"
		% [str(pop.visible), str(pop.size), sections.get_child_count()])
	if not pop.visible:
		print("   ✗ Gecikme sonrası kart AÇILMADI"); _fail += 1
	if sections.get_child_count() != ud.abilities.size() * 2:
		print("   ✗ Yetenek satırları eksik (beklenen %d, bulunan %d)"
			% [ud.abilities.size() * 2, sections.get_child_count()]); _fail += 1

	# KÜNYE SÜTUNU: anahtar etiketleri sarmaya AÇILIRSA asgari genişlikleri 1 px olur ve
	# GridContainer sütunu 1 px'e düşürür — metin karakter başına bir satıra iner (kullanıcı
	# bildirimi: "harfler alt alta olmuş, japon yazısı gibi").
	var grid: GridContainer = pop.get_node("%FactsGrid")
	for c in grid.get_children():
		if c is Label and c.size_flags_horizontal == Control.SIZE_SHRINK_BEGIN:
			if c.autowrap_mode != TextServer.AUTOWRAP_OFF:
				print("   ✗ Künye ANAHTARI sarmaya açık — sütun 1 px'e çöker"); _fail += 1
			elif c.size.x < 20.0:
				print("   ✗ Künye anahtarı '%s' ÇÖKMÜŞ genişlikte (%.0f px)" % [c.text, c.size.x])
				_fail += 1
	anchor.queue_free()
	pop.queue_free()
	await get_tree().process_frame

## Sentetik fare hareketi — `Viewport.get_mouse_position()`ı gerçekten günceller.
## `at` PENCERE pikselinde verilir; görünüm ölçeği uygulanmış mantıksal konum okunur.
##
## ⚠ Olay SIRADA işlenir: `parse_input_event` çağrısının hemen ardından okunan imleç konumu hâlâ
## ESKİ değeri verir (bu, denetimleri bir adım kaydırıp yanlış "geçti" üretiyordu). Olay
## işlenene kadar beklenir.
func _move_mouse(at: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = at
	ev.global_position = at
	Input.parse_input_event(ev)
	for _i in 2:
		await get_tree().process_frame
