## FactionRules — Trench Crusade Faksiyon Pasif Kuralları
##
## Bu sınıf STATELESS'tır (mechanics_resolver.gd/ability_executor.gd ile aynı desen).
## Compendium'daki bazı warband dosyalarında "## Faction Rules" başlığı altında
## army-wide pasif kurallar tanımlanır. Her faction'da bulunmaz — sadece
## FactionData.has_faction_rule = true olanlarda gerçek bir mantık BEKLENİR (bu sınıfın
## match'lerine faction_id eklenmemişse flag YANLIŞTIR, bkz. P0-7).
##
## Trench Pilgrims/Iron Sultanate/Heretic Legion'ın resmi "## Faction Rules" bölümü yok
## (kimlikleri per-unit ability'lerden geliyor, has_faction_rule=false doğru). Cult of the
## Black Grail'in korku-morale pasifi VAR ama bu sınıftan DEĞİL, doğrudan
## TurnManager.morale_fear_penalty'den uygulanıyor (has_faction_rule=true doğru).
## New Antioch'un Fireteam + Concentrated Attack'ı (P1-1, 2026-07-16) artık uygulandı — bkz.
## ActivationRules (isteğe bağlı ortak aktivasyon; eşleri oyuncu ilk ortak aktivasyonda seçer) +
## injury_marker_spend (Concentrated Attack Bloodbath indirimi). Court'un Goetic Powers sistemi zaten uygulandı
## (has_faction_rule=true, Nobles of the Court roster-kısıtı kısmen — Praetor is_leader).
##
## Eklenen her yeni faction pasifi için:
##   1. FactionData.has_faction_rule = true, faction_rule_summary doldurulur
##   2. Buraya faction_id ile eşleşen bir _apply_<faction>_* fonksiyonu eklenir
##   3. İlgili hook'tan (aşağıda) çağrılır
class_name FactionRules

## Aktivasyon başında çağrılır (unit.gd::set_selected — Regeneration/Disease Carrier
## ile aynı noktada). Şu an hiçbir faction için efekt yok.
static func on_activation_start(_unit_node) -> void:
	if _unit_node.unit_data == null:
		return
	# DEMONIC AURA (Desecrated Saint, Court): aktivasyon başında aura bilgisi loglanır.
	if _unit_node.unit_data.faction_id == &"court_of_seven_headed_serpent" \
			and KeywordSystem.has(_unit_node.unit_data, &"demonic") \
			and _unit_node.unit_data.abilities.any(func(ab): return ab != null and ab.ability_id == &"demonic_aura"):
		apply_demonic_aura_info(_unit_node)
	match _unit_node.unit_data.faction_id:
		_:
			pass

## Success Roll DICE havuzuna faction pasifinden gelen ek modifier.
## dice_pool_builder.gd::compute_success_modifier tarafından çağrılabilir.
static func get_success_dice_modifier(_unit_node, _ctx: Dictionary) -> int:
	if _unit_node.unit_data == null:
		return 0
	match _unit_node.unit_data.faction_id:
		_:
			return 0

## FIRETEAM UYGUNLUĞU — compendium (recruit-your-warband.md):
##   "Mercenaries DO NOT BENEFIT from the Faction Special Rules of your Warband, SUCH AS THE
##    NEW ANTIOCH CONCENTRATED ATTACK RULE."
## Bu yüzden eşleştirme OYUNCUNUN faksiyonuna değil, BİRİMİN [New Antioch] keyword'üne bakar.
## Mercenary birimler (Observer, Witchburner, Scripture Guardian...) bu keyword'ü taşımaz.
static func is_fireteam_eligible(unit_data: Resource) -> bool:
	return unit_data != null and KeywordSystem.has(unit_data, &"new_antioch")

## Concentrated Attack'ı yalnız [New Antioch] keyword'lü modeller kullanabilir (aynı gerekçe).
static func can_use_concentrated_attack(unit_data: Resource) -> bool:
	return is_fireteam_eligible(unit_data)

# ── SEVEN DEADLY SINS — DEMONIC AURA (Court of the Seven-Headed Serpent) ─────────
## Compendium: Desecrated Saint'in Demonic Aura'sı seçilen günaha göre değişir.
## Her turun başında veya aktivasyon başlangıcında 3" içindeki düşmanlara etki eder.
## Bu fonksiyon SADECE Desecrated Saint aktive olduğunda çağrılır (on_activation_start).

## Seçilen günahı al: oyuncunun FactionData'sından selected_sin oku.
static func _get_selected_sin(unit_node) -> StringName:
	var faction = GameState.get_faction_for_player(unit_node.owner_id)
	if faction == null:
		return &""
	return faction.selected_sin

## 3" içindeki düşman birimleri döndürür.
static func _enemies_within_aura(unit_node, range_m: float = 3.0) -> Array:
	return UnitQuery.enemies_within(unit_node, range_m)

## Desecrated Saint aktivasyonunda Demonic Aura bilgisini logla.
## Gerçek mekanik etkileri ilgili sistemlerde (DicePoolBuilder, UnitActions, AbilityExecutor)
## _is_in_demonic_aura() kontrolü ile REAL-TIME uygulanır — bu fonksiyon sadece
## aktivasyon başlangıcında bilgilendirme amaçlıdır.
static func apply_demonic_aura_info(unit_node) -> void:
	var sin: StringName = _get_selected_sin(unit_node)
	if sin == &"" or not FactionData.SEVEN_DEADLY_SINS.has(sin):
		return
	var sin_data: Dictionary = FactionData.SEVEN_DEADLY_SINS[sin]
	var enemies: Array = _enemies_within_aura(unit_node)
	if enemies.size() > 0:
		var names: String = ", ".join(enemies.map(func(e): return e.display_name))
		GameLogger.log_info("[Demonic Aura — %s] %s'in aurası %d düşmanı etkiliyor: %s. Etki: %s" \
			% [sin_data["display_name"], unit_node.display_name, enemies.size(), names, sin_data["demonic_aura_desc"]], "COMBAT")
