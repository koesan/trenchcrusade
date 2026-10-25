## BİRİME ÖZEL ("custom") YETENEK KAYIT DEFTERİ — ability_id → handler script'i.
##
## NEDEN VAR: `ability_executor.gd` iki ayrı elle-bakımlı listeyi aynı anda tutuyordu —
##   1. `CUSTOM_IMPLEMENTED` dizisi (butonun görünüp görünmeyeceğini belirler),
##   2. `_handle_custom()` içindeki dev `match ability.ability_id` dalı (asıl çağrı).
## İkisi ayrı ayrı güncelleniyordu; biri diğerinden SAPARSA ya "hiçbir şey yapmayan buton"
## ya da "uygulanmış ama hiç gösterilmeyen yetenek" doğuyordu. Artık TEK KAYNAK burası:
## `CUSTOM_IMPLEMENTED` bu sözlüğün anahtarlarından TÜRETİLİR, sapma matematiksel olarak
## imkânsızdır.
##
## YENİ YETENEK EKLEME (kural: mevcut hiçbir dosyaya dokunmadan):
##   1. `abilities/custom/<ability_id>.gd` yaz — `static func apply(ctx: AbilityContext) -> bool`
##      (dönüş: aktivasyon bitsin mi). İstersen `static func validate(ctx) -> String` de ekle
##      ("" = geçerli; dolu string = ret sebebi).
##   2. Aşağıdaki `CUSTOM` sözlüğüne 1 satır ekle.
##   3. `.tres`te `effect_type = "custom"` ve `ability_id` aynı olsun.
## Not: `effect_type` VERİ ODAKLI olan (blessing/teleport/add_blood/...) yeteneklerde kod
## gerekmez — bkz. `ability_effects.gd`.
##
## `preload` kullanılır (runtime `load` değil): yol yanlışsa parse HATA verir, sessizce null
## dönmez; ayrıca export'ta kaynak bağımlılığı görünür kalır.
class_name AbilityRegistry

const CUSTOM := {
	&"ammunition_sacrament": preload("res://scripts/rules/abilities/custom/ammunition_sacrament.gd"),
	&"burning_inferno": preload("res://scripts/rules/abilities/custom/burning_inferno.gd"),
	&"defuse_mine": preload("res://scripts/rules/abilities/custom/defuse_mine.gd"),
	&"devour_the_guilty": preload("res://scripts/rules/abilities/custom/devour_the_guilty.gd"),
	&"elemental_change": preload("res://scripts/rules/abilities/custom/elemental_change.gd"),
	&"enforced_orthodoxy": preload("res://scripts/rules/abilities/custom/enforced_orthodoxy.gd"),
	&"fortify": preload("res://scripts/rules/abilities/custom/fortify.gd"),
	&"left_hand_path": preload("res://scripts/rules/abilities/custom/left_hand_path.gd"),
	&"purge": preload("res://scripts/rules/abilities/custom/purge.gd"),
	&"set_mine": preload("res://scripts/rules/abilities/custom/set_mine.gd"),
	&"shadow_walker": preload("res://scripts/rules/abilities/custom/shadow_walker.gd"),
	&"slavemaster": preload("res://scripts/rules/abilities/custom/slavemaster.gd"),
	&"temporal_assassin": preload("res://scripts/rules/abilities/custom/temporal_assassin.gd"),
	&"trample": preload("res://scripts/rules/abilities/custom/trample.gd"),
	&"trigger_martyrdom_device": preload("res://scripts/rules/abilities/custom/trigger_martyrdom_device.gd"),
	&"vengeful_scripture": preload("res://scripts/rules/abilities/custom/vengeful_scripture.gd"),
	&"voice_of_god": preload("res://scripts/rules/abilities/custom/voice_of_god.gd"),
}

## Bu ability_id için kayıtlı handler (yoksa null).
static func handler_for(ability_id: StringName) -> GDScript:
	return CUSTOM.get(ability_id, null)

## Handler'ı BULUNAN custom yetenek kimlikleri.
## `AbilityExecutor` bunu "buton üretilebilir mi" ve "boşa aktivasyon harcatma" kararlarında
## kullanır — uygulanmamış bir custom yetenek asla tıklanabilir bir butona dönüşmez.
static func implemented_ids() -> Array:
	return CUSTOM.keys()

static func is_implemented(ability_id: StringName) -> bool:
	return CUSTOM.has(ability_id)
