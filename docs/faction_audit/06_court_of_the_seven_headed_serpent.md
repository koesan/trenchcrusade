# Faction Sadakat Denetimi — 06: Court of the Seven-Headed Serpent

**Kaynak:** `trench_compendium/warbands/court-of-the-seven-headed-serpent.md` (1102 satır)
**Oyun tarafı:** `assets/data/factions/court_of_seven_headed_serpent.tres`, 11 birim `.tres`, `faction_data.gd` (SEVEN_DEADLY_SINS), `faction_rules.gd`, `ability_executor.gd`, `mechanics_resolver.gd`, `unit_actions.gd`, `turn_manager.gd`, `sin_selection_overlay.gd`
**Denetim tarihi:** 2026-07-28

---

## 1. Kaynak Materyaldeki Tasarım ve Amaç

### 1.1 Lore ve Tema
Court of the Seven-Headed Serpent, Cehennem'in **Savaş Konseyi**dir — Gazap, Haset, Şehvet, Kibir, Tembellik, Oburluk ve Açgözlülük'ü temsil eden yedi Yılan Başı.

Tematik çekirdek üç sütun:

1. **İstikrarsız hiyerarşi.** *"even the mightiest of devils rarely hold their seat on the great War Council for long."* Yoke Fiend işçi çeteleri Yılan Başlarının heykellerini diker, sonra yeni bir iblis lordu iktidara tırmanınca aynı heykeller yıkılır. Konsey **çoğunluk oyuyla** işler ve en ince farkla karar alır.
2. **Güç = ölümlü takipçi sayısı.** *"the strength of a demon waxes and wanes with the number of mortal followers they can corrupt."* Bu, fraksiyonun **Wretched** biriminin varlık sebebidir: ölümlüler hem şok birliği hem **Goetic büyünün yakıtı**dır.
3. **Goetia — kan bedelli büyü.** Court, Trench Crusade'in **tek gerçek büyü fraksiyonu**dur. Büyüler zar atışıyla değil, **acıyla** ödenir.

Dikkat: Beelzebub (Oburluk) Konsey'deki hakkını *küçümser* ve savaşını kendi Kara Kase'siyle yürütür — bu yüzden Açlık Tahtı boştur ve küçük düşmüş melekler o ödül için kapışır. Bu, Court ile Black Grail'in **kardeş ama rakip** konumunu açıklar (ve ikisinin Morale kuralında birbirini muaf tutmasını).

### 1.2 Faction Rules — compendium'daki İKİ resmî pasif

#### (1) Nobles of the Court
> Warband'ınız kurulurken lider olarak **bir Praetor VEYA bir Sorcerer içermek zorundadır**. Praetor'u lider seçerseniz warband'a **en fazla 1 Sorcerer** ekleyebilirsiniz; tersi de geçerlidir.

#### (2) Goetic Powers
> `[Elite]` modeller Goetic Power'lara sahip olabilir. **Sayısı her modelin Warband Entry'sinde yazar.** Goetic Power'lar ikiye ayrılır: **Goetic Abilities** ve **Goetic Spells**.
>
> Goetic Spells için:
> - Büyünün **Blood Marker cinsinden bir maliyeti** vardır (başlıkta parantez içinde).
> - **Bir model aynı büyüyü aktivasyon başına birden fazla kez casteemez.**
> - Maliyeti ödemek için **sahadaki herhangi bir modelden** (dost ya da düşman) Blood Marker kaldırılır — **ancak `[Black Grail]` veya `[Demonic]` keyword'ü olanlardan alınamaz.** Modeller sahanın herhangi bir yerinde olabilir, **Line of Sight gerekmez**, maliyet birden fazla modelden bölünerek ödenebilir.
> - Maliyet bir **aralıksa** (örn. 1-3), cast etmeden ÖNCE ne kadar ödeyeceğini seçersin.
> - Bazı büyüler **Cast Spell `[Action]`** gerektirir; bu aksiyon aktivasyonda birden fazla kez kullanılabilir (aynı büyü tekrarlanmadıkça).
> - **Büyü için Success Roll ATILMAZ.**

Tasarım amacı — bu, oyundaki en özgün kaynak sistemidir:
- **Zar yok, dolayısıyla başarısızlık yok.** Court'un büyüleri *kesin* etki eder. Diğer fraksiyonların Risky Success'e bağlı yetenekleri kumar, Court'unki muhasebedir.
- **Yakıt düşmandan da alınabilir.** Rakibin üzerindeki Blood Marker'lar Court için bir *kaynak havuzudur*. Yani rakip yaralandıkça Court güçlenir — ve rakip, kendi Blood Marker'larını temizlemek için baskı altındadır.
- **Demonic/Black Grail'den alınamaz.** Court'un kendi çekirdek birimlerinin çoğu `[Demonic]`'tir; yani fraksiyon **kendi kanını yakamaz**. Bu, ölümlü Wretched'ları (`[The Court]` ama `[Demonic]` değil) stratejik bir kaynak hâline getirir — ve lore ile birebir örtüşür: *"used as subjects of torture to power the Goetic magic of the sorcerers."*
- **Oyunun başında büyü yapılamaz.** Sahada hiç Blood Marker yokken hiçbir Goetic Spell castedilemez. Court, *önce kan dökmek* zorundadır.

