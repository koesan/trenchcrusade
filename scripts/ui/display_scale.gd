## EKRAN ÖLÇEĞİ — arayüzün pencere çözünürlüğüne UYUM SAĞLAMASININ tek kaynağı.
##
## SORUN: `project.godot` 1280x720 taban çözünürlük + `stretch/mode = canvas_items` ile
## kurulmuştu ve `stretch/aspect` ayarlanmamıştı (varsayılan "keep"). Bunun anlamı: oyun 1920x1080
## çalıştırıldığında TÜM arayüz 1.5 kat BÜYÜTÜLÜYOR — mantıksal alan hâlâ 1280x720 kalıyordu.
## Yani daha büyük ekran daha fazla YER kazandırmıyor, sadece her şeyi kabalaştırıyordu; paneller
## ekranın orantısal olarak aynı (büyük) kısmını kaplamaya devam ediyordu.
##
## ÇÖZÜM — iki parça:
##   1. `project.godot`: `stretch/aspect = "expand"` → farklı en-boy oranlarında siyah bant yok,
##      fazladan genişlik mantıksal alana EKLENİR (ultra-wide ekranlar da doğru çalışır).
##   2. Bu sınıf: pencere boyutuna göre MANTIKSAL arayüz alanını (`content_scale_size`) yazar.
##      Arayüz büyütmesi çözünürlükle ORANTILI DEĞİL, ondan DAHA YAVAŞ artar — böylece yüksek
##      çözünürlükte hem daha çok mantıksal alan kazanılır hem yazılar okunaklı kalır:
##
##        1280x720  → büyütme 1.00 → mantıksal 1280x720   (taban)
##        1600x900  → büyütme 1.10 → mantıksal 1454x818
##        1920x1080 → büyütme 1.25 → mantıksal 1536x864   (+%20 alan, %25 daha büyük yazı)
##        2560x1440 → büyütme 1.60 → mantıksal 1600x900
##        3840x2160 → büyütme 2.40 → mantıksal 1600x900   (4K'da minik arayüz olmaz)
##
## Pencere yeniden boyutlandığında (ayarlardan çözünürlük değişimi, tam ekran geçişi, kullanıcının
## pencereyi sürüklemesi) OTOMATİK yeniden uygulanır — çağıranın bir şey yapması gerekmez.
class_name DisplayScale

## Arayüzün tasarlandığı taban yükseklik (project.godot viewport_height ile aynı olmalı).
const BASE_HEIGHT := 720.0

## (pencere yüksekliği, içerik ölçeği) kırılma noktaları. Aradaki değerler enterpole edilir.
## Ölçek yükseklikten DAHA YAVAŞ artar; fark, kazanılan mantıksal alandır.
const BREAKPOINTS := [
	Vector2(720.0, 1.00),
	Vector2(900.0, 1.10),
	Vector2(1080.0, 1.25),
	Vector2(1440.0, 1.60),
	Vector2(2160.0, 2.40),
]

static var _wired := false

## Kullanıcının ayarlardan seçtiği REFERANS ÇÖZÜNÜRLÜK. `Vector2i.ZERO` = seçim yok (pencere
## boyutu kullanılır).
##
## NEDEN VAR (kullanıcı bildirimi: "ayarlarda çözünürlük seçince hiçbir şey değişmiyor"):
## `_apply_resolution` YALNIZ pencereli modda `window_set_size` çağırıyordu; TAM EKRANDA hiçbir
## şey yapmıyordu. Ayrıca pencereli modda bile ayar sadece pencere boyutunu değiştiriyor, arayüz
## ölçeğini etkilemiyordu.
##
## Artık seçilen çözünürlük ARAYÜZÜN REFERANSIDIR: mantıksal alan ondan türetilir. Böylece ayar
## HER MODDA görünür bir fark yaratır — tam ekranda 1280x720 seçmek arayüzü büyütür, 2560x1440
## seçmek daha çok yer açar. Pencereli modda ayrıca pencere de o boyuta getirilir.
static var _reference_size := Vector2i.ZERO

