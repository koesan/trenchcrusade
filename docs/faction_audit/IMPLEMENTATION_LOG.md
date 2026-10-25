# Faksiyon Sadakat Uygulama Günlüğü

**Denetim:** `docs/faction_audit/00_NIHAI_RAPOR.md`
**Başlangıç branch'i:** `compendium-alignment-p0-p1`
**Test baseline (başlangıç):** 2118 assert / 0 başarısız

Her task tamamlandığında bu tabloya bir satır eklenir. Sütunlar:
- **Bulgu:** Denetim raporundaki madde kimliği
- **Test:** Task sonrası tam paket sonucu (`godot --headless res://tests/test_main.tscn`)

---

## İlerleme

| # | Task | Bulgu | Değişen / eklenen | Test | Commit |
|---|---|---|---|---|---|
| 0 | Lokalizasyon eşitlik testi + günlük | Global Constraint | `tests/cases/localization_parity_test.gd` (yeni), bu dosya (yeni) | 2124 / 0 | `test: lokalizasyon anahtar eşitliği testi + uygulama günlüğü` |
| 1 | Uydurma faksiyon kuralı metinlerini sil | **S-9** | `heretic_legion.tres`, `iron_sultanate.tres`, `trench_pilgrims.tres`, `tr.json`, `en.json`, `faction_data_integrity_test.gd`, `faction_rule_text_test.gd` (yeni) | 2136 / 0 | `fix(data): compendium'da karşılığı olmayan uydurma faksiyon kuralı metinlerini sil` |
| 2 | Compendium Armoury silahları | **S-3, P0-BG-2** | 38 yeni `assets/data/attacks/*.tres`, `dice_pool_builder.gd`, `tr.json`+`en.json` (+76 anahtar ×2), `armoury_fidelity_test.gd` (yeni) | 2425 / 0 | `data(armoury): battlekit'ten 38 silah eklendi + silah düzeyi Injury Modifier` |
| 3 | Ağır silah platformlarına ağır silah | **S-2**, P0-NA-1, P0-HL-1, P0-IS-2, P0-BG-1, P0-CT-2 | 5 birim `.tres`, `stigmatic_nun.tres`, `court_yoke_fiend.tres`, 2 yeni melee pistol `.tres`, `weapon_keyword_test.gd`, `heavy_platform_test.gd` (yeni), lokalizasyon | 2463 / 0 | `fix(data): beş ağır silah platformu birimine compendium ağır silahları verildi` |
| 4 | Uydurma menzilleri compendium değerlerine çek | **P0-NA-2, P0-HL-2, P2-NA-13, P1-IS-4b** | 12 varlık silindi, 5 menzil düzeltildi, 11 birim `.tres`, lokalizasyon (−24 anahtar), `weapon_range_fidelity_test.gd` (yeni) | 2486 / 0 | `fix(data): uydurma silah menzilleri compendium değerlerine çekildi` |
| 5 | Roster üyelikleri ve yanlış yetenek kartları | **P0-TP-2, P1-IS-6, P2-CT-7i, P1-HL-4a** | `trench_pilgrims.tres`, `lions_of_jabir.tres`, `court_pit_locust.tres`, `infernal_bomb.tres`, `poison_stingers.tres` (attack+yeni ability), `dice_pool_builder.gd`, `maintenance_pass_p0_test.gd`, `roster_membership_test.gd` (yeni) | 2526 / 0 | `fix(data): Observer TP rosterine geri eklendi; yanlış yetenek kartları ve uydurma keywordler düzeltildi` |
| 6 | Glory Point / ducat ayrımı | **S-1** (fraksiyon-üstü) | `economy_rules.gd` (yeni), `unit_data.gd`, `scenario_data.gd`, `game_state.gd`, `game.gd`, `deploy_validator.gd`, `scenario_manager.gd`, 10 mercenary `.tres`, `content_audit_fixes_test.gd`, `glory_economy_test.gd` (yeni), lokalizasyon | 2593 / 0 | `feat(economy): Glory Point ve ducat ayrı havuzlara ayrıldı` |
| 7 | Warband inşa kuralları | **P1-NA-9, P0-BG-3, P0-CT-3** | `roster_rules.gd` (yeni), `faction_data.gd`, `deploy_validator.gd`, `game.gd`, `plague_knight.tres`, `roster_rules_test.gd` (yeni), lokalizasyon (+11×2) | 2636 / 0 | `feat(roster): Elite tavanı, Order of the Fly ve Nobles of the Court uygulandı` |
| 8 | Order of the Fly seçim ekranı | **P0-BG-3** | `faction_choice_overlay.{gd,tscn}` (genelleştirildi), `game_hud.gd`, `demonic_aura_test.gd` | 2644 / 0 | `feat(ui): faksiyon kurulum seçimi genel bileşene taşındı (Sins + Order of the Fly)` |
| 9 | Faksiyona özel ekonomik kırılmalar | **S-8** (P0-TP-1, P0-CT-1, P1-BG-5, P1-TP-5) | `loadout_option.gd`, `loadout_resolver.gd`, `ecclesiastic_prisoner`, `court_praetor`, `court_auxilia_sorceror`, `court_hell_knight`, `plague_knight`, `shrine_anchorite`, `yuzbasi`, `janissary`, `heretic_priest`, `ability_integrity_test.gd`, `missing_armoury_weapons_test.gd`, lokalizasyon | 2644 / 0 | `fix(economy): Martyrdom Device ve Goetic Powerlar satın alınır oldu` |

---

## Notlar

### Task 0
`tr.json` ve `en.json` denetim anında **zaten tam eşitti** (her iki dosyada da aynı anahtar kümesi,
boş değer yok). Bu yüzden düzeltme gerekmedi; test yalnız mevcut durumu kilitliyor ve sonraki
tasklarda eklenecek her yeni anahtarın iki dile de girmesini zorunlu kılıyor.

Baseline 2118 → 2124 (+6 assert): yeni testin 6 assert'i.

### Task 1
Silinen 4 uydurma lokalizasyon anahtarı ve neden uydurma oldukları:

| Anahtar | Uydurma içerik | Neden yanlış |
|---|---|---|
| `FACTION_HERETIC_LEGION_RULES` | *"Blood Sacrifice: Gain 1 **Faith Point**"* | Heretic Legion'un compendium'da `## Faction Rules` bölümü **yok**; "Faith Point" Trench Crusade'de var olmayan bir kaynak |
| `FACTION_IRON_SULTANATE_RULES` | *"Alchemical Armor: **All models receive a +1 Armour bonus**"* | Compendium'un **tam tersi** — Iron Sultanate'in 8 çekirdek biriminin tamamı Armour **0**'dır, faksiyonun zayıflığı budur |
| `FACTION_TRENCH_PILGRIMS_RULES` | *"Martyrdom: ...**faith generating acts**"* | Yine var olmayan "faith" kaynağına atıf |
| `FACTION_DEFAULT_RULES` | *"Shield of Faith: **Spend Faith points**"* | Aynı hayalet mekanik |

