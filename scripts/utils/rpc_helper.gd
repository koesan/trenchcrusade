## RpcHelper
## Multiplayer RPC doğrulamalarını, yetki kontrollerini ve ağ/yerel senkron katmanını
## tek elden yöneten yardımcı sınıf.
class_name RpcHelper

## Tek senkron katmanı: bir @rpc metodunu ağ moduna göre çağırır.
## Çok oyunculuda broadcast (rpc), tek oyuncuda doğrudan yerel çağrı. Böylece kod tabanına
## dağılmış "if multiplayer.has_multiplayer_peer(): rpc(m, ...) else: m(...)" tekrarı tek
## noktaya toplanır (Single Source of Truth). method bir @rpc metodu olmalıdır.
static func sync(node: Object, method: StringName, args: Array = []) -> void:
	if node.multiplayer.has_multiplayer_peer():
		var call_args: Array = [method]
		call_args.append_array(args)
		node.callv("rpc", call_args)
	else:
		node.callv(method, args)

## Gelen RPC isteğinin yetkili (sunucu ve doğru oyuncu) olup olmadığını doğrular.
static func validate_rpc_request(node: Node, owner_id: int) -> bool:
	if node.multiplayer.has_multiplayer_peer():
		if not node.multiplayer.is_server():
			return false
		var real_sender = node.multiplayer.get_remote_sender_id()
		if real_sender == 0:
			real_sender = 1
		# KÖK NEDEN DÜZELTMESİ: gönderenin HAM peer id'si (host=1, istemci=rastgele büyük sayı)
		# ile owner_id/current_turn_player_id (kanonik 1/2) karşılaştırılamaz — önce kanoniğe çevir.
		var sender: int = NetworkManager.canonical_for_peer(real_sender)
		if sender != owner_id:
			return false
		if TurnManager.current_turn_player_id != sender:
			return false
	else:
		if TurnManager.current_turn_player_id != owner_id:
			return false
	return true
