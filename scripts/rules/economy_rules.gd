## EconomyRules — Warband satın alma ekonomisi (STATELESS).
##
## KURAL KAYNAĞI (warbands/starting-a-warband/recruit-your-warband.md):
##   "Each model you recruit has a specific cost in . The Faction List will show how many
##    you have to spend; usually, it will be 700 ."
##   "Some models and pieces of Battlekit cost Glory Points () INSTEAD OF (), are earned by
##    performing valorous deeds in battle, as described in the Campaign section. Generally,
##    Warbands don't have access to when they are first created, so you will probably have
##    to wait until later on in a campaign to recruit any models that require them."
##   "Mercenaries... CANNOT be purchased with  — the only way to attract their services is
##    to perform glorious deeds on the battlefield!"
##
## Bu yüzden İKİ AYRI havuz vardır ve biri diğerinin yerine GEÇEMEZ. Ducat'ı olan bir oyuncu
## Glory birimini satın alamaz; Glory'si olan bir oyuncu ducat birimini satın alamaz.
##
## Compendium'da Glory kampanyada kazanılır; oyunda kampanya olmadığından her senaryo küçük bir
## Glory bütçesi verir (ScenarioData.glory_budget) — birkaç mercenary'ye yeter, hepsine yetmez.
##
## Bu sınıf STATELESS'tır (MechanicsResolver / InjuryResolver / KeywordSystem ile aynı desen):
## havuzları kendisi TUTMAZ, yalnız hesaplar. Havuzların sahibi GameState'tir.
class_name EconomyRules

## UnitData.Currency.GLORY'nin sayısal karşılığı. UnitData'ya bağımlılık yaratmamak için
## (bu sınıf saf/testlenebilir kalmalı) doğrudan sabit olarak tutulur.
const CURRENCY_GLORY := 1

## UI'da maliyetin yanında gösterilecek para birimi etiketleri (lokalizasyon anahtarları —
## metin ASLA koda gömülmez).
const KEY_DUCAT := "CURRENCY_DUCAT"
const KEY_GLORY := "CURRENCY_GLORY"

## Bu birim Glory Point ile mi fiyatlanmış?
static func is_glory(unit_data: Resource) -> bool:
	if unit_data == null or not ("cost_currency" in unit_data):
		return false
	return int(unit_data.cost_currency) == CURRENCY_GLORY

## Bu birim verilen havuzlarla alınabilir mi? Havuzlar BİRBİRİNİN YERİNE GEÇMEZ.
static func can_afford(unit_data: Resource, ducat_pool: int, glory_pool: int) -> bool:
	if unit_data == null:
		return false
	var cost: int = int(unit_data.cost)
	return (glory_pool >= cost) if is_glory(unit_data) else (ducat_pool >= cost)

## Ödemeyi uygular ve GÜNCELLENMİŞ havuzları döndürür (girdi sözlüğünü mutasyona uğratmaz).
## pools: {"ducat": int, "glory": int} → aynı biçimde döner.
static func pay(unit_data: Resource, pools: Dictionary) -> Dictionary:
	var out := {
		"ducat": int(pools.get("ducat", 0)),
		"glory": int(pools.get("glory", 0)),
	}
	if unit_data == null:
		return out
	var cost: int = int(unit_data.cost)
	if is_glory(unit_data):
		out["glory"] = maxi(0, out["glory"] - cost)
	else:
		out["ducat"] = maxi(0, out["ducat"] - cost)
	return out

## Bu faksiyonun roster'ında, verilen havuzlarla alınabilecek EN AZ BİR birim var mı?
##
## KRİTİK: bu kontrol İKİ havuzu da gözetmek ZORUNDADIR. Tek havuzlu (eski) mantık,
## ducat'ı biten bir oyuncuyu 2 Glory'lik bir mercenary yüzünden "hâlâ yerleştirebilir"
## sayar ve yerleştirme fazı hiç bitmezdi.
static func can_afford_any(faction: Resource, ducat_pool: int, glory_pool: int) -> bool:
	if faction == null or not ("available_units" in faction):
		return false
	for u in faction.available_units:
		if u != null and can_afford(u, ducat_pool, glory_pool):
			return true
	return false

## Bu birimin maliyeti hangi para biriminde gösterilmeli? (UI için lokalizasyon anahtarı)
static func currency_key(unit_data: Resource) -> String:
	return KEY_GLORY if is_glory(unit_data) else KEY_DUCAT