## Ayarlardan gelen referans çözünürlüğü belirler (Vector2i.ZERO = otomatik/pencere boyutu).
static func set_reference_size(size: Vector2i, window: Window = null) -> void:
	_reference_size = size
	if window != null:
		apply(window)

## Verilen pencere yüksekliği için ARAYÜZ BÜYÜTME oranı. SAF fonksiyon (test edilebilir).
## 1.0 = 720p'deki fiziksel boyut. Kırılma noktaları arasında doğrusal enterpolasyon.
static func factor_for_height(height: float) -> float:
	if height <= BREAKPOINTS[0].x:
		return BREAKPOINTS[0].y
	var last: Vector2 = BREAKPOINTS[BREAKPOINTS.size() - 1]
	if height >= last.x:
		# 4K üstü: ölçeği yükseklikle orantılı sürdür (aksi hâlde 8K'da arayüz minicik kalır).
		return last.y * (height / last.x)
	for i in range(BREAKPOINTS.size() - 1):
		var a: Vector2 = BREAKPOINTS[i]
		var b: Vector2 = BREAKPOINTS[i + 1]
		if height <= b.x:
			var t: float = (height - a.x) / (b.x - a.x)
			return lerpf(a.y, b.y, t)
	return last.y

## Verilen pencere boyutu için MANTIKSAL arayüz alanı (piksel değil, düzen birimi).
## SAF fonksiyon — testler bunu doğrudan sınayabilir.
##
## `mantıksal = pencere / büyütme`. Büyütme çözünürlükten YAVAŞ arttığı için mantıksal alan da
## artar: 1080p'de 1536x864 (720p'ye göre +%20 alan) ama arayüz öğeleri %25 daha büyük çizilir.
static func logical_size_for(window_size: Vector2i) -> Vector2i:
	var f: float = factor_for_height(float(window_size.y))
	if f <= 0.0:
		return window_size
	return Vector2i(roundi(float(window_size.x) / f), roundi(float(window_size.y) / f))

## Pencerenin şu anki boyutuna göre arayüz ölçeğini uygular.
##
## ⚠ `content_scale_factor` DEĞİL `content_scale_size` kullanılır. `canvas_items` germe kipinde
## Godot mantıksal alanı proje ayarındaki taban boyuttan (1280x720) alır ve `content_scale_factor`
## bunu BÖLER — yani factor'ü büyütmek alanı KÜÇÜLTÜR (ilk denemede tam bu yaşandı: 1080p'de
## mantıksal alan 1280x720 yerine 1024x576'ya düştü ve paneller sığmaz oldu). Mantıksal alanı
## doğrudan yazmak için `content_scale_size` ayarlanmalıdır.
static func apply(window: Window) -> void:
	if window == null or window.size.y <= 0:
		return
	# Referans seçilmişse ARAYÜZ ONA GÖRE ölçeklenir (pencere boyutundan bağımsız) — böylece
	# ayar tam ekranda da işe yarar. Seçim yoksa pencerenin gerçek boyutu kullanılır.
	var basis: Vector2i = _reference_size if _reference_size.y > 0 else window.size
	window.content_scale_size = logical_size_for(basis)

## Ölçeği uygular VE pencere yeniden boyutlandığında kendini yenilemesi için bağlanır.
## Birden fazla kez çağrılması güvenlidir (yalnız ilk çağrı bağlantı kurar) — her UI sahnesi
## `GothicThemeHelper.init_ui()` üzerinden bunu çağırır, yani hangi sahneden başlanırsa
## başlansın ölçek doğru olur.
static func ensure_applied(window: Window) -> void:
	if window == null:
		return
	apply(window)
	if _wired:
		return
	_wired = true
	window.size_changed.connect(func(): apply(window))
