#!/usr/bin/env python3
"""Armoury (Battlekit) veri üreteci.

KAYNAK
------
* Fiyat / `LIMIT: N` / kısıt  ->  trench_compendium/warbands/<faction>.md  "## Armoury" tablosu
* Kural ve anahtar kelimeler  ->  trench_compendium/battlekit/{melee,ranged,grenade,armour,
                                  shield,equipment}.md

ÜRETİLEN
--------
* assets/data/armoury/*.tres            — ArmouryItem kaynakları
* assets/localization/{tr,en}.json      — ARM_* ad/açıklama/kısıt anahtarları
* faksiyon .tres dosyalarındaki `armoury = Array[Resource]([...])` satırı

NEDEN ÜRETEÇ?
-------------
229 faksiyon girdisi / 96 benzersiz kalem elle yazılamayacak kadar çok ve elle yazılırsa
compendium ile arasındaki bağ kopar. Üreteç, verinin kaynağını denetlenebilir kılar:
fiyat tablosu değişirse tek komutla yeniden üretilir.

KUR: python3 tools/generate_armoury.py   (proje kökünden)
"""
import json
import os
import re
import collections

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COMP = os.path.join(ROOT, "trench_compendium")
OUT = os.path.join(ROOT, "assets/data/armoury")

FACTIONS = {
    "new_antioch": "new-antioch",
    "heretic_legion": "heretic-legion",
    "trench_pilgrims": "trench-pilgrims",
    "iron_sultanate": "iron-sultanate",
    "cult_of_the_black_grail": "cult-of-the-black-grail",
    "court_of_seven_headed_serpent": "court-of-the-seven-headed-serpent",
}
CATS = {"Melee Weapons": "MELEE", "Ranged Weapons": "RANGED", "Grenades": "GRENADE",
        "Armour": "ARMOUR", "Shields": "SHIELD", "Equipment": "EQUIPMENT"}
CAT_ENUM = {"MELEE": 0, "RANGED": 1, "GRENADE": 2, "ARMOUR": 3, "SHIELD": 4, "EQUIPMENT": 5}

# Compendium'daki para birimi simgeleri kazımada kaybolmuştur. Aşağıdaki girdiler, AYNI kalemin
# başka bir faksiyonda 10-25 kat pahalı listelenmesiyle Glory Point fiyatı olarak teşhis edildi
# (ör. Automatic Rifle: New Antioch 40 ducat / Heretic Legion "2"). Anti-Materiel Rifle ve
# Holy Icon Shield tek faksiyonda geçer; ikisi de battlekit'te seçkin/nadir olarak tanımlanır.
GLORY_PRICED = {
    ("heretic_legion", "Hellblade"), ("heretic_legion", "Anti-Materiel Rifle"),
    ("heretic_legion", "Automatic Rifle"), ("heretic_legion", "Submachine Gun"),
    ("trench_pilgrims", "Machine Gun"), ("trench_pilgrims", "Sniper Rifle"),
    ("trench_pilgrims", "Submachine Gun"), ("trench_pilgrims", "Holy Icon Shield"),
}

# ── Silah kalemi -> mevcut AttackData kaynağı ────────────────────────────────
# Adı doğrudan dosya adına çevrilemeyen kalemler burada eşlenir.
WEAPON_OVERRIDE = {
    "Great Hammer/Maul": ["great_hammer_maul"],
    "Greatsword / Axe": ["greatsword_axe"],
    "Sword / Axe": ["sword_axe"],
    "Flail / Scourge": ["flail_scourge"],
    "M.U.R.A.D Bombard": ["murad_bombard"],
    "Assassin's Dagger": ["assassins_dagger"],
    "Beelzebub's Axe": ["beelzebubs_axe"],
    "Frag Grenades": ["frag_grenade"],
    "Halberd-Gun": ["halberd_gun", "halberd_gun_shot"],  # 24" ateş + yakın dövüş profili
}

