## Birim konuşlanma kancaları — unit.gd'den ayrıldı (o dosya satır sınırında).
##
## İki ayrı tür durum var ve kayıt/yükleme ikisini farklı ele alır:
##   • İLK KONUŞLANMA kancaları oyunda bir kez çalışır (oyuncuya seçim sorar / sahaya parça koyar);
##     kayıttan yüklemede ÇALIŞMAZ — sonuçları kayıttan gelir.
##   • LOADOUT'tan türeyen durum her eşte ve her yüklemede aynı biçimde yeniden kurulur.
class_name UnitDeployHooks

## Konuşlanmada BİR KEZ çalışan kural kancaları (oyuncu seçimi / sahaya parça koyma). Sunucu
## otoritesi: çok oyunculuda konuşlanmadan sonra sunucuda çağrılır (bkz. game._spawn_deployed_unit).
static func run_first_deploy(unit) -> void:
	if unit.unit_data == null:
		return
	# MASTERY OF THE ELEMENTS (Alchemist, iron-sultanate.md): "When this model is deployed for
	# the FIRST TIME in a game, YOU CAN GIVE one of the following Keywords to all of the
	# Alchemist's Weapons: [Fire] OR [Gas] OR [Shrapnel]." Seçim OYUNCUNUNdur — eskiden koda
	# `fire` sabitlenmişti ve oyuncu ilk turunu Elemental Change'e harcamak zorunda kalıyordu
	# (denetim bulgusu P1-IS-4a). Varsayılan `fire` korunur; seçim UI yoksa akış kilitlenmez.
	if KeywordSystem.has(unit.unit_data, &"mastery_of_elements"):
		unit.current_element = &"fire"
		unit._request_mastery_element_choice.call_deferred()
	# DUG IN (Combat Engineer'ın Şovel'i, P1-1): "a model equipped with a Shovel that starts
	# the game on Open terrain has [Cover] until it moves away from its starting position."
	# Fortify ile AYNI mekanizma (has_fortify_cover, ilk harekette otomatik temizlenir —
	# unit.gd break_stealth_on_own_action). Basitleştirme: "Open terrain" şartı taşınmadı
	# (proje terrain-tipini ayırt etmiyor) — tüm Şovel taşıyıcılara koşulsuz uygulanır.
	if KeywordSystem.has(unit.unit_data, &"dug_in"):
		FortifyActions.apply_dug_in.call_deferred(unit)

## Seçilen loadout'tan TÜREYEN durum — her eşte (ve kayıttan yüklemede) aynı biçimde kurulur.
static func apply_loadout_side_effects(unit) -> void:
	if unit.unit_data == null:
		return
	# BROKEN ON THE WHEEL (Anchorite Shrine, P1-1): "Broken on the Wheel" loadout'u seçildiyse
	# (armour_override=0 zaten LoadoutOption ile uygulandı) has_tough/negate_shrapnel bu birime
	# ÖZGÜ unit_data kopyasından (LoadoutResolver zaten .duplicate(true) yapar, güvenli) geçici
	# olarak çıkarılır — ilk Out of Action'da injury_resolver.gd normale döndürür.
	if KeywordSystem.has(unit.unit_data, &"broken_on_wheel_chosen"):
		unit.broken_on_wheel_active = true
		unit.unit_data.has_tough = false
		unit.unit_data.keywords.erase(&"negate_shrapnel")
