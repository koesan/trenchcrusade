# Faction Sadakat Denetimi — 05: Cult of the Black Grail

**Kaynak:** `trench_compendium/warbands/cult-of-the-black-grail.md` (1035 satır) + 2 Variant dosyası
**Oyun tarafı:** `assets/data/factions/cult_of_the_black_grail.tres`, 10 birim `.tres`, `injury_resolver.gd`, `turn_manager.gd`, `dice_pool_builder.gd`, `unit.gd`
**Denetim tarihi:** 2026-07-28

---

## 1. Kaynak Materyaldeki Tasarım ve Amaç

### 1.1 Lore ve Tema
Cult of the Black Grail, Cehennem'in **Yedinci Katmanı**'nın efendisi **Beelzebub**'un (Sinekler Efendisi) lanetidir. Compendium'un fraksiyon metni bunu çok net bir cümleyle kurar: Beelzebub *entrika çevirmez — lanetini salıverir*.

Tematik çekirdek dört sütun:

1. **Hastalık bir bulaşma değil, bir hiyerarşidir.** Kara Kase enfeksiyonu canlı ete işler, tümörler ve iltihaplı yaralarla büker; **bedeni yok ederken zihni acı çeksin diye ayakta bırakır**. Kurbanlar iblisçe bir irade altında yeniden kalkar.
2. **Bozulmanın kademeleri.** Cult'un rosteri bir **dönüşüm merdiveni**dir: Grail Thrall (boşaltılmış kabuk) → Fly Thrall (sinek kontrolünde) → Herald of Beelzebub (sinekle kaynaşmış) → Corpse Guard (hayatta kalan güçlü mümin) → Plague Knight (bilinci korumuş asilzade) → Lord of Tumours (Beelzebub ile trans hâlinde iletişim kuran soylu). Her birim, hastalığın bir aşamasıdır.
3. **Amalgam — çoğulluğun dehşeti.** Onlarca bedenin, böceğin ve memelinin *birlikte* enfekte olup kaynaşmasıyla oluşan yürüyen et dağı. Kurbanlarının hayattayken kullandığı silahları hâlâ savuran altı kolu vardır.
4. **Order of the Fly.** Kültün askerî aristokrasisi; kutsal toprakları kirletip Beelzebub'un tapınaklarını kurmayı amaçlar.

### 1.2 Faction Rules — compendium'daki ÜÇ resmî pasif

Bu, denetlenen fraksiyonlar içinde **en zengin resmî fraksiyon kuralı setidir**.

#### (1) Infection Markers
> Bazı Black Grail silahları `[Infection Markers]` keyword'üne sahiptir. Bu silahlar hedefe **Blood Marker yerine Infection Marker** koyar.
>
> - Bir model aynı anda **6 Infection + 6 Blood Marker**'a kadar taşıyabilir.
> - Infection Marker, Blood Marker gibi **harcanabilir**: Success Roll ve Injury Roll'u değiştirmek, Bloodbath'e çevirmek için. **Blood ve Infection aynı atışta birleştirilebilir.**
> - **Blood Marker kaldırmaya izin veren kurallar, Infection Marker'ı kaldıramaz** (açıkça belirtilmedikçe).
> - **Bir modelin üzerinde 1+ Infection Marker varken aktive olursa, hiçbir eylem yapmadan önce +1 Infection Marker daha alır.**

Tasarım amacı: Kara Kase'nin laneti *geri döndürülemez ve büyür*. Rakip, Medi-kit/Laying on Hands gibi iyileştirmelerle Blood Marker'ları temizleyebilir ama enfeksiyonu **temizleyemez**. Enfekte bir model her aktivasyonda daha da kötüleşir → oyuncu ya modeli hiç aktive etmemeye ya da hızla ölmeye zorlanır. Bu, oyundaki **tek geri döndürülemez kaynak**tır.

#### (2) Morale
> *"Fighting against the Cult of the Black Grail is a terrifying prospect. Your opponent must add `[-1 Dice]` to **all Morale Checks** unless their Warband is of either the Court of the Seven-Headed Serpent or the Cult of the Black Grail."*

Fraksiyon-geneli, koşulsuz bir psikolojik baskı. İstisna listesi (Court + Black Grail) tematiktir: Cehennem'in kendi tarafı korkmaz.

#### (3) The Order of the Fly
> Warband kurulurken **Lord of Tumours mu yoksa Plague Knight mı** liderlik edecek seçilmelidir.
> - **Lord of Tumours:** Warband kurulurken bir Lord of Tumours **içermek zorundadır**. En fazla **1 Lord of Tumours + 2 Plague Knight**.
> - **Plague Knight:** Warband kurulurken bir Plague Knight **içermek zorundadır** ve **en fazla 3** olabilir.