# ── Silah dışı kalemler: etki + iki dilde metin ──────────────────────────────
# armour: `[-N Injury Modifier]`  ·  kw: KeywordSystem'e eklenen anahtarlar  ·  hands: el
NONWEAPON = {
    # ---- ARMOUR ----
    "Standard Armour": dict(armour=1, kw={}, hands=0,
        tr="Standart Zırh", en="Standard Armour",
        tr_d="Cephe birliklerinin standart plaka zırhı. Kendisine yapılan Yaralanma Zarlarına [-1 Yaralanma Değiştirici] ekler.",
        en_d="Standard issue plate for front-line troops. Grants [-1 Injury Modifier] against attacks that hit the wearer."),
    "Reinforced Armour": dict(armour=2, kw={}, hands=0,
        tr="Takviyeli Zırh", en="Reinforced Armour",
        tr_d="Ağır piyade için kalınlaştırılmış zırh. [-2 Yaralanma Değiştirici] sağlar; taşıyabilmek için olağanüstü güç gerekir.",
        en_d="Thickened plate for heavy infantry. Grants [-2 Injury Modifier]; only the strongest can bear its weight."),
    "Machine Armour": dict(armour=3, kw={}, hands=0,
        tr="Makine Zırhı", en="Machine Armour",
        tr_d="Buharla çalışan dış iskelet zırhı. [-3 Yaralanma Değiştirici] sağlar — savaş alanındaki en ağır koruma.",
        en_d="A steam-driven exoskeleton harness. Grants [-3 Injury Modifier] — the heaviest protection on the battlefield."),
    "Alchemist Armour": dict(armour=2, kw={"negate_fire": 1, "negate_gas": 1}, hands=0,
        tr="Simyacı Zırhı", en="Alchemist Armour",
        tr_d="Jabir simyacılarının mühürlü kıyafeti. [-2 Yaralanma Değiştirici] verir; Ateş ve Gaz etkilerini tamamen engeller.",
        en_d="A sealed suit of the Jabirean alchemists. Grants [-2 Injury Modifier] and negates Fire and Gas entirely."),
    # ---- SHIELD ----
    "Trench Shield": dict(armour=1, kw={"shield": 1}, hands=1,
        tr="Siper Kalkanı", en="Trench Shield",
        tr_d="Hurda çelikten dövülmüş ağır siper kalkanı. [-1 Yaralanma Değiştirici] sağlar ve bir el işgal eder.",
        en_d="A heavy shield beaten from scrap steel. Grants [-1 Injury Modifier] and occupies one hand."),
    "Heavy Ballistic Shield": dict(armour=0, kw={"shield": 1, "cover": 1, "shield_combo": 1}, hands=1,
        tr="Ağır Balistik Kalkan", en="Heavy Ballistic Shield",
        tr_d="Yalnızca Makine Zırhının taşıyabileceği devasa çelik levha. Taşıyıcıya kalıcı [Siper] verir.",
        en_d="A vast steel plate only Machine Armour can carry. Grants the bearer permanent [Cover]."),
    "Black Grail Shield": dict(armour=1, kw={"shield": 1}, hands=1,
        tr="Kara Kâse Kalkanı", en="Black Grail Shield",
        tr_d="Hastalıklı etle kaplanmış çürümüş kalkan. [-1 Yaralanma Değiştirici] sağlar.",
        en_d="A rotting shield sheathed in diseased flesh. Grants [-1 Injury Modifier]."),
    "Holy Icon Shield": dict(armour=1, kw={"shield": 1, "impervious": 1}, hands=1,
        tr="Kutsal İkon Kalkanı", en="Holy Icon Shield",
        tr_d="Mucize göstermiş bir ikondan yapılmış kalkan. [-1 Yaralanma Değiştirici] ve [Nüfuz Edilemez] verir.",
        en_d="A shield made from an icon that has worked miracles. Grants [-1 Injury Modifier] and [Impervious]."),
    # ---- EQUIPMENT ----
    "Combat Helmet": dict(armour=0, kw={"negate_shrapnel": 1}, hands=0,
        tr="Muharebe Miğferi", en="Combat Helmet",
        tr_d="Çelik miğfer — [Şarapnel] anahtar kelimesini tamamen etkisiz kılar.",
        en_d="A steel helmet — negates the [Shrapnel] Keyword entirely."),
    "Gas Mask": dict(armour=0, kw={"negate_gas": 1}, hands=0,
        tr="Gaz Maskesi", en="Gas Mask",
        tr_d="Filtreli maske — [Gaz] anahtar kelimesini tamamen etkisiz kılar.",
        en_d="A filtered mask — negates the [Gas] Keyword entirely."),
    "Iron Capirote": dict(armour=0, kw={"negate_shrapnel": 1, "negate_fear": 1}, hands=0,
        tr="Demir Kapirote", en="Iron Capirote",
        tr_d="Kefaret giyen hacıların sivri demir başlığı. [Şarapnel] ve [Korku] etkilerini engeller.",
        en_d="The pointed iron hood of penitent pilgrims. Negates both [Shrapnel] and [Fear]."),
    "Compound Eyes Helmet": dict(armour=0, kw={"negate_shrapnel": 1, "ranged_dice_bonus": 1}, hands=0,
        tr="Petek Gözlü Miğfer", en="Compound Eyes Helmet",
        tr_d="Sinek gözü camlarla donatılmış miğfer. [Şarapnel]'i engeller ve Menzilli Saldırılara +1 Zar ekler.",
        en_d="A helm fitted with fly-eye lenses. Negates [Shrapnel] and adds +1 Dice to Ranged Attacks."),
    "Infernal Brand": dict(armour=0, kw={"negate_fire": 1}, hands=0,
        tr="Cehennem Damgası", en="Infernal Brand",
        tr_d="Ete kazınmış cehennemî mühür — taşıyıcı [Ateş] etkisinden muaf olur.",
        en_d="An infernal sigil seared into the flesh — the bearer is immune to [Fire]."),
    "Holy Relic": dict(armour=0, kw={"blessed": 1}, hands=0,
        tr="Kutsal Emanet", en="Holy Relic",
        tr_d="Bir azizin kemiği ya da kanı. Taşıyıcıya [Kutsanmış 1] verir.",
        en_d="The bone or blood of a saint. Grants the bearer [Blessed 1]."),
    "Unholy Relic": dict(armour=0, kw={"fear": 1}, hands=0,
        tr="Kutsal Olmayan Emanet", en="Unholy Relic",
        tr_d="Lanetli bir kalıntı. Taşıyıcıya [Korku] anahtar kelimesini verir.",
        en_d="A damned remnant. Grants the bearer the [Fear] Keyword."),
    "Blessed Icon": dict(armour=0, kw={"consumable": 1, "talisman": 1}, hands=0,
        tr="Kutsanmış İkon", en="Blessed Icon",
        tr_d="Tılsım: Oyunda bir kez, başarısız bir [Riskli Başarı] atışından sonra modelin aktivasyonu sona ermez.",
        en_d="Talisman: Once per game, a failed [Risky Success] Roll does not end the model's Activation."),
    "Unholy Trinket": dict(armour=0, kw={"consumable": 1, "talisman": 1}, hands=0,
        tr="Kutsal Olmayan Muska", en="Unholy Trinket",
        tr_d="Tılsım: Oyunda bir kez, başarısız bir [Riskli Başarı] atışından sonra modelin aktivasyonu sona ermez.",
        en_d="Talisman: Once per game, a failed [Risky Success] Roll does not end the model's Activation."),
    "Martyrdom Pills": dict(armour=0, kw={"consumable": 1, "negate_fear": 1, "inured_to_pain": 1}, hands=0,
        tr="Şehadet Hapları", en="Martyrdom Pills",
        tr_d="Acıya Duyarsız: Yerleştirmede yutulursa oyun sonuna dek [Korku]'yu engeller ve modele isabet eden saldırılara [-1 Yaralanma Zarı] ekler.",
        en_d="Inured to Pain: If swallowed at deployment, negates [Fear] for the game and adds [-1 Injury Dice] to attacks that hit the model."),
    "Medi-Kit": dict(armour=0, kw={"medi_kit": 1}, hands=0,
        tr="Sıhhiye Çantası", en="Medi-Kit",
        tr_d="Tedavi Et [Eylem]: Riskli Başarı atışı yap; başarılıysa kendinden ya da 1\" içindeki dost bir modelden 1 [Kan İşareti] kaldır veya onu ayağa kaldır.",
        en_d="Treat [Action]: Take a Risky Success Roll; on a success remove 1 [Blood Marker] from this or a friendly model within 1\", or stand it up."),
    "Mountaineer Kit": dict(armour=0, kw={"mountaineer": 1}, hands=0,
        tr="Dağcı Takımı", en="Mountaineer Kit",
        tr_d="Halatlar ve Kancalar: Dik yüzeye tırmanma [Riskli Başarı] atışlarına +1 Zar ekler.",
        en_d="Ropes and Pitons: Adds +1 Dice to [Risky Success] Rolls to climb a sheer surface."),
    "Shovel": dict(armour=0, kw={"shovel": 1, "dug_in": 1}, hands=0,
        tr="Kürek", en="Shovel",
        tr_d="Siper Kaz: Açık arazide başlayan model, yerinden ayrılana dek [Siper] kazanır. Ayrıca 2 elli yakın dövüş silahı olarak kullanılabilir.",
        en_d="Dug In: A model starting on Open terrain gains [Cover] until it moves. Can also be used as a 2-Handed Melee weapon."),
    "Marid Shovel": dict(armour=0, kw={"shovel": 1, "dug_in": 1, "heavy": 1}, hands=0,
        tr="Marid Küreği", en="Marid Shovel",
        tr_d="Yalnızca Tunç Boğa'nın kaldırabileceği devasa kürek. Kürek kurallarını uygular, [Ağır] anahtar kelimesini taşır.",
        en_d="A giant shovel only a Brazen Bull can lift. Follows the Shovel rules and carries the [Heavy] Keyword."),
    "Binoculars": dict(armour=0, kw={"binoculars": 1}, hands=0,
        tr="Dürbün", en="Binoculars",
        tr_d="Araziyi Gözle: Düşman modeller, kendi yerleştirme bölgeleri dışında bu modelin 16\" yakınına [Sızıcı] ile yerleşemez.",
        en_d="Survey the Land: Enemy models cannot use [Infiltrator] to deploy within 16\" of this model, unless in their own deployment zone."),
    "Field Shrine": dict(armour=0, kw={"field_shrine": 1, "deployable": 1}, hands=0,
        tr="Seyyar Mabet", en="Field Shrine",
        tr_d="İbadet Yeri: Modelle birlikte yerleştirilen geçilemez bir arazi parçası; Moral Fazında dost modellere yardım eder.",
        en_d="Site of Worship: An Impassable terrain piece deployed with the model; it aids friendly models in the Morale Phase."),
    "Musical Instrument": dict(armour=0, kw={"musical_instrument": 1, "held": 1}, hands=0,
        tr="Çalgı", en="Musical Instrument",
        tr_d="Fanfar: 4\" içindeki dost modellerin Atılım [Eylem] [Riskli Başarı] atışlarına +1 Zar ekler.",
        en_d="Fanfare: Adds +1 Dice to [Risky Success] Rolls for friendly models taking a Dash [Action] within 4\"."),
    "Troop Flag": dict(armour=0, kw={"leader": 1, "held": 1}, hands=0,
        tr="Birlik Sancağı", en="Troop Flag",
        tr_d="Taşıyıcıya [Lider] anahtar kelimesini verir; sancak elde tutulur.",
        en_d="Grants the bearer the [Leader] Keyword; the flag is Held in hand."),
    "Wind Amulet": dict(armour=0, kw={"wind_amulet": 1}, hands=0,
        tr="Rüzgâr Muskası", en="Wind Amulet",
        tr_d="Rüzgâr Esintisi: Oyunda bir kez, aktivasyon başında modelin Hareket değerine 3\" ekler.",
        en_d="Gusts of Wind: Once per game, adds 3\" to the model's Movement for that Activation."),
    "Takwin Anqa Bird": dict(armour=0, kw={"takwin_anqa": 1}, hands=0,
        tr="Takvin Anka Kuşu", en="Takwin Anqa Bird",
        tr_d="Şaşkınlık Yarat: Bu modeli hedef alan Yakın Dövüş atışları [Riskli Başarı]'ya dönüşür; 1\" içindeki düşmanlar geri çekilmekte zorlanır.",
        en_d="Cause Confusion: Melee Success Rolls targeting this model become [Risky Success] Rolls, and enemies within 1\" struggle to retreat."),
    "Cloak of Alamut": dict(armour=0, kw={"cloak_of_alamut": 1}, hands=0,
        tr="Alamut Pelerini", en="Cloak of Alamut",
        tr_d="Gölgeye Karış: Bu model siperdeyken düşman Menzilli Saldırı cezası -1 Zar yerine [-2 Zar] olur.",
        en_d="Blend In: While this model is in Cover, the enemy Ranged Attack modifier is [-2 Dice] instead of -1."),
    "Crown of Hellfire": dict(armour=0, kw={"crown_of_hellfire": 1}, hands=0,
        tr="Cehennem Ateşi Tacı", en="Crown of Hellfire",
        tr_d="Kavurucu Alevler: Aktivasyon sonunda 1\" içindeki her düşman modele 1 [Kan İşareti] koyar ([Ateşi Engelle] taşıyanlar hariç).",
        en_d="Searing Flames: At the end of its Activation, place 1 [Blood Marker] on each enemy within 1\" (except those with [Negate Fire])."),
    "Hellbound Soul Contract": dict(armour=0, kw={"hellbound_contract": 1}, hands=0,
        tr="Cehenneme Bağlı Ruh Sözleşmesi", en="Hellbound Soul Contract",
        tr_d="Ateşli Çıkış: Model Devre Dışı kaldığında, kaldırılmadan önce 1\" içindeki her düşmana 1 [Kan İşareti] ekler.",
        en_d="Fiery Exodus: When taken Out of Action, add 1 [Blood Marker] to each enemy within 1\" before removal."),
    "Grail Devotee": dict(armour=0, kw={"grail_devotee": 1}, hands=0,
        tr="Kâse Müridi", en="Grail Devotee",
        tr_d="Sürünen Takipçiler: Modelin Yakın Dövüş Yaralanma Atışlarına her mürit için [+1 Yaralanma Değiştirici] ekler (model başına en fazla 2).",
        en_d="Grovelling Followers: Adds [+1 Injury Modifier] to the model's Melee Injury Rolls per Devotee (max 2 per model)."),
    "Restraining Muzzle": dict(armour=0, kw={"restraining_muzzle": 1}, hands=0,
        tr="Zapt Edici Ağızlık", en="Restraining Muzzle",
        tr_d="Zapt Edildi: Boyunduruk İblisi'nin Menzilli Saldırılarına +1 Zar ekler ve Kinci yeteneğini iptal eder.",
        en_d="Brought to Heel: Adds +1 Dice to a Yoke Fiend's Ranged Attacks and cancels its Hateful ability."),
    "Alchemical Ammunition": dict(armour=0, kw={"ammunition_dice": 1}, hands=0,
        tr="Simyasal Mühimmat", en="Alchemical Ammunition",
        tr_d="[Mühimmat +1 Zar]. Yalnızca Alaybozan, Halberd-Gun, Cezayir Tüfeği veya Kuşatma Cezayiri ile kullanılabilir.",
        en_d="[Ammunition +1 Dice]. Can only be used with an Alaybozan, Halberd-Gun, Jezzail or Siege Jezzail."),
    "Incendiary Ammunition": dict(armour=0, kw={"consumable": 1, "ammunition_fire": 1}, hands=0,
        tr="Yakıcı Mühimmat", en="Incendiary Ammunition",
        tr_d="[Sarf Edilir] [Mühimmat Ateş] — atış silahına oyunda bir kez [Ateş] anahtar kelimesi kazandırır.",
        en_d="[Consumable] [Ammunition Fire] — grants the firearm the [Fire] Keyword once per game."),
    "Martyrdom Device": dict(armour=0, kw={"martyrdom_device": 1}, hands=0,
        tr="Şehadet Düzeneği", en="Martyrdom Device",
        tr_d="Modelin üzerine kuşatılmış patlayıcı yük. Devre Dışı kaldığında ya da tetiklendiğinde patlar.",
        en_d="An explosive charge strapped to the model. It detonates when the model is taken Out of Action or triggered."),
}

