## TEK HOVER BİLGİ KARTI — oyundaki BÜTÜN "üstüne gelince bilgi göster" kartları budur.
##
## NEDEN TEK BİLEŞEN (kullanıcı isteği: "farklı farklı popuplar yapmaktansa tek popup yap ve
## farklı şekillerde kullan"): önce üç ayrı kart vardı — `InfoPopup` (senaryo/faksiyon künyesi),
## `UnitStatusPanel` (birim profili) ve `HUDTooltipPopup` (yetenek açıklaması). Üçü de aynı
## işi yapıyordu ama gecikme, konumlandırma, yükseklik sınırlama ve fare geçirgenliği kuralları
## HER BİRİNDE AYRI yazılmıştı; bir hata düzeltilince diğer ikisi geride kalıyordu (kullanıcı
## aynı "sol üste sabit" hatasını üç kez ayrı ayrı bildirdi). Artık davranış TEK yerde.
##
## ŞEKİLLER: kart bir SÖZLEŞME (spec) sözlüğü ile doldurulur; hangi bölümler doluysa o bölümler
## görünür, kalanlar gizlenir. Bölümler sırayla:
##   title     — başlık (zorunlu)
##   subtitle  — ikincil satır (ör. birim statları)
##   body      — serbest metin (ör. faksiyon hikâyesi, senaryo açıklaması)
##   facts     — [{label, value}] "etiket: değer" ızgarası (künye)
##   badges    — [{text, color}] kısa durum rozetleri
##   sections  — [{heading, text}] başlıklı paragraflar (ör. yetenekler, başarı/başarısızlık)
## Spec üreticileri için bkz. `scripts/ui/info_spec.gd`.
##
## BOYUTLANDIRMA SÖZLEŞMESİ (kullanıcı isteği: "maximum uzunluk ekran yüksekliğinin yarısı
## kadar olsun, fazlası kaydırılsın; az bilgi varsa popup ona göre küçülsün, altta gereksiz
## devasa boşluk kalmasın"):
##   • ASGARİ boyut YOKTUR — kısa metinde kart küçük kalır.
##   • AZAMİ yükseklik ekranın yarısı VE imlecin üstündeki gerçek boşlukla sınırlıdır.
##   • Taşan içerik kart İÇİNDE kaydırılır (bilgi kesilmez), kart ekran dışına ÇIKMAZ.
##
## KONUM: kart HER ZAMAN imlecin ÜSTÜNDE açılır (kullanıcı isteği: "aşağısına inmesin, bu
## sayede tıklamada sorun yaşatmaz"). Bkz. `UIPlacement.vertical_slot_for`.
##
## TIKLAMA GEÇİRGENLİĞİ: kart sığıyorsa fare olaylarına tamamen ŞEFFAFTIR (altındaki butona
## tıklanabilir); kaydırılabilir hâle geldiyse olayları ALIR ki oyuncu üstüne gelip
## kaydırabilsin. Godot'ta `mouse_filter` MİRAS ALINMAZ — bkz. `UIPlacement.make_click_through`.
class_name InfoPopup
extends PanelContainer

@onready var _title: Label = %TitleLabel
@onready var _subtitle: Label = %SubtitleLabel
@onready var _divider: ColorRect = %Divider
@onready var _body: Label = %BodyLabel
@onready var _facts: GridContainer = %FactsGrid
@onready var _badges: HFlowContainer = %Badges
@onready var _sections: VBoxContainer = %Sections
@onready var _scroll: ScrollContainer = $Margin/Scroll

## Gecikmeli açılışı iptal edebilmek için (hover erken bittiyse).
var _hover_token: int = 0