#### Seven Deadly Sins
> *"Many of the warriors of the Court have access to a selection of devastating Spells and other Powers... Depending on the type of model and **which Deadly Sin the warband is dedicated to**, the selection available to you may vary."*

Warband kurulurken bir Ölümcül Günah seçilir; bu seçim (a) hangi Goetic Power'lara erişileceğini ve (b) Desecrated Saint'in **Demonic Aura**'sını belirler.

> ⚠️ **Kaynak notu:** Elimizdeki compendium kopyasında Seven Deadly Sins'in **ayrıntılı listesi bulunmuyor.** `## Warband Options` bölümü yalnız *"Seven Deadly Sins — Change"* şeklinde kazınmış (sitedeki açılır widget içeriği alınmamış). Dolayısıyla **yedi aura'nın mekanik içerikleri bu denetimde doğrulanamıyor.** Doğrulanabilen tek sin-özel kural şudur:
>
> **"A Praetor can have up to 2 Goetic Powers. Praetors from a Warband dedicated to Wrath can have only 1 Goetic Power."**

#### Goetic Power kataloğu (compendium'da açıkça verilenler)

| Power | Maliyet (satın alma) | Blood maliyeti | Kim |
|---|---|---|---|
| **Slavemaster** | 10  | (1) | Praetor, Sorcerer, Hell Knight |
| **Burning Inferno** | 15  | (1-3) | Sorcerer, Praetor |
| **Blessings of the Serpent Moon** | **bedava** | (2/4/6) | Sorcerer (otomatik) |
| **Blood Magic** | **bedava** | (1) | Hell Knight (zorunlu, 2 slotundan biri) |
| **Shadow Walker** | — | (2) | Hunter |
| **Left-Hand Path** | — | (2) | Hunter |
| **Oracle Beast Cloak** | — | (3) | Hunter |