Tasarım amacı: iki farklı warband arketipi. "Lord" listesi tek bir devasa +4D melee canavarı etrafında kurulur; "Knight" listesi üç orta seviye zırhlı şövalye etrafında. Bu, roster inşasının **ilk kararıdır** ve fraksiyonun oynanış kimliğini ikiye ayırır.

### 1.3 Oynanış Kimliği (Tabletop Rolü)

- **Zırhsız ama dayanıklı.** 8 çekirdek birimin **tamamı Armour 0**'dır. Dayanıklılık zırhtan değil, **Undead Fortitude** (Fire hariç −1 Injury Dice), **Corpulent** (−2 Injury Dice) ve **Tough**'tan gelir. Sonuç: `[Fire]` silahlar Cult'a karşı olağanüstü etkilidir — bilinçli ve keskin bir zayıflık.
- **Kalabalık + korku.** `[Fear]` **her çekirdek birimde** vardır (istisnasız). Melee'de rakibe sürekli −1D. Buna Morale −1D eklenince Cult, rakibi hem savaş hem moral ekseninde ezer.
- **Overwhelming Horde.** Thrall'lar 3" içindeki her dost için melee'ye **+1D** alır. Yığılma ödüllendirilir — 25 ducat'lık sınırsız Thrall'lar, doğru kümelendiğinde +4D/+5D'ye ulaşır.
- **Hava üstünlüğü.** Fly Thrall (6"/Flying) ve Herald of Beelzebub (**10"/Flying**) — oyunun en hızlı ve tek uçan birimleri.
- **Yavaş ama durdurulamaz çekirdek.** Grail Thrall 5" (oyunun en yavaş birimi), Amalgam 6"/`Unstoppable`, Lord of Tumours 6". Cult *yürür*, koşmaz.

### 1.4 Fraksiyona Özgü Mekanikler

