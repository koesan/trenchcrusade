# Faction Sadakat Denetimi — 01: The Principality of New Antioch

**Kaynak:** `trench_compendium/warbands/new-antioch.md` (1608 satır) + 6 Variant dosyası
**Oyun tarafı:** `assets/data/factions/new_antioch.tres`, 15 birim `.tres`, `scripts/rules/faction_rules.gd`, `scripts/turn_manager/turn_manager.gd`, `scenes/unit/unit.gd`
**Denetim tarihi:** 2026-07-28

---

## 1. Kaynak Materyaldeki Tasarım ve Amaç

### 1.1 Lore ve Tema
New Antioch, Cehennem Kapısı'nın gölgesinde 300 yıldır ayakta duran **kale-şehir**tir. 1545'te yıkılan antik Antakya'nın kraterinde, 1559 Viyana Kılıç Kongresi kararıyla yeniden inşa edilmiştir. Tüm Sadık ulusların yıllık haracıyla ayakta durur: para değil, **yiyecek, alet, mühimmat, silah, makine, kalifiye işçi ve mühendis** akışı.

Tematik çekirdek üç sütun üzerine kuruludur:

1. **Sanayi ve teknoloji.** Fabrikalar tank üretir, dökümhaneler topçu bataryalarını besler, tekno-laboratuvarlar Kurtarıcı'nın klonlanmış etiyle Communicant üretir. New Antioch, Trench Crusade'in "endüstriyel Sadık" tarafıdır.
2. **Çokuluslu gönüllü ordusu.** Sokaklarda yüzlerce dil konuşulur: Polonya-Litvanya hussarları, Varangian Muhafızları'nın son kalıntıları, Éire'li vaizler, Habeş askerleri. Kimlik "tek bir halk" değil, **koalisyon**tur.
3. **Savunma duruşu ve derinlik.** Sekiz büyük kuşatma, 77 kuleli surlar, duvarlara gömülü yüzlerce anchorite. New Antioch saldırgan değil, **dayanan** taraftır; ve Cehennem'in kendi iç çekişmesi sayesinde hâlâ ayaktadır.

Warband seviyesinde bu, "Dük'ün komisyonuyla No Man's Land'e gönderilen, kendi fonunu kendi toplayan küçük müfreze" olarak somutlaşır.

### 1.2 Oynanış Kimliği (Tabletop Rolü)
New Antioch, oyunun **"düz asker" / birleşik silah (combined arms)** fraksiyonudur:

- **Doğaüstü özelliği en az olan fraksiyon.** Demonic, Undead, Blessed Stigmata, Infection yoktur. Gücü *ekipmandan ve koordinasyondan* gelir.
- **En geniş Armoury erişimi.** 15 ranged silah, 3 el bombası tipi, 3 zırh, 2 kalkan, 12 ekipman + 13 Exploration kalemi. Otomatik Tüfek, Makineli Tüfek, Ağır Alev Silahı, Keskin Nişancı Tüfeği — hiçbir fraksiyonda bu genişlik yok.
- **İstisnai olarak ucuz ve sınırsız gövde birimi.** Yeoman: 30 , Unlimited. Fraksiyonun "sayı üstünlüğü" ekseni budur.
- **Uzmanlık birimleri.** Her biri dar ama net bir görev taşır: Sniper Priest (menzil), Combat Engineer (arazi/mayın/tahkimat), Combat Medic (idame), Mechanized Heavy Infantry (ağır silah platformu), Shocktrooper (yakın dövüş baskını).
- **Sıralama kontrolü.** Fraksiyonun gerçek "hile"si aktivasyon sırasını manipüle etmektir: Fireteam (iki modelin araya girilemez ortak aktivasyonu) + Hold Your Fire! (rakibi zorla aktive ettirme).

### 1.3 Faction Rules (compendium'daki TEK resmî pasif)

> **New Antioch Fireteams**
> Bir New Antioch Warband'ı **en fazla 2 Fireteam** içerebilir. Her Fireteam, Warband'daki **herhangi iki modelden** oluşur. Fireteam'deki tüm modeller `[Fireteam]` keyword'ünü **ek ücret olmadan** alır.
>
> **FIRETEAM:** Aynı Fireteam'deki modeller **eşzamanlı aktive olabilir**. Eylemlerini istedikleri sırayla alabilir, iki model arasında serbestçe geçiş yapılabilir. Ancak **birinin aktivasyonu biterse (örn. başarısız `[Risky Success]`), diğerininki de anında biter.**
>
> **Concentrated Attack:** Bir Fireteam modeli, **aynı ortak aktivasyonda** diğer üyenin daha önce vurduğu bir hedefi vurursa, **3 `[Blood Marker]` harcayarak** ikinci saldırının Injury Roll'unu **Bloodbath Roll'a** çevirebilirsin — **hedef Down olmasa bile**.

Tasarım amacı: New Antioch'un doğaüstü gücü yoktur; yerine **taktiksel eşgüdüm** verilir. "Bloodbath, hedef Down olmasa bile" maddesi kritiktir — normalde Bloodbath sadece Down hedefe uygulanır. Fireteam, sağlam bir eliti tek turda indirebilen **tek doğaüstü-olmayan burst** mekaniğidir.

