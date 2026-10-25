## ARAYÜZ KATMANI (OVERLAY) TABAN SINIFI — `OverlayManager`in yönettiği her panel bunu türetir.
##
## NEDEN VAR: `OverlayManager.open_overlay()` her açılışta `open_panel()` kancasını çağırıyordu
## ama bu bir SÖZLEŞME değil, bir `has_method()` tahminiydi — 9 overlay'den yalnız 3'ü uyguluyordu.
## Uygulamayanlar içeriğini SADECE `_ready()`de (HUD kurulurken, henüz hiçbir birim
## yerleştirilmeden ÖNCE) doldurup bir daha asla yenilemiyordu; savaş ortasında açılan panel
## "bayat/boş" görünüyordu. Bu, projede DÖRT KEZ tekrar eden bir bug sınıfıydı.
## Artık kanca taban sınıfta tanımlı: yeni bir overlay yazarken unutulması İMKÂNSIZ.
##
## Ayrıca her overlay'de birebir tekrarlanan lokalizasyon bağlama kalıbı buraya alındı:
##     if not Engine.is_editor_hint():
##         LocalizationManager.locale_changed.connect(update_locale)
##         update_locale()
##
## ALT SINIF SÖZLEŞMESİ — `_ready()`i EZME, bunun yerine:
##   `_bind_controls()` : düğüm/sinyal bağlantılarını kur (bir kez, kurulumda).
##   `update_locale()`  : tüm metinleri yerelleştirme anahtarlarından yaz (dil değişiminde de).
##   `open_panel()`     : DİNAMİK içeriği tazele (HER açılışta çağrılır) — liste/sayı/durum.
##   `close_panel()`    : kapanışta temizlik (nadiren gerekir).
##
## `@onready var` alanları alt sınıfta güvenle kullanılabilir: Godot bunları taban sınıfın
## `_ready()`i çalışmadan ÖNCE atar (ampirik olarak doğrulandı).
class_name OverlayPanel
extends CenterContainer

## ARKA PLAN KARARTMASI: panel açıkken arkadaki savaş alanı/HUD karartılır — panel öne çıkar,
## oyuncu modal bir ekranda olduğunu anlar. Eskiden overlay'ler doğrudan haritanın üstünde
## duruyor, metinleri arkadaki ayrıntıyla karışıyordu (2026-10-23 görsel denetim).
## Kök CenterContainer zaten tam ekran olduğu için ek düğüm gerekmez.
func _draw() -> void:
	ModalBackdrop.paint(self)

## Panelin "Geri/Kapat" düğmesi. `game_hud` bunu `OverlayManager.go_back`e bağlar.
## Tek yerde tanımlı olduğu için her overlay'de yeniden bildirilmesi GEREKMEZ.
signal close_pressed

func _ready() -> void:
	_bind_controls()
	if not Engine.is_editor_hint():
		LocalizationManager.locale_changed.connect(update_locale)
		update_locale()

## Düğüm/sinyal bağlantıları. Kurulumda BİR KEZ çağrılır.
func _bind_controls() -> void:
	pass

## Tüm görünür metinleri yerelleştirme anahtarlarından yazar. Kurulumda ve her dil
## değişiminde çağrılır. Parametre `LocalizationManager.locale_changed` imzasından gelir.
func update_locale(_new_lang: String = "") -> void:
	pass

## Panel HER açıldığında çağrılır — dinamik içeriği (listeler, sayılar, seçili birim) tazele.
func open_panel() -> void:
	pass

## Panel kapanırken çağrılır. Temizlik/durdurma gerektiren paneller için.
func close_panel() -> void:
	pass
