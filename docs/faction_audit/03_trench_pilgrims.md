# Faction Sadakat Denetimi — 03: Trench Pilgrims

**Kaynak:** `trench_compendium/warbands/trench-pilgrims.md` (1276 satır) + 3 Variant dosyası
**Oyun tarafı:** `assets/data/factions/trench_pilgrims.tres`, 12 birim `.tres`, `mechanics_resolver.gd`, `ability_executor.gd`, `unit.gd`, `turn_manager.gd`
**Denetim tarihi:** 2026-07-28

---

## 1. Kaynak Materyaldeki Tasarım ve Amaç

### 1.1 Lore ve Tema
Trench Pilgrims **bir ordu değil, bir alaydır** (*Procession*). Kilise onları resmen tanımaz ama seferlerini kutsar. Bunlar "deliler ve sakatlar, Tanrı'ya dokunulmuşlar ve suçluluk yüklüler" — Peygamberlerin etrafında toplanıp cepheye yürüyen, **düzensiz** gruplardır.

Tematik çekirdek beş sütun:

1. **Vizyon ve kehanet.** Alayı yönlendiren şey strateji değil, War Prophet'in Armageddon vizyonlarıdır. Hoparlörlerden 100 desibelde vaaz yayınlanır.
2. **Korkunun cerrahi olarak çıkarılması.** **Iron Capirote** (demir külah) takan bir Pilgrim'in zihni tahkim edilir; Cehennem'in en derin Bolgia'larından gelen iblisler karşısında bile geri adım atmaz. `[Negate Fear]` bu fraksiyonun ontolojisidir, bir bonus değil.
3. **Acı = güç.** Stigmatic Nun'lar, Üçüncü Meta-Christ'in yaralarını taşır ve **her kanayan yara onları güçlendirir**. `[Regenerate 1]` + *Blessed Stigmata* (temizlenen her Blood Marker → +1 Blessing Marker) bu teolojinin doğrudan mekanik tercümesidir.
4. **Şehitlik bir hedeftir, bir risk değil.** Ecclesiastic Prisoner'lar yüksek patlayıcı kuşanmış, zincire vurulmuş günahkârlardır. Ölmek onlar için başarısızlık değil, **amaç**tır (*Awaited*: Martyrdom Device ile ölen Morale sayımına girmez).
5. **Disiplin kırbaçla sağlanır.** Castigator, "Tanrı korkusunu askere işleyen" ortodoks subaydır. **Whip of God**, kendi adamını öldürerek warband'ın moralini yükseltir — bu, oyundaki en karanlık ve en karakteristik mekaniktir.

### 1.2 Oynanış Kimliği (Tabletop Rolü)

**Trench Pilgrims, "kitlesel intihar hücumu" fraksiyonudur.**

