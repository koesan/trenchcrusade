# Trench Crusade — Faksiyon Sadakat Denetimi: NİHAİ RAPOR

**Kapsam:** Oyunda mevcut 6 faksiyonun, `trench_compendium/` içindeki kaynak materyale sadakati
**Yöntem:** Faksiyon başına compendium warband dosyası (lore + Faction Rules + roster + abilities + Armoury + Variants) tam okuma → oyundaki `.tres` verisi ve GDScript motor kodu ile satır düzeyinde karşılaştırma
**Denetim tarihi:** 2026-07-28
**Detay raporlar:** `01_new_antioch.md` · `02_heretic_legion.md` · `03_trench_pilgrims.md` · `04_iron_sultanate.md` · `05_cult_of_the_black_grail.md` · `06_court_of_the_seven_headed_serpent.md`

---

## 1. Yönetici Özeti

Bu proje, Trench Crusade'in kural motorunu **beklenenin çok üzerinde bir doğrulukla** uygulamış. Injury Roll tablosu, Blood/Infection Marker ekonomisi, Bloodbath, Tough/Golem/Memento Mori zinciri, Fear, Cover, Charge geometrisi, Diving Charge, Scatter+Blast, Risky Success — hepsi compendium'a sadık. Faksiyon düzeyinde ise **65 birimin tamamında** Movement/Ranged/Melee/Armour/Cost/Availability değerleri ve keyword listeleri **neredeyse sıfır sapmayla** doğru girilmiş.

Buna karşılık üç sistemik boşluk, faksiyonların masa oyunundaki kimliklerini oyunda görünmez kılıyor:

> **1. Ekipman katmanı yok.** Altı faksiyonun Armoury tablolarındaki ~70 faksiyona-özgü kalemin oyunda karşılığı olan sayısı **2**'dir (Titan Zulfiqar, Assassin's Dagger). Faksiyon kimliğinin büyük kısmı silah/ekipman isimlerinde ve kısıtlarında yaşar.
>
> **2. "Ağır silah platformu" birimlerinin hiçbirinde ağır silah yok.** `[Strong]` + `[Negate Heavy]` + Ranged bonusu taşıyan **beş birim** (New Antioch MHI, Heretic Anointed, Iron Sultanate Brazen Bull, Black Grail Amalgam, Court Desecrated Saint) oyunda tek bir melee silahla bırakılmış. Bu keyword çiftinin var oluş sebebi ortadan kalkmış.
>
> **3. Ekonomi tek para birimi üzerinden işliyor.** Mercenary'ler Glory Point () ile fiyatlanmış olmasına rağmen 700 ducat'lık () havuzdan düşülüyor. Sonuç: oyunun en güçlü 10 birimi, en ucuz askerin fiyatına satın alınabiliyor.

Ayrıca **üç faksiyonun `.tres` dosyasında compendium'da hiç var olmayan, uydurulmuş "fraksiyon kuralı" metinleri** duruyor (Heretic Legion, Iron Sultanate, Trench Pilgrims — "Faith Point" gibi Trench Crusade'de bulunmayan bir kaynağa atıf yapıyorlar). Şu an `has_faction_rule = false` bayrağıyla gizleniyorlar, ama silinmeleri gerekiyor.

---

## 2. Faksiyon Skor Tablosu

| Faksiyon | Roster | Stat | Keyword | Fraksiyon pasifi | Yetenekler | Armoury | Ekonomi | Lore/Tema | Oynanış kimliği | **Genel** |
|---|---|---|---|---|---|---|---|---|---|---|
| **Court of the Seven-Headed Serpent** | 10 | 10 | 10 | 7 | 9 | 1 | 2 | 4 | 8 | **7.4** |
| **Heretic Legion** | 10 | 10 | 9 | 10 | 9 | 2 | 3 | 4 | 7 | **7.1** |
| **Cult of the Black Grail** | 10 | 10 | 10 | 7 | 9 | 1 | 3 | 6 | 6 | **6.9** |
| **New Antioch** | 10 | 10 | 9 | 6 | 7 | 3 | 3 | 5 | 5 | **6.4** |
| **Iron Sultanate** | 10 | 10 | 8 | 10 | 5 | 2 | 3 | 6 | 4 | **6.4** |
| **Trench Pilgrims** | 8 | 10 | 10 | 10 | 7 | 1 | 2 | 4 | 5 | **6.3** |
| **ORTALAMA** | **9.7** | **10** | **9.3** | **8.3** | **7.7** | **1.7** | **2.7** | **4.8** | **5.8** | **6.75** |

**Okuma:** Veri katmanı (roster/stat/keyword) örnek nitelikte — **9.7/10 ortalama**. Motor katmanı (fraksiyon pasifi + yetenekler) güçlü — 8.0. Ekipman ve ekonomi katmanları çökmüş durumda — **1.7 ve 2.7**. Lore/oynanış kimliği skorları, bu iki çöküşün doğrudan sonucudur.

---

## 3. Fraksiyon Pasifleri — Doğruluk Denetimi

Compendium'da yalnız **üç** faksiyonun `## Faction Rules` bölümü vardır. Oyun bunu **doğru tespit etmiş**:

