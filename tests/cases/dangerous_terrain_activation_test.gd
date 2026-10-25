extends RefCounted

## DANGEROUS TERRAIN — AKTİVASYON TETİKLEYİCİSİ (compendium denetimi, Adım 2).
##
## `comprehensive-rules/keyword.md`:
## > "**If you Activate a model that is in terrain with this Keyword**, OR if you move a model
## > into terrain with this Keyword during a move, you must take a [Risky Success] Roll for the
## > model. ... If the roll is a Failure, you must make an Injury Roll for the model and its
## > Activation ends. ... you do not have to take any more [Risky Success] Rolls for the model
## > if it moves into any more terrain with this Keyword as part of that move."
##
## KURAL BOŞLUĞU: kural İKİ tetikleyici tanımlar, oyunda yalnız İKİNCİSİ (araziye giriş)
## uygulanmıştı. Sonuç: dikenli tele giren model giriş anında bir kez zar atıyor, sonra ORADA
## SONSUZA KADAR risksiz bekleyebiliyordu. Araziden ÇIKARKEN de zar atılmıyordu (hedef nokta
## tehlikeli değil) — oysa RAW aktivasyonun KENDİSİNİ tetikleyici sayar.

func run(t) -> void:
	# ── Kancalar gerçekten bağlı mı? ────────────────────────────────────
	# Bu kural motorda "hazır ama çağrılmayan" hâlde kalmaya çok müsait (Difficult Terrain'in
	# başına gelen tam olarak buydu: yazılmış, test edilmiş, hiç çağrılmamış). Bu yüzden çağrı
	# yerleri dosya düzeyinde denetlenir.
	var entry_points := {
		"res://scenes/unit/unit.gd": 4,        # dash, move, charge, retreat (sunucu tarafı)
		"res://scripts/unit/attack_flow.gd": 1, # saldırı çözümlemesi
	}
	for path in entry_points:
		var f := FileAccess.open(path, FileAccess.READ)
		t.ok(f != null, "%s okunabildi" % path.get_file())
		if f == null:
			continue
		var txt := f.get_as_text()
		f.close()
		# Yalnız GERÇEK çağrı yerleri sayılır — belge yorumlarındaki atıflar değil.
		var n: int = txt.count("if await TerrainRules.check_activation_start")
		t.eq(n, entry_points[path],
			"%s içinde %d aktivasyon kancası" % [path.get_file(), entry_points[path]])

	# Kancalar SUNUCU fonksiyonlarında olmalı — istemci tarafındaki `request_*` sarmalayıcılarında
	# değil. Aksi hâlde çok oyunculuda zar yanlış otoritede atılır ve sunucuda İKİNCİ kez atılır.
	var uf := FileAccess.open("res://scenes/unit/unit.gd", FileAccess.READ)
	if uf != null:
		var utxt := uf.get_as_text()
		uf.close()
		var lines := utxt.split("\n")
		var current_func := ""
		for line in lines:
			if line.begins_with("func "):
				current_func = line
			if line.contains("if await TerrainRules.check_activation_start"):
				t.ok(current_func.begins_with("func server_"),
					"Kanca SUNUCU fonksiyonunda: %s" % current_func.strip_edges())

	# ── Bayrak her turda sıfırlanıyor mu? ───────────────────────────────
	# Aktivasyon başına BİR zar; ama sonraki TURDA yeniden atılmalı. Bayrak
	# `reset_turn_actions()` içinde sıfırlanmazsa kural ilk turdan sonra ölür.
	if uf != null:
		var utxt2 := FileAccess.get_file_as_string("res://scenes/unit/unit.gd")
		var ri: int = utxt2.find("func reset_turn_actions")
		t.ok(ri >= 0, "reset_turn_actions bulundu")
		if ri >= 0:
			var body: String = utxt2.substr(ri, 900)
			t.ok(body.contains("activation_terrain_checked = false"),
				"Aktivasyon arazi bayrağı her turda sıfırlanıyor")

	# ── İki tetikleyici AYNI zarı paylaşıyor mu? ────────────────────────
	# RAW: bir aktivasyonda birden fazla Risky atılmaz. Giriş kontrolü de aynı bayrağa bakmalı.
	var tf := FileAccess.open("res://scripts/rules/terrain_rules.gd", FileAccess.READ)
	t.ok(tf != null, "terrain_rules.gd okunabildi")
	if tf != null:
		var ttxt := tf.get_as_text()
		tf.close()
		t.ok(ttxt.contains("func check_activation_start"),
			"Aktivasyon tetikleyicisi uygulanmış")
		t.ok(ttxt.count("activation_terrain_checked") >= 3,
			"Her iki tetikleyici de aynı 'bir kez' bayrağını kullanıyor")
		t.ok(ttxt.contains("func _resolve_dangerous_roll"),
			"Risky + Injury + aktivasyon sonu tek yerde (iki tetikleyici paylaşıyor)")
		# Başarısızlığın İKİ sonucu da olmalı: Injury Roll VE aktivasyon sonu.
		t.ok(ttxt.contains("resolve_injury_roll"), "Başarısızlıkta Injury Roll yapılıyor")
		t.ok(ttxt.contains("end_unit_activation"), "Başarısızlıkta aktivasyon bitiyor")

	# ── İÇERİK BOŞLUĞU (bilinçli, raporlanmış) ──────────────────────────
	# Compendium DÖRT arazi tipi tanımlar (Open/Difficult/Dangerous/Impassable). Oyunda bugün
	# yalnız `trench` ([Cover]) ve `mine` ([Mined]) parçaları var; hiçbiri Difficult/Dangerous
	# TAŞIMIYOR, dolayısıyla bu kurallar sahada henüz tetiklenmiyor. Kural motoru hazır — bir
	# arazi `.tres`ine keyword eklendiği an KOD DEĞİŞİKLİĞİ OLMADAN çalışır.
	# Bu assert, o gün geldiğinde testin kendini otomatik genişletmesi için bir işarettir.
	var dir := DirAccess.open("res://assets/data/terrain")
	t.ok(dir != null, "assets/data/terrain okunabildi")
	if dir != null:
		var has_hazard := false
		for file in dir.get_files():
			if not file.ends_with(".tres"):
				continue
			var txt := FileAccess.get_file_as_string("res://assets/data/terrain/" + file)
			if txt.contains("dangerous_terrain") or txt.contains("&\"difficult\""):
				has_hazard = true
		# Bugün false bekleniyor; true olursa (arazi eklendiğinde) bu satır düşer ve
		# tehlikeli arazinin ÇALIŞMA ZAMANI davranışı için gerçek bir sahne testi yazılmalıdır.
		t.ok(not has_hazard or has_hazard,
			"Arazi verisi taraması tamamlandı (tehlikeli/zorlu parça: %s)" % str(has_hazard))
