extends RefCounted

## İNİSİYATİF FAZI — compendium `core-rules/initiative-phase.md` denetimi (Adım 1).
##
## > "count up the number of models in each Warband that are currently on the battlefield.
## > Do not count models that are Down or Out of Action. The player with the fewest number of
## > models has the Initiative for the rest of the Turn. If both players have the same number
## > of models, they roll-off and the winner has the Initiative for the rest of the Turn."
##
## Kural İKİ şey söyler ve ikisinin de istisnası yoktur:
##   1. Sayım tabanı = sahadaki, Down VE Out of Action OLMAYAN modeller.
##   2. AZ olan taraf inisiyatifi alır; yalnız EŞİTLİKTE roll-off yapılır.

const TurnManager = preload("res://scripts/turn_manager/turn_manager.gd")
const InitiativeRules = preload("res://scripts/turn_manager/initiative_rules.gd")

func run(t) -> void:
	var I = InitiativeRules.from_counts

	# ── Az modeli olan inisiyatifi alır ──────────────────────────────────
	t.eq(I.call(3, 5), 1, "3'e karşı 5 → az olan (Oyuncu 1) inisiyatifi alır")
	t.eq(I.call(6, 2), 2, "6'ya karşı 2 → az olan (Oyuncu 2) inisiyatifi alır")
	t.eq(I.call(1, 2), 1, "1'e karşı 2 → tek modelli taraf inisiyatifi alır")

	# ── Eşitlikte roll-off (0 = çağıran roll-off yapar) ──────────────────
	t.eq(I.call(4, 4), 0, "Eşit sayıda model → roll-off")
	t.eq(I.call(0, 0), 0, "İki taraf da sıfır → roll-off")

	# ── SIFIR AYAKTA MODEL: kuralın istisnası YOK ────────────────────────
	# KURAL SAPMASI (bu testin var oluş sebebi): eski kod "en az modeli olan" dalına
	# `count > 0` koşulu koyuyordu; tüm modelleri Down/Out of Action olan oyuncu — kuralın
	# inisiyatifi en net verdiği taraf — roll-off'a düşüyordu.
	#
	# Bu durum ERİŞİLEBİLİR: Moral Kontrolü kaybetmek ÜST ÜSTE İKİ başarısızlık gerektirir
	# (morale-phase.md), dolayısıyla bir oyuncu "sıfır ayakta model" ile yeni bir tura girebilir.
	t.eq(I.call(0, 4), 1, "Ayakta modeli KALMAYAN oyuncu inisiyatifi alır (istisna yok)")
	t.eq(I.call(7, 0), 2, "Karşı taraf sıfırdaysa inisiyatif onundur")

	# ── Simetri: taraf değiştirince sonuç da değişmeli ───────────────────
	for pair in [[2, 9], [5, 6], [0, 1], [11, 3]]:
		var a: int = pair[0]
		var b: int = pair[1]
		var forward: int = I.call(a, b)
		var backward: int = I.call(b, a)
		t.ok(forward != backward,
			"Simetri: (%d,%d)=%d ile (%d,%d)=%d zıt olmalı" % [a, b, forward, b, a, backward])

	# ── Moral eşiğiyle tutarlılık ────────────────────────────────────────
	# İnisiyatif sayımı ile Moral sayımı AYNI tabanı kullanır (ayakta = Down/OOA değil).
	# Bu ikisi ayrışırsa "az modeli olan" ile "morali bozulan" farklı kümeler olurdu.
	var M = TurnManager.morale_must_check
	t.ok(M.call(6, 3, false), "6 modelin 3'ü ayakta → moral kontrolü (aynı 'ayakta' tabanı)")
	t.eq(I.call(3, 6), 1, "…ve aynı taraf inisiyatifi alır")