### 1.4 Kısıtlamalar ve Genel Kurallar (fraksiyonu bağlayan)
- **Alignment: Faithful.** Fallen hizalı model alınamaz.
- **Maximum Elites: 6.** Warband hiçbir zaman 6'dan fazla `[Elite]` model içeremez — kampanya boyunca da geçerli.
- **Mercenaries** yalnız **Glory Point ()** ile alınır, ducat () ile **alınamaz**. Ve kritik madde:
  > *"Mercenaries do not benefit from the Faction Special Rules of your Warband, **such as the New Antioch Concentrated Attack rule**."*
- **Availability** limitleri: Lieutenant 1, Sniper Priest 0-2, Trench Cleric 0-1, Combat Engineer 0-2, Combat Medic 0-1, Mech. Heavy Infantry 0-3, Shocktrooper 0-5, Yeoman Unlimited.
- **6 Variant Warband:** Papal States Intervention Force, Eire Rangers, Stoßtruppen of the Free State of Prussia, Kingdom of Alba Assault Detachment, Expeditionary Forces of Abyssinia, The Red Brigade. Bunlar fraksiyonun "çokuluslu koalisyon" temasının mekanik karşılığıdır.

### 1.5 Güçlü / Zayıf Yönler (tabletop dengesi)
| Güçlü | Zayıf |
|---|---|
| En geniş silah havuzu, her role uygun kit | Model başına doğaüstü güç yok |
| Ucuz sınırsız Yeoman → sayı | Elite'ler pahalı, 6 tavanı sıkı |
| Fireteam ile araya girilemez 2-model burst | Fireteam zincirleme risk: biri düşerse ikisi de biter |
| Hold Your Fire! ile rakip tempo kırma | Lieutenant zırhsız (Armour 0), Tough'a rağmen kırılgan |
| Combat Engineer arazi kontrolü (mayın/Cover) | Sniper Priest melee -1D, angaje olunca işlevsiz |

---

## 2. Oyundaki Uygulama

### 2.1 Roster Karşılaştırması

| Compendium | Cost | Avail | Oyunda var mı | Oyun cost/avail | Durum |
|---|---|---|---|---|---|
| Lieutenant (Captain) | 70 | 1 | ✅ `new_antioch_lieutenant` | 70 / 1 | ✔ |
| Sniper Priest (Elite) | 50 | 0-2 | ✅ `new_antioch_sniper_priest` | 50 / 2 | ✔ |
| Trench Cleric (Elite) | 60 | 0-1 | ✅ `new_antioch_trench_cleric` | 60 / 1 | ✔ |
| Combat Engineer | 80 | 0-2 | ✅ `new_antioch_combat_engineer` | 80 / 2 | ✔ |
| Combat Medic | 65 | 0-1 | ✅ `new_antioch_combat_medic` | 65 / 1 | ✔ |
| Mechanized Heavy Infantry | 85 | 0-3 | ✅ `new_antioch_mechanized_heavy_infantry` | 85 / 3 | ✔ |
| Shocktrooper | 45 | 0-5 | ✅ `new_antioch_shocktrooper` | 45 / 5 | ✔ |
| Yeoman | 30 | Unlimited | ✅ `new_antioch_yeoman` | 30 / 999 | ✔ |
| *Merc:* Combat Biologist | 3  | 0-1 | ✅ | 3 / 1 | ⚠ birim para |
| *Merc:* Communicant Anti-Tank Hunter | 5  | 0-1 | ✅ | 5 / 1 | ⚠ birim para |
| *Merc:* Mamluk Faris | 4  | 0-1 | ✅ | 4 / 1 | ⚠ birim para |
| *Merc:* Mendelist Ammo Monk | 2  | 0-1 | ✅ | 2 / 1 | ⚠ birim para |
| *Merc:* Observer | 3  | 0-1 | ✅ | 3 / 1 | ⚠ birim para |
| *Merc:* Scripture Guardian | 7  | 0-1 | ✅ | 7 / 1 | ⚠ birim para |
| *Merc:* Witchburner | 5  | 0-1 | ✅ | 5 / 1 | ⚠ birim para |

**Roster kompozisyonu %100 doğru.** Eksik birim yok, fazla birim yok. Bu, denetlenen en temiz noktadır.

### 2.2 Stat Bloğu Doğruluğu

Tüm 8 çekirdek birim için Movement / Ranged / Melee / Armour değerleri compendium ile **birebir** eşleşiyor:

```
Lieutenant       6" | +2D | +2D | 0   → oyun: 6.0 / +2 / +2 / 0   ✔
Sniper Priest    6" | +2D | -1D | 0   → oyun: 6.0 / +2 / -1 / 0   ✔
Trench Cleric    6" | +1D | +1D | 0   → oyun: 6.0 / +1 / +1 / 0   ✔
Combat Engineer  6" |  0D | +1D | -2  → oyun: 6.0 /  0 / +1 / 2   ✔
Combat Medic     6" |  0D |  0D | -1  → oyun: 6.0 /  0 /  0 / 1   ✔
Mech. Hvy Inf.   6" | +1D |  0D | -2  → oyun: 6.0 / +1 /  0 / 2   ✔
Shocktrooper     6" |  0D | +1D | 0   → oyun: 6.0 /  0 / +1 / 0   ✔
Yeoman           6" |  0D |  0D | 0   → oyun: 6.0 /  0 /  0 / 0   ✔
```

