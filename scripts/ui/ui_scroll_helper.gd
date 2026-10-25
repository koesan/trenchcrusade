## UIScrollHelper — "N öğeden sonra kaydır" davranışının TEK kaynağı.
##
## SORUN (kullanıcı bildirimi): uzayabilen listeler sınırsız büyüyünce diğer HUD öğelerinin
## üstüne biniyordu — bir birimin yetenek sayısı arttıkça eylem butonları paneli aşağı/yukarı
## taşıyor, faksiyon birim listesi ekranı dolduruyordu.
##
## ÇÖZÜM: listeye bir YÜKSEKLİK/GENİŞLİK TAVANI konur; tavanı aşan öğelere kaydırma çubuğuyla
## erişilir. Üç panel de aynı yardımcıyı kullanır (DRY) — böylece "kaç öğe görünsün" kararı
## tek yerde ve tutarlı olur.
class_name UIScrollHelper

## ⚠ SABİT ÖĞE TAVANLARI ÇÖZÜNÜRLÜĞÜ GÖRMEZ. Eylem butonlarının `MAX_VISIBLE_ACTIONS = 5` ve
## birim kartlarının `MAX_VISIBLE_UNIT_CARDS = 4` tavanları bu yüzden KALDIRILDI: 720p'de
## panelin yarısını kaplıyor, 2160p'de küçücük bir şerit bırakıyorlardı. Yerlerini oransal
## tavanlar aldı (`cap_to_half`, `fit_count_half`) — bkz. `HALF_SCREEN`.
##
## Aynı anda görünecek en fazla faksiyon birimi (Cephanelik'teki dikey liste). Bu liste sabit
## yükseklikli bir panelin İÇİNDE olduğu için ekran oranına değil panele bağlıdır.
const MAX_VISIBLE_UNITS := 6

## N öğenin toplam uzunluğu (öğe boyu + aralardaki boşluklar). SAF fonksiyon.
static func content_height(item_height: float, count: int, separation: float) -> float:
	if count <= 0:
		return 0.0
	return item_height * float(count) + separation * float(count - 1)

## Tavanla sınırlanmış uzunluk: `max_visible` öğeden fazlası kaydırmaya düşer. SAF fonksiyon.
static func capped_height(item_height: float, count: int, max_visible: int,
		separation: float) -> float:
	return content_height(item_height, mini(count, max_visible), separation)

## Bir ScrollContainer'ı içeriğe göre DİKEY boyutlar ve gerektiğinde kaydırmayı açar.
## Tavana ulaşılmadıysa kaydırma kapalı kalır (gereksiz çubuk gösterilmez).
##
## NOT: `SCROLL_MODE_AUTO` çubuğu yalnız içerik taştığında gösterir — yani çubuğun VARLIĞI
## "devamı var" sinyalidir. Çubuğun kendisi uzun süre GÖRÜNMÜYORDU çünkü tema stillerinde
## kalınlık (content_margin) tanımlı değildi; bu `gothic_theme_builder.gd` 14. bölümde
## düzeltildi. Buradaki mantık doğruydu.
static func apply_max_visible(scroll: ScrollContainer, item_height: float, count: int,
		max_visible: int, separation: float) -> void:
	if scroll == null or not is_instance_valid(scroll):
		return
	scroll.custom_minimum_size.y = capped_height(item_height, count, max_visible, separation)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS if count > max_visible \
		else ScrollContainer.SCROLL_MODE_DISABLED
	if count > max_visible:
		DragScroll.attach(scroll)

## Bir listenin kaplayabileceği en fazla ORAN (görüntü alanına göre).
##
## Kullanıcı isteği: "birim kartları o an ekranın GENİŞLİĞİNİN YARISI kadar olsun, geçerse
## kaydırma çubuğuyla sağa kaydırılsın — böylece ekranın altı kartlarla dolmaz. Butonlarda da
## aynı: o an ekran YÜKSEKLİĞİNİN YARISI, fazlası kaydırmayla."
##
## Sabit bir piksel tavanı DEĞİL, oran: 1280x720'de de 3840x2160'ta da ekranın yarısı.
const HALF_SCREEN := 0.5

## EYLEM BUTONU panelinin tavanı — ekran yüksekliğinin ÜÇTE BİRİ.
##
## Şeritten daha dar tutulur (kullanıcı isteği: "butonları ekran yüksekliğinin yarısından üçte
## birine düşür"): buton paneli sağ ALTTA dikey durur ve yarım ekran yüksekliğinde savaş
## alanının görünür kısmını ciddi biçimde kapatıyordu.
const ACTION_PANEL_RATIO := 1.0 / 3.0

