extends RefCounted

## YETENEK KAYIT DEFTERİ SÖZLEŞMESİ.
##
## Eskiden iki elle-bakımlı liste vardı — `CUSTOM_IMPLEMENTED` dizisi (butonun görünürlüğü) ve
## `_handle_custom()` içindeki `match ability_id` dalı (asıl çağrı). Biri diğerinden saparsa
## ya "hiçbir şey yapmayan buton" ya da "uygulanmış ama hiç gösterilmeyen yetenek" doğuyordu.
## Artık tek kaynak `AbilityRegistry.CUSTOM`; bu test o kaydın gerçekten çalışır olduğunu ve
## VERİYLE (assets/data/abilities/*.tres) tutarlı kaldığını doğrular.

const ABILITY_DIR := "res://assets/data/abilities"

## Alt sistemi eksik olduğu için BİLİNÇLİ olarak uygulanmamış custom yetenekler.
## (Boş olması iyi bir haber — buraya bir şey eklemek "ertelendi" demektir, "unutuldu" değil.)
const KNOWN_DEFERRED: Array[StringName] = []

func _all_abilities() -> Array:
	var out: Array = []
	var d := DirAccess.open(ABILITY_DIR)
	if d == null:
		return out
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		if f.ends_with(".tres"):
			var res: Resource = load(ABILITY_DIR.path_join(f))
			if res != null:
				out.append(res)
		f = d.get_next()
	d.list_dir_end()
	return out

func run(t) -> void:
	# ── 1. Kayıtlı her handler sözleşmeyi sunuyor mu? ──────────────────────
	var ids: Array = AbilityRegistry.implemented_ids()
	t.ok(ids.size() >= 16, "Kayıtta %d custom handler var" % ids.size())
	for id in ids:
		var h: GDScript = AbilityRegistry.handler_for(id)
		t.ok(h != null, "%s → handler yüklendi" % id)
		if h != null:
			t.ok(h.has_method("apply"), "%s → apply(ctx) sunuyor" % id)

	# Kayıtta olmayan bir id için null dönmeli (çökmemeli).
	t.eq(AbilityRegistry.handler_for(&"__olmayan_yetenek__"), null,
		"Bilinmeyen ability_id → null (çökmez)")
	t.ok(not AbilityRegistry.is_implemented(&"__olmayan_yetenek__"),
		"Bilinmeyen ability_id → is_implemented false")

	# ── 2. Kayıt ile VERİ tutarlı mı? ─────────────────────────────────────
	var abilities: Array = _all_abilities()
	t.ok(abilities.size() > 50, "%d yetenek .tres'i tarandı" % abilities.size())

	# ÖNEMLİ AYRIM: `effect_type = "custom"` olan yeteneklerin ÇOĞU PASİFTİR (`action_key` boş) —
	# mekanikleri keyword'ler/resolver'lar üzerinden işler, `AbilityExecutor`den HİÇ geçmezler ve
	# handler'a ihtiyaç duymazlar. Handler yalnız AKSİYON BUTONU üreten (action_key dolu ve temel
	# eylemlerle çakışmayan) custom yetenekler için zorunludur — aksi hâlde tıklanabilir ama
	# hiçbir şey yapmayan bir buton doğar.
	var base_actions := ["move", "charge", "retreat", "dash", "melee", "shoot"]
	var unknown_effect: Array = []
	var custom_without_handler: Array = []
	var actionable_custom := 0
	for ab in abilities:
		if not (ab.effect_type in AbilityEffects.EFFECT_TYPES):
			unknown_effect.append("%s(%s)" % [ab.ability_id, ab.effect_type])
		if ab.effect_type != "custom":
			continue
		if ab.action_key == "" or ab.action_key in base_actions:
			continue  # pasif ya da temel eylemle çakışan → handler gerekmez
		actionable_custom += 1
		if not AbilityRegistry.is_implemented(ab.ability_id) \
				and not KNOWN_DEFERRED.has(ab.ability_id):
			custom_without_handler.append(String(ab.ability_id))
	t.ok(actionable_custom > 0, "%d AKSİYON üreten custom yetenek var" % actionable_custom)

	# Tanınmayan bir effect_type, yeteneği SESSİZCE etkisiz bırakır (dispatcher hiçbir dala girmez).
	t.eq(unknown_effect.size(), 0,
		"Tanınmayan effect_type yok (AbilityEffects.EFFECT_TYPES): %s" % str(unknown_effect))

	# effect_type="custom" ama handler'ı olmayan yetenek = tıklanabilir ölü buton riski.
	t.eq(custom_without_handler.size(), 0,
		"Handler'ı olmayan custom yetenek yok: %s" % str(custom_without_handler))

	# ── 3. Kayıtta OLUP veride karşılığı olmayan handler (ölü kod) ────────
	var data_custom_ids: Array = []
	for ab in abilities:
		if ab.effect_type == "custom":
			data_custom_ids.append(ab.ability_id)
	# (Burada pasifler de sayılır: bir handler'ın verisi HİÇ yoksa o kayıt ölü koddur.)
	var orphan_handlers: Array = []
	for id in ids:
		if not data_custom_ids.has(id):
			orphan_handlers.append(String(id))
	t.eq(orphan_handlers.size(), 0,
		"Verisi olmayan (ölü) handler kaydı yok: %s" % str(orphan_handlers))

	# ── 4. Çalıştırıcı gerçekten registry'yi kullanıyor mu? ───────────────
	var src := FileAccess.open("res://scripts/rules/ability_executor.gd", FileAccess.READ)
	t.ok(src != null, "ability_executor.gd okunabildi")
	if src != null:
		var txt := src.get_as_text()
		src.close()
		t.ok(txt.contains("AbilityRegistry.handler_for"),
			"Çalıştırıcı handler'ı registry'den alıyor")
		# (Yorumda adının geçmesi serbest — aranan, listenin TANIMI ve KULLANIMI.)
		t.ok(not txt.contains("const CUSTOM_IMPLEMENTED"),
			"Elle bakımlı CUSTOM_IMPLEMENTED listesi geri TANIMLANMADI")
		t.ok(not txt.contains("CUSTOM_IMPLEMENTED.has("),
			"CUSTOM_IMPLEMENTED artık KULLANILMIYOR (tek kaynak registry)")
		t.ok(not txt.contains("func _handle_custom"),
			"Dev `match ability_id` dalı geri gelmedi")

	# ── 5. AbilityContext sözleşmesi ─────────────────────────────────────
	var ctx := AbilityContext.create(abilities[0], null, null, 9, true, "x")
	t.eq(ctx.roll_total, 9, "AbilityContext.roll_total taşınıyor")
	t.eq(ctx.is_crit, true, "AbilityContext.is_crit taşınıyor")
	t.eq(ctx.extra_param, "x", "AbilityContext.extra_param taşınıyor")
	t.ok(ctx.ability != null, "AbilityContext.ability taşınıyor")