**Goetic Power slot sayıları:** Praetor **2** (Wrath'ta **1**), Sorcerer **3** + bedava Blessing, Hell Knight **2** (biri zorunlu Blood Magic).

### 1.3 Oynanış Kimliği (Tabletop Rolü)

- **Oyunun en pahalı rosteri.** Praetor 115, Hunter 110, Hell Knight 100, Desecrated Saint 140, Pit Locust 90. Court, **az sayıda çok güçlü model** oynar.
- **Hava üstünlüğü.** Praetor 8"/Flying, Sorcerer 6"/Flying, Pit Locust 8"/Flying — üç uçan birim.
- **`[Negate Fire]` her yerde.** Çekirdek birimlerin **tamamı** ateşe bağışıktır (Wretched hariç). Cult of the Black Grail'in tam tersi bir dayanıklılık profili.
- **Kesin etkili büyü.** Zar atmadan çalışan yetenekler: Slavemaster (18" içindeki Yoke Fiend'e komut), Burning Inferno (36" Blast, yarıçap = ödenen marker), Blood Magic (+1 Injury Dice), Oracle Beast Cloak (Injury Roll'u No Effect'e çevir).
- **Ölümlü yakıt döngüsü.** Wretched (20 ) → Goetic yakıt + *Law of Hell* ile Elite avlarsa özgürlük. Yoke Fiend (30 , Unlimited) → *Hateful* ile zorunlu hücum eden, *Torturer* ile kendi dostunu döven, Slavemaster ile uzaktan komuta edilen köle.
- **Yoke Fiend'in çelişkisi.** *Hateful*, Yoke Fiend'i her aktivasyonda en yakın (Demonic/Black Grail olmayan) düşmana hücuma **zorlar**. Bu bir güç değil, bir **kontrol kaybıdır**; Slavemaster ve Restraining Muzzle bu kaybı yönetmek için vardır.

### 1.4 Fraksiyona Özgü Mekanikler

| Birim | Mekanik | Tasarım amacı |
|---|---|---|
| Praetor | 8"/Flying, **+3D/+3D**, Goetic Power ×2 (Wrath'ta 1) | Oyunun en yüksek zar profilli lideri |
| Sorcerer | Goetic Power ×3 + bedava **Blessings of the Serpent Moon** (2/4/6 → her 2 marker için −1 Injury Modifier) | Saf büyücü; Ranged Weapon/Grenade alamaz |
| Hell Knight | **Infernal Iron Armour** (−2 + **`[Impervious]`**: Ignore Armour'a karşı bile geçerli), **Blood Magic** (+1 Injury Dice, Blast'ta her modele) | Delinemez zırh + hasar çarpanı |
| Hunter of the Left-Hand Path | **Shadow Walker** (2: retreat'te melee yenmez), **Left-Hand Path** (2: arazi→arazi ışınlanma, hareket ortasında), **Oracle Beast Cloak** (3: Injury Roll → No Effect, tur başına 1), **Bow of Lethe** (24", Assault, Special Ammunition) | Yakalanamaz nişancı |
| Desecrated Saint | **Demonic Aura** (seçilen günaha göre), **Annihilator** (her melee silahıyla 1 Fight, Off-Hand cezası yok), −3 Armour, +3D melee, `[Ignore Off-hand Weapon]` | Üç kollu aura taşıyıcısı |
| Pit Locust | **Poison Stingers** (silahsız `[Cleave 2]` + `[Shrapnel]`), 8"/Flying, −2 | Uçan kanat vurucusu |
| Wretched | **Law of Hell**; **Availability: `[Demonic]` modellerce sayıca aşılmalı** | Goetic yakıt + feda |
| Yoke Fiend | **Hateful** (zorunlu hücum), **Torturer** (dostuna vurabilir, sonra aktivasyon biter) | Kontrol edilemez köle |

### 1.5 Mercenaries
Goetic Warlock (4 ), Scripture Guardian (7 ), Sin Eater (6 ).

### 1.6 Armoury

| Kalem | Fiyat | Kısıt |
|---|---|---|
| **Malebranche Sword** | 50  | LIMIT 1 |
| **Hellblade** | 15  | LIMIT 3 |
| **Head Taker** | 15  | LIMIT 2 |
| **Torture Instrument** | 8  | — |
| **Ophidian Rifle** | 25  | LIMIT 3, Elite only |
| **Serpent Assault Gun** | 50  | LIMIT 2 |
| **Arquebus** | 8  | — |
| **Crown of Hellfire** | 15  | **Elite, Pit Locust only** |
| **Restraining Muzzle** | 10  | LIMIT 3, **Yoke Fiend only** |
| Heavy Flamethrower / Flamethrower | 55 (L1) / 30 (L2) | — |
| Unholy Relic / Unholy Trinket | 15  / 15  | — |
| Incendiary Ammunition | 15  | LIMIT 1 |
| Shovel | 5  | **Yoke Fiend, Wretched only** |

### 1.7 Variant Warband'lar
**Yoktur.** Court, compendium'da `## Variants` bölümü bulunmayan **tek fraksiyondur** (Armoury'den doğrudan Promotions'a geçer).

### 1.8 Güçlü / Zayıf Yönler
| Güçlü | Zayıf |
|---|---|
| Zar atmadan çalışan, kesin etkili büyüler | Büyüler sahada Blood Marker yoksa çalışmaz (tur 1 ölü) |
| Rakibin yaraları Court'un yakıtı | Kendi Demonic birimlerinden yakıt alınamaz |
| Praetor +3D/+3D, Desecrated Saint +3D | Roster çok pahalı → az model → Morale kırılganlığı |
| Hell Knight `[Impervious]`: Ignore Armour bile delemez | Praetor/Sorcerer/Hunter/Saint hepsi Armour 0 veya düşük |
| Üç uçan birim | Yoke Fiend *Hateful* ile kontrol dışı hücum eder |
| Her birim `[Negate Fire]` | Wretched sayısı Demonic sayısıyla sınırlı |

---

## 2. Oyundaki Uygulama

### 2.1 Roster Karşılaştırması

| Compendium | Cost | Avail | Oyunda | Durum |
|---|---|---|---|---|
| Praetor (Captain) | 115 | 0-1 | ✅ 115 / 1 | ✔ |
| Sorcerer (Captain) | 75 | 0-1 | ✅ 75 / 1 | ✔ |
| Hell Knight (Elite) | 100 | 0-3 | ✅ 100 / 3 | ✔ |
| Hunter of the Left-Hand Path (Elite) | 110 | 0-1 | ✅ 110 / 1 | ✔ |
| Desecrated Saint | 140 | 0-1 | ✅ 140 / 1 | ✔ |
| Pit Locust | 90 | 0-3 | ✅ 90 / 3 | ✔ |
| Wretched | 20 | `[Demonic]`'ce aşılmalı | ✅ 20, **kural uygulanmış** | ✔ |
| Yoke Fiend | 30 | Unlimited | ✅ 30 / 999 | ✔ |
| *Merc:* Goetic Warlock | 4  | 0-1 | ✅ 4 / 1 | ⚠ birim para |
| *Merc:* Scripture Guardian | 7  | 0-1 | ✅ 7 / 1 | ⚠ birim para |
| *Merc:* Sin Eater | 6  | 0-1 | ✅ 6 / 1 | ⚠ birim para |

**11/11 birim mevcut.**

### 2.2 Stat ve Keyword Doğruluğu

```
Praetor          8"F | +3D | +3D |  0  [Negate Fire][Fear][Strong][Negate Heavy][Tough][Leader][Flying][Elite][Demonic][The Court] ✔ (10/10 keyword)
Sorcerer         6"F | +1D | +1D |  0  [Negate Fire][Fear][Flying][Elite][Demonic][The Court]  ✔
Hell Knight      6"  |  0D | +2D | -2  [Negate Fire][Strong][Negate Heavy][Elite][Demonic][The Court] + Impervious ✔
Hunter of LHP    6"  | +2D | +1D |  0  [Negate Fire][Infiltrator][Elite][Demonic][The Court]   ✔
Desecrated Saint 6"  |  0D | +3D | -3  [Negate Fire][Fear][Strong][Negate Heavy][Tough][Demonic][The Court][Ignore Off-hand] ✔
Pit Locust       8"F |  0D | +2D | -2  [Negate Fire][Fear][Flying][Demonic][The Court]         ✔
Wretched         6"  | -1D | -1D |  0  [The Court]                                              ✔
Yoke Fiend       6"  |  0D | +1D |  0  [Negate Fire][Demonic][The Court]                        ✔
```

**Sıfır sapma.** Praetor'un 10 keyword'ünün tamamı doğru girilmiş.

### 2.3 Doğru Uygulanmış Mekanikler

**Goetic Powers sistemi — compendium'daki en karmaşık kaynak sistemi, neredeyse eksiksiz:**

| Compendium maddesi | Oyunda | Nerede |
|---|---|---|
| *"you do not have to take a Success Roll in order to cast a spell"* | ✔ | `requires_roll = false` |
| *"remove Blood Markers from any models (friend or foe)"* | ✔ | `CombatChoice.request_blood_drain` — harita üzerinde tıklayarak seçim |
| *"that do not have the `[Black Grail]` or `[Demonic]` Keywords"* | ✔ | `MechanicsResolver.is_goetic_blood_source()` |
| *"anywhere on the battlefield, do not have to be in Line of Sight"* | ✔ | Menzil/LoS kontrolü yok |
| *"the spell cost can be paid by removing markers from more than one model"* | ✔ | `sources` bir Dictionary (model → miktar) |
| *"If the cost is a range, you must choose how many before the spell is cast"* | ✔ | `pay_goetic_cost(min_cost, max_cost)` |
| *"A model cannot cast the same spell more than once per Activation"* | ✔ | `unit.goetic_spells_cast_this_activation` |
| *"You can use the Cast Spell Action more than once per Activation"* | ✔ | Aksiyon başına ayrı `action_key` |
| Reaktif büyüler (*"cast before an Injury Roll / before Retreat"*) | ✔ | `try_cast_reactive_goetic()` + onay diyaloğu |
| **Wrath: Praetor yalnız 1 Goetic Power** | ✔ | `unit_actions.gd:116-124` — Wrath seçiliyse Burning Inferno butonu üretilmiyor |
| Sahada yeterli Blood yoksa kilitlenme önlemi | ✔ | `total_available_goetic_blood()` ön-kontrolü — buton hiç üretilmiyor |

**Diğer mekanikler:**

| Mekanik | Nerede | Not |
|---|---|---|
| **Seven Deadly Sins seçim UI'ı** | `sin_selection_overlay.gd`, `game_hud.gd:608` | 7 günah seçilebiliyor, `FactionData.selected_sin`'e yazılıyor ✔ |
| **Demonic Aura (7 günah)** | `mechanics_resolver.is_in_demonic_aura()` | Yedisi de **gerçekten etki ediyor**: Lust→charge yasağı (`unit_actions.gd:108`), Wrath→melee −1D (`dice_pool_builder.gd:146`), Pride→Morale −1D (`turn_manager.gd:540`), Envy→dost yetenek hedefi olamama (`ability_executor.gd:99,200`), Gluttony→iyileştirilememe (`ability_executor.gd:282,306`), Sloth→hareket yarılanması (`unit.gd:638,896,1021`), Greed→retreat cezası |
| **Slavemaster** | `CUSTOM_IMPLEMENTED` + `ability_executor._handle_slavemaster` | 18", 4 komut (Move/Shoot/Fight/Sacrifice); hedef doğrulaması `hateful` keyword'ü ile (yalnız Yoke Fiend) ✔ |
| **Burning Inferno** | `CUSTOM_IMPLEMENTED` + `burning_inferno_attack.tres` | 36", Blast yarıçapı = **ödenen Blood Marker sayısı**, Scatter (7−roll), Ignore Armour ✔ — değişken yarıçap dahil |
| **Blood Magic** | `blood_magic` keyword | +1 Injury Dice, Blast'ta her modele ✔ |
| **Blessings of the Serpent Moon** | `blessings_of_serpent_moon` keyword + reaktif akış | 2/4/6 → her 2 marker için −1 Injury Modifier ✔ |
| **Shadow Walker** | `shadow_step.tres` (`ability_id = &"shadow_walker"`) + `CUSTOM_IMPLEMENTED` | Retreat'te melee yenmeme ✔ |
| **Left-Hand Path** | `left_hand_path.tres` | Arazi→arazi ışınlanma ✔ |
| **Oracle Beast Cloak** | `oracle_beast_cloak.tres` | Injury Roll → No Effect ✔ |
| **Impervious (Infernal Iron Armour)** | `impervious: 1` | Ignore Armour'a karşı bile −2 ✔ — **compendium'un en teknik zırh kuralı, doğru** |
| **Annihilator (mekanik)** | `annihilator: 1` + `ignore_offhand_weapon` | Her silahla ayrı Fight, Off-Hand cezası yok ✔ (silah yok, bkz. P0-CT-2) |
| **Law of Hell** | `mechanics_resolver.law_of_hell_triggers` | Elite öldüren Wretched sahadan çekilir ✔ |
| **Wretched Availability kuralı** | `game.gd:594-608` + `court_wretched_deploy_allowed()` | *"Must be outnumbered by models with the Keyword DEMONIC"* — **"outnumbered" = kesin çoğunluk** olarak doğru yorumlanmış (eşitlik yetmiyor) ✔ |
| **Hateful** | `hateful` keyword + `unit.gd` | 12" LoS içindeki, Demonic/Black Grail olmayan en yakın düşmana zorunlu hücum ✔ |
| **Torturer** | `torturer` keyword | Dosta melee, sonra aktivasyon biter ✔ |
| **Bow of Lethe** | `bow_of_lethe.tres` | 24", `[Assault]`, `special_ammunition` (+2 Injury Dice **veya** Ignore Armour seçimi) ✔ |
| **Poison Stingers** | `poison_stingers.tres` | `[Cleave 2]` + `[Shrapnel]` ✔ |
| **Variant yokluğu** | — | Compendium'da Court'un Variant'ı **yok**; oyunda da yok — **doğru** ✔ |

**Değerlendirme:** Goetic Powers, projedeki **en iyi uygulanmış fraksiyon kuralıdır**. Compendium'un 8 alt maddesinin tamamı doğru; üstelik "sahada Blood yoksa büyü butonu üretme" gibi RAW'da olmayan ama RAW'ı oynanabilir kılan bir UX kararı eklenmiş.

---

## 3. Tespit Edilen Sorunlar

### 🔴 P0-CT-1 — Goetic Power'lar bedava ve slot sistemi yok

**Bulgu:** Goetic Power'lar birimlere sabit `abilities[]` olarak gömülmüş:

| Birim | Oyunda verilen | Compendium |
|---|---|---|
| Praetor | `slavemaster` + `burning_inferno` — **ikisi de bedava** | **2 slot**, satın alınır: Slavemaster 10  + Burning Inferno 15  = **25 ** |
| Sorcerer | `blessing_of_the_serpent_moon` + `burning_inferno` + `slavemaster` — **üçü de bedava** | 3 slot; Blessing **bedava ✔**, diğer ikisi **25 ** |
| Hell Knight | `blood_magic` + `slavemaster` — **ikisi de bedava** | 2 slot; Blood Magic **zorunlu ve bedava ✔**, Slavemaster **10 ** |

**Neden sorun:**

1. **Fraksiyonun ikinci resmî kuralının ekonomik yarısı yok.** Compendium *"which can be **purchased at the indicated cost** when the model is initially purchased"* der. Oyunda hiçbir maliyet ödenmiyor: bir Court warband'ı, 3 Hell Knight × 10  + Praetor 25  = **55 ducat**lık Goetic Power'ı bedavaya alıyor.
2. **Seçim kararı yok.** Compendium'da slot sayısı sınırlıdır (Praetor 2, Sorcerer 3, Hell Knight 2 — biri zorunlu). Yani Court oyuncusunun **roster inşasındaki ana kararı** "hangi büyüleri alacağım"dır. Oyunda herkes her şeyi alıyor; karar ortadan kalkıyor.
3. **Wrath kısıtı yalnız yarı anlamlı hâle geliyor.** Oyun Wrath'ta Praetor'un Burning Inferno'sunu doğru şekilde engelliyor ✔ — ama compendium'da bu, "2 slot yerine 1 slot" demektir; oyuncu hangi tek gücü alacağını *seçer*. Oyunda seçim yok, sabit olarak Slavemaster kalıyor.

**Olması gereken:** Goetic Power'lar `LoadoutOption` olarak modellenmeli (`cost_delta = 10/15`, `max_per_warband` yerine birim-başı slot sayısı). Motor tarafı (`CUSTOM_IMPLEMENTED`, blood cost) zaten hazır; bu **tamamen roster/veri katmanı işi**.

---

### 🔴 P0-CT-2 — Desecrated Saint çok kollu ama tek silahı var (ve o silah Black Grail'e ait)

**Bulgu:** `court_desecrated_saint.tres` → `attacks = [plague_sword.tres]`, `keywords = { annihilator: 1, ignore_offhand_weapon: 1, ... }`

**Compendium:**
> *"A Desecrated Saint **has several arms**. It can have **up to three 1-Handed Melee Weapons** from The Court's Armoury Tables **or two 1-Handed Melee Weapons and one 2-Handed Melee Weapon**. It cannot have any other Battlekit."*
> **Annihilator:** *"A Desecrated Saint can take **1 Fight `[Action]` per Activation with each Melee Weapon** it is equipped with. The Off-hand Weapon modifier does not apply."*

**Neden sorun:**
- **140 ducat** — fraksiyonun en pahalı birimi. Melee +3D ve Armour −3 ile zaten güçlü; ama ödediğin bedelin bir kısmı **üç ayrı Fight aksiyonu**dur. Tek silahla bu, tek saldırıya düşüyor.
- Oyunda `annihilator` mekaniği **doğru şekilde hazır** (Amalgam ile aynı kod yolu) — silah verilmediği için atıl.
- Verilen silah `plague_sword.tres` **Cult of the Black Grail'in** silahıdır ve `is_poison = true` taşır. Court armoury'sinde Hellblade (15 , LIMIT 3), Head Taker (15 , LIMIT 2), Torture Instrument (8 ), Malebranche Sword (50 , LIMIT 1) gibi tam olarak bu iş için var olan **dört 1-El melee silahı** bulunuyor — hiçbiri oyunda yok.
- Bu, Cult of the Black Grail'in Amalgam'ıyla (P0-BG-1) **birebir aynı hatadır**: `annihilator` taşıyan iki birim de tek silahla bırakılmış.

---

### 🔴 P0-CT-3 — "Nobles of the Court" zorunluluğu denetlenmiyor

**Bulgu:** `court_praetor.tres` ve `court_auxilia_sorceror.tres` ikisinde de `is_leader = true`, `availability_max = 1`. Kodda Court'a özel bir roster doğrulaması yok (`FactionRules.gd` yorumu bunu *"Nobles of the Court roster-kısıtı **kısmen** — Praetor is_leader"* diye kabul ediyor).

**Compendium:** *"Your warband **must include** a Praetor **OR** a Sorcerer as your leader when it is created."*

**Durum:**
- ✔ *"up to one Sorcerer... and vice versa"* — `availability_max = 1` ile doğru karşılanmış.
- ❌ *"must include"* — **zorunluluk hiç denetlenmiyor.** Oyuncu ne Praetor ne Sorcerer alarak sahaya çıkabilir; Court, compendium'da imkânsız olan "lidersiz" bir hâle gelebiliyor.

**Neden önemli:** Court'un tüm Goetic sistemi liderden başlar (Praetor/Sorcerer, Goetic Power sayısı en yüksek modellerdir). Lidersiz bir Court, Slavemaster'sız kalır → Yoke Fiend'ler *Hateful* yüzünden kontrolsüz hücum eden bir sürüye dönüşür. Yani zorunluluk, fraksiyonun iç tutarlılığını koruyan bir emniyet supabıdır.

Bu, Black Grail'in **Order of the Fly** eksikliğiyle (P0-BG-3) aynı ailedendir: iki fraksiyonun da "warband kurulurken lider tipini seç" kuralı uygulanmamış.

---

### 🔴 P0-CT-4 — Mercenary ekonomisi (fraksiyon-üstü; bkz. P0-NA-3)

Goetic Warlock 4 + Scripture Guardian 7 + Sin Eater 6 = **17 puan**. Court'un en ucuz modeli Wretched 20 . Üç mercenary'nin tamamı bir Wretched'dan ucuz.

**Court'a özel şiddeti:** Goetic Warlock ve Sin Eater **`[Demonic]`**'tir → *Goetic büyü için kan kaynağı olamazlar*, ama aynı zamanda `court_wretched_deploy_allowed()` sayımında **Demonic sayısını artırırlar**. Yani 10 puanlık iki mercenary, ücretsiz olarak iki ek Wretched slotu açıyor. Compendium'da bu ikisi kampanya ödülüdür ve ilk kadroda bulunamazlar.

---

### 🟠 P1-CT-5 — Seven Deadly Sins aura içerikleri kaynakta doğrulanamıyor; Pride aurası var olmayan bir mekaniğe atıf yapıyor

**Bulgu:** `FactionData.SEVEN_DEADLY_SINS` yedi aura tanımlıyor ve **yedisi de kodda gerçekten uygulanmış** (§2.3). Ancak:

**(a) Kaynak doğrulanamıyor.** Elimizdeki compendium kopyasında `## Warband Options` bölümü yalnız *"Seven Deadly Sins — Change"* olarak kazınmış; sin listesinin içeriği yok. Yedi auranın hiçbiri bu belgeyle karşılaştırılamıyor.

**(b) Pride aurası var olmayan bir stat'a atıf yapıyor.**
```
SIN_PRIDE_AURA = "Enemy models within 3\" suffer -1 to Willpower tests."
```
**Trench Crusade'de "Willpower testi" diye bir mekanik yoktur.** Moral, warband seviyesinde Morale Check ile işler. Kodun kendisi bunu doğru şekilde Morale Check'e −1 DICE olarak çevirmiş (`turn_manager.gd:543`) — yani **mekanik makul, metin yanlış**. Oyuncuya oyunda bulunmayan bir sistem tarif ediliyor. (Aynı hayalet, `UnitData.willpower` ölü alanında da var — bkz. P2-NA-14.)

**(c) Doğrulanabilir tek sin kuralı uygulanmış ✔.** Compendium'un metin olarak verdiği tek sin-özel kural — *"Praetors from a Warband dedicated to Wrath can have only 1 Goetic Power"* — oyunda doğru uygulanmış. Bu, sin sisteminin **genel iskeletinin doğru kurulduğunu** gösteriyor; sorun yalnız aura içeriklerinin kaynaksız olması.

**Olması gereken:** Resmî sin listesi (trench-companion.com'daki açılır bölüm) elde edilene kadar auralar **"proje yorumu"** olarak işaretlenmeli; Pride'ın metni "Morale Check'lere −1 DICE" şeklinde düzeltilmeli.

---

### 🟠 P1-CT-6 — Court'un armoury'si hiç yok; birimler **üç farklı fraksiyonun** silahlarını taşıyor

**Compendium Court armoury'sinin oyunda karşılığı olan kalem sayısı: 0.**

| Kalem | Fiyat | Kısıt | Oyunda |
|---|---|---|---|
| Malebranche Sword | 50  | LIMIT 1 | ❌ |
| Hellblade | 15  | LIMIT 3 | ❌ |
| Head Taker | 15  | LIMIT 2 | ❌ |
| Torture Instrument | 8  | — | ❌ |
| Ophidian Rifle | 25  | LIMIT 3, Elite only | ❌ |
| Serpent Assault Gun | 50  | LIMIT 2 | ❌ |
| Arquebus | 8  | — | ❌ |
| **Crown of Hellfire** | 15  | **Elite, Pit Locust only** | ❌ |
| **Restraining Muzzle** | 10  | LIMIT 3, **Yoke Fiend only** | ❌ |
| Heavy Flamethrower / Flamethrower | 55  / 30  | L1 / L2 | ❌ |
| Unholy Relic / Unholy Trinket | 15  / 15  | — | ❌ |
| Incendiary Ammunition | 15  | LIMIT 1 | ❌ |

**Yerine kullanılan silahlar ve gerçek sahipleri:**

| Court birimi | Oyundaki silah | Gerçek fraksiyon |
|---|---|---|
| Hell Knight | `templar_hammer` | **New Antioch** ("Templar") |
| Yoke Fiend | `templar_hammer` + `heavy_pistol` | **New Antioch** |
| Sorcerer | `legionary_dagger` | **Heretic Legion** |
| Wretched | `legionary_dagger` | **Heretic Legion** |
| Desecrated Saint | `plague_sword` | **Cult of the Black Grail** |
| Praetor | `court_praetor_sword` | ✔ Court'a özgü (uydurma ama tematik) |
| Hunter | `bow_of_lethe` | ✔ **compendium'a birebir** |
| Pit Locust | `poison_stingers` | ✔ compendium'a uygun |

**Neden bu en ağır tematik bulgu:** Cehennem'in Savaş Konseyi'nin şövalyesi **"Tapınakçı Çekici"** taşıyor. Bu, sadece bir isim hatası değil — Templar, Trench Crusade'de *Sadık taraf* terminolojisidir ve Court, oyunun en saf Cehennem fraksiyonudur (her birim `[Demonic]` ve `[Negate Fire]`). Üç farklı fraksiyondan ödünç alınmış silahlarla Court'un görsel/tematik dili tamamen dağılmış.

**İki kayıp özellikle mekanik sonuç doğuruyor:**
- **Restraining Muzzle (10 , LIMIT 3, Yoke Fiend only)** — Yoke Fiend'in *Hateful* zorunlu-hücum kuralını yönetmek için tasarlanmış kalem. Onsuz Yoke Fiend'ler her tur kontrolsüz hücum eder ve oyuncunun tek çaresi Slavemaster olur.
- **Crown of Hellfire (15 , Pit Locust only)** — Pit Locust'un alabileceği **tek** battlekit. Onsuz Pit Locust hiç özelleştirilemiyor.

---

### 🟡 P2-CT-7 — Küçük sapmalar

| # | Bulgu | Compendium | Oyun |
|---|---|---|---|
| a | `poison_stingers` `is_poison = true` | Yalnız `[Cleave 2]` + `[Shrapnel]` — `[Gas]` **yok** | `is_poison = true` eklenmiş. `[Negate Gas]` taşıyan hedeflere karşı davranış compendium'dan sapıyor |
| b | Birim adı | **Hunter of the Left-Hand Path** (tireli) | `"Hunter of the Left Hand Path"` |
| c | Dosya/birim adı | Compendium'da birim yalnız **"Sorcerer"** | `court_auxilia_sorceror.tres` — "Auxilia" compendium'da geçmiyor (`unit_name = "Sorcerer"` ✔ doğru) |
| d | Sorcerer Battlekit kısıtı | *"apart from **Ranged Weapons and Grenades**"* | Modellenmemiş (şu an zaten ranged'i yok — pratikte sorun değil, Armoury gelince gerekli) |
| e | Hunter Battlekit kısıtı | *"apart from **2-Handed Weapons**"* | Modellenmemiş |
| f | Yoke Fiend Battlekit kısıtı | *"1 Ranged Weapon that has a cost of **30  or less**"* | Modellenmemiş (`heavy_pistol` verilmiş) |
| g | Wretched Battlekit kısıtı | *"costs up to **10 **... must have at least 1 Weapon"* | Modellenmemiş |
| h | Praetor sabit silahı | Praetor'un **sabit battlekit'i yoktur** (*"any Battlekit from The Court's Armoury"*) | `court_praetor_sword` zorla verilmiş |
| i | Pit Locust yetenek kartı | **Poison Stingers** bir Ability olarak listelenir | `abilities[]` **boş**; yalnız attack olarak var → oyuncu birim panelinde yeteneği görmüyor |
| j | `FACTION_COURT_OF_SEVEN_HEADED_SERPENT_RULES` | Nobles of the Court + Goetic Powers | **Compendium'a sadık** ✔ — ama tarif ettiği "Nobles of the Court" kuralı kodda yok (P0-CT-3) |
| k | `FACTION_COURT_OF_SEVEN_HEADED_SERPENT_STORY` | Konsey/yedi baş/istikrarsız hiyerarşi teması | Oyun metni kısa ve *"auxilia sorcerors, desecrated saints, and Gehenna demons"* diyor. "Auxilia sorceror" ve "Gehenna demons" compendium'da geçmiyor; asıl tema (Konsey siyaseti, güç = ölümlü takipçi sayısı) hiç anılmıyor |
| l | Variant yokluğu | Court'un Variant'ı **yok** | Oyunda da yok — **doğru** ✔ |

---

## 4. Özet Skor — Court of the Seven-Headed Serpent

| Eksen | Skor | Gerekçe |
|---|---|---|
| **Roster kompozisyonu** | 10/10 | 11/11 birim |
| **Stat sadakati** | 10/10 | Sıfır sapma; Praetor'un 10 keyword'ü dahil |
| **Keyword sadakati** | 10/10 | `[Impervious]` gibi teknik kurallar dahil doğru |
| **Fraksiyon pasifi** | 7/10 | **Goetic Powers mekaniği kusursuz** (8/8 alt madde); Nobles of the Court zorunluluğu yok; Goetic satın alma ekonomisi yok |
| **Birim yetenekleri** | 9/10 | Slavemaster, Burning Inferno (değişken yarıçap!), Oracle Beast Cloak, Left-Hand Path, Impervious, Hateful, Torturer, Law of Hell — hepsi doğru |
| **Ekipman / Armoury** | 1/10 | 13 kalemin **hiçbiri** yok; birimler **üç farklı fraksiyonun** silahlarını taşıyor; Desecrated Saint tek silahlı |
| **Ekonomi** | 2/10 | Glory Point ↔ ducat **+** Goetic Power'ların bedava olması (fraksiyona özel ikinci kırılma) |
| **Lore / tema** | 4/10 | Konsey siyaseti teması lore metninde yok; Hell Knight "Templar Çekici" taşıyor; sin auraları kaynaksız |
| **Oynanış kimliği** | 8/10 | Kan-bedelli büyü döngüsü **tam çalışıyor** — fraksiyonun asıl tezi oyunda hissediliyor; Desecrated Saint ve Goetic seçim ekonomisi eksik |

**Genel: 7.4 / 10** — **Denetlenen altı fraksiyon içindeki en yüksek skor.**

**Bu fraksiyonun karakteristik durumu:** Court, en zor mekaniği (zar atmadan çalışan, düşmanın yaralarından beslenen, Demonic olmayan modellerden ödenen büyü ekonomisi) **eksiksiz uygulanmış** tek fraksiyon. Oyuncu, Court oynarken compendium'daki fraksiyonu gerçekten hissediyor. Kayıplar tamamen (a) satın alma ekonomisi ve (b) ekipman/tema katmanında.

### Öncelik sırası
1. **P0-CT-1** Goetic Power'ları `LoadoutOption`'a taşı (`cost_delta` 10/15 + slot sayısı). Motor hazır — saf veri işi
2. **P0-CT-2** Desecrated Saint'e 3 melee silah (`annihilator` zaten hazır) + `plague_sword`'ü Court silahıyla değiştir
3. **P0-CT-3** Nobles of the Court zorunluluğu (Black Grail'in Order of the Fly'ıyla aynı altyapı)
4. **P0-CT-4** Glory Point / ducat ayrımı (fraksiyon-üstü)
5. **P1-CT-6** Court armoury'si — öncelik: Hellblade, Head Taker, Torture Instrument, Malebranche Sword (Desecrated Saint'i de çözer), Restraining Muzzle, Crown of Hellfire; `templar_hammer`/`legionary_dagger`/`plague_sword`'ü kaldır
6. **P1-CT-5** `SIN_PRIDE_AURA` metnini düzelt ("Willpower" → "Morale Check"); auraları "proje yorumu" olarak işaretle
7. **P2-CT-7a/i** `poison_stingers`'tan `is_poison`'ı kaldır; Pit Locust'a Poison Stingers ability kartı ekle
