extends Control
class_name GameTopBar

## ÜST BAR: ortada tur madalyonu (tur rakamı + faz), iki köşede tur kazanma rozetleri, altında
## faz/sıra satırı (koyu şerit üzerinde), sağ kenarda ikonlu sistem butonları (Menü, Kayıtlar,
## Hedefler, Kaynaklar, Savaş Günlüğü). Hangi butonun hangi aşamada görüneceği `apply_phase`te — tek kaynak.
##
## Kök düz bir Control'dür (Container değil): her öğe kendi anchor/offset'iyle editörde serbestçe
## konumlandırılabilir (kullanıcı isteği, 2026-07-18).
## "Aktivasyonu bitir" 2026-10-24 yeniden tasarımında komuta paneline (command_bar) taşındı.
signal chronicles_pressed
signal pause_pressed
signal objectives_pressed
signal resources_pressed
signal log_pressed

@onready var status_label = $StatusLabel
@onready var round_medallion = %RoundMedallion
@onready var round_win_badge_left = %RoundWinBadgeLeft
@onready var round_win_badge_right = %RoundWinBadgeRight
@onready var menu_btn: Button = %MenuButton
@onready var chronicles_btn: Button = %ChroniclesButton
@onready var objectives_btn: Button = %ObjectivesButton
@onready var resources_btn: Button = %ResourcesButton
@onready var log_btn: Button = %LogButton
## Faz + sıra satırının arkasındaki koyu şerit — metin 3B arazinin üstünde kaybolmasın.
@onready var _status_band: TextureRect = %StatusBand

# Durum satırındaki BBCode renkleri artık gothic_theme.tres "Constants" tipinden okunuyor
# (tek kaynak — bkz. gothic_theme_builder.gd COLOR_HIGHLIGHT_GOLD/ALERT_RED/DIM_TEXT).
var COL_GOLD := "d4af37"
var COL_RED := "c0392b"
var COL_DIM := "9a8f80"

func _ready():
	COL_GOLD = get_theme_color("color_highlight_gold", "Constants").to_html(false)
	COL_RED = get_theme_color("color_alert_red", "Constants").to_html(false)
	COL_DIM = get_theme_color("color_dim_text", "Constants").to_html(false)
	menu_btn.pressed.connect(func(): pause_pressed.emit())
	chronicles_btn.pressed.connect(func(): chronicles_pressed.emit())
	objectives_btn.pressed.connect(func(): objectives_pressed.emit())
	resources_btn.pressed.connect(func(): resources_pressed.emit())
	log_btn.pressed.connect(func(): log_pressed.emit())
	menu_btn.tooltip_text = LocalizationManager.tr_t("MENU")
	chronicles_btn.tooltip_text = LocalizationManager.tr_t("CHRONICLES_TITLE")
	objectives_btn.tooltip_text = LocalizationManager.tr_t("OBJECTIVES")
	resources_btn.tooltip_text = LocalizationManager.tr_t("RESOURCES")
	log_btn.tooltip_text = LocalizationManager.tr_t("BATTLE_LOG_TITLE")
	if not Engine.is_editor_hint():
		# Round-kazanma rozetleri artık TopBar'ın kendi sahnesinde yaşıyor (bkz. yukarıdaki
		# mimari not) — sabit Oyuncu 1 (sol) / Oyuncu 2 (sağ), "Squad 1/2" ile AYNI sabit kimlik.
		if is_instance_valid(round_win_badge_left):
			round_win_badge_left.set_player(1)
		if is_instance_valid(round_win_badge_right):
			round_win_badge_right.set_player(2)
	# Tur/faz/durum değiştikçe otomatik yenile.
	TurnManager.turn_changed.connect(func(_p): update_top_bar())
	TurnManager.round_started.connect(func(_r): update_top_bar())
	TurnManager.phase_changed.connect(func(_ph): update_top_bar())
	TurnManager.player_shaken_changed.connect(func(_id, _s): update_top_bar())
	GameState.game_phase_changed.connect(func(_ph): update_top_bar())

func _get_local_player_id() -> int:
	return NetworkManager.get_local_canonical_id()

func _squad_name(pid: int) -> String:
	return PlayerLabel.name_of(pid)

## UI redesign (2026-07-18) — kullanıcı isteği: "arayüz sade, okunabilir olsun; gereksiz
## bilgilerden kaçın." Round numarası VE faz metni artık RoundMedallion'da (üst bar tam ortası);
## "hazır birim sayısı"/"inisiyatif sahibi"/"ayakta oran" bilgileri RoundMedallion'ın
## hover-tooltip'ine taşındı (bkz. round_medallion.gd) — hiçbir bilgi kaybolmadı. Bu tek
## DURUM satırında yalnız "sıradaki oyuncu + Shaken uyarısı" kalıyor (madalyonun hemen altında).
## Aktivasyon özeti (ActivationCues.refresh_all): durum satırına "Aktif model: X" ya da
## "N model hazır" eklenir — oyuncu sırasında kimi oynatabileceğini satırdan da okur.
var _activation_summary: Dictionary = {}
func set_activation_summary(summary: Dictionary) -> void:
	var active = summary.get("active")
	var key := "%s|%d" % [active.get_instance_id() if is_instance_valid(active) else 0, int(summary.get("ready", 0))]
	if key == str(_activation_summary.get("key", "")):
		return
	_activation_summary = summary.duplicate()
	_activation_summary["key"] = key
	update_top_bar()

