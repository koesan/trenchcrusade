extends RefCounted

## Release-candidate QC turu (2026-07-18, 3. tur) — fork denetiminde bulunan 4 silah verisi
## boşluğu: [Critical] keyword'ü hiç modellenmemiş silahlar (compendium battlekit/melee.md ile
## birebir karşılaştırıldı). Ayrıca Titan Zulfiqar'ın yanlış "2H" eli ve iki Greatsword'ün
## compendium'da HİÇ olmayan (muhtemelen kopyala-yapıştır hatası) Cleave 2'si.

const KeywordSystem = preload("res://scripts/rules/keyword_system.gd")

func run(t) -> void:
	# Titan Zulfiqar (Brazen Bull, Iron Sultanate): battlekit/melee.md — "1 Hands (Melee)",
	# [+2 Injury Modifier][Critical][Heavy]. hands=2H yanlıştı; critical/heavy hiç yoktu;
	# ignore_armour/is_deadly/is_cumbersome compendium'da desteklenmiyordu.
	var zulfiqar = load("res://assets/data/attacks/titan_zulfiqar.tres")
	t.eq(zulfiqar.hands, "1H", "Titan Zulfiqar → 1H (compendium: '1 Hands (Melee)', regresyon)")
	t.ok(KeywordSystem.has(zulfiqar, &"critical"), "Titan Zulfiqar → [Critical] var")
	t.ok(KeywordSystem.has(zulfiqar, &"heavy"), "Titan Zulfiqar → [Heavy] var")
	t.eq(KeywordSystem.value(zulfiqar, &"injury_modifier", 0), 2, "Titan Zulfiqar → +2 Injury MODIFIER (sabit, zar değil)")
	t.eq(zulfiqar.injury_dice_modifier, 0, "Titan Zulfiqar → Injury DICE eklemez (compendium: [+2 Injury Modifier])")
	t.ok(not zulfiqar.is_deadly, "Titan Zulfiqar → is_deadly artık YOK (compendium'da desteklenmiyordu)")
	t.ok(not zulfiqar.is_cumbersome, "Titan Zulfiqar → is_cumbersome artık YOK")
	t.ok(not zulfiqar.ignore_armour, "Titan Zulfiqar → ignore_armour artık YOK")

	# Assassin's Dagger (Sultanate Assassin): melee.md — [+1 Injury Modifier][Critical].
	var dagger = load("res://assets/data/attacks/assassins_dagger.tres")
	t.ok(KeywordSystem.has(dagger, &"critical"), "Assassin's Dagger → [Critical] var")
	t.eq(KeywordSystem.value(dagger, &"injury_modifier", 0), 1, "Assassin's Dagger → +1 Injury MODIFIER (sabit)")
	t.eq(dagger.injury_dice_modifier, 0, "Assassin's Dagger → Injury DICE eklemez")
	t.ok(not dagger.is_assault, "Assassin's Dagger → [Assault] YOK (compendium bloğunda yok)")
	t.ok(not dagger.is_deadly, "Assassin's Dagger → is_deadly artık YOK (compendium'da desteklenmiyordu)")
	t.ok(not dagger.is_poison, "Assassin's Dagger → is_poison artık YOK")
	# SLASHING ATTACK (battlekit/melee.md): "at least one Blood Marker... Dash Action to Retreat...
	# enemy models within 1" cannot make a Melee Attack." Trigger/exemption'ın canlı (async/RPC'li
	# resolve_injury_roll + can_perform_action) kısmı court_goetic_test.gd'deki async notuyla AYNI
	# nedenle burada headless test edilemiyor — yalnızca veri katmanı (keyword) kilitleniyor.
	t.ok(KeywordSystem.has(dagger, &"slashing_attack"), "Assassin's Dagger → [Slashing Attack] keyword'ü var")

	# unit.gd::sync_ability_flags Slashing Attack için 4. parametreye genişletildi (geriye dönük
	# uyumlu varsayılan=false) — statik kaynak analiziyle imza regresyonu kilitleniyor.
	var unit_src := FileAccess.get_file_as_string("res://scenes/unit/unit.gd")
	t.ok(unit_src.contains("func sync_ability_flags(p_hidden: bool, p_fortify: bool, p_shadow: bool, p_slashing: bool = false):"),
		"sync_ability_flags → slashing_attack_active parametresiyle genişletildi")
	t.ok(unit_src.contains("var slashing_attack_active: bool = false"),
		"unit.gd → slashing_attack_active alanı tanımlı")

	var actions_src := FileAccess.get_file_as_string("res://scripts/unit/unit_actions.gd")
	t.ok(actions_src.contains("slashing_dash_exempt"),
		"unit_actions.gd → Slashing Attack Dash-while-engaged istisnası kayıtlı")

	# Greatsword/Axe (base): melee.md — [+1 Injury Dice][Critical][Heavy], HİÇ Cleave YOK.
	var mamluk_gs = load("res://assets/data/attacks/mamluk_greatsword.tres")
	t.ok(KeywordSystem.has(mamluk_gs, &"critical"), "Mamluk Greatsword → [Critical] var")
	t.ok(not KeywordSystem.has(mamluk_gs, &"heavy"),
		"Mamluk Greatsword → [Heavy] YOK (Martial Prowess: 'The Mamluk's Greatsword does not have the HEAVY Keyword' — RAW istisnası)")
	t.ok(not mamluk_gs.has_cleave, "Mamluk Greatsword → Cleave YOK (compendium'da hiç yok, kopyala-yapıştır hatasıydı)")

	# Anointed Greatsword compendium'da YOK (uydurma silahtı) — AHI artık gerçek Greatsword/Axe taşır.
	t.ok(not ResourceLoader.exists("res://assets/data/attacks/anointed_greatsword.tres"),
		"Uydurma 'Anointed Greatsword' kaldırıldı (compendium'da yok)")

	# Anointed Heavy Infantry zaten unit-seviyesinde strong+negate_heavy taşıyor — Heavy eklenmesi
	# davranışı DEĞİŞTİRMEZ (zaten negate ediliyordu), yalnız veri doğruluğu için.
	var ahi_ud = load("res://assets/data/units/anointed_heavy_infantry.tres")
	t.ok(KeywordSystem.negates(ahi_ud, &"heavy"),
		"Anointed Heavy Infantry → Heavy zaten unit-seviyesinde negate ediliyor (davranış değişmedi)")
