## AKTİVASYON TAAHHÜDÜ — "bir model aktive edildiyse aktivasyonu bitene kadar başkası aktive edilemez".
##
## COMPENDIUM (core-rules/activations.md): oyuncular sırayla BİRER model aktive eder; aktive edilen
## model eylemlerini yapar, aktivasyonu biter, sıra rakibe geçer. Bir modeli yarıda bırakıp başka
## bir modelle oynamak ve sonra ilkine dönmek RAW'da yoktur.
##
## KURAL SAPMASI DÜZELTMESİ (compendium denetimi, Adım 1): seçim = aktivasyon olmasına rağmen
## (1) aktivasyon-başı etkileri (ayağa kalkma, Regenerate, Infection büyümesi, Devour, faction
## kuralları, Hateful) birim HER SEÇİLDİĞİNDE yeniden çalışıyordu → seç/bırak döngüsüyle Infection
## katlanıyor, Regenerate tekrarlanıyordu; (2) A birimi eylem yapıp yarıda bırakılınca B birimi
## tam oynatılıp A'ya geri dönülebiliyordu → sıralı aktivasyon bozuluyordu.
##
## ÇÖZÜM: aktivasyon-başı etkileri round başına BİR KEZ (unit.activation_started) çalışır. Bir
## birim eylem yaptıysa veya ayağa kalktıysa aktivasyonu TAAHHÜT edilmiş sayılır; bitene kadar
## aynı oyuncu başka birim seçemez. Hiçbir şey yapmadan seçilmiş birimden vazgeçmek serbesttir
## (yanlış tıklama kilitlemez).
##
## ORTAK AKTİVASYON (compendium denetimi, Adım 6) — iki kural aynı motoru paylaşır:
##   • FIRETEAM (warbands/new-antioch.md + keyword.md): "Models that are part of the same Fireteam
##     can be Activated simultaneously... switch between the two models freely. However, if the
##     Activation of either member ends (due to a failed Risky Success Roll for example), it
##     immediately ends for the other model". New Antioch en fazla 2 Fireteam kurar ([New
##     Antioch] keyword'lü iki model); SWORN BRETHREN (Mamluk Faris) bunlara EK olarak Mamluk'u
##     bir [Elite] modelle eşler.
##   • FAITHFUL FOLLOWERS (Mendelist Ammo Monk): 1" içindeki bir model aktive edilince Monk da
##     "can also" aktive edilir; biri biterse "the other model can carry on normally".
## İkisi de İSTEĞE BAĞLIDIR (önceki uygulama partneri ZORLA sıraya sokuyordu). Taahhüt edilmiş
## birim varken eşi seçmek ortak aktivasyonu başlatır; ayrı ayrı aktive etmek de serbesttir.
## Fireteam eşleri roster ekranı olmadığından oyuncunun İLK ortak aktivasyonunda kalıcılaşır
## (önceden düğüm adı sırasına göre otomatik eşleniyordu — oyuncu seçimi değildi).
class_name ActivationRules
extends RefCounted

const JOINT_NONE := 0
const JOINT_FIRETEAM := 1
const JOINT_FOLLOWERS := 2
const MAX_NEW_ANTIOCH_FIRETEAMS := 2
const FOLLOWERS_RANGE := 1.0


## Birim aktivasyonunun ortasında mı (eylem yaptı / ayağa kalktı, ama aktivasyonu bitmedi)?
static func is_committed(u) -> bool:
	if u == null or not is_instance_valid(u):
		return false
	if u.has_moved or u.current_health <= 0:
		return false
	# `activation_started` BAKILMAZ: o bayrak seçimde yalnız seçen makinede kurulur; eylemler
	# (actions_taken) ise sunucuda çalışıp senkronlanır → ağ oyununda sunucu da aynı sonucu bulur.
	return not u.actions_taken.is_empty() or u.stood_up_this_activation


## `player_id`'nin aktivasyonu taahhüt edilmiş birimi (yoksa null). `units` = GameState.units değerleri.
static func committed_unit(units: Array, player_id: int):
	for u in units:
		if is_instance_valid(u) and u.owner_id == player_id and is_committed(u):
			return u
	return null


## `candidate` seçilebilir mi? Aynı oyuncunun başka bir birimi taahhüt edilmişse hayır.
static func can_select(units: Array, candidate) -> bool:
	if candidate == null or not is_instance_valid(candidate):
		return true
	var c = committed_unit(units, candidate.owner_id)
	return c == null or c == candidate


## Seçim engelleniyorsa oyuncuya gösterilecek açıklama, değilse "". `units` = GameState.units
## sözlüğü; `forced_name` = TurnManager.forced_next_activator (Hold Your Fire).
static func selection_block_reason(units: Dictionary, unit, forced_name: String) -> String:
	# Taahhüt edilmiş birimin ortak aktivasyon eşi her zaman seçilebilir — zorunlu aktivasyonda
	# da (community-faq KEYWORDS Q1: Hold Your Fire/Faithful Followers ile seçilen modelin
	# Fireteam eşi de aktive edilebilir).
	var joint_with = committed_unit(units.values(), unit.owner_id)
	if joint_with != null and joint_with != unit and joint_allowed(joint_with, unit, units.values()):
		return ""
	if forced_name != "" and forced_name != unit.name:
		var forced = units.get(forced_name)
		if is_instance_valid(forced) and forced.owner_id == unit.owner_id \
				and forced.current_health > 0 and not forced.has_moved:
			return LocalizationManager.tr_t("SELECT_FAIL_FORCED") % forced.display_name
	var committed = committed_unit(units.values(), unit.owner_id)
	if committed != null and committed != unit:
		return LocalizationManager.tr_t("SELECT_FAIL_COMMITTED") % committed.display_name
	return ""


