extends Control
class_name RoundMedallion

## UI redesign (2026-07-18) — kullanıcı isteği: "Top Bar'ın tam ortasına evrene uygun kaliteli
## bir panel ekle. Panelde mevcut round rakamı yer alsın. Üzerine gelindiğinde mevcut tur ve fazı
## açıklayan kısa bir tooltip açılsın." Bu bileşen, top_bar.gd'nin eski kalabalık StatusLabel'ında
## dağınık duran "hazır birim sayısı" / "inisiyatif sahibi" / "ayakta oran" bilgilerini de
## TEK bir hover-tooltip altında topluyor (üst bar sürekli görünen kısmı sadeleşiyor).
##
## Kullanıcının sağladığı gerçek asset (round_medallion_banner.png) kullanılıyor.
##
## KÖK NEDEN (canlı bildirimler: "çok devasa", sonra "gereksiz boşluklar var"): bu sahne eskiden
## bir PanelContainer'ın (TopBar) çocuğuydu ve PanelContainer TÜM Control çocuklarını
## `fit_child_in_rect()` ile zorla geriyordu. O dönem `top_level = true` ile bu zorlamadan
## kaçınılmıştı. top_bar.tscn artık PanelContainer DEĞİL, düz bir Control (bkz. top_bar.gd'deki
## mimari notu) — bu yüzden `top_level` KALDIRILDI (2026-07-18, kaymışlık düzeltmesi):
## top_level=true, düğümü ebeveyninin (TopBar) konum ofsetinden de TAMAMEN koparıyordu (sadece
## boyuttan değil), bu da TopBar bir MarginContainer içine yerleştiğinde (bkz. game_hud.tscn,
## 15px kenar boşluğu) RoundMedallion'ın gerçek merkezden ~15px kaymasına yol açıyordu.
## top_bar.tscn artık container olmadığı için bu koruma gereksiz; normal anchor/offset yeterli.
##
## 5. TUR (kullanıcı isteği, 2026-07-18): "üst barı kaldırsak... ortada sadece RoundMedallion olur,
## biraz daha büyük ve geniş." Madalyon round rakamını (NumberLabel) ve faz metnini (PhaseLabel)
## gösterir.
##
## 9. TUR (kullanıcı isteği, 2026-07-19): "MedallionMenuButton bu butonlar round_medallion.tscn
## burada RoundMedallion'ın içinde olacağına top_bar.tscn'de ayrı öğeler olsunlar." Menü/Nizamlar/
## Gazavat Hedefleri/Kaynaklar butonları artık RoundMedallion'ın İÇİNDE DEĞİL — top_bar.tscn'in
## KENDİ düz çocukları (bkz. top_bar.gd). Gerekçe: bu butonlar madalyonun içindeyken düzenlemek
## için önce round_medallion.tscn alt-sahnesine girmek gerekiyordu — bu da kullanıcının sürükleme
## denemelerinde defalarca butonları görünmez konumlara kaydırmasına yol açtı (RoundMedallion'ın
## kendi 118px yüksekliğinin ÇOK dışına taşan offset'ler). top_bar.tscn'in düz bir Control olması
## sayesinde (bkz. top_bar.gd'deki mimari notu) artık bu 4 buton da TopBar'ın diğer tüm öğeleri
## (RoundMedallion, RoundWinBadge'ler, StatusLabel) gibi AYNI düzeyde, aynı anda
## görünür ve serbestçe sürüklenebilir.

@onready var number_label: Label = %NumberLabel
@onready var phase_label: Label = %PhaseLabel

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not Engine.is_editor_hint():
		# BUG (canlı log, 2026-07-18): locale_changed bir String argümanıyla emit ediliyor;
		# _refresh() parametresiz olduğundan doğrudan bağlanınca "Method expected 0 argument(s),
		# but called with 1" hatası veriyordu. Diğer tüm update_locale(_new_lang="") desenleriyle
		# AYNI şekilde bir lambda ile sarmalandı.
		LocalizationManager.locale_changed.connect(func(_l): _refresh())
		TurnManager.round_started.connect(func(_r): _refresh())
		TurnManager.phase_changed.connect(func(_p): _refresh())
		TurnManager.turn_changed.connect(func(_p): _refresh())
		TurnManager.player_shaken_changed.connect(func(_id, _s): _refresh())
		_refresh()

func _squad_name(pid: int) -> String:
	return PlayerLabel.name_of(pid)

func _refresh() -> void:
	if not is_instance_valid(number_label):
		return
	number_label.text = str(TurnManager.current_round)

	var phase_txt: String = LocalizationManager.tr_t(TurnManager.phase_display_key())
	if is_instance_valid(phase_label):
		phase_label.text = phase_txt

	var lines: Array = []
	lines.append("%s %d — %s" % [LocalizationManager.tr_t("TURN_PREFIX"), TurnManager.current_round, phase_txt])

	if TurnManager.initiative_winner_id > 0:
		lines.append("%s: %s" % [LocalizationManager.tr_t("INITIATIVE_HOLDER"), _squad_name(TurnManager.initiative_winner_id)])

	var active_id: int = TurnManager.current_turn_player_id
	if active_id > 0:
		var ready_active: int = TurnManager.get_ready_unit_count(active_id)
		lines.append("%s %s (%s: %d)" % [LocalizationManager.tr_t("TURN_ORDER"), _squad_name(active_id),
			LocalizationManager.tr_t("UNITS_READY"), ready_active])

	for pid in TurnManager.get_players():
		var standing: int = TurnManager.get_total_unit_count(pid)
		var initial: int = TurnManager.player_starting_unit_counts.get(pid, standing)
		var seg := "%s: %d/%d" % [_squad_name(pid), standing, initial]
		if TurnManager.is_shaken(pid):
			seg += " ⚠ " + LocalizationManager.tr_t("SHAKEN_BADGE")
		lines.append(seg)

	tooltip_text = "\n".join(lines)
