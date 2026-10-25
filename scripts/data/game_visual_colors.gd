class_name GameVisualColors
extends Resource

## TEK ERİŞİM NOKTASI — projedeki tüm görsel renkler bu tek .tres'ten okunur.
## Eskiden 6 ayrı script `preload("res://assets/data/game_visual_colors.tres")` tekrarlıyordu;
## artık hepsi `GameVisualColors.get_colors()` çağırır → path tek yerde, typo/drift riski yok.
##
## KAYNAK ZİNCİRİ: Bu .tres'i `scripts/ui/theme/gothic_theme_builder.gd` (SceneTree dev-tool)
## ÜRETİR — renk sabitleri orada tanımlıdır. Renk değiştirmek için .tres'i elle düzenleme,
## builder'daki değerleri değiştirip `godot -s scripts/ui/theme/gothic_theme_builder.gd` çalıştır.
## (load: bu script kendi .tres'ini preload edemez — döngü olur; load ResourceLoader'da önbelleklenir.)
const RESOURCE_PATH := "res://assets/data/game_visual_colors.tres"

static func get_colors() -> GameVisualColors:
	return load(RESOURCE_PATH)

@export_category("Faction Unit Colors")
@export var unit_heretic: Color = Color(0.5, 0.05, 0.05)
@export var unit_anointed: Color = Color(0.12, 0.45, 0.6)
@export var unit_pilgrims: Color = Color(0.78, 0.58, 0.15)
@export var unit_default: Color = Color(0.72, 0.68, 0.62)

# ── HAREKET ALANI (MOVEMENT) — tüm faction/unit için AYNI, açık nötr gri ──
# Hareket ve menzil aynı görsel dili kullanır ama farklı gri tonuyla ayrışır (karışmasın).
# Hareket = AÇIK gri (calm, geniş alan).
@export_category("Faction Path Range Colors")
@export var path_heretic: Color = Color(0.66, 0.69, 0.72)
@export var path_anointed: Color = Color(0.66, 0.69, 0.72)
@export var path_pilgrims: Color = Color(0.66, 0.69, 0.72)
@export var path_default: Color = Color(0.86, 0.72, 0.46)

# ── MENZİL ALANI (ATTACK/CHARGE RANGE) — tüm faction/unit için AYNI, koyu nötr gri ──
# Menzil = KOYU gri; hareketin açık grisinden net ayrışır, sade ve profesyonel.
@export_category("Faction Circle Range Colors")
@export var circle_heretic: Color = Color(0.40, 0.41, 0.43)
@export var circle_anointed: Color = Color(0.40, 0.41, 0.43)
@export var circle_pilgrims: Color = Color(0.40, 0.41, 0.43)
@export var circle_default: Color = Color(0.40, 0.41, 0.43)

@export_category("Selection Colors")
@export var selection_selected: Color = Color(0.85, 0.05, 0.05, 0.8)
@export var selection_targeted: Color = Color(0.95, 0.15, 0.15, 0.8)
## Geçerli hedef vurgusu (attack/charge seçiliyken menzildeki düşman) — sade, açık nötr.
@export var selection_valid_target: Color = Color(0.88, 0.86, 0.78, 0.6)
## P2-5: geçerli menzilli hedef SİPERDE (Cover) ise halka bu amber renkte gösterilir —
## oyuncu −1 DICE Cover cezasını saha üzerinde görür (Atış Breakdown Kartı LOS_COVER ile aynı ton).
@export var selection_cover: Color = Color(0.83, 0.72, 0.42, 0.7)

@export_category("Damage Flash")
@export var damage_flash: Color = Color(0.9, 0.1, 0.1)

@export_category("Deployment Zone Overlay")
## Yerleştirme bölgelerini haritada gösteren yuvarlak köşeli halka (game.gd → Decal, _deploy_zone_texture).
## Sahip belirlenene kadar nötr ton; belirlenince game.gd::_refresh_zone_colors bunu ilgili
## oyuncunun FactionData.team_color'ıyla (aynı alfa korunarak) değiştirir.
@export var deploy_zone_neutral: Color = Color(0.82, 0.68, 0.32, 0.22)
