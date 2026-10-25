## AbilityExecutor — Trench Crusade Faksiyon Yeteneği Çalıştırıcı
##
## Bu sınıf STATELESS'tır.
## unit.gd'deki tüm server_request_*_action fonksiyonları buraya delege eder.
##
## Kullanım (unit.gd içinden):
##   var result = await AbilityExecutor.execute(ability_data, self, target)
##
## SORUMLULUK: yalnız ÇALIŞTIRMA AKIŞI — doğrulama → başarı zarı → efekt yönlendirme.
## Efektlerin GÖVDESİ burada DEĞİL:
##   • veri odaklı jenerik efektler  → `abilities/ability_effects.gd`
##   • birime özel ("custom") mantık → `abilities/custom/<ability_id>.gd` + `ability_registry.gd`
##
## YENİ YETENEK EKLEME (bu dosyaya DOKUNMADAN):
##   1. `AbilityData` .tres oluştur, `UnitData.abilities[]`e ekle.
##   2. Davranış mevcut bir `effect_type` ile ifade edilebiliyorsa (blessing/teleport/add_blood/
##      set_flag/...) İŞ BİTTİ — kod yazılmaz.
##   3. Değilse: `effect_type = "custom"`, `abilities/custom/<ability_id>.gd` yaz
##      (`static func apply(ctx: AbilityContext) -> bool`) ve `AbilityRegistry.CUSTOM`e 1 satır ekle.
class_name AbilityExecutor

const AbilityData = preload("res://scripts/data/ability_data.gd")
const MechanicsResolver = preload("res://scripts/rules/mechanics_resolver.gd")

## Temel eylemlerle çakışan action_key'ler — bunlar ayrı yetenek butonu ÜRETMEZ.
const _BASE_ACTIONS := ["move", "charge", "retreat", "dash", "melee", "shoot"]

## Bu yetenek, panelde AKSİYON BUTONU üretebilir/aktivasyonda sayılabilir mi? (P2-7: tek kaynak.)
## Pasifler (action_key boş), temel-eylemle çakışanlar ve `AbilityRegistry`de KAYITLI OLMAYAN
## custom yetenekler hariç tutulur — böylece "etkisi olmayan yanıltıcı buton" oluşmaz. Panel +
## has_any_remaining_action AYNI filtreyi kullanır (aksi halde "buton var ama otomatik bitiyor"
## çelişkisi doğar). "Uygulanmış mı" sorusunun TEK KAYNAĞI registry'dir; eskiden ayrıca elle
## bakımlı bir `CUSTOM_IMPLEMENTED` dizisi vardı ve dispatcher'dan sapabiliyordu.
## NOT: bu, eylemin ŞU AN yapılabilirliğini (can_perform_action) İÇERMEZ — çağıran ayrıca kontrol eder.
static func is_actionable_ability(ab) -> bool:
	if ab == null or ab.action_key == "" or ab.action_key in _BASE_ACTIONS:
		return false
	if ab.effect_type == "custom" and not AbilityRegistry.is_implemented(ab.ability_id):
		return false
	return true

## Serialize edilmiş yetenek hedefini gerçek nesneye çözer.
## KRİTİK: Node.name bir StringName'dir; `x is String` bir StringName'i YAKALAMAZ. Bu yüzden
## yalnız `is String` kontrolü yerel oyunda birim adını çözemeyip hedefi düşürüyordu ("Geçerli
## hedef yok" → "butona basınca bir şey olmuyor"). StringName ve String ikisi de kabul edilir;
## GameState.units StringName ile anahtarlı ama Dictionary erişimi iki tür arasında çapraz çalışır.
static func resolve_target(serialized):
	if serialized is String or serialized is StringName:
		return GameState.units.get(serialized)
	return serialized  # Vector3 (position) veya null

