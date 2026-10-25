extends Button

## Senaryo seçim kartı: senaryonun görseli + adı + tek satırlık künye (tur · zafer · hedef).
## Ayrıntılı açıklama kartın ÜSTÜNDE açılan InfoPopup'ta kalır (scenario_selection_panel.gd).
##
## NEDEN AYRI SAHNE: kart eskiden `Button.new()` + iki satır düz metindi — görsel yoktu ve
## oyuncu senaryoları ancak üzerine gelip popup okuyarak ayırt edebiliyordu.

## Fare üstündeyken görsel aydınlanır (seçilebilirlik geri bildirimi).
## (Ton yok, yalnız parlaklık — tema rengi gerektirmez.)
const ART_IDLE := Color.WHITE * 0.7
const ART_HOVER := Color.WHITE

@onready var _art: TextureRect = %Art
@onready var _title: Label = %Title
@onready var _facts: Label = %Facts

func _ready() -> void:
	mouse_entered.connect(func(): _art.modulate = ART_HOVER)
	mouse_exited.connect(func(): _art.modulate = ART_IDLE)

func setup(sdata: Resource, victory_label: String) -> void:
	_art.texture = sdata.banner
	_title.text = LocalizationManager.tr_t(sdata.scenario_name_key)
	var facts: Array[String] = [
		"%d %s" % [sdata.turn_limit, LocalizationManager.tr_t("TURNS_LABEL")],
		victory_label,
	]
	if sdata.objectives.size() > 0:
		facts.append(LocalizationManager.tr_t("SCENARIO_CARD_OBJECTIVES") % sdata.objectives.size())
	_facts.text = "  ·  ".join(facts)
