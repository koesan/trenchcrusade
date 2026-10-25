## Faksiyon kataloğu — oyundaki tüm oynanabilir faksiyonların TEK KAYNAĞI.
##
## Yeni faksiyon eklemek için: (1) yeni bir FactionData `.tres` oluştur,
## (2) bu manifest'in `factions` dizisine editörden sürükle-bırak ekle. **Kod değişmez.**
##
## Dizinin sırası UI'da faksiyonların gösterim sırasını belirler (belirleyici — klasör
## taramasına göre daha güvenilir ve export/.pck'de sorun çıkarmaz).
class_name FactionManifest
extends Resource

@export var factions: Array[FactionData] = []