- **`## Faction Rules` bölümü YOKTUR.** Heretic Legion gibi, kimlik birim yeteneklerinden gelir. (Oyundaki `has_faction_rule = false` **doğru**.)
- **En ucuz gövde.** Ecclesiastic Prisoner 20  (Unlimited) — oyunun en ucuz modeli. Trench Pilgrim 30  (Unlimited). Sayı üstünlüğü fraksiyonun temelidir.
- **Menzil neredeyse yok.** Communicant Ranged **−3D**. War Prophet ve Castigator +2D/+1D ranged'e sahip ama fraksiyon armoury'sinde ciddi bir menzilli silah yok (Musket, Blunderbuss, Punt Gun — hepsi antika/kısa menzil). Pilgrims **kapanmak zorundadır**.
- **Alay hareketi.** *Loudspeakers* fraksiyonun imza hamlesidir: 8" içindeki **tüm** dost modeller 3" ilerler ve **düşmanın 1" içine girerse hücum sayılır**. Tek eylemle bütün alayı düşman hattına çarpma.
- **Ayağa kaldırma.** *Enforced Orthodoxy* (8" içindeki tüm Down dostlar bedava ayağa kalkar) — kitlesel hücumun ardından gelen kayıpları anında telafi eder.
- **İki dev.** Anchorite Shrine (140 , `[Fear]`, Armour −3) ve Communicant (100 , `[Tough]`+`[Regenerate 1]`+`[Strong]`) — ucuz kalabalığın içindeki iki çekirdek.
- **Yıkım paketi.** Martyrdom Device: 3" yarıçapta herkese Injury Roll, taşıyıcının kendisine **4D6 toplamı**. Ama **35 , LIMIT 4, yalnız Ecclesiastic Prisoner**.

### 1.3 Fraksiyona Özgü Mekanikler

| Birim | Mekanik | Tasarım amacı |
|---|---|---|
| War Prophet | **Loudspeakers** (8"/3"/hücum sayılır), **Laying on Hands** (6", 1 Blood Marker; crit'te 3), **Memento Mori** (ilk OOA → No Effect; `[Tough]` alamaz) | Alayın motoru; ölümsüz görünen ama Tough'suz lider |
| Castigator | **Enforced Orthodoxy** (+1D Risky, 8" içindeki Down dostlar kalkar), **Whip of God** (dostu öldür → sonraki Morale Check'e +1D) | Disiplin; kendi kaynağını yakan lider |
| Communicant | **Pilgrim Bodyguard** (1" içindeki `[Pilgrim]` dosta gelen isabeti üstlenir; Blast hariç), Communicant Cross | Canlı kalkan |
| Anchorite Shrine | **Broken on the Wheel** (bir Pilgrim/Prisoner kalıcı feda → Armour 0 + Down→Minor Hit + ilk OOA→No Effect, sonra −3/Tough/Negate Shrapnel'e döner), **Symphony of Slaughter** | Kurban üzerine kurulu iki-fazlı tank |
| Ecclesiastic Prisoner | **Awaited**, **Mad Dash** (+1D Dash), **Feeble Flailing** (−1D silahsız melee) | Feda edilebilir hızlı gövde |
| Stigmatic Nun | **Agile** (+1D Climb/Jump/Diving Charge/Dash), **Blessed Stigmata**, 8" hareket, `[Regenerate 1]` | Hızlı vurucu; acıdan besleniyor |
| Trench Pilgrim | **Zealot Strength** (+5 , `[Strong]`), **Martyr Penitent Resurrection** (45 , kampanya) | Ölçeklenebilir gövde |

### 1.4 Mercenaries (6 adet)
Sister of Saint Cosmas (2 ), Communicant Anti-Tank Hunter (5 ), Mendelist Ammo Monk (2 ), **Observer (3 )**, Scripture Guardian (7 ), Witchburner (5 ).

### 1.5 Armoury — fraksiyonun karakteri
TP Armoury'si, lore'daki tek cümlenin doğrudan mekanik karşılığıdır:

> *"They arm themselves with **anything they can get their hands on**, from **antique muskets** to **scourges** and **Molotov cocktails**."*

| Kalem | Fiyat | Kısıt |
|---|---|---|
| **Musket** | 5  | — |
| **Blunderbuss** | 5  | — |
| **Punt Gun** | 20  | LIMIT 2 |
| **Flail / Scourge** | 5  | — |
| **Molotov Cocktail** | 5  | — |
| **War-Cross** | 5  | (Nun'ın alabildiği tek el bombası) |
| **Anti-Tank Hammer** | 35  | LIMIT 3, Elite only |
| **Martyrdom Device** | **35 ** | **LIMIT 4, Ecclesiastic Prisoner only** |
| **Martyrdom Pills** | 20  | LIMIT 3 |
| **Iron Capirote** | 7  | — |
| Holy Icon Shield / Blessed Icon / Holy Relic | 2  / 15  / 2  | — |
| Donkey's Jawbone | 4  | Exploration |

Dikkat: TP Grenades listesi **yalnız** Incendiary Grenades, Molotov Cocktail ve War-Cross'tan oluşur — **Frag Grenade yoktur**.

### 1.6 Variant Warband'lar
Procession of the Sacred Affliction, Cavalcade of the Tenth Plague, War Pilgrimage of Saint Methodius. (Compendium'daki TP birim görsellerinin neredeyse tamamı `procession-of-the-sacred-affliction` etiketlidir — yani bu variant, fraksiyonun varsayılan görsel kimliğidir.)

### 1.7 Güçlü / Zayıf Yönler
| Güçlü | Zayıf |
|---|---|
| En ucuz modeller → en kalabalık warband | Menzilli ateş gücü fiilen yok |
| Loudspeakers ile tek eylemde toplu hücum | Zırh neredeyse yok (çoğu birim Armour 0) |
| Enforced Orthodoxy ile kitlesel ayağa kalkma | Kayıplar Morale Check'i hızla tetikler |
| Whip of God ile Morale'i satın alma | Whip of God kendi modelini harcar |
| Blessed Stigmata: hasar → Blessing ekonomisi | Nun 50  ve zırhsız; Regenerate yalnız 1 |
| Martyrdom Device: 4 adet güçlü yıkım paketi | 35  + LIMIT 4 → kıt kaynak |

---

## 2. Oyundaki Uygulama

### 2.1 Roster Karşılaştırması

| Compendium | Cost | Avail | Oyunda | Durum |
|---|---|---|---|---|
| War Prophet (Captain) | 80 | 1 | ✅ 80 / 1 | ✔ |
| Castigator (Elite) | 50 | 0-1 | ✅ 50 / 1 | ✔ |
| Communicant (Elite) | 100 | 0-1 | ✅ 100 / 1 | ✔ |
| Anchorite Shrine | 140 | 0-1 | ✅ 140 / 1 (adı "Shrine Anchorite") | ⚠ ad ters |
| Ecclesiastic Prisoner | 20 | Unlimited | ✅ 20 / 999 | ✔ |
| Stigmatic Nun | 50 | 0-4 | ✅ 50 / 4 | ✔ |
| Trench Pilgrim | 30 | Unlimited | ✅ 30 / 999 | ✔ |
| *Merc:* Sister of Saint Cosmas | 2  | 0-1 | ✅ (`combat_medic.tres`) 2 / 1 | ⚠ birim para |
| *Merc:* Communicant Anti-Tank Hunter | 5  | 0-1 | ✅ 5 / 1 | ⚠ birim para |
| *Merc:* Mendelist Ammo Monk | 2  | 0-1 | ✅ 2 / 1 | ⚠ birim para |
| ***Merc:* Observer** | **3 ** | **0-1** | ❌ **YOK** | 🔴 **eksik** |
| *Merc:* Scripture Guardian | 7  | 0-1 | ✅ 7 / 1 | ⚠ birim para |
| *Merc:* Witchburner | 5  | 0-1 | ✅ 5 / 1 | ⚠ birim para |

**12/13 birim mevcut** — Observer eksik (bkz. P0-TP-2).

### 2.2 Stat ve Keyword Doğruluğu

```
War Prophet       6" | +2D | +2D |  0  [Leader][Elite][Pilgrim] + Memento Mori, Tough YOK  ✔
Castigator        6" | +1D | +1D |  0  [Elite][Pilgrim]                                     ✔
Communicant       6" | -3D | +2D |  0  [Regenerate 1][Strong][Negate Heavy][Tough][Elite][Pilgrim]
                                       + Cross: [Negate Shrapnel][Negate Gas][Negate Fear]   ✔
Anchorite Shrine  6" |  0D | +2D | -3  [Negate Shrapnel][Fear][Strong][Negate Heavy][Tough][Pilgrim] ✔
Eccl. Prisoner    6" |  0D | -1D |  0  [Pilgrim] + Capirote: [Negate Shrapnel][Negate Fear]  ✔
Stigmatic Nun     8" | +1D | +1D |  0  [Regenerate 1][Pilgrim]                               ✔
Trench Pilgrim    6" |  0D |  0D |  0  [Pilgrim]                                             ✔
Sister of St Cosmas 6"| 0D |  0D | -1  [Negate Fear]                                         ✔
Communicant ATH   6" | +1D | +1D | -1  [Regenerate 1][Strong][Negate Heavy][Tough]           ✔
```

**Sıfır stat sapması.** War Prophet'in `has_tough = false` bırakılması özellikle dikkatli — compendium açıkça *"A War Prophet cannot have the `[Tough]` Keyword"* der.

### 2.3 Doğru Uygulanmış Mekanikler

| Mekanik | Nerede | Not |
|---|---|---|
| **Faction Rules yokluğu** | `has_faction_rule = false` | Compendium'da bölüm yok — **doğru** ✔ |
| **Memento Mori** | `injury_resolver.gd:160` | İlk OOA → No Effect, tek kullanımlık; Tough'la çakışmıyor ✔ |
| **Laying on Hands** | `remove_blood` efekt tipi | 6", Success → 1, Crit → 3 Blood Marker ✔ |
| **Enforced Orthodoxy** | `CUSTOM_IMPLEMENTED` | Risky +1D, 8" içindeki Down dostlar kalkar ✔ |
| **Whip of God** | `unit.gd:1861-1866` + `TurnManager.pending_morale_bonus_dice` | Dostu melee ile OOA edince sonraki Morale Check'e +1D ✔ — **compendium'a tam sadık** |
| **Pilgrim Bodyguard** | `combat_choice.gd`, `unit.gd` | 1" içindeki `[Pilgrim]` dostun isabetini üstlenme; Blast istisnası ✔ |
| **Broken on the Wheel** | `shrine_anchorite.tres` Loadout2 + `injury_resolver.gd:148` | Armour 0, Tough/Negate Shrapnel yok, Down→Scratch, ilk OOA→No Effect, sonra −3/Tough/Negate Shrapnel'e dönüş — **tüm alt maddeler doğru** ✔ |
| **Symphony of Slaughter silahları** | `catherine_wheel.tres` / `bonebreaker_mace.tres` | Catherine Wheel `[+1 Dice][Deadly][Heavy][Risky]`; Bonebreaker Mace `[+1 Injury Dice][Risky]` — **birebir** ✔ |
| **Martyrdom Device** | `mechanics_resolver.gd:297-320` | 3" yarıçap, taşıyıcıya **4D6 toplamı**, 1" içindekilere **+1 Injury Dice** — **birebir** ✔ |
| **Awaited** | `mechanics_resolver.gd` + `TurnManager.exempt_from_morale_count` | Martyrdom ile ölen Morale sayımına girmez ✔ |
| **Mad Dash** | `dash_dice_bonus` | +1D Dash Risky Roll ✔ |
| **Feeble Flailing** | `feeble_flailing.tres` `dice_modifier = -1` | ✔ |
| **Agile** | `unit.gd` | Climb/Jump/Diving Charge/Dash +1D ✔ |
| **Regenerate 1** | `mechanics_resolver.compute_regeneration` | X-değerli `regenerate` keyword'ü destekli ✔ |
| **Blessed Stigmata** | `unit.gd:336` | Regenerate ile temizlenen her marker → +1 Blessing Marker ✔ |
| **Zealot Strength** | `castigator.tres` / `trench_pilgrim.tres` Loadout2 | +5 , `[Strong]` ✔ |
| **Iron Capirote** | `negate_shrapnel` + `negate_fear` (Prisoner'a gömülü) | ✔ |
| **Misericordia — Despatch** | `misericordia.tres` `despatch: 1` | Down hedefe Ignore Armour ✔ |

---

## 3. Tespit Edilen Sorunlar

### 🔴 P0-TP-1 — Martyrdom Device ücretsiz, sınırsız ve her Prisoner'da doğuştan var

**Bulgu:** `ecclesiastic_prisoner.tres` yetenekleri: `trigger_martyrdom_device`, `awaited`, `mad_dash`, `iron_capirote`. **`loadout_options` boş.** Yani sahaya inen her Ecclesiastic Prisoner, Martyrdom Device'a **ek ücret ödemeden** sahip.

**Compendium (hem warband hem armoury tablosu):**
> *"An Ecclesiastic Prisoner always has an Iron Capirote. **Up to 4** Ecclesiastic Prisoners can have a Martyrdom Device for **35 **. They cannot have any other Battlekit."*
> Armoury: **Martyrdom Device — 35 , LIMIT: 4, Ecclesiastic Prisoner only**

**Neden sorun — üç katmanlı:**

**(a) Ekonomi.** Compendium'da bir bombacı 20 + 35 = **55 ducat**tır ve warband'da **en fazla 4 tane** olabilir → toplam 220 ducat. Oyunda bir bombacı **20 ducat**tır ve **sınırsız**dır → 700 ducat bütçeyle **35 canlı bomba**. Fraksiyonun tüm maliyet eğrisi çöküyor.

**(b) Denge.** Martyrdom Device 3" yarıçapta *herkese* Injury Roll atar ve 1" içindekilere +1 Injury Dice verir. 35 bombacılık bir liste, rakip hangi fraksiyon olursa olsun deterministik olarak siler. Bu, oyunun tek baskın stratejisi hâline gelir.

**(c) Tema — en önemlisi.** Compendium'da şehitlik **kıt ve pahalı** bir kaynaktır; bu kıtlık kasıtlıdır. Alayın çoğunluğu *savaşır*, sadece birkaçı *patlar*. Oyunda şehitlik varsayılan davranışa dönüşünce "Tanrı'ya adanmış çaresiz alay" teması, "canlı bomba spam'i"ne indirgeniyor. Kaynak materyalin tematik yükü tersine çevriliyor.

**Olması gereken:** `ecclesiastic_prisoner.tres`'e iki `LoadoutOption`: (1) Standard (cost_delta 0, `trigger_martyrdom_device` yok), (2) Martyrdom Device (`cost_delta = 35`, `max_per_warband = 4`). `awaited` de cihazla birlikte gelmeli (compendium'da Awaited yalnız *"when their Martyrdom Device is triggered"* geçerlidir).

---

### 🔴 P0-TP-2 — Observer mercenary'si Trench Pilgrims rosterinde yok

**Bulgu:** `trench_pilgrims.tres` `available_units` içinde `observer.tres` **bulunmuyor**. Oysa:
- Compendium TP Mercenaries listesinde Observer (3 , 0-1) **açıkça vardır**.
- `assets/data/units/observer.tres` oyunda **zaten mevcut** ve New Antioch rosterine eklenmiş.
- Yetenekleri (`eye_of_god`, `voice_of_god`, `lightning_speed`, `temporal_fuge`) **zaten uygulanmış**.

**Neden sorun:** Observer, TP için mekanik olarak önemli: `Voice of God` (sahadaki herhangi bir modeli anında aktive ettirme) Trench Pilgrims'in "toplu hücum" ekseniyle doğrudan sinerji kurar — Loudspeakers ile hücuma kalkan bir Nun'ı veya Communicant'ı sıra dışı aktive edebilir. Ayrıca 8" hareket + Melee +2D ile alayın en hızlı vurucusudur.

Bu, **tek satırlık bir veri eksikliği** (rostere bir `ExtResource` eklemek) ama fraksiyonun araç kutusundan tam bir birim eksiltiyor.

---

### 🔴 P0-TP-3 — Mercenary ekonomisi (fraksiyon-üstü; bkz. P0-NA-3)

TP, bu sorundan **en çok etkilenen** fraksiyondur çünkü mercenary sayısı en fazla olan fraksiyondur (6 adet, oyunda 5).

Oyundaki maliyetler: Sister of Saint Cosmas **2**, Mendelist Ammo Monk **2**, Witchburner **5**, Communicant ATH **5**, Scripture Guardian **7** → toplam **21 puan**. Bir tek Trench Pilgrim 30 . Yani beş mercenary'nin tamamı, tek bir sıradan hacının fiyatının altında.

Özellikle **Communicant Anti-Tank Hunter** (5 puan): `[Regenerate 1][Strong][Negate Heavy][Tough]`, +1D/+1D, Anti-Materiel Rifle (36", `[+1 Injury Dice][Critical][Ignore Armour][Heavy]`) + Iron Fists (`[Cleave 2]`). Bu birim, oyundaki **100 ducat'lık Communicant'tan daha iyi bir menzilli platform** ve fiyatı 5.

---

### 🟠 P1-TP-4 — Loudspeakers'ın "hücum sayılır" maddesi eksik

**Bulgu:** `_handle_move_allies` (`ability_executor.gd:333-361`) dost modelleri en yakın düşmana doğru 3" ilerletiyor, ama:

| Compendium maddesi | Oyunda |
|---|---|
| *"move all friendly models within 8" up to 3""* | ✔ (caster hariç) |
| *"end the move as close as possible to the nearest enemy model **that was visible to them** at the start of the move"* | ❌ LoS kontrolü yok, en yakın düşman körlemesine seçiliyor |
| *"can be used to bring a model within 1" of an enemy model in which case **the model counts as charging**"* | ❌ **Hiç uygulanmamış** |
| *"If no enemy models are visible, they can move normally."* | ❌ Yok |

**Neden sorun:** *"counts as charging"* maddesi bu yeteneğin **tek gerçek payoff'u**dur. Trench Crusade'de charge, Charge Bonus zarını (ve dolayısıyla melee saldırı fırsatını) getirir. Onsuz Loudspeakers sadece "herkesi 3" ileri it" olur — konum düzeltmesi, saldırı değil.

Bu, fraksiyonun **imza hamlesidir**: tek bir Risky Roll ile bütün alayı düşman hattına çarpmak. Oyunda o an gerçekleşmiyor; modeller düşmanın 1" içine giriyor ve orada bekliyor, ardından bir sonraki aktivasyonlarında zaten angaje oldukları için charge yapamıyorlar. Yeteneğin taktik değeri neredeyse sıfırlanıyor.

---

### 🟠 P1-TP-5 — Broken on the Wheel'in bedeli (bir modelin kalıcı feda edilmesi) yok

**Bulgu:** `shrine_anchorite.tres` Loadout2 (`SHRINE_LOADOUT_BROKEN`): `armour_override = 0`, `extra_keywords = {broken_on_wheel_chosen: 1}`, **`cost_delta` yok**.

**Compendium:**
> *"you can say that one Trench Pilgrim or Ecclesiastic Prisoner will be broken on the wheel to show their piety and devotion. **The model you choose is permanently removed from your Warband**..."*

**Neden sorun:** Mekaniğin çalışan yanı (Armour 0 → ilk OOA No Effect → sonra −3/Tough/Negate Shrapnel) **kusursuz uygulanmış**. Eksik olan tek şey **bedeli**: bir Trench Pilgrim (30 ) veya Ecclesiastic Prisoner (20 ) warband'dan silinmeli. Şu hâliyle oyuncu bedelsiz bir seçenek karşısında; rasyonel oyunda **her zaman** Broken'ı seçer, çünkü hiçbir şey kaybetmiyor.

Ayrıca tematik ağırlık kayboluyor: Anchorite Shrine'ın gücü *bir insanı çarkta kırarak* elde edilir. Bu, fraksiyonun en güçlü lore anıdır ve oyunda ücretsiz bir onay kutusuna dönüşmüş.

**Olması gereken:** Loadout seçildiğinde bütçeden 20–30  düşülmeli (feda edilen modelin maliyeti) veya deploy sırasında bir Pilgrim/Prisoner slotu bloke edilmeli.

---

### 🟠 P1-TP-6 — Stigmatic Nun'ın silah kısıtı ihlal ediliyor

**Bulgu:** `stigmatic_nun.tres` saldırıları: `nun_blessed_sword` (melee) + **`nun_crossbow`** (RANGED, 6", `pistol` keyword'lü).

**Compendium:** *"The only Ranged Weapons they can have are **Automatic Pistols and Pistols**, and the only Grenades they can have are **Warcrosses**."*

**Neden sorun:**
- TP Armoury'sinde **arbalet (crossbow) diye bir kalem yoktur**. Uydurma bir silah.
- Mekanik olarak `pistol` keyword'ü taşıdığı için işleyiş yaklaşık doğru, ama menzili **6"** — compendium'da Pistol **8"**dir.
- Tematik: Nun'ın lore'u *"Armed with **swords and pistols**, they charge across No Man's Land"* der. Arbalet, orta çağ imgesine kayıyor; oysa Trench Crusade'in estetiği **I. Dünya Savaşı + Cehennem**dir, fantezi değil.
- Compendium'un bu kısıtı koymasının sebebi var: Nun 8" hareket + `Agile` ile hızlı bir *melee* vurucudur; uzun menzilli silah alabilseydi rolü bulanırdı. Kısıt, birim kimliğinin bir parçası.

---

### 🟠 P1-TP-7 — Trench Pilgrim'e Frag Grenade veriliyor; TP Armoury'sinde Frag Grenade yok

**Bulgu:** `trench_pilgrim.tres` Loadout3 (`ZEALOT_LOADOUT_GRENADE`, `cost_delta = 7`) → `frag_grenade.tres` ekliyor.

**Compendium TP Grenades listesi (tamamı):** Incendiary Grenades 15 , **Molotov Cocktail 5 **, **War-Cross 5 **. Frag Grenade **yoktur**.

**Neden sorun:** Fiyat da (7 ) doğrudan **New Antioch** armoury'sindeki Frag Grenade fiyatıdır. Yani başka bir fraksiyonun ekipmanı, o fraksiyonun fiyatıyla, Trench Pilgrims'e verilmiş. Molotov Cocktail (5 ) tam olarak lore'da adı geçen kalemdir ve yerine kullanılmalıydı.

---

### 🟠 P1-TP-8 — "Eline ne geçerse" armoury'sinin **hiçbir** kalemi yok

Trench Pilgrims'in merkezi lore cümlesi:

> *"They arm themselves with **anything they can get their hands on**, from **antique muskets** to **scourges** and **Molotov cocktails**."*

Bu cümlenin mekanik karşılığı olan kalemlerin oyunda karşılığı yok:

| Kalem | Fiyat | Kayıp olan şey |
|---|---|---|
| **Musket** | 5  | "Antika silah" temasının çekirdeği |
| **Blunderbuss** | 5  | Aynı |
| **Punt Gun** | 20  (LIMIT 2) | Av tüfeğinden bozma toplu ateş |
| **Flail / Scourge** | 5  | Castigator kırbaç temasının yayılımı |
| **Molotov Cocktail** | 5  | Lore'da **adı geçen** el bombası |
| **War-Cross** | 5  | Nun'ın alabildiği **tek** el bombası |
| **Anti-Tank Hammer** | 35  (LIMIT 3, Elite only) | Elite'lerin zırh delici tek seçeneği |
| **Martyrdom Pills** | 20  (LIMIT 3) | Şehitlik temasının ikinci ayağı |
| **Holy Icon Shield / Blessed Icon / Holy Relic** | 2 /15 /2  | Kutsal ikonografi katmanı |
| **Iron Capirote** (satın alınabilir) | 7  | Prisoner dışındakiler `[Negate Fear]` alamıyor |
| **Donkey's Jawbone** | 4  | — |

**Sonuç:** Oyunda TP, tamamen jenerik silahlarla (`crusader_bayonet`, `frag_grenade`, `nun_crossbow`) donatılmış "ucuz melee yığını"na dönüşüyor. Compendium'daki "atık ve antika silahlarla dolu kaotik alay" kimliğinin görsel/mekanik hiçbir izi kalmıyor.

**Ek not:** Iron Capirote'un satın alınabilir olmaması özellikle önemli — compendium'da bu, herhangi bir Pilgrim'e `[Negate Fear]` + `[Negate Shrapnel]` veren 7 ducat'lık bir kalemdir ve fraksiyonun "korkusuzluk" kimliğinin taşıyıcısıdır. Oyunda yalnız Ecclesiastic Prisoner'a gömülü.

---

### 🟠 P1-TP-9 — 3 Variant Warband yok

Procession of the Sacred Affliction, Cavalcade of the Tenth Plague, War Pilgrimage of Saint Methodius — hiçbiri yok.

**Neden özellikle önemli:** Compendium'daki TP birim görsellerinin **neredeyse tamamı** `procession-of-the-sacred-affliction` etiketini taşır (War Prophet, Castigator, Communicant, Anchorite Shrine, Ecclesiastic Prisoner, Stigmatic Nun, Trench Pilgrim). Yani bu variant, Trench Pilgrims'in *varsayılan* görsel-tematik kimliğidir; ana liste ondan türetilmiş gibi sunulur. Yokluğunda fraksiyonun görsel dili kaynağa bağlanmıyor.

---

### 🟡 P2-TP-10 — Küçük sapmalar

| # | Bulgu | Compendium | Oyun |
|---|---|---|---|
| a | Birim adı ters | **Anchorite Shrine** | `unit_name = "Shrine Anchorite"` |
| b | `crusader_bayonet` | TP Armoury: Bayonet 2  (yalnız `[Bayonet Lug]`'lı silahla) | Trench Pilgrim'in sabit melee'si; ayrıca isim New Antioch temalı |
| c | Loudspeakers caster'ı hariç tutuyor | *"all friendly models within 8""* | `u == caster` atlanıyor |
| d | `martyr_penitent_resurrection` | Kampanya terfisi (45 , Melee +1D, `[-1 Injury Dice]`) | `.tres` var, kodda hiç okunmuyor. `CUSTOM_IMPLEMENTED`'da olmadığı için yanıltıcı buton üretmiyor ✔ — kampanya sistemi gelene kadar kabul edilebilir |
| e | Yetim varlıklar | — | `atonement_bell.tres` ve `holy_water_grenade.tres` **hiçbir birim tarafından kullanılmıyor** |
| f | `willpower = 10` (Ecclesiastic Prisoner) | Trench Crusade'de Willpower stat'ı **yok** | Motorda okunmuyor; ölü/yanıltıcı veri (bkz. P2-NA-14) |
| g | `faction_rule_summary` ölü metni | TP'nin `## Faction Rules` bölümü **yok** | `.tres` `"FACTION_TRENCH_PILGRIMS_RULES"`a işaret ediyor; metin *"Holy Wrath… Martyrdom: Models that are Downed still count towards **faith generating acts**"* diyor — **compendium'da böyle bir kural yok, "faith" diye bir kaynak da yok**. `has_faction_rule=false` sayesinde gizli, ama silinmeli |
| h | Communicant'ın ranged silahı | Ranged −3D, Communicant Cross ekipman | Oyunda hiç ranged yok ✔ (doğru), ama `communicant_greatsword` Armoury'de "Greatsword/Axe 12 " karşılığı — fiyat modellenmemiş |

---

## 4. Özet Skor — Trench Pilgrims

| Eksen | Skor | Gerekçe |
|---|---|---|
| **Roster kompozisyonu** | 8/10 | 12/13; Observer eksik |
| **Stat sadakati** | 10/10 | Sıfır sapma; Memento Mori/Tough ilişkisi dahil |
| **Keyword sadakati** | 10/10 | Tümü doğru |
| **Fraksiyon pasifi** | 10/10 | Compendium'da yok, oyunda da yok — **doğru** |
| **Birim yetenekleri** | 7/10 | Whip of God, Broken on the Wheel, Martyrdom Device birebir; Loudspeakers'ın charge maddesi eksik |
| **Ekipman / Armoury** | 1/10 | 11 fraksiyona-özgü kalemin **hiçbiri** yok; Martyrdom Device bedava; başka fraksiyonun el bombası verilmiş |
| **Ekonomi** | 2/10 | Glory Point ↔ ducat **+** Martyrdom Device'ın bedavaya gelmesi (fraksiyona özel ikinci kırılma) |
| **Lore / tema** | 4/10 | Lore metni doğru; ama "antika silahlar/scourge/molotof" kimliği hiç yok, 3 Variant yok, arbalet uydurma |
| **Oynanış kimliği** | 5/10 | Acı→Blessing ve disiplin ekonomisi sağlam; ama imza hamlesi (Loudspeakers charge) çalışmıyor ve şehitlik ekonomisi bozuk |

**Genel: 6.3 / 10** — Mekanik uygulama kalitesi yüksek (Martyrdom Device ve Broken on the Wheel örnek nitelikte), ama **iki ekonomik kırılma** (bedava Martyrdom Device, Glory Point karışımı) ve **sıfır armoury temsili** fraksiyonun oynanış kimliğini ciddi biçimde saptırıyor.

### Öncelik sırası
1. **P0-TP-1** Martyrdom Device'ı LoadoutOption'a taşı: `cost_delta = 35`, `max_per_warband = 4`
2. **P0-TP-2** `observer.tres`'i TP `available_units`'e ekle (tek satır)
3. **P0-TP-3** Glory Point / ducat ayrımı (fraksiyon-üstü)
4. **P1-TP-4** Loudspeakers'a "counts as charging" + LoS
5. **P1-TP-5** Broken on the Wheel'e feda bedeli
6. **P1-TP-6/7** `nun_crossbow` → Pistol (8"); `frag_grenade` → Molotov Cocktail
7. **P1-TP-8** TP armoury kalemleri (öncelik: Molotov Cocktail, War-Cross, Musket, Flail/Scourge, Iron Capirote, Anti-Tank Hammer)
8. **P2-TP-10a/e/g** Ad düzeltmesi, yetim varlık temizliği, uydurma faction rule metnini sil