# ── Kısıt metinleri (lokalizasyon) ───────────────────────────────────────────
RESTRICT_TEXT = {
    "Elite only": ("Yalnızca [Seçkin]", "[Elite] only"),
    "BAYONET LUG only": ("Yalnızca [Süngü Yuvası] olan silahlarla", "[Bayonet Lug] weapons only"),
    "Machine Armour only": ("Yalnızca Makine Zırhı ile", "Machine Armour only"),
    "Mechanized Heavy Infantry, Elite only": ("Yalnızca Mekanize Ağır Piyade, [Seçkin]", "Mechanized Heavy Infantry, [Elite] only"),
    "Anointed Heavy Infantry, Elite only": ("Yalnızca Kutsanmış Ağır Piyade, [Seçkin]", "Anointed Heavy Infantry, [Elite] only"),
    "Janissary, Elite only": ("Yalnızca Yeniçeri, [Seçkin]", "Janissary, [Elite] only"),
    "Death Commando only": ("Yalnızca Ölüm Komandosu", "Death Commando only"),
    "Heretic Trooper only": ("Yalnızca Sapkın Er", "Heretic Trooper only"),
    "Sultanate Assassin only": ("Yalnızca Saltanat Suikastçısı", "Sultanate Assassin only"),
    "Sultanate Sapper only": ("Yalnızca Saltanat İstihkâmcısı", "Sultanate Sapper only"),
    "Brazen Bull only": ("Yalnızca Tunç Boğa", "Brazen Bull only"),
    "Jabirean Alchemist only": ("Yalnızca Jabir Simyacısı", "Jabirean Alchemist only"),
    "Ecclesiastic Prisoner only": ("Yalnızca Ruhban Mahkûm", "Ecclesiastic Prisoner only"),
    "Amalgam only": ("Yalnızca Amalgam", "Amalgam only"),
    "Herald of Beelzebub, Elite only": ("Yalnızca Beelzebub Habercisi, [Seçkin]", "Herald of Beelzebub, [Elite] only"),
    "Elite, Pit Locust only": ("Yalnızca Çukur Çekirgesi, [Seçkin]", "Pit Locust, [Elite] only"),
    "Yoke Fiend only": ("Yalnızca Boyunduruk İblisi", "Yoke Fiend only"),
    "Yoke Fiend, Wretched only": ("Yalnızca Boyunduruk İblisi, Sefil", "Yoke Fiend, Wretched only"),
}
# Kısıt -> gerekli birim adları (oyundaki UnitData.unit_name ile birebir)
RESTRICT_UNITS = {
    "Mechanized Heavy Infantry, Elite only": ["Mechanized Heavy Infantry"],
    "Anointed Heavy Infantry, Elite only": ["Anointed Heavy Infantry"],
    "Janissary, Elite only": ["Janissary"],
    "Death Commando only": ["Death Commando"],
    "Heretic Trooper only": ["Heretic Trooper"],
    "Sultanate Assassin only": ["Sultanate Assassin"],
    "Sultanate Sapper only": ["Sultanate Sapper"],
    "Brazen Bull only": ["Brazen Bull"],
    "Jabirean Alchemist only": ["Jabirean Alchemist"],
    "Ecclesiastic Prisoner only": ["Ecclesiastic Prisoner"],
    "Amalgam only": ["Amalgams"],
    "Herald of Beelzebub, Elite only": ["Herald of Beelzebub"],
    "Elite, Pit Locust only": ["Pit Locust"],
    "Yoke Fiend only": ["Yoke Fiend"],
    "Yoke Fiend, Wretched only": ["Yoke Fiend", "Wretched"],
}
RESTRICT_KEYWORDS = {"BAYONET LUG only": ["bayonet_lug"]}
RESTRICT_ITEM = {"Machine Armour only": "machine_armour"}