| Birim | Mekanik | Tasarım amacı |
|---|---|---|
| Lord of Tumours | **Melee +4D** (oyunun en yükseği), **Beelzebub's Touch** (melee marker koyarsa +1 ek Infection), **Crushing Blows** (silahsız `[Cleave 2]`) | Tek başına savaş kazanan kaptan |
| Plague Knight | **Undead Fortitude**; **Plague Almoner** (+10 , Bloodbath maliyeti −1), **Knight Companion of the Fly** (+5 , Ranged **veya** Melee +1D), **Knight of the Rotten Cross** (+5 , **New Antioch veya Heretic Legion armoury'sinden** 1 silah) | Modüler zırhlı şövalye; zorunlu zırh |
| Corpse Guard | **Parasite Host** (melee marker koyarsa kendinden 1 marker sil), **Black Grail Bodyguard** (1" içindeki dostun isabetini üstlen; Blast hariç) | Kendini onaran koruma |
| Amalgam | **Six-Armed Monstrosity** (her Ranged silahla 1 Shoot, her Melee silahla 1 Fight; Off-Hand cezası yok), **Corpulent** (−2 Injury Dice), **Trample**, **Unstoppable** | **6 silaha kadar** taşıyan yürüyen batarya |
| Grail Thrall | **Undead Fortitude**, **Overwhelming Horde**; 5" | Ucuz, dayanıklı, yavaş kabuk |
| Fly Thrall | **Overwhelming Horde**, `[Flying]` 6"; **Undead Fortitude YOK** | Hareketlilik ↔ dayanıklılık takası |
| Herald of Beelzebub | **Infected Proboscis** (silahsız `[Infection Markers]` melee + kendinden 1 Blood sil), **Maddening Buzzing** (+10 , LIMIT 1: 8" içindeki düşman Success Roll'ları `[Risky]` olur), `[Skirmisher]`, 10"/Flying | Öncü/keşif + en güçlü debuff aurası |
| Hound of the Black Grail | **Frightening Speed** (+1D Dash; ayağa kalkarken hareket yarılanmaz), **Disease Carrier** (1" içinde aktive olan düşmana +1 Infection), **Infested Carcasses** (+5 , melee'ye `[Infection Markers]`) | Salgının taşıyıcısı |

### 1.5 Mercenaries
Scripture Guardian (7 ), Sin Eater (6 ).

### 1.6 Armoury — enfeksiyon dağıtım sistemi
BG Armoury'sinin ayırt edici yanı, **dört ayrı menzilli enfeksiyon silahı** içermesidir:

| Kalem | Fiyat | Kısıt |
|---|---|---|
| **Corruption Belcher** | 30  | LIMIT 2 |
| **Infested Rifle** | 15  | — |
| **Putrid Shotgun** | 20  | LIMIT 2 |
| **Viscera Cannon** | 50  | LIMIT 2, Elite only |
| **Parasite Grenades** | 15  | — |
| **Beelzebub's Axe** | 30  | LIMIT 1, Elite only |
| **Plague Blade** | 7  | LIMIT 3, Elite only |
| **Black Grail Shield** | 20  | Elite only |
| **Compound Eyes Helmet** | 10  | LIMIT 3, **Herald of Beelzebub**, Elite only |
| **Grail Devotee** | 15  / 2  | LIMIT 2, Herald of Beelzebub, Elite only |
| **Machine Gun** | 50  | LIMIT 1, **Amalgam only** |
| **Armour of the Fly** | 7  | LIMIT 1, Elite only (Exploration) |
| Gas Grenades / Musket / Blunderbuss / Unholy Trinket | 10 /5 /5 /15  | — |

### 1.7 Variant Warband'lar
Dirge of the Great Hegemon, The Great Hunger.

### 1.8 Güçlü / Zayıf Yönler
| Güçlü | Zayıf |
|---|---|
| Infection Markers: geri döndürülemez, büyüyen hasar | `[Fire]` silahlar Undead Fortitude'u tamamen aşar |
| Her birimde `[Fear]` + fraksiyon-geneli Morale −1D | Tüm birimler Armour 0 |
| Overwhelming Horde ile kümelenme ödülü | Kümelenme Blast silahlara açık |
| Lord of Tumours +4D melee | Grail Thrall 5" — oyunun en yavaşı |
| Uçan birimler (Fly Thrall, Herald 10") | Herald/Thrall'lar Melee −1D veya 0D |
| Maddening Buzzing: 8" içinde tüm Success Roll'lar Risky | LIMIT 1 ve +10  |

---

## 2. Oyundaki Uygulama

### 2.1 Roster Karşılaştırması

| Compendium | Cost | Avail | Oyunda | Durum |
|---|---|---|---|---|
| Lord of Tumours (Captain) | 130 | 0-1 | ✅ 130 / 1 | ✔ |
| Plague Knight (Captain + Elite) | 60 | 0-1 / 0-2 | ✅ 60 / 2, `is_leader = true` | ⚠ Order of the Fly yok |
| Corpse Guard (Elite) | 55 | 0-3 | ✅ 55 / 3 | ✔ |
| Amalgam | 140 | 0-1 | ✅ 140 / 1 | ✔ |
| Grail Thrall | 25 | Unlimited | ✅ 25 / 999 | ✔ |
| Fly Thrall | 25 | Unlimited | ✅ 25 / 999 | ✔ |
| Herald of Beelzebub | 50 | 0-4 | ✅ 50 / 4 | ✔ |
| Hound of the Black Grail | 55 | 0-3 | ✅ 55 / 3 | ✔ |
| *Merc:* Scripture Guardian | 7  | 0-1 | ✅ 7 / 1 | ⚠ birim para |
| *Merc:* Sin Eater | 6  | 0-1 | ✅ 6 / 1 | ⚠ birim para |

**10/10 birim mevcut.**

### 2.2 Stat ve Keyword Doğruluğu

```
Lord of Tumours   6"  | +1D | +4D | 0  [Negate Gas][Fear][Strong][Negate Heavy][Tough][Leader][Elite][Black Grail] ✔
Plague Knight     6"  |  0D | +2D | 0  [Negate Gas][Fear][Strong][Negate Heavy][Elite][Black Grail]  ✔
Corpse Guard      6"  |  0D | +1D | 0  [Negate Gas][Fear][Elite][Black Grail]                        ✔
Amalgam           6"  |  0D |  0D | 0  [Negate Gas][Fear][Strong][Negate Heavy][Tough][Black Grail]   ✔
Grail Thrall      5"  |  0D | -1D | 0  [Negate Gas][Fear][Black Grail] + Undead Fortitude             ✔
Fly Thrall        6"F |  0D | -1D | 0  [Negate Gas][Fear][Flying][Black Grail], Undead Fortitude YOK  ✔
Herald            10"F|  0D |  0D | 0  [Negate Gas][Fear][Skirmisher][Flying][Black Grail]            ✔
Hound             8"  |  0D | +1D | 0  [Negate Gas][Fear][Black Grail] + Disease Carrier              ✔
```

**Sıfır sapma.** İki nokta özellikle dikkat çekici:
- **Grail Thrall 5" / Fly Thrall 6"** ayrımı doğru girilmiş (kolayca gözden kaçabilecek bir detay).
- **Fly Thrall'ın Undead Fortitude'u YOK** — compendium bunu bilinçli olarak vermez (*"allowing far greater mobility **in exchange for less resistance to pain**"*). Oyun `has_undead_fortitude = false` ile bunu doğru yakalamış. Bu, veri katmanının ne kadar dikkatli hazırlandığının en iyi kanıtı.

### 2.3 Doğru Uygulanmış Mekanikler

| Mekanik | Nerede | Not |
|---|---|---|
| **Infection Markers — ayrı havuz** | `injury_resolver.gd:57, 137-141` | `[Infection Markers]` silahları Blood **yerine** Infection basıyor; 6 tavan ✔ |
| **Infection ≠ Blood (temizlenemez)** | `ability_executor.gd:275-277` | *"Rules that allow Blood Markers to be removed CANNOT remove Infection Markers"* — kod yorumunda açıkça belgelenmiş ve `_handle_remove_blood` yalnız `blood_markers`'a dokunuyor ✔ |
| **Aktivasyonda +1 Infection büyümesi** | `unit.gd:341-344` | *"If a model activates with one or more Infection Markers, it gains +1"* — Disease Carrier'dan bağımsız, yalnız önceki miktara bakıyor ✔ |
| **Infection harcanabilirliği** | `marker_spend_overlay`, `combat_choice.gd` | Blood ile birleştirilerek Success/Injury/Bloodbath ✔ |
| **Morale −1 Dice** | `turn_manager.gd:450` `morale_fear_penalty()` | Rakip Court **veya** Black Grail değilse −1D ✔ — istisna listesi doğru |
| **Undead Fortitude** | `unit_data.has_undead_fortitude` + injury pipeline | Fire hariç −1 Injury Dice ✔ |
| **Beelzebub's Touch** | `unit.gd:1897` + `mechanics_resolver` | Melee marker koyarsa +1 ek Infection ✔ |
| **Crushing Blows** | `crushing_blows.tres` `has_cleave`, `cleave_count = 2` | Silahsız `[Cleave 2]` melee ✔ |
| **Parasite Host** | `mechanics_resolver.gd`, `unit.gd` | Melee marker koyarsa saldırandan 1 marker sil ✔ |
| **Black Grail Bodyguard** | `unit.gd` | 1" içindeki `[Black Grail]` dostun isabetini üstlenme; Blast istisnası ✔ |
| **Corpulent** | `injury_dice_defence: -2` | Amalgam'a yapılan tüm saldırılara −2 Injury Dice ✔ |
| **Unstoppable** | `unit_actions.gd`, `unit.gd` | ≤32mm düşmanlar retreat'te saldıramaz; Amalgam yine de hareket edebilir ✔ |
| **Six-Armed Monstrosity (mekanik)** | `annihilator` + `ignore_offhand_weapon` | Her silahla ayrı saldırı + Off-Hand cezası yok — **mekanizma hazır** (ama silah yok, bkz. P0-BG-1) ✔/⚠ |
| **Trample** | `CUSTOM_IMPLEMENTED` | Down hedefe `[Ignore Armour]` silahsız melee ✔ |
| **Overwhelming Horde** | `dice_pool_builder.gd:121-122` | 3" içindeki her dost için melee'ye +1D ✔ |
| **Disease Carrier** | `unit.gd` `is_disease_carrier` | 1" içinde aktive olan düşmana +1 Infection ✔ |
| **Frightening Speed** | `dash_dice_bonus` + `ignore_standup_penalty` | **Her iki maddesi de** uygulanmış ✔ |
| **Infested Carcasses** | `hound.tres` Loadout2, +5 , `teeth_and_claws_infested` | Melee'ye `[Infection Markers]` ✔ |
| **Infected Proboscis** | `infected_proboscis.tres` + `unit.gd` | Silahsız `[Infection Markers]` melee + kendinden 1 Blood sil ✔ |
| **Maddening Buzzing** | `heralds.tres` Loadout2 (+10 , `max_per_warband = 1`) + `ability_executor.gd:152` | 8" içindeki düşman Success Roll'ları Risky sayılıyor ✔ — **LIMIT 1 dahil** |
| **Plague Almoner** | `plague_knight.tres` Loadout2, +10  | Bloodbath maliyeti −1 ✔ |
| **Knight Companion of the Fly** | Loadout3/4, +5 , ranged **veya** melee +1D | ✔ — compendium'daki seçim iki ayrı loadout olarak modellenmiş |
| **Flying** | `climbing_resolver.gd`, `unit.gd` | ✔ |
| **Skirmisher (Herald)** | `unit.gd:847` | Hücumdan D3" kaçış ✔ |

**Değerlendirme:** Infection Markers sistemi — compendium'daki en karmaşık fraksiyon kuralı — **eksiksiz ve doğru** uygulanmış. Bu, projedeki en iyi mekanik iştir.

---

## 3. Tespit Edilen Sorunlar

### 🔴 P0-BG-1 — Amalgam altı kollu ama elinde tek bir hançer var

**Bulgu:** `amalgams.tres`:
```
attacks = [legionary_dagger.tres]
keywords = { annihilator: 1, ignore_offhand_weapon: 1, fixed_weapon_loadout: 1, ... }
```

**Compendium:**
> *"An Amalgam **has six arms**, which allows it to carry **a vast combination of different Ranged and Melee Weapons**. It can have **up to six** Ranged or Melee Weapons from the `[Black Grail]` Armoury. In addition, an Amalgam can treat **two 2-Handed Weapons with the `[Heavy]` Keyword** as 1-Handed Weapons... An Amalgam may have up to 1 Trench Shield in place of one of its 1-Handed Weapons."*
>
> **Six-Armed Monstrosity:** *"An Amalgam can take **1 Shoot `[Action]` per Activation with each Ranged Weapon** it is equipped with, and **1 Fight `[Action]` per Activation with each Melee Weapon** it is equipped with."*

**Neden sorun:**
- Amalgam **140 ducat** — fraksiyonun en pahalı birimi ve Lord of Tumours'tan (130) bile pahalı. Ranged 0D / Melee 0D'dir; yani **hiçbir zar bonusu yoktur**. Ödediğin 140 ducat'ın karşılığı **saldırı sayısıdır**, saldırı kalitesi değil. Altı silah = altı saldırı.
- Oyunda `annihilator` mekaniği **doğru şekilde hazır** (her silahla ayrı saldırı) — ama silah verilmediği için tamamen atıl. `fixed_weapon_loadout` ile de kilitlenmiş; oyuncu değiştiremiyor.
- Sonuç: 140 ducat'lık bir birim, 0D melee ile tek bir hançer sallıyor. **25 ducat'lık Grail Thrall'dan daha az saldırı yapıyor** (Thrall en azından Overwhelming Horde ile +1D/+2D alıyor).
- Ayrıca `legionary_dagger` bir **Heretic Legion** silahıdır; BG armoury'sinde Trench Knife (1 ) veya Plague Blade (7 , Elite only) var.
- BG armoury'sinde **Machine Gun 50 , LIMIT 1, "Amalgam only"** kalemi var — bu, oyunda mevcut olan `machine_gun.tres` ile karşılanabilir.

**Olması gereden:** Amalgam'a en az 3–4 silahlık bir varsayılan yükleme (örn. Machine Gun + Great Hammer + Plague Blade + Trench Shield) veya bir loadout seti; `annihilator` zaten hazır olduğu için bu **tamamen veri işi**.

---

### 🔴 P0-BG-2 — Enfeksiyon yayan **menzilli** silah yok; fraksiyonun ana kuralı melee'ye hapsedilmiş

**Bulgu:** Oyundaki tüm attack varlıkları içinde `infection_markers` keyword'ünü taşıyan **yalnızca 2 tane** var:
- `infected_proboscis.tres` (MELEE, Herald)
- `teeth_and_claws_infested.tres` (MELEE, Hound — üstelik +5 'lik opsiyonel bir yükseltmeyle)

**Compendium BG Armoury'sinde dört adet menzilli enfeksiyon silahı vardır:**

| Silah | Fiyat | Kısıt |
|---|---|---|
| **Corruption Belcher** | 30  | LIMIT 2 |
| **Infested Rifle** | 15  | — |
| **Putrid Shotgun** | 20  | LIMIT 2 |
| **Viscera Cannon** | 50  | LIMIT 2, Elite only |
| **Parasite Grenades** | 15  | — |

Lore da bunu doğrudan söyler: *"Heralds wield discarded weapons contaminated with horrible worms that churn through them, which in turn infect their victims. **Each diseased bullet has a sentience of its own**, finding even the smallest chink in any armour, burrowing into the nervous system and liquefying the internal organs from within."*

**Neden bu P0:**
1. **Infection Markers, bu fraksiyonun 1 numaralı resmî kuralıdır.** Oyunda tam ve doğru uygulanmış (bkz. §2.3) — ama onu *tetikleyecek* araç neredeyse yok. Motor hazır, mühimmat yok.
2. Enfeksiyon yalnız **1" mesafede** yayılabiliyor. Oysa fraksiyonun tezi "salgın *yayılır*"dır. Rakip, Cult'un melee birimlerinden uzak durarak enfeksiyon mekaniğinin tamamını devre dışı bırakabiliyor.
3. **Herald of Beelzebub** özellikle sakatlanıyor: 10" uçan, Ranged 0D bir birim; compendium ona *"any Ranged Weapon from the Black Grail Armoury Tables"* verir — yani menzilli enfeksiyon dağıtımı Herald'ın ana işidir. Oyunda elinde `legionary_gasbomb` (yine bir **Heretic Legion** varlığı) ve enfeksiyonsuz.
4. Bu, mekanik olarak "uygulanmış ama ulaşılamaz" bir sistemdir — denetimdeki en ironik bulgu: **projenin en iyi kodlanmış sistemi, veri eksikliği yüzünden oyunda görünmüyor.**

---

### 🔴 P0-BG-3 — The Order of the Fly uygulanmamış

**Bulgu:** `cult_of_the_black_grail.tres` `has_faction_rule = true` ve `FACTION_CULT_OF_THE_BLACK_GRAIL_RULES` metni kuralı **doğru şekilde tarif ediyor**. Ancak kodda karşılığı yok:
- `DeployValidator.REASON_RATIO` var, ama `game.gd:594-608`'de **yalnız Court of the Seven-Headed Serpent'in Wretched kuralı** için kullanılıyor.
- `FactionRules.gd` içinde Black Grail için hiçbir fonksiyon yok.
- `grep -rn "order_of_the_fly"` → boş.

**Oyundaki yaklaşık davranış:** `lord_of_tumours.availability_max = 1`, `plague_knight.availability_max = 2`. Bu, compendium'un **yalnız "Lord of Tumours liderliğinde"** dalını kabaca taklit ediyor.

**Eksik olanlar:**
1. *"Your warband **must include** a Lord of Tumours"* / *"must include a Plague Knight"* — **zorunluluk hiç denetlenmiyor**. Oyuncu ikisini de almadan sahaya çıkabilir (fraksiyonun lidersiz kalması compendium'da imkânsızdır).
2. **"Plague Knight liderliğinde 1-3 Plague Knight" dalı ulaşılamaz.** `availability_max = 2` sabit olduğu için 3 Plague Knight'lık liste kurulamıyor. Bu, fraksiyonun **iki arketipinden birini tamamen siliyor**.
3. İki dal arasında bir **seçim adımı** yok. Compendium bunu *"When your warband is created, you must choose"* diye tanımlar — yani bu, Court'un Seven Deadly Sins seçimiyle aynı türde bir roster-inşa kararıdır (ki o oyunda `FactionData.selected_sin` ile modellenmiş).

**Olması gereken:** `FactionData`'ya `selected_sin` ile aynı desende bir `order_of_the_fly_leader: StringName` (`lord` / `knight`) alanı; deploy'da liderlik zorunluluğu ve dala göre dinamik availability.

---

### 🔴 P0-BG-4 — Mercenary ekonomisi (fraksiyon-üstü; bkz. P0-NA-3)

Scripture Guardian 7 + Sin Eater 6 = **13 puan**. Bir Grail Thrall 25 . İki mercenary'nin toplamı, en ucuz Cult modelinin yarısından ucuz.

Cult'a özel şiddeti: **Sin Eater `[Demonic]`, `[Fear]`, `[Tough]`, `[Strong]`, `[Negate Fire]`, Melee +2D, Armour −2**. Cult'un **en büyük zayıflığı `[Fire]` silahlardır** (Undead Fortitude Fire'a karşı işlemez) — ve 6 puanlık bir mercenary o zayıflığı `[Negate Fire]` ile kapatıyor, üstelik fraksiyonun tek zırhlı modeli olarak. Compendium'da bu birim bir **kampanya ödülüdür**, ilk kadro seçeneği değil.

---

### 🟠 P1-BG-5 — Plague Knight'ın zorunlu zırhı yok

**Bulgu:** `plague_knight.tres` `armour = 0`, zırh loadout'u yok. Loadout seçenekleri yalnız Plague Almoner (+10) ve Knight Companion (+5, ranged/melee).

**Compendium:** *"A Plague Knight can have any Battlekit from the Cult of the Black Grail Armoury Tables. **It must have a suit of Armour.** No restrictions apply to any other Types of Battlekit."*

**Neden sorun:** Plague Knight `[Elite]`'tir; BG armoury'sinde Reinforced Armour (40 , Elite only, **−2**) ve Standard Armour (15 , **−1**) alabilir. Compendium'da zırh **zorunludur** — yani sahadaki her Plague Knight en az −1, tipik olarak −2 zırhla gelir. Oyunda Armour 0.

Bu, birimin hem hayatta kalma matematiğini hem lore'unu bozuyor: *"these **great armoured warriors**... retain a semblance of sentience and **the ability to wield weapons as they did in life**."* Plague Knight, Cult'un **tek zırhlı birimidir** — fraksiyonun "hepsi Armour 0" profilindeki tek istisnası. O istisna silinince Plague Knight ile Corpse Guard arasındaki rol farkı da siliniyor.

---

### 🟠 P1-BG-6 — Knight of the Rotten Cross yok (oyunun tek çapraz-armoury kuralı)

**Compendium:** *"**Knight of the Rotten Cross — 5 , Limit: 1.** You can purchase 1 Ranged Weapon or 1 Melee Weapon from the **New Antioch or Heretic Legions Armoury Tables** for this model."*

**Neden özellikle önemli:** Bu, Trench Crusade'de bir fraksiyonun **başka fraksiyonun armoury'sine erişebildiği tek kuraldır**. Lore gerekçesi net: Plague Knight'lar *"hayattayken silah kullanma yetisini korumuş"* asilzadelerdir — yani Kültten önceki hayatlarının (Sadık veya Sapkın) silahlarını hâlâ taşıyabilirler. Bu, birimin lore'unun **doğrudan mekanik ifadesidir**.

Oyunda yok. Ayrıca oyunun `available_units` tabanlı roster mimarisi (fraksiyon başına küratörlü liste) bu kuralı ifade etmeye şu an uygun değil — bir `LoadoutOption` ile modellenmesi gerekir.

---

### 🟠 P1-BG-7 — BG'ye özgü Armoury kalemlerinin **hiçbiri** yok; yerine başka fraksiyonların silahları kullanılmış

| Compendium kalemi | Fiyat | Oyunda |
|---|---|---|
| Corruption Belcher | 30  (L2) | ❌ |
| Infested Rifle | 15  | ❌ |
| Putrid Shotgun | 20  (L2) | ❌ |
| Viscera Cannon | 50  (L2, Elite only) | ❌ |
| Parasite Grenades | 15  | ❌ |
| Beelzebub's Axe | 30  (L1, Elite only) | ❌ |
| Plague Blade | 7  (L3, Elite only) | ❌ |
| Black Grail Shield | 20  (Elite only) | ❌ |
| Compound Eyes Helmet | 10  (L3, Herald + Elite only) | ❌ |
| Grail Devotee | 15  / 2  (L2, Herald + Elite only) | ❌ |
| Machine Gun (Amalgam only) | 50  (L1) | ⚠ varlık var, Amalgam'a verilmemiş |
| Armour of the Fly | 7  (L1, Elite only) | ❌ |
| Musket / Blunderbuss | 5  / 5  | ❌ |

**Yerine kullanılan silahlar ve kaynakları:**

| Birim | Oyundaki silah | Gerçek sahibi |
|---|---|---|
| Corpse Guard | `legionary_dagger` | **Heretic Legion** |
| Amalgam | `legionary_dagger` | **Heretic Legion** |
| Herald of Beelzebub | `legionary_gasbomb` | **Heretic Legion** |
| Plague Knight | `rot_grenade` | **Uydurma** (BG'de Frag/Rot Grenade yok) |
| Grail/Fly Thrall | `feeble_flailing` | Ecclesiastic Prisoner (**Trench Pilgrims**) |

**Neden sorun:** Cult of the Black Grail'in görsel/tematik dili — sinek, kurtçuk, irin, tümör — silah isimlerinde yaşar (Corruption Belcher, Viscera Cannon, Putrid Shotgun, Beelzebub's Axe, Compound Eyes Helmet). Bunların yerine Heretic Legion hançerleri ve gaz bombaları konunca fraksiyon, "yeşile boyanmış Heretic Legion"a dönüşüyor.

Ek olarak `rot_grenade` **uydurma bir kalemdir**: Blast 2", Ignore Cover, ama `is_poison = false` ve `infection_markers` **yok**. Yani "çürüme bombası" adında ama ne zehirli ne enfekte edici bir silah. Yerini alması gereken **Parasite Grenades**'tir ve o `[Infection Markers]` taşımalıdır.

---

### 🟠 P1-BG-8 — 2 Variant Warband yok

**Dirge of the Great Hegemon**, **The Great Hunger**. İkisi de fraksiyonun "bozulmanın kademeleri" temasını farklı yönlere çeker. Yokluklarında Cult tek bir arketiple sınırlı kalıyor — ki Order of the Fly'ın da uygulanmamış olmasıyla birleşince (P0-BG-3), fraksiyon oyunda **tek bir liste** olarak var oluyor.

---

### 🟡 P2-BG-9 — Küçük sapmalar

| # | Bulgu | Compendium | Oyun |
|---|---|---|---|
| a | Herald'ın el bombası | Herald *"can have any **Ranged Weapon**... cannot have any other Battlekit **apart from a Compound Eyes Helmet**"* — grenade **alamaz** | `legionary_gasbomb` verilmiş |
| b | `plague_sword` `is_poison = true` | Compendium'da "Plague Blade" (7 ) var; `[Gas]` keyword'ü **belirtilmemiş** | `is_poison = true` → `[Gas]` sayılıyor. Sonuç: BG'nin kendi kılıcı, `[Negate Gas]` taşıyan **tüm BG birimlerine** karşı ekstra marker basmıyor (aynalı maçta sessiz bir zayıflık) |
| c | Dosya/birim adı çoğulluğu | Amalgam, Herald of Beelzebub (tekil) | `amalgams.tres`, `heralds_of_beelzebub.tres` — `unit_name` doğru tekil ✔, yalnız dosya adı |
| d | Lord of Tumours yazımı | Compendium başlığı "Lord of **Tumors**", gövde metni "Lord of **Tumours**" | Oyun "Lord of Tumours" — gövde metnine uyumlu ✔ |
| e | `FACTION_CULT_OF_THE_BLACK_GRAIL_RULES` metni | Infection Markers + Morale + Order of the Fly | **Compendium'a sadık** ✔ — ama tarif ettiği Order of the Fly kuralı kodda yok (P0-BG-3), yani oyuncuya uygulanmayan bir kural gösteriliyor |
| f | `FACTION_CULT_OF_THE_BLACK_GRAIL_STORY` | — | **Compendium'dan neredeyse birebir** ✔ |
| g | Amalgam `has_undead_fortitude = false` | Compendium Amalgam'a Undead Fortitude vermez (Corpulent + Tough var) | ✔ doğru |

---

## 4. Özet Skor — Cult of the Black Grail

| Eksen | Skor | Gerekçe |
|---|---|---|
| **Roster kompozisyonu** | 10/10 | 10/10 birim |
| **Stat sadakati** | 10/10 | Sıfır sapma; Grail/Fly Thrall ayrımı ve Fly Thrall'ın Undead Fortitude yokluğu dahil |
| **Keyword sadakati** | 10/10 | Tümü doğru |
| **Fraksiyon pasifi** | 7/10 | Infection Markers **kusursuz**, Morale −1D **kusursuz**, Order of the Fly **hiç yok** (3'te 2) |
| **Birim yetenekleri** | 9/10 | 20+ yetenek doğru; Maddening Buzzing/Frightening Speed/Parasite Host örnek nitelikte |
| **Ekipman / Armoury** | 1/10 | 13 kalemin **hiçbiri** yok; enfeksiyon silahları yok; Amalgam silahsız; başka fraksiyonların silahları kullanılmış |
| **Ekonomi** | 3/10 | Glory Point ↔ ducat; Plague Knight zorunlu zırhı fiyatlanmamış |
| **Lore / tema** | 6/10 | Lore metni birebir ✔; ama silah/ekipman isimleri Heretic Legion'dan ödünç, 2 Variant yok |
| **Oynanış kimliği** | 6/10 | Korku + kalabalık + dayanıklılık eksenleri sağlam; **enfeksiyon yayma ekseni melee'ye hapsedilmiş**, Amalgam işlevsiz |

**Genel: 6.9 / 10**

**Bu fraksiyonun karakteristik durumu:** Projedeki **en iyi kodlanmış sistem** (Infection Markers) burada. Motor tarafı kusursuz — ayrı marker havuzu, birleşik harcama, temizlenememe, aktivasyonda büyüme, hepsi doğru. Ama o motoru besleyecek **silah verisi yok**. Cult, "mükemmel çalışan ama yakıtı olmayan makine" durumunda.

### Öncelik sırası
1. **P0-BG-2** Menzilli enfeksiyon silahları (`infested_rifle`, `putrid_shotgun`, `corruption_belcher`, `viscera_cannon`, `parasite_grenades` — hepsi `keywords = {infection_markers: 1}`). **En yüksek etki/maliyet oranı olan düzeltme:** motor zaten hazır, sadece `.tres` gerekiyor
2. **P0-BG-1** Amalgam'a çoklu silah yüklemesi (`annihilator` zaten hazır)
3. **P0-BG-3** Order of the Fly (`selected_sin` deseniyle `order_of_the_fly_leader`)
4. **P0-BG-4** Glory Point / ducat ayrımı (fraksiyon-üstü)
5. **P1-BG-5** Plague Knight'a zorunlu zırh loadout'u
6. **P1-BG-7** BG'ye özgü silahlar; Heretic Legion varlıklarını değiştir
7. **P1-BG-6** Knight of the Rotten Cross
8. **P2-BG-9a/b** Herald'ın grenade'ini kaldır; `plague_sword`'ün `is_poison`'ını gözden geçir
