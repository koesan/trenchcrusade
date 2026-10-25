## INFILTRATOR SIRASI — comprehensive-rules/keyword.md: "INFILTRATORS are deployed after models that
## do not have this Keyword."
##
## Oyunda warband yerleşim sırasında seçildiği için (önceden kurulmuş roster yok) bir oyuncunun
## hangi normal modelleri daha yerleştireceği bilinemez. Bu yüzden oyuncu bunu KENDİSİ bildirir:
## Sızıcıyı bölgesi dışına (serbest) yerleştirmeye çalıştığında, rakibi normal modellerini henüz
## bitirmediyse "hazır" işaretlenir ve BEKLER. Bekleyen oyuncu compendium'daki "modelleri biten
## oyuncu" gibi sayılır ("the other player sets up all their remaining models, one after another")
## → rakip kalan modellerini art arda yerleştirir. Rakip de Sızıcısını serbest yerleştirmek
## istediğinde (ya da yerleşimi bittiğinde) Sızıcılar sırayla konuşlanır. Kendi bölgesine normal
## yerleşim her zaman serbesttir.
class_name InfiltrationOrder
extends RefCounted


static func _opp(pid: int) -> int:
	return 2 if pid == 1 else 1


## `pid` Sızıcısı için rakibin normal modellerini mi bekliyor?
static func is_waiting(pid: int) -> bool:
	return GameState.infiltration_ready.get(pid, false) and not GameState.infiltration_ready.get(_opp(pid), false)


## `pid` Sızıcısını ŞİMDİ serbest yerleştirebilir mi? Rakip normal modellerini bitirdiyse (o da
## Sızıcı aşamasında ya da yerleşimi tamamen bitti) evet.
static func may_infiltrate_now(pid: int) -> bool:
	var opp := _opp(pid)
	return GameState.infiltration_ready.get(opp, false) or not GameState._has_deploy_budget(opp)


## Sunucu: `pid` normal modellerini bitirdi. Rakip hâlâ normal model yerleştiriyorsa sıra ona geçer.
static func mark_ready(pid: int) -> void:
	GameState.infiltration_ready[pid] = true
	var active: int = GameState.active_deployer_id
	if is_waiting(pid) and GameState._has_deploy_budget(_opp(pid)):
		active = _opp(pid)
	RpcHelper.sync(GameState, "sync_infiltration_ready", [GameState.infiltration_ready, active])
