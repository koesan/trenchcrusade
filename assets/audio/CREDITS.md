# Ses & Müzik Künyesi (Audio Credits)

Bu dosya, oyunda kullanılan tüm ses efekti ve müziklerin kaynağını + lisansını takip eder.
Yeni bir ses eklerken kaynağını ve lisansını buraya işleyin.

- **CC0 / Public Domain:** atıf gerekmez.
- **CC-BY:** atıf ZORUNLU (aşağıda listelenir + oyun içi künyede gösterilmeli).

---

## Müzik — Kevin MacLeod (incompetech.com) · CC-BY 4.0 (ATIF ZORUNLU)

> "Music by Kevin MacLeod (incompetech.com) — Licensed under Creative Commons: By Attribution 4.0"
> https://creativecommons.org/licenses/by/4.0/

**Menü** (`music/menu/`): Anguish · Ossuary 5 - Rest · Dark Times · Echoes of Time v2
**Oynanış** (`music/gameplay/`): Killers · Volatile Reaction · Nightmare Machine · Static Motion

## Ses Efektleri — Kenney.nl · CC0 (atıf gerekmez)

- **Interface Sounds** (CC0) → `sfx/ui/` (click, hover, back, confirm, error, open)
- **Impact Sounds** (CC0) → `sfx/units/footstep_*`, `sfx/weapons/melee_hit,impact_metal`, `sfx/environment/bell`
- **RPG Audio** (CC0) → `sfx/units/select`, `sfx/weapons/melee_hit` (chop/knife)
- **Casino Audio** (CC0) → `sfx/dice/throw_*` (2026-07-18 genel bakım turu — projede hiç zar atma
  sesi yoktu, `DiceManager.dice_roll_started` hiç dinlenmiyordu)

**İşleme notu:** Bazı SFX (hover/click/confirm/error/abilities/impact_metal/bell) ffmpeg ile "tok/dolgun"
olacak şekilde işlendi (pitch-down + lowpass — tiz frekanslar kesildi). Kaynak lisansı (Kenney CC0)
değişmez; türev de CC0. `sfx/units/move_slide` = **prosedürel üretim** (ffmpeg filtreli gürültü, tok
sürükleme sesi) — telif yok.

Kaynaklar: https://kenney.nl/assets/interface-sounds · https://kenney.nl/assets/impact-sounds ·
https://kenney.nl/assets/rpg-audio · https://kenney.nl/assets/casino-audio

---

## Drop-in boşlukları (istenirse sonradan klasöre atılır, KOD GEREKMEZ)
- `sfx/weapons/ranged_shot*` — gerçek WW1 tüfek/silah sesi (Kenney paketlerinde yok).
- `sfx/ambient/*` — rüzgâr/uğultu/gerilim yatak sesi (atmosfer için önerilir).
- `music/*` — daha fazla parça: klasöre at, playlist otomatik alır.
- `sfx/dice/throw_*` DOLDU (2026-07-18) — daha fazla varyasyon istenirse aynı klasöre `throw_4.ogg`
  vb. atmak yeterli (kod değişmez).

### Güvenilir CC0/CC-BY kaynak havuzu
- **Kenney.nl** — CC0 (atıf gerekmez).
- **OpenGameArt.org** — CC0 / CC-BY (dosya bazında kontrol).
- **incompetech.com (Kevin MacLeod)** — CC-BY 4.0 (atıf zorunlu).
- **Pixabay Audio** — Pixabay Content License (ücretsiz).