def slug(name):
    s = name.lower().replace("'", "").replace("/", "_").replace("-", "_").replace(".", "")
    return re.sub(r"[^a-z0-9]+", "_", s).strip("_")


def parse_faction(fid, fname):
    txt = open(os.path.join(COMP, "warbands", fname + ".md"), encoding="utf-8").read()
    m = re.search(r"^## Armoury\s*$(.*?)^## (Variants|Promotions)", txt, re.S | re.M)
    lines = [l.strip() for l in m.group(1).split("\n") if l.strip()]
    cat, items, cur = None, [], None
    for l in lines:
        if l in CATS:
            cat = CATS[l]
            continue
        if l == "Exploration Only":      # kampanya kalemleri — çatışma modunda geçerli değil
            break
        if re.fullmatch(r"\d+", l):
            if cur:
                cur["cost"] = int(l)
            continue
        if l.startswith("LIMIT:"):
            if cur:
                cur["limit"] = int(re.search(r"\d+", l).group())
            continue
        if cur and cur["cost"] is not None and l in RESTRICT_TEXT:
            cur["restrict"] = l
            continue
        cur = {"name": l, "cat": cat, "cost": None, "limit": 0, "restrict": ""}
        items.append(cur)
    seen, out = set(), []
    for i in items:
        if i["cost"] is None or i["name"] in seen:
            continue                      # kazımada yinelenen satırlar (ör. Grail Devotee)
        seen.add(i["name"])
        out.append(i)
    return out


