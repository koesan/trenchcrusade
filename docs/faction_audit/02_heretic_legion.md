# Faction Sadakat Denetimi — 02: Heretic Legion

**Kaynak:** `trench_compendium/warbands/heretic-legion.md` (1087 satır) + 3 Variant dosyası
**Oyun tarafı:** `assets/data/factions/heretic_legion.tres`, 11 birim `.tres`, `ability_executor.gd`, `dice_pool_builder.gd`, `mechanics_resolver.gd`, `unit.gd`
**Denetim tarihi:** 2026-07-28

---

## 1. Kaynak Materyaldeki Tasarım ve Amaç

### 1.1 Lore ve Tema
Heretic Legion, **Cehennem'in Yeryüzü'ndeki ana askerî gücü**dür. İnsanlığın üçte biri Cehennem'in putları önünde diz çökmüştür; Legion bu lanetlilerin arasından toplanır.

Tematik çekirdek dört sütun:

1. **Hac ve mühürlenme.** Legion'a girmek bir *seçim* değil bir **çile**dir: Cehennem'in tunç Kapısı'na yapılan kutsal olmayan hac. Gözyaşları Vadisi'nde yol, "kötülükleri yetersiz bulunmuş", yarı-canlı, kavrulmuş bedenlerle döşelidir. Kapı'yı görebilenler kabul edilir, sonsuza dek zincirleyen yeminler eder ve kendilerini sahiplenen iblis lordunun damgasını taşır.
2. **Anointed — daha ileri gidenler.** Kapı'nın ötesine, Ebedî Alev Gölü'nün kıyısına ulaşanların eti tutuşur ve **asla iyileşmez**. Karşılığında ağır **Gehenna zırh takımları** giyme hakkı ve normal bir insanın zar zor kaldıracağı silahları kullanma gücü kazanırlar.
3. **Cehennem'in endüstrisi.** Et ve metalden yapılmış fabrikalar, Tartarus demircilerinin öğretileri, "hiçbir insan mühendisinin kavrayamayacağı" metalürji. Legion, New Antioch'un endüstriyel gücünün **karanlık aynası**dır.
4. **Cehennem'in kendi yavruları.** Ele geçirilmiş ve içine girilmiş yaratıklardan yapılan **War Beast**'ler ve mobil topçu görevi gören **Artillery Witch**'ler — bunlar ölümlü askerleri takviye eder.

### 1.2 Oynanış Kimliği (Tabletop Rolü)

**Heretic Legion, New Antioch'un doğrudan karşıtıdır: aynı "düz asker" iskeleti üzerine doğaüstü bir katman.**

