extends RefCounted

## Demonic Aura Testleri (Pride Aura ve Envy Aura).
## Kibir (Pride) Aurası: Moral Kontrolü zarına -1 DICE uygular.
## Kıskançlık (Envy) Aurası: 3" içindeki düşmanların dost yeteneklerden (Treat vb.) yararlanmasını engeller.

const MechanicsResolver = preload("res://scripts/rules/mechanics_resolver.gd")
const AbilityExecutor = preload("res://scripts/rules/ability_executor.gd")
const AbilityData = preload("res://scripts/data/ability_data.gd")
const UnitData = preload("res://scripts/data/unit_data.gd")
const FactionData = preload("res://scripts/data/faction_data.gd")

class _FakeUnit:
	extends RefCounted
	var name: String = "FakeUnit"
	var display_name: String = "Test Unit"
	var owner_id: int = 1
	var current_health: int = 10
	var is_down: bool = false
	var global_position: Vector3 = Vector3.ZERO
	var unit_data: Resource

	## AbilityExecutor._validate() bunu çağırır. Eksik olduğunda Godot "Nonexistent function"
	## hatası verip _validate'i YARIDA KESİYORDU — fonksiyon "" döndüğü için Envy aurası
	## denetimine hiç ulaşılamıyor, test de yanlışlıkla geçiyordu.
	func is_engaged() -> bool:
		return false

func run(t) -> void:
	# ── ENVY AURA HEDEFLEME KONTROLLERİ ──
	var treat_ab := AbilityData.new()
	treat_ab.ability_id = &"treat"
	treat_ab.display_name = "Treat"
	treat_ab.target_type = "friendly"
	treat_ab.target_same_faction = true
	treat_ab.range_meters = 8.0

	var caster := _FakeUnit.new()
	caster.owner_id = 1
	caster.unit_data = UnitData.new()

	var target := _FakeUnit.new()
	target.owner_id = 1
	target.unit_data = UnitData.new()
	target.global_position = Vector3(1, 0, 0)

	# Sahada düşman Desecrated Saint (Demonic + demonic_aura ability) kurulumu
	var saint := _FakeUnit.new()
	saint.owner_id = 2  # Düşman oyuncu
	saint.global_position = Vector3(2, 0, 0)  # Target'a 1" mesafede (3" aura içinde)
	saint.unit_data = UnitData.new()
	saint.unit_data.faction_id = &"court_of_seven_headed_serpent"
	saint.unit_data.keywords = {&"demonic": 1}
	
	var demonic_ab := AbilityData.new()
	demonic_ab.ability_id = &"demonic_aura"
	# UnitData.abilities `Array[Resource]` TİPLİdir; çıplak `[...]` ataması Godot'ta çalışma
	# zamanında sessizce başarısız oluyordu ("Invalid assignment... value of type 'Array'"),
	# yani aura testi aslında BOŞ bir abilities listesi üzerinde koşuyordu.
	var abs: Array[Resource] = [demonic_ab]
	saint.unit_data.abilities = abs

	# GameState birimlerini ayarla
	GameState.units.clear()
	GameState.units["caster"] = caster
	GameState.units["target"] = target
	GameState.units["saint"] = saint

	# FactionData / GameState faksiyon bilgisi ayarla (Player 2: Envy Sin seçmiş)
	var env_faction = FactionData.new()
	env_faction.faction_id = &"court_of_seven_headed_serpent"
	env_faction.selected_sin = &"envy"
	GameState.player_factions[2] = env_faction

	# Target Envy aurasında mı?
	t.ok(MechanicsResolver.is_in_demonic_aura(target, &"envy_aura"), "Target Envy Aurası içinde (3\" mesafede)")

	# Envy aurasındaki hedef dost yetenek için GEÇERSİZ olmalı
	t.ok(not AbilityExecutor.is_valid_ability_target(treat_ab, caster, target),
		"Envy aurasındaki dost hedef is_valid_ability_target = false olmalı")

	var val_err: String = AbilityExecutor._validate(treat_ab, caster, target)
	t.ok(val_err != "", "Envy aurasındaki hedef _validate'den hata dönmeli")
	t.eq(val_err, "Hedef Kıskançlık Aurasında (dost yeteneklerden yararlanamaz).", "_validate doğru hata mesajını vermeli")

	# Saint uzaklaşsın (aura dışına çıksın)
	saint.global_position = Vector3(50, 0, 0)
	t.ok(not MechanicsResolver.is_in_demonic_aura(target, &"envy_aura"), "Target aura dışında")
	t.ok(AbilityExecutor.is_valid_ability_target(treat_ab, caster, target), "Aura dışında dost hedef geçerli")
	t.eq(AbilityExecutor._validate(treat_ab, caster, target), "", "Aura dışında _validate geçerli olmalı")

	# ── PRIDE AURA KONTROLLERİ ──
	var pride_faction = FactionData.new()
	pride_faction.faction_id = &"court_of_seven_headed_serpent"
	pride_faction.selected_sin = &"pride"
	GameState.player_factions[2] = pride_faction

	saint.global_position = Vector3(2, 0, 0) # Yeniden yakın
	t.ok(MechanicsResolver.is_in_demonic_aura(target, &"pride_aura"), "Target Pride Aurası içinde")

	# Temizlik
	GameState.units.clear()
	GameState.player_factions.clear()