**Yan bulgu:** Mevcut `faction_data_integrity_test.gd` **hatalı değişmezi kilitliyordu** —
"her faksiyonun `faction_rule_summary`'si dolu olmalı" diye assert ediyordu, yani uydurma
metinlerin varlığını *zorunlu* kılıyordu. Test, `has_faction_rule` bayrağına göre dallanacak
şekilde düzeltildi: bayrak açıksa dolu, kapalıysa **boş** olmalı.

Kodda hiçbir yerde bu anahtarlara fallback referansı yoktu (`blessings_overlay.gd:39`'daki
tek eşleşme bir yorum satırıydı) — UI değişikliği gerekmedi.

Test: 2124 → 2136 (+12 assert), 0 başarısız.

### Task 2

**Önemli kaynak keşfi:** `trench_compendium/battlekit/{ranged,melee,grenade,armour,shield,equipment,special}.md`
dosyaları silahların **resmî stat bloklarını** içeriyor. Warband dosyalarındaki Armoury tabloları
yalnız *fiyat* veriyor. Denetim raporu yazılırken bu dizin kullanılmamıştı; bu task'ta tüm
değerler oradan **birebir** alındı.

**Denetim raporundaki iki tahminin düzeltilmesi:**

| Rapor tahmini | Gerçek battlekit verisi |
|---|---|
| `01_new_antioch.md`: Sniper Rifle "≈36\", `is_sniper=true`, +1 Injury" | **48"**, `[+1 Dice]` `[Critical]` `[Risky]` + Bull's Eye (kritikte Ignore Armour). `[Sniper]` diye bir compendium keyword'ü **yoktur** — motordaki `is_sniper` aslında `[Ignore Long Range]`in eş anlamlısıdır |
| `05_cult_of_the_black_grail.md`: "dört menzilli enfeksiyon silahı" (Corruption Belcher, Infested Rifle, Putrid Shotgun, Viscera Cannon + Parasite Grenades) | `[Infection Marker]`i **doğrudan** taşıyan tek menzilli silah **Putrid Shotgun**'dır. Viscera Cannon bunu *Self Sacrifice* özel kuralıyla yapar; Corruption Belcher `[Gas]`, Infested Rifle `[Armour Piercing]`, Parasite Grenades *Terrifying Hallucinations* taşır. Melee tarafta Plague Blade ve Beelzebub's Axe doğrudan enfeksiyon basar |

**Eklenen 38 silah:** 19 ranged, 4 grenade, 15 melee.
Enfeksiyon dağıtımı artık melee'ye hapis değil — Putrid Shotgun (12", `[Infection Marker]`) ile
Cult of the Black Grail'in 1 numaralı fraksiyon kuralı menzilden de tetiklenebiliyor.

**Motor eklemesi (3 satır):** `dice_pool_builder.compute_injury_flat()` artık **silah düzeyi**
`[+N Injury Modifier]` keyword'ünü okuyor. Compendium bunu `[+N Injury Dice]`'tan ayırır
(biri zar *sayısını*, diğeri zar *toplamına* eklenen flat değeri değiştirir). Great Hammer/Maul
`[+1 Injury Modifier]` ve Sacrificial Blade `[+2 Injury Modifier]` bu destek olmadan
compendium'daki hâllerini temsil edemezdi.

**Yeni koruma:** `armoury_fidelity_test.gd`, `assets/data/attacks/` altındaki **her** silahın
`attack_name` ve `description` alanlarının geçerli birer lokalizasyon anahtarı olduğunu denetliyor.
Mevcut 78 silahın tamamı bu denetimi ilk seferde geçti.

Test: 2136 → 2425 (+289 assert), 0 başarısız.

### Task 3

Beş faksiyonu birden vuran **S-2** bulgusu çözüldü. `[Strong]` + `[Negate Heavy]` çiftinin
tek işlevi ağır silah taşımaktır; beş birimde de keyword'ler doğruydu ama taşıyacak silah yoktu.