## `target` (bir birim node/stub) bu yetenek için GEÇERLİ bir dost/düşman hedefi mi?
## Tek kaynak: hedef vurgusu (_compute_is_valid_target), tıklama yönlendirmesi (map_input) ve
## _validate aynı allegiance/menzil/hayatta kuralını kullanır → "dost yetenek butonu basınca
## hangi birimlerin hedeflenebileceği" artık görsel olarak vurgulanabilir. Yalnız friendly/enemy
## türleri birim vurgular; self/none/position birim-hedefi değildir (false döner).
static func is_valid_ability_target(ability, caster, target) -> bool:
	if ability == null or caster == null:
		return false
	if ability.target_type != "friendly" and ability.target_type != "enemy" and ability.target_type != "any":
		return false
	if target == null or not is_instance_valid(target):
		return false
	if ability.target_must_be_alive and target.current_health <= 0:
		return false
	# "any" (P1-1, Puppet Master — Heretic Priest): "pick 1 model (friend or foe)... apart from
	# themselves" — allegiance hiç kontrol edilmez (yalnız kendisi hariç); friendly/enemy türlerinde
	# target_same_faction doğrulanmaya devam eder (mevcut davranış, regresyon riski yok).
	if ability.target_type == "any":
		if target == caster:
			return false
	else:
		if ability.target_same_faction and target.owner_id != caster.owner_id:
			return false
		if not ability.target_same_faction and target.owner_id == caster.owner_id:
			return false
	if ability.range_meters > 0.0:
		if caster.global_position.distance_to(target.global_position) > ability.range_meters:
			return false
	# SLAVEMASTER (Court of the Seven-Headed Serpent, P1-1): compendium — hedef SADECE bir Yoke
	# Fiend olabilir ("carry out one of the following Commands with a Yoke Fiend"). Yoke Fiend'e
	# özgü ayrı bir "identity" keyword'ü yok; &"hateful" bugün YALNIZ Yoke Fiend'de var, güvenilir
	# bir vekil olarak kullanılıyor.
	if ability.ability_id == &"slavemaster":
		if target.unit_data == null or not KeywordSystem.has(target.unit_data, &"hateful"):
			return false
	# DEMONIC AURA — ENVY (Court, Desecrated Saint): düşman modeller 3" içinde
	# dost yeteneklerden yararlanamazlar.
	if ability.target_type == "friendly" and MechanicsResolver.is_in_demonic_aura(target, &"envy_aura"):
		return false
	return true

# ─────────────────────────────────────────────────────────────────────────────
# GENEL ÇALIŞTIRICI
# ─────────────────────────────────────────────────────────────────────────────

## Ana giriş noktası. AbilityData'ya göre doğru efekti çalıştırır.
## extra_param: bazı yeteneklerin (örn. Ammunition Sacrament) yerel bir ön-seçim taşıması için —
## çoğu yetenek için boş string.
## Döndürür: { "success": bool, "end_activation": bool }
static func execute(ability: AbilityData, caster, target = null, extra_param: String = "") -> Dictionary:
	# "self" hedefli yetenekler için hedef her zaman caster'ın kendisidir.
	if ability.target_type == "self" and target == null:
		target = caster

	# 0. Henüz uygulanmamış custom yetenekleri erkenden durdur (boşa aktivasyon harcatma).
	if ability.effect_type == "custom" and not AbilityRegistry.is_implemented(ability.ability_id):
		GameLogger.log_warn("[Ability] '%s' yeteneği henüz uygulanmadı — eylem iptal edildi (aktivasyon korunuyor)." \
			% ability.display_name, "GAME")
		return { "success": false, "end_activation": false }

	# 1. Geçerlilik kontrolü (genel kurallar + custom handler'ın isteğe bağlı `validate(ctx)`'i —
	# eylem hakkı harcanmadan ÖNCE; bkz. AbilityContext sözleşmesi)
	var err = _validate(ability, caster, target)
	if err == "" and ability.effect_type == "custom":
		var h: GDScript = AbilityRegistry.handler_for(ability.ability_id)
		if h != null and h.get_script_method_list().any(func(m): return m.name == "validate"):
			err = h.validate(AbilityContext.create(ability, caster, target, 0, false, extra_param))
	if err != "":
		GameLogger.log_warn("[Ability] %s yeteneğini kullanamaz (Yetenek: %s): %s" % [caster.display_name, ability.display_name, err], "GAME")
		return { "success": false, "end_activation": false }

	# 2. Aksiyonu kaydet
	caster.actions_taken.append(ability.action_key)
	RpcHelper.sync(caster, "sync_actions_taken", [caster.actions_taken])

	# 3. Başarı zarı
	var roll_total := 0
	var is_crit := false
	if ability.requires_roll:
		var roll_mod: int = ability.dice_modifier
		# EXPERT MEDIC (Combat Medic): Treat aksiyonunun Risky Success Roll'una +2 DICE.
		if ability.ability_id == &"treat" and caster.unit_data != null \
				and KeywordSystem.has(caster.unit_data, &"expert_medic"):
			roll_mod += 2
		var res: Array = await caster.perform_unit_success_roll(roll_mod)
		roll_total = res[0]
		is_crit = res[1]
		GameLogger.log_info("[Ability] %s yetenek zarı attı: %s | Zar: %d (Gereken: %d+)" \
			% [caster.display_name, ability.display_name, roll_total, ability.success_threshold], "GAME")

		if roll_total < ability.success_threshold:
			GameLogger.log_warn("[Ability] Yetenek başarısız! %s" % ability.display_name, "GAME")
			BattleEvents.ability(caster, ability.display_name, false)
			# `is_risky` yetenek VEYA Sarsılmış ordu VEYA Maddening Buzzing → aktivasyon biter.
			# Karar tek kaynakta (bkz. scripts/rules/risky_rolls.gd).
			# NOT: burada `end_activation: true` DÖNDÜRÜLÜR; aktivasyonu çağıran bitirir, bu yüzden
			# `RiskyRolls.apply_failure` yerine yalnız PREDİKAT kullanılır (çifte bitirme olmasın).
			if RiskyRolls.is_risky(caster, ability.is_risky):
				return { "success": false, "end_activation": true }
			return { "success": false, "end_activation": false }
	else:
		GameLogger.log_info("[Ability] %s — %s: Otomatik başarı." % [caster.display_name, ability.display_name], "GAME")

	# 4. Efekt uygula
	BattleEvents.ability(caster, ability.display_name, true)
	var ctx := AbilityContext.create(ability, caster, target, roll_total, is_crit, extra_param)
	var end_act: bool = await _dispatch(ctx)
	return { "success": true, "end_activation": end_act }

