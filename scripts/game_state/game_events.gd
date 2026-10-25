extends Node

## Global sinyal bus'ı (Event Bus).
## Farklı sistemler arasında gevşek bağlantılı (loose coupling) iletişim sağlar.
## Bir sistemin diğer sistemlerin varlığını bilmesine gerek kalmadan olay yayınlamasına
## ve dinlemesine olanak tanır.
##
## Kullanım: GameEvents.unit_spawned.emit(unit)
## Dinleme: GameEvents.unit_spawned.connect(_on_unit_spawned)

## Birim olayları
signal unit_spawned(unit: Node3D)
signal unit_destroyed(unit: Node3D)

## Savaş olayları
signal damage_dealt(attacker: Node3D, target: Node3D, amount: int)
signal unit_killed(killer: Node3D, victim: Node3D)

## Oyun aşaması olayları
signal phase_changed(new_phase: int)

## Tur olayları
signal turn_started(player_id: int, turn_number: int)
signal turn_ended(player_id: int)

## Yerleşim olayları
signal deployment_started()
signal all_units_deployed()

## Yerleşim reddedildiğinde (sebep lokalizasyon anahtarı) — HUD kısa bir toast gösterir.
## Böylece "birimi yerleştiremiyorum, neden belli değil" durumu ortadan kalkar.
signal deploy_rejected(reason_key: String)

## Hareket/tırmanma reddedildiğinde (sebep lokalizasyon anahtarı) — HUD kısa bir toast gösterir.
## Örn. "Yukarı çıkmak için yeterli hareket yok" (compendium: tüm yüzeyi geçecek hareket gerekir).
signal move_rejected(reason_key: String)

## Bir yetenek/büyü sessizce sonuçsuz kaldığında (sebep lokalizasyon anahtarı) — HUD kısa bir
## toast gösterir. Örn. Goetic Spell'in ödeyecek Kan İşareti yok, Slavemaster Command'ın hedefi/
## silahı yok, Teleport hedefi NavMesh dışı. deploy_rejected/move_rejected ile AYNI desen —
## "butona bastım, zar attı ama hiçbir şey olmadı, neden belli değil" sınıfını kapatır.
signal ability_rejected(reason_key: String)

## Hazır (lokalize edilmiş) metinli bildirim — kind: "warn" | "info". Ör. seçim engeli
## ("Önce X'in aktivasyonunu bitir"), sıra hatırlatması. HUD bildirim akışında gösterir.
signal notice_posted(text: String, kind: String, title: String)

## Ağ olayları
signal player_joined(player_id: int, player_name: String)
signal player_left(player_id: int, player_name: String)

## Oyun sonu olayları
signal game_over(winner_id: int)


## ── SAVAŞ OLAYLARI (oyuncuya gösterilen) ────────────────────────────────────
## Kural motoru bir sonucu belirlediği anda yayınlar (bkz. scripts/rules/battle_events.gd).
## Savaş günlüğü, birim üstü yüzen yazılar ve sesler BU sinyali dinler.
##   kind: &"hit" | &"miss" | &"injury" | &"ability"
##   data: yalnız ağdan geçebilen değerler (birim ADLARI, sayılar, anahtarlar)
signal battle_event(kind: StringName, data: Dictionary)

## Sunucudan (ya da tek makinede doğrudan) bütün oyunculara iletilir.
@rpc("authority", "call_local", "reliable")
func rpc_battle_event(kind: StringName, data: Dictionary) -> void:
	battle_event.emit(kind, data)
