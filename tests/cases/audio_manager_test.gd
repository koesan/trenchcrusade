extends RefCounted

## AudioManager saf mantık + güvenlik kilidi (Ses Faz 1).
## Ses ÇALMA headless doğrulanamaz; burada yalnız veri-odaklı mantık test edilir:
##  - Dosya adı → event anahtarı gruplama (varyasyon eki soyma).
##  - Playlist cursor ilerleme (next/prev, loop açık/kapalı, boş).
##  - Boş klasörde güvenli no-op (çökme yok).

func run(t) -> void:
	# ── strip_variation: varyasyon eki (_<rakam>, _alt) düşer; anlamlı isim korunur ──
	t.eq(AudioManager.strip_variation("click"), "click", "ek yoksa aynı")
	t.eq(AudioManager.strip_variation("click_2"), "click", "_<rakam> ekini soyar")
	t.eq(AudioManager.strip_variation("click_alt"), "click", "_alt ekini soyar")
	t.eq(AudioManager.strip_variation("melee_hit"), "melee_hit", "anlamlı çift kelime korunur")
	t.eq(AudioManager.strip_variation("footstep_stone_3"), "footstep_stone", "çok kelime + rakam")
	t.eq(AudioManager.strip_variation("shot"), "shot", "tek kelime")

	# ── next_cursor: son elemanda loop açık→0, kapalı→-1 ──
	t.eq(AudioManager.next_cursor(0, 3, true), 1, "next ortada")
	t.eq(AudioManager.next_cursor(2, 3, true), 0, "next son + loop → başa")
	t.eq(AudioManager.next_cursor(2, 3, false), -1, "next son + loop kapalı → dur")
	t.eq(AudioManager.next_cursor(0, 0, true), -1, "next boş → -1")

	# ── prev_cursor: baştaysa loop açık→son, kapalı→0 ──
	t.eq(AudioManager.prev_cursor(1, 3, true), 0, "prev ortada")
	t.eq(AudioManager.prev_cursor(0, 3, true), 2, "prev baş + loop → sona")
	t.eq(AudioManager.prev_cursor(0, 3, false), 0, "prev baş + loop kapalı → 0'da kal")
	t.eq(AudioManager.prev_cursor(0, 0, true), -1, "prev boş → -1")

	# ── Zar atma sesi (2026-07-18 genel bakım turu): projede hiç yoktu, sfx/dice/throw_* eklendi +
	# AudioDirector artık DiceManager.dice_roll_started'ı dinliyor. Burada yalnız dosyaların
	# tarayıcı tarafından doğru anahtara ("dice/throw") gruplandığı doğrulanır.
	t.ok(AudioManager.has_sfx_event(&"dice/throw"), "dice/throw SFX event'i tarandı (throw_1/2/3.ogg)")

	# ── KÖK NEDEN KİLİDİ (2026-07-18, ikinci genel bakım turu): project.godot'ta [audio] bölümü
	# HİÇ YOKTU → default_bus_layout.tres (Music/SFX/Ambient bus'ları tanımlayan dosya) hiçbir zaman
	# yüklenmiyordu, AudioServer'da yalnız "Master" bus'ı vardı. Sonuç: Ayarlar'daki Music/SFX/
	# Ambient sliderları AudioServer.get_bus_index(...)==-1 olduğu için SESSİZCE NO-OP oluyordu
	# (yalnız Master slider çalışıyordu) — TÜM sesler (müzik/SFX/zar dahil) sessizce Master'a
	# yönlendiriliyordu (Godot: var olmayan bus adına atama → otomatik Master'a düşer, hata vermez).
	# Fix: project.godot'a `[audio] buses/default_bus_layout="res://default_bus_layout.tres"` eklendi.
	t.ok(AudioServer.get_bus_index("Music") != -1,
		"Music bus'ı AudioServer'da kayıtlı (project.godot [audio] regresyon kilidi)")
	t.ok(AudioServer.get_bus_index("SFX") != -1,
		"SFX bus'ı AudioServer'da kayıtlı (Ayarlar'daki SFX slider'ı artık gerçekten çalışır)")
	t.ok(AudioServer.get_bus_index("Ambient") != -1,
		"Ambient bus'ı AudioServer'da kayıtlı (Ayarlar'daki Ambient slider'ı artık gerçekten çalışır)")
	t.eq(AudioServer.bus_count, 4, "Toplam 4 bus (Master + Music + SFX + Ambient) — fazla/eksik yok")

	# ── Güvenlik: boş/eksik içerikte çökmeden no-op ──
	t.ok(not AudioManager.has_sfx_event(&"olmayan/ses"), "bilinmeyen SFX event yok")
	AudioManager.play_sfx_event(&"olmayan/ses")  # çökmemeli
	AudioManager.play_sfx(null)                   # null stream → no-op
	AudioManager.next_track()                     # aktif playlist yokken güvenli
	AudioManager.prev_track()
	t.ok(true, "boş içerikte ses çağrıları güvenli (no-op, çökme yok)")