## `available`ı ekranın verilen ORANIYLA da sınırlar. İki sınır da geçerlidir: kardeş panellerin
## bıraktığı gerçek boşluk VE ekran oranı — hangisi küçükse o.
static func cap_to_ratio(available: float, viewport_extent: float, ratio: float) -> float:
	return minf(available, viewport_extent * ratio)

## `cap_to_ratio`nun ekranın YARISI için kısayolu (birim kartı şeridi).
static func cap_to_half(available: float, viewport_extent: float) -> float:
	return cap_to_ratio(available, viewport_extent, HALF_SCREEN)

## Ekranın verilen oranına kaç TAM öğe sığar? (Dikey liste için `item_height`, yatay için genişlik.)
static func fit_count_ratio(viewport_extent: float, item_extent: float, separation: float,
		ratio: float) -> int:
	return fit_count(viewport_extent * ratio, item_extent, separation)

## `fit_count_ratio`nun ekranın YARISI için kısayolu.
static func fit_count_half(viewport_extent: float, item_extent: float, separation: float) -> int:
	return fit_count_ratio(viewport_extent, item_extent, separation, HALF_SCREEN)

## YATAY listeler (birim kartları şeridi) için: genişliği TAM kart sayısına yuvarlar.
## Kullanıcı bildirimi: "4.5 tane unit gösteriliyor" — yarım kart hem çirkin hem yanıltıcı.
## Döndürür: tam kart sayısına karşılık gelen genişlik.
static func snap_to_whole_items(item_width: float, count: int, max_visible: int,
		separation: float) -> float:
	return capped_height(item_width, count, max_visible, separation)

## KULLANILABİLİR GENİŞLİĞE kaç TAM öğe sığar? SAF fonksiyon.
##
## Kullanıcı bildirimi: "unit kısmı ekran boyunca uzanabilsin... ekran taşacağı zaman kaydırma
## olsun; şu anda 1920x1080'de ekranın yarısını kaplıyor ama scroll bar var, bu olmamalı."
## KÖK NEDEN: görünür kart sayısı SABİT bir tavandı (4) — ekran genişliğine hiç bakmıyordu, bu
## yüzden geniş ekranda şerit gereksiz yere kısa kalıyor ve kaydırma çubuğu çıkıyordu.
static func fit_count(available_width: float, item_width: float, separation: float) -> int:
	if item_width <= 0.0:
		return 1
	# n öğe = n*item + (n-1)*sep  ≤  available  →  n ≤ (available + sep) / (item + sep)
	return maxi(1, int(floor((available_width + separation) / (item_width + separation))))

## Yatay şeridi KULLANILABİLİR GENİŞLİĞE göre boyutlar: sığdığı kadar TAM kart gösterir,
## taşarsa kaydırma açılır. Sabit bir kart tavanı YOKTUR — ekran ne kadar genişse o kadar kart.
static func fit_horizontal(scroll: ScrollContainer, item_width: float, count: int,
		separation: float, available_width: float) -> void:
	if scroll == null or not is_instance_valid(scroll):
		return
	var visible_count: int = mini(count, fit_count(available_width, item_width, separation))
	scroll.custom_minimum_size.x = snap_to_whole_items(item_width, count, visible_count, separation)
	# SHOW_ALWAYS (AUTO değil): taşma olduğunu ZATEN biliyoruz ve oyuncunun "devamı var"
	# sinyalini görmesi gerekiyor (kullanıcı isteği: "kaydırma çubukları da gözüksün ki devam
	# ettiği anlaşılsın; yatay olanlar yatay, dikey olanlar dikey").
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS if count > visible_count \
		else ScrollContainer.SCROLL_MODE_DISABLED
	if count > visible_count:
		DragScroll.attach(scroll)

## Yatay bir ScrollContainer'ı SABİT bir kart tavanına oturtur ve gerekiyorsa kaydırmayı açar.
## (Ekran genişliğine duyarlı davranış için `fit_horizontal` tercih edilir.)
static func apply_horizontal(scroll: ScrollContainer, item_width: float, count: int,
		max_visible: int, separation: float) -> void:
	if scroll == null or not is_instance_valid(scroll):
		return
	scroll.custom_minimum_size.x = snap_to_whole_items(item_width, count, max_visible, separation)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if count > max_visible \
		else ScrollContainer.SCROLL_MODE_DISABLED
