## MineResolver — Mayın kuralları (STATELESS, saf).
##
## KURAL KAYNAĞI: iron-sultanate.md (Sultanate Sapper) ve new-antioch.md (Combat Engineer).
## İki faksiyonda da kural METNİ AYNIdır, bu yüzden tek yerde toplanır.
##
##   Set Mine:
##     "A [model] can take a Set Mine [Action] if they are in contact with a terrain piece that
##      measures up to 8" by 8" that doesn't have the [Mined] Keyword. If they do so, take a
##      Success Roll for the model and add [+2 Dice] to the roll. If the roll is a Failure,
##      nothing happens. If Success or Critical Success, the terrain piece gains [Mined]."
##
##   Defuse Mine:
##     "When you move a [model] into contact with a Marker or terrain piece with the [Mined]
##      Keyword, you can say the model will try to defuse the mine before it detonates. If you
##      do so, take a [Risky Success] Roll. If Failure the mine detonates and the model's
##      Activation ends. If Success or Critical Success, the mine does not detonate and the
##      Marker or terrain piece loses [Mined]. A model that SETS a mine on a terrain piece can
##      defuse the mine AUTOMATICALLY if it moves into contact with it (do not take a Roll)."
##
##   Detonating Mines:
##     "When a model moves into contact with a Mined terrain piece, the mine will detonate
##      UNLESS the model is the one that set the mine, or has the Defuse Mine ability. Make an
##      Injury Roll with the [Shrapnel] Keyword for the model that detonated the mine. The
##      terrain piece is then no longer considered to be Mined. If the model wasn't taken Down
##      or Out of Action, it can then continue its move. FLYING models only detonate a mine if
##      they FINISH a move in contact with a Mined terrain piece (they can fly across it)."
class_name MineResolver

## Set Mine başarı eşiği — compendium'da özel bir eşik verilmez, standart Success Roll'dur.
const SET_MINE_THRESHOLD := 7
## Set Mine bonusu: "add [+2 Dice] to the roll".
const SET_MINE_BONUS_DICE := 2

static func set_mine_threshold() -> int:
	return SET_MINE_THRESHOLD

static func set_mine_bonus_dice() -> int:
	return SET_MINE_BONUS_DICE

## Bu birim burada mayın kurabilir mi? Zaten `[Mined]` olan bir yere ikinci mayın konmaz.
static func can_set_mine(unit_data: Resource, already_mined: bool) -> bool:
	if unit_data == null:
		return false
	return not already_mined

## Bu birim Defuse Mine yapabilir mi? Yalnız `[Negate Mined]` taşıyanlar
## (Sultanate Sapper, New Antioch Combat Engineer).
static func can_defuse(unit_data: Resource) -> bool:
	return unit_data != null and KeywordSystem.has(unit_data, &"negate_mined")

## Mayını KURAN model ona tekrar temas ederse zar atılmaz — otomatik etkisizleştirir.
static func defuse_is_automatic(setter_name: String, unit_name: String) -> bool:
	return setter_name != "" and setter_name == unit_name

## Bu model bu mayını PATLATIR mı?
## Patlatmaz: (a) mayını kuran modelse, (b) Defuse Mine yeteneği (`[Negate Mined]`) varsa.
static func detonates_for(unit_data: Resource, setter_name: String, unit_name: String) -> bool:
	if unit_data == null:
		return false
	if defuse_is_automatic(setter_name, unit_name):
		return false
	if can_defuse(unit_data):
		return false
	return true

## FLYING modeller mayını yalnız hareketlerini onun ÜZERİNDE BİTİRİRSE patlatır;
## üzerinden uçup geçmek tetiklemez.
## is_move_end: bu kontrol hareketin SONUNDA mı yapılıyor?
static func flying_triggers(unit_data: Resource, is_move_end: bool) -> bool:
	if unit_data == null:
		return true
	if KeywordSystem.has(unit_data, &"flying"):
		return is_move_end
	return true
