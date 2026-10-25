## Bir yerleştirme (deploy) isteğinin TÜM bağlamı.
##
## `game.gd::request_deploy_unit` 292 satırlık, 16 ardışık ret kapısından oluşan bir prosedürdü.
## Kapılar ayrı fonksiyonlara bölünürken aralarında taşınan durum bu nesnede toplandı.
##
## ⚠ İKİ FARKLI OYUNCU KİMLİĞİ — karıştırmak gerçek bir bug kaynağıydı:
##   `real_sender_id` : RPC ADRESLEME için — GERÇEK ENet peer id'si (istemcininki rastgele
##                      büyük bir sayıdır, ASLA "2" değil). Ret bildirimi buna gönderilir.
##   `sender_id`      : OYUN MANTIĞI için — kanonik 1/2. `player_deploy_pool`, `player_factions`,
##                      `unit.owner_id` hep bunu bekler.
class_name DeployRequest
extends RefCounted

# ── İSTEK ────────────────────────────────────────────────────────────────────
var sender_id: int = 1
var real_sender_id: int = 1
var unit_data_path: String = ""
var loadout_index: int = -1
## Oyuncunun haritada TIKLADIĞI ham konum.
var target_pos: Vector3 = Vector3.ZERO

# ── ÇÖZÜMLENEN ───────────────────────────────────────────────────────────────
## Palet kartındaki taban birim tanımı.
var unit_data: Resource = null
## Seçilen Battlekit/loadout uygulandıktan SONRAKİ tanım. Keyword'ler DEĞİŞEBİLİR
## (örn. Trench Mole terfisi [Infiltrator]'ı yalnız seçilirse ekler) — bütçe/yerleşim
## kontrolleri bu yüzden `unit_data` değil BUNU okur.
var resolved_data: Resource = null
var player_faction: Resource = null

## Navigasyona hizalanmış yerleşim noktası. Automaton Destrier kenar hizalaması BUNU değiştirir.
var closest_pos: Vector3 = Vector3.ZERO
## Sahne navigasyon haritası (kapıların NavigationServer sorguları için).
var map_rid: RID

## Birimin gerçekten doğacağı konum (`closest_pos` + küçük yükseklik payı).
func spawn_position() -> Vector3:
	var p := closest_pos
	p.y += 0.02
	return p

## Sahadaki DÜŞMAN (hayatta) birimlerin konumları — yerleşim mesafesi kuralları için.
func enemy_positions() -> Array:
	var out: Array = []
	for u in UnitQuery.where(UnitQuery.alive(), func(u): return u.owner_id != sender_id):
		out.append(u.global_position)
	return out
