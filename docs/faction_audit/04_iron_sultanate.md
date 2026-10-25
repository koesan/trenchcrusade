# Faction Sadakat Denetimi — 04: Iron Sultanate

**Kaynak:** `trench_compendium/warbands/iron-sultanate.md` (1101 satır) + 3 Variant dosyası
**Oyun tarafı:** `assets/data/factions/iron_sultanate.tres`, 11 birim `.tres`, `dice_pool_builder.gd`, `loadout_resolver.gd`, `ability_executor.gd`, `unit.gd`
**Denetim tarihi:** 2026-07-28

---

## 1. Kaynak Materyaldeki Tasarım ve Amaç

### 1.1 Lore ve Tema
Iron Sultanate, Cehennem Kapısı açıldığında **Dhu al-Qarnayn'ın Demir Duvarı**'nın Rûm Sultanı'nın topraklarında tecelli etmesiyle kurulmuştur. Avrupa, Asya ve Afrika'daki tüm İnananların — Peygamber'in Hicret'inden sonraki en önemli göç sayılan — büyük göçüyle oluşmuş, ardından al-Qarnayn Kapıları kapatılmıştır.

Tematik çekirdek dört sütun:

1. **Duvar ve savunma refleksi.** *"The protection of the Iron Wall has had an extensive influence on the Sultanate's way of war."* Bu, fraksiyonun savaş doktrininin **doğrudan** kaynağıdır: kuşatma savunması mantığı sahra savaşına taşınmıştır.
2. **Korunmuş bilgi.** Duvarın ardında "kayıp bilgi" gelişir. **House of Wisdom** ve **Jabirean Alchemist**'ler simyayı, yapay yaşamı (*Takwin*) ve elementel ustalığı temsil eder. Sultanate, oyunun **bilim/simya** fraksiyonudur.
3. **Onur ve şahsi hüner.** *"matters of honour are swiftly resolved with duels to the death."* Yüzbaşı'nın **Mubarizun**'u (Tough hedeflere +1 Injury Dice) tam olarak budur: komutan, düşmanın en güçlüsüyle *şahsen* dövüşür.
4. **Kayıp geçmişin ihyası.** Duvarın ötesindeki seferler, düşmüş Hilafetlerin harabelerinden **kayıp hazineleri ve bilgi kitaplarını** kurtarmaya gider.

### 1.2 Oynanış Kimliği (Tabletop Rolü)

Compendium, fraksiyonun savaş doktrinini **tek bir paragrafta açıkça tarif eder** — bu, denetlenen altı fraksiyon içinde tasarım niyetinin en net yazıldığı yerdir:

> *"The conscripted **Azebs are experts at feigned flight and skirmish**, while the **loping Lions of Jabir harass the enemy flanks**. All the while, the **superb artillery of the Sultan bombards the enemy** as they make their tortuous journey across a battlefield **littered with traps set by the skilled Sappers**. When they reach the ranks of the righteous, the **Janissaries... close in and finish the enemy with a devastating counter-charge**. Dreaded **Assassins from Alamut prowl in the winds of time, striking at enemy elites and leaders**, while the **Alchemists of the House of Wisdom unleash devastating weapons made deadly by their elemental mastery**."*

Bu paragraf **altı ayrı mekanik sütun** tanımlar:

