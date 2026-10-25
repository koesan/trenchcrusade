extends OverlayPanel
class_name GameEndOverlay

## Zafer veya yenilgi durumunda gösterilen ortak sonuç ekranı.
## VictoryOverlay ve DefeatOverlay bileşenleri tek bir modüler yapıda birleştirildi.

signal return_pressed

var is_victory: bool = true
var local_offline: bool = false
var winner_player_id: int = 0

@onready var icon_label: Label = $Panel/Margin/VBox/Icon
@onready var title_label: Label = $Panel/Margin/VBox/Title
@onready var desc_label: Label = $Panel/Margin/VBox/Desc
@onready var return_btn: Button = $Panel/Margin/VBox/ReturnBtn
@onready var summary_label: Label = $Panel/Margin/VBox/Summary
@onready var stats: GridContainer = $Panel/Margin/VBox/Stats

func _bind_controls() -> void:
	return_btn.pressed.connect(func(): return_pressed.emit())

func setup(victory: bool, p_local_offline: bool = false, p_winner_id: int = 0) -> void:
	is_victory = victory
	local_offline = p_local_offline
	winner_player_id = p_winner_id
	if is_node_ready():
		update_locale()

func update_locale(_new_lang: String = "") -> void:
	if local_offline:
		if is_instance_valid(icon_label):
			icon_label.text = "✝"
		if is_instance_valid(title_label):
			if winner_player_id == 0:
				title_label.text = LocalizationManager.tr_t("DRAW")
			else:
				# Metin ASLA koda gömülmez. Eski hâlde "%d" içermeyen bir çeviri için
				# İngilizce bir yedek dal vardı; anahtarın biçimlendirici taşıdığı
				# localization_coverage_test ile GARANTİ altına alındığı için kaldırıldı.
				title_label.text = LocalizationManager.tr_t("PLAYER_X_VICTORY") % PlayerLabel.name_of(winner_player_id)
			title_label.theme_type_variation = &"LabelTitleLarge"
		if is_instance_valid(desc_label):
			desc_label.text = LocalizationManager.tr_t("VICTORY_DESC")
	else:
		if is_victory:
			if is_instance_valid(icon_label):
				icon_label.text = "✝"
			if is_instance_valid(title_label):
				title_label.text = LocalizationManager.tr_t("VICTORY")
				title_label.theme_type_variation = &"LabelTitleLarge"
			if is_instance_valid(desc_label):
				desc_label.text = LocalizationManager.tr_t("VICTORY_DESC")
		else:
			if is_instance_valid(icon_label):
				icon_label.text = "☠"
			if is_instance_valid(title_label):
				title_label.text = LocalizationManager.tr_t("DEFEAT")
				title_label.theme_type_variation = &"LabelTitleDefeat"
			if is_instance_valid(desc_label):
				desc_label.text = LocalizationManager.tr_t("DEFEAT_DESC")
			
	if is_instance_valid(return_btn):
		return_btn.text = LocalizationManager.tr_t("GAME_END_RETURN")

## SONUÇ TABLOSU: senaryo + oynanan tur, iki tarafın Zafer Puanı ve ayakta kalan model sayısı.
## Eskiden ekran yalnız "Zafer" başlığı ve sabit bir cümleden ibaretti — oyuncu NEDEN
## kazandığını/kaybettiğini göremiyordu. Her açılışta tazelenir (savaş sonu verisi).
func open_panel() -> void:
	var scen = ScenarioManager.active_scenario
	var scen_name: String = LocalizationManager.tr_t(scen.scenario_name_key) if scen != null else ""
	summary_label.text = LocalizationManager.tr_t("GAME_END_SUMMARY_FMT") % [scen_name, TurnManager.current_round]
	stats.get_node("Side1").text = PlayerLabel.name_of(1)
	stats.get_node("Side2").text = PlayerLabel.name_of(2)
	stats.get_node("VpLabel").text = LocalizationManager.tr_t("GAME_END_VP")
	stats.get_node("ModelsLabel").text = LocalizationManager.tr_t("GAME_END_MODELS")
	var uses_vp: bool = ScenarioManager.uses_vp_victory()
	for n in ["VpLabel", "Vp1", "Vp2"]:
		stats.get_node(n).visible = uses_vp
	for pid in [1, 2]:
		stats.get_node("Vp%d" % pid).text = str(ScenarioManager.player_vp.get(pid, 0))
		var standing: int = UnitQuery.standing(UnitQuery.of_player(pid)).size()
		var fielded: int = UnitQuery.roster_of(pid).size()
		stats.get_node("Models%d" % pid).text = "%d / %d" % [standing, fielded]

