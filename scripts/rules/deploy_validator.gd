## DeployValidator — yerleştirme ret sebeplerinin TEK KAYNAĞI.
##
## request_deploy_unit'teki her ret dalı bir lokalizasyon anahtarına bağlanır; game.gd bunu hem
## loglar hem GameEvents.deploy_rejected ile HUD toast'ına yollar. Böylece oyuncu her zaman NEDEN
## yerleştiremediğini görür (canlı testte "hata yok, koyamıyorum" kök sorunu).
##
## Anahtarların ikisinde de (tr/en) karşılığı OLMAK ZORUNDA — deploy_validator_test bunu kilitler.
class_name DeployValidator

const REASON_PHASE        := "DEPLOY_FAIL_PHASE"
const REASON_POINTS_FULL  := "DEPLOY_FAIL_POINTS_FULL"
const REASON_NO_FACTION   := "DEPLOY_FAIL_NO_FACTION"
const REASON_WRONG_FACTION := "DEPLOY_FAIL_WRONG_FACTION"
const REASON_BUDGET       := "DEPLOY_FAIL_BUDGET"
## Glory Point yetersiz — mercenary birimler YALNIZ Glory ile alınır (EconomyRules).
const REASON_GLORY        := "DEPLOY_FAIL_GLORY"
const REASON_LOADOUT      := "DEPLOY_FAIL_LOADOUT"
const REASON_NAV          := "DEPLOY_FAIL_NAV"
const REASON_INFILTRATOR  := "DEPLOY_FAIL_INFILTRATOR"
## Infiltrator serbest yerleşimi bir düşmanın görüş hattında (compendium: "out of line of sight of all enemies").
const REASON_INFILTRATOR_LOS := "DEPLOY_FAIL_INFILTRATOR_LOS"
## Sızıcı, rakip normal modellerini bitirmeden serbest yerleştirilemez (oyuncu beklemeye alınır).
const REASON_INFILTRATOR_ORDER := "DEPLOY_FAIL_INFILTRATOR_ORDER"
const REASON_ZONE         := "DEPLOY_FAIL_ZONE"
const REASON_PROXIMITY    := "DEPLOY_FAIL_PROXIMITY"
const REASON_AVAILABILITY := "DEPLOY_FAIL_AVAILABILITY"
const REASON_AUTOMATON_DESTRIER := "DEPLOY_FAIL_AUTOMATON_DESTRIER"
const REASON_RATIO           := "DEPLOY_FAIL_RATIO"
const REASON_LEGIONNAIRE_RATIO := "DEPLOY_FAIL_LEGIONNAIRE_RATIO"
## [Elite] tavanı (6) aşıldı — compendium'un TÜM faksiyonlar için geçerli global kuralı.
const REASON_ELITE_CAP    := "DEPLOY_FAIL_ELITE_CAP"
## The Order of the Fly (Cult of the Black Grail): seçilen liderlik dalının Lord/Knight tavanı aşıldı.
const REASON_ORDER_OF_FLY := "DEPLOY_FAIL_ORDER_OF_FLY"
## Alignment (Faithful/Fallen) çakışması — compendium choosing-a-faction.md.
const REASON_ALIGNMENT    := "DEPLOY_FAIL_ALIGNMENT"

## Test/denetim için tüm anahtarlar (her biri tr.json + en.json'da bulunmalı).
const ALL_REASONS := [
	REASON_PHASE, REASON_POINTS_FULL, REASON_NO_FACTION, REASON_WRONG_FACTION,
	REASON_BUDGET, REASON_GLORY, REASON_LOADOUT, REASON_NAV, REASON_INFILTRATOR, REASON_INFILTRATOR_LOS, REASON_INFILTRATOR_ORDER,
	REASON_ZONE, REASON_PROXIMITY, REASON_AVAILABILITY, REASON_AUTOMATON_DESTRIER,
	REASON_RATIO, REASON_LEGIONNAIRE_RATIO, REASON_ELITE_CAP, REASON_ORDER_OF_FLY, REASON_ALIGNMENT,
]

## Saf yardımcı: verilen konum mevcut birimlerin herhangi birine min_dist'ten yakın mı?
## (Yerleştirme çakışma kontrolünün test edilebilir çekirdeği.)
static func too_close_to_any(pos: Vector3, occupied_positions: Array, min_dist: float) -> bool:
	for p in occupied_positions:
		if pos.distance_to(p) < min_dist:
			return true
	return false