## Efekti doğru sahibe yönlendirir. Tek karar noktası: custom mu, veri odaklı mı?
static func _dispatch(ctx: AbilityContext) -> bool:
	if ctx.ability.effect_type == "custom":
		var handler: GDScript = AbilityRegistry.handler_for(ctx.ability.ability_id)
		if handler == null:
			# execute() bunu zaten erkenden eler; burası yalnız savunma amaçlı.
			push_warning("[AbilityExecutor] Custom yetenek '%s' için kayıtlı handler yok." \
				% ctx.ability.ability_id)
			return false
		return await handler.apply(ctx)
	return await AbilityEffects.apply(ctx)

# ─────────────────────────────────────────────────────────────────────────────
# GEÇERLİLİK KONTROLÜ
# ─────────────────────────────────────────────────────────────────────────────

static func _validate(ability: AbilityData, caster, target) -> String:
	# Birim Down ise ve yetenek standing gerektiriyorsa
	if ability.requires_standing and caster.is_down:
		return "Birim yerde (Down)."

	# Angaje durumu kontrolleri
	var engaged: bool = caster.is_engaged()
	if ability.requires_not_engaged and engaged:
		return "Angaje birim bu yeteneği kullanamaz."
	if ability.requires_engaged and not engaged:
		return "Bu yetenek için angaje olunması gerekir."

	# Hedef geçerlilik
	if ability.target_type == "friendly" or ability.target_type == "enemy" or ability.target_type == "any":
		if target == null or not is_instance_valid(target):
			return "Geçerli hedef yok."
		if ability.target_must_be_alive and target.current_health <= 0:
			return "Hedef Savaş Dışı."
		# "any" (Puppet Master): allegiance serbest, yalnız kendisi hariç (bkz. is_valid_ability_target).
		if ability.target_type == "any":
			if target == caster:
				return "Hedef kendisi olamaz."
		else:
			if ability.target_same_faction and target.owner_id != caster.owner_id:
				return "Hedef dost birim değil."
			if not ability.target_same_faction and target.owner_id == caster.owner_id:
				return "Hedef düşman birim değil."
		if ability.range_meters > 0.0:
			var dist: float = caster.global_position.distance_to(target.global_position)
			if dist > ability.range_meters:
				return "Hedef menzil dışında (%.1f > %.1f m)" % [dist, ability.range_meters]

	# DEMONIC AURA — ENVY (Court, Desecrated Saint): düşman modeller 3" içinde
	# dost yeteneklerden yararlanamazlar.
	if ability.target_type == "friendly" and MechanicsResolver.is_in_demonic_aura(target, &"envy_aura"):
		return "Hedef Kıskançlık Aurasında (dost yeteneklerden yararlanamaz)."

	# HOLD YOUR FIRE! (new-antioch.md): "pick 1 enemy model that is IN THE LIEUTENANT'S
	# LINE OF SIGHT and that the opponent is allowed to Activate." Compendium MENZİL SINIRI
	# KOYMAZ — kısıt yalnız görüş hattıdır. Eskiden uydurma bir 12" menzil vardı ve LoS hiç
	# denetlenmiyordu (denetim bulgusu P1-NA-8).
	if ability.ability_id == &"hold_your_fire":
		if target == null or not is_instance_valid(target):
			return "Geçerli hedef yok."
		if caster.has_method("get_line_of_sight_status"):
			var hyf_los: Dictionary = caster.get_line_of_sight_status(target)
			if hyf_los.get("is_blocked", false):
				return "HOLD_YOUR_FIRE_FAIL_LOS"

	# DEVOUR THE GUILTY (Sin Eater, P1-1): "A Sin Eater can only have 1 devoured model at a time."
	if ability.ability_id == &"devour_the_guilty":
		if caster.devoured_unit != null:
			return "Sin Eater zaten bir model yutmuş durumda."
		if target != null and "devoured_by" in target and target.devoured_by != null:
			return "Hedef zaten başka bir Sin Eater tarafından yutulmuş."
	# PURGE (Sin Eater, P1-1): yalnız yutulmuş bir model varsa anlamlı.
	if ability.ability_id == &"purge" and caster.devoured_unit == null:
		return "Sin Eater'ın yutulmuş bir modeli yok."

	return ""  # Geçerli