func update_top_bar():
	var active_id = TurnManager.current_turn_player_id

	# ── SCENARIO_SELECT & DEPLOYMENT ─────────────────────────────────────────
	# Savaş öncesi aşamaların her birinin kendi paneli (senaryo/faksiyon/yerleştirme/armoury)
	# zaten başlık ve yönerge taşıyor. Eski sabit "harita bölgesine tıkla" satırı senaryo ve
	# faksiyon seçiminde de görünüyordu (yanlış yönerge) ve haritanın üstünde arka plansız
	# yüzüyordu — savaş dışında durum satırı gizlenir.
	if GameState.game_phase != GameState.GamePhase.BATTLE:
		status_label.visible = false
		_status_band.visible = false
		set_round_indicators_visible(false)
		return

	set_round_indicators_visible(true)
	status_label.visible = true
	_status_band.visible = true

	# ── DURUM SATIRI: sıradaki oyuncu + Shaken uyarısı (yalnızca sarsılan taraf varsa) ────
	var parts: Array = []
	parts.append("%s [color=%s]%s[/color]" % [
		LocalizationManager.tr_t("TURN_ORDER"), COL_GOLD, _squad_name(active_id)])
	var active_unit = _activation_summary.get("active")
	if is_instance_valid(active_unit):
		parts.append(LocalizationManager.tr_t("STATUS_ACTIVE_UNIT") % ("[color=%s]%s[/color]" % [COL_GOLD, active_unit.display_name]))
	elif int(_activation_summary.get("ready", 0)) > 0:
		parts.append("[color=%s]%s[/color]" % [COL_DIM, LocalizationManager.tr_t("STATUS_READY_COUNT") % int(_activation_summary["ready"])])
	for pid in TurnManager.get_players():
		if TurnManager.is_shaken(pid):
			parts.append("[color=%s]⚠ %s %s[/color]" % [COL_RED, _squad_name(pid), LocalizationManager.tr_t("SHAKEN_BADGE")])

	status_label.text = "[center]" + "   ·   ".join(parts) + "[/center]"

## AŞAMA → GÖRÜNÜR SİSTEM BUTONLARI (tek kaynak). Eskiden Hedefler/Kaynaklar butonları senaryo
## ve faksiyon seçiminde de görünüyordu; o aşamalarda anlamları yoktu.
##   Senaryo seçimi / Armoury : yalnız Menü
##   Yerleştirme              : Menü · Kayıtlar · Hedefler (konuşlanırken hedefleri görmek gerekir)
##   Savaş                    : hepsi
## "Aktivasyonu bitir" artık komuta panelinde (command_bar) — üst barda değil.
func apply_phase(phase: int) -> void:
	var GP = GameState.GamePhase
	menu_btn.visible = true
	chronicles_btn.visible = phase == GP.DEPLOYMENT or phase == GP.BATTLE
	objectives_btn.visible = phase == GP.DEPLOYMENT or phase == GP.BATTLE
	resources_btn.visible = phase == GP.BATTLE
	log_btn.visible = phase == GP.BATTLE
	update_top_bar()

## Round-kazanma rozetleri VE ortadaki RoundMedallion yalnızca SAVAŞ (BATTLE) fazında görünür.
##
## NOT (2026-07-29 denetimi): `round_medallion.gd` bir zamanlar "madalyonun KENDİSİ her zaman
## görünür kalmalı, yalnız iki label gizlenmeli" diyen `set_round_info_visible()` fonksiyonunu
## taşıyordu — çünkü ESKİ tasarımda Menü/Nizamlar butonları madalyonun üzerindeydi. O butonlar
## 2026-07-17 üst-bar yeniden düzeninde TopBar'a taşındı; madalyonda gizlenmesi sakıncalı bir
## şey kalmadı. Fonksiyon hiç çağrılmıyordu ve yorumu bu koddaki davranışla ÇELİŞİYORDU
## (kafa karıştırıcı bir "iki doğru" durumu); silindi. Tek geçerli davranış: aşağıdaki.
func set_round_indicators_visible(v: bool) -> void:
	if is_instance_valid(round_medallion):
		round_medallion.visible = v
	if is_instance_valid(round_win_badge_left):
		round_win_badge_left.visible = v
	if is_instance_valid(round_win_badge_right):
		round_win_badge_right.visible = v
