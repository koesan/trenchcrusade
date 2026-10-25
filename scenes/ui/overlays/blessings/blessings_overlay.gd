extends OverlayPanel


@onready var rules_desc = %RulesDesc
@onready var rules_title = $Panel/Margin/HBox/RulesVBox/RulesTitle
@onready var miracles_title = $Panel/Margin/HBox/MiraclesVBox/MiraclesTitle
@onready var close_btn = $Panel/Margin/HBox/MiraclesVBox/CloseBlessingsBtn
@onready var blessing_list: VBoxContainer = %BlessingList

func _bind_controls() -> void:
	close_btn.pressed.connect(func(): close_pressed.emit())

func update_locale(_new_lang: String = "") -> void:
	rules_title.text = LocalizationManager.tr_t("FACTION_RULES")
	miracles_title.text = LocalizationManager.tr_t("BLESSINGS")
	close_btn.text = LocalizationManager.tr_t("BACK")
	populate_blessings()

## OverlayManager.open_overlay() her açılışta bunu çağırır (has_method kontrolü). Bunsuz liste
## yalnız _ready()'de (HUD kurulurken, henüz hiçbir birim yerleştirilmeden ÖNCE) dolduruluyordu
## ve bir daha ASLA yenilenmiyordu — savaş ortasında açılan Blessings "tamamen boş" görünüyordu
## (kullanıcı bildirimi). Roster'daki aynı düzeltmeyle birlikte.
func open_panel() -> void:
	populate_blessings()

func populate_blessings() -> void:
	if Engine.is_editor_hint():
		return
		
	var local_id = NetworkManager.get_local_canonical_id()
	var faction = GameState.get_faction_for_player(local_id)
	
	if faction:
		# TEK KAYNAK: FactionData.faction_rule_summary zaten localization anahtarını taşır
		# (ör. "FACTION_TRENCH_PILGRIMS_RULES"). Faction başına dallanmaya gerek yok.
		# has_faction_rule=false ise faction_rule_summary'nin metnini GÖSTERMEYİZ — o metin
		# gerçek bir mantık BEKLER (bkz. faction_rules.gd başlık yorumu) ve henüz yoksa/motoruna
		# bağlanmadıysa oyuncuya olmayan bir mekaniği varmış gibi anlatmak yanıltıcı olur (P0-7'nin
		# asıl amacı buydu; bayrak QA denetiminde tek başına hiçbir yeri etkilemediği tespit edildi).
		var key: String = "FACTION_RULE_NOT_AVAILABLE_DESC"
		if faction.has_faction_rule and not faction.faction_rule_summary.is_empty():
			key = faction.faction_rule_summary
		rules_desc.text = LocalizationManager.tr_t(key)
	else:
		rules_desc.text = LocalizationManager.tr_t("NO_FACTION_SELECTED")

	_populate_blessing_markers(local_id)

const BLESSING_ROW_SCENE = preload("res://scenes/ui/overlays/blessings/blessing_row_item.tscn")

## Sağdaki "BLESSINGS" listesi: uydurma büyü/mucize butonları yerine (kaldırıldı — hiçbir
## gerçek mekanizmaya bağlı değildi) her dost birimin GERÇEK Nimet İşareti sayısını gösterir
## (Success Roll'a +1 Dice için harcanabilir — bkz. CombatChoice.request_blessing_spend_on_success).
func _populate_blessing_markers(local_id: int) -> void:
	if not is_instance_valid(blessing_list):
		return
	# MİMARİ DÜZELTME (kullanıcı isteği): "boş durum" etiketi SABİT/tek bir yapı — artık .tscn'de
	# tanımlı (%EmptyLabel), kod yalnız gösterip/gizliyor. Temizleme döngüsü onu ATLAR (dice_bar.gd
	# ile AYNI desen — total_lbl'i atlayıp yalnız dinamik satırları temizlemesi).
	var empty_lbl: Label = %EmptyLabel
	for child in blessing_list.get_children():
		if child != empty_lbl:
			child.queue_free()

	var any_unit := false
	for unit in UnitQuery.roster_of(local_id):
		any_unit = true
		var row = BLESSING_ROW_SCENE.instantiate()
		blessing_list.add_child(row)
		row.setup(unit)

	empty_lbl.text = LocalizationManager.tr_t("NO_FACTION_SELECTED")
	empty_lbl.visible = not any_unit