## SARMASI AÇILIP KAPANACAK etiketler. Genişlik ölçümü sırasında hepsinde sarma kapatılır
## (bkz. `_size_and_place`), sonra geri açılır.
##
## ⚠ KÜNYE ANAHTARLARI ("Tur sınırı:") BU LİSTEDE YOKTUR — ve bu kritik. Godot'ta sarması AÇIK
## bir Label'ın ASGARİ GENİŞLİĞİ 1 px'dir. Anahtar etiketleri de sarmaya açılınca
## `GridContainer` sol sütuna 1 px veriyor, metin karakter başına bir satıra düşüyordu
## (kullanıcı bildirimi: "harfler alt alta olmuş, japon yazısı gibi" — ölçüldü:
## "Zafer koşulu:" → size=(1, 257)). Kısa anahtarların sarmaya İHTİYACI YOK; sarmasız
## kaldıklarında asgari genişlikleri gerçek metin genişliği olur ve sütun doğru ölçülür.
var _wrapping: Array[Label] = []

## Kartı açan öğe. İmleç kart ile bu öğe arasındaki boşluktan geçerken kart kapanmamalı.
var _anchor: Control = null
## Kart kaydırılabilir mi? (Kapanma sorumluluğu yalnız bu durumda karta geçer.)
var _scrollable := false
## İmlecin kart ve tetikleyici DIŞINDA geçirdiği süre (saniye).
var _outside_time := 0.0

## İmleç kartın dışına çıktıktan sonra kapanmadan önce beklenen süre.
##
## NEDEN VAR: kart imlecin `ANCHOR_GAP` kadar üstünde durur. Oyuncu fareyi karta doğru
## götürürken bu boşluktan geçer; gecikme olmasaydı kart tam o anda kapanır ve karta ULAŞMAK
## imkânsız olurdu.
const CLOSE_GRACE := 0.25

func _ready() -> void:
	top_level = true
	visible = false
	UIPlacement.make_click_through(self)
	set_process(true)

## KAPANMA KARARI SİNYALLE DEĞİL, YOKLAMAYLA verilir.
##
## ⚠ KÖK NEDEN (kullanıcı bildirimi: "popupların üstüne gidince otomatik kapanıyor, bu yüzden
## aşağı kaydıramıyorum"): kapanma `mouse_exited` sinyaline bağlıydı ve bu iki ayrı şekilde
## yanlış ateşleniyordu:
##   1. Kartın kökü `STOP` iken İÇİNDEKİ ScrollContainer da `STOP` olur. İmleç kökten çocuğa
##      geçtiği anda Godot köke `mouse_exited` gönderir — yani kart, oyuncu ÜSTÜNE GELİR
##      GELMEZ kendi kendini kapatıyordu.
##   2. Eski `is_mouse_over()` koruması `CanvasItem.get_global_mouse_position()` kullanıyordu;
##      bu CANVAS uzayındadır ve `top_level` bir Control ile `content_scale` altında
##      `get_global_rect()` uzayıyla EŞLEŞMEZ (1920x1080'de 1.25 ölçek farkı). Koruma bu yüzden
##      "fare üstünde değil" diyordu.
## Yoklama ikisini de atlatır: her karede GÖRÜNÜM koordinatında bakılır, kart VE tetikleyici
## birlikte değerlendirilir, aradaki boşluk için `CLOSE_GRACE` payı bırakılır.
func _process(delta: float) -> void:
	if not visible or not _scrollable:
		return
	if _mouse_inside(self) or _mouse_inside(_anchor):
		_outside_time = 0.0
		return
	_outside_time += delta
	if _outside_time >= CLOSE_GRACE:
		hide_popup()

## İmleç `ctl`in üstünde mi? İmleç GÖRÜNÜM (mantıksal) koordinatından okunur — kenetleme ve
## yerleştirme ile AYNI uzay (bkz. `UIPlacement.mouse_point`).
func _mouse_inside(ctl: Control) -> bool:
	if not is_instance_valid(ctl) or not ctl.is_visible_in_tree():
		return false
	return ctl.get_global_rect().has_point(UIPlacement.mouse_point(self))

# ─── GENEL API ────────────────────────────────────────────────────────────────

