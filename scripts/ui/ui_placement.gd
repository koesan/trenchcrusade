## POPUP KONUMLANDIRMA — "tetikleyicinin üstünde aç, ekrana kenetle" davranışının TEK kaynağı.
##
## Bu projede birden fazla hover kartı var (birim profili, senaryo künyesi) ve hepsi AYNI kuralı
## izlemeli: kart, hover edilen öğenin TAM ÜSTÜNDE açılır (öğenin kendisini ya da altındaki
## butonları örtmez) ve asla ekran dışına taşmaz. Kural iki yerde ayrı ayrı yazılmıştı; buraya
## toplandı.
##
## YÜKSEKLİK KURALI: kart ekrana sığmıyorsa yalnız KONUMU kenetlemek YETMEZ — kart y=kenar payına
## oturur ama alt kısmı ekranın dışında kalır, yani bilgi görünmez. Bu yüzden çağıranın önce
## kartın yüksekliğini sınırlaması (ve taşan içeriği kendi içinde kaydırılabilir yapması) gerekir;
## `available_height()` bunun için kullanılabilir yüksekliği verir.
class_name UIPlacement

## Ekran kenarına bırakılan asgari pay.
const SCREEN_MARGIN := 8.0
## Tetikleyici ile popup arasındaki boşluk.
const ANCHOR_GAP := 10.0

## BÜYÜK hover bilgi kartlarının (birim profili, senaryo künyesi) açılma gecikmesi (saniye).
##
## Bu değer önce 3.0 idi (gerekçe: anında açılan kartlar fareyi gezdirirken sürekli parlıyordu).
## Kullanıcı bildirimi bunun ÇOK uzun olduğunu gösterdi: faksiyon ve senaryo kartlarının bilgi
## popup'ı ZATEN VARDI ama 3 saniye bekleyen hiç kimse onu görmediği için "popup yok" olarak
## rapor edildi. 0.5 sn hem gezinme parıltısını engelliyor hem de kartı keşfedilebilir kılıyor.
const HOVER_DELAY := 0.5

## KÜÇÜK tooltip'lerin (yetenek butonu açıklaması) gecikmesi. Bilerek daha kısa: küçük bir
## tooltip ekranı kapatmaz ve hızlı başvuru içindir; büyük kartla aynı 3 sn'yi beklemek
## kullanışsız olurdu. İkisi de tek yerden ayarlanabilsin diye burada.
const TOOLTIP_DELAY := 0.4

## Popup'ın kaplayabileceği en fazla ORAN (görüntü alanına göre). İçerik bundan küçükse popup da
## küçük kalır — sabit bir asgari boyut YOKTUR (kullanıcı isteği: "boş kısımlar olmasın,
## minimum ölçek içeriğe göre olsun").
##
## ⚠ BU ORANLAR "SOL ÜSTE SABİT" ŞİKÂYETİNİN KÖK NEDENİYDİ. Eski değerler 0.42 × 0.72 idi.
## Faksiyon hikâyeleri 1200 karaktere kadar çıkıyor; kart o oranlarda 1280x720 ekranda
## 537x518 px (ekranın %72'si) ölçülüyordu. Bu boyutta kart imlecin YANINA FİZİKSEL OLARAK
## SIĞMIYOR, `position_near_point` her seferinde ekran kenarına kenetliyor ve kart imleç nerede
## olursa olsun (8, 10) — yani sol üst köşe — konumuna düşüyordu. Konumlandırma matematiği
## doğruydu; kart fazla büyüktü. Kartı küçültmeden konumu düzeltmek mümkün değil.
## Kullanıcı isteği: "maximum uzunluk ekran ölçeğinin yüksekliğinin YARISI kadar olsun,
## fazlası kaydırılarak indirilebilsin."
const MAX_WIDTH_RATIO := 0.30
const MAX_HEIGHT_RATIO := 0.50

