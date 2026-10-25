## UnitVisuals
## Birimin görsel geri bildirim, seçim halkası ve faksiyon renklerini yöneten alt sınıf.
class_name UnitVisuals
extends RefCounted

# Static material cache for sharing StandardMaterial3D instances
static var _material_cache: Dictionary = {}
static var _flash_material_cache: Dictionary = {}

var unit: CharacterBody3D

func _init(p_unit: CharacterBody3D):
	unit = p_unit

func apply_owner_color():
	# TEK DOĞRU KAYNAK: oyuncunun SEÇTİĞİ faction (GameState.player_factions) — unit_data.
	# faction_id'ye DEĞİL. QA denetimi (2026-07-16): paylaşılan mercenary birimlerinin (Combat
	# Biologist/Communicant ATH/Mamluk Faris vb.) kendi .tres'lerindeki faction_id genelde "ev
	# sahibi" faction'a hardcoded'dır (örn. combat_biologist.tres → iron_sultanate) — o mercenary
	# BAŞKA bir faction (New Antioch gibi) tarafından deploy edildiğinde eskiden yanlış faction'ın
	# rengiyle boyanırdı. owner_id zaten biliniyor, o oyuncunun gerçek faction'ı buradan okunur.
	var player_faction = GameState.get_faction_for_player(unit.owner_id)
	var faction_id: StringName = player_faction.faction_id if player_faction != null else \
		(unit.unit_data.faction_id if unit.unit_data else &"")

	var cache_key = str(faction_id) + "_" + str(unit.owner_id)

	_apply_team_ring_color(player_faction if player_faction != null else GameState.get_faction_by_id(faction_id))

	if _material_cache.has(cache_key):
		unit.mesh_instance.set_surface_override_material(0, _material_cache[cache_key])
		return

	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.roughness = 0.5
	mat.metallic = 0.1

	var colors = GameVisualColors.get_colors()

	var faction = player_faction
	if faction == null:
		faction = GameState.get_faction_by_id(faction_id)

	var raw_color: Color
	if faction and "team_color" in faction:
		raw_color = faction.team_color
	else:
		raw_color = colors.unit_default if colors else Color(0.6, 0.6, 0.6)

	# Kaide rengi: Tamamen opak (saydam değil), faksiyon renginin daha açık ve yumuşatılmış pastel tonu
	mat.albedo_color = raw_color.lightened(0.25)

	_material_cache[cache_key] = mat
	unit.mesh_instance.set_surface_override_material(0, mat)

## Takım halkası (unit.tscn/TeamRing, team_ring.gdshader) — faksiyon rengini instance
## uniform olarak alır; materyal tüm birimlerde ortaktır.
func _apply_team_ring_color(faction: Resource) -> void:
	var ring: GeometryInstance3D = unit.get_node_or_null("TeamRing")
	if ring == null:
		return
	var colors = GameVisualColors.get_colors()
	var c: Color = faction.team_color if (faction != null and "team_color" in faction) else colors.unit_default
	ring.set_instance_shader_parameter("team_color", c.lightened(0.2))
	refresh_team_ring()

## Takım halkası aktivasyon durumunu gösterir (ActivationCues): şimdi oynatılabilir model nabız
## atar, aktivasyonu süren modelin çevresinde dönen çember belirir, bekleyen/bitmiş modelin
## halkası söner — oyuncu kimin oynayabileceğini haritaya bakarak görür.
func refresh_team_ring() -> void:
	var ring: GeometryInstance3D = unit.get_node_or_null("TeamRing")
	if ring == null:
		return
	var cue: StringName = unit.get_meta("activation_cue", &"")
	var vigor: float = 1.0
	if unit.has_moved:
		vigor = 0.0
	elif cue == ActivationCues.WAITING:
		vigor = 0.55
	ring.set_instance_shader_parameter("vigor", vigor)
	var pulse: float = 1.0 if cue == ActivationCues.READY else (2.0 if cue == ActivationCues.ACTIVE else 0.0)
	ring.set_instance_shader_parameter("pulse", pulse)