| Faksiyon | Compendium'da `## Faction Rules`? | `has_faction_rule` | Doğru mu? |
|---|---|---|---|
| New Antioch | ✅ Var (Fireteams + Concentrated Attack) | `true` | ✔ |
| Cult of the Black Grail | ✅ Var (Infection Markers + Morale + Order of the Fly) | `true` | ✔ |
| Court of the Seven-Headed Serpent | ✅ Var (Nobles of the Court + Goetic Powers) | `true` | ✔ |
| Heretic Legion | ❌ Yok | `false` | ✔ |
| Iron Sultanate | ❌ Yok | `false` | ✔ |
| Trench Pilgrims | ❌ Yok | `false` | ✔ |

**6/6 doğru.** Bu, projenin compendium'u dikkatli okuduğunun en net kanıtı.

### Pasiflerin uygulama durumu

| Pasif | Alt madde | Uygulanmış |
|---|---|---|
| **NA — Fireteams** | Ortak aktivasyon, araya girilememe, partner erken bitiş | ✅ |
| **NA — Concentrated Attack** | 3 Blood Marker → Bloodbath, "Down olmasa bile" | ✅ |
| NA — Fireteam üye seçimi | *"any two models from the Warband"* (oyuncu kararı) | ❌ alfabetik otomatik |
| NA — Mercenary muafiyeti | *"Mercenaries do not benefit from... Concentrated Attack"* | ❌ **kural ihlali** |
| **BG — Infection Markers** | Ayrı havuz, 6 tavan, birleşik harcama, temizlenememe, aktivasyonda +1 | ✅ **8/8 madde** |
| **BG — Morale −1 Dice** | Court/Black Grail istisnası dahil | ✅ |
| BG — The Order of the Fly | Lider tipi seçimi + zorunluluk + dinamik availability | ❌ **hiç yok** |
| **Court — Goetic Powers** | Zar yok, Blood maliyeti, Demonic/BG'den alınamaz, LoS yok, çok kaynaklı ödeme, aralıklı maliyet, aktivasyon başına 1 kez, Cast Spell çoklu | ✅ **8/8 madde** |
| Court — Goetic satın alma | *"purchased at the indicated cost"* + slot sayısı | ❌ hepsi bedava |
| Court — Nobles of the Court | *"must include a Praetor OR a Sorcerer"* | ⚠ "en fazla 1" ✅, "zorunlu" ❌ |

---

## 4. Sistemik Bulgular (fraksiyon-üstü)

### 🔴 S-1 — Glory Point / ducat karışımı: tek para birimi tüm ekonomiyi bozuyor

**Bulgu:** Tüm senaryolarda `points_budget = 700` (ducat). Mercenary birimlerin `cost` alanları compendium'daki **Glory Point** değerleridir (2–7) ve aynı havuzdan düşülüyor.

**Compendium:**
> *"Some models and pieces of Battlekit cost **Glory Points ()** instead of ()... Generally, Warbands don't have access to when they are first created."*
> *"Mercenaries... **cannot be purchased with **."*

**Etki tablosu:**

| Faksiyon | Mercenary'lerin toplam "maliyeti" | En ucuz normal askeri |
|---|---|---|
| Trench Pilgrims | 21 puan (5 merc) | Ecclesiastic Prisoner 20 |
| Court | 17 puan (3 merc) | Wretched 20 |
| New Antioch | 29 puan (7 merc) | Yeoman 30 |
| Heretic Legion | 17 puan (3 merc) | Wretched 25 |
| Iron Sultanate | 14 puan (3 merc) | Azeb 25 |
| Black Grail | 13 puan (2 merc) | Grail Thrall 25 |

Yani **her faksiyonda, mercenary kadrosunun tamamı tek bir en ucuz askerin fiyatına geliyor.** Optimal oyun daima "önce tüm mercenary'leri al" olur. Bu sadece bir denge sorunu değil, tematik bir ters çevirmedir: Glory Point "savaş alanında kazanılan şan"dır ve kampanyanın geç aşamasına aittir; mercenary'lerin ilk kadroda bulunmaması **kasıtlı bir tasarım kararıdır**.

**Aşırı örnekler:**
- **Sin Eater — 6 puan.** `[Negate Fire][Fear][Strong][Negate Heavy][Tough][Demonic]`, Melee +2D, Armour −2, Tenderiser Maul. Cult of the Black Grail'in **tek `[Fire]` zaafını** kapatıyor.
- **Communicant Anti-Tank Hunter — 5 puan.** `[Regenerate 1][Strong][Negate Heavy][Tough]`, Anti-Materiel Rifle (36", Ignore Armour). Trench Pilgrims'in **100 ducat'lık Communicant'ından daha iyi bir platform**.
- **Mamluk Faris — 4 puan.** Armour −2/−3. Iron Sultanate'in **8 çekirdek biriminin tamamı Armour 0'dır**; 4 puanlık merc, tüm rosterden daha zırhlı.

**Öneri:** `UnitData`'ya `cost_currency: ducat | glory` alanı + `GameState.player_glory_pool` (skirmish'te varsayılan 0). Kısa vadede: skirmish modunda mercenary'leri kapat veya ducat karşılığı gerçekçi değere (≈60–120) çevir.

---

### 🔴 S-2 — `[Strong]` + `[Negate Heavy]` taşıyan **beş** birimin hiçbirinde ağır silah yok

Bu, denetimdeki **en tekrarlayan hatadır** ve beş faksiyonu birden vuruyor.