def attack_paths(name):
    if name in WEAPON_OVERRIDE:
        cands = WEAPON_OVERRIDE[name]
    else:
        s = slug(name)
        cands = [s, s.replace("_grenades", "_grenade"), s + "s", s.rstrip("s")]
        cands = [c for c in cands if os.path.exists(os.path.join(ROOT, "assets/data/attacks", c + ".tres"))][:1]
    for c in cands:
        assert os.path.exists(os.path.join(ROOT, "assets/data/attacks", c + ".tres")), f"eksik saldırı: {name} -> {c}"
    return ["res://assets/data/attacks/%s.tres" % c for c in cands]


def attack_field(path, field):
    txt = open(os.path.join(ROOT, path.replace("res://", "")), encoding="utf-8").read()
    m = re.search(r'^%s = "(.*)"$' % field, txt, re.M)
    return m.group(1) if m else ""


def attack_hands(path):
    txt = open(os.path.join(ROOT, path.replace("res://", "")), encoding="utf-8").read()
    if re.search(r'^attack_type = "RANGED"', txt, re.M) and re.search(r'&"grenade"', txt):
        return 0                                    # el bombaları elde tutulmaz
    return 2 if re.search(r'^hands = "2H"', txt, re.M) else 1


TRES = '''[gd_resource type="Resource" script_class="ArmouryItem" load_steps={steps} format=3]

[ext_resource type="Script" path="res://scripts/data/armoury_item.gd" id="1"]
{exts}
[resource]
script = ExtResource("1")
item_id = &"{iid}"
name_key = "{nk}"
desc_key = "{dk}"
category = {cat}
cost = {cost}
cost_currency = {curr}
limit_per_warband = {limit}
elite_only = {elite}
required_unit_names = Array[String]([{units}])
required_keywords = Array[StringName]([{kws}])
required_item_id = &"{ritem}"
restriction_key = "{rk}"
granted_attacks = Array[Resource]([{atks}])
armour_value = {armour}
granted_keywords = {{
{gkw}
}}
hands = {hands}
'''