## Kartı `spec`e göre doldurup `anchor` hover'ı için HOVER GECİKMESİNDEN sonra gösterir.
## Gecikme bitmeden `hide_popup()` çağrılırsa (fare ayrıldı) açılış İPTAL edilir.
func show_spec(anchor: Control, spec: Dictionary) -> void:
	# ⚠ ÖNCE KAPAT: kullanıcı bildirimi "bir kartın üstünden diğerine geçince ESKİ KONUMDAKİ
	# popup açık kalıyor, sadece içindeki bilgi değişiyor". Kart değiştiğinde eskisi DERHAL
	# yok olmalı; yenisi gecikme dolduktan ve YENİ konumu hesaplandıktan sonra belirir.
	hide_popup()
	_anchor = anchor
	var token: int = _hover_token
	await get_tree().create_timer(UIPlacement.HOVER_DELAY).timeout
	if token != _hover_token or not is_instance_valid(anchor) or not anchor.is_visible_in_tree():
		return
	_populate(spec)
	await _size_and_place(token)

func hide_popup() -> void:
	_hover_token += 1   # bekleyen gecikmeli açılışı iptal et
	visible = false
	modulate.a = 1.0
	_scrollable = false
	_outside_time = 0.0

## Kapatmayı İSTER. Kullanıcı isteği: "üstüne gidince açık kalması lazım ki aşağı kaydırılabilsin."
##
## Tetikleyicinin `mouse_exited`ı `hide_popup()` yerine BUNU çağırmalı: kart KAYDIRILABİLİR
## durumdaysa kapanma kararı `_process` yoklamasınındır (oyuncu fareyi karta doğru götürüyor
## olabilir; doğrudan kapatmak kartı ulaşılamaz kılar). Kaydırılamayan kısa kartta okunacak
## fazladan bir şey yoktur — hemen kapanır.
func request_hide() -> void:
	if _scrollable:
		return
	hide_popup()

## Fare kartın üstünde mi? (Çağıranların "kapatayım mı" kararı için.)
func is_mouse_over() -> bool:
	return visible and _mouse_inside(self)

# ─── DOLDURMA ─────────────────────────────────────────────────────────────────

func _populate(spec: Dictionary) -> void:
	_wrapping.clear()

	_title.text = String(spec.get("title", ""))
	_wrapping.append(_title)

	var subtitle: String = String(spec.get("subtitle", ""))
	_subtitle.text = subtitle
	_subtitle.visible = subtitle.strip_edges() != ""
	if _subtitle.visible:
		_wrapping.append(_subtitle)

	var body: String = String(spec.get("body", ""))
	_body.text = body
	_body.visible = body.strip_edges() != ""
	if _body.visible:
		_wrapping.append(_body)

	_fill_facts(spec.get("facts", []))
	_fill_badges(spec.get("badges", []))
	_fill_sections(spec.get("sections", []))
	# Ayraç yalnız başlığın ALTINDA içerik varsa anlamlı.
	_divider.visible = _body.visible or _facts.visible or _badges.visible or _sections.visible

func _clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()

func _fill_facts(facts: Array) -> void:
	_clear(_facts)
	_facts.visible = not facts.is_empty()
	for f in facts:
		# ANAHTAR: sarma KAPALI (bkz. `_wrapping` notu) ve sütun genişliğini kendi metni belirler.
		var key_lbl := Label.new()
		# Ayraç bile lokalizasyondan: kodda görünür metin bırakılmaz (bazı dillerde iki nokta
		# öncesi boşluk gerekir, bazılarında ayraç hiç kullanılmaz).
		key_lbl.text = String(f.get("label", "")) + LocalizationManager.tr_t("FACT_LABEL_SUFFIX")
		key_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
		key_lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		key_lbl.add_theme_color_override("font_color", GothicThemeHelper.color("color_dim_text"))
		_facts.add_child(key_lbl)

		# DEĞER: kalan genişliği alır ve gerekirse sarar.
		var val_lbl := Label.new()
		val_lbl.text = String(f.get("value", ""))
		val_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		val_lbl.add_theme_color_override("font_color", GothicThemeHelper.color("color_parchment"))
		_facts.add_child(val_lbl)
		_wrapping.append(val_lbl)

