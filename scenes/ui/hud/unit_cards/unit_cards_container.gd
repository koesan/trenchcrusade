extends VBoxContainer
class_name UnitCardsContainer

## KADRO LİSTESİ — savaşta ekranın sol kenarı: sırası gelen oyuncunun modelleri, okunur satırlar
## hâlinde (durum ikonu · ad · kan işareti). Satıra tıklamak birimi seçer; üzerine gelince
## ayrıntılı bilgi kartı açılır.
##
## Eski hâli alttaki 120 px'lik 3B kart şeridiydi: adlar küçük ve sönüktü, kartlar her tur
## yıkılıp 3B önizlemeleriyle yeniden kuruluyordu. Satırlar artık oyuncu değişmedikçe korunur;
## `update_realtime` yalnız değişen satırı günceller.

signal card_hover_started(unit: Node, card: Control)
signal card_hover_ended

const ROW_SCENE := preload("res://scenes/ui/hud/unit_cards/roster_row.tscn")

@onready var _title: Label = %Title
@onready var cards_container: VBoxContainer = %CardsContainer

## Listenin hangi oyuncuya ve hangi birimlere ait olduğu — değişmedikçe satırlar yeniden kurulmaz.
var _built_for := ""

func rebuild() -> void:
	if GameState.game_phase != GameState.GamePhase.BATTLE:
		visible = false
		return
	visible = true
	var player := TurnManager.current_turn_player_id
	var roster: Array = UnitQuery.roster_of(player)
	var key := str(player) + ":" + ",".join(roster.map(func(u): return str(u.get_instance_id())))
	_title.text = PlayerLabel.name_of(player)
	if key == _built_for:
		update_realtime()
		return
	_built_for = key
	for c in cards_container.get_children():
		cards_container.remove_child(c)
		c.queue_free()
	for unit in roster:
		var row = ROW_SCENE.instantiate()
		cards_container.add_child(row)
		row.setup(unit)
		row.set_meta("unit", unit)
		var u = unit
		row.pressed.connect(func(): GameState.select_unit(u))
		row.mouse_entered.connect(func(): card_hover_started.emit(u, row))
		row.mouse_exited.connect(func(): card_hover_ended.emit())
	update_realtime()

func update_realtime() -> void:
	if not visible:
		return
	for row in cards_container.get_children():
		var u = row.get_meta("unit", null)
		if not is_instance_valid(u):
			_built_for = ""
			rebuild()
			return
		row.refresh(GameState.selected_unit == u)