def main():
    os.makedirs(OUT, exist_ok=True)
    parsed = {fid: parse_faction(fid, fn) for fid, fn in FACTIONS.items()}

    # (kalem, fiyat, para, limit, kısıt) demeti benzersiz bir varyanttır
    variants = collections.OrderedDict()
    faction_files = collections.defaultdict(list)
    for fid, items in parsed.items():
        for i in items:
            curr = 1 if (fid, i["name"]) in GLORY_PRICED else 0
            key = (i["name"], i["cat"], i["cost"], curr, i["limit"], i["restrict"])
            if key not in variants:
                base = slug(i["name"])
                fname = base if not any(k[0] == i["name"] for k in variants) else "%s__%s" % (base, fid)
                variants[key] = fname
            faction_files[fid].append(variants[key])

    loc = {"tr": {}, "en": {}}
    for (name, cat, cost, curr, limit, restrict), fname in variants.items():
        is_weapon = cat in ("MELEE", "RANGED", "GRENADE")
        if is_weapon:
            paths = attack_paths(name)
            nk = attack_field(paths[0], "attack_name")
            dk = attack_field(paths[0], "description")
            armour, gkw, hands = 0, {}, attack_hands(paths[0])
        else:
            spec = NONWEAPON[name]
            paths = []
            nk, dk = "ARM_" + slug(name).upper(), "ARM_%s_DESC" % slug(name).upper()
            loc["tr"][nk], loc["en"][nk] = spec["tr"], spec["en"]
            loc["tr"][dk], loc["en"][dk] = spec["tr_d"], spec["en_d"]
            armour, gkw, hands = spec["armour"], spec["kw"], spec["hands"]

        rk = ""
        if restrict:
            rk = "ARM_RESTRICT_" + slug(restrict).upper()
            loc["tr"][rk], loc["en"][rk] = RESTRICT_TEXT[restrict]

        exts, atks = [], []
        for n, p in enumerate(paths, start=2):
            exts.append('[ext_resource type="Resource" path="%s" id="%d"]' % (p, n))
            atks.append('ExtResource("%d")' % n)

        open(os.path.join(OUT, fname + ".tres"), "w", encoding="utf-8").write(TRES.format(
            steps=2 + len(paths), exts="\n".join(exts) + ("\n" if exts else ""),
            iid=slug(name), nk=nk, dk=dk, cat=CAT_ENUM[cat], cost=cost, curr=curr, limit=limit,
            elite="true" if "Elite only" in restrict else "false",
            units=", ".join('"%s"' % u for u in RESTRICT_UNITS.get(restrict, [])),
            kws=", ".join('&"%s"' % k for k in RESTRICT_KEYWORDS.get(restrict, [])),
            ritem=RESTRICT_ITEM.get(restrict, ""), rk=rk, atks=", ".join(atks),
            armour=armour, gkw=",\n".join('&"%s": %d' % kv for kv in gkw.items()), hands=hands))

    # ── faksiyon .tres dosyalarına armoury listesini yaz ─────────────────────
    for fid, files in faction_files.items():
        p = os.path.join(ROOT, "assets/data/factions", fid + ".tres")
        if fid == "court_of_seven_headed_serpent" and not os.path.exists(p):
            p = os.path.join(ROOT, "assets/data/factions/court_of_the_seven_headed_serpent.tres")
        txt = open(p, encoding="utf-8").read()
        txt = re.sub(r'\n\[ext_resource type="Resource" path="res://assets/data/armoury/[^\n]*', "", txt)
        txt = re.sub(r"\narmoury = Array\[Resource\]\(\[[^\]]*\]\)", "", txt)
        used = max([int(m) for m in re.findall(r'id="(\d+)"', txt)] or [0])
        exts, refs = [], []
        for n, f in enumerate(sorted(set(files)), start=used + 1):
            exts.append('[ext_resource type="Resource" path="res://assets/data/armoury/%s.tres" id="%d"]' % (f, n))
            refs.append('ExtResource("%d")' % n)
        txt = txt.replace("\n[resource]", "\n" + "\n".join(exts) + "\n\n[resource]", 1)
        txt = txt.rstrip("\n") + "\narmoury = Array[Resource]([%s])\n" % ", ".join(refs)
        open(p, "w", encoding="utf-8").write(txt)

    # ── lokalizasyon ────────────────────────────────────────────────────────
    for lang in ("tr", "en"):
        p = os.path.join(ROOT, "assets/localization/%s.json" % lang)
        data = json.load(open(p, encoding="utf-8"))
        tgt = data["translations"] if "translations" in data else data
        added = sum(1 for k in loc[lang] if k not in tgt)
        tgt.update(loc[lang])
        json.dump(data, open(p, "w", encoding="utf-8"), ensure_ascii=False, indent=4, sort_keys=True)
        print("%s: +%d yeni anahtar (toplam %d)" % (lang, added, len(tgt)))

    print("%d benzersiz Armoury kalemi üretildi" % len(variants))
    for fid, files in faction_files.items():
        print("  %-32s %d kalem" % (fid, len(set(files))))


if __name__ == "__main__":
    main()