Mercenary'ler de aynı şekilde doğru (Observer 8"/+1D/+2D/-1, Scripture Guardian -2 + `[Golem]`, vb.).

### 2.3 Doğru Uygulanmış Mekanikler

| Mekanik | Nerede | Not |
|---|---|---|
| **Fireteam ortak aktivasyon** | `faction_rules.gd:55` + `turn_manager.gd:321` | `forced_next_activator` ile "rakip araya giremez" garantisi sağlanıyor |
| **Fireteam erken bitiş** | `turn_manager.gd:324` | Partner Down ise onun da aktivasyonu biter |
| **Concentrated Attack** | `unit.gd:1690-1707` | Aynı aktivasyonda partnerin vurduğu hedefe Bloodbath — "Down olmasa bile" koşulu doğru |
| **Hold Your Fire!** | `ability_executor.gd:361` | Zar gerektirmez, aktivasyon biter, hedef zorunlu aktive olur ✔ |
| **Aim** | `aim.tres` + `_handle_buff_dice` | Risky, +2D roll bonusu, başarıda +2D ranged ✔ |
| **Absolute Faith** | `unit.gd:1347` | Rakip Sniper Priest'in ranged saldırısına Blood Marker ile −DICE basamıyor ✔ |
| **Onward, Christian Soldiers!** | `dice_pool_builder.gd:103` | 8" aura, dost NA modellere `[Negate Fear]` ✔ |
| **God is With Us!** | `god_is_with_us.tres` | Risky, 6" menzil, +1 Blessing Marker ✔ |
| **Fortify** | `CUSTOM_IMPLEMENTED` + `has_fortify_cover` | Risky, hareket edene kadar `[Cover]` ✔ |
| **Dug In (Shovel)** | `unit.gd:278` | Açık arazide başlayan model Cover alır ✔ |
| **Shock Charge** | `unit.gd:866-877` | Charge bonusunda 2D6 atıp en yükseği alır ✔ |
| **Assault Drill / Battlefield Demolition** | `negate_heavy_effect`, `mechanics_resolver.gd:433` | Tek silah için HEAVY etkisi yok sayılır ✔ |
| **Expert Medic** | `ability_executor.gd:138` | Treat'e +2 DICE ✔ |
| **Finish the Fallen** | `dice_pool_builder.gd:346` | Down hedefe +1 Injury Dice ✔ |
| **Steadfast (Machine Armour)** | `injury_resolver.gd:114` | Down sonucu Scratch'e düşer ✔ |
| **Trench Mole** | `new_antioch_yeoman.tres` Loadout3/4 | +10 , `[Infiltrator]`, `limit_group` ile toplam 2 tavanı ✔ |
| **Availability tavanları** | `game_state.gd:421` | Deploy'da denetleniyor ✔ |
| **Mercenary roster üyeliği** | `game.gd:465` | `faction_id` eşitliği değil `available_units` üyeliği kullanılıyor — **doğru tasarım karar** ✔ |
| **Automaton Destrier (Mamluk)** | `game.gd` + `mechanics_resolver.gd:67` | Kenar yerleşimi uygulanmış ✔ |
| **Eye of God (Observer)** | `combat_choice.gd`, `unit.gd` | Re-roll + 1 gelirse Down ✔ |
| **Voice of God (Observer)** | `CUSTOM_IMPLEMENTED` | ✔ |
| **Vengeful Scripture (Scripture Guardian)** | `CUSTOM_IMPLEMENTED` + `vengeful_scripture_attack.tres` | ✔ |
| **Ammunition Sacrament (Mendelist)** | `CUSTOM_IMPLEMENTED` | 3 sacrament seçimi ✔ |
| **Faithful Followers (Mendelist)** | `turn_manager.gd:336` | 1" içindeki modelle beraber aktivasyon ✔ |
| **Divine Judgement (Witchburner)** | `add_blood` + `blood_bonus_vs_unholy` | Unholy hedefe 2 marker ✔ |
| **Found Guilty (Gavel)** | `injury_resolver.gd:84` | No Effect dahil +1/+2 marker ✔ |
| **Prize Specimens (Combat Biologist)** | `mechanics_resolver.gd` | ✔ |
| **Battlefield Vivisection → Gather Knowledge** | `scenario_logic.gd` | Glorious Deed ekleniyor ✔ |

Bu tablo, New Antioch'un **birim düzeyinde en iyi uygulanmış fraksiyon** olduğunu gösteriyor.

---

## 3. Tespit Edilen Sorunlar

### 🔴 P0-NA-1 — Mechanized Heavy Infantry'nin menzilli silahı yok; rolü tersine dönmüş

