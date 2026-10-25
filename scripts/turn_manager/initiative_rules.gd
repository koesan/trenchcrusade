## İNİSİYATİF KURALI — compendium `core-rules/initiative-phase.md` + `other-rules-principles.md`.
##
## > "count up the number of models in each Warband that are currently on the battlefield.
## > Do not count models that are Down or Out of Action. The player with the fewest number of
## > models has the Initiative for the rest of the Turn. If both players have the same number
## > of models, they roll-off and the winner has the Initiative for the rest of the Turn."
##
## NEDEN AYRI MODÜL: kural iki bağımsız parçadan oluşuyor (sayım karşılaştırması + roll-off) ve
## ikisi de saf; `turn_manager.gd` içinde durursa oradaki durum yönetimiyle karışır ve test
## edilemez hâle gelir (mimari sağlık testi de dosya boyu tavanını uyarıyordu).
class_name InitiativeRules

## Kuralın SAF çekirdeği. `count1`/`count2`: sahadaki, Down VE Out of Action OLMAYAN model sayısı.
##
## Dönüş: kazanan oyuncu id'si (1 veya 2); BERABERLİKTE 0 — çağıran `roll_off()` yapar.
##
## ⚠ KURAL SAPMASI DÜZELTMESİ (compendium denetimi, Adım 1): eski kod "en az modeli olan"
## dalına `count > 0` koşulu ekliyordu. Yani modellerinin TAMAMI Down/Out of Action olmuş bir
## oyuncu — kuralın inisiyatifi en net verdiği taraf — bunun yerine roll-off'a düşüyordu.
## Bu durum ERİŞİLEBİLİR: Moral Kontrolü kaybetmek ÜST ÜSTE İKİ başarısızlık gerektirir
## (morale-phase.md), dolayısıyla bir oyuncu "sıfır ayakta model" ile yeni bir tura girebilir.
## Compendium sayının sıfır olmasına dair hiçbir istisna tanımlamaz.
static func from_counts(count1: int, count2: int) -> int:
	if count1 < count2:
		return 1
	if count2 < count1:
		return 2
	return 0   # beraberlik → roll-off

## Compendium "Rolling Off": her oyuncu 1D6 atar, YÜKSEK olan kazanır. Zar değiştirilemez ve
## yeniden atılamaz; YALNIZ beraberlikte roll-off tekrarlanır.
static func roll_off() -> int:
	var r1: int = randi_range(1, 6)
	var r2: int = randi_range(1, 6)
	while r1 == r2:
		r1 = randi_range(1, 6)
		r2 = randi_range(1, 6)
	var winner: int = 1 if r1 > r2 else 2
	GameLogger.log_info("[Initiative] Roll-off — P1 zar: %d, P2 zar: %d. Kazanan: Oyuncu %d" \
		% [r1, r2, winner], "TURN")
	return winner