- **`## Faction Rules` bölümü YOKTUR.** Bu bilinçli bir tasarım kararıdır: Legion'un kimliği fraksiyon-geneli bir pasiften değil, **birim başına özel yeteneklerden** gelir. (Bu, oyundaki `has_faction_rule = false` ayarını **doğrular**.)
- **En derin araç kutusu.** Fraksiyonun 8 çekirdek birimi birbirine hiç benzemez: bir zihin-kontrolcü kaptan, bir infiltratör suikastçı, bir aura-debuff'çu, bir ağır piyade, bir topçu, bir gövde birimi, bir savaş canavarı ve bir feda edilebilir köle.
- **Sıralama/pozisyon manipülasyonu.** Puppet Master (düşmanı D6" zorla hareket ettir), Goetic Portal (6" ışınlan + düşman sürükle), Hide, Infiltrator — Legion, rakibin pozisyonunu bozmakta uzmandır.
- **Aura baskısı.** Unholy Hymns (8" içindeki düşman Success Roll'larına −1 Dice) fraksiyonun tek kalıcı alan-etkisidir ve **kümülatif değildir** ("one or more Choristers").
- **Feda edilebilirlik ekonomisi.** Wretched (25 , Unlimited) iki yönlü bir kaynak: (a) *Law of Hell* — bir `[Elite]` öldürürse özgürlüğüne kavuşup **oyundan çıkar** ve Morale sayımından düşer; (b) *Dark Blessing* — öldüğünde en yakın `[Elite] [Heretic]` modele **+1 Blessing Marker**. Yani Wretched'ın ölmesi *fayda üretir*. Bu, Legion'un "insanı harcanabilir kaynak olarak gören" temasının doğrudan mekanik karşılığıdır.
- **Doğrusal olmayan ateş gücü.** Artillery Witch (100 ) Infernal Bomb ile 36" menzil, Blast 3", Scatter, Deadly-on-hit ve D3" savurma sağlar — oyunun en güçlü tek atışı, ama `[Reload]` ile yavaşlatılmış.

### 1.3 Fraksiyona Özgü Mekanikler (birim düzeyinde)

| Birim | Mekanik | Tasarım amacı |
|---|---|---|
| Heretic Priest | **Puppet Master** — 12" + LoS, dost/düşman fark etmez, D6" düz çizgi zorla hareket; hedef Diving Charge yapamaz ve charge saymaz | Rakibin dizilimini bozan tek "telekinezi" |
| Death Commando | **Hide** (+1D Risky, hedeflenemez) + **Stealth Generator** (−1D ranged) + `[Infiltrator]` | Cerrahi suikast; Blast'a karşı savunmasız kalması bilinçli zayıflık |
| Heretic Chorister | **Unholy Hymns** — 8" düşman Success Roll'larına −1D; kendisi `[Fear]` | Alan kontrolü; Ranged −2D ile bilinçli olarak "sadece durup baskı yapan" birim |
| Anointed Heavy Infantry | `[Strong]` `[Negate Heavy]` + Infernal Brand (`[Negate Fire]`) + Reinforced Armour | **Ağır silah platformu**; 95  ile en pahalı Infantry |
| Artillery Witch | **Levitate** (Climb/Jump/Fall zarı yok) + **Abiotic Life** (Gas'a −1 Injury Dice) + Infernal Bomb | Mobil topçu; `[Artificial]`, mutlak sessiz, Cehennem'de üretilmiş |
| Heretic Trooper | **Heretic Legionnaire** terfisi: +10 , Ranged **veya** Melee 0→+1; *Legionnaire sayısı Trooper sayısını geçemez* | Ölçeklenebilir gövde; oran kuralı "elit yığma"yı engeller |
| War Wolf | **Loping Dash** (+1D Dash) + **Assault Beast** (Chainsaw Mouth **ve** Shredding Claws, ikisi de `[Risky]`) + `[Negate Difficult Terrain]` | Dikenli teli yaran hücum canavarı; `[Risky]` iki-silah kombosunu yüksek riskli yapar |
| Wretched | **Law of Hell** + **Dark Blessing** + **Chattel** | Harcanabilir kaynak ekonomisi |

### 1.4 Mercenaries
Goetic Warlock (4 ), Scripture Guardian (7 ), Sin Eater (6 ). Üçü de **Glory Point** ile alınır.

### 1.5 Armoury — fraksiyonun karakteri
HL Armoury'si New Antioch'unkinden **daha dar ama daha karakterli**tir. Fraksiyona özgü kalemler:

| Kalem | Fiyat | Kısıt |
|---|---|---|
| Hellblade | 1  | LIMIT 2 |
| Sacrificial Blade | 23  | LIMIT 2, Elite only |
| Tartarus Claws | 15  | **Death Commando only** |
| Blasphemous Staff | 2  | Elite only |
| Hellbound Soul Contract | 5  | LIMIT 3, **Heretic Trooper only** |
| Unholy Relic / Unholy Trinket | 15  / 15  | — |
| Incendiary Ammunition | 15  | LIMIT 1 |
| Infernal Brand | 5  | `[Negate Fire]` |
| Armour of Cobar | 8  | Exploration, Elite only |

Ağır silahlar: Machine Gun 50 (**LIMIT 1**), Heavy Flamethrower 55 (LIMIT 2), Flamethrower 30 (LIMIT 3), Anti-Materiel Rifle 3 . Bunlar `[Strong]`/`[Negate Heavy]` taşıyan Anointed'in varlık sebebidir.

### 1.6 Variant Warband'lar
Heretic Naval Raiders, Trench Ghosts, Knights of Avarice.

### 1.7 Güçlü / Zayıf Yönler
| Güçlü | Zayıf |
|---|---|
| En çeşitli araç kutusu (8 farklı rol) | Fraksiyon-geneli pasif yok → sinerji birim yerleşimine bağlı |
| Wretched ile "ölmek bile fayda" ekonomisi | Elite'ler pahalı: Priest 80, Commando 90, AHI 95, War Wolf 145 |
| Puppet Master + Goetic Portal ile pozisyon kırma | Priest zırhsız (0), Chorister Ranged −2D |
| Artillery Witch: oyunun en yıkıcı tek atışı | Witch 100  + `[Reload]` + Melee −1D → çok kırılgan |
| Unholy Hymns kalıcı 8" baskı | Chorister ölünce aura anında gider |

---

## 2. Oyundaki Uygulama

### 2.1 Roster Karşılaştırması

| Compendium | Cost | Avail | Oyunda | Durum |
|---|---|---|---|---|
| Heretic Priest (Captain) | 80 | 1 | ✅ 80 / 1 | ✔ |
| Death Commando (Elite) | 90 | 0-1 | ✅ 90 / 1 | ✔ |
| Heretic Chorister (Elite) | 65 | 0-1 | ✅ 65 / 1 | ✔ |
| Anointed Heavy Infantry | 95 | 0-5 | ✅ 95 / 5 | ✔ |
| Artillery Witch | 100 | 0-1 (0-2 @ >1000) | ✅ 100 / 1 | ⚠ Battery kuralı yok |
| Heretic Trooper | 30 | Unlimited | ✅ 30 / 999 | ✔ |
| War Wolf Assault Beast | 145 | 0-1 | ✅ 145 / 1 | ✔ |
| Wretched | 25 | Unlimited | ✅ 25 / 999 | ✔ |
| *Merc:* Goetic Warlock | 4  | 0-1 | ✅ 4 / 1 | ⚠ birim para |
| *Merc:* Scripture Guardian | 7  | 0-1 | ✅ 7 / 1 | ⚠ birim para |
| *Merc:* Sin Eater | 6  | 0-1 | ✅ 6 / 1 | ⚠ birim para |

**11/11 birim mevcut. Eksik yok, fazla yok.**

### 2.2 Stat ve Keyword Doğruluğu

```
Heretic Priest    6" | +2D | +2D |  0  [Tough][Leader][Elite][Heretic]        ✔ hepsi
Death Commando    6" | +1D | +2D |  0  [Infiltrator][Elite][Heretic]          ✔ hepsi
Heretic Chorister 6" | -2D | +2D |  0  [Fear][Elite][Heretic]                 ✔ hepsi
Anointed Hvy Inf. 6" | +1D | +1D | -2  [Strong][Negate Heavy][Heretic]        ✔ + negate_fire (Infernal Brand)
Artillery Witch   6" |  0D | -1D |  0  [Negate Gas][Negate Fear][Artificial][Heretic] ✔ hepsi
Heretic Trooper   6" |  0D |  0D |  0  [Heretic]                              ✔
War Wolf          8" |  0D | +2D | -3  [Fear][Tough][Artificial][Heretic][Negate Difficult Terrain] ✔ hepsi
Wretched          6" | -1D | -1D |  0  [Heretic]                              ✔
Goetic Warlock    6" | +1D | +1D | -2  [Negate Fire][Fear][Demonic][Artificial] ✔ hepsi
Sin Eater         6" |  0D | +2D | -2  [Negate Fire][Fear][Strong][Negate Heavy][Tough][Demonic] ✔ hepsi
```

**Sıfır sapma.** Bu, denetlenen fraksiyonlar içinde en temiz stat/keyword eşleşmesidir.

### 2.3 Doğru Uygulanmış Mekanikler

| Mekanik | Nerede | Not |
|---|---|---|
| **Faction Rules yokluğu** | `heretic_legion.tres` `has_faction_rule = false` | Compendium'da `## Faction Rules` başlığı **yok** — **doğru karar** ✔ |
| **Puppet Master** | `_handle_force_move` | 12", `target_type = "any"` (dost/düşman), D6" düz çizgi, yönü CASTER seçer — RAW'a **çok sadık** ✔ |
| **Hide** | `set_flag` → `is_hidden` | Risky, +1D, hedeflenemezlik ✔ |
| **Stealth Generator** | `target_ranged_penalty: -1`, `dice_pool_builder.gd:114` | ✔ |
| **Unholy Hymns** | `dice_pool_builder.gd:132` | 8" aura, düşman Success Roll'una −1D ✔ |
| **Infernal Brand** | `negate_fire: 1` + `KeywordSystem.negates` | ✔ |
| **Levitate** | `unit.gd` | Climb/Jump/Fall zarı atlanır ✔ |
| **Abiotic Life** | `dice_pool_builder.gd:359` | Gas saldırısına −1 Injury Dice ✔ |
| **Heretic Legionnaire terfisi** | `heretic_trooper.tres` Loadout2/3 + `mechanics_resolver.gd:499` | +10 , Ranged **veya** Melee +1, **oran kuralı** (`legionnaire_count_after <= plain_trooper_count`) dahil ✔ — compendium'a tam sadık |
| **Law of Hell** | `mechanics_resolver.law_of_hell_triggers` + `unit.gd:1923` | Elite öldüren Wretched sahadan çekilir ✔ |
| **Dark Blessing** | `unit.gd:1878-1894` | En yakın `[Elite]`+`[Heretic]` dosta +1 Blessing Marker; **menzil sınırı yok** (compendium'daki gibi) ✔ |
| **Loping Dash** | `dash_dice_bonus`, `unit.gd` | Dash Risky Roll'una +1D ✔ |
| **Assault Beast silahları** | `chainsaw_mouth.tres` / `shredding_claws.tres` | **Birebir:** Chain Maw `[+1 Dice][+1 Injury Dice][Ignore Armour][Risky]`; Shredding Claws `[+1 Injury Dice][Cumbersome][Risky]` — projedeki **en sadık silah çifti** ✔ |
| **Infernal Bomb** | `infernal_bomb.tres` + `mechanics_resolver.gd:238-253` | 36", 1H, Blast 3", Scatter, Shrapnel, Reload, Ignore Cover, Ignore Long Range, **Infernal Strike (Deadly)**, **Mighty Explosion (D3" savurma)** — hepsi çalışıyor ✔ |
| **Goetic Portal** | `_handle_teleport` + `ability_executor.gd:469` | 6" ışınlanma **ve** 1" içindeki düşmanı beraberinde sürükleme dahil ✔ |
| **Goetic Gaze** | `add_blood`, 24" | Success → 1, Crit → 2 Blood Marker ✔ |
| **Barbed Embrace** | `unit_actions.gd` | 1" içindeki düşman Retreat yapamaz ✔ |
| **Iron Clawed Hands** | `iron_clawed_hands_attack.tres` | `[Cleave 2]` + `[Critical]` + off-hand ✔ |
| **Devour the Guilty** | `_handle_devour_the_guilty` | Düşmana Risky, dosta +1D normal roll; yutulan model Down sayılır; **her aktivasyonda +1 Blood Marker, 6'da OOA**; Sin Eater ölürse serbest bırakır; içeriden −3D Fight — **tüm alt maddeler uygulanmış** ✔ |
| **Purge** | `_handle_purge` | +4D Success Roll, Down olarak bırakır ✔ |
| **Fear** | `dice_pool_builder.gd:99-106` | Melee'de −1D; Fear'lı saldıran bağışık; Negate Fear ✔ |
| **Golem (Scripture Guardian)** | `injury_resolver.gd:175` | Bloodbath dışı OOA → Down; Tough ile çakışmaz ✔ |

**Değerlendirme:** Heretic Legion, birim yetenekleri açısından **projenin en iyi uygulanmış fraksiyonu**. Özellikle Sin Eater, Goetic Portal, Infernal Bomb ve Heretic Legionnaire terfisi RAW seviyesinde doğru.

---

## 3. Tespit Edilen Sorunlar

### 🔴 P0-HL-1 — Anointed Heavy Infantry ağır silah taşımıyor; üstelik silahı New Antioch temalı

**Bulgu:** `anointed_heavy_infantry.tres` saldırıları: `anointed_greatsword` (MELEE, 2H, `[Critical][Heavy]`, +1 Injury) + **`templar_pistol`** (RANGED, 6") + `templar_pistol_melee`.

**Neden sorun — iki katmanlı:**

**(a) Mekanik / rol.** Compendium AHI'yi **Ranged +1D**, `[Strong]`, `[Negate Heavy]`, `[-2]` Armour, 95  olarak tanımlar — fraksiyonun **en pahalı Infantry** birimi. `[Strong]` + `[Negate Heavy]` kombinasyonunun **tek varlık sebebi** HL Armoury'sindeki ağır silahları taşıyabilmektir: Machine Gun 50 (LIMIT 1), Heavy Flamethrower 55 (LIMIT 2), Flamethrower 30, Anti-Materiel Rifle. Oyunda AHI'nin elindeki tek ağır şey `anointed_greatsword` — ama o **melee**, ve `[Negate Heavy]` zaten melee için `[Strong]`'un doğal etkisi. Sonuç: `[Negate Heavy]` fiilen ölü, Ranged +1D bonusu 6"lik bir tabancaya harcanıyor. Lore'daki *"gain strength to wield weapons that a normal man could barely lift"* cümlesinin oyunda hiçbir karşılığı yok.

**(b) Tema.** Bir **Heretic** birimi `templar_pistol` ("Tapınakçı Tabancası") taşıyor. Templar, Trench Crusade'de Sadık taraf terminolojisidir. Anointed'in lore'u tam tersidir: Cehennem Kapısı'nın ötesine geçmiş, eti sonsuza dek yanmış, **Gehenna zırhı** giyen bir hacı. Cehennem'in dövdüğü bir silah taşımalı.

**Olması gereken:** AHI'ye bir HEAVY menzilli silah (Machine Gun veya Heavy Flamethrower) + HL temalı bir 1H yedek. `machine_gun.tres` zaten compendium'a sadık şekilde mevcut.

---

### 🔴 P0-HL-2 — Heretic Trooper ve Chorister'ın tüfeği 10" menzilli uydurma bir silah

**Bulgu:** `heretic_rifle.tres`: `attack_range = 10.0`, keyword yok, injury modifier yok. Heretic Trooper'ın (fraksiyonun tek Unlimited gövde birimi) ve Chorister'ın tek menzilli silahı bu.

**Neden sorun:**
- Compendium HL Armoury'de **Bolt-Action Rifle 10 , 24" menzil** vardır ve oyunda `bolt_action_rifle.tres` **zaten doğru şekilde mevcut** (24", `[Bayonet Lug]`) — ama sadece Yeoman kullanıyor.
- Compendium'daki hiçbir tüfek 10" değildir; en kısa menzilli uzun silah Jezzail'dir (18").
- Sonuç: HL'nin gövde birimi 10" menzille sahaya çıkıyor, New Antioch'un Yeoman'ı 24" ile. Bu, iki fraksiyon arasında compendium'da **var olmayan** bir menzil asimetrisi yaratıyor ve Legion'u zorla melee'ye itiyor — oysa Legion, compendium'da Machine Gun/Flamethrower/Anti-Materiel Rifle erişimi olan bir ateş gücü fraksiyonudur.

**Ek not:** `silenced_pistol` de 10". Compendium'da Silenced Pistol 15  (Elite only) bir Pistol'dür; standart Pistol menzili 8"dir. 10" burada daha az yanlış, ama yine de uydurma.

---

### 🔴 P0-HL-3 — Mercenary ekonomisi (fraksiyon-üstü; bkz. P0-NA-3)

**Bulgu:** Goetic Warlock 4, Sin Eater 6, Scripture Guardian 7 — hepsi Glory Point maliyeti, ama 700 ducat'lık `player_deploy_pool`dan düşülüyor.

**Heretic Legion'a özel şiddeti:** Sin Eater profili `[Negate Fire] [Fear] [Strong] [Negate Heavy] [Tough] [Demonic]`, Melee +2D, Armour −2, Tenderiser Maul (`[Heavy]`, +1 Injury, Swinging Blow). Oyunda maliyeti **6 puan** — bir Wretched'ın (25) **dörtte birinden az**. Goetic Warlock ise `[Demonic]` + `[Fear]` + Cleave 2 + ışınlanma + 24" Blood Marker basma yeteneğiyle **4 puan**. 700 ducat'lık bir Legion listesi üç mercenary'nin tamamını 17 puana alıp geri kalan 683'ü çekirdek rostere harcayabilir.

Bu, Legion'un tasarım dengesini tamamen bozar: compendium'da bu üç birim kampanyanın *geç aşama ödülü*dür.

---

### 🟠 P1-HL-4 — Artillery Witch: uydurma kısıt + üç eksik alt kural

**(a) Uydurma `[Cumbersome]`.** `infernal_bomb.tres`'te `is_cumbersome = true`. Compendium Infernal Bomb keyword listesi: `[Ignore Cover] [Ignore Long Range] [Ignore Elevated Position] [Blast 3"] [Scatter] [Shrapnel] [Reload]` — **`[Cumbersome]` yoktur.**

*Neden sorun:* Oyunda `[Cumbersome]` "aynı aktivasyonda Dash yapılamaz" demek. Artillery Witch, `[Reload]` yüzünden zaten iki turda bir ateş edebiliyor; üzerine Dash yasağı eklenince fraksiyonun **tek mobil topçusu** fiilen sabit bir taret hâline geliyor. Lore ise tersini söylüyor: *"Artillery Witches **stalk the battlefields**... supporting **lightning assaults**."* Bu, uydurulmuş bir kısıtın doğrudan lore'u ihlal etmesi.

**(b) `[Ignore Elevated Position]` eksik.** Compendium'da var, `infernal_bomb.tres`'te yok. Yüksekten atış avantajını (`dice_pool_builder.gd:138` `MOD_ELEVATED`) iptal etmesi gerekirdi — bu, havan/topçu silahlarının ayırt edici özelliğidir.

**(c) "Duck" kuralı eksik.** *"Add `[-1 Injury Dice]` for a model hit by an Infernal Bomb if it is in contact with a terrain piece at least ½" tall that lies between it and the target point."* Uygulanmamış. Bomba'nın `[Ignore Cover]` taşımasına karşı dengeleyici olan tek savunma bu.

**(d) Artillery Witch Battery eksik.** *"You may include 0-2 Artillery Witches if the total cost of all other models adds up to 1,000 or more."* `availability_max = 1` sabit. (Bütçe 700 olduğu için şu an ulaşılamaz, ama kampanya modunda gerekli.)

---

### 🟠 P1-HL-5 — War Wolf'un `[Negate Difficult Terrain]`'i uygulanmamış

**Bulgu:** `war_wolf_assault_beast.tres` içinde `negate_difficult_terrain: 1` var, ama `grep -rl "negate_difficult_terrain" scripts scenes` **boş dönüyor** — hiçbir kod yolu bu keyword'ü okumuyor.

**Neden sorun:** War Wolf'un lore'u tek cümleyle bu keyword'dür: *"This abomination **charges through miles of barbed wire, clearing a path for the Heretic infantry**. Its uniquely formed head is designed to cut cleanly through it."* 145 ducat'lık, fraksiyonun en pahalı birimi; ödediğin bedelin bir parçası bu araziyi yok sayma yeteneğidir. Şu an ölü.

*Kapsam notu:* Oyunda genel bir "Difficult Terrain" sistemi olup olmadığı ayrıca doğrulanmalı; yoksa bu, arazi katmanının eksikliğinin bir semptomudur.

---

### 🟠 P1-HL-6 — Death Commando'nun Battlekit kısıtı ve özel silahları yok

**Compendium:** *"The only Ranged Weapons they can have are **Silenced Pistols and Tormentor Chains**, and the only Grenades they can have are **Gas Grenades**. No restrictions apply to any other Types of Battlekit."* Ayrıca Armoury'de **Tartarus Claws (15 , Death Commando only)**.

**Oyunda:** `silenced_pistol` var ✓; **Tormentor Chains yok**, **Tartarus Claws yok**, Gas Grenades yok, kısıt sistemi yok.

**Neden sorun:** Death Commando 90  ile fraksiyonun **en pahalı Elite**'i. Compendium onu bilinçli olarak *dar ama benzersiz* bir silah havuzuna hapseder — "sessiz katil" kimliği bu kısıttan doğar. Oyunda ne kısıt ne de benzersiz silah var; geriye jenerik bir hançer + tabanca kalıyor.

---

### 🟠 P1-HL-7 — Fraksiyona özgü Armoury kalemlerinin **hiçbiri** yok

Aşağıdaki 10 kalemin oyunda karşılığı bulunmuyor:

| Kalem | Kayıp olan şey |
|---|---|
| **Hellblade** (1 , LIMIT 2) | Legion'un imza ucuz melee'si |
| **Sacrificial Blade** (23 , LIMIT 2, Elite only) | Kurban temasının tek silahı |
| **Tartarus Claws** (15 , Death Commando only) | Commando'nun kimlik silahı |
| **Blasphemous Staff** (2 , Elite only) | Priest/Chorister'ın büyücü kimliği |
| **Hellbound Soul Contract** (5 , LIMIT 3, Heretic Trooper only) | "Ruhunu satan asker" teması |
| **Unholy Relic / Unholy Trinket** (15  / 15 ) | Sadık tarafın kutsal emanetlerinin karşıtı |
| **Incendiary Ammunition** (15 , LIMIT 1) | Ateş teması |
| **Infernal Brand** (5 , ekipman olarak) | Oyunda yalnız AHI'ye gömülü; başkası alamıyor |
| **Armour of Cobar** (8 , Elite only) | — |

**Neden sorun:** Bu kalemler HL'nin **tematik yükünün büyük kısmını taşır**. "Cehennem'in armoury'si", "Tartarus demircilerinin metalürjisi", "ruh sözleşmeleri" — lore'daki bu unsurların oyundaki tek somut karşılığı bunlardı. Yokluklarında Legion, kırmızı boyalı bir New Antioch'a dönüşüyor.

---

### 🟠 P1-HL-8 — 3 Variant Warband yok

Heretic Naval Raiders, Trench Ghosts, Knights of Avarice — hiçbiri yok. *Trench Ghosts* özellikle önemli: compendium'da Heretic Priest, Death Commando, Heretic Chorister ve Heretic Trooper'ın görsel/tematik varyantı olarak işaretlenmiş (`fc_hereticlegion_fv_trenchghosts` etiketleri), yani fraksiyonun ana alt-kimliği.

---

### 🟡 P2-HL-9 — Küçük sapmalar

| # | Bulgu | Compendium | Oyun |
|---|---|---|---|
| a | Heretic Priest Shotgun loadout maliyeti | Shotgun 10  | `cost_delta = 3` |
| b | `heretic_bayonet` serbest kullanım | Bayonet yalnız `[Bayonet Lug]`'lı silahla | Bağımsız melee saldırısı olarak verilmiş |
| c | Wretched Battlekit kısıtı | Yalnız ≤10  kalemler; **en az 1 silah zorunlu** | Modellenmemiş (tek `legionary_dagger` sabit) |
| d | Wretched **Chattel** | Kampanyada 25  + battlekit'in yarısına satılabilir | Kampanya sistemi yok — N/A |
| e | `dark_blessing.tres` `range_meters = 12.0` | Menzil sınırı yok | Kod doğru davranıyor (menzilsiz), ama `.tres` verisi yanıltıcı |
| f | `faction_rule_summary` ölü metni | HL'nin `## Faction Rules` bölümü **yok** | `.tres` hâlâ `"FACTION_HERETIC_LEGION_RULES"`a işaret ediyor; o metin *"Hellfire pact… **Gain 1 Faith Point**"* diyor — **Faith Point Trench Crusade'de var olmayan bir kaynaktır**. `has_faction_rule=false` sayesinde gizli, ama silinmeli |
| g | `FACTION_HERETIC_LEGION_STORY` lore metni | Compendium: Cehennem Kapısı'na hac, Gözyaşları Vadisi, Anointed'in Alev Gölü çilesi | Oyun metni *"66 dark warlords"*, *"infernal covenant signed in blood"* diyor — **compendium'da geçmeyen** öğeler; hac/çile teması (fraksiyonun kimlik çekirdeği) hiç anılmıyor |

---

## 4. Özet Skor — Heretic Legion

| Eksen | Skor | Gerekçe |
|---|---|---|
| **Roster kompozisyonu** | 10/10 | 11/11 birim, birebir |
| **Stat sadakati** | 10/10 | Sıfır sapma |
| **Keyword sadakati** | 9/10 | Tümü doğru girilmiş; `negate_difficult_terrain` okunmuyor |
| **Fraksiyon pasifi** | 10/10 | Compendium'da yok, oyunda da yok — **doğru** |
| **Birim yetenekleri** | 9/10 | 20+ yetenek RAW seviyesinde; Sin Eater ve Goetic Portal örnek nitelikte |
| **Ekipman / Armoury** | 2/10 | 10 fraksiyona-özgü kalemin **hiçbiri** yok; AHI ağır silahsız; tüfek 10" |
| **Ekonomi** | 3/10 | Glory Point ↔ ducat (fraksiyon-üstü) |
| **Lore / tema** | 4/10 | Lore metni compendium'dan sapıyor; `templar_pistol` bir Heretic birimde; 3 Variant yok |
| **Oynanış kimliği** | 7/10 | Pozisyon manipülasyonu ve Wretched ekonomisi sağlam; ateş gücü ekseni çökmüş |

**Genel: 7.1 / 10** — Projenin **en iyi uygulanmış fraksiyonu**. Mekanik katman neredeyse kusursuz; kayıplar tamamen ekipman/tema katmanında.

### Öncelik sırası
1. **P0-HL-1** Anointed Heavy Infantry'ye ağır menzilli silah + `templar_pistol`'ü kaldır
2. **P0-HL-2** `heretic_rifle` menzilini 24"e çek veya `bolt_action_rifle` kullan
3. **P0-HL-3** Glory Point / ducat ayrımı (fraksiyon-üstü)
4. **P1-HL-4a** Infernal Bomb'dan uydurma `[Cumbersome]`'ı kaldır (tek satırlık düzeltme, lore'u geri kazandırır)
5. **P1-HL-4b/c** `[Ignore Elevated Position]` + Duck kuralı
6. **P1-HL-5** `[Negate Difficult Terrain]` implementasyonu
7. **P1-HL-7** HL'ye özgü Armoury kalemleri (en azından Hellblade, Tartarus Claws, Blasphemous Staff, Unholy Relic)
8. **P2-HL-9f/g** Uydurma faction rule metnini sil, lore metnini compendium'a hizala