func _fill_badges(badges: Array) -> void:
	_clear(_badges)
	_badges.visible = not badges.is_empty()
	for b in badges:
		var lbl := Label.new()
		lbl.text = String(b.get("text", ""))
		lbl.autowrap_mode = TextServer.AUTOWRAP_OFF   # rozetler kısa; sarmaları sütunu bozar
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.add_theme_font_size_override("font_size", 12)
		if b.has("color"):
			lbl.add_theme_color_override("font_color", b["color"])
		_badges.add_child(lbl)

func _fill_sections(sections: Array) -> void:
	_clear(_sections)
	_sections.visible = not sections.is_empty()
	for s in sections:
		var heading: String = String(s.get("heading", ""))
		if heading != "":
			var head := Label.new()
			head.text = heading
			head.mouse_filter = Control.MOUSE_FILTER_IGNORE
			head.add_theme_font_size_override("font_size", 13)
			head.add_theme_color_override("font_color",
				s.get("color", GothicThemeHelper.color("color_gold_bright")))
			_sections.add_child(head)
			_wrapping.append(head)
		var text: String = String(s.get("text", ""))
		if text != "":
			var body := Label.new()
			body.text = text
			body.mouse_filter = Control.MOUSE_FILTER_IGNORE
			body.add_theme_font_size_override("font_size", 12)
			body.add_theme_color_override("font_color", GothicThemeHelper.color("color_dim_text"))
			_sections.add_child(body)
			_wrapping.append(body)

# ─── BOYUTLANDIRMA + KONUMLANDIRMA ────────────────────────────────────────────

## Sarmayı YALNIZ sarması gereken etiketlerde açar/kapatır (genişlik ölçümü için).
func _set_wrap(on: bool) -> void:
	var mode := TextServer.AUTOWRAP_WORD_SMART if on else TextServer.AUTOWRAP_OFF
	for lbl in _wrapping:
		if is_instance_valid(lbl):
			lbl.autowrap_mode = mode

## Kaydırıcının DIŞINDA kalan sabit yükseklik (panel kenarlığı + Margin payları).
##
## ⚠ BU DEĞER `size.y - _scroll.size.y` İLE HESAPLANAMAZ. Ölçüm sırası şudur: önce sarma KAPALI
## ölçülür (kaydırıcı metnin tek satırlık GENİŞLİĞİNE kadar uzar — ölçüldü: 6534x1665), sonra
## sarma açılıp genişlik azamiye sabitlenir. O ikinci adımda `_scroll.size` HENÜZ BAYATTIR ve
## popup'ın kendisinden BÜYÜK olabilir; fark NEGATİF çıkar (-660 ölçüldü) ve tavan 345 yerine
## 1005 px'e ÇIKAR — kart ekranın dışına taşar. Asgari boyutlar ise yerleşimden değil temadan
## gelir; bayatlamazlar.
func _chrome_height() -> float:
	return maxf(0.0, get_combined_minimum_size().y - _scroll.get_combined_minimum_size().y)

## Yerleşim OTURANA KADAR bekler: `reset_size()` çağırıp boyut değişmeyi bırakana dek kare geçirir.
##
## ⚠ SABİT KARE SAYISI YETMEZ. Asgari boyut, sarma değiştiğinde Label → VBox → Scroll → Margin →
## PanelContainer zinciri boyunca KARE KARE yayılır; zincirin kaç kare süreceği içeriğe ve
## çözünürlüğe göre değişir. Tek kare beklemek, boyutu HENÜZ BÜYÜMEDEN okumaya yol açıyordu:
## kart 205 px sanılıp konumlandırılıyor, sonra 265 px'e uzayıp imlecin ALTINA taşıyordu; uzun
## faksiyon hikâyelerinde ise yükseklik denetimi tavanın altında kalıp kaydırma HİÇ açılmıyor,
## kart 603 px'e (ekranın yarısının çok üstüne) çıkıyordu. İkisi de ölçüldü.
func _settle(max_frames: int = 6) -> void:
	var last := Vector2(-1.0, -1.0)
	for _i in max_frames:
		reset_size()
		await get_tree().process_frame
		if size.is_equal_approx(last):
			return
		last = size