func update_selection_ring():
	refresh_team_ring()
	if not unit.selection_ring:
		return

	var mat = unit.selection_ring.get_surface_override_material(0)
	if not mat:
		var base_mesh = unit.selection_ring.mesh as TorusMesh
		if base_mesh and base_mesh.material:
			mat = base_mesh.material.duplicate()
			unit.selection_ring.set_surface_override_material(0, mat)

	if not mat:
		return

	var colors = GameVisualColors.get_colors()
	if unit.is_selected:
		unit.selection_ring.visible = true
		if unit.is_activatable():
			# Aktif seçim — parlak halka: bu birim şu an eylem yaptırılabilir.
			mat.albedo_color = colors.selection_selected
			mat.emission = Color(colors.selection_selected.r, colors.selection_selected.g, colors.selection_selected.b, 1.0)
			mat.emission_energy_multiplier = 3.5
		else:
			# İnceleme seçimi — sönük halka: birim seçili ama (düşman / bu tur aktive olmuş / Down)
			# eylem yaptırılamaz. Parlak halkanın "hazır" yanılsaması önlenir (P0-C).
			mat.albedo_color = colors.selection_valid_target
			mat.emission = Color(colors.selection_valid_target.r, colors.selection_valid_target.g, colors.selection_valid_target.b, 1.0)
			mat.emission_energy_multiplier = 1.0
	elif unit.is_targeted:
		unit.selection_ring.visible = true
		mat.albedo_color = colors.selection_targeted
		mat.emission = Color(colors.selection_targeted.r, colors.selection_targeted.g, colors.selection_targeted.b, 1.0)
		mat.emission_energy_multiplier = 4.0
	elif unit.is_valid_target:
		# Sade, dikkat dağıtmayan geçerli-hedef vurgusu (nötr, düşük parlaklık).
		# P2-5: hedef siperdeyse amber renk — oyuncu −1 DICE Cover cezasını saha üzerinde görür.
		unit.selection_ring.visible = true
		var col: Color = colors.selection_cover if unit.is_cover_highlighted else colors.selection_valid_target
		mat.albedo_color = col
		mat.emission = Color(col.r, col.g, col.b, 1.0)
		mat.emission_energy_multiplier = 1.7 if unit.is_cover_highlighted else 1.4
	else:
		unit.selection_ring.visible = false

func play_damage_effect():
	var target_node = unit.model_node if is_instance_valid(unit.model_node) else unit.mesh_instance
	if not is_instance_valid(target_node):
		return
	GameLogger.log_info("%s hasar efekti (sallantı) uygulanıyor. Düğüm: %s" % [unit.display_name, target_node.name], "COMBAT")

	var original_pos = target_node.position
	# Yalnızca piyonun kendi mesh'lerini bul (göstergeleri karıştırma)
	var meshes = _find_all_meshes(target_node)
	var original_materials = {}

	for m in meshes:
		if is_instance_valid(m) and m != unit.selection_ring:
			var mat = m.get_surface_override_material(0)
			if not mat and m.mesh and "material" in m.mesh:
				mat = m.mesh.material
			if mat is BaseMaterial3D:
				original_materials[m] = {
					"mat": mat
				}
				var flash_mat = _flash_material_cache.get(mat)
				if not flash_mat:
					flash_mat = mat.duplicate()
					flash_mat.emission_enabled = true
					var colors = GameVisualColors.get_colors()
					flash_mat.emission = colors.damage_flash
					flash_mat.emission_energy_multiplier = 5.0
					_flash_material_cache[mat] = flash_mat
				m.set_surface_override_material(0, flash_mat)

	var tween = unit.create_tween()
	tween.set_parallel(false)
	for i in range(6):
		var offset = Vector3(randf_range(-0.35, 0.35), 0, randf_range(-0.35, 0.35))
		tween.tween_property(target_node, "position", original_pos + offset, 0.04)
	tween.tween_property(target_node, "position", original_pos, 0.04)

	await tween.finished

	for m in original_materials:
		if is_instance_valid(m):
			m.set_surface_override_material(0, original_materials[m]["mat"])

## Yetenek geri bildirimi — DOST/pozitif etki: model hafifçe yukarı kalkıp iner (nazik "bob").
## Renk YOK (kullanıcı isteği). "Buton işe yaradı" hissini hareketle verir.
func play_effect_bob() -> void:
	var target_node = unit.model_node if is_instance_valid(unit.model_node) else unit.mesh_instance
	if not is_instance_valid(target_node):
		return
	var base_pos = target_node.position
	var tween = unit.create_tween()
	tween.tween_property(target_node, "position", base_pos + Vector3(0, 0.25, 0), 0.14) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(target_node, "position", base_pos, 0.20) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

## Yetenek geri bildirimi — DÜŞMAN/negatif etki: model kısa süre titrer (renk YOK; hasar
## efektinden farklı olarak flash yapmaz, yalnız hafif sarsıntı).
func play_effect_shake() -> void:
	var target_node = unit.model_node if is_instance_valid(unit.model_node) else unit.mesh_instance
	if not is_instance_valid(target_node):
		return
	var base_pos = target_node.position
	var tween = unit.create_tween()
	for _i in range(6):
		var off = Vector3(randf_range(-0.16, 0.16), 0, randf_range(-0.16, 0.16))
		tween.tween_property(target_node, "position", base_pos + off, 0.04)
	tween.tween_property(target_node, "position", base_pos, 0.04)

func _find_all_meshes(node: Node) -> Array:
	var list = []
	if node is MeshInstance3D:
		list.append(node)
	for child in node.get_children():
		list.append_array(_find_all_meshes(child))
	return list
