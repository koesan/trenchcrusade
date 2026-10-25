class_name PlayerLabel
extends RefCounted

## Oyuncunun ekranda görünen adı — TEK KAYNAK.
##
## NEDEN: aynı oyuncu ekranın farklı yerlerinde "Commander 1", "Squad 2", "Sacred Squad 2" ve
## faksiyon adı olarak dört farklı biçimde yazılıyordu (2026-10-23 ekran görüntüsü denetimi).
## Kural: faksiyon seçildiyse faksiyon adı; seçilmediyse "Savaş Grubu N" (Trench Crusade'in
## kendi terimi: Warband). İki oyuncu aynı faksiyonu seçtiyse ayırt etmek için numara eklenir.

static func generic(player_id: int) -> String:
	return LocalizationManager.tr_t("PLAYER_WARBAND_FMT") % player_id

static func name_of(player_id: int) -> String:
	var faction = GameState.get_faction_for_player(player_id)
	if faction == null:
		return generic(player_id)
	var fname := faction_name(faction)
	var other = GameState.get_faction_for_player(2 if player_id == 1 else 1)
	if other != null and other.faction_id == faction.faction_id:
		return "%s (%d)" % [fname, player_id]
	return fname

static func faction_name(faction: Resource) -> String:
	return LocalizationManager.tr_t("FACTION_" + String(faction.faction_id).to_upper())