| # | Sütun | Mekanik taşıyıcısı |
|---|---|---|
| 1 | **Kaçarak yıpratma** (feigned flight/skirmish) | Azeb + `[Skirmisher]` (hücumdan D3" kaçış) |
| 2 | **Kanat tacizi** | Lion of Jabir (8" hareket, `Agile`, `Pin`) |
| 3 | **Topçu bombardımanı** | Brazen Bull (Flame Cannon, M.U.R.A.D Bombard) + Siege Jezzail |
| 4 | **Tuzaklarla dolu saha** | Sultanate Sapper (Set Mine / Defuse Mine / Detonating Mines / `[Negate Mined]`) |
| 5 | **Karşı-hücum** | Janissary + `Counter-Charge` (+1D melee, aktivasyonun ilk eylemi Charge ise) |
| 6 | **Zaman-uzay suikastı + elementel ustalık** | Sultanate Assassin (Time Slip, Temporal Assassin) + Jabirean Alchemist (Mastery of the Elements) |

**Fraksiyonun tezi:** düşmanı yavaşlat, yıprat, tuzağa düşür, sonra hazır kuvvetle karşı-hücumla bitir. Bu, "önce sen gel, ben duvarımın ardında beklerim" doktrinidir.

- **`## Faction Rules` bölümü YOKTUR.** (Oyundaki `has_faction_rule = false` **doğru**.)
- **Zırh neredeyse hiç yok.** 8 çekirdek birimin **tamamı Armour 0**'dır — Brazen Bull dahil. Sultanate zırhla değil, **pozisyon ve tempoyla** hayatta kalır. (Zırh Armoury'den satın alınır: Standard 15, Reinforced 40 — *Janissary/Elite only*, Alchemist Armour 50.)
- **Azeb 25 ** ile oyunun en ucuz ikinci modeli; Janissary 0-6 ile en yüksek Availability'ye sahip Elite-olmayan vurucu.

### 1.3 Fraksiyona Özgü Mekanikler

| Birim | Mekanik | Tasarım amacı |
|---|---|---|
| Yüzbaşı | **Mubarizun** (`[Tough]` hedeflere +1 Injury Dice); **Janissary Veteran** terfisi (+10 , `[Strong]` + Counter-Charge) | "Düelloya çıkan komutan" — düşman elitini bizzat avlar |
| Jabirean Alchemist | **Mastery of the Elements** (ilk yerleşimde tüm silahlarına `[Fire]`/`[Gas]`/`[Shrapnel]`'den birini ver), **Elemental Change** (Risky, elementi değiştir) | Rakibin `[Negate Fire/Gas/Shrapnel]` savunmasını **aşma**; *"capable of overcoming the defences of virtually any foe"* |
| Sultanate Assassin | **Time Slip** (rakip isabetsiz atarsa 6" yeniden konuşlan), **Temporal Assassin** (tek Charge'da **iki farklı düşmana** iki Fight) | "Aynı anda iki yerde" — elit/lider avcısı |
| Azeb | **Skirmisher** terfisi (+5 , hücumdan önce D3" kaçış, araya giren model yaratır) | Feigned flight; düşman hücumunu boşa çıkarır |
| Brazen Bull | **Artificial Life** (tüm Injury Roll'lara −1 Injury Dice), **Trample** (Down hedefe silahsız `[Ignore Armour]` melee); **yalnız `[Heavy]` silah taşıyabilir** | Yürüyen topçu platformu |
| Janissary | **Counter-Charge** (ilk eylem Charge ise aktivasyon boyunca +1D melee) | Fraksiyonun bitirici darbesi |
| Lion of Jabir | **Artificial Life**, **Pin** (1" içindeki Down ≤40mm düşman ayağa kalkamaz), **Agile**, **Teeth and Claws**; **Fierce and Brave** (+5 , `[Fear]`) | Kanat tacizi + kilitleme |
| Sultanate Sapper | **Set Mine**, **Defuse Mine**, **Detonating Mines**, **Forward Positions** (6" ileri konuşlanma), **Fortify**, `[Negate Mined]` | Sahayı tuzaklarla şekillendirme |

### 1.4 Mercenaries
Combat Biologist (3 ), Mamluk Faris (4 ), Scripture Guardian (7 ).

### 1.5 Armoury — fraksiyonun karakteri

| Kalem | Fiyat | Kısıt |
|---|---|---|
| **Alaybozan** | 9  | **Sultanate Sapper only** |
| **Jezzail** | 7  | (18" düz namlulu — Alchemical Ammunition ile kullanılır) |
| **Siege Jezzail** | 30  | — |
| **Halberd-Gun** | 20  | Elite only |
| **Flame Cannon** | 60  | LIMIT 1, **Brazen Bull only** |
| **M.U.R.A.D Bombard** | 50  | LIMIT 1, **Brazen Bull only** |
| **Titan Zulfiqar** | 30  | **Brazen Bull only** |
| **Assassin's Dagger** | 15  | **Sultanate Assassin only** |
| **Alchemical Ammunition** | 3  | Alaybozan/Halberd-Gun/Jezzail/Siege Jezzail ile |
| **Alchemist Armour** | 50  | LIMIT 1, Elite only |
| **Cloak of Alamut** | 25  | LIMIT 1, Elite only |
| **Marid Shovel** | 15  | Brazen Bull only |
| **Takwin Anqa Bird** | 2  | LIMIT 1 |
| Musket / Machine Gun / Sniper Rifle | 5 / 50 (L1) / 35 (L2, Janissary+Elite only) | — |

**Dikkat:** Bu armoury, Trench Crusade'deki **en fazla birim-özel kalem** içeren listedir (7 adet "X only"). Yani Sultanate'in birimleri, kendilerine has ekipman olmadan compendium'daki hâllerini **temsil edemez**.

### 1.6 Variant Warband'lar
Fidai of Alamut — The Cabal of Assassins, House of Wisdom, Defenders of the Iron Wall. (Üçü de yukarıdaki altı sütundan birini derinleştirir.)

### 1.7 Güçlü / Zayıf Yönler
| Güçlü | Zayıf |
|---|---|
| Elementel ustalık: her savunmayı aşabilme | Tüm birimler taban Armour 0 |
| Counter-Charge ile en yüksek melee patlaması | İlk vuran taraf olmak istemiyor → tempo kaybı riski |
| Mayınlarla saha şekillendirme | Sapper 50  ve kırılgan |
| Skirmisher/Lion ile hücum boşa çıkarma | Azeb Melee −1D, savunmasız |
| Temporal Assassin: tek aktivasyonda 2 elit hedef | Assassin 85  ve Armour 0 |
| Brazen Bull: −1 Injury Dice + Tough + Fear | Bull `[Heavy]` dışı silah taşıyamaz |

---

## 2. Oyundaki Uygulama

### 2.1 Roster Karşılaştırması

| Compendium | Cost | Avail | Oyunda | Durum |
|---|---|---|---|---|
| Yüzbaşı Captain | 70 | 1 | ✅ 70 / 1 | ✔ |
| Jabirean Alchemist (Elite) | 55 | 0-1 | ✅ 55 / 1 | ✔ |
| Sultanate Assassin (Elite) | 85 | 0-1 | ✅ 85 / 1 | ✔ |
| Azeb | 25 | Unlimited | ✅ 25 / 999 | ✔ |
| Brazen Bull | 100 | 0-1 | ✅ 100 / 1 | ✔ |
| Janissary | 55 | 0-6 | ✅ 55 / 6 | ✔ |
| Lion of Jabir | 60 | 0-2 | ✅ 60 / 2 (adı "Lions of Jabir") | ⚠ ad çoğul |
| Sultanate Sapper | 50 | 0-2 | ✅ 50 / 2 | ✔ |
| *Merc:* Combat Biologist | 3  | 0-1 | ✅ 3 / 1 | ⚠ birim para |
| *Merc:* Mamluk Faris | 4  | 0-1 | ✅ 4 / 1 | ⚠ birim para |
| *Merc:* Scripture Guardian | 7  | 0-1 | ✅ 7 / 1 | ⚠ birim para |

**11/11 birim mevcut.**

### 2.2 Stat ve Keyword Doğruluğu

```
Yüzbaşı            6" | +2D | +2D | 0  [Negate Fear][Tough][Leader][Elite][Sultanate]      ✔
Jabirean Alchemist 6" | +2D | +1D | 0  [Elite][Sultanate]                                   ✔
Sultanate Assassin 6" | +1D | +2D | 0  [Infiltrator][Elite][Sultanate]                      ✔
Azeb               6" |  0D | -1D | 0  [Sultanate]                                          ✔
Brazen Bull        6" |  0D | +2D | 0  [Fear][Strong][Negate Heavy][Tough][Artificial][Sultanate] ✔
Janissary          6" | +1D | +1D | 0  [Strong][Negate Heavy][Sultanate]                    ✔
Lion of Jabir      8" |  0D | +1D | 0  [Artificial][Sultanate]                              ✔
Sultanate Sapper   6" | +1D |  0D | 0  [Sultanate][Negate Mined]                            ✔
```

**Sıfır sapma.** Brazen Bull'un Armour 0 olması dahil (100 ducat'lık bir canavarın zırhsız olması sezgiye aykırı görünse de compendium böyle diyor — doğru girilmiş).

### 2.3 Doğru Uygulanmış Mekanikler

| Mekanik | Nerede | Not |
|---|---|---|
| **Faction Rules yokluğu** | `has_faction_rule = false` | Compendium'da bölüm yok — **doğru** ✔ |
| **Mubarizun** | `dice_pool_builder.gd:364` | Hedef `[Tough]` ise +1 Injury Dice ✔ |
| **Janissary Veteran terfisi** | `yuzbasi.tres` Loadout2, `cost_delta = 10` | `[Strong]` + Counter-Charge ✔ (compendium +10) |
| **Counter-Charge** | `dice_pool_builder.gd:119` | Aktivasyonun ilk eylemi Charge ise +1D melee ✔ |
| **Mastery of the Elements** | `unit.gd:271` + `current_element` | Silahlara dinamik `[Fire]`/`[Gas]`/`[Shrapnel]` — `injury_resolver.apply_outcome(attacker_element)` ile marker kuralına doğru bağlanmış ✔ (bkz. P1-IS-4a) |
| **Elemental Change** | `CUSTOM_IMPLEMENTED` | Risky Roll ile element değişimi ✔ |
| **Time Slip** | `unit.gd`, `combat_choice.gd`, `map_input.gd` | Rakip isabetsiz atınca 6" yeniden konuşlanma, oyuncuya sorulur ✔ |
| **Temporal Assassin** | `CUSTOM_IMPLEMENTED` + `unit_actions.gd` | Tek Charge'da iki ayrı düşmana iki Fight ✔ — projedeki en karmaşık yeteneklerden, doğru uygulanmış |
| **Skirmisher** | `unit.gd:847-857` + `azebs.tres` Loadout2 (+5 ) | Hücumdan önce D3" kaçış, tüm düşmanlardan >1" bitirme ✔ |
| **Artificial Life** | `injury_dice_defence: -1`, `dice_pool_builder.gd` | Tüm Injury Roll'lara −1 Injury Dice ✔ (Brazen Bull + Lion) |
| **Trample** | `CUSTOM_IMPLEMENTED` + `trample_attack.tres` | Down hedefe silahsız `[Ignore Armour]` melee ✔ |
| **Pin** | `lions_of_jabir.tres` `pin: 1` | 1" içindeki Down düşman kalkamaz ✔ |
| **Agile** | `unit.gd` | Climb/Jump/Diving Charge/Dash +1D ✔ |
| **Fierce and Brave** | `lions_of_jabir.tres` Loadout2, `cost_delta = 5` | `[Fear]` ✔ |
| **Brazen Bull `[Heavy]`-only kısıtı** | `loadout_resolver.gd` `heavy_only` | ✔ — compendium'daki *"may only have Weapons that have the `[Heavy]` Keyword"* uygulanmış |
| **Jezzail** | `janissary_jezzail.tres` | **18"** — compendium ile birebir ✔ |
| **Titan Zulfiqar** | `titan_zulfiqar.tres` | `[Critical][Heavy]` +2 Injury Dice, Brazen Bull'a özel ✔ |
| **Assassin's Dagger** | `assassins_dagger.tres` | `[Critical]` + slashing, Assassin'e özel ✔ |
| **Dug In / Fortify** | `sultanate_sapper.tres` | ✔ |
| **Automaton Destrier (Mamluk merc)** | `mechanics_resolver.gd:67` | Kenar yerleşimi ✔ |

---

## 3. Tespit Edilen Sorunlar

### 🔴 P0-IS-1 — Sultanate Sapper'ın kimliği tamamen ölü: mayın sistemi + Alaybozan + Forward Positions

Bu, denetimde bulunan **en ağır tek-birim kaybıdır**. Compendium'da Sapper'ın **5 yeteneği + 1 keyword'ü** vardır; oyunda **yalnız 2'si çalışıyor**.

| Compendium yeteneği | Oyunda | Durum |
|---|---|---|
| **Set Mine** | `set_mine.tres` var, `CUSTOM_IMPLEMENTED`'da **yok** | ❌ `execute()` erkenden iptal ediyor, buton bile üretilmiyor |
| **Defuse Mine** | `defuse_mine.tres` var, `CUSTOM_IMPLEMENTED`'da **yok** | ❌ ölü |
| **Detonating Mines** | — | ❌ hiç yok |
| `[Negate Mined]` | `negate_mined: 1` keyword'ü var | ❌ `grep` boş — hiçbir kod okumuyor |
| **Forward Positions** | `forward_positions.tres` var, `effect_type = "custom"`, `CUSTOM_IMPLEMENTED`'da **yok**, deploy sistemi de okumuyor | ❌ ölü |
| **Fortify** | ✔ | ✅ |
| Dug In (Shovel) | ✔ | ✅ |

**Neden bu bir P0:**

1. **Fraksiyonun altı doktrin sütunundan biri (#4, "tuzaklarla dolu saha") tamamen yok.** Compendium'un doktrin paragrafı Sapper'ı ismen anar: *"a battlefield **littered with traps set by the skilled Sappers**."*
2. **Sapper'ın hiç menzilli silahı yok.** Ranged **+1D**'ye sahip, ama oyundaki tek saldırısı `sapper_shovel` (melee). Armoury'de **Alaybozan (9 , Sultanate Sapper only)** vardır — bu, Sapper'a özel bir `[Shrapnel]`'li ateşli silahtır. Lore da bunu doğrular: *"The Sultan's Sappers... hold **the great cannons of the Iron Wall**... easily identified by the **terrible burns all over their bodies as their mighty artillery is prone to overheating**."* Oyunda Sapper, kürek sallayan bir istihkâmcıdır.
3. **Forward Positions'ın yokluğu**, Sapper'ı ilk turdan itibaren işlevsiz bırakır: mayın kuramadığı için ileri konuşlanmasının da anlamı kalmazdı — ama ileri konuşlanamadığı için Fortify bile geç devreye girer.
4. Aynı mayın sistemi eksikliği New Antioch Combat Engineer'ı da vuruyor (P1-NA-5), ama Engineer'ın 4 yeteneğinden 2'si sağ kalıyor. Sapper'ın 6 unsurundan 4'ü ölü.

**Olması gereken:** Arazi parçalarına `[Mined]` bayrağı taşıyabilen marker sistemi + `set_mine`/`defuse_mine` handler'ları + Detonating Mines (Shrapnel'li Injury Roll) + `[Negate Mined]` kontrolü + deploy'da `forward_positions` (6" ileri, ≥½" arazi teması) + `alaybozan.tres`.

---

### 🔴 P0-IS-2 — Brazen Bull'un topçusu yok: Flame Cannon ve M.U.R.A.D Bombard eksik

**Bulgu:** `brazen_bull.tres` tek saldırısı `titan_zulfiqar` (MELEE). `heavy_only` kısıtı uygulanmış ✔ ama taşınabilecek başka `[Heavy]` silah oyunda **yok**.

**Compendium Armoury (Brazen Bull only):**
- **Flame Cannon** — 60 , LIMIT 1
- **M.U.R.A.D Bombard** — 50 , LIMIT 1
- Marid Shovel — 15 
- Titan Zulfiqar — 30  ✅ (tek uygulanan)

**Lore:** *"The Sultan's armourers equip the Bulls with **heavy artillery that even the superhuman Janissaries cannot lift**, let alone use in battle: **flame cannons, volley guns** and holy blades blessed by the Word of the Great Protector."*

**Neden sorun:** Fraksiyonun doktrin sütunu #3 — *"the **superb artillery of the Sultan bombards the enemy** as they make their tortuous journey"* — oyunda **hiç temsil edilmiyor**. Brazen Bull, Ranged 0D olduğu için zaten atıcı bir birim değil; ama compendium onu bir **ağır silah platformu** olarak konumlandırır (`[Strong]` + `[Negate Heavy]` + yalnız-Heavy kısıtı bunun içindir). Oyunda Bull, pahalı bir melee canavarına indirgenmiş.

**Ek:** Siege Jezzail (30 ) da yok — fraksiyonun ikinci uzun menzilli topçu seçeneği.

Bu, New Antioch MHI (P0-NA-1) ve Heretic Legion AHI (P0-HL-1) ile **aynı sistemik hata**: `[Strong]`/`[Negate Heavy]` taşıyan her ağır-silah platformu birimi, oyunda ağır silahsız bırakılmış.

---

### 🔴 P0-IS-3 — Mercenary ekonomisi (fraksiyon-üstü; bkz. P0-NA-3)

Combat Biologist 3, Mamluk Faris 4, Scripture Guardian 7 — toplam **14 puan** (700 ducat bütçeden). Bir Azeb 25 . Yani üç mercenary'nin tamamı, tek bir en ucuz askerin yarısından ucuz.

**Sultanate'e özel şiddeti:** Mamluk Faris (4 puan) Armour **−2/−3** taşır. Sultanate'in **8 çekirdek biriminin tamamı Armour 0**'dır. Yani 4 puanlık bir mercenary, fraksiyonun tüm rosterinden daha iyi zırhlıdır ve bu zırh compendium'da 40 ducat'lık Reinforced Armour + Trench Shield ile fiyatlanmıştır.

---

### 🟠 P1-IS-4 — Jabirean Alchemist: seçim ve kapsam sapmaları

**(a) Mastery of the Elements'te oyuncu seçimi yok.** `unit.gd:271`:
```gdscript
if KeywordSystem.has(unit_data, &"mastery_of_elements"):
    current_element = &"fire"
```
Compendium: *"When this model is deployed for the first time in a game, **you can give one of the following Keywords** to all of the Jabirean Alchemist's Ranged Weapons and Melee Weapons: `[Fire]` **or** `[Gas]` **or** `[Shrapnel]`."*

Oyun her zaman `Fire`'a sabitliyor. Oyuncu, ilk turda bir **Risky Success Roll** harcayarak (Elemental Change) değiştirmek zorunda kalıyor — ki compendium'da bu ayrı ve sonraki turlar için tasarlanmış bir aksiyondur. Etki: rakip `[Negate Fire]` taşıyan bir warband ise (Heretic Legion'un Anointed'i, Goetic Warlock, Sin Eater — hepsi `[Negate Fire]`), Alchemist ilk turunu **zorunlu olarak** element değiştirmeye harcıyor ve %25–30 ihtimalle başarısız olup aktivasyonunu kaybediyor. Compendium'da bu ceza yok.

**(b) Alchemist'in menzilli silahı 10".** `alchemist_pistol.tres` `attack_range = 10.0`. Alchemist Ranged **+2D** ile fraksiyonun en iyi atıcısıdır; compendium'da Jezzail (18"), Siege Jezzail, Halberd-Gun (20 , Elite only) ve Incendiary Grenades (15 , **Jabirean Alchemist only**) alabilir. Elementel ustalığın tüm anlamı, o elementi **düşmana ulaştırmak**tır; 10" bunun için yetersiz.

**(c) Incendiary Grenades (Jabirean Alchemist only)** yok — Alchemist'e özel tek kalem.

---

### 🟠 P1-IS-5 — Fraksiyona özgü Armoury kalemlerinin çoğu yok

Iron Sultanate, Trench Crusade'de **en fazla birim-özel kalem** taşıyan armoury'ye sahiptir (7 adet "X only"). Oyunda yalnız 2'si var:

| Kalem | Kısıt | Oyunda |
|---|---|---|
| Titan Zulfiqar 30  | Brazen Bull only | ✅ |
| Assassin's Dagger 15  | Sultanate Assassin only | ✅ |
| **Alaybozan** 9  | **Sultanate Sapper only** | ❌ |
| **Flame Cannon** 60  | **Brazen Bull only** | ❌ |
| **M.U.R.A.D Bombard** 50  | **Brazen Bull only** | ❌ |
| **Marid Shovel** 15  | **Brazen Bull only** | ❌ |
| **Incendiary Grenades** 15  | **Jabirean Alchemist only** | ❌ |
| **Halberd-Gun** 20  | Elite only | ❌ |
| **Siege Jezzail** 30  | — | ❌ |
| **Cloak of Alamut** 25  | LIMIT 1, Elite only | ❌ |
| **Alchemist Armour** 50  | LIMIT 1, Elite only | ❌ |
| **Takwin Anqa Bird** 2  | LIMIT 1 | ❌ |
| **Alchemical Ammunition** 3  | Jezzail ailesi | ⚠ yalnız `mamluk_jezzail` içinde gömülü; Janissary/Azeb alamıyor |
| Musket 5  | — | ❌ |

**Neden sorun:** Bu kalemler *isim düzeyinde* fraksiyonun kültürel kimliğini taşır (Alaybozan, Zulfiqar, Marid, Takwin, Alamut, al-Qarnayn). Oyunda kalanlar `janissary_scimitar`, `janissary_jezzail`, `greatsword_axe` — üçü de jenerik. Ayrıca **Alchemical Ammunition'ın** yokluğu, Jezzail'in compendium'daki tüm anlamını siliyor: Jezzail düz namlulu ve kısa menzillidir *çünkü* farklı simyasal mermilerle doldurulabilsin diye (*"this allows them to be loaded with different types of alchemical ammunition made by the Jabirean Alchemists"*). Oyunda Jezzail sadece kötü bir tüfek.

---

### 🟠 P1-IS-6 — Lion of Jabir'e yanlış yetenek kartı gösteriliyor

**Bulgu:** `lions_of_jabir.tres` yetenekleri: **`abiotic_life.tres`**, `pin.tres`, `agile.tres`.

Compendium'da Lion of Jabir'in yeteneği **Artificial Life**'tır: *"Add `[-1 Injury Dice]` to Injury Rolls for the model."* (Tüm saldırılara karşı.)
**Abiotic Life** ise **Artillery Witch**'in (Heretic Legion) yeteneğidir: *"Add `[-1 Injury Dice]` to rolls for an Artillery Witch that has been hit by an attack with the `[Gas]` Keyword."* (Yalnız Gas'a karşı.)

Mekanik olarak doğru davranıyor (`injury_dice_defence: -1` keyword'ü tüm Injury Roll'lara uygulanıyor ✔) — ama oyuncuya gösterilen **ad ve açıklama yanlış**. Brazen Bull doğru şekilde `artificial_life.tres` kullanıyor; Lion tutarsız. Bu, oyuncunun Lion'ın yalnız gaza karşı dirençli olduğunu sanmasına yol açar.

---

### 🟠 P1-IS-7 — 3 Variant Warband yok

**Fidai of Alamut — The Cabal of Assassins**, **House of Wisdom**, **Defenders of the Iron Wall**.

Bu üç variant, fraksiyonun altı doktrin sütununun üçünü doğrudan derinleştirir (suikast, simya, duvar savunması). Yokluklarında Sultanate, "Osmanlı temalı jenerik asker listesi"ne indirgeniyor.

---

### 🟡 P2-IS-8 — Küçük sapmalar

| # | Bulgu | Compendium | Oyun |
|---|---|---|---|
| a | Birim adı çoğul | **Lion of Jabir** (tekil) | `unit_name = "Lions of Jabir"` |
| b | Yüzbaşı adı | **Yüzbaşı** | `unit_name = "Yuzbasi"` (Türkçe karakter yok — proje Türkçe lokalizasyon içerdiği hâlde) |
| c | Yüzbaşı Machine Gun loadout | Machine Gun **50 ** | `cost_delta = 45` |
| d | Janissary Greatsword loadout | Greatsword/Axe **12 ** | `cost_delta = 5` |
| e | Janissary Armoured loadout | Reinforced Armour **40 ** (Janissary/Elite only ✔) | `cost_delta = 15`, `armour_override = 1` (−1 zırh; compendium Reinforced **−2**) |
| f | `alchemist_pistol` menzili | Pistol 8  → 8" | 10.0 |
| g | Lion of Jabir Battlekit kısıtı | *"can have Armour and/or a Wind Amulet... **cannot have Shields or any other Battlekit**"* | Modellenmemiş |
| h | Sultanate Assassin'in ranged'i | Ranged +1D, Armoury'den Pistol/Jezzail alabilir | Hiç ranged silahı yok (yalnız `assassins_dagger`) |
| i | `faction_rule_summary` ölü metni | IS'in `## Faction Rules` bölümü **yok** | `.tres` `"FACTION_IRON_SULTANATE_RULES"`a işaret ediyor; metin *"**Alchemical Armor: All models receive a +1 Armour bonus**… Ranged Focus: Re-roll failed shoot rolls of 1"* diyor — **tamamen uydurma** ve üstelik compendium'un tam tersi (Sultanate'in tüm birimleri Armour **0**'dır, fraksiyonun zayıflığı budur). `has_faction_rule=false` sayesinde gizli, ama silinmeli |
| j | `FACTION_IRON_SULTANATE_STORY` | — | **Compendium'dan neredeyse birebir alınmış** ✔ — altı fraksiyon içindeki en sadık lore metni |

---

## 4. Özet Skor — Iron Sultanate

| Eksen | Skor | Gerekçe |
|---|---|---|
| **Roster kompozisyonu** | 10/10 | 11/11 birim |
| **Stat sadakati** | 10/10 | Sıfır sapma (Brazen Bull Armour 0 dahil) |
| **Keyword sadakati** | 8/10 | Tümü doğru girilmiş; `negate_mined` okunmuyor |
| **Fraksiyon pasifi** | 10/10 | Compendium'da yok, oyunda da yok — **doğru** |
| **Birim yetenekleri** | 5/10 | Temporal Assassin/Time Slip/Skirmisher/Counter-Charge örnek nitelikte; ama **Sapper'ın 6 unsurundan 4'ü ölü** |
| **Ekipman / Armoury** | 2/10 | 14 kalemin 12'si yok; Bull topçusuz, Sapper silahsız, Alchemical Ammunition yok |
| **Ekonomi** | 3/10 | Glory Point ↔ ducat; loadout fiyatları armoury ile tutarsız |
| **Lore / tema** | 6/10 | Lore metni en sadık olan (birebir alıntı) ✔; ama kültürel isimli kalemler ve 3 Variant yok |
| **Oynanış kimliği** | 4/10 | Compendium 6 doktrin sütunu tanımlıyor; oyunda **#3 (topçu) ve #4 (tuzaklar) tamamen yok**, #6'nın yarısı (elementel menzil) sakat |

**Genel: 6.4 / 10** — Veri ve çekirdek mekanik katmanı çok güçlü (Temporal Assassin gibi karmaşık bir yetenek doğru uygulanmış), ama fraksiyonun **kendi doktrin paragrafında yazdığı altı sütundan ikisi oyunda hiç yok**. Bu, denetlenen fraksiyonlar içinde tasarım niyeti ile uygulama arasındaki **en ölçülebilir boşluk**.

### Öncelik sırası
1. **P0-IS-1** Mayın sistemi (Sapper + New Antioch Combat Engineer'ı birlikte kurtarır) + `alaybozan.tres` + `forward_positions` deploy entegrasyonu
2. **P0-IS-2** Brazen Bull'a Flame Cannon / M.U.R.A.D Bombard
3. **P0-IS-3** Glory Point / ducat ayrımı (fraksiyon-üstü)
4. **P1-IS-4a** Mastery of the Elements'e deploy anında oyuncu seçimi
5. **P1-IS-6** Lion of Jabir'in `abiotic_life` → `artificial_life` düzeltmesi (tek satır)
6. **P1-IS-5** Alchemical Ammunition, Halberd-Gun, Siege Jezzail, Incendiary Grenades
7. **P2-IS-8c/d/e** Loadout fiyatlarını armoury tablosuna hizala; Reinforced Armour −2 olmalı
8. **P2-IS-8i** Uydurma faction rule metnini sil
