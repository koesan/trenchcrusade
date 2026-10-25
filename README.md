<a id="top"></a>

<p align="center">
  <a href="#english"><b>English</b></a> &nbsp;·&nbsp; <a href="#turkce"><b>Türkçe</b></a>
</p>

<a id="english"></a>

# Iron Requiem

<p align="center">
  <img src="docs/screenshots/en/menu.jpg" alt="Iron Requiem main menu" width="100%">
</p>

<p align="center">
  <b>A turn-based 3D tactics game built on the rules of the <i>Trench Crusade</i> tabletop wargame.</b><br>
  Two warbands, one trench line, and a war between Heaven and Hell that never ended.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Godot-4.7-478CBF?logo=godotengine&logoColor=white" alt="Godot 4.7">
  <img src="https://img.shields.io/badge/platform-Windows%20%7C%20Linux-5a4632" alt="Windows | Linux">
  <img src="https://img.shields.io/badge/players-2%20(local%20%2F%20online)-7a1f1f" alt="2 players">
  <img src="https://img.shields.io/badge/languages-English%20%7C%20T%C3%BCrk%C3%A7e-8a7a5a" alt="English | Türkçe">
</p>

---

## Contents

- [The game](#the-game)
- [How a battle plays out](#how-a-battle-plays-out)
- [On the battlefield](#on-the-battlefield)
- [Factions](#factions)
- [Scenarios](#scenarios)
- [Controls](#controls)
- [System requirements and graphics](#system-requirements-and-graphics)
- [Getting started](#getting-started)
- [For developers](#for-developers)
- [Credits and license](#credits-and-license)

---

## The game

The year is 1917, and the Great War has raged for eight centuries. Iron Requiem puts you in command of a small warband in the trenches of this endless crusade. You recruit your models, arm them, and fight a scenario against another player.

The game follows the official *Trench Crusade* rules: 2D6 success rolls with bonus and penalty dice, injury markers, Down and Out of Action, morale checks, climbing and falling, line of sight, and base-to-base measurement. Weapon keywords such as `[Cleave]`, `[Assault]`, `[Heavy]`, `[Shield Combo]` and `[Sniper]` all work as written.

| | |
| --- | --- |
| **6 factions** | each with its own units, armoury and special rules |
| **6 scenarios** | from objective control to bounty hunts |
| **57 unit types** | each with a 3D model, stats and abilities |
| **117 armoury items** | weapons, armour, grenades, shields and equipment |
| **100 abilities** | prayers, goetic spells, commands and faction tricks |
| **2 play modes** | local hot-seat on one computer, or online over the network |

There is no AI opponent. Iron Requiem is a game for two people.

---

## How a battle plays out

### 1. Choose a scenario

Each scenario has its own map setup, objectives and victory conditions.

<img src="docs/screenshots/en/scenario.jpg" alt="Scenario selection" width="100%">

### 2. Choose your faction

Each player picks one of the six warbands.

<img src="docs/screenshots/en/faction.jpg" alt="Faction selection" width="100%">

### 3. Deploy your warband

Pick models from your roster and place them in your deployment zone. Every model costs ducats or glory points. A warband must include a leader, and faction limits are enforced: elite caps, unit ratios and alignment.

<img src="docs/screenshots/en/deployment.jpg" alt="Deployment" width="100%">

### 4. Visit the armoury

Before the battle, buy weapons, armour and equipment for each model. The armoury enforces hand slots, `[Heavy]` limits, headgear rules and per-faction item tables.

<img src="docs/screenshots/en/armoury.jpg" alt="Armoury" width="100%">

### 5. Fight

Players roll for initiative, then take turns activating one model at a time. A model can move, charge, shoot, fight in melee, pray or cast spells. When its activation ends, the turn passes to the other side. The battle ends when the scenario's turn limit is reached, or when one warband is wiped out or flees.

<img src="docs/screenshots/en/battlefield.jpg" alt="Battlefield overview" width="100%">

---

## On the battlefield

The interface is built so you always know what you can do next.

<table>
  <tr>
    <td width="50%"><img src="docs/screenshots/en/movement.jpg" alt="Movement area"></td>
    <td width="50%"><img src="docs/screenshots/en/shooting.jpg" alt="Shooting line"></td>
  </tr>
  <tr>
    <td><b>Movement area.</b> Select a model to see where it can go. Climbable walls and ledges are marked at ground level.</td>
    <td><b>Shooting and charging.</b> The attack line runs base to base and shows range, cover and the final dice bonus before you commit.</td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/screenshots/en/dice.jpg" alt="Dice bar"></td>
    <td width="50%"><img src="docs/screenshots/en/activation.jpg" alt="Activation cues"></td>
  </tr>
  <tr>
    <td><b>Dice bar.</b> Every roll shows which dice counted, the total and the result needed.</td>
    <td><b>Whose turn, which model.</b> Models you can activate now have a softly pulsing ring. The model you are using keeps a rotating ring until its activation ends. Everything else dims.</td>
  </tr>
</table>

- **Helpful notices.** If a move breaks a rule, a short card in the centre of the screen tells you why and what to do instead. Cards never cover other panels or block clicks.
- **Target picking.** Valid targets are ringed. A click that lands on a wall or fence still picks the nearest valid target on screen.
- **Top bar.** Shows the turn, the phase, the side to act, and either the active model or how many models are ready.
- **Roster list.** Shows each model's state at a glance: ready, active, waiting, done or down.
- **Joint activation.** Fireteam, Sworn Brethren and Faithful Followers models can activate together.

---

## Factions

| Faction | Allegiance |
| --- | --- |
| **New Antioch** | The last great Christian city-state and its trench armies |
| **Trench Pilgrims** | Zealots who march to war on faith alone |
| **Iron Sultanate** | The alchemist-engineers of the Sultanate and their Assassins |
| **Heretic Legion** | Soldiers who sold their souls to the powers of Hell |
| **Cult of the Black Grail** | Plague-ridden followers of Beelzebub, Lord of Flies |
| **Court of the Seven-Headed Serpent** | Demonic nobility of the Pit and their enslaved thralls |

## Scenarios

| Scenario | Goal |
| --- | --- |
| **Claim No Man's Land** | Hold 5 objectives; 2 VP per objective each turn |
| **Fields of Glory** | Score only through Glorious Deeds |
| **Great War** | No morale checks. Score VP for every enemy taken Out of Action |
| **The High Ground** | Hold 5 objectives; diving charges score extra |
| **Marked for Death** | Hunt down the enemy's most valuable model |
| **Relic Hunt** | Find and claim the four sacred Reliquaries |

---

## Controls

| Action | Input |
| --- | --- |
| Select a model / give an order | Left click |
| Pan the camera | W A S D or arrow keys |
| Rotate the camera | Q / E or right-click drag |
| Zoom | Mouse wheel |
| Focus on the selected model | F |
| Action shortcuts | 1–9 (numbers on the action buttons) |
| End activation | Space |
| Cancel target picking | Esc |

All bindings are also listed in-game under **Settings → Key Bindings**.

---

## System requirements and graphics

| | Minimum | Recommended |
| --- | --- | --- |
| OS | Windows 10 64-bit / Linux x86_64 | Windows 11 / a current Linux distribution |
| GPU | Integrated GPU with OpenGL 3.3 | Dedicated GPU with Vulkan |
| Memory | 4 GB | 8 GB |
| Resolution | 1280×720 | 1920×1080 or higher |

The game runs on Vulkan by default. If Vulkan is missing, it falls back to Direct3D 12 on Windows, then to OpenGL 3.

On first launch a graphics preset is picked for your GPU: **High** on a dedicated GPU, **Medium** on an integrated GPU, **Low** on a software renderer. You can change it in **Settings → Graphics**.

| Preset | 3D resolution | Anti-aliasing | Shadows | Effects |
| --- | --- | --- | --- | --- |
| Low | 67% (FSR upscaled) | FXAA | Hard | Off |
| Medium | 85% (FSR upscaled) | FXAA | Soft (low) | Glow |
| High | 100% | MSAA 2× | Soft (medium) | SSAO and glow |

The interface always renders at full resolution; only the 3D scene is scaled. A frame-rate cap (unlimited, 30, 60, 120 or 144) helps with battery life and heat.

---

## Getting started

You only need **Godot 4.7** or newer. There are no other dependencies and no build step.

```bash
git lfs install            # models, textures and audio are stored with Git LFS
git clone <repository-url>
cd Trenchcrusade
godot --path .             # run the game
godot -e --path .          # open it in the editor
```

> If you clone without `git lfs install`, models and textures download as text pointers. The game still starts, but the visuals will be missing.

From the main menu, choose **Local battle** to play hot-seat on one computer, or **Online battle** to host or join a game. Online play uses ENet on port `10567` by default. The host validates every rule, and a dropped connection tries to reconnect. An unfinished battle is saved and can be resumed with **Continue**.

---

## For developers

### Exporting

Windows and Linux presets are ready in `export_presets.cfg`. Once Godot's export templates are installed:

```bash
godot --headless --export-release "Windows Desktop" build/windows/IronRequiem.exe
godot --headless --export-release "Linux" build/linux/IronRequiem.x86_64
```

### Tests

```bash
godot --headless --path . tests/test_main.tscn
```

Expected output: `6190 assert, 0 başarısız` (0 failed) across 144 test files. Some tests compare the game data with the official rules text in `trench_compendium/`. If unit stats, abilities, armoury items or scenarios drift from the rules, a test fails. The suite also requires a minimum assert count (`MIN_ASSERTS`), so a test file that fails to compile cannot be skipped silently.

### Project layout

```
assets/
  data/            Units, factions, scenarios, armoury, abilities (.tres)
  localization/    tr.json, en.json — add a language by adding a JSON file
  models/          Character, map and scenario models (.glb)
  audio/           Music and sound effects (credits: assets/audio/CREDITS.md)
  shaders/         Team ring (ready / active model cues)
scripts/
  rules/           Rule resolvers (combat, morale, terrain, activation)
  game_state/      Game state, event bus, armoury
  turn_manager/    Turn and activation loop
  networking/      ENet host/join, reconnect
  ui/              Theme, loading screen, graphics settings, localization
  unit/            Unit behaviour and visual cues
scenes/            Scenes (ui, game, map, unit, dice, scenario)
tests/             Headless test runner and test cases
trench_compendium/ Text copy of the official rules (the reference for the tests)
docs/screenshots/  Images used in this README
tools/             Data generation scripts
```

The game is data-driven. Units, weapons and scenarios live in `.tres` resources, not in code, so adding a unit or weapon usually means adding one resource file. The game has 1643 translated text keys. To add a language, drop a JSON file into `assets/localization/`; the game finds it automatically.

---

## Credits and license

This is a **non-commercial fan project**.

- **Trench Crusade**, its rules text, faction names and setting belong to their creators, Tuomas Pirinen and Mike Franchina (Factory Fortress). The content in `trench_compendium/` comes from [trench-companion.com](https://trench-companion.com/compendium) and is included for reference only.
- **Music:** Kevin MacLeod (incompetech.com), CC-BY 4.0. Attribution required.
- **Sound effects:** Kenney.nl, CC0.
- Full credits: [`assets/audio/CREDITS.md`](assets/audio/CREDITS.md)

The code and data changes in this repository belong to the project owner.

<p align="right"><a href="#top">Back to top ↑</a></p>

---
---

<a id="turkce"></a>

# Iron Requiem

<p align="center">
  <img src="docs/screenshots/tr/menu.jpg" alt="Iron Requiem ana menü" width="100%">
</p>

<p align="center">
  <b><i>Trench Crusade</i> masa oyununun kurallarıyla yapılmış, sıra tabanlı bir 3B taktik oyunu.</b><br>
  İki savaş grubu, bir siper hattı ve Cennet ile Cehennem arasında hiç bitmeyen bir savaş.
</p>

---

## İçindekiler

- [Oyun](#oyun)
- [Bir savaş nasıl oynanır](#bir-savaş-nasıl-oynanır)
- [Savaş alanında](#savaş-alanında)
- [Faksiyonlar](#faksiyonlar)
- [Senaryolar](#senaryolar)
- [Kontroller](#kontroller)
- [Sistem gereksinimleri ve grafik](#sistem-gereksinimleri-ve-grafik)
- [Başlarken](#başlarken)
- [Geliştiriciler için](#geliştiriciler-için)
- [Haklar ve lisans](#haklar-ve-lisans)

---

## Oyun

Yıl 1917. Büyük Savaş sekiz yüzyıldır sürüyor. Iron Requiem'de bu bitmeyen haçlı seferinin siperlerinde küçük bir savaş grubunu yönetirsin. Modellerini toplar, donatır ve bir senaryoda başka bir oyuncuya karşı savaşırsın.

Oyun resmî *Trench Crusade* kurallarını izler: bonus ve ceza zarlı 2D6 başarı atışları, yara işaretleri, Down ve Out of Action, moral testleri, tırmanma ve düşme, görüş hattı ve tabandan tabana ölçüm. `[Cleave]`, `[Assault]`, `[Heavy]`, `[Shield Combo]` ve `[Sniper]` gibi silah anahtar kelimeleri kurallardaki gibi işler.

| | |
| --- | --- |
| **6 faksiyon** | her birinin kendi birimleri, cephaneliği ve özel kuralları |
| **6 senaryo** | hedef kontrolünden ödül avına kadar |
| **57 birim türü** | her biri 3B model, stat ve yeteneklerle |
| **117 cephanelik kalemi** | silah, zırh, el bombası, kalkan ve teçhizat |
| **100 yetenek** | dualar, goetik büyüler, komutlar ve faksiyon hileleri |
| **2 oyun modu** | aynı bilgisayarda sırayla ya da ağ üzerinden |

Yapay zekâ rakip yoktur. Iron Requiem iki kişilik bir oyundur.

---

## Bir savaş nasıl oynanır

### 1. Senaryoyu seç

Her senaryonun kendi harita düzeni, hedefleri ve zafer koşulları vardır.

<img src="docs/screenshots/tr/scenario.jpg" alt="Senaryo seçimi" width="100%">

### 2. Faksiyonunu seç

Her oyuncu altı savaş grubundan birini seçer.

<img src="docs/screenshots/tr/faction.jpg" alt="Faksiyon seçimi" width="100%">

### 3. Savaş grubunu yerleştir

Kadrondan modelleri seçip yerleştirme bölgene koyarsın. Her modelin bir duka ya da şan puanı bedeli vardır. Savaş grubunda bir lider bulunmalıdır; seçkin model sınırı, birim oranları ve hizalama gibi faksiyon kuralları uygulanır.

<img src="docs/screenshots/tr/deployment.jpg" alt="Yerleştirme" width="100%">

### 4. Cephaneliğe uğra

Savaştan önce her model için silah, zırh ve teçhizat alırsın. Cephanelik el sayısını, `[Heavy]` sınırını, başlık kuralını ve faksiyona özel kalem listelerini uygular.

<img src="docs/screenshots/tr/armoury.jpg" alt="Cephanelik" width="100%">

### 5. Savaş

Oyuncular inisiyatif için zar atar, sonra sırayla birer model aktive eder. Bir model yürüyebilir, hücum edebilir, ateş edebilir, yakın dövüşe girebilir, dua edebilir ya da büyü yapabilir. Aktivasyonu bitince sıra karşı tarafa geçer. Savaş, senaryonun tur sınırı dolunca ya da bir savaş grubu yok olunca veya kaçınca biter.

<img src="docs/screenshots/tr/battlefield.jpg" alt="Savaş alanı" width="100%">

---

## Savaş alanında

Arayüz, bir sonraki adımda ne yapabileceğini her an bilmen için tasarlandı.

<table>
  <tr>
    <td width="50%"><img src="docs/screenshots/tr/movement.jpg" alt="Hareket alanı"></td>
    <td width="50%"><img src="docs/screenshots/tr/shooting.jpg" alt="Atış çizgisi"></td>
  </tr>
  <tr>
    <td><b>Hareket alanı.</b> Bir model seçince nereye gidebileceği görünür. Tırmanılabilir duvarlar ve kenarlar zemin hizasında işaretlenir.</td>
    <td><b>Atış ve hücum.</b> Saldırı çizgisi tabandan tabana çizilir; karar vermeden önce menzili, siperi ve toplam zar bonusunu gösterir.</td>
  </tr>
  <tr>
    <td width="50%"><img src="docs/screenshots/tr/dice.jpg" alt="Zar barı"></td>
    <td width="50%"><img src="docs/screenshots/tr/activation.jpg" alt="Aktivasyon ipuçları"></td>
  </tr>
  <tr>
    <td><b>Zar barı.</b> Her atışta hangi zarların sayıldığını, toplamı ve gereken sonucu gösterir.</td>
    <td><b>Sıra kimde, hangi model.</b> Şu an aktive edebileceğin modellerin halkası yavaşça nabız atar. Kullandığın modelin çevresinde, aktivasyonu bitene kadar dönen bir çember kalır. Diğerleri sönükleşir.</td>
  </tr>
</table>

- **Yönlendirici bildirimler.** Bir hamle kurala takılırsa, ekranın ortasında kısa bir kart neden olmadığını ve ne yapman gerektiğini söyler. Kartlar diğer panellerin üstüne binmez ve tıklamayı engellemez.
- **Hedef seçimi.** Geçerli hedefler halkayla işaretlenir. Tıklama bir duvara ya da çite takılsa bile ekrandaki en yakın geçerli hedef seçilir.
- **Üst bar.** Turu, fazı, sıranın kimde olduğunu ve aktif modeli ya da kaç modelin hazır olduğunu gösterir.
- **Kadro listesi.** Her modelin durumunu bir bakışta gösterir: hazır, aktif, bekliyor, bitti ya da yerde.
- **Ortak aktivasyon.** Fireteam, Sworn Brethren ve Faithful Followers modelleri birlikte aktive olabilir.

---

## Faksiyonlar

| Faksiyon | Taraf |
| --- | --- |
| **Yeni Antakya** (New Antioch) | Son büyük Hristiyan şehir devleti ve siper orduları |
| **Hendek Hacıları** (Trench Pilgrims) | Savaşa yalnızca inançla yürüyen bağnazlar |
| **Demir Sultanlık** (Iron Sultanate) | Sultanlığın simyacı mühendisleri ve suikastçıları |
| **Sapkın Lejyon** (Heretic Legion) | Ruhlarını Cehennem'e satmış askerler |
| **Kara Kase Kültü** (Cult of the Black Grail) | Sineklerin Efendisi Beelzebub'un vebalı müritleri |
| **Yedi Başlı Yılan Divanı** (Court of the Seven-Headed Serpent) | Cehennem'in iblis soyluları ve köleleri |

## Senaryolar

| Senaryo | Hedef |
| --- | --- |
| **Sahipsiz Toprağı Ele Geçir** (Claim No Man's Land) | 5 hedefi tut; her tur tuttuğun her hedef için 2 VP |
| **Şeref Alanları** (Fields of Glory) | Yalnızca Şanlı İşlerle puan kazan |
| **Büyük Savaş** (Great War) | Moral testi yok. Saf dışı bıraktığın her düşman için VP kazan |
| **Yüksek Zemin** (The High Ground) | 5 hedefi tut; dalış hücumları ek puan getirir |
| **Ölüm Damgası** (Marked for Death) | Düşmanın en değerli modelini avla |
| **Kutsal Emanet Avı** (Relic Hunt) | Dört kutsal emaneti bul ve sahiplen |

---

## Kontroller

| Eylem | Tuş |
| --- | --- |
| Model seç / emir ver | Sol tık |
| Kamerayı kaydır | W A S D ya da ok tuşları |
| Kamerayı döndür | Q / E ya da sağ tık + sürükle |
| Yakınlaştır | Fare tekerleği |
| Seçili modele odaklan | F |
| Eylem kısayolları | 1–9 (eylem düğmelerindeki numaralar) |
| Aktivasyonu bitir | Boşluk |
| Hedef seçimini iptal et | Esc |

Tuşlar oyun içinde **Ayarlar → Tuş Atamaları** bölümünde de listelenir.

---

## Sistem gereksinimleri ve grafik

| | En az | Önerilen |
| --- | --- | --- |
| İşletim sistemi | Windows 10 64 bit / Linux x86_64 | Windows 11 / güncel bir Linux dağıtımı |
| Ekran kartı | OpenGL 3.3 destekli tümleşik kart | Vulkan destekli harici kart |
| Bellek | 4 GB | 8 GB |
| Çözünürlük | 1280×720 | 1920×1080 ve üstü |

Oyun varsayılan olarak Vulkan ile çalışır. Vulkan yoksa Windows'ta Direct3D 12'ye, o da yoksa OpenGL 3'e kendiliğinden geçer.

İlk açılışta ekran kartına göre bir grafik ayarı seçilir: harici kartta **Yüksek**, tümleşik kartta **Orta**, yazılım çizicide **Düşük**. **Ayarlar → Grafik** bölümünden değiştirilebilir.

| Ön ayar | 3B çözünürlük | Kenar yumuşatma | Gölge | Efektler |
| --- | --- | --- | --- | --- |
| Düşük | %67 (FSR ile büyütülür) | FXAA | Sert | Kapalı |
| Orta | %85 (FSR ile büyütülür) | FXAA | Yumuşak (düşük) | Parlama |
| Yüksek | %100 | MSAA 2× | Yumuşak (orta) | SSAO ve parlama |

Arayüz her zaman tam çözünürlükte çizilir; yalnızca 3B sahne ölçeklenir. Kare hızı sınırı (sınırsız, 30, 60, 120 ya da 144) pil ömrüne ve ısınmaya yardımcı olur.

---

## Başlarken

**Godot 4.7** ya da üstü dışında hiçbir şey gerekmez. Başka bağımlılık ya da derleme adımı yoktur.

```bash
git lfs install            # modeller, dokular ve sesler Git LFS ile tutulur
git clone <depo-adresi>
cd Trenchcrusade
godot --path .             # oyunu başlatır
godot -e --path .          # editörde açar
```

> `git lfs install` çalıştırılmadan klonlanırsa modeller ve dokular metin işaretçisi olarak iner. Oyun açılır, ama görseller eksik olur.

Ana menüde **Yerel savaş** ile aynı bilgisayarda sırayla oynayabilir, **Çevrimiçi savaş** ile oyun kurabilir ya da bir oyuna katılabilirsin. Çevrimiçi oyun varsayılan olarak `10567` portunda ENet kullanır. Kuralların hepsini sunucu doğrular; bağlantı koparsa oyun yeniden bağlanmayı dener. Yarım kalan savaş kaydedilir ve **Devam et** ile sürdürülür.

---

## Geliştiriciler için

### Dışa aktarma

`export_presets.cfg` dosyasında Windows ve Linux ön ayarları hazırdır. Godot'un dışa aktarma şablonları kurulduktan sonra:

```bash
godot --headless --export-release "Windows Desktop" build/windows/IronRequiem.exe
godot --headless --export-release "Linux" build/linux/IronRequiem.x86_64
```

### Testler

```bash
godot --headless --path . tests/test_main.tscn
```

Beklenen çıktı: 144 test dosyasında `6190 assert, 0 başarısız`. Testlerin bir kısmı oyunun verisini `trench_compendium/` altındaki resmî kural metniyle karşılaştırır. Birim statları, yetenekler, cephanelik kalemleri ya da senaryolar kurallardan saparsa test kırılır. Süit en az `MIN_ASSERTS` kadar assert bekler; derlenemeyen bir test dosyası sessizce atlanamaz.

### Proje yapısı

```
assets/
  data/            Birimler, faksiyonlar, senaryolar, cephanelik, yetenekler (.tres)
  localization/    tr.json, en.json — yeni dil = yeni JSON dosyası
  models/          Karakter, harita ve senaryo modelleri (.glb)
  audio/           Müzik ve ses efektleri (künye: assets/audio/CREDITS.md)
  shaders/         Takım halkası (hazır / aktif model ipuçları)
scripts/
  rules/           Kural çözümleyicileri (dövüş, moral, arazi, aktivasyon)
  game_state/      Oyun durumu, olay veriyolu, cephanelik
  turn_manager/    Tur ve aktivasyon döngüsü
  networking/      ENet host/join, yeniden bağlanma
  ui/              Tema, yükleme ekranı, grafik ayarları, yerelleştirme
  unit/            Birim davranışı ve görsel ipuçları
scenes/            Sahneler (ui, game, map, unit, dice, scenario)
tests/             Headless test koşucusu ve test dosyaları
trench_compendium/ Resmî kural derlemesinin metin kopyası (testlerin referansı)
docs/screenshots/  Bu README'deki görseller
tools/             Veri üretim betikleri
```

Oyun veri odaklıdır. Birimler, silahlar ve senaryolar koda değil `.tres` kaynaklarına yazılıdır; yeni bir birim ya da silah eklemek çoğu zaman tek bir kaynak dosyası eklemek demektir. Oyunda 1643 çevrilmiş metin anahtarı vardır. Yeni bir dil eklemek için `assets/localization/` klasörüne bir JSON dosyası bırakmak yeterlidir; oyun onu kendiliğinden bulur.

---

## Haklar ve lisans

Bu **ticari olmayan bir hayran projesidir**.

- **Trench Crusade**, kural metni, faksiyon adları ve dünya kurgusu yaratıcılarına aittir: Tuomas Pirinen ve Mike Franchina (Factory Fortress). `trench_compendium/` altındaki içerik [trench-companion.com](https://trench-companion.com/compendium) kaynaklıdır ve yalnızca referans için bulunur.
- **Müzik:** Kevin MacLeod (incompetech.com), CC-BY 4.0. Atıf zorunludur.
- **Ses efektleri:** Kenney.nl, CC0.
- Tam künye: [`assets/audio/CREDITS.md`](assets/audio/CREDITS.md)

Bu depodaki kod ve veri düzenlemeleri proje sahibine aittir.

<p align="right"><a href="#top">Başa dön ↑</a></p>