| Faksiyon | Birim | Cost | Ranged | Oyundaki tek/ana silah | Compendium'un öngördüğü |
|---|---|---|---|---|---|
| New Antioch | Mechanized Heavy Infantry | 85 | **+1D** | `templar_hammer` (MELEE) | Machine Gun 50, Heavy Flamethrower 55, Automatic Rifle 40 |
| Heretic Legion | Anointed Heavy Infantry | 95 | **+1D** | `anointed_greatsword` + `templar_pistol` (6") | Machine Gun 50, Heavy Flamethrower 55, Flamethrower 30 |
| Iron Sultanate | Brazen Bull | 100 | 0D | `titan_zulfiqar` (MELEE) | **Flame Cannon 60 / M.U.R.A.D Bombard 50** (Brazen Bull only) |
| Cult of the Black Grail | Amalgam | 140 | 0D | `legionary_dagger` (tek!) | **6 silaha kadar** + Machine Gun 50 (Amalgam only) |
| Court | Desecrated Saint | 140 | 0D | `plague_sword` (tek!) | **3× 1-El melee** veya 2× 1-El + 1× 2-El |

**Neden bu tek bir hata sınıfı:** `[Strong]` (2-El silahı tek elle kullan) ve `[Negate Heavy]` (HEAVY cezasını yok say) keyword'lerinin **tek işlevi** ağır silah taşımaktır. Beş birimde de bu keyword'ler doğru girilmiş ✅ ama taşıyacakları silah yok → keyword'ler ölü.

**İkinci katman:** Amalgam ve Desecrated Saint'te `annihilator` mekaniği (her silahla ayrı saldırı, Off-Hand cezası yok) **kodda hazır ve doğru** — ama tek silah verildiği için hiç tetiklenmiyor. İkisi de kendi faksiyonlarının en pahalı birimi (140 ducat) ve ödedikleri bedelin karşılığı **saldırı sayısıdır**.

**Öneri:** En yüksek etki/maliyet oranlı düzeltme. `machine_gun.tres` zaten compendium'a sadık şekilde mevcut (36", `automatic:3`, `heavy:1`, `reload:1`) ve **hiçbir ağır piyade birimi kullanmıyor** — yalnız `trench_pilgrim`, `heretic_priest`, `yuzbasi` referans veriyor.

---

### 🔴 S-3 — Armoury katmanı: ~70 faksiyona-özgü kalemin 2'si var

| Faksiyon | Compendium'daki özgün kalem | Oyunda | Kayıp olan kimlik |
|---|---|---|---|
| New Antioch | 55 kalem (15 ranged, 7 melee, 3 grenade, 3 armour, 2 shield, 12 equipment, 13 exploration) | ~0 | "En geniş silah erişimi" — fraksiyonun **birincil ayırt edicisi** |
| Heretic Legion | Hellblade, Sacrificial Blade, Tartarus Claws, Blasphemous Staff, Hellbound Soul Contract, Unholy Relic/Trinket, Incendiary Ammunition, Infernal Brand, Armour of Cobar | 0 | "Cehennem armoury'si", Tartarus metalürjisi |
| Trench Pilgrims | Musket, Blunderbuss, Punt Gun, Flail/Scourge, Molotov Cocktail, War-Cross, Anti-Tank Hammer, Martyrdom Pills, Holy Icon Shield, Blessed Icon, Iron Capirote, Donkey's Jawbone | 0 | *"anything they can get their hands on, from antique muskets to scourges and Molotov cocktails"* — **lore'un merkez cümlesi** |
| Iron Sultanate | Alaybozan, Halberd-Gun, Flame Cannon, M.U.R.A.D Bombard, Siege Jezzail, Alchemical Ammunition, Alchemist Armour, Cloak of Alamut, Marid Shovel, Takwin Anqa Bird, Incendiary Grenades | **2** (Titan Zulfiqar, Assassin's Dagger) | Kültürel isimlendirme (al-Qarnayn, Zulfiqar, Marid, Takwin, Alamut) |
| Cult of the Black Grail | Corruption Belcher, Infested Rifle, Putrid Shotgun, Viscera Cannon, Parasite Grenades, Beelzebub's Axe, Plague Blade, Black Grail Shield, Compound Eyes Helmet, Grail Devotee, Armour of the Fly | 0 | **Menzilli enfeksiyon dağıtımı** (bkz. S-4) |
| Court | Malebranche Sword, Hellblade, Head Taker, Torture Instrument, Ophidian Rifle, Serpent Assault Gun, Arquebus, Crown of Hellfire, Restraining Muzzle, Incendiary Ammunition, Unholy Relic/Trinket | 0 | Cehennem sarayı estetiği |

**Sonuç — silah "ödünç alma" haritası:** Faksiyonlar birbirlerinin silahlarını taşıyor.

| Silah | Gerçek sahibi | Kimlere verilmiş |
|---|---|---|
| `templar_pistol` / `templar_hammer` ("Templar" = **Sadık** terminolojisi) | New Antioch | **Heretic Legion** Anointed, **Court** Hell Knight, **Court** Yoke Fiend |
| `crusader_bayonet` / `crusader_rifle` ("Crusader") | New Antioch | **Trench Pilgrims** Trench Pilgrim |
| `legionary_dagger` / `legionary_gasbomb` | Heretic Legion | **Black Grail** Corpse Guard + Amalgam + Herald, **Court** Sorcerer + Wretched |
| `plague_sword` | Cult of the Black Grail | **Court** Desecrated Saint |
| `feeble_flailing` | Trench Pilgrims (Ecclesiastic Prisoner) | **Black Grail** Grail/Fly Thrall |
| `frag_grenade` (TP armoury'sinde **yok**) | New Antioch | **Trench Pilgrims** |

**En keskin örnek:** Cehennem'in Savaş Konseyi'nin şövalyesi (**Hell Knight**, `[Demonic]` + `[Negate Fire]`) **"Tapınakçı Çekici"** taşıyor.

---

### 🔴 S-4 — Mekanizma hazır, veri yok: uygulanmış ama ulaşılamayan sistemler

Denetimin en ironik bulgu sınıfı. Motor kodu compendium'a sadık şekilde yazılmış, ama onu tetikleyecek veri hiç oluşturulmamış:

| Sistem | Motor durumu | Veri durumu | Sonuç |
|---|---|---|---|
| **Infection Markers** (BG fraksiyon kuralı #1) | ✅ Kusursuz (8/8 madde) | Yalnız **2 melee silah** taşıyor; compendium'daki 4 menzilli enfeksiyon silahı + Parasite Grenades **yok** | Enfeksiyon yalnız 1" mesafede yayılabiliyor; rakip uzak durarak faksiyonun ana kuralını devre dışı bırakabiliyor |
| **Annihilator / Six-Armed Monstrosity** | ✅ Doğru (her silahla 1 saldırı, Off-Hand yok) | Amalgam ve Desecrated Saint'e **tek silah** verilmiş | İki 140-ducat'lık birim tek saldırı yapıyor |
| **`heavy_only` (Brazen Bull kısıtı)** | ✅ `loadout_resolver.gd` | Taşınabilecek `[Heavy]` silah **yok** | Kısıt anlamsız |
| **`negate_heavy_effect`** (NA Battlefield Demolition, Shocktrooper Assault Drill) | ✅ `mechanics_resolver.gd:433` | Satchel Charge ve HEAVY melee silahlar **yok** | İki yetenek de no-op |
| **`[Sniper]`** (`AttackData.is_sniper`) | ✅ Motor destekli | Hiçbir silahta açık değil; Sniper Rifle `.tres`'i **yok** | Sniper Priest 10" menzilli bir tüfekle savaşıyor |

---

### 🟠 S-5 — Mayın sistemi hiç yok: iki faksiyonun uzman birimi sakat

`set_mine` ve `defuse_mine` `.tres` dosyaları mevcut ama `AbilityExecutor.CUSTOM_IMPLEMENTED` listesinde **yok** → `execute()` erkenden iptal ediyor, buton bile üretilmiyor. `[Mined]` / `negate_mined` kodda hiç okunmuyor. "Detonating Mines" kuralı hiç yok.

| Birim | Cost | Etkilenen yetenek sayısı |
|---|---|---|
| **Iron Sultanate — Sultanate Sapper** | 50 | **6 unsurdan 4'ü ölü** (Set Mine, Defuse Mine, Detonating Mines, `[Negate Mined]`) + Forward Positions da uygulanmamış + menzilli silahı (Alaybozan) yok → **6 unsurdan 5'i** |
| New Antioch — Combat Engineer | 80 | 4 yetenekten 2'si ölü |

**Iron Sultanate için özellikle ağır:** Compendium, bu faksiyonun savaş doktrinini altı sütun hâlinde açıkça yazar — *"a battlefield **littered with traps set by the skilled Sappers**"* bunlardan biridir. Topçu sütunuyla birlikte (Flame Cannon/M.U.R.A.D yok) **altı sütundan ikisi oyunda hiç yok**.

---

### 🟠 S-6 — Variant Warband sistemi yok (17 variant)

| Faksiyon | Variant sayısı | Notlar |
|---|---|---|
| New Antioch | 6 | Papal States, Éire Rangers, Stoßtruppen, Alba, Abyssinia, Red Brigade — **"çokuluslu koalisyon" temasının tek mekanik ifadesi** |
| Trench Pilgrims | 3 | Compendium'daki TP birim görsellerinin **neredeyse tamamı** `procession-of-the-sacred-affliction` etiketli → bu variant, faksiyonun *varsayılan* görsel kimliği |
| Heretic Legion | 3 | Trench Ghosts özellikle: Priest/Commando/Chorister/Trooper'ın tematik varyantı |
| Iron Sultanate | 3 | Fidai of Alamut, House of Wisdom, Defenders of the Iron Wall — altı doktrin sütunundan üçünü derinleştirir |
| Cult of the Black Grail | 2 | Dirge of the Great Hegemon, The Great Hunger |
| **Court** | **0** | Compendium'da Court'un Variant'ı **yoktur** — oyunda da yok ✔ **doğru** |

**Toplam 17 variant, hiçbiri yok.** Bu, tam bir roster-builder gerektiren büyük bir kapsam; kısa vadede Codex/lore ekranında tanıtılmaları bile tematik kaybı azaltır.

---

### 🟠 S-7 — Roster inşa kuralları: 3'te 1 uygulanmış

Compendium'da üç faksiyonun "warband kurulurken bir karar ver" kuralı vardır:

| Kural | Faksiyon | Durum |
|---|---|---|
| **Seven Deadly Sins** | Court | ✅ Seçim UI'ı var (`sin_selection_overlay.gd`), `selected_sin` yazılıyor, 7 aura da etki ediyor, Wrath kısıtı uygulanmış |
| **The Order of the Fly** | Cult of the Black Grail | ❌ Hiç yok — `availability_max` ile kabaca "Lord dalı" taklit ediliyor; "Plague Knight liderliğinde 1-3 PK" dalı **ulaşılamaz** |
| **Nobles of the Court** | Court | ⚠ "en fazla 1 Praetor + 1 Sorcerer" ✅; **"en az birini içermek zorunda"** ❌ |

Diğer roster kısıtlarının durumu:

| Kural | Faksiyon | Durum |
|---|---|---|
| Heretic Legionnaire oranı (*Legionnaire ≤ Trooper*) | Heretic Legion | ✅ **Tam doğru** (`mechanics_resolver.gd:499`) |
| Wretched *"outnumbered by DEMONIC"* | Court | ✅ **Tam doğru** ("outnumbered" = kesin çoğunluk olarak yorumlanmış) |
| Trench Mole limiti (2) | New Antioch | ✅ `limit_group` ile |
| Maddening Buzzing (LIMIT 1) | Black Grail | ✅ `max_per_warband = 1` |
| **`[Elite]` maksimum 6** (global kural) | Hepsi | ❌ **Hiç uygulanmamış** |
| **Alignment (Faithful/Fallen)** | Hepsi | ❌ Kavram kodda hiç yok |
| Martyrdom Device (35 , LIMIT 4) | Trench Pilgrims | ❌ **Bedava ve sınırsız** (bkz. S-8) |
| Goetic Power satın alma + slot | Court | ❌ Hepsi bedava |

---

### 🟠 S-8 — Faksiyona özel ekonomik kırılmalar (Glory Point dışında)

| # | Bulgu | Faksiyon | Etki |
|---|---|---|---|
| 1 | **Martyrdom Device bedava ve sınırsız** | Trench Pilgrims | Compendium: 20 + 35 = **55 ducat**, LIMIT 4 → max 4 bombacı. Oyunda: **20 ducat, sınırsız** → 700 bütçeyle **35 canlı bomba**. Faksiyonun maliyet eğrisi çöküyor; "şehitlik kıt ve pahalı bir kaynaktır" teması tersine dönüyor |
| 2 | **Goetic Power'lar bedava** | Court | 3 Hell Knight + Praetor = **55 ducat**lık güç bedavaya geliyor; roster inşasındaki ana karar (hangi büyüler) ortadan kalkıyor |
| 3 | **Broken on the Wheel'in bedeli yok** | Trench Pilgrims | Compendium: bir Pilgrim/Prisoner **kalıcı silinir**. Oyunda `cost_delta = 0` → rasyonel oyuncu her zaman seçer |
| 4 | **Plague Knight'ın zorunlu zırhı yok** | Black Grail | *"It must have a suit of Armour"* — oyunda Armour 0. Faksiyonun **tek zırhlı biriminin** ayırt ediciliği siliniyor |
| 5 | Loadout fiyatları Armoury ile tutarsız | Iron Sultanate, Heretic Legion, Trench Pilgrims | Machine Gun 45 (armoury 50), Greatsword 5 (12), Reinforced Armour 15 + sadece −1 (armoury 40, −2), Shotgun 3 (10), Frag Grenade 7 (TP armoury'sinde **yok**) |

---

### 🟡 S-9 — Uydurulmuş içerik

| İçerik | Nerede | Sorun |
|---|---|---|
| `FACTION_HERETIC_LEGION_RULES` | `en.json` + `heretic_legion.tres` | *"Hellfire pact… Blood Sacrifice: **Gain 1 Faith Point**"* — **HL'nin `## Faction Rules` bölümü yok**; "Faith Point" Trench Crusade'de var olmayan bir kaynak |
| `FACTION_IRON_SULTANATE_RULES` | `en.json` + `iron_sultanate.tres` | *"**Alchemical Armor: All models receive a +1 Armour bonus**… Ranged Focus: Re-roll failed shoot rolls of 1"* — uydurma **ve compendium'un tam tersi** (IS'in tüm birimleri Armour **0**'dır, zayıflığı budur) |
| `FACTION_TRENCH_PILGRIMS_RULES` | `en.json` + `trench_pilgrims.tres` | *"Holy Wrath… Martyrdom: Downed models still count towards **faith generating acts**"* — uydurma |
| `FACTION_DEFAULT_RULES` | `en.json` | *"Shield of Faith: **Spend Faith points** to negate incoming hits"* — uydurma |
| `SIN_PRIDE_AURA` | `en.json` | *"−1 to **Willpower tests**"* — **Willpower testi Trench Crusade'de yoktur**. (Kod bunu doğru şekilde Morale −1 DICE'a çeviriyor; yalnız metin yanlış) |
| Seven Deadly Sins aura içerikleri | `faction_data.gd` | Elimizdeki compendium kopyasında sin listesi **kazınmamış** → 7 auranın hiçbiri doğrulanamıyor. Doğrulanabilir tek sin kuralı (Wrath → Praetor 1 Goetic Power) **uygulanmış ✔** |
| `UnitData.willpower` | `unit_data.gd` | Trench Crusade'de Willpower stat'ı **yok**; motorda hiç okunmuyor (ölü alan) |
| `UnitData.max_health` | `unit_data.gd` | Trench Crusade'de **hit point yok**; motorda yalnız `> 0` hayatta/ölü bayrağı olarak kullanılıyor. Birim kartlarında anlamlı görünen ama etkisiz sayılar (Lieutenant 12 vs Yeoman 10) |
| Uydurma silah varlıkları | `assets/data/attacks/` | `crusader_rifle` (10" — compendium'daki en kısa uzun silah 18"), `heretic_rifle` (10"), `templar_pistol` (6" — Pistol 8"), `nun_crossbow` (TP armoury'sinde arbalet yok), `rot_grenade` (BG'de yok), `alchemist_pistol` (10") |
| Yetim varlıklar | `assets/data/attacks/` | `atonement_bell.tres`, `holy_water_grenade.tres` — **hiçbir birim kullanmıyor** |
| Uydurma kısıt | `infernal_bomb.tres` | `is_cumbersome = true` — compendium'da Infernal Bomb'da `[Cumbersome]` **yok**. Artillery Witch'i Dash yapamaz hâle getiriyor, oysa lore *"stalk the battlefields... supporting lightning assaults"* diyor |

---

## 5. Faksiyon Bazında En Kritik Bulgular

### New Antioch — 6.4/10
Roster ve statlar kusursuz (15/15 birim). Fireteam + Concentrated Attack gerçekten uygulanmış.
- 🔴 **MHI'nin menzilli silahı yok** — rolü tersine dönmüş
- 🔴 **Sniper Priest 10" menzilli tüfek taşıyor**; Sniper Rifle `.tres`'i yok. Aim + Absolute Faith'in tüm anlamı uzun menzil
- 🔴 **Fireteam eşleştirmesi mercenary'leri kapsıyor** — compendium'un ismen yasakladığı şey
- 🟠 Treat'in Blood Marker seçeneği yok + `is_risky = false` (compendium Risky)
- 🟠 Hold Your Fire!'a uydurma 12" menzil konmuş, LoS kontrolü yok

### Heretic Legion — 7.1/10
Projenin en iyi uygulanmış fraksiyonu. Sin Eater (tüm alt maddeleriyle), Goetic Portal (düşman sürükleme dahil), Infernal Bomb (Scatter/Infernal Strike/Mighty Explosion), Heretic Legionnaire oran kuralı — hepsi RAW seviyesinde.
- 🔴 **Anointed Heavy Infantry ağır silahsız** ve üstelik `templar_pistol` taşıyor
- 🔴 **Gövde tüfeği 10"** (`heretic_rifle`); `bolt_action_rifle` (24") zaten mevcut ama kullanılmıyor
- 🟠 Infernal Bomb'a uydurma `[Cumbersome]`; `[Ignore Elevated Position]` ve "Duck" kuralı eksik
- 🟠 War Wolf'un `[Negate Difficult Terrain]`'i hiç okunmuyor — lore'unun tek mekanik ifadesi

### Trench Pilgrims — 6.3/10
Whip of God, Broken on the Wheel, Martyrdom Device (4D6 + 1" bonusu) birebir doğru.
- 🔴 **Martyrdom Device bedava ve sınırsız** — faksiyonun ekonomisini ve temasını birlikte bozuyor
- 🔴 **Observer mercenary'si rosterde yok** — `observer.tres` mevcut, tek satırlık eksik
- 🟠 **Loudspeakers'ın "hücum sayılır" maddesi yok** — imza hamlenin tek payoff'u
- 🟠 Broken on the Wheel'in feda bedeli yok
- 🟠 Stigmatic Nun'ın silah kısıtı ihlal ediliyor (`nun_crossbow`)

### Iron Sultanate — 6.4/10
Temporal Assassin, Time Slip, Skirmisher, Counter-Charge, Impervious-benzeri teknik kurallar doğru. Jezzail 18" birebir.
- 🔴 **Sapper'ın 6 unsurundan 5'i ölü** (mayın sistemi + Forward Positions + Alaybozan)
- 🔴 **Brazen Bull'un topçusu yok** (Flame Cannon, M.U.R.A.D Bombard)
- 🟠 Mastery of the Elements'te oyuncu seçimi yok (her zaman `fire`) → `[Negate Fire]` ağırlıklı rakiplere karşı ilk tur zorunlu harcanıyor
- 🟠 Lion of Jabir'e **yanlış yetenek kartı** gösteriliyor (`abiotic_life` ≠ `artificial_life`)
- **Compendium doktrin paragrafındaki 6 sütundan 2'si (topçu, tuzaklar) oyunda hiç yok**

### Cult of the Black Grail — 6.9/10
**Infection Markers sistemi projenin en iyi kodlanmış mekaniği** — 8/8 alt madde. Fly Thrall'ın Undead Fortitude'unun *olmaması* gibi ince detaylar bile doğru.
- 🔴 **Menzilli enfeksiyon silahı yok** — motor hazır, mühimmat yok
- 🔴 **Amalgam altı kollu ama tek hançeri var**
- 🔴 **Order of the Fly hiç uygulanmamış** — faksiyonun iki arketipinden biri ulaşılamaz
- 🟠 Plague Knight'ın zorunlu zırhı yok
- 🟠 Knight of the Rotten Cross yok (oyunun tek çapraz-armoury kuralı)

### Court of the Seven-Headed Serpent — 7.4/10
**En yüksek skor.** Goetic Powers — compendium'un en karmaşık kaynak sistemi — 8/8 alt maddesiyle eksiksiz. Wrath kısıtı, Wretched'ın "outnumbered by Demonic" kuralı, `[Impervious]` zırh kuralı hepsi doğru. Variant'ı olmayan tek faksiyon olması da doğru yansıtılmış.
- 🔴 **Goetic Power'lar bedava ve slot sistemi yok** — roster inşasındaki ana karar yok
- 🔴 **Desecrated Saint tek silahlı** (compendium: 3 melee silah)
- 🔴 Nobles of the Court zorunluluğu denetlenmiyor
- 🟠 Court armoury'sinin **hiçbiri yok**; birimler **üç farklı faksiyonun** silahlarını taşıyor
- 🟠 Sin auraları kaynakta doğrulanamıyor; Pride aurası var olmayan "Willpower testi"ne atıf yapıyor

---

## 6. Öncelikli Eylem Listesi

Etki/maliyet oranına göre sıralandı. **1–6 arası neredeyse tamamen `.tres` veri işidir; motor kodu zaten hazır.**

### Kademe 1 — Yüksek etki, düşük maliyet (saf veri)

| # | Eylem | Etkilenen | Neden ilk |
|---|---|---|---|
| 1 | **Menzilli enfeksiyon silahları** (`infested_rifle`, `putrid_shotgun`, `corruption_belcher`, `viscera_cannon`, `parasite_grenades` — hepsi `keywords = {infection_markers: 1}`) | Black Grail | Projenin en iyi sistemi şu an ulaşılamaz durumda; 5 `.tres` dosyası açar |
| 2 | **Ağır silah platformlarına ağır silah** (MHI, Anointed, Brazen Bull, Amalgam, Desecrated Saint) | 5 faksiyon | `machine_gun.tres` zaten doğru; `annihilator` ve `heavy_only` zaten hazır |
| 3 | **`sniper_rifle.tres`** (36", `is_sniper = true`, +1 Injury) → Sniper Priest | New Antioch | `is_sniper` motorda destekli ama hiç kullanılmıyor |
| 4 | **`observer.tres`'i TP rosterine ekle** | Trench Pilgrims | Tek satır; eksik birim |
| 5 | **10" uydurma tüfekleri düzelt** (`crusader_rifle`, `heretic_rifle` → 24") | NA, HL | `bolt_action_rifle.tres` zaten doğru referans |
| 6 | **Martyrdom Device'ı LoadoutOption'a taşı** (`cost_delta = 35`, `max_per_warband = 4`) | Trench Pilgrims | `LoadoutOption` sistemi zaten `max_per_warband` destekliyor |
| 7 | **Lion of Jabir'in `abiotic_life` → `artificial_life`** | Iron Sultanate | Tek satır; yanlış bilgi gösteriliyor |
| 8 | **Infernal Bomb'dan uydurma `[Cumbersome]`'ı kaldır** | Heretic Legion | Tek satır; lore'u geri kazandırır |
| 9 | **Uydurma faction rule metinlerini sil** (HL/IS/TP + `FACTION_DEFAULT_RULES`) | 3 faksiyon | "Faith Point" gibi var olmayan mekaniklere atıf |
| 10 | **`SIN_PRIDE_AURA` metnini düzelt** ("Willpower" → "Morale Check") | Court | Kod zaten doğru davranıyor |

### Kademe 2 — Orta maliyet (küçük kod + veri)

| # | Eylem | Etkilenen |
|---|---|---|
| 11 | **Fireteam eşleştirmesini `[New Antioch]` keyword'üyle filtrele** + Concentrated Attack'ta saldıranı doğrula | New Antioch (kural ihlali) |
| 12 | **Treat'e `remove_blood` seçeneği + `is_risky = true` + menzil 1"** | NA, TP (Medi-kit taşıyan herkes) |
| 13 | **Loudspeakers'a "counts as charging" + LoS** | Trench Pilgrims (imza hamle) |
| 14 | **Hold Your Fire!: menzil kaldır, LoS koy** | New Antioch |
| 15 | **`[Elite]` maksimum 6 tavanı** (`DeployValidator`'a yeni ret sebebi) | Hepsi |
| 16 | **Goetic Power'ları LoadoutOption'a taşı** (`cost_delta` 10/15 + slot) | Court |
| 17 | **Order of the Fly + Nobles of the Court** (`selected_sin` deseniyle lider tipi seçimi) | Black Grail, Court |
| 18 | **Mastery of the Elements'e deploy anında oyuncu seçimi** | Iron Sultanate |
| 19 | **Plague Knight'a zorunlu zırh loadout'u** | Black Grail |
| 20 | **Broken on the Wheel'e feda bedeli** | Trench Pilgrims |

### Kademe 3 — Büyük kapsam

| # | Eylem | Etkilenen |
|---|---|---|
| 21 | **Glory Point / ducat ayrımı** (`cost_currency` + ayrı havuz) | **Hepsi** — tek başına en büyük denge düzeltmesi |
| 22 | **Mayın sistemi** (`[Mined]` arazi bayrağı + Set/Defuse/Detonating Mines + `[Negate Mined]` + Forward Positions) | Iron Sultanate Sapper, New Antioch Combat Engineer |
| 23 | **Faksiyona-özgü Armoury kalemleri** — faksiyon başına en az 5–8 imza kalem | Hepsi (~70 kalem) |
| 24 | **Ödünç silahları temizle** (`templar_*`, `crusader_*`, `legionary_*` yanlış faksiyonlarda) | 4 faksiyon |
| 25 | **`willpower` ve `max_health` alanlarını kaldır** (veya UI'dan çıkar) | Hepsi — var olmayan stat gösteriliyor |
| 26 | **Alignment (Faithful/Fallen) sistemi** | Hepsi |
| 27 | **17 Variant Warband** | Court hariç hepsi |

---

## 7. Sonuç

Projenin faksiyon sadakati **6.75/10**. Bu ortalama, birbirinden çok farklı iki gerçeği gizliyor:

- **Veri ve motor katmanı: 9+/10.** 65 birimin stat/keyword doğruluğu neredeyse kusursuz. Infection Markers, Goetic Powers, Fireteam, Temporal Assassin, Sin Eater, Broken on the Wheel, Martyrdom Device, Heretic Legionnaire oranı, Wretched availability kuralı — bunların hepsi RAW seviyesinde doğru uygulanmış. Compendium'da `## Faction Rules` bölümü olan/olmayan faksiyonların 6/6 doğru ayırt edilmiş olması, kaynağın dikkatle okunduğunu gösteriyor.

- **Ekipman ve ekonomi katmanı: 2/10.** Faksiyonların masa oyunundaki kimliği büyük ölçüde **Armoury'de** yaşar: New Antioch'un genişliği, Heretic Legion'un Cehennem metalürjisi, Trench Pilgrims'in antika hurdaları, Iron Sultanate'in kültürel isimlendirmesi, Black Grail'in enfeksiyon dağıtımı, Court'un saray estetiği. Bu katman yokken altı faksiyon, farklı renklere boyanmış aynı iskelet gibi oynanıyor.

**Tek cümlelik teşhis:** Motor Trench Crusade'i doğru oynuyor; eksik olan, faksiyonlara *kendi silahlarını* vermek.

En yüksek getirili müdahale Kademe 1'dir: yaklaşık **15–20 `.tres` dosyası** oluşturmak/düzeltmek, zaten yazılmış ama şu an ulaşılamayan beş sistemi (Infection Markers dağıtımı, Annihilator, `heavy_only`, `negate_heavy_effect`, `[Sniper]`) oyuna geri açar ve altı faksiyonun da oynanış kimliğini gözle görülür biçimde değiştirir.

---

## 8. UYGULAMA SONRASI DURUM (2026-07-28)

> Bu denetimdeki bulgular kademeli bir uygulama turuyla hayata geçirildi.
> Ayrıntılı task-task günlük: `docs/faction_audit/IMPLEMENTATION_LOG.md`.

**Test paketi:** 2118 → **2877 assert**, 0 başarısız, 0 script hatası (13 yeni denetim testi)
**Commit:** 20 (her task tek commit, hepsi test-korumalı)

### Çözülen sistemik bulgular

| # | Bulgu | Durum |
|---|---|---|
| **S-1** | Glory Point / ducat karışımı | ✅ `EconomyRules` + ayrı `player_glory_pool`; mercenary'ler artık ducat ile alınamıyor |
| **S-2** | 5 ağır silah platformunda ağır silah yok | ✅ MHI/Anointed → Machine Gun; Brazen Bull → Flame Cannon + M.U.R.A.D; Amalgam → 4 farklı silah; Desecrated Saint → 3 melee |
| **S-3** | ~70 armoury kaleminin 2'si var | ✅ **38 silah** eklendi; ödünç silahların **tamamı** temizlendi + kalıcı değişmez testi |
| **S-4** | Mekanizma hazır, veri yok | ✅ Infection (Putrid Shotgun), Annihilator, `heavy_only`, `negate_heavy_effect`, `[Sniper]` yolu — hepsi canlandı |
| **S-5** | Mayın sistemi hiç yok | ✅ `MineResolver` + `TerrainManager` + `MineActions`; Sapper'ın 6 unsurunun tamamı çalışıyor |
| **S-7** | Roster inşa kuralları 3'te 1 | ✅ Elite tavanı (6), Order of the Fly, Nobles of the Court — üçü de uygulandı |
| **S-8** | Faksiyona özel ekonomik kırılmalar | ✅ Martyrdom Device 35 /LIMIT 4; Goetic Power'lar satın alınır; Plague Knight zorunlu zırh; Broken on the Wheel bedeli |
| **S-9** | Uydurulmuş içerik | ✅ 4 uydurma faksiyon kuralı metni, 12 uydurma silah varlığı, `willpower`/`max_health` alanları silindi |
| **S-6** | 17 Variant Warband | ⏸️ Kapsam dışı (ayrı proje — roster-builder gerektiriyor) |

### Ek kazanım: Mayın ve Siper mekaniği

Kullanıcının sağladığı `mine_model.glb` / `trench_model.glb` modelleriyle **yeni bir arazi
alt sistemi** kuruldu:
- `TerrainFeatureData` / `TerrainPlacement` (veri-güdümlü; yeni arazi tipi script gerektirmez)
- `TerrainManager` (autoload — sahadaki kayıt ve sorgular)
- `TerrainFeature` (3B görsel — GLB + etki yarıçapı halkası)
- Siperler 6 senaryonun tamamında No Man's Land bandına yerleştirildi ve gerçek `[Cover]` veriyor

### Faksiyon skorları — sonra

| Faksiyon | Önce | Sonra (tahmini) | Ana kazanım |
|---|---|---|---|
| Court of the Seven-Headed Serpent | 7.4 | **8.7** | Goetic satın alma, Nobles of the Court, kendi armoury silahları |
| Heretic Legion | 7.1 | **8.5** | Anointed'e Machine Gun, 24" tüfek, Infernal Bomb düzeltmesi |
| Cult of the Black Grail | 6.9 | **8.4** | Menzilli enfeksiyon, Amalgam'ın 4 silahı, Order of the Fly |
| New Antioch | 6.4 | **8.3** | MHI'ye Machine Gun, Sniper Rifle 48", Fireteam merc filtresi, mayınlar |
| Iron Sultanate | 6.4 | **8.2** | Sapper'ın mayınları + Forward Positions, Bull'un topçusu, Mastery seçimi |
| Trench Pilgrims | 6.3 | **8.0** | Martyrdom Device ekonomisi, Observer, Loudspeakers hücumu |

*Not: bu skorlar uygulanan düzeltmelere göre tahminidir; bağımsız bir yeniden denetim yapılmadı.*