**Bulgu:** `new_antioch_mechanized_heavy_infantry.tres` içindeki tek saldırı `templar_hammer.tres` (MELEE, 1.5", Ignore Armour, Cumbersome, +2 Injury Dice). Loadout seçenekleri sadece zırh değiştiriyor (`armour_override = 3` → Machine Armour).

**Neden sorun:**
- Compendium bu birimi **Ranged +1D / Melee 0D** olarak tanımlar. Yani zar profili açıkça *menzilli* bir birim.
- Lore: *"the Mechanized Heavy Infantry **wield the heavy weaponry of the company**."*
- `[Strong]` + `[Negate Heavy]` keyword'lerinin **tek varlık sebebi** ağır menzilli silah (Makineli Tüfek 50, Ağır Alev Silahı 55, Otomatik Tüfek 40) taşıyabilmektir. Oyunda bu iki keyword birimde var ama **taşıyacak bir HEAVY silah yok** → ölü keyword.
- Sonuç: oyunda MHI, +1D ranged bonusunu hiç kullanamayan, 0D melee ile balyoz sallayan bir birim. Compendium'daki rolünün **tam tersi**.
- Ek kanıt: `assets/data/attacks/machine_gun.tres` **zaten mevcut ve compendium'a sadık** (36", `automatic:3`, `heavy:1`, `reload:1`) — ama onu kullanan birimler `trench_pilgrim`, `heretic_priest`, `yuzbasi`. New Antioch'ta hiç kimse kullanmıyor.

**Olması gereken:** MHI'nin varsayılan/loadout saldırısı bir HEAVY menzilli silah olmalı (Machine Gun veya Heavy Flamethrower), yanında bir 1H yedek. Zırh seçimi (Reinforced -2 / Machine -2 + Steadfast) ayrı bir eksende kalmalı.

---

### 🔴 P0-NA-2 — Sniper Priest'in silahı Keskin Nişancı Tüfeği değil; 10" menzilli genel bir tüfek

**Bulgu:** Sniper Priest'in tek saldırısı `crusader_rifle.tres`: `attack_range = 10.0`, `is_sniper = false`, `injury_dice_modifier = 0`, keyword yok.

**Neden sorun:**
- Compendium New Antioch Armoury'de **Sniper Rifle (35 )** vardır ve oyunda böyle bir `.tres` **hiç yok**.
- Sniper Priest'in **iki yeteneğinin de tek amacı uzun menzilli atıştır**:
  - *Aim*: aktivasyon boyunca ranged saldırılara +2D.
  - *Absolute Faith*: rakip, bu birimin ranged saldırısına Blood Marker ile −DICE basamaz.
  Her ikisi de 10"lik bir menzilde büyük ölçüde anlamsızlaşır; birim düşman hattına girmek zorunda kalır, ama Melee −1D.
- Kıyas: aynı oyunda `bolt_action_rifle` 24", `machine_gun` 36", `anti_materiel_rifle` 36". 50 ducat'lık Elite keskin nişancının menzili 30 ducat'lık Yeoman'ınkinin **yarısından az**.
- Ayrıca `[Sniper]` keyword'ü (Long Range −1 DICE cezasını yok sayar) motorda destekli (`AttackData.is_sniper`) ama Sniper Priest'te kapalı.

**Olması gereken:** `sniper_rifle.tres` (≈36", 2H, `is_sniper = true`, `injury_dice_modifier = +1`) oluşturulup Sniper Priest'e verilmeli.

---

### 🔴 P0-NA-3 — Mercenary maliyetleri Glory Point olduğu hâlde ducat bütçesinden düşülüyor

**Bulgu:** Tüm senaryolarda `points_budget = 700`. Mercenary birimlerin `cost` değerleri 2–7 arası. `game.gd:481` bu maliyeti doğrudan `player_deploy_pool`dan (ducat havuzu) düşüyor.

**Neden sorun:**
- Compendium: *"Some models and pieces of Battlekit cost **Glory Points ()** instead of ()... Generally, Warbands don't have access to when they are first created."* ve *"Mercenaries... **cannot be purchased with **."*
- Oyunda 700 ducat ile: Witchburner (5) + Observer (3) + Scripture Guardian (7) + Mamluk Faris (4) + Combat Biologist (3) + Communicant ATH (5) + Mendelist Monk (2) = **29 puan**. 7 mercenary'nin tamamı, tek bir Yeoman'ın (30) fiyatına geliyor.
- Sonuç: optimal oyun daima "önce tüm mercenary'leri al, kalan 671 ducat ile normal kadroyu kur" olur. Fraksiyonun ekonomik kimliği tamamen çöker; üstelik bu **New Antioch'a özgü değil, tüm fraksiyonları** aynı anda bozar (mercenary listesi paylaşılıyor).
- Ayrıca tematik olarak yanlış: Glory Point "savaş alanında kazanılan şan"dır, kampanyanın ilerleyen aşamalarında elde edilir; ilk kadroda mercenary bulunmaması **kasıtlı bir tasarım kararıdır**.

**Olması gereken:** Ayrı bir `glory_points` havuzu (skirmish modunda varsayılan 0) ve `UnitData`'ya `cost_currency: ducat|glory` alanı. En azından, skirmish modunda mercenary'ler ya tamamen kapatılmalı ya da ducat karşılığı gerçekçi bir değere (≈ 60–120) çevrilmeli.

---

### 🔴 P0-NA-4 — Fireteam eşleştirmesi mercenary'leri de kapsıyor (açık kural ihlali)

**Bulgu:** `faction_rules.gd:55-73`:
```gdscript
var faction = GameState.get_faction_for_player(player_id)
if faction == null or faction.faction_id != &"new_antioch":
    continue
for u_name in GameState.units:
    var u = GameState.units[u_name]
    if is_instance_valid(u) and u.owner_id == player_id and u.current_health > 0:
        names.append(u_name)
names.sort()
```
Filtre **oyuncunun** fraksiyonuna bakıyor, **birimin** ne olduğuna değil. Sonra isim sırasına göre ilk 4 birim eşleştiriliyor.

**Neden sorun:**
1. Compendium bunu ismen yasaklar: *"Mercenaries do not benefit from the Faction Special Rules of your Warband, **such as the New Antioch Concentrated Attack rule**."* Oyunda bir Observer + Scripture Guardian çifti pekâlâ Fireteam olabiliyor ve Concentrated Attack (3 Blood Marker → Bloodbath) kullanabiliyor.
2. İsim sırasına göre alfabetik eşleştirme, "Combat Biologist" + "Combat Engineer" gibi tesadüfi çiftler üretir. Compendium *"any two models from the Warband"* der — bu bir **oyuncu kararıdır** ve fraksiyonun ana taktik kaldıracıdır. Deterministik alfabetik atama, mekaniğin karar değerini tamamen siler.
3. Mamluk Faris'in **Sworn Brethren** yeteneği (kendi ek Fireteam'ini bir `[Elite]` ile kurar, ve *"only the model from the New Antioch Warband can use the Concentrated Attack special rule"*) **hiç uygulanmamış** — `sworn_brethren` ne bir keyword ne bir handler olarak kodda geçmiyor.

**Olması gereken:** (a) Eşleştirme yalnızca `KeywordSystem.has(unit_data, &"new_antioch")` olan birimler arasında yapılmalı; (b) Concentrated Attack kontrolü saldıran birimin `[New Antioch]` keyword'ünü doğrulamalı; (c) uzun vadede eşleştirme deploy sonrası bir oyuncu seçimi olmalı.

---

### 🟠 P1-NA-5 — Mayın sistemi hiç yok; Combat Engineer'ın 4 yeteneğinden 2'si ölü

**Bulgu:**
- `set_mine.tres` ve `defuse_mine.tres` mevcut, `effect_type = "custom"`.
- `AbilityExecutor.CUSTOM_IMPLEMENTED` listesinde **ikisi de yok** → `execute()` erkenden iptal ediyor, `is_actionable_ability()` butonu bile üretmiyor.
- `[Mined]` / `negate_mined` kodda hiç geçmiyor (`grep` boş döndü) — Combat Engineer'ın `negate_mined: 1` keyword'ü tamamen ölü.
- Ek olarak `set_mine.tres` içinde `success_threshold = 5`, compendium ise standart **7+ ve +2 Dice** der. Hem eşik düşürülmüş hem +2 Dice verilmiş → çifte kolaylaştırma.

**Neden sorun:** Combat Engineer, New Antioch'un **arazi kontrolü** eksenidir; Set Mine / Defuse Mine / `[Negate Mined]` bu ekseninin üçte ikisidir. Geriye sadece Fortify + Dug In (ikisi de aynı şeyi yapıyor: Cover) kalıyor. 80 ducat ile fraksiyonun **en pahalı Infantry** birimi, işlevinin yarısını kaybetmiş durumda.

**Olması gereken:** Arazi parçalarına `[Mined]` bayrağı taşıyabilen bir marker sistemi; Set Mine (7+, +2D, non-risky), Defuse Mine (7+, risky, başarısızlıkta patlar), `[Negate Mined]` ile Engineer'ın mayına basmaması.

---

### 🟠 P1-NA-6 — Satchel Charge yok; Battlefield Demolition'ın taşıyacağı yük yok

**Bulgu:** Compendium Armoury'de **Satchel Charge (15 , LIMIT 3)** var ve Battlefield Demolition'ın tanımı doğrudan ona atıf yapar: *"You can ignore the Effect of the `[Heavy]` Keyword for **1 Satchel Charge** that a Combat Engineer has."* Oyunda `satchel_charge.tres` yok; `assets/data/attacks/` içinde tek bombalar `frag_grenade`, `holy_water_grenade`, `legionary_gasbomb`, `rot_grenade`, `infernal_bomb`.

**Neden sorun:** `negate_heavy_effect` keyword'ü Engineer'da var ama elinde HEAVY hiçbir şey yok (`crusader_rifle` + `sapper_shovel`, ikisi de HEAVY değil) → yetenek fiilen no-op. Aynı sorun Shocktrooper'ın **Assault Drill**'inde de var: HEAVY melee silahı (Great Hammer/Maul, Greatsword) oyunda Shocktrooper'a verilmemiş; elinde sadece `crusader_bayonet` var.

---

### 🟠 P1-NA-7 — Treat aksiyonu compendium'daki seçimi kaybetmiş ve Risky değil

**Bulgu:** `treat.tres`: `is_risky = false`, `effect_type = "stand_up"`, `range_meters = 2.0`.

**Compendium:**
> **Treat:** take a `[Risky Success]` Roll. **If the roll is a Failure, the model's Activation ends immediately.** If Success/Critical, you can do **one of the following**:
> - Remove `[1 Blood Marker]` from the model or a friendly model within 1".
> - Stand up a friendly model that is Down and within 1".

**Üç ayrı sapma:**
1. `is_risky = false` → başarısızlıkta aktivasyon bitmiyor. Compendium'da bitiyor. Medi-kit'in risk/ödül dengesi kayboluyor.
2. Sadece `stand_up` uygulanmış; **Blood Marker kaldırma seçeneği yok**. Combat Medic'in idame rolünün asıl yarısı bu. (Motorda `remove_blood` efekt tipi zaten var — kullanılmamış.)
3. `range_meters = 2.0` vs compendium 1". İki katı menzil.

---

### 🟠 P1-NA-8 — Hold Your Fire! yanlış hedefleme kısıtı kullanıyor

**Bulgu:** `hold_your_fire.tres`: `range_meters = 12.0`.

**Compendium:** *"pick 1 enemy model that is in the Lieutenant's **Line of Sight** and that the opponent is allowed to Activate."* — **Menzil sınırı yoktur**, kısıt yalnız **Line of Sight**'tır.

**Neden sorun:** Oyunda 12" keyfi bir tavan koyuyor ve LoS hiç kontrol edilmiyor (`ability_executor._validate` yalnız `range_meters` bakıyor; motorda `get_line_of_sight_status()` mevcut ama bu yetenekte kullanılmıyor). İki hata birbirini götürmüyor: masanın karşı ucundaki, açıkta duran bir düşmanı zorlayamıyorsun; ama 10" ötedeki, duvar arkasındaki bir düşmanı zorlayabiliyorsun. Yeteneğin taktik dokusu (görüş hattı kurmak için pozisyon alma) yok oluyor.

---

### 🟠 P1-NA-9 — `[Elite]` 6 tavanı hiçbir yerde uygulanmıyor

**Bulgu:** `DeployValidator.ALL_REASONS` içinde Elite ile ilgili bir ret sebebi yok; `grep -rn "elite"` yalnız senaryo Glorious Deed'lerinde eşleşiyor.

**Neden sorun:** *"A Warband can never include more than 6 models with the `[Elite]` Keyword."* — bu global bir warband kuralıdır ve doğrudan fraksiyon kimliğini şekillendirir. New Antioch'un Elite'leri (Lieutenant 1 + Sniper Priest 2 + Trench Cleric 1 = 4) zaten Availability ile sınırlı, ama Witchburner (`elite:1`) eklenince 5 olur ve tavan kritikleşir. Diğer fraksiyonlarda (özellikle Iron Sultanate, Court) tavan çok daha bağlayıcıdır.

---

### 🟠 P1-NA-10 — Alignment (Faithful/Fallen) sistemi yok

**Bulgu:** Kodda `alignment`, `faithful`, `fallen` kavramı hiç geçmiyor.

**Neden sorun:** *"All Warbands in this book are either Faithful or Fallen... Unless stated otherwise, a Warband cannot include models of the opposing alignment."* Şu an roster üyeliği `available_units` küratörlüğüyle korunuyor (pratikte çalışıyor), ama:
- Bu kavram `KeywordSystem.is_unholy()` gibi mekaniklerle iç içedir (Divine Judgement, Found Guilty, Prize Specimens hep hizalamaya bakar).
- Mercenary'lerin hangi fraksiyonlara gidebileceğini belirleyen ana filtredir; şu an her mercenary elle 1-2 rostere kopyalanmış durumda. Yeni mercenary eklendiğinde tutarlılık garantisi yok.

---

### 🟡 P2-NA-11 — 6 Variant Warband'ın hiçbiri yok

Papal States Intervention Force, Eire Rangers, Stoßtruppen of the Free State of Prussia, Kingdom of Alba Assault Detachment, Expeditionary Forces of Abyssinia, The Red Brigade — hiçbiri oyunda temsil edilmiyor; kodda "variant" kavramı yok.

**Neden sorun:** New Antioch'un **temel lore kimliği** "yüzlerce dil konuşulan çokuluslu gönüllü ordusu"dur. Variant'lar bu temanın tek mekanik ifadesidir. Bunlar olmadan New Antioch, temasız bir "generic Sadık asker" listesine indirgeniyor. Bu, "eksik içerik"ten öte bir **tematik kimlik kaybı**dır.

*Kapsam notu:* Variant'lar tam bir roster-builder gerektirir; kısa vadede en azından Codex/lore ekranında tanıtılmaları bile temayı geri kazandırır.

---

### 🟡 P2-NA-12 — Armoury sistemi yok; fraksiyonun ana ayırt edici özelliği temsil edilmiyor

**Bulgu:** Compendium New Antioch Armoury'si **7 melee + 15 ranged + 3 grenade + 3 armour + 2 shield + 12 equipment + 13 exploration = 55 kalem**. Oyunda `LoadoutOption` sistemi var ama New Antioch'ta yalnız 3 birimde, toplam **8 seçenek** tanımlı (Lieutenant 2, Yeoman 4, MHI 2).

**Neden sorun:** "En geniş silah erişimi" New Antioch'un **birincil fraksiyon ayırt edicisidir** — doğaüstü gücü olmayan bir fraksiyonun tek üstünlüğü budur. Sabit silahlı bir rosterle New Antioch, kendi tasarım tezinin tam tersini oynuyor.

*Kapsam notu:* Bu bilinçli bir mimari basitleştirme (`loadout_option.gd` başlığında dokümante edilmiş). Sorun olarak raporluyorum çünkü **fraksiyon kimliğini** doğrudan etkiliyor; ama tam Armoury bir roster-builder projesidir.

---

### 🟡 P2-NA-13 — Silah varlıkları New Antioch'a ait değil (uydurma isim ve değerler)

| Birim | Oyundaki silah | Menzil | Compendium karşılığı |
|---|---|---|---|
| Lieutenant | `templar_pistol` | 6.0 | Armoury'de "Pistol" (8") — "Templar Pistol" diye bir şey yok |
| Lieutenant | `templar_pistol_melee` | 1.5 | Pistol'ün melee kullanımı diye bir kural yok |
| Sniper Priest / Combat Engineer | `crusader_rifle` | 10.0 | "Crusader Rifle" yok; Bolt-Action 24", Semi-Auto, Sniper 35 |
| Shocktrooper / Trench Cleric / Yeoman | `crusader_bayonet` | 1.5 | "Bayonet" (2 , yalnız BAYONET LUG'lı silahla) |
| MHI | `templar_hammer` | 1.5 | "Great Hammer/Maul" (10 ) |

**Neden sorun:** İki katmanlı. (a) İsimlendirme: "Templar"/"Crusader" ön ekleri Trench Crusade'de New Antioch'a ait terimler değil; fraksiyonun kendi terminolojisi (Yeoman, Shocktrooper, Mendelist, Communicant) çok belirgin ve tutarlı. (b) Değerler: `crusader_rifle` 10" — compendium'daki hiçbir tüfek bu menzilde değil (en kısası Jezzail 18"). Yeni eklenen varlıklar (`bolt_action_rifle` 24", `machine_gun` 36", `anti_materiel_rifle` 36") ise **tam doğru**; yani eski "crusader/templar" varlıkları compendium öncesi yer tutuculardır ve temizlenmeleri gerekir.

Ayrıca compendium'da Lieutenant'ın **sabit battlekit'i yoktur** (*"can have any Battlekit from the New Antioch Armoury Tables"*) — oyunda ona zorla bir tabanca verilmiş.

---

### 🟡 P2-NA-14 — `max_health` ve `willpower` alanları Trench Crusade'de yok

**Bulgu:** `UnitData.max_health` (Lieutenant 12, Yeoman 10, MHI 15…) ve `UnitData.willpower` (5–7) alanları tanımlı. Ancak:
- `willpower` motorda **hiç okunmuyor** (grep: sadece `unit_data.gd`).
- `max_health` yalnız `current_health > 0` biçiminde **hayatta/ölü bayrağı** olarak kullanılıyor; `injury_resolver.gd:182` OOA'da `current_health = 0` yapıyor. Hasar biriktiren bir HP sistemi yok.

**Neden sorun:** Trench Crusade'de **hit point yoktur**; sonuç yalnız Injury Roll tablosundan gelir (No Effect / Blood Marker / Down / Out of Action) ve motor bunu **doğru** uyguluyor. Sorun mekanikte değil, veride: birim kartlarında/UI'da 12 HP vs 10 HP gibi anlamlı görünen ama motorda hiçbir etkisi olmayan sayılar duruyor. Bu, hem gelecekte yanlış bir "HP" mekaniğine kapı açar hem de oyuncuya var olmayan bir istatistik gösterir.

**Olması gereken:** İkisi de kaldırılmalı ya da açıkça "deprecated / kullanılmıyor" olarak işaretlenip UI'dan çıkarılmalı.

---

### 🟡 P2-NA-15 — Küçük sapmalar

| # | Bulgu | Compendium | Oyun |
|---|---|---|---|
| a | **Trench Mole 3. adet** | Warband toplamı ≥1000  ise 3. Trench Mole alınabilir | Uygulanmamış (bütçe 700 olduğu için ulaşılamaz — ama kampanyada gerekli) |
| b | **Ballistic Box Armour** | Engineer Body Armour: Shrapnel isabetinde `[-1 Injury Dice]`, **saldıranda Ignore Armour olsa bile** | Yalnız `negate_shrapnel` var; ek −1 Injury Dice yok |
| c | **Martial Prowess (Mamluk)** | Greatsword'den HEAVY kalkar, Jezzail `[Assault]` + Shield Combo kazanır | `martial_prowess.tres` var ama kodda hiç okunmuyor |
| d | **Sworn Brethren (Mamluk)** | Elite bir modelle ek Fireteam kurar | Uygulanmamış (kodda hiç geçmiyor) |
| e | **`set_mine` eşiği** | Success Roll 7+, +2 Dice | `success_threshold = 5`, `dice_modifier = 2` |
| f | **`faction_rule_summary` ölü metinleri** | — | `heretic_legion` / `iron_sultanate` / `trench_pilgrims` `.tres`'lerinde `has_faction_rule = false` olmasına rağmen **uydurma** kural metinlerine işaret eden anahtarlar duruyor (bkz. §4). UI doğru şekilde gizliyor, ama veri yanıltıcı. |

---

## 4. Çapraz-Fraksiyon Uyarısı (bu denetimde ortaya çıktı, ilgili raporlarda derinleştirilecek)

`assets/localization/en.json` içinde **compendium'da hiç var olmayan**, tamamen uydurulmuş fraksiyon kuralı metinleri bulunuyor:

- `FACTION_HERETIC_LEGION_RULES`: *"Hellfire pact… Blood Sacrifice: **Gain 1 Faith Point**"*
- `FACTION_IRON_SULTANATE_RULES`: *"Alchemical Armor: **All models receive a +1 Armour bonus**… Ranged Focus: Re-roll failed shoot rolls of 1"*
- `FACTION_TRENCH_PILGRIMS_RULES`: *"Holy Wrath… Martyrdom"*
- `FACTION_DEFAULT_RULES`: *"Shield of Faith: **Spend Faith points** to negate incoming hits"*

**"Faith Point" Trench Crusade'de var olmayan bir kaynaktır.** Bu üç fraksiyonun compendium'da `## Faction Rules` başlığı **yoktur** — kimlikleri birim yeteneklerinden gelir, ki `faction_rules.gd` başlığı bunu doğru tespit etmiş. Metinler şu an `has_faction_rule` bayrağıyla gizleniyor, ama silinmeleri gerekir; aksi halde bir gün bayrak açıldığında oyuncuya masa oyununda olmayan kurallar gösterilir.

`FACTION_NEW_ANTIOCH_RULES`, `FACTION_CULT_OF_THE_BLACK_GRAIL_RULES` ve `FACTION_COURT_OF_SEVEN_HEADED_SERPENT_RULES` metinleri ise **compendium'a sadık**.

---

## 5. Özet Skor — New Antioch

| Eksen | Skor | Gerekçe |
|---|---|---|
| **Roster kompozisyonu** | 10/10 | Birebir; eksik/fazla birim yok |
| **Stat sadakati** | 10/10 | 15 birimin tümünde Movement/Ranged/Melee/Armour/Cost/Availability doğru |
| **Keyword sadakati** | 9/10 | Doğru; yalnız `negate_mined` ölü |
| **Fraksiyon pasifi (Fireteam)** | 6/10 | Mekanik doğru uygulanmış; mercenary filtresi ve oyuncu seçimi eksik |
| **Birim yetenekleri** | 7/10 | 25+ yetenek doğru; Set/Defuse Mine ölü, Treat eksik |
| **Ekipman / Armoury** | 3/10 | Armoury sistemi yok; MHI ve Sniper Priest'in silahları rolleriyle çelişiyor |
| **Ekonomi** | 3/10 | Glory Point ↔ ducat karışımı fraksiyon-üstü bir sorun |
| **Lore / tema** | 5/10 | Fraksiyon metinleri doğru; ama 6 Variant yok → "çokuluslu koalisyon" teması temsil edilmiyor |
| **Oynanış kimliği** | 5/10 | "Sıralama kontrolü" ekseni sağlam; "birleşik silah + geniş armoury" ekseni yok |

**Genel: 6.4 / 10** — Veri katmanı örnek niteliğinde sadık, mekanik katman kısmen sadık, ekipman/ekonomi katmanı fraksiyonun tasarım tezini taşımıyor.

### Öncelik sırası
1. **P0-NA-1** MHI'ye ağır menzilli silah ver (`machine_gun.tres` zaten hazır)
2. **P0-NA-2** `sniper_rifle.tres` oluştur, Sniper Priest'e ver
3. **P0-NA-4** Fireteam eşleştirmesini `[New Antioch]` keyword'üyle filtrele
4. **P0-NA-3** Glory Point / ducat ayrımı (fraksiyon-üstü)
5. **P1-NA-7** Treat'e `remove_blood` seçeneği + `is_risky = true`
6. **P1-NA-8** Hold Your Fire!: menzil kaldır, LoS koy
7. **P1-NA-5/6** Mayın sistemi + Satchel Charge
8. **P1-NA-9** `[Elite]` 6 tavanı
9. **P2** Silah varlığı temizliği, `willpower`/`max_health` kaldırma, Variant'lar
