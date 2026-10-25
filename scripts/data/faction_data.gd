## Faksiyon tanımı Resource sınıfı.
## Her faksiyon için takım rengi, kullanılabilir birim türleri ve görünen ad tanımlar.
## Yeni faksiyon eklemek script düzenlemesi gerektirmez.
class_name FactionData
extends Resource

@export var faction_id: StringName = &""
@export var display_name: String = ""
@export var team_color: Color = Color.WHITE

## HİZALAMA (choosing-a-faction.md): "All Warbands are either FAITHFUL or FALLEN...
## a Warband cannot include models of the opposing alignment." Kural mantığı AlignmentRules'ta.
## 0 = UNSET, 1 = FAITHFUL, 2 = FALLEN
@export var alignment: int = 0
@export var available_units: Array[Resource] = []

## Bu faksiyonun **Armoury Tablosu** (compendium: her faksiyonun kendi tablosu vardır).
## Yalnızca burada listelenen Battlekit kalemleri satın alınabilir — `ArmouryRules` denetler.
## Veri `tools/generate_armoury.py` ile compendium'dan üretilir; elle düzenlenmez.
@export var armoury: Array[Resource] = []

## Faksiyon logosu (UI'da faction seçim / codex / kart için). Tek kaynak: burada.
## Eskiden GameState.faction_logos sözlüğünde hardcoded'du — artık FactionData taşıyor.
@export var logo: Texture2D

## Bu faksiyonun eski/kısa kimlik takma adları (ör. heretic_legion için &"heretic" ve
## &"anointed"). Kod içinde kısa id ile arama yapıldığında canonical faction'a çözülür;
## böylece dağınık "id normalizasyonu" gerekmez. Boş olabilir.
@export var aliases: Array[StringName] = []

# ── FAKSİYON PASİF KURALI ────────────────────────────────────────────────────
@export_group("Faction Rule")

## Bu faksiyonun army-wide bir pasif kuralı (compendium'daki "Faction Rules" bölümü) var mı?
## Tüm faksiyonlarda bulunmaz — sadece bazı warband dosyalarında "## Faction Rules" başlığı var.
@export var has_faction_rule: bool = false

## Pasifin kısa açıklaması (UI/tooltip için). Gerçek mekanik FactionRules.apply_*() içinde uygulanır.
@export var faction_rule_summary: String = ""


# ── ORDER OF THE FLY (Cult of the Black Grail) ───────────────────────────────
## Compendium: "When your warband is created, you must choose whether it will be led by a
## Lord of Tumours or a Plague Knight." Seçim, hem hangi liderin ZORUNLU olduğunu hem de
## Lord/Plague Knight adet tavanlarını belirler (kural mantığı: RosterRules).
## Bu alan YALNIZCA faction_id == "cult_of_the_black_grail" için anlamlıdır.
@export_group("Order of the Fly")

## Seçilen liderlik dalı. İzin verilen değerler LEADER_CHOICES anahtarlarıdır.
@export var leader_choice: StringName = &""

## Liderlik dalları — seçim UI'ı ve doğrulama için TEK KAYNAK (SEVEN_DEADLY_SINS ile aynı desen).
const LEADER_CHOICES: Dictionary = {
	&"lord": {
		"display_name": "ORDER_OF_FLY_LORD",
		"desc": "ORDER_OF_FLY_LORD_DESC",
	},
	&"knight": {
		"display_name": "ORDER_OF_FLY_KNIGHT",
		"desc": "ORDER_OF_FLY_KNIGHT_DESC",
	},
}

# ── SEVEN DEADLY SINS (Court of the Seven-Headed Serpent) ────────────────────────
## Compendium: "When a player creates their warband they must choose one of the Seven
## Deadly Sins for their warband. The choice of Sin determines Goetic Powers, Praetor
## abilities, and the Desecrated Saint's Demonic Aura."
## Bu alan YALNIZCA faction_id == "court_of_seven_headed_serpent" için anlamlıdır.
## Diğer faksiyonlarda boş kalır (&"").
@export_group("Seven Deadly Sins")

## Seçilen günah (warband oluşturma sırasında belirlenir). İzin verilen değerler
## SEVEN_DEADLY_SINS sabitindeki anahtarlardır.
@export var selected_sin: StringName = &""

## Yedi Ölümcül Günah — her birinin mekanik etkileri FactionRules ve AbilityExecutor'da
## uygulanacaktır. Bu sabit, seçim UI'ı ve doğrulama için tek kaynaktır.
## Değerler: {sin_id: {display_name, demonic_aura_desc, goetic_power_filter}}
const SEVEN_DEADLY_SINS: Dictionary = {
	&"pride": {
		"display_name": "SIN_PRIDE",
		"demonic_aura": "pride_aura",
		"demonic_aura_desc": "SIN_PRIDE_AURA"
	},
	&"greed": {
		"display_name": "SIN_GREED",
		"demonic_aura": "greed_aura",
		"demonic_aura_desc": "SIN_GREED_AURA"
	},
	&"lust": {
		"display_name": "SIN_LUST",
		"demonic_aura": "lust_aura",
		"demonic_aura_desc": "SIN_LUST_AURA"
	},
	&"envy": {
		"display_name": "SIN_ENVY",
		"demonic_aura": "envy_aura",
		"demonic_aura_desc": "SIN_ENVY_AURA"
	},
	&"gluttony": {
		"display_name": "SIN_GLUTTONY",
		"demonic_aura": "gluttony_aura",
		"demonic_aura_desc": "SIN_GLUTTONY_AURA"
	},
	&"wrath": {
		"display_name": "SIN_WRATH",
		"demonic_aura": "wrath_aura",
		"demonic_aura_desc": "SIN_WRATH_AURA"
	},
	&"sloth": {
		"display_name": "SIN_SLOTH",
		"demonic_aura": "sloth_aura",
		"demonic_aura_desc": "SIN_SLOTH_AURA"
	},
}