## Bir hover kartının "hâlâ işe yarar" sayıldığı en küçük yükseklik.
##
## Kart KURAL OLARAK imlecin üstünde açılır (bkz. `vertical_slot_for`). Tek istisna: imleç
## ekranın en tepesindeyken üstte bundan az yer kalır — o boyutta bir kart tek satır bile
## gösteremeyeceği için alta düşmek, hiçbir şey göstermemekten iyidir.
const MIN_USABLE_HEIGHT := 120.0

## Popup'ın bu görüntü alanında kaplayabileceği en fazla boyut.
static func max_size_for(viewport_size: Vector2) -> Vector2:
	return Vector2(viewport_size.x * MAX_WIDTH_RATIO, viewport_size.y * MAX_HEIGHT_RATIO)

## Bir popup'ı ve TÜM alt düğümlerini fare olaylarına ŞEFFAF yapar.
##
## KÖK NEDEN (kullanıcı bildirimi: "popup yüzünden bir butona tıklayamıyorum"): Godot'ta
## `mouse_filter` MİRAS ALINMAZ. Popup'ın KÖKÜNE `MOUSE_FILTER_IGNORE` vermek yetmez — içindeki
## `PanelContainer`/`MarginContainer`/`VBoxContainer` gibi düğümler varsayılan olarak
## `MOUSE_FILTER_STOP` taşır ve altlarındaki butonu ÖRTER. Hover kartı bilgi amaçlıdır, hiçbir
## tıklamayı yakalamamalıdır.
static func make_click_through(root: Node) -> void:
	if root is Control:
		(root as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in root.get_children():
		make_click_through(child)

## Bir popup'ın kaplayabileceği en fazla yükseklik (iki kenar payı düşülmüş).
static func available_height(viewport_size: Vector2) -> float:
	return maxf(0.0, viewport_size.y - 2.0 * SCREEN_MARGIN)

## Bir popup'ı SERBEST konumlandırılabileceği bir ebeveyne ekler ve düğümü döndürür.
##
## KÖK NEDEN (kullanıcı bildirimi: "popup hâlâ sol üste sabit duruyor"): popup'lar
## `CenterContainer` olan panel köklerine `add_child` ediliyordu. Godot'ta bir **Container**
## HER YERLEŞİM GEÇİŞİNDE çocuklarının konumunu VE boyutunu zorla ayarlar (`fit_child_in_rect`);
## `top_level = true` bile bunu engellemez. Sonuç: `global_position` ataması bir sonraki karede
## container tarafından EZİLİYOR ve kart panelin dayattığı yerde (sol üst) kalıyordu.
##
## Çözüm: popup, Container OLMAYAN en yakın üst düğüme eklenir (tipik olarak HUD'un CanvasLayer'ı).
static func attach_popup(owner: Node, popup: Control) -> Control:
	var host: Node = owner
	while host != null and host is Container:
		host = host.get_parent()
	if host == null:
		host = owner            # güvenli geri düşüş (hiç Container-olmayan ata yoksa)
	host.add_child(popup)
	return popup

## Popup'ı FARE İMLECİNİN biraz ÜSTÜNE yerleştirir ve görüntü alanına kenetler.
##
## Kullanıcı isteği: "popuplar sabit bir konumda açılmasın, bastığın yerin yakınında açılsın;
## mausun biraz üstünde açılsın daha iyi olur."
##
## NEDEN ANCHOR DEĞİL DE FARE: hover kartları bir ızgaranın/şeridin herhangi bir öğesinden
## açılabiliyor; anchor'a göre konumlandırmak kartı bazen ekranın uzak bir köşesine atıyordu
## (kullanıcı bildirimi: "sol üste sabit"). İmleç, oyuncunun BAKTIĞI yerdir — kart oraya gelir.
##
## `gap`: imleç ile popup'ın ALT kenarı arasındaki boşluk. İmleci ÖRTMEZ, böylece altındaki
## öğe görünür kalır ve tıklanabilir.
static func place_near_mouse(popup: Control, viewport_size: Vector2, above: bool = true,
		gap: float = ANCHOR_GAP) -> void:
	if not is_instance_valid(popup):
		return
	popup.global_position = position_near_point(
		mouse_point(popup), popup.size, viewport_size, above, gap)

## Kenetleme uzayıyla BİREBİR eşleşen imleç konumu.
##
## ⚠ `CanvasItem.get_global_mouse_position()` düğümün CANVAS DÖNÜŞÜMÜNE göre hesaplar —
## `top_level` bir Control, CanvasLayer içi ve `content_scale_size` ile ölçeklenmiş bir
## görünümde bu değer `get_visible_rect()` uzayıyla AYNI olmayabilir; sonuç popup'ın sol üste
## kenetlenmesiydi. `Viewport.get_mouse_position()` tartışmasız GÖRÜNÜM (mantıksal)
## koordinatındadır (ölçüldü: 1920x1080 pencerede 1.25 ölçekle 1400px → 1120 mantıksal).
static func mouse_point(node: CanvasItem) -> Vector2:
	return node.get_viewport().get_mouse_position()

## İmlecin ETRAFINDA bir hover kartına ayrılabilecek DİKEY YUVA: hangi tarafa açılacağı ve
## o tarafta kartın kullanabileceği EN FAZLA yükseklik.
##
## Kullanıcı isteği: "popup ekranda mausun YUKARISINDA olsun, aşağısına inmesin — bu sayede
## tıklamada sorun yaşatmaz. Mausun üstünde gidecek fazla alan kalmadıysa ekranın dışına
## TAŞMASIN, o zaman scroll bar ile kaydırma olsun."
##
## İki sonuç:
##   • TARAF: kart daima ÜSTTE. Kart imlecin altına inerse tıklamak üzere olduğun şeyi örter;
##     üstte açıldığında imleç ve hedefi serbest kalır. Tek istisna, imleç ekranın tepesine
##     dayandığında üstte `MIN_USABLE_HEIGHT` kadar yer bile kalmamasıdır.
##   • YÜKSEKLİK: tavan hem ekranın yarısı hem de o taraftaki GERÇEK boşluk ile sınırlanır —
##     bu yüzden kart asla ekran dışına taşmaz; taşan içerik kartın İÇİNDE kaydırılır.
##
## Çağıran kartı bu tavana göre boyutlar (taşarsa iç kaydırma açar), sonra `position_near_point`e
## AYNI tarafı verir. Sıra önemli — önce boyut, sonra konum; aksi hâlde kenetleme yanlış boyutla
## yapılır ve kart hesaplanmadığı tarafa taşar.
##
## Dönüş: { "above": bool, "max_height": float }
static func vertical_slot_for(mouse_y: float, viewport_size: Vector2,
		gap: float = ANCHOR_GAP) -> Dictionary:
	var room_above: float = maxf(0.0, mouse_y - gap - SCREEN_MARGIN)
	var room_below: float = maxf(0.0, viewport_size.y - mouse_y - gap - SCREEN_MARGIN)
	var above: bool = room_above >= MIN_USABLE_HEIGHT
	var room: float = room_above if above else room_below
	return {
		"above": above,
		"max_height": minf(viewport_size.y * MAX_HEIGHT_RATIO, room),
	}

## `place_near_mouse`in SAF çekirdeği — test edilebilir olsun diye ayrıldı.
## `point` etrafında, `size` boyutundaki bir kutunun ekrana kenetlenmiş sol-üst konumunu verir.
## `above`: kutu noktanın ÜSTÜNE mi (true) yoksa ALTINA mı (false) yerleşsin.
static func position_near_point(point: Vector2, size: Vector2, viewport_size: Vector2,
		above: bool = true, gap: float = ANCHOR_GAP) -> Vector2:
	# Yatayda noktaya ortala.
	var x: float = point.x - size.x * 0.5
	var y: float = point.y - size.y - gap if above else point.y + gap
	return Vector2(
		clampf(x, SCREEN_MARGIN, maxf(SCREEN_MARGIN, viewport_size.x - size.x - SCREEN_MARGIN)),
		clampf(y, SCREEN_MARGIN, maxf(SCREEN_MARGIN, viewport_size.y - size.y - SCREEN_MARGIN)))

## Popup'ın fare etkileşimini içeriğe göre ayarlar.
##
## İKİ İSTEK ÇATIŞIYORDU: "popup butona tıklamama engel olmasın" ve "üstüne gidince açık kalsın
## ki aşağı kaydırılabilsin". Çözüm içeriğe bağlı:
##   • İçerik SIĞIYORSA → kart tamamen ŞEFFAF; hiçbir tıklamayı yakalamaz (küçük kartlar zaten
##     kaydırılacak bir şey içermez).
##   • İçerik TAŞIYORSA (kaydırma çubuğu var) → kart fare olaylarını ALIR; oyuncu üstüne gelip
##     tekerlekle kaydırabilir. Bu durumda kart zaten büyük ve bilinçli olarak incelenen bir
##     nesnedir, tıklamayı "engellemesi" beklenen davranıştır.
## `scroll`: kartın iç kaydırıcısı. Kaydırılabilir durumda ONUN DA fare olaylarını alması
## ŞARTTIR — aksi hâlde tekerlek kartın köküne çarpıp orada tükenir.
##
## ⚠ KÖK NEDEN (kullanıcı bildirimi: "popuplardaki kaydırma işe yaramıyor, aşağı kaydıramıyorum"):
## `make_click_through` kartın TÜM alt düğümlerini — ScrollContainer dâhil — `MOUSE_FILTER_IGNORE`
## yapıyor. Yalnız KÖKÜ `STOP`a çevirmek yetmiyordu: tekerlek olayı kökte yakalanıyor,
## kaydırıcıya HİÇ ulaşmıyordu. Kaydırma çubuğu görünüyor ama hiçbir şey kaydırmıyordu.
static func set_interactive(popup: Control, scrollable: bool, scroll: ScrollContainer = null) -> void:
	if not is_instance_valid(popup):
		return
	if scrollable:
		popup.mouse_filter = Control.MOUSE_FILTER_STOP
		if is_instance_valid(scroll):
			scroll.mouse_filter = Control.MOUSE_FILTER_STOP
			# Sürükleyerek kaydırma (sol/orta tuş) — tekerleği olmayan fareler ve dokunmatik
			# yüzeyler için de çalışsın (kullanıcı isteği).
			DragScroll.attach(scroll)
	else:
		make_click_through(popup)

## `popup`u `anchor`ın ÜSTÜNE yerleştirir ve görüntü alanına kenetler.
##
## `align_center`: true ise yatayda anchor'a göre ORTALANIR (senaryo kartları gibi ızgara
## öğeleri için doğru), false ise anchor'ın SOL kenarıyla hizalanır (alt şeritteki birim
## kartları için — kart sırası boyunca zıplamayı önler).
## Üstte yeterli yer yoksa popup anchor'ın ALTINA düşer.
static func place_above(popup: Control, anchor: Control, viewport_size: Vector2,
		align_center: bool = false) -> void:
	if not is_instance_valid(popup) or not is_instance_valid(anchor):
		return
	var sz: Vector2 = popup.size
	var a: Rect2 = anchor.get_global_rect()

	var x: float = a.position.x
	if align_center:
		x = a.position.x + a.size.x * 0.5 - sz.x * 0.5

	var y: float = a.position.y - sz.y - ANCHOR_GAP
	if y < SCREEN_MARGIN:
		var below: float = a.end.y + ANCHOR_GAP
		# Alta ancak GERÇEKTEN sığıyorsa düş; sığmıyorsa üstte kalıp kenetlenmek daha az kötüdür
		# (en azından kartın BAŞLIĞI görünür durumda kalır).
		if below + sz.y <= viewport_size.y - SCREEN_MARGIN:
			y = below

	popup.global_position = Vector2(
		clampf(x, SCREEN_MARGIN, maxf(SCREEN_MARGIN, viewport_size.x - sz.x - SCREEN_MARGIN)),
		clampf(y, SCREEN_MARGIN, maxf(SCREEN_MARGIN, viewport_size.y - sz.y - SCREEN_MARGIN)))
