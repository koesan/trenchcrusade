class_name DeployZoneOverlay
extends Node3D

## YERLEŞTİRME BÖLGESİ GÖSTERGESİ — iki oyuncunun ScenarioData.p1/p2_deploy_zone bölgesini
## haritada gösterir. Yalnız DEPLOYMENT fazında görünür (kullanıcı isteği: "unit yerleştirme
## bitince saydam kısım kalksın, oyun normal haline dönsün"). Bölge sahibi belli olunca o
## oyuncunun faksiyon rengini alır. Sinyallerini kendisi dinler; game.gd yalnız setup() çağırır.
## (game.gd'den ayrıldı — architecture_health_test satır tavanı.)

var _zones: Array[Decal] = []

func _ready() -> void:
	GameState.game_phase_changed.connect(_on_phase_changed)
	GameState.deploy_side_chosen.connect(refresh_colors)
	GameState.faction_selected.connect(refresh_colors)

## SAHA GÖSTERGESİ: p1/p2_deploy_zone Rect2'lerinden (XZ düzlemi — scenario_logic.gd
## is_valid_deploy_position ile AYNI eksen eşlemesi) iki yuvarlak köşeli, İÇİ BOŞ (bilezik)
## zemin halkası kurar. Kullanıcı isteği: "harita kadar uzun/geniş olsun, gereksiz büyük olmasın"
## — bu yüzden mantıksal bölge (oynanışı etkilemez) GÖRSEL olarak gerçek savaş alanı sınırlarına
## (GameState.battlefield_bounds, navmesh'ten hesaplanır) kırpılır.
func setup(scenario_data) -> void:
	for m in _zones:
		if is_instance_valid(m):
			m.queue_free()
	_zones.clear()
	if scenario_data == null:
		return

	var bounds_rect := Rect2()
	if GameState.battlefield_bounds.size.x > 0.0 and GameState.battlefield_bounds.size.z > 0.0:
		bounds_rect = Rect2(GameState.battlefield_bounds.position.x, GameState.battlefield_bounds.position.z,
			GameState.battlefield_bounds.size.x, GameState.battlefield_bounds.size.z)

	# DECAL: gösterge arazinin ÜSTÜNE yansıtılır (plato, siper tabanı, rampa). Eskiden y=0'da
	# derinlik testi kapalı düz bir düzlemdi — harita yüzeyi y≈-1.6/-6 olduğu için perspektifte
	# haritanın dışına, boşluğa taşıyormuş gibi görünüyordu.
	var b: AABB = GameState.battlefield_bounds
	var y_center: float = b.get_center().y if b.size.y > 0.0 else 0.0
	var y_size: float = (b.size.y if b.size.y > 0.0 else 20.0) + 4.0
	for zone_rect in [scenario_data.p1_deploy_zone, scenario_data.p2_deploy_zone]:
		var visual_rect: Rect2 = zone_rect
		if bounds_rect.size.x > 0.0:
			var clipped: Rect2 = zone_rect.intersection(bounds_rect)
			if clipped.size.x > 1.0 and clipped.size.y > 1.0:
				visual_rect = clipped

		var decal := Decal.new()
		decal.size = Vector3(visual_rect.size.x, y_size, visual_rect.size.y)
		decal.texture_albedo = _zone_texture(visual_rect.size)
		decal.normal_fade = 0.55          # siper duvarları gibi dik yüzeylere bulaşmasın
		decal.position = Vector3(visual_rect.position.x + visual_rect.size.x * 0.5, y_center,
			visual_rect.position.y + visual_rect.size.y * 0.5)
		decal.visible = GameState.game_phase == GameState.GamePhase.DEPLOYMENT
		add_child(decal)
		_zones.append(decal)

	refresh_colors()

## Overlay yalnız DEPLOYMENT fazında görünür — faction seçiminden unit yerleştirmenin sonuna
## kadar. BATTLE'a geçince (kullanıcı isteği) kaybolup oyun normal haline döner.
func _on_phase_changed(phase_idx: int) -> void:
	var visible_now: bool = phase_idx == GameState.GamePhase.DEPLOYMENT
	for m in _zones:
		if is_instance_valid(m):
			m.visible = visible_now

## SAHA RENKLENDİRME (kullanıcı isteği): bir bölgenin sahibi belirlenene kadar (ilk unit o
## bölgeye yerleştirilene dek — bkz. request_deploy_unit) İKİ bölge de nötr/bej kalır. Sahip
## belli olunca VE o oyuncu faksiyonunu seçmişse bölge o faksiyonun rengini (FactionData.
## team_color) alır. Hem GameState.deploy_side_chosen (saha örtük belirlenince) hem
## GameState.faction_selected (ikinci oyuncu kendi faksiyonunu seçince) bunu tetikler.
func refresh_colors(_a = null, _b = null) -> void:
	if _zones.size() < 2:
		return
	var colors := GameVisualColors.get_colors()
	var neutral: Color = colors.deploy_zone_neutral if colors else Color(0.82, 0.68, 0.32, 0.22)

	for i in range(2):
		var zone_node = _zones[i]
		if not is_instance_valid(zone_node) or not (zone_node is Decal):
			continue
		var owner_id := 0
		if GameState.zone_a_owner_id != 0:
			owner_id = GameState.zone_a_owner_id if i == 0 else (2 if GameState.zone_a_owner_id == 1 else 1)
		var final_color := neutral
		if owner_id != 0:
			var faction: Resource = GameState.get_faction_for_player(owner_id)
			if faction != null and "team_color" in faction:
				final_color = faction.team_color.lightened(0.15)
		# Saydamlık dokuda (kenar şeridi opak, iç alan çok hafif); modulate yalnız ton + genel yoğunluk.
		final_color.a = ZONE_DECAL_STRENGTH
		zone_node.modulate = final_color

const ZONE_DECAL_STRENGTH := 0.9
## Dokuda 1 inç = bu kadar piksel.
const ZONE_TEX_PX_PER_INCH := 8.0
const ZONE_EDGE_INCHES := 0.45
const ZONE_FILL_ALPHA := 0.05
const ZONE_CORNER_INCHES := 2.5

## Yuvarlak köşeli bölge çerçevesi + çok hafif iç dolgu (beyaz; renk decal modulate'ından gelir).
static func _zone_texture(rect_size: Vector2) -> ImageTexture:
	var w := int(clampf(rect_size.x * ZONE_TEX_PX_PER_INCH, 16.0, 512.0))
	var h := int(clampf(rect_size.y * ZONE_TEX_PX_PER_INCH, 16.0, 512.0))
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var px_per_in := Vector2(w / rect_size.x, h / rect_size.y)
	var half := rect_size * 0.5
	var r := minf(ZONE_CORNER_INCHES, minf(half.x, half.y) * 0.8)
	for y in h:
		for x in w:
			# Piksel merkezinin inç cinsinden konumu (dikdörtgen merkezine göre)
			var p := Vector2((x + 0.5) / px_per_in.x, (y + 0.5) / px_per_in.y) - half
			var q := Vector2(absf(p.x), absf(p.y)) - half + Vector2(r, r)
			var d := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - r
			var edge := clampf(1.0 - absf(d + ZONE_EDGE_INCHES * 0.5) / (ZONE_EDGE_INCHES * 0.5), 0.0, 1.0)
			var a := maxf(smoothstep(0.0, 0.6, edge), ZONE_FILL_ALPHA if d < 0.0 else 0.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