## `candidate`, taahhüt edilmiş `committed` ile ortak aktive edilebilir mi (mevcut bağ ya da yeni)?
static func joint_allowed(committed, candidate, all_units: Array) -> bool:
	return committed.joint_partner == candidate or joint_kind(committed, candidate, all_units) != JOINT_NONE


## `a` (aktivasyonu sürüyor) ile `b` arasında YENİ bir ortak aktivasyon kurulabilir mi, hangi türde?
static func joint_kind(a, b, all_units: Array) -> int:
	if not is_instance_valid(a) or not is_instance_valid(b) or a == b or a.owner_id != b.owner_id:
		return JOINT_NONE
	if a.has_moved or b.has_moved or b.current_health <= 0 or a.joint_partner != null or b.joint_partner != null:
		return JOINT_NONE
	if a.fireteam_partner == b:
		return JOINT_FIRETEAM
	if a.fireteam_partner == null and b.fireteam_partner == null and fireteam_form(a, b, all_units) != &"":
		return JOINT_FIRETEAM
	# "When you Activate a model within 1\" of a Monk" — mesafe modelin AKTİVASYON BAŞINDAKİ
	# konumundan ölçülür (sonradan Monk'tan uzaklaşmış olsa da katılabilir); bazdan baza.
	var start_pos = a.get("activation_start_pos")
	var from: Vector3 = start_pos if start_pos is Vector3 else a.global_position
	if is_follower_monk(b) and not is_follower_monk(a) \
			and from.distance_to(b.global_position) <= FOLLOWERS_RANGE + GameState.ATTACK_RANGE_TOLERANCE:
		return JOINT_FOLLOWERS
	return JOINT_NONE


## Eşi olmayan iki model yeni bir Fireteam kurabilir mi? &"sworn" (Mamluk + [Elite]),
## &"new_antioch" (iki [New Antioch] modeli, oyuncunun 2 Fireteam sınırı dolmadıysa) ya da &"".
static func fireteam_form(a, b, all_units: Array) -> StringName:
	if (_is_mamluk(a) and _is_elite(b)) or (_is_mamluk(b) and _is_elite(a)):
		return &"sworn"
	if not FactionRules.is_fireteam_eligible(a.unit_data) or not FactionRules.is_fireteam_eligible(b.unit_data):
		return &""
	var members := 0
	for u in all_units:
		if is_instance_valid(u) and u.owner_id == a.owner_id and u.fireteam_partner != null and not u.fireteam_sworn:
			members += 1
	return &"new_antioch" if members / 2 < MAX_NEW_ANTIOCH_FIRETEAMS else &""


## Bağı iki birime yazar (sunucu doğruladıktan sonra her makinede çalışır). `form` boş değilse
## bu bağ yeni bir kalıcı Fireteam'dir.
static func apply_link(a, b, form: StringName) -> void:
	a.joint_partner = b
	b.joint_partner = a
	if form != &"":
		a.fireteam_partner = b
		b.fireteam_partner = a
		a.fireteam_sworn = form == &"sworn"
		b.fireteam_sworn = a.fireteam_sworn
		GameLogger.log_info("[Fireteam] %s <-> %s Fireteam kurdu%s." % [a.display_name, b.display_name,
			" (Sworn Brethren)" if a.fireteam_sworn else ""], "TURN")
	else:
		GameLogger.log_info("[Ortak Aktivasyon] %s ile %s birlikte aktive ediliyor." \
			% [a.display_name, b.display_name], "TURN")


## Bir üyenin aktivasyonu bitince eşe ne olur: &"end" (Fireteam + ZORUNLU bitiş → eş de biter),
## &"continue" (eş zaten başladı → aktivasyonu sürer, sıra rakibe geçmez) ya da &"none".
## `natural` = birim eylemlerini tüketti / oyuncu bitirdi (Risky başarısızlığı, Reload vb. değil).
static func partner_outcome(u, natural: bool) -> StringName:
	var p = u.joint_partner
	if not is_instance_valid(p) or p.has_moved or p.current_health <= 0:
		return &"none"
	if not natural and u.fireteam_partner == p:
		return &"end"
	return &"continue" if is_committed(p) else &"none"


static func is_follower_monk(u) -> bool:
	return u.unit_data != null and KeywordSystem.has(u.unit_data, &"faithful_followers")


static func _is_elite(u) -> bool:
	return u.unit_data != null and KeywordSystem.has(u.unit_data, &"elite")


static func _is_mamluk(u) -> bool:
	return u.unit_data != null and u.unit_data.abilities.any(
		func(ab): return ab != null and ab.ability_id == &"sworn_brethren")
