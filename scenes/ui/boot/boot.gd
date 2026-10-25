extends Control

## AÇILIŞ — oyun açılır açılmaz yükleme ekranı (logo + ilerleme çubuğu) görünür; ana menü ve
## tüm faksiyonların birim modelleri arka planda yüklenir, sonra ekran solarak ana menüye geçer.
## Böylece ilk pencere boş/donuk kalmaz ve menüden savaşa geçiş, kadro önizlemeleri takılmaz.

const MAIN_MENU := "res://scenes/ui/main_menu/main_menu.tscn"

func _ready() -> void:
	LoadingManager.load_scene(MAIN_MENU, LoadingManager.unit_model_paths())
