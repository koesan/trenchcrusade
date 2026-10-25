## AKTİVASYON İPUÇLARI — "bu el hangi modeli oynatabilirim?" sorusunun haritadaki cevabı.
##
## Kullanıcı bildirimi: "o turda hangi unit hareket ettirebileceğim belli olsun; bir unit hareket
## ettirdiysem hareketleri bitene kadar belli olsun ki tek tek bakmayayım." Her canlı modelin
## durumu tek kaynaktan (ActivationRules) türetilir ve takım halkasına, kadro listesine ve üst
## bardaki durum satırına aynı anda yansır:
##   READY   — sırası gelen oyuncu bu modeli şimdi aktive edebilir → halka yumuşakça nabız atar
##   ACTIVE  — aktivasyonu sürüyor (eylem yaptı, bitmedi) → halkanın dışında dönen kesikli çember
##   WAITING — sıra bu oyuncuda ama başka model aktif / Hold Your Fire → halka sönükleşir
##   SPENT   — bu tur aktive oldu → halka söner
##   IDLE    — sıra rakipte (ya da ağ oyununda başkasının modeli) → normal halka
## Durum yalnız DEĞİŞİNCE yazılır (birim meta'sı "activation_cue"); HUD her birkaç karede çağırır.
class_name ActivationCues
extends RefCounted

const READY := &"ready"
const ACTIVE := &"active"
const WAITING := &"waiting"
const SPENT := &"spent"
const IDLE := &"idle"

## SAF karar fonksiyonu (sahnesiz test edilir). `local_ok`: bu makine modelin sahibini oynatıyor mu.
static func state_of(u, all_units: Dictionary, current_player: int, forced_name: String, local_ok: bool) -> StringName:
	if u.has_moved:
		return SPENT
	if u.owner_id != current_player or not local_ok:
		return IDLE
	if ActivationRules.is_committed(u):
		return ACTIVE
	if ActivationRules.selection_block_reason(all_units, u, forced_name) != "":
		return WAITING
	return READY

## Tüm canlı modellerin ipucunu günceller. Dönüş: üst bar için özet {active: Node|null, ready: int}.
static func refresh_all() -> Dictionary:
	var summary := {"active": null, "ready": 0}
	if GameState.game_phase != GameState.GamePhase.BATTLE:
		return summary
	var current: int = TurnManager.current_turn_player_id
	var networked: bool = NetworkManager.multiplayer.has_multiplayer_peer() \
		and NetworkManager.multiplayer.multiplayer_peer is not OfflineMultiplayerPeer
	var local_id: int = NetworkManager.get_local_canonical_id()
	for u in UnitQuery.alive():
		var cue: StringName = state_of(u, GameState.units, current, TurnManager.forced_next_activator,
			not networked or u.owner_id == local_id)
		if cue == ACTIVE and summary["active"] == null:
			summary["active"] = u
		elif cue == READY:
			summary["ready"] += 1
		if u.get_meta("activation_cue", &"") != cue:
			u.set_meta("activation_cue", cue)
			if u.has_method("update_indicators"):
				u.visuals_manager.refresh_team_ring()
	return summary