## İçeriğe göre boyutlandırır (azami sınırlarla), sonra imlecin ÜSTÜNE yerleştirir.
## `token`: açılış kimliği — bekleme sırasında hover bittiyse işlem iptal edilir.
func _size_and_place(token: int) -> void:
	var vp: Vector2 = get_viewport_rect().size
	# DİKEY YUVA: kart imlecin ÜSTÜNE açılır; yükseklik tavanı hem ekranın yarısı hem de
	# imlecin üstündeki GERÇEK boşlukla sınırlanır — kart ekran dışına taşmaz, taşan içerik
	# kart İÇİNDE kaydırılır (kullanıcı isteği).
	var slot: Dictionary = UIPlacement.vertical_slot_for(UIPlacement.mouse_point(self).y, vp)
	var limit := Vector2(UIPlacement.max_size_for(vp).x, slot["max_height"])

	# 1) GENİŞLİK — iki aşamalı ölçüm.
	#
	# ⚠ `autowrap` AÇIKKEN bir Label'ın ASGARİ genişliği 1 px'dir. Doğrudan `reset_size()`
	# çağırmak bu yüzden popup'ı ince bir şerite sıkıştırıp yüksekliği patlatıyordu
	# (ölçüm: 156x4140 px). Doğru yol:
	#   a) Sarmayı KAPAT → metnin doğal (tek satır) genişliğini ölç.
	#   b) Doğal genişlik azaminin ALTINDAysa onu kullan (kısa metinde kart dar kalır).
	#   c) Değilse sarmayı AÇ ve genişliği azamiye sabitle, yüksekliği ona göre ölç.
	custom_minimum_size = Vector2.ZERO
	_scroll.custom_minimum_size = Vector2.ZERO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_set_wrap(false)
	# ⚠ ÖLÇÜM SIRASINDA GÖRÜNMEZ KAL: Godot bir Control'ün boyutunu ancak ağaçta ve görünürken
	# çözer, ama ölçüm 2-3 KARE sürüyor. `visible = true` deyip konumu SONRA atamak, o karelerde
	# kartın HENÜZ KONUMLANMAMIŞ hâlde (0,0 — ekranın sol üstü) çizilmesine yol açıyordu;
	# kullanıcı bunu "popup sol üste sabit" olarak görüyordu. Çözüm: ölçüm boyunca saydam tut,
	# konum kesinleşince göster.
	modulate.a = 0.0
	visible = true
	size = Vector2.ZERO
	await _settle()
	if token != _hover_token:
		return

	if size.x > limit.x:
		_set_wrap(true)
		custom_minimum_size.x = limit.x
		size.x = limit.x
		await _settle()
		if token != _hover_token:
			return

	# 2) Yükseklik: azamiyi aşarsa iç kaydırma aç (bilgi kesilmesin).
	var scrollable := false
	if size.y > limit.y:
		_scroll.custom_minimum_size.y = maxf(60.0, limit.y - _chrome_height())
		# SHOW_ALWAYS (AUTO değil): burada içeriğin taştığını ZATEN biliyoruz ve oyuncunun
		# "devamı var" sinyalini görmesi gerekiyor (kullanıcı isteği: "kaydırma çubukları da
		# gözüksün ki devam ettiği anlaşılsın").
		_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
		scrollable = true
		await _settle()
		if token != _hover_token:
			return

	# Kaydırılabiliyorsa kart fare olaylarını ALIR (oyuncu üstüne gelip kaydırabilsin);
	# sığıyorsa tamamen ŞEFFAF kalır (altındaki butona tıklanabilsin).
	_scrollable = scrollable
	_outside_time = 0.0
	UIPlacement.set_interactive(self, scrollable, _scroll)
	UIPlacement.place_near_mouse(self, vp, slot["above"])
	modulate.a = 1.0   # konum kesinleşti, artık gösterilebilir