# ─────────────────────────────────────────────────────────────────────────────
# GOETIC SPELLS — Court of the Seven-Headed Serpent (P1-1) ORTAK ÖDEME ALTYAPISI
# ─────────────────────────────────────────────────────────────────────────────
## Compendium (Faction Rules → Goetic Powers and Spells): "Note that you do not have to take a
## Success Roll for a model in order to cast a spell." — maliyet SADECE Blood Marker'dır.
## min_cost==max_cost ise oyuncuya sorulmadan sabit maliyetle devam edilir (örn. Blood Magic'in
## "Goetic (1)"i); aksi halde önce ödenecek miktar sorulur (örn. Burning Inferno'nun "1-3"ü,
## Blessings of the Serpent Moon'un "2/4/6"sı — ARALIKLI olsa da bu projede DİSKRET seçenek
## kümesi yerine SÜREKLİ aralık olarak modellendi, basit bir sadeleştirme: 2/4/6 yerine 2-6 arası
## HERHANGİ bir değer seçilebilir; RAW'ın izin verdiği 3 değerin üst kümesini kapsar, daha kısıtlı
## değil daha esnektir — dokümante edilen, zararsız bir gevşetme).
## Döner: ödenen maliyet (>0, büyü gerçekleşti) veya 0 (iptal/kaynak yetersiz/oyuncu vazgeçti).
static func pay_goetic_cost(caster, min_cost: int, max_cost: int, cost_display_key: String) -> int:
	var cost: int = min_cost
	if max_cost > min_cost:
		cost = await CombatChoice.request_goetic_cost(caster, min_cost, max_cost, cost_display_key)
		if cost < min_cost:
			return 0
	if cost <= 0:
		return 0
	# ÖN-KONTROL: sahada `cost` kadar Blood Marker toplanabilecek kaynak yoksa "blood_drain" pick
	# modunu HİÇ açma — açılırsa oyuncu hiçbir tıklamanın işe yaramadığı bir ekranda kilitlenir
	# (30sn'lik oto-iptale kadar "butona bastım hiçbir şey olmadı" hissi verir). Sahada TEK
	# Blood Marker yoksa (oyunun başında hep böyledir) bu, Slavemaster/Burning Inferno/Shadow
	# Walker gibi TÜM Goetic Spell'lerin ortak sessiz-kilitlenme kök nedeniydi.
	var field_sources: Array = []
	for u in UnitQuery.alive():
		field_sources.append({"blood_markers": u.blood_markers, "unit_data": u.unit_data})
	if MechanicsResolver.total_available_goetic_blood(field_sources) < cost:
		GameEvents.ability_rejected.emit("GOETIC_FAIL_NO_BLOOD")
		GameLogger.log_warn("[Goetic] %s büyünün bedelini ödeyecek Kan İşareti sahada yok (gerekli: %d)." \
			% [caster.display_name, cost], "GAME")
		return 0
	var sources = await CombatChoice.request_blood_drain(caster, cost, "GOETIC_DRAIN")
	if sources == null:
		return 0
	for u_name in sources:
		if GameState.units.has(u_name):
			var u = GameState.units[u_name]
			if is_instance_valid(u):
				u.blood_markers = max(0, u.blood_markers - int(sources[u_name]))
				CombatResolver.sync_target_health(u)
	GameLogger.log_info("[Goetic] %s büyünün bedelini ödedi: %d Kan İşareti (%d model)." \
		% [caster.display_name, cost, sources.size()], "GAME")
	return cost

## Reaktif (buton tetiklemeyen, "Cast before an Injury Roll/Retreat/etc." tipi) bir Goetic
## Spell'i castetmeyi DENER: sahibine Evet/Hayır sorulur, kabul edilirse maliyet ödenir. "A model
## cannot cast the same spell more than once per Activation" kuralı burada uygulanır.
## Döner: ödenen maliyet (>0, büyü gerçekleşti) veya 0 (reddedildi/iptal/bu aktivasyonda zaten cast edilmiş).
static func try_cast_reactive_goetic(unit, ability_id: StringName, min_cost: int, max_cost: int,
		prompt_key: String) -> int:
	if unit.goetic_spells_cast_this_activation.has(ability_id):
		return 0
	var wants: bool = await CombatChoice.request_goetic_cast_confirm(unit, prompt_key)
	if not wants:
		return 0
	var paid: int = await pay_goetic_cost(unit, min_cost, max_cost, prompt_key)
	if paid > 0:
		unit.goetic_spells_cast_this_activation.append(ability_id)
	return paid