| Birim | Önce | Sonra | Kaynak |
|---|---|---|---|
| Mechanized Heavy Infantry (NA) | `templar_hammer` (MELEE, uydurma) | **`machine_gun`** (36", Heavy) + `sword_axe` | NA Armoury: Machine Gun 50  |
| Anointed Heavy Infantry (HL) | `anointed_greatsword` + `templar_pistol` ×2 | **`machine_gun`** + `anointed_greatsword` | HL Armoury: Machine Gun 50  (LIMIT 1) |
| Brazen Bull (IS) | `titan_zulfiqar` (tek) | `titan_zulfiqar` + **iki topçu loadout'u**: Flame Cannon (90 ) ve M.U.R.A.D Bombard (80 ), her biri LIMIT 1 | IS Armoury: "Brazen Bull only" kalemleri |
| Amalgam (BG) | `legionary_dagger` ×3 (**aynı silahın 3 kopyası**) | **4 FARKLI silah**: `machine_gun` + `great_hammer_maul` + `putrid_shotgun` + `sword_axe` | BG Armoury: Machine Gun "Amalgam only" |
| Desecrated Saint (Court) | `plague_sword` (Black Grail silahı!) | `head_taker` + `sword_axe` + **`malebranche_sword`** | Compendium: "two 1-Handed + one 2-Handed Melee Weapon" |

**Denetim raporundaki bir ifadenin düzeltilmesi:** `05_cult_of_the_black_grail.md` Amalgam için
"tek bir hançer" diyordu. Gerçekte `attacks` dizisinde **aynı hançerin üç kopyası** vardı —
`annihilator` her silahla ayrı saldırı verdiği için üç saldırı yapılıyordu, ama compendium
*"a vast combination of **different** Ranged and Melee Weapons"* der. Test artık **farklı**
silah sayısını denetliyor (Amalgam ≥4, Desecrated Saint ≥3).

**Desecrated Saint'e `fixed_weapon_loadout` eklendi:** compendium *"has several arms"* der ve
üç melee silah verir; bu, standart "1×2H veya 2×1H" el limitinin açık istisnasıdır. `loadout_resolver.gd`
bu istisnayı zaten Amalgam ve War Wolf için tanıyordu (aynı sınıf: oyuncunun seçtiği Battlekit
değil, sabit stat-blok).

**Testin yakaladığı iki ek mevcut hata:** Yeni eklenen *genel* değişmez ("RANGED pistol taşıyan
her birimin MELEE pistol eşi olmalı") elle tutulan listenin kaçırdığı iki bozuk birimi buldu:
- `court_yoke_fiend` → `heavy_pistol` vardı, melee eşi yoktu (eklendi)
- `stigmatic_nun` → `nun_crossbow` (compendium'da olmayan uydurma bir silah) melee eşsizdi.
  **Task 4'ten öne çekilerek** compendium'un izin verdiği `automatic_pistol` + melee eşiyle
  değiştirildi (compendium: *"The only Ranged Weapons they can have are Automatic Pistols and Pistols"*)

`weapon_keyword_test.gd`'deki elle tutulan liste, Anointed Heavy Infantry'yi **zorunlu** tabancalı
sayıyordu — yani uydurma `templar_pistol`'ün varlığını kilitliyordu. Değişmez koşullu hâle
getirildi ve genel süpürmeyle güçlendirildi (yeni birimler otomatik kapsanıyor).

Test: 2425 → 2463 (+38 assert), 0 başarısız.

### Task 4

**Menzil düzeltmeleri** (kaynak: `battlekit/ranged.md` — compendium'da **her tabanca 12"**dir):

| Silah | Önce | Sonra |
|---|---|---|
| `prophet_pistol` (+melee) | 6" | **12"** |
| `medic_pistol` (+melee) | 10" | **12"** |
| `yuzbasi_pistol` (+melee) | 10" | **12"** |
| `silenced_pistol` | 10" | **12"** + `[Silent]` özel kuralı eklendi |
| `anti_materiel_rifle` | 1 El | **2 El** (compendium: *"2 Hands (Ranged)"*) |

**Silinen 12 uydurma varlık** ve yerlerine geçen compendium karşılıkları:

| Uydurma | Gerçek karşılığı | Etkilenen birimler |
|---|---|---|
| `crusader_rifle` (10", 1H) | `sniper_rifle` (48") / `bolt_action_rifle` (24") | Sniper Priest / Combat Engineer |
| `heretic_rifle` (10", 1H) | `bolt_action_rifle` (24") | Heretic Trooper, Chorister, Priest |
| `templar_pistol` (+melee, 6") | `pistol` (+melee, 12") | Lieutenant |
| `alchemist_pistol` (+melee, 10") | `pistol` (+melee, 12") | Jabirean Alchemist |
| `heavy_pistol` (+melee, 6") — compendium'da **"Heavy Pistol" diye bir kalem yok** | `pistol` (+melee, 12") | Mamluk Faris, Yoke Fiend, Castigator |
| `nun_crossbow` | (Task 3'te `automatic_pistol` ile değiştirildi) | — |
| `rot_grenade` | `parasite_grenades` (BG Armoury) | Plague Knight |
| `atonement_bell`, `holy_water_grenade` | — (hiçbir birim kullanmıyordu) | — |

**Sniper Priest artık gerçekten keskin nişancı:** 10"lik uydurma tüfek yerine **48"** Sniper Rifle.
*Aim* (+2D ranged) ve *Absolute Faith* (rakip Blood Marker ile −DICE basamaz) yeteneklerinin tek
anlamı uzun menzilli atıştır; eski hâlinde birim 30 ducat'lık Yeoman'ın (24") yarısı menzille
savaşıyordu.

**Yeni genel değişmezler** (`weapon_range_fidelity_test.gd`): `[Pistol]` keyword'lü hiçbir silah
12"den kısa olamaz; 2-El menzilli hiçbir silah 8"den kısa olamaz. Bu iki kural, gelecekte
uydurma menzilli silah eklenmesini engelliyor.

**Ayrıca:** silinen silahların 24 yetim lokalizasyon anahtarı da temizlendi (önce hiçbir
`.tres`/`.gd`/`.tscn` dosyasında kullanılmadıkları doğrulandı).

**Süreç notu:** Bu task sırasında test paketi bir süre "asıldı" sandım; sebep önceki bir
`cd trench_compendium` komutunun kalıcı olması ve Godot'un yanlış dizinden çalıştırılmasıydı.
Bundan sonra tüm test çağrıları `--path /home/koesan/Müzik/Trenchcrusade` ile mutlak dizin
belirterek yapılıyor.

Test: 2463 → 2486 (+23 assert), 0 başarısız.

### Task 5

| Bulgu | Düzeltme |
|---|---|
| **P0-TP-2** | `observer.tres` Trench Pilgrims roster'ına eklendi |
| **P1-IS-6** | Lion of Jabir: `abiotic_life` → **`artificial_life`** (yanlış yetenek kartı gösteriliyordu) |
| **P2-CT-7i** | Pit Locust'a `poison_stingers` ability kartı eklendi (yetenek yalnız attack olarak vardı, panelde görünmüyordu) |
| **P1-HL-4a** | Infernal Bomb'dan uydurma `[Cumbersome]` kaldırıldı + `[Ignore Elevated Position]` eklendi |
| **P2-CT-7a** | Poison Stingers'tan uydurma `[Gas]` kaldırıldı (compendium yalnız `[Cleave 2]` + `[Shrapnel]` verir) |

**Motor eklemesi (4 satır):** `dice_pool_builder._success_entries()` artık
`[Ignore Elevated Position]` okuyor — havan/topçu tipi silahlar yüksekten atış avantajından
(`MOD_ELEVATED +1`) yararlanmıyor.

**Önceki bir kararın geri alınması — P0-2 (2026-07-18 bakım turu):**
`maintenance_pass_p0_test.gd`, Observer'ın Trench Pilgrims roster'ından çıkarılmış olmasını
kilitliyordu. Test'in açıklamasında **hiçbir compendium gerekçesi yoktu**. Kaynak doğrulandı:

```
trench_compendium/warbands/trench-pilgrims.md → "## Mercenaries"
  Observer — Cost: 3 (Glory Point), Availability: 0-1, Movement 8"/Infantry
  Görsel etiketi: procession-of-the-sacred-affliction (bir TP variant'ı)
```

Observer, TP'nin 6 mercenary'sinden biridir. Karar geri alındı, test compendium alıntısıyla
yeniden yazıldı (`_test_watcher_hidden_from_trench_pilgrims` → `_test_observer_available_to_trench_pilgrims`).

Bu, uygulama sırasında **üçüncü kez** karşılaşılan "mevcut test hatalı değişmezi kilitliyor"
durumu (önceki ikisi: Task 1 `faction_data_integrity_test`, Task 3 `weapon_keyword_test`).

**Doğrulama yan faydası:** Yeni `roster_membership_test.gd` altı faksiyonun **tüm** mercenary
listelerini compendium'a karşı denetliyor; Observer dışındaki 20 mercenary üyeliği ilk seferde
doğru çıktı — denetim raporundaki roster analizini bağımsız olarak doğruluyor.

Test: 2486 → 2526 (+40 assert), 0 başarısız.

### Task 6

**S-1 çözüldü — denetimdeki en büyük tek denge sorunu.**

Compendium iki ayrı para birimi tanımlar ve biri diğerinin yerine **geçemez**:
> *"Some models cost **Glory Points ()** instead of ()."*
> *"Mercenaries... **cannot be purchased with ** — the only way to attract their services is
> to perform glorious deeds on the battlefield!"*
> *"Generally, Warbands don't have access to when they are first created."*

Önceki durumda 10 mercenary'nin Glory maliyeti (2–7) doğrudan 700 ducat'lık havuzdan
düşülüyordu; yani **her faksiyonda mercenary kadrosunun tamamı tek bir en ucuz askerin
fiyatına** geliyordu.

**Yeni mimari (god-file yasağına uygun):**

| Katman | Dosya | Sorumluluk |
|---|---|---|
| Kural | **`scripts/rules/economy_rules.gd`** (yeni, stateless) | `is_glory`, `can_afford`, `pay`, `can_afford_any`, `currency_key` |
| Veri | `scripts/data/unit_data.gd` | `enum Currency { DUCAT, GLORY }` + `cost_currency` |
| Veri | `scripts/data/scenario_data.gd` | `glory_budget` (skirmish varsayılanı **0**) |
| Durum | `scripts/game_state/game_state.gd` | `player_glory_pool` — yalnız havuzu **tutar**, karar vermez |
| Akış | `scenes/game/game.gd` | Bütçe kontrolünü `EconomyRules`'a **delege eder** (6 satır) |
| Hata | `scripts/rules/deploy_validator.gd` | `REASON_GLORY` |

**Kritik incelik:** `GameState._has_deploy_budget()` eskiden tek havuza bakıp roster'daki
`min_cost`'u hesaplıyordu. Glory birimleri eklenince bu mantık, ducat'ı biten bir oyuncuyu
2 Glory'lik bir mercenary yüzünden *"hâlâ yerleştirebilir"* sayacak ve **yerleştirme fazı hiç
bitmeyecekti**. Artık `EconomyRules.can_afford_any()` iki havuzu birden gözetiyor.

**İki engel ve çözümleri:**
1. `class_name EconomyRules` Godot'un `global_script_class_cache.cfg`'sinde kayıtlı olmadığı için
   parse hatası verdi ve **autoload zinciri çöktü** (assert 2526 → 1290, ama "0 başarısız"
   göründüğü için sessiz bir kırılmaydı). `godot --headless --editor --quit` ile önbellek
   yenilendi. *Ders: yeni `class_name` eklendiğinde bu adım zorunlu.*
2. `content_audit_fixes_test.gd` silinen `nun_crossbow.tres`'i yüklüyordu. Önceki bir oturum
   crossbow sorununu **dosya adını koruyup** içine Pistol stat'ları yazarak "çözmüştü" (üstelik
   6" menzille — compendium'da her tabanca 12"dir). Test, birimin gerçek silahını denetleyecek
   şekilde yeniden yazıldı.

Test: 2526 → 2593 (+67 assert), 0 başarısız.

### Task 7

Üç warband inşa kuralı uygulandı — hepsi yeni **`scripts/rules/roster_rules.gd`** modülünde
(saf/stateless; `game.gd` yalnız sayım yapıp karar için buraya soruyor, god-file'a dönüşmüyor).

| Kural | Kaynak | Uygulama |
|---|---|---|
| **Maximum Elites (6)** | `recruit-your-warband.md`: *"A Warband can never include more than 6 models with the `[Elite]` Keyword. This limit applies **at all times**."* | Deploy sırasında `RosterRules.elite_cap_ok()`; ret sebebi `DEPLOY_FAIL_ELITE_CAP`. **Tüm faksiyonlar** için geçerli — daha önce hiç uygulanmıyordu |
| **The Order of the Fly** | `cult-of-the-black-grail.md` Faction Rules | `FactionData.leader_choice` (`&"lord"` / `&"knight"`) + `RosterRules.order_of_the_fly_allowed()`. Lord dalı: ≤1 Lord + ≤2 Knight; Knight dalı: ≤3 Knight, Lord **alınamaz**. Plague Knight `availability_max` 2 → **3** (Knight dalının üst sınırı; gerçek sınır dala göre uygulanıyor) |
| **Nobles of the Court** | `court-of-the-seven-headed-serpent.md` Faction Rules | `RosterRules.nobles_of_the_court_satisfied()` — yerleşimi bitirirken Praetor **veya** Sorcerer bulunması zorunlu |

**"Yerleşimi bitir" ön koşulu:** `game.gd::request_finish_deployment` artık
`RosterRules.warband_ready()` çağırıyor. Lidersiz bir Court warband'ı ya da seçtiği dalın
liderini almamış bir Grail warband'ı sahaya çıkamıyor; oyuncuya lokalize bir toast gösteriliyor.

`FactionData.leader_choice`, mevcut `selected_sin` deseninin birebir ikizi olarak eklendi
(`LEADER_CHOICES` sabiti seçim UI'ı ve doğrulama için tek kaynak) — Task 8 bu veriyi kullanacak.

Test: 2593 → 2636 (+43 assert), 0 başarısız.

### Task 8

**P0-BG-3'ün UI ayağı.** Aynı yapıda ikinci bir overlay yazmak yerine mevcut
`sin_selection_overlay` **genelleştirildi**:

`scenes/ui/faction_select/sin_selection_overlay.{gd,tscn}` → **`faction_choice_overlay.{gd,tscn}`**

Artık tek bileşen iki seçimi de sürüyor:

| Faksiyon | Seçim | Sözlük |
|---|---|---|
| Court of the Seven-Headed Serpent | Seven Deadly Sins | `FactionData.SEVEN_DEADLY_SINS` |
| Cult of the Black Grail | The Order of the Fly | `FactionData.LEADER_CHOICES` |

`show_prompt(callback, choices, desc_field, title_key, desc_key)` — sözlük, açıklama alanı ve
başlık anahtarları parametre. `game_hud.gd` tarafında `_FACTION_SETUP_CHOICES` sabiti hangi
faksiyonun hangi seçimi yapacağını tanımlıyor; yeni bir faksiyon-kurulum seçimi eklemek artık
**yalnız bir sözlük girdisi** gerektiriyor, yeni sahne/script değil.

Ayrıca `_confirm_faction_selection()` çıkarıldı — seçimli ve seçimsiz iki yolun ortak sonu
(önceden aynı 6 satır iki kez tekrarlanıyordu).

**Yan bulgu — iki gizli test hatası ortaya çıktı:** `demonic_aura_test.gd` çalışırken
2 `SCRIPT ERROR` üretiyordu ve bunlar Envy aurası doğrulamasını **sessizce etkisiz kılıyordu**:
1. `saint.unit_data.abilities = [demonic_ab]` — `Array[Resource]` tipli alana çıplak `Array`
   ataması ("Invalid assignment of property or key 'abilities'").
2. `_FakeUnit`'te `is_engaged()` yoktu — `AbilityExecutor._validate()` bu çağrıda
   **yarıda kesiliyor** ve `""` döndürüyordu, yani Envy denetimine hiç ulaşılmıyordu.

İkisi de düzeltildi. Test paketi artık **0 SCRIPT ERROR** ile koşuyor ve Envy aurası ilk kez
gerçekten doğrulanıyor.

Test: 2636 → 2644 (+8 assert), 0 başarısız, 2 → **0** script hatası.

### Task 9

**S-8: faksiyona özel ekonomik kırılmalar.** Compendium'da *ücretli ve sayısı sınırlı* olan
yetenekler artık birime gömülü değil, satın alınan birer `LoadoutOption`.

**Motor eklemesi:** `LoadoutOption.extra_abilities: Array[Resource]` +
`LoadoutResolver.resolve_loadout()` birleştirmesi (mevcut `extra_keywords` deseninin ikizi).

| Bulgu | Önce | Sonra |
|---|---|---|
| **P0-TP-1** Martyrdom Device | Her Ecclesiastic Prisoner'da **bedava ve sınırsız** (700 bütçeyle 35 canlı bomba) | `EP_LOADOUT_MARTYRDOM_DEVICE`: **35 , `max_per_warband = 4`**. `awaited` de cihazla birlikte geliyor (compendium: kural yalnız *"when their Martyrdom Device is triggered"* geçerli) |
| **P0-CT-1** Goetic Powers | Praetor/Sorcerer/Hell Knight'a **hepsi bedava** | Praetor: Slavemaster 10 / Burning Inferno 15 / ikisi 25 . Sorcerer: Blessing **bedava** (compendium) + diğerleri ücretli. Hell Knight: Blood Magic **bedava/zorunlu** + Slavemaster 10  |
| **P1-BG-5** Plague Knight zırhı | Armour 0 | Her loadout'ta zırh: Standard 15 /−1 veya Reinforced 40 /−2 (compendium: *"It must have a suit of Armour"*) |
| **P1-TP-5** Broken on the Wheel | `cost_delta` yok (bedava) | **20 ** — feda edilen Ecclesiastic Prisoner'ın bütçe karşılığı |
| **P2-IS-8c** Machine Gun | 45  | **50 ** (IS Armoury) |
| **P2-HL-9a** Shotgun | 3  | **10 ** (HL Armoury) |
| **P2-IS-8d** Greatsword/Axe | 5  | **12 ** (IS Armoury) |

**Kendi hatamı bir test yakaladı:** Denetim raporu P2-IS-8e, Janissary'nin zırh loadout'unu
"Reinforced Armour 40 /−2 olmalı" diye işaretlemişti. `missing_armoury_weapons_test.gd`
bunun **Standard Armour** (15 , −1) olduğunu açıkça belgeliyordu ve Iron Sultanate Armoury'de
Standard Armour gerçekten 15 . Değişiklik geri alındı; **denetim raporundaki P2-IS-8e maddesi
hatalıydı** (Machine Gun ve Greatsword fiyatları ise doğru tespitlerdi).

`ability_integrity_test.gd` yetenekleri yalnız `abilities[]`'de arıyordu; artık
`loadout_options[].extra_abilities`'i de tarıyor (aksi halde satın alınan yetenekler
"orphan" sayılıyordu).

Test: 2644 → 2644 assert, 0 başarısız, 0 script hatası.

### Task 10–19 (özet)

| # | Task | Bulgu | Test |
|---|---|---|---|
| 10 | TerrainFeatureData + model taşıma | S-5 (veri temeli) | 2669 / 0 |
| 11 | MineResolver (saf kurallar) | S-5 | 2692 / 0 |
| 12 | TerrainManager autoload + TerrainFeature sahnesi | S-5 | 2713 / 0 |
| 13 | Set Mine / Defuse Mine / Detonating Mines | **S-5, P0-IS-1, P1-NA-5** | 2739 / 0 |
| 14 | Siper `[Cover]` + Forward Positions | **P0-IS-1** | 2795 / 0 |
| 15 | Treat / Hold Your Fire! / Loudspeakers | **P1-NA-7, P1-NA-8, P1-TP-4** | 2820 / 0 |
| 16 | Fireteam mercenary filtresi | **P0-NA-4** | 2848 / 0 |
| 17 | Negate Difficult Terrain, Ballistic Box Armour, Mastery seçimi | P1-HL-5, P2-NA-15b, P1-IS-4a | 2875 / 0 |
| 18 | Ödünç silahların temizliği | **S-3** | 2877 / 0 |
| 19 | `willpower` / `max_health` kaldırıldı | P2-NA-14, S-9 | 2877 / 0 |

### Task 20 — Nihai doğrulama

**Test paketi:** `2877 assert / 0 başarısız / 0 script hatası` (baseline 2118 → **+759 assert**)
**Test dosyası:** 76 → **89** (13 yeni denetim testi)
**Commit:** 20 (her task tek commit)

**Çalışma zamanı doğrulaması:**
- `godot res://scenes/game/game.tscn` → **0 script hatası**; log'da 5 siperin sahaya yerleştiği görülüyor
- `godot res://scenes/ui/main_menu/main_menu.tscn` → **0 script hatası**

**Headless testlerin yakalamadığı bir hata:** `codex_panel.gd` hâlâ `ud.willpower` okuyordu;
yalnız gerçek oyun açılışında ortaya çıktı. Bu, "her task sonunda testi çalıştır" disiplininin
yanına **"oyunu da gerçekten başlat"** adımının neden gerekli olduğunu gösteriyor.

---

## Kapsam dışı bırakılanlar (bilinçli, gerekçeli)

| Bulgu | Neden ertelendi |
|---|---|
| **17 Variant Warband** (S-6) | Tam roster-builder + 17 ayrı liste gerektirir; ayrı bir proje |
| **Tam Armoury satın alma UI'ı** (S-3) | Bu tur Armoury *kalemlerini* ve loadout fiyatlarını getirdi; serbest satın alma ekranı ayrı bir UI projesi |
| **Alignment (Faithful/Fallen)** (S-7) | Roster üyeliği `available_units` küratörlüğüyle korunuyor; Alignment ancak serbest Mercenary seçimi gelince gerekli olur |
| **Knight of the Rotten Cross** (P1-BG-6) | Çapraz-faksiyon armoury erişimi — yukarıdaki Armoury UI'ına bağımlı |
| **Infernal Bomb "Duck" kuralı** (P1-HL-4c) | Hedef ile patlama noktası arasındaki arazi geometrisi gerektiriyor; `TerrainManager` altyapısı hazır, ayrı bir görev |
| **Seven Deadly Sins aura doğrulaması** (P1-CT-5) | Kaynak eksik — compendium kopyasında sin listesi kazınmamış. Auralar kodda çalışıyor ama içerikleri doğrulanamıyor |

---

## Denetim raporundaki üç hatalı tespit (uygulama sırasında düzeltildi)

Bu tur, denetim raporunun kendisini de test etti. Üç madde yanlış çıktı:

1. **`01_new_antioch.md` — Sniper Rifle "≈36\", `[Sniper]`, +1 Injury"**
   Gerçek: **48"**, `[+1 Dice]` `[Critical]` `[Risky]` + Bull's Eye. `[Sniper]` diye bir
   compendium keyword'ü **yoktur**.
2. **`05_cult_of_the_black_grail.md` — "dört menzilli enfeksiyon silahı"**
   Gerçek: `[Infection Marker]`i doğrudan taşıyan tek menzilli silah **Putrid Shotgun**'dır.
3. **`04_iron_sultanate.md` P2-IS-8e — "Janissary zırhı Reinforced 40 /−2 olmalı"**
   Gerçek: o loadout **Standard Armour**'dur (15 , −1) ve mevcut veri **zaten doğruydu**.
   Mevcut bir test bu hatayı yakaladı ve değişiklik geri alındı.

Ayrıca **dört kez** "mevcut test hatalı bir değişmezi kilitliyordu" durumu yaşandı
(`faction_data_integrity_test`, `weapon_keyword_test`, `maintenance_pass_p0_test`,
`missing_armoury_weapons_test`). Her birinde test, compendium alıntısıyla yeniden yazıldı.

---

# İKİNCİ TUR — Cila, Mimari ve Oyuncu Deneyimi (2026-07-28)

| # | Task | Konu | Test |
|---|---|---|---|
| P2-1 | Siper Fortify/Dug In'den doğuyor | **Kural düzeltmesi** (kendi hatam) | 2868 / 0 |
| P2-2 | `unit.gd` bölünmesi + ölü alanlar + zombi kod | Mimari | 2904 / 0 |
| P2-4 | Taşan panellere kaydırma sözleşmesi | UI | 2920 / 0 |
| P2-5 | Dikey erişim göstergesi yeniden çizimi | UI | 2945 / 0 |
| P2-6 | Arazi kaynaklı `[Cover]` rozeti | UI | 2945 / 0 |
| P2-3 | Ulaşılamayan silahlar bağlandı, ölüler silindi | Zombi kod | **2963 / 0** |

## Öne çıkanlar

**Kendi hatamı düzelttim:** Birinci turda 6 senaryoya 5'er siper otomatik yerleştirmiştim.
Compendium'da böyle bir kural **yok** — siper bir *eylem sonucudur*. Artık `FortifyActions`
üzerinden **Fortify** (Risky Success) ve **Dug In** (Şovel, pasif) sahaya gerçek bir siper
arazi parçası koyuyor; birim mevziyi terk edince siper de kalkıyor
(*"until they move away from their current position"*).

**Zombi kod temizliği:**
- `is_near_enemy_chorister()` iki dosyada tanımlıydı, **hiçbir yerden çağrılmıyordu**
  (Chorister'ın gerçek kuralı `unholy_hymns` keyword'üyle zaten işliyor)
- 5 ölü `UnitData` alanı: `max_health`, `willpower`, `has_blast`, `base_color`, `is_chorister`
- 6 gerçekten ölü silah varlığı (silinmiş birimlere aitti) + 12 yetim lokalizasyon anahtarı
- 26 ulaşılamayan silah, compendium'un izin verdiği birimlere loadout olarak bağlandı

**Mimari:** `unit.gd` 2349 → 2191 satır (çoklu saldırı zincirleri `UnitAttackChains`'e).
Yeni **`architecture_health_test.gd`** bir *çırçır* (ratchet) olarak çalışıyor: dosya boyutu
tavanları, sorumluluk modülleri için 400 satır sınırı, ölü alanların ve zombi fonksiyonun
geri gelmemesi.

**UI:**
- Eylem butonları paneli artık `ScrollContainer` — en fazla **5 buton** görünür, gerisi kaydırma.
  Panel diğer HUD öğelerinin üstüne binmiyor.
- Birim kartı şeridi **tam 4 karta** oturuyor (yarım kart gösterimi kalktı), taşınca yatay
  kaydırma çubuğu görünüyor.
- Dikey erişim göstergesi: iki soluk gri 1-piksellik çizgi yerine **dört ayrı renkli ok**
  (yeşil=serbest çıkış, turuncu=Riskli tırmanış, mavi=serbest iniş, kırmızı=Riskli iniş),
  yükseklik 0.7 → 1.15. Sınıflandırma `ClimbingResolver` ile **aynı eşikleri** kullanıyor —
  görsel mekanikle çelişemez, test bunu kilitliyor.
- Siperdeki birim artık panelde **"Siperde"** rozeti gösteriyor (`DicePoolBuilder` ile aynı kaynak).

## Kapsam dışı (değişmedi)

17 Variant Warband · tam Armoury satın alma ekranı · Alignment sistemi ·
Infernal Bomb "Duck" kuralı · Seven Deadly Sins aura doğrulaması (kaynak eksik)

---

## P3-4 — Armoury (Battlekit) satın alma ekranı

**Kullanıcı isteği:** *"Tam Armoury / silah satın alma UI'ı ekle... görsel olmadığı için isim ve
açıklama olsun... kategorize edilmiş... yerleştirmeden sonra oyuncular yerleştirilen unitlere
satın alma yapabilsin."* + *"silah eksiklikleri kısmında bir elden geçir."*

### Kural yeri
Compendium'da Battlekit model **işe alınırken** satın alınır. Oyunda roster-builder yoktur;
kurallara en uygun an **yerleştirme bittikten sonra, savaş başlamadan önce**dir. Yeni faz:
`DEPLOYMENT → ARMOURY → BATTLE` (kampanyadaki *Quartermaster* adımının çatışma karşılığı).

### Veri (üreteçle, elle değil)
`tools/generate_armoury.py` compendium'dan **229 faksiyon girdisi / 117 benzersiz kalem** üretir:
fiyat + `LIMIT: N` + kısıtlar `warbands/<faction>#Armoury` tablolarından, anahtar kelimeler
`battlekit/*.md` kural bloklarından. Fiyat tablosu değişirse tek komutla yeniden üretilir —
veri ile kaynak arasındaki bağ kopmaz.

| Faksiyon | Kalem |
|---|---|
| New Antioch | 39 |
| Heretic Legion | 42 |
| Trench Pilgrims | 41 |
| Iron Sultanate | 41 |
| Cult of the Black Grail | 32 |
| Court of the Seven-Headed Serpent | 33 |

**Faksiyona göre değişen 21 varyant** ayrı kaynak olarak üretildi — aynı kalem farklı faksiyonda
farklı `LIMIT` ya da kısıt taşır (ör. Machine Gun: New Antioch `LIMIT: 2`, Heretic Legion `LIMIT: 1`).

### EKSİK SİLAHLAR (kullanıcı bildirimi) — 11 adet eklendi
Armoury tablolarındaki 60 silahın **10'unun** oyunda hiçbir karşılığı yoktu. Compendium stat
bloklarından üretildiler: Automatic Shotgun, Heavy Shotgun, Punt Gun, Semi-Automatic Rifle,
Submachine Gun, Grenade Launcher, Jezzail, Gas Grenades, Incendiary Grenades, Halberd-Gun
(yakın dövüş + 24" atış olmak üzere iki profil). Hepsi iki dilde adlandırıldı ve açıklandı.

### Glory Point fiyatlı Battlekit
Compendium: *"Some pieces of Battlekit cost Glory Points instead of ducats."* Kazımada para
birimi simgeleri kaybolmuş; 8 girdi **aynı kalemin başka faksiyonda 10-25 kat pahalı listelenmesiyle**
teşhis edildi (ör. Automatic Rifle: New Antioch 40 ducat / Heretic Legion "2" → 2 Şan Puanı).
Ducat ve Şan havuzları birbirinin yerine geçmez — `EconomyRules` ile aynı ilke.

### Mimari
| Dosya | Sorumluluk | Satır |
|---|---|---|
| `scripts/data/armoury_item.gd` | yalnızca veri tanımı | 63 |
| `scripts/rules/armoury_rules.gd` | **saf** karar mantığı (11 kapı) | 206 |
| `scripts/game_state/armoury_manager.gd` | faz durumu + çok oyunculu senkron (autoload) | 114 |
| `scenes/ui/armoury/armoury_panel.{tscn,gd}` | yalnızca çizim | 242 |

Satın alma durumu `game_state.gd`'ye **konmadı** — orası zaten yerleştirme, tur ve bütçe taşıyor;
eklenseydi god-file olurdu. Panel kendi kuralını uydurmaz: alınamayan kalem **solar**, sebebi
kartın üstünde ve tooltip'inde lokalize olarak yazar — `DeployAvailability` ile aynı "tek kaynak" ilkesi.

Kapılar sırayla: faksiyon tablosu üyeliği → `Elite only` → `<Birim> only` → gerekli anahtar
kelime → ön koşul kalem → modelde zaten var mı → `LIMIT: N` → zırh tekliği → **el bütçesi**
(1x2El veya 2x1El) → `[Heavy]` tekliği → bütçe (Şan/ducat ayrı).

Satın alma modelin `.tres`'ini **asla mutasyona uğratmaz** — kopya üzerinde çalışır.

### Metinler
Koda tek bir metin gömülmedi. **+142 anahtar** iki dilde: 96 kalem adı/açıklaması, 18 kısıt
metni, 12 ret sebebi, 6 kategori başlığı, 14 ekran metni, 22 yeni silah adı/açıklaması.

### Doğrulama
* Test: 3034 → **4319 assert, 0 başarısız**
* `armoury_rules_test.gd` — tablo boyutları, fiyat/LIMIT sadakati, 11 kapının hepsi, satın
  alma uygulaması, paylaşılan kaynağın korunması
* `armoury_panel_smoke_test.gd` — ekranı gerçekten kurar, 6 kategoriyi de çizer ve tam bir
  satın alma akışı yürütür (`codex_panel.gd` vakasındaki gibi yalnız çalışırken çıkan hataları yakalar)
* `armoury_reachability_test.gd` — Armoury artık üçüncü bir ulaşılabilirlik yolu; zombi silah yok
* Oyun: **0 script hatası, 0 hata**

### Yol boyunca yakalanan iki gerçek kusur
1. `queue_free()` ertelenir; aynı karede iki kez tazelenen liste satırları üst üste biniyordu →
   çocuklar artık **anında** ayrılıyor.
2. Yeoman'ın Süngüsü 2 elli ve `[Cumbersome]`; yakın dövüş elleri zaten dolu. El bütçesi kapısı
   bunu doğru reddediyor — testte belgelendi.

---

## P3-6 — Lokalizasyon süpürmesi

**Kullanıcı bildirimi:** *"bazı metinler local kısmında dil dosyalarında yok, koda metin
koymayın, tüm metinler dil dosyasında olsun."*

### Bulunan gerçek kusurlar (3)
1. **`shot_breakdown_card.gd`** atış dökümünün altbilgisinde İngilizce `DICE` kelimesi koda
   gömülüydü — dil ne olursa olsun İngilizce görünüyordu. `DICE_LABEL` anahtarına taşındı.
2. **`game_end_overlay.gd`** çevrilmemiş bir yedek dal taşıyordu:
   `title_label.text = "PLAYER %d VICTORY" % winner_player_id`. Ölü koddu (anahtar zaten `%d`
   içeriyor) ama İngilizce metni koda bağlıyordu — kaldırıldı; anahtarın biçimlendirici
   taşıdığı artık testle garanti altında.
3. **`LORD_LOADOUT_BEELZEBUB_STANDARD`** yanıltıcı bir üretilmiş addı — "standart teçhizat"
   seçeneğinin Beelzebub'un Baltası ile ilgisi yok. `LORD_LOADOUT_STANDARD` oldu.

### Kalıcı bekçi: `localization_coverage_test.gd`
Süpürme tek seferlik kalmasın diye 5 denetim kalıcılaştırıldı:
1. Koddaki her `tr_t("SABIT")` çağrısının iki dilde karşılığı var (**~120 betik taranıyor**).
2. `.tres` verilerindeki her lokalizasyon alanının karşılığı var (**~350 kaynak**).
3. Sahnelerdeki her metin ya çevrilmiş ya da çalışma anında yazılıyor — yer tutucu listesi
   bayatlarsa (yazan dosya silinirse) test düşer.
4. **Koda gömülü oyuncu metni yok.** BBCode etiketleri ve `%s`/`%.1f` biçim belirteçleri
   ayıklandıktan sonra geriye kelime kalıyorsa hatadır. Bu denetim `DICE` kusurunu yakaladı.
5. Kodun `% deger` ile kullandığı anahtarlar biçimlendiricilerini korur — düşerse çalışma
   anında patlardı.

`localization_parity_test.gd` iki dilin anahtar kümelerinin eşitliğini denetler; bu test
anahtarların KULLANILDIĞI yerlerden geriye bakar. İkisi birlikte boşluk bırakmaz.

**Sonuç:** iki dil de **1491 anahtar**, sapma yok. Test: 4319 → **4336 assert, 0 başarısız**.
Oyun: 0 script hatası.

---

## P3-7 — Alışveriş kapanmıyordu + teçhizat seçiminin rolü

**Kullanıcı bildirimi:** *"alışverişi bitir deyince alışveriş penceresi kapanmıyor"* ve
*"unit yerleştirince teçhizat seç seçimi gelmesi normal mi, yoksa satın alma ekranında mı olmalı?"*

### 1) Kapanmayan pencere (gerçek hata)
`finish_player()` yalnızca YEREL oyuncuyu bitmiş sayıyordu. Tek makinede iki oyuncu oynanırken
rakip hiçbir zaman "bitirdi" olmuyor, dolayısıyla faz `ARMOURY`de kilitleniyor ve ekran açık
kalıyordu. Yerleştirmedeki `active_deployer_id` deseni birebir uygulandı:
* `ArmouryManager.active_shopper_id` eklendi; bitirince sıra rakibe geçiyor.
* Panel sırayı `current_shopper()`'dan okuyor, kendi başına tahmin etmiyor.
* İki taraf da bitirince faz `BATTLE`e geçiyor ve panel **kapanıyor**.

`has_multiplayer_peer()` gerçek bir maçı ayırt etmeye yetmiyor (lobi bağlantısı da bir peer'dır
ve tek makinede sırayı bozardı) — ayrım `NetworkManager.is_in_match` ile yapılıyor.

Regresyon koruması `armoury_panel_smoke_test.gd`'ye eklendi: tek taraf bitirince faz ARMOURY
kalır ve panel yeni oyuncuya döner; iki taraf da bitirince savaş başlar ve panel kapanır.

### 2) Teçhizat seçimi gerekli mi? — EVET, ama farklı bir şey
İkisi compendium'da **ayrı iki adımdır** ve biri diğerinin yerine geçmez:

| | Ne zaman | Ne verir |
|---|---|---|
| **Başlangıç Teçhizatı** (yerleştirmede) | model sahaya girerken | modelin KENDİ stat-bloğundaki varyant |
| **Cephanelik** (yerleştirmeden sonra) | savaş öncesi | Armoury Tablosundan satın alınan ek Battlekit |

97 loadout seçeneğinin **28'i** Armoury'nin ifade edemeyeceği etkiler taşıyor (zırh değeri
değişimi, ek anahtar kelimeler, satın alınan yetenekler — Brazen Bull'un Titan Zülfikar'ı,
Anchorite'ın "Broken on the Wheel"i, Azeb'in Skirmisher'ı gibi). Kaldırılsaydı bu içerik yok olurdu.

Karışıklık **adlandırmadan** kaynaklanıyordu: başlık "Teçhizat Seç" idi ve satın alma ekranıyla
aynı şeyi ima ediyordu. İki dilde yeniden yazıldı:
* **Başlangıç Teçhizatı** — *"%s modelinin KENDİ silah/zırh varyantını seç. Ek Battlekit'i
  yerleştirme bittikten sonra Cephanelik'ten satın alacaksın."*

**Doğrulama:** 4336 → **4343 assert, 0 başarısız**. Oyun: 0 script hatası.

---

## P3-8 — Siper/mayın yerleşimi ve kalıcılığı

**Kullanıcı bildirimi:** *"siper haritanın içine giriyor ve yan duruyor... harita üstünde
duracak ve düşmana bakacak şekilde olmalı, aynısı mayında da... tekrar tahkim et deyince eski
tahkim gidiyor ve yeni yere ışınlanıyor, bu böyle olmamalı."*

### 1) Modeller haritanın içine gömülüyordu
`terrain_feature.gd` sabit bir `y_offset` kullanıyordu. GLB'lerin yerel orijini merkezlerinde
olduğu için model yarı yarıya zemine gömülüyordu. Artık parçanın **gerçek sınır kutusundan**
en alçak nokta bulunup taban `y=0`'a oturtuluyor — hangi model gelirse gelsin doğru duruyor.

### 2) Yön: siper yan duruyordu
`spawn_feature` her zaman `rotation_y = 0` ile çağrılıyordu. Artık hem siper hem mayın
**düşman modellerin ortalama konumuna** dönük yerleştiriliyor (`FortifyActions._facing_enemy`);
sahada düşman yoksa birimin kendi yönü kullanılıyor.

### 3) Siper "ışınlanıyordu" — kural hatası
`apply_fortify` her seferinde `clear_for(unit)` çağırıp birimin önceki mevzisini siliyordu;
ayrıca birim hareket edince siper de sahadan kalkıyordu. İkisi de yanlıştı:

> *"the model has [Cover] until they move away from their current position"*

Kural **avantajın** kaybedildiğini söyler, kazılan toprağın yok olduğunu değil. Şimdi:
* Kazılan mevzi **kalıcıdır**, sahada durur.
* Birim uzaklaşınca yalnız `has_fortify_cover` bayrağı düşer — siper yerinde kalır.
* Tekrar Fortify → sahaya **yeni** bir mevzi eklenir, eskisi durmaya devam eder.

Mayın zaten bu davranıştaydı (her Set Mine yeni bir mayın kurar; aynı noktada ikinci mayın
`MINE_FAIL_ALREADY_MINED` ile reddedilir, tetiklenince tüketilir — compendium'a uygun).

`clear_for()` artık araziye dokunmuyor; gerçekten silinmesi gereken durumlar için
`remove_terrain_for()` ayrıldı.

**Doğrulama:** 4343 → **4348 assert, 0 başarısız**. Oyun: 0 script hatası.
