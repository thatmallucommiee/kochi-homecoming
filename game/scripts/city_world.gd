extends Node
## Procedural, mobile-minded Kochi district for the Godot starter.
## Static architecture is batched into MultiMeshes; moving traffic and walkers remain individual agents.
## All coordinates are meters. No external runtime downloads are required.

const GRID := 96.0
const ROAD_WIDTH := 15.0
const ROAD_HALF := ROAD_WIDTH * 0.5
const SIDEWALK_WIDTH := 2.2
const WORLD_EDGE := GRID * 4.0 + 12.0
const WORLD_SIZE := GRID * 9.0 + 48.0
const CHUNK_SIZE := GRID * 3.0
const CITY_SEED := 20261014

var _rng := RandomNumberGenerator.new()
var _materials: Dictionary = {}
var _batches: Dictionary = {}
var _city_root: Node3D
var _active_scene: Node
var _traffic: Array[Dictionary] = []
var _walkers: Array[Dictionary] = []
var _clock := 0.0
var _built := false
var _sign_count := 0
var _tracked_player: Node3D
var _last_player_position := Vector3.ZERO
var _walk_distance := 0.0
var _home_walk_distance := 0.0
var _home_roof_root: Node3D
var _home_interior := false
var _interaction_key := ""

const HOUSE_PALETTE := [
	"wall_cream", "wall_pale_green", "wall_sky", "wall_ochre",
	"wall_rose", "wall_sand", "wall_white", "wall_mint"
]
const SHOP_NAMES := [
	"CHAYA KADA", "RAFI AUTO WORKS", "MALABAR BAKERY", "MEDICALS",
	"FAMILY STORE", "CITY TEXTILES", "FRESH MART", "HOTEL KOCHI",
	"MOBILE CARE", "COOL BAR", "TWO WHEELERS", "SUPERMARKET",
	"JUICE CORNER", "FISH MARKET", "SREE STORES", "BUS SERVICE"
]

func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	if scene != _active_scene or not is_instance_valid(_city_root):
		_active_scene = scene
		_install_city(scene)
	if not _built:
		return
	_clock += delta
	_update_traffic(delta)
	_update_walkers(delta)
	_update_story_triggers()

func _install_city(scene: Node) -> void:
	if not is_instance_valid(scene):
		return
	var existing := scene.get_node_or_null("KochiLivingDistrict")
	if existing is Node3D:
		_city_root = existing
		_built = true
		return
	_city_root = Node3D.new()
	_city_root.name = "KochiLivingDistrict"
	scene.add_child(_city_root)
	_rng.seed = CITY_SEED
	_materials.clear()
	_batches.clear()
	_traffic.clear()
	_walkers.clear()
	_sign_count = 0
	_make_materials()
	_apply_city_textures()
	_build_ground_and_roads()
	_build_buildings()
	_build_street_life()
	_build_landmarks()
	_build_story_landmarks()
	_flush_static_batches()
	_build_traffic()
	_build_parked_vehicles()
	_build_pedestrians()
	_build_idle_citizens()
	_setup_lighting(scene)
	_built = true
	print("KochiLivingDistrict ready: dense procedural neighborhood, road grid, buildings, traffic and pedestrians.")

func _make_materials() -> void:
	_mat("ground_concrete", Color("#686b65"), 0.95)
	_mat("ground_soil", Color("#594b3d"), 1.0)
	_mat("grass", Color("#485d3c"), 1.0)
	_mat("grass_light", Color("#617148"), 1.0)
	_mat("road", Color("#303337"), 0.95)
	_mat("road_patch", Color("#424449"), 1.0)
	_mat("road_white", Color("#d5d3c9"), 0.85)
	_mat("road_yellow", Color("#d2ae48"), 0.8)
	_mat("sidewalk", Color("#88877e"), 0.95)
	_mat("drain", Color("#343b3b"), 1.0)
	_mat("wall_cream", Color("#cbbd9e"), 0.9)
	_mat("wall_pale_green", Color("#98b19a"), 0.9)
	_mat("wall_sky", Color("#8fa9b5"), 0.9)
	_mat("wall_ochre", Color("#c6a56f"), 0.9)
	_mat("wall_rose", Color("#b98c84"), 0.9)
	_mat("wall_sand", Color("#b7aa91"), 0.9)
	_mat("wall_white", Color("#d4d0c3"), 0.9)
	_mat("wall_mint", Color("#a8bba5"), 0.9)
	_mat("wall_gray", Color("#858b8b"), 0.95)
	_mat("concrete", Color("#9a978d"), 0.95)
	_mat("floor_redoxide", Color("#914f3f"), 0.92)
	_mat("sofa_fabric", Color("#58604d"), 0.95)
	_mat("photo_paper", Color("#bbaa88"), 0.92)
	_mat("family_photo", Color("#fff1d2"), 0.96)
	_mat("glass_shards", Color("#8fabad"), 0.22)
	_mat("tire", Color("#252729"), 0.98)
	_mat("roof_red", Color("#79483b"), 0.95)
	_mat("roof_dark", Color("#41494d"), 0.9)
	_mat("wood", Color("#654b38"), 0.9)
	_mat("wood_light", Color("#8b6b4a"), 0.9)
	_mat("glass", Color("#253b42"), 0.25, Color("#101c20"), 0.15)
	_mat("glass_light", Color("#526b70"), 0.3)
	_mat("frame", Color("#d3c8b0"), 0.75)
	_mat("metal", Color("#4b5252"), 0.6)
	_mat("metal_light", Color("#8b918e"), 0.55)
	_mat("sign_red", Color("#963b2e"), 0.8)
	_mat("sign_blue", Color("#2c5368"), 0.8)
	_mat("sign_green", Color("#2c5e49"), 0.8)
	_mat("sign_yellow", Color("#d4a842"), 0.8)
	_mat("awning", Color("#b8553d"), 0.8)
	_mat("awning_green", Color("#4e7257"), 0.8)
	_mat("awning_blue", Color("#40677b"), 0.8)
	_mat("palm_trunk", Color("#6e5940"), 1.0)
	_mat("leaf_dark", Color("#2f5034"), 1.0)
	_mat("leaf_green", Color("#4f6a3a"), 1.0)
	_mat("bush", Color("#3e5a39"), 1.0)
	_mat("puddle", Color("#36464b"), 0.22)
	_mat("lamp_glow", Color("#e7b86a"), 0.4, Color("#e7b86a"), 1.4)
	_mat("cable", Color("#262c2b"), 0.8)
	_mat("car_white", Color("#d3d0c6"), 0.45)
	_mat("car_silver", Color("#929b9d"), 0.4, Color("#171a1b"), 0.05)
	_mat("car_blue", Color("#35576e"), 0.4)
	_mat("car_red", Color("#943f37"), 0.4)
	_mat("car_green", Color("#49624b"), 0.45)
	_mat("car_black", Color("#303538"), 0.4)
	_mat("auto_yellow", Color("#d2a92f"), 0.6)
	_mat("auto_green", Color("#305a43"), 0.55)
	_mat("bus_blue", Color("#587c98"), 0.5)
	_mat("shirt_blue", Color("#3b637a"), 0.9)
	_mat("shirt_white", Color("#c8c6ba"), 0.9)
	_mat("shirt_green", Color("#536b51"), 0.9)
	_mat("shirt_maroon", Color("#7a4443"), 0.9)
	_mat("shirt_ochre", Color("#b18b50"), 0.9)
	_mat("skin", Color("#9b6b4f"), 0.95)
	_mat("hair", Color("#242321"), 0.95)
	_mat("pants_dark", Color("#343b43"), 0.9)
	_mat("pants_blue", Color("#40566d"), 0.9)

func _apply_city_textures() -> void:
	var shader_resource := load("res://shaders/triplanar_city.gdshader") as Shader
	if shader_resource == null:
		push_warning("City surface shader was not available; using fallback flat materials.")
		return
	var texture_specs := {
		"road": {"file": "asphalt.svg", "scale": 0.34, "roughness": 0.96},
		"road_patch": {"file": "asphalt.svg", "scale": 0.30, "roughness": 0.98},
		"ground_concrete": {"file": "concrete.svg", "scale": 0.075, "roughness": 0.98},
		"sidewalk": {"file": "concrete.svg", "scale": 0.14, "roughness": 0.94},
		"drain": {"file": "concrete.svg", "scale": 0.28, "roughness": 1.0},
		"wall_cream": {"file": "plaster.svg", "scale": 0.34, "roughness": 0.92},
		"wall_pale_green": {"file": "plaster.svg", "scale": 0.34, "roughness": 0.92},
		"wall_sky": {"file": "plaster.svg", "scale": 0.34, "roughness": 0.92},
		"wall_ochre": {"file": "plaster.svg", "scale": 0.34, "roughness": 0.92},
		"wall_rose": {"file": "plaster.svg", "scale": 0.34, "roughness": 0.92},
		"wall_sand": {"file": "plaster.svg", "scale": 0.34, "roughness": 0.92},
		"wall_white": {"file": "plaster.svg", "scale": 0.34, "roughness": 0.92},
		"wall_mint": {"file": "plaster.svg", "scale": 0.34, "roughness": 0.92},
		"wall_gray": {"file": "plaster.svg", "scale": 0.22, "roughness": 0.96},
		"concrete": {"file": "concrete.svg", "scale": 0.18, "roughness": 0.97},
		"floor_redoxide": {"file": "concrete.svg", "scale": 0.10, "roughness": 0.94},
		"sofa_fabric": {"file": "plaster.svg", "scale": 0.90, "roughness": 0.99},
		"photo_paper": {"file": "wood.svg", "scale": 0.60, "roughness": 0.99},
		"family_photo": {"file": "family_photo.svg", "scale": 1.0, "roughness": 0.99},
		"glass_shards": {"file": "glass.svg", "scale": 0.30, "roughness": 0.25},
		"tire": {"file": "asphalt.svg", "scale": 0.42, "roughness": 1.0},
		"roof_red": {"file": "terracotta.svg", "scale": 0.38, "roughness": 0.91},
		"roof_dark": {"file": "concrete.svg", "scale": 0.12, "roughness": 0.92},
		"wood": {"file": "wood.svg", "scale": 0.20, "roughness": 0.90},
		"wood_light": {"file": "wood.svg", "scale": 0.24, "roughness": 0.88},
		"glass": {"file": "glass.svg", "scale": 0.30, "roughness": 0.28}
	}
	var loaded_textures: Dictionary = {}
	for spec_variant in texture_specs.values():
		var file_path := "res://assets/textures/" + str(spec_variant["file"])
		if not loaded_textures.has(file_path):
			loaded_textures[file_path] = load(file_path) as Texture2D
	for material_variant in texture_specs.keys():
		var material_id := str(material_variant)
		var spec: Dictionary = texture_specs[material_id]
		var base_material := _materials[material_id] as StandardMaterial3D
		var texture_path := "res://assets/textures/" + str(spec["file"])
		var surface_texture := loaded_textures.get(texture_path) as Texture2D
		if base_material == null or surface_texture == null:
			push_warning("Missing city texture for " + material_id + "; keeping flat fallback.")
			continue
		var textured_material := ShaderMaterial.new()
		textured_material.shader = shader_resource
		textured_material.set_shader_parameter("surface_tex", surface_texture)
		textured_material.set_shader_parameter("tint_color", base_material.albedo_color)
		textured_material.set_shader_parameter("texture_scale", float(spec["scale"]))
		textured_material.set_shader_parameter("surface_roughness", float(spec["roughness"]))
		_materials[material_id] = textured_material

func _mat(id: String, color: Color, roughness: float = 0.9, emission: Color = Color.BLACK, emission_energy: float = 0.0) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = emission_energy
	_materials[id] = material

func _add(shape: String, material_id: String, position: Vector3, dimensions: Vector3, rotation: Vector3 = Vector3.ZERO) -> void:
	# Keep static batches spatially bounded so the renderer can cull distant city chunks.
	var chunk_x := int(floor((position.x + CHUNK_SIZE * 0.5) / CHUNK_SIZE))
	var chunk_z := int(floor((position.z + CHUNK_SIZE * 0.5) / CHUNK_SIZE))
	var key := "%s|%s|%d|%d" % [shape, material_id, chunk_x, chunk_z]
	if not _batches.has(key):
		_batches[key] = []
	var basis := Basis.from_euler(rotation) * Basis.from_scale(dimensions)
	var transform := Transform3D(basis, position)
	_batche_append(key, transform)

func _batche_append(key: String, transform: Transform3D) -> void:
	var records: Array = _batches[key]
	records.append(transform)
	_batches[key] = records

func _box(material_id: String, position: Vector3, size: Vector3, rotation: Vector3 = Vector3.ZERO) -> void:
	_add("box", material_id, position, size, rotation)

func _cylinder(material_id: String, position: Vector3, size: Vector3, rotation: Vector3 = Vector3.ZERO) -> void:
	_add("cylinder", material_id, position, size, rotation)

func _sphere(material_id: String, position: Vector3, size: Vector3, rotation: Vector3 = Vector3.ZERO) -> void:
	_add("sphere", material_id, position, size, rotation)

func _build_ground_and_roads() -> void:
	_box("ground_concrete", Vector3(0, -0.43, 0), Vector3(WORLD_SIZE, 0.55, WORLD_SIZE))
	# The city is rendered with batched MultiMeshes, which have no collision by themselves.
	# Add one world-sized static floor so the player and vehicles cannot fall through roads.
	_add_static_collision(Vector3(0, -0.165, 0), Vector3(WORLD_SIZE, 0.55, WORLD_SIZE))
	var extent := GRID * 4.0
	var road_length := GRID * 8.0 + ROAD_WIDTH
	var section_length := road_length / 4.0
	for index in range(-4, 5):
		var line := float(index) * GRID
		# Split long streets into manageable pieces instead of one city-wide mesh.
		for section in range(4):
			var along := -road_length * 0.5 + section_length * (float(section) + 0.5)
			_box("road", Vector3(along, 0.02, line), Vector3(section_length + 0.22, 0.18, ROAD_WIDTH))
			_box("road", Vector3(line, 0.021, along), Vector3(ROAD_WIDTH, 0.18, section_length + 0.22))
			for side in [-1.0, 1.0]:
				var sidewalk_offset := ROAD_HALF + SIDEWALK_WIDTH * 0.5
				_box("sidewalk", Vector3(along, 0.15, line + side * sidewalk_offset), Vector3(section_length + 0.22, 0.25, SIDEWALK_WIDTH))
				_box("sidewalk", Vector3(line + side * sidewalk_offset, 0.15, along), Vector3(SIDEWALK_WIDTH, 0.25, section_length + 0.22))
				_box("drain", Vector3(along, 0.075, line + side * (ROAD_HALF + 0.18)), Vector3(section_length + 0.22, 0.055, 0.34))
				_box("drain", Vector3(line + side * (ROAD_HALF + 0.18), 0.075, along), Vector3(0.34, 0.055, section_length + 0.22))
		# Broken white lane dividers and a double yellow center line.
		for x in range(-56, 57):
			var dash_x := float(x) * 7.1
			if abs(dash_x) < extent - 4.0:
				_box("road_white", Vector3(dash_x, 0.119, line + 3.75), Vector3(3.8, 0.018, 0.11))
				_box("road_white", Vector3(dash_x, 0.119, line - 3.75), Vector3(3.8, 0.018, 0.11))
		for z in range(-56, 57):
			var dash_z := float(z) * 7.1
			if abs(dash_z) < extent - 4.0:
				_box("road_white", Vector3(line + 3.75, 0.12, dash_z), Vector3(0.11, 0.018, 3.8))
				_box("road_white", Vector3(line - 3.75, 0.12, dash_z), Vector3(0.11, 0.018, 3.8))
		for dash in range(-56, 57):
			var mark_x := float(dash) * 7.1
			if abs(mark_x) < extent - 4.0:
				_box("road_yellow", Vector3(mark_x, 0.122, line - 0.20), Vector3(3.5, 0.02, 0.10))
				_box("road_yellow", Vector3(mark_x, 0.122, line + 0.20), Vector3(3.5, 0.02, 0.10))
			var mark_z := float(dash) * 7.1
			if abs(mark_z) < extent - 4.0:
				_box("road_yellow", Vector3(line - 0.20, 0.123, mark_z), Vector3(0.10, 0.02, 3.5))
				_box("road_yellow", Vector3(line + 0.20, 0.123, mark_z), Vector3(0.10, 0.02, 3.5))
	# Zebra crossings around the central junctions.
	for ix in range(-1, 2):
		for iz in range(-1, 2):
			var cx := float(ix) * GRID
			var cz := float(iz) * GRID
			for stripe in range(-4, 5):
				var offset := float(stripe) * 1.25
				_box("road_white", Vector3(cx + offset, 0.128, cz + ROAD_HALF - 1.35), Vector3(0.72, 0.025, 2.4))
				_box("road_white", Vector3(cx + offset, 0.128, cz - ROAD_HALF + 1.35), Vector3(0.72, 0.025, 2.4))
				_box("road_white", Vector3(cx + ROAD_HALF - 1.35, 0.129, cz + offset), Vector3(2.4, 0.025, 0.72))
				_box("road_white", Vector3(cx - ROAD_HALF + 1.35, 0.129, cz + offset), Vector3(2.4, 0.025, 0.72))
	# A few patched areas stop the asphalt reading as one flat material.
	for i in range(140):
		var patch_pos := Vector3(_rng.randf_range(-extent, extent), 0.118, _rng.randf_range(-extent, extent))
		if _nearest_grid_distance(patch_pos.x) < ROAD_HALF or _nearest_grid_distance(patch_pos.z) < ROAD_HALF:
			_box("road_patch", patch_pos, Vector3(_rng.randf_range(0.5, 2.2), 0.012, _rng.randf_range(0.35, 1.1)))

func _nearest_grid_distance(value: float) -> float:
	return abs(value - round(value / GRID) * GRID)

func _build_buildings() -> void:
	# Building rows sit along both sides of every street, making a dense connected grid.
	for axis in [0, 1]:
		for road_index in range(-4, 5):
			for segment in range(-4, 4):
				for side in [-1, 1]:
					var central: bool = abs(road_index) <= 1 and abs(segment) <= 2
					var count := 2 if central else 1
					if abs(road_index) == 3 and abs(segment) == 2 and _rng.randf() < 0.45:
						continue
					for slot in range(count):
						var along := float(segment) * GRID + GRID * 0.5
						var frontage := _rng.randf_range(27.0, 35.0)
						if count == 2:
							along = float(segment) * GRID + (37.0 if slot == 0 else 59.0)
							frontage = _rng.randf_range(15.0, 19.0)
						frontage = clamp(frontage, 14.0, 36.0)
						var depth := _rng.randf_range(13.0, 22.0)
						var floors := _choose_floors(road_index, segment, axis)
						var face := 0
						var position := Vector3.ZERO
						if axis == 0:
							var road_z := float(road_index) * GRID
							position = Vector3(along, 0, road_z + side * (ROAD_HALF + SIDEWALK_WIDTH + depth * 0.5 + 0.45))
							face = 0 if side > 0 else 1
						else:
							var road_x := float(road_index) * GRID
							position = Vector3(road_x + side * (ROAD_HALF + SIDEWALK_WIDTH + depth * 0.5 + 0.45), 0, along)
							face = 2 if side > 0 else 3
						if _reserved_for_landmark(position):
							continue
						var wall_id: String = HOUSE_PALETTE[_rng.randi_range(0, HOUSE_PALETTE.size() - 1)]
						var kind := "shop" if central or (_rng.randf() < 0.22) else "residential"
						if floors >= 4:
							kind = "apartment"
						_make_building(position, frontage, depth, floors, face, wall_id, kind)
	# Fill the center of blocks with workshops, small homes and courtyards.
	for gx in range(-4, 4):
		for gz in range(-4, 4):
			if _rng.randf() < 0.22:
				continue
			var cx := (float(gx) + 0.5) * GRID + _rng.randf_range(-9.0, 9.0)
			var cz := (float(gz) + 0.5) * GRID + _rng.randf_range(-9.0, 9.0)
			if _reserved_for_landmark(Vector3(cx, 0, cz)):
				continue
			var width := _rng.randf_range(12.0, 21.0)
			var depth := _rng.randf_range(10.0, 17.0)
			var face := _rng.randi_range(0, 3)
			var wall_id: String = HOUSE_PALETTE[_rng.randi_range(0, HOUSE_PALETTE.size() - 1)]
			_make_building(Vector3(cx, 0, cz), width, depth, _rng.randi_range(1, 2), face, wall_id, "yard")
	_build_trees_and_verges()

func _reserved_for_landmark(position: Vector3) -> bool:
	# Keep the dedicated garage and tea stall lots clear so frontages do not overlap them.
	if position.distance_to(Vector3(48.0, 0.0, 48.0)) < 21.0:
		return true
	if position.distance_to(Vector3(-48.0, 0.0, 48.0)) < 13.0:
		return true
	if position.distance_to(Vector3(-48.0, 0.0, -72.0)) < 19.0:
		return true
	if position.distance_to(Vector3(-144.0, 0.0, 10.0)) < 24.0:
		return true
	return false

func _choose_floors(road_index: int, segment: int, axis: int) -> int:
	var center_weight: bool = abs(road_index) <= 1 and abs(segment) <= 1
	if center_weight:
		return _rng.randi_range(2, 5)
	if abs(road_index) <= 1 or abs(segment) <= 1:
		return _rng.randi_range(2, 4)
	if _rng.randf() < 0.10:
		return _rng.randi_range(3, 5)
	return _rng.randi_range(1, 3)

func _make_building(center: Vector3, frontage_width: float, depth: float, floors: int, face: int, wall_id: String, kind: String) -> void:
	var width: float = clampf(frontage_width, 14.0, 46.0)
	var building_depth: float = clampf(depth, 11.0, 24.0)
	var sx: float = width if face < 2 else building_depth
	var sz: float = building_depth if face < 2 else width
	var total_height := 2.8 + float(floors) * 2.75
	var shell_size := Vector3(sx, total_height, sz)
	_box(wall_id, center + Vector3(0, total_height * 0.5, 0), shell_size)
	_add_building_collision(center + Vector3(0, total_height * 0.5, 0), shell_size)
	# Foundation, plinth, and a thin parapet give each silhouette more depth.
	_box("concrete", center + Vector3(0, 0.22, 0), Vector3(sx + 0.35, 0.42, sz + 0.35))
	if floors >= 2:
		_box("concrete", center + Vector3(0, total_height - 0.22, 0), Vector3(sx + 0.35, 0.38, sz + 0.35))
		if kind == "apartment":
			_box("wall_gray", center + Vector3(0, total_height + 0.28, 0), Vector3(sx + 0.25, 0.42, sz + 0.25))
	else:
		# Many Kerala homes have simple sloping tiled roofs rather than glass towers.
		if face < 2 and _rng.randf() < 0.66:
			var roof_color := "roof_red" if _rng.randf() < 0.78 else "roof_dark"
			_box(roof_color, center + Vector3(0, total_height + 0.12, -sz * 0.18), Vector3(sx + 1.0, 0.30, sz * 0.66), Vector3(0.33, 0, 0))
			_box(roof_color, center + Vector3(0, total_height + 0.12, sz * 0.18), Vector3(sx + 1.0, 0.30, sz * 0.66), Vector3(-0.33, 0, 0))
		else:
			_box("roof_dark", center + Vector3(0, total_height + 0.15, 0), Vector3(sx + 0.7, 0.28, sz + 0.7))
	# Ground floor has a shutter or a glazed shopfront.
	var shop_front := kind == "shop" or kind == "yard"
	if shop_front:
		_add_facade_panel(center, face, width * 0.78, 1.9, 1.72, building_depth, "glass")
		_add_facade_panel(center, face, width * 0.82, 0.20, 2.82, building_depth, "metal")
		var awning_id: String = ["awning", "awning_green", "awning_blue"][_rng.randi_range(0, 2)]
		var awning_pos := _face_position(center, face, building_depth * 0.5 + 0.62, 3.05)
		var awning_size := Vector3(width * 0.88, 0.26, 1.05) if face < 2 else Vector3(1.05, 0.26, width * 0.88)
		_box(awning_id, awning_pos, awning_size)
		_box(["sign_red", "sign_blue", "sign_green", "sign_yellow"][_rng.randi_range(0, 3)], _face_position(center, face, building_depth * 0.5 + 0.13, 3.63), Vector3(width * 0.72, 0.62, 0.18) if face < 2 else Vector3(0.18, 0.62, width * 0.72))
		if _sign_count < 26:
			_add_shop_label(center, face, building_depth, width, _sign_count)
			_sign_count += 1
	else:
		_add_facade_panel(center, face, width * 0.22, 1.15, 1.65, building_depth, "glass")
		_box("wood", _face_position(center, face, building_depth * 0.5 + 0.10, 1.35), Vector3(width * 0.24, 2.15, 0.16) if face < 2 else Vector3(0.16, 2.15, width * 0.24))
	# Upper floors get repeated dark windows, pale frames, and occasional balconies.
	for floor in range(1, floors):
		var y := 2.95 + float(floor) * 2.75
		var window_count: int = clampi(int(width / 5.5), 2, 5)
		for wi in range(window_count):
			var u: float = (float(wi) - float(window_count - 1) * 0.5) * (width / float(window_count))
			var win_width: float = minf(1.55, width / float(window_count) * 0.48)
			_add_window(center, face, u, y, win_width, 1.22, building_depth)
			if kind == "apartment" and _rng.randf() < 0.56:
				_add_balcony(center, face, u, y - 0.15, win_width + 0.65, building_depth)
	# AC units, roof tanks, aerials and laundry-like details.
	if floors >= 2 and _rng.randf() < 0.7:
		var ac_pos := _face_position(center, (face + 2) % 4, building_depth * 0.5 + 0.23, minf(total_height - 0.8, 5.3))
		_box("metal_light", ac_pos, Vector3(1.05, 0.72, 0.55) if face < 2 else Vector3(0.55, 0.72, 1.05))
	if floors >= 2 and _rng.randf() < 0.44:
		_cylinder("metal", center + Vector3(sx * 0.22, total_height + 0.85, sz * 0.18), Vector3(1.0, 1.65, 1.0))
	if floors >= 3 and _rng.randf() < 0.3:
		_cylinder("metal_light", center + Vector3(-sx * 0.23, total_height + 1.4, -sz * 0.2), Vector3(0.12, 2.8, 0.12))
	if _rng.randf() < 0.22:
		_box("wood_light", _face_position(center, face, building_depth * 0.5 + 0.13, _rng.randf_range(2.1, min(total_height - 0.4, 5.7))), Vector3(width * 0.24, 0.08, 0.10) if face < 2 else Vector3(0.10, 0.08, width * 0.24))

func _face_position(center: Vector3, face: int, distance: float, y: float) -> Vector3:
	match face:
		0:
			return center + Vector3(0, y, -distance)
		1:
			return center + Vector3(0, y, distance)
		2:
			return center + Vector3(-distance, y, 0)
		_:
			return center + Vector3(distance, y, 0)

func _add_facade_panel(center: Vector3, face: int, width: float, height: float, y: float, depth: float, material_id: String) -> void:
	var pos := _face_position(center, face, depth * 0.5 + 0.10, y)
	var size := Vector3(width, height, 0.13) if face < 2 else Vector3(0.13, height, width)
	_box(material_id, pos, size)

func _add_window(center: Vector3, face: int, offset: float, y: float, width: float, height: float, depth: float) -> void:
	var pos := _face_position(center, face, depth * 0.5 + 0.10, y)
	if face < 2:
		pos.x += offset
		_box("glass", pos, Vector3(width, height, 0.13))
		_box("frame", pos + Vector3(0, height * 0.5, 0), Vector3(width + 0.18, 0.09, 0.16))
		_box("frame", pos + Vector3(0, -height * 0.5, 0), Vector3(width + 0.18, 0.09, 0.16))
		_box("frame", pos + Vector3(-width * 0.5, 0, 0), Vector3(0.08, height, 0.16))
		_box("frame", pos + Vector3(width * 0.5, 0, 0), Vector3(0.08, height, 0.16))
		_box("frame", pos, Vector3(0.055, height, 0.17))
	else:
		pos.z += offset
		_box("glass", pos, Vector3(0.13, height, width))
		_box("frame", pos + Vector3(0, height * 0.5, 0), Vector3(0.16, 0.09, width + 0.18))
		_box("frame", pos + Vector3(0, -height * 0.5, 0), Vector3(0.16, 0.09, width + 0.18))
		_box("frame", pos + Vector3(0, 0, -width * 0.5), Vector3(0.16, height, 0.08))
		_box("frame", pos + Vector3(0, 0, width * 0.5), Vector3(0.16, height, 0.08))
		_box("frame", pos, Vector3(0.17, height, 0.055))

func _add_balcony(center: Vector3, face: int, offset: float, y: float, width: float, depth: float) -> void:
	var distance := depth * 0.5 + 0.55
	var pos := _face_position(center, face, distance, y - 0.48)
	var slab := Vector3(width, 0.12, 0.8) if face < 2 else Vector3(0.8, 0.12, width)
	if face < 2:
		pos.x += offset
	else:
		pos.z += offset
	_box("concrete", pos, slab)
	for bar in range(5):
		var u := (float(bar) - 2.0) * width / 4.0
		var rail_pos := pos + Vector3(u, 0.48, 0) if face < 2 else pos + Vector3(0, 0.48, u)
		_box("metal_light", rail_pos, Vector3(0.045, 0.85, 0.045))
	var top_pos := pos + Vector3(0, 0.88, 0)
	_box("metal_light", top_pos, Vector3(width, 0.05, 0.05) if face < 2 else Vector3(0.05, 0.05, width))

func _add_shop_label(center: Vector3, face: int, depth: float, width: float, index: int) -> void:
	var label := Label3D.new()
	label.name = "ShopSign_%02d" % index
	label.text = SHOP_NAMES[index % SHOP_NAMES.size()]
	label.font_size = 42
	label.pixel_size = 0.009
	label.outline_size = 5
	label.modulate = Color("#fff0d2")
	label.no_depth_test = false
	label.position = _face_position(center, face, depth * 0.5 + 0.24, 3.65)
	if face == 1:
		label.rotation.y = PI
	elif face == 2:
		label.rotation.y = PI * 0.5
	elif face == 3:
		label.rotation.y = -PI * 0.5
	_city_root.add_child(label)

func _add_building_collision(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "BuildingCollision"
	body.position = center
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	_city_root.add_child(body)

func _build_trees_and_verges() -> void:
	# Roadside lamps and power poles: clustered props, with a handful of overhead cables.
	for road_index in range(-4, 5):
		var line := float(road_index) * GRID
		for along_index in range(-8, 9):
			var along := float(along_index) * 45.0
			if abs(along) > WORLD_EDGE - 20:
				continue
			for side in [-1.0, 1.0]:
				var x_road_pole := Vector3(along, 0, line + side * 9.2)
				_cylinder("metal", x_road_pole + Vector3(0, 4.0, 0), Vector3(0.20, 8.0, 0.20))
				_box("metal", x_road_pole + Vector3(0.75, 7.6, 0), Vector3(1.6, 0.12, 0.12))
				_sphere("lamp_glow", x_road_pole + Vector3(1.45, 7.45, 0), Vector3(0.32, 0.18, 0.24))
				var z_road_pole := Vector3(line + side * 9.2, 0, along)
				_cylinder("metal", z_road_pole + Vector3(0, 4.0, 0), Vector3(0.20, 8.0, 0.20))
				_box("metal", z_road_pole + Vector3(0, 7.6, 0.75), Vector3(0.12, 0.12, 1.6))
				_sphere("lamp_glow", z_road_pole + Vector3(0, 7.45, 1.45), Vector3(0.24, 0.18, 0.32))
		# Three overhead lines on each road; keep cable instances light-weight.
		for seg in range(-4, 4):
			for wire in range(3):
				var wire_height := 8.4 + float(wire) * 0.32
				var wire_z := line + 9.2 + float(wire) * 0.10
				_box("cable", Vector3((float(seg) + 0.5) * GRID, wire_height, wire_z), Vector3(GRID, 0.045, 0.045))
				var wire_x := line + 9.2 + float(wire) * 0.10
				_box("cable", Vector3(wire_x, wire_height, (float(seg) + 0.5) * GRID), Vector3(0.045, 0.045, GRID))
	# Palms and broad-leaf trees at block corners and near the outer roads.
	for i in range(96):
		var x := _rng.randf_range(-WORLD_EDGE + 8, WORLD_EDGE - 8)
		var z := _rng.randf_range(-WORLD_EDGE + 8, WORLD_EDGE - 8)
		if _nearest_grid_distance(x) < ROAD_HALF + 4.5 or _nearest_grid_distance(z) < ROAD_HALF + 4.5:
			continue
		if _rng.randf() < 0.66:
			_add_palm(Vector3(x, 0, z), _rng.randf_range(5.5, 9.0))
		else:
			_add_broad_tree(Vector3(x, 0, z), _rng.randf_range(3.5, 5.2))
	# Puddles sit off the driving lanes, catching the gray Kerala daylight.
	for p in range(64):
		var x := _rng.randf_range(-WORLD_EDGE + 3, WORLD_EDGE - 3)
		var z := _rng.randf_range(-WORLD_EDGE + 3, WORLD_EDGE - 3)
		if _nearest_grid_distance(x) < ROAD_HALF - 1.0 and _nearest_grid_distance(z) < ROAD_HALF - 1.0:
			continue
		_box("puddle", Vector3(x, 0.118, z), Vector3(_rng.randf_range(0.8, 3.0), 0.018, _rng.randf_range(0.45, 1.4)))

func _add_palm(base: Vector3, height: float) -> void:
	_cylinder("palm_trunk", base + Vector3(0, height * 0.5, 0), Vector3(0.42, height, 0.42), Vector3(0, 0, _rng.randf_range(-0.07, 0.07)))
	var crown := base + Vector3(0, height, 0)
	for i in range(7):
		var angle := TAU * float(i) / 7.0
		var direction := Vector3(cos(angle), 0, sin(angle))
		var leaf_pos := crown + direction * 2.0 + Vector3(0, -0.45, 0)
		_box("leaf_green" if i % 2 == 0 else "leaf_dark", leaf_pos, Vector3(4.6, 0.16, 0.48), Vector3(-0.18, -angle, 0.30))

func _add_broad_tree(base: Vector3, height: float) -> void:
	_cylinder("palm_trunk", base + Vector3(0, height * 0.42, 0), Vector3(0.40, height * 0.85, 0.40))
	_sphere("bush", base + Vector3(0, height * 0.92, 0), Vector3(3.0, 2.6, 3.0))
	_sphere("leaf_green", base + Vector3(-0.9, height * 0.80, 0.45), Vector3(1.8, 1.6, 1.7))
	_sphere("leaf_dark", base + Vector3(0.8, height * 0.80, -0.5), Vector3(1.8, 1.5, 1.8))

func _build_street_life() -> void:
	# Bus shelters, small stalls, waste bins and roadside notice boards.
	for i in range(-2, 3):
		var x := float(i) * GRID + 22.0
		var z := -GRID * 2.0 - ROAD_HALF - SIDEWALK_WIDTH * 0.5
		_box("metal", Vector3(x, 1.4, z), Vector3(5.0, 0.16, 2.2))
		for post_x in [-2.2, 2.2]:
			for post_z in [-0.8, 0.8]:
				_cylinder("metal", Vector3(x + post_x, 1.25, z + post_z), Vector3(0.12, 2.5, 0.12))
		_box("roof_dark", Vector3(x, 2.7, z), Vector3(5.4, 0.22, 2.6))
		_box("sign_blue", Vector3(x, 2.15, z - 1.18), Vector3(4.5, 0.5, 0.14))
		var bin_x := x + 5.0
		_box("metal", Vector3(bin_x, 0.48, z), Vector3(0.65, 0.95, 0.65))
	# Corner shops get kerbside stacks and simple produce crates.
	for i in range(36):
		var x := _rng.randf_range(-WORLD_EDGE + 10, WORLD_EDGE - 10)
		var z := _rng.randf_range(-WORLD_EDGE + 10, WORLD_EDGE - 10)
		if _nearest_grid_distance(x) > ROAD_HALF + 8 and _nearest_grid_distance(z) > ROAD_HALF + 8:
			continue
		var crate_mat := "wood_light" if i % 2 == 0 else "wood"
		_box(crate_mat, Vector3(x, 0.45, z), Vector3(0.75, 0.75, 0.75))
		if i % 3 == 0:
			_box("sign_yellow", Vector3(x + 0.42, 1.05, z), Vector3(0.8, 0.09, 0.7))
	# A small central signal adds an urban anchor without expensive real-time lights.
	for offset in [-1.0, 1.0]:
		_cylinder("metal", Vector3(offset, 3.8, -5.8), Vector3(0.16, 7.6, 0.16))
		_box("metal", Vector3(offset, 7.4, -5.8), Vector3(0.72, 1.9, 0.45))
		for dy in [0.48, 0.0, -0.48]:
			_sphere("lamp_glow", Vector3(offset, 7.4 + dy, -5.53), Vector3(0.24, 0.24, 0.14))

func _build_landmarks() -> void:
	# An identifiable garage district anchor for future real interaction triggers.
	_box("concrete", Vector3(48.0, 0.10, 48.0), Vector3(28.0, 0.20, 17.0))
	_box("wall_gray", Vector3(48.0, 2.0, 56.0), Vector3(26.0, 4.0, 0.5))
	_box("roof_dark", Vector3(48.0, 4.2, 48.0), Vector3(28.0, 0.35, 18.0))
	_box("sign_blue", Vector3(48.0, 3.0, 40.33), Vector3(13.0, 0.9, 0.12))
	var garage_label := Label3D.new()
	garage_label.name = "RafiGarageSign"
	garage_label.text = "RAFI AUTO WORKS"
	garage_label.font_size = 58
	garage_label.pixel_size = 0.012
	garage_label.outline_size = 5
	garage_label.modulate = Color("#fff0d2")
	garage_label.position = Vector3(48.0, 2.72, 40.15)
	garage_label.rotation.y = 0.0
	_city_root.add_child(garage_label)
	# Garage shutter and bays.
	for bay in range(2):
		_box("metal", Vector3(42.0 + float(bay) * 12.0, 1.45, 40.36), Vector3(10.5, 2.75, 0.18))
		for rib in range(7):
			_box("metal_light", Vector3(42.0 + float(bay) * 12.0, 0.35 + float(rib) * 0.34, 40.48), Vector3(10.2, 0.035, 0.06))
	# A simple tea stall opposite the junction creates a recognisable street-life cue.
	_box("wall_ochre", Vector3(-48.0, 1.5, 48.0), Vector3(8.5, 3.0, 7.0))
	_box("roof_red", Vector3(-48.0, 3.25, 48.0), Vector3(9.2, 0.3, 7.6))
	_box("sign_red", Vector3(-48.0, 2.65, 44.45), Vector3(6.7, 0.55, 0.18))
	var tea_label := Label3D.new()
	tea_label.text = "CHAYA KADA"
	tea_label.font_size = 42
	tea_label.pixel_size = 0.010
	tea_label.outline_size = 4
	tea_label.position = Vector3(-48.0, 2.45, 44.31)
	tea_label.rotation.y = 0.0
	tea_label.modulate = Color("#fff0d2")
	_city_root.add_child(tea_label)

func _build_story_landmarks() -> void:
	_build_family_home()
	_build_accident_site()

func _build_family_home() -> void:
	# A modest Kerala family house with a usable front doorway and furnished interior.
	var cx := -48.0
	var cz := -72.0
	_box("floor_redoxide", Vector3(cx, -0.015, cz), Vector3(12.0, 0.16, 12.0))
	_box("concrete", Vector3(cx, -0.01, -81.1), Vector3(7.2, 0.14, 3.8))
	for step in range(3):
		_box("concrete", Vector3(cx, -0.04 + float(step) * 0.05, -83.5 - float(step) * 0.65), Vector3(3.4 + float(step) * 0.5, 0.15, 0.75))
	_make_home_wall(Vector3(cx, 1.65, -66.0), Vector3(12.0, 3.3, 0.36))
	_make_home_wall(Vector3(-54.0, 1.65, cz), Vector3(0.36, 3.3, 12.0))
	_make_home_wall(Vector3(-42.0, 1.65, cz), Vector3(0.36, 3.3, 12.0))
	# Front wall leaves a proper doorway; the player is not trapped inside a solid shell.
	_make_home_wall(Vector3(-51.5, 1.65, -78.0), Vector3(5.0, 3.3, 0.36))
	_make_home_wall(Vector3(-44.5, 1.65, -78.0), Vector3(5.0, 3.3, 0.36))
	_box("wood", Vector3(-49.0, 1.40, -78.05), Vector3(0.14, 2.8, 0.26))
	_box("wood", Vector3(-47.0, 1.40, -78.05), Vector3(0.14, 2.8, 0.26))
	_box("wood_light", Vector3(cx, 2.94, -78.05), Vector3(2.15, 0.18, 0.28))
	# Front and rear windows.
	_box("wood", Vector3(-52.5, 1.98, -78.19), Vector3(1.15, 1.1, 0.10))
	_box("glass", Vector3(-52.5, 1.98, -78.25), Vector3(0.92, 0.85, 0.08))
	_box("frame", Vector3(-52.5, 1.98, -78.32), Vector3(0.06, 0.85, 0.04))
	_box("wood", Vector3(-43.5, 1.98, -78.19), Vector3(1.15, 1.1, 0.10))
	_box("glass", Vector3(-43.5, 1.98, -78.25), Vector3(0.92, 0.85, 0.08))
	_box("frame", Vector3(-43.5, 1.98, -78.32), Vector3(0.06, 0.85, 0.04))
	_box("wood", Vector3(-51.7, 2.0, -65.75), Vector3(1.1, 1.0, 0.10))
	_box("glass", Vector3(-51.7, 2.0, -65.68), Vector3(0.86, 0.78, 0.08))
	# Everyday living-room props, including a family photograph to inspect.
	_box("sofa_fabric", Vector3(cx, 0.67, -68.25), Vector3(3.75, 0.86, 1.15))
	_box("sofa_fabric", Vector3(-49.72, 1.02, -68.35), Vector3(0.36, 0.72, 1.22))
	_box("sofa_fabric", Vector3(-46.28, 1.02, -68.35), Vector3(0.36, 0.72, 1.22))
	_box("wood_light", Vector3(cx, 0.51, -72.8), Vector3(1.8, 0.12, 0.95))
	for leg_x in [-0.72, 0.72]:
		for leg_z in [-0.32, 0.32]:
			_box("wood", Vector3(cx + leg_x, 0.27, -72.8 + leg_z), Vector3(0.10, 0.48, 0.10))
	_box("metal", Vector3(-52.7, 0.92, -71.1), Vector3(0.92, 0.84, 1.25))
	_box("glass", Vector3(-52.19, 0.96, -71.1), Vector3(0.06, 0.52, 0.91))
	_box("wood", Vector3(-52.66, 0.42, -71.1), Vector3(1.12, 0.10, 1.4))
	_box("wood", Vector3(cx, 2.17, -65.78), Vector3(0.90, 0.88, 0.10))
	_box("family_photo", Vector3(cx, 2.17, -65.70), Vector3(0.70, 0.68, 0.045))
	_box("family_photo", Vector3(-48.22, 2.22, -65.66), Vector3(0.16, 0.16, 0.035))
	_box("wood", Vector3(-44.0, 0.45, -70.0), Vector3(1.1, 0.10, 0.95))
	for chair_x in [-44.4, -43.6]:
		_box("wood", Vector3(chair_x, 0.55, -70.0), Vector3(0.11, 0.7, 0.11))
	_box("wood", Vector3(-44.0, 0.95, -70.4), Vector3(1.1, 0.65, 0.10))
	# Roof can hide for interior exploration while retaining a finished exterior silhouette.
	_home_roof_root = Node3D.new()
	_home_roof_root.name = "AbrahamHouseRoof"
	_city_root.add_child(_home_roof_root)
	_add_individual_box(_home_roof_root, "roof_red", Vector3(cx, 3.65, -75.25), Vector3(13.0, 0.24, 6.7), Vector3(-0.28, 0.0, 0.0))
	_add_individual_box(_home_roof_root, "roof_red", Vector3(cx, 3.65, -68.75), Vector3(13.0, 0.24, 6.7), Vector3(0.28, 0.0, 0.0))
	_add_individual_box(_home_roof_root, "concrete", Vector3(cx, 4.25, -72.0), Vector3(0.28, 0.22, 13.4))
	for fence_x in range(-5, 6):
		if abs(fence_x) < 2:
			continue
		_box("wood_light", Vector3(cx + float(fence_x), 0.48, -86.5), Vector3(0.12, 0.9, 0.12))
	_box("wood", Vector3(cx, 0.74, -86.5), Vector3(9.8, 0.12, 0.10))
	_add_static_collision(Vector3(cx, -0.01, cz), Vector3(12.0, 0.16, 12.0))
	_add_static_collision(Vector3(cx, 1.65, -66.0), Vector3(12.0, 3.3, 0.36))
	_add_static_collision(Vector3(-54.0, 1.65, cz), Vector3(0.36, 3.3, 12.0))
	_add_static_collision(Vector3(-42.0, 1.65, cz), Vector3(0.36, 3.3, 12.0))
	_add_static_collision(Vector3(-51.5, 1.65, -78.0), Vector3(5.0, 3.3, 0.36))
	_add_static_collision(Vector3(-44.5, 1.65, -78.0), Vector3(5.0, 3.3, 0.36))

func _make_home_wall(position: Vector3, size: Vector3) -> void:
	_box("wall_cream", position, size)
	_box("concrete", position + Vector3(0, -size.y * 0.47, 0), Vector3(size.x + 0.08, 0.22, size.z + 0.08))

func _add_static_collision(position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = position
	body.name = "StoryLandmarkCollision"
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	_city_root.add_child(body)

func _add_individual_box(parent: Node3D, material_id: String, position: Vector3, size: Vector3, rotation: Vector3 = Vector3.ZERO) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _materials[material_id]
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	instance.rotation = rotation
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)

func _build_accident_site() -> void:
	# The wreck is visible for investigation, but no sabotage is confirmed by the scene.
	var center := Vector3(-144.0, 0.0, 9.6)
	_box("road_patch", Vector3(-150.5, 0.13, 8.9), Vector3(14.0, 0.025, 0.16), Vector3(0, 0, -0.02))
	_box("road_patch", Vector3(-151.0, 0.135, 9.5), Vector3(11.0, 0.025, 0.11), Vector3(0, 0, -0.018))
	_box("car_red", center + Vector3(0, 0.62, 0), Vector3(4.2, 0.82, 1.78), Vector3(0, 0, 0.03))
	_box("glass", center + Vector3(-0.10, 1.30, 0), Vector3(2.15, 0.82, 1.44), Vector3(0, 0, -0.08))
	_box("car_red", center + Vector3(1.48, 1.02, 0), Vector3(1.12, 0.26, 1.70), Vector3(0, 0, -0.16))
	_box("metal", center + Vector3(-1.6, 1.10, 0), Vector3(0.20, 0.22, 1.76), Vector3(0, 0, 0.22))
	for wheel_x in [-1.3, 1.3]:
		for wheel_z in [-0.88, 0.88]:
			_cylinder("tire", center + Vector3(wheel_x, 0.30, wheel_z), Vector3(0.68, 0.45, 0.68), Vector3(PI * 0.5, 0, 0))
			_cylinder("metal_light", center + Vector3(wheel_x, 0.30, wheel_z * 1.02), Vector3(0.34, 0.46, 0.34), Vector3(PI * 0.5, 0, 0))
	for shard in range(22):
		var offset := Vector3(_rng.randf_range(-5.0, 4.5), 0.14, _rng.randf_range(6.5, 13.0))
		_box("glass_shards", Vector3(-144.0, 0.0, 0.0) + offset, Vector3(_rng.randf_range(0.06, 0.28), 0.025, _rng.randf_range(0.05, 0.22)), Vector3(0, _rng.randf_range(-0.5, 0.5), _rng.randf_range(-0.6, 0.6)))
	_add_static_collision(center + Vector3(0, 0.72, 0), Vector3(4.6, 1.85, 2.0))

func _find_player(scene: Node) -> Node3D:
	if is_instance_valid(_tracked_player):
		return _tracked_player
	var candidates := scene.find_children("*", "CharacterBody3D", true, false)
	for candidate in candidates:
		if candidate is CharacterBody3D and not candidate.is_ancestor_of(_city_root):
			_tracked_player = candidate as Node3D
			_last_player_position = _tracked_player.global_position
			return _tracked_player
	return null

func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

func _is_in_home_room(position: Vector3) -> bool:
	return absf(position.x + 48.0) <= 5.0 and absf(position.z + 72.0) <= 5.0

func _update_story_triggers() -> void:
	var director := get_node_or_null("/root/MissionDirector")
	var scene := get_tree().current_scene
	if director == null or scene == null:
		return
	var player := _find_player(scene)
	if player == null or not is_instance_valid(player):
		director.call("clear_nearby_interaction")
		_interaction_key = ""
		return
	if player != _tracked_player:
		_tracked_player = player
		_last_player_position = player.global_position
	var moved := _flat_distance(player.global_position, _last_player_position)
	if moved < 4.0:
		_walk_distance += moved
		if _home_interior and _is_in_home_room(player.global_position) and _is_in_home_room(_last_player_position):
			_home_walk_distance += moved
	_last_player_position = player.global_position
	var mission_index := int(director.get("mission_index"))
	var objective_index := int(director.get("objective_index"))
	var home_door := Vector3(-48.0, 0.0, -79.5)
	var garage_door := Vector3(48.0, 0.0, 40.4)
	var crash_site := Vector3(-144.0, 0.0, 9.6)
	if mission_index == 0 and objective_index == 0:
		director.call("complete_objective", "Arrive in Kochi")
		return
	if mission_index == 0 and objective_index == 1:
		if _walk_distance >= 16.0:
			director.call("complete_objective", "Look around the street")
		return
	if mission_index == 0 and objective_index == 2:
		if _flat_distance(player.global_position, home_door) <= 10.0:
			director.call("complete_objective", "Find the way to Abraham's house")
		return
	if mission_index == 1 and objective_index == 0:
		if _flat_distance(player.global_position, home_door) <= 4.0:
			_set_world_interaction(director, "Enter Abraham's house", Callable(self, "_enter_family_home"))
		else:
			_clear_world_interaction(director)
		return
	if mission_index == 1 and objective_index == 1:
		if _is_in_home_room(player.global_position) and _home_walk_distance >= 4.5:
			director.call("complete_objective", "Look around the living room")
		return
	if mission_index == 1 and objective_index == 2:
		if _flat_distance(player.global_position, Vector3(-48.0, 0.0, -65.4)) <= 3.5:
			_set_world_interaction(director, "Inspect the family photograph", Callable(self, "_inspect_family_photo"))
		else:
			_clear_world_interaction(director)
		return
	if mission_index == 2 and objective_index == 0:
		if _home_interior and _flat_distance(player.global_position, home_door) <= 3.2:
			_set_world_interaction(director, "Leave Abraham's house", Callable(self, "_leave_family_home"))
		else:
			_clear_world_interaction(director)
		return
	if mission_index == 2 and objective_index == 1:
		if _flat_distance(player.global_position, garage_door) <= 12.0:
			director.call("complete_objective", "Find Rafi's garage")
		return
	if mission_index == 2 and objective_index == 2:
		if _flat_distance(player.global_position, garage_door) <= 8.0:
			_set_world_interaction(director, "Speak to Rafi", Callable(self, "_talk_to_rafi"))
		else:
			_clear_world_interaction(director)
		return
	if mission_index == 3 and objective_index == 0:
		if _flat_distance(player.global_position, garage_door) <= 8.0:
			_set_world_interaction(director, "Ask Rafi about the last drive", Callable(self, "_ask_rafi_about_drive"))
		else:
			_clear_world_interaction(director)
		return
	if mission_index == 3 and objective_index == 1:
		if _flat_distance(player.global_position, crash_site) <= 15.0:
			director.call("complete_objective", "Visit the road where Abraham's car was found")
		return
	if mission_index == 3 and objective_index == 2:
		if _flat_distance(player.global_position, crash_site) <= 6.0:
			_set_world_interaction(director, "Examine the wreckage", Callable(self, "_inspect_accident_site"))
		else:
			_clear_world_interaction(director)
		return
	_clear_world_interaction(director)

func _set_world_interaction(director: Node, label: String, action: Callable) -> void:
	if _interaction_key == label:
		return
	_interaction_key = label
	director.call("set_nearby_interaction", label, action)

func _clear_world_interaction(director: Node) -> void:
	if _interaction_key != "":
		_interaction_key = ""
		director.call("clear_nearby_interaction")

func _enter_family_home() -> void:
	var player := _find_player(get_tree().current_scene)
	if player == null:
		return
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	player.global_position = Vector3(-48.0, 0.20, -75.5)
	player.rotation.y = PI
	_last_player_position = player.global_position
	_home_walk_distance = 0.0
	_home_interior = true
	if is_instance_valid(_home_roof_root):
		_home_roof_root.visible = false
	var director := get_node_or_null("/root/MissionDirector")
	if director:
		director.call("show_story_line", "Vivek has not been home in years. The silence feels unfamiliar.")
		director.call("complete_objective", "Enter the family home")

func _leave_family_home() -> void:
	var player := _find_player(get_tree().current_scene)
	if player == null:
		return
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	player.global_position = Vector3(-48.0, 0.20, -82.0)
	player.rotation.y = 0.0
	_last_player_position = player.global_position
	_home_interior = false
	if is_instance_valid(_home_roof_root):
		_home_roof_root.visible = true
	var director := get_node_or_null("/root/MissionDirector")
	if director:
		director.call("show_story_line", "Outside, the neighborhood carries on as if nothing has changed.")
		director.call("complete_objective", "Leave the house")

func _inspect_family_photo() -> void:
	var director := get_node_or_null("/root/MissionDirector")
	if director:
		director.call("show_story_line", "A family photograph. Abraham looks ordinary, almost distant. It offers no answers.")
		director.call("complete_objective", "Inspect the photograph near the table")

func _talk_to_rafi() -> void:
	var director := get_node_or_null("/root/MissionDirector")
	if director:
		director.call("show_story_line", "Rafi: Your father didn't talk much about work. I knew the man who came by the garage.")
		director.call("complete_objective", "Speak to Rafi")

func _ask_rafi_about_drive() -> void:
	var director := get_node_or_null("/root/MissionDirector")
	if director:
		director.call("show_story_line", "Rafi: I heard it was a road accident. I didn't see what happened myself.")
		director.call("complete_objective", "Listen to what Rafi remembers")

func _inspect_accident_site() -> void:
	var director := get_node_or_null("/root/MissionDirector")
	if director:
		director.call("show_story_line", "Rain has battered the roadside and the wreck. Nothing here proves what happened.")
		director.call("complete_objective", "Look around the crash site")

func _flush_static_batches() -> void:
	for key_variant in _batches.keys():
		var key := String(key_variant)
		var shape_id := key.get_slice("|", 0)
		var material_id := key.get_slice("|", 1)
		var transforms: Array = _batches[key]
		if transforms.is_empty():
			continue
		var mesh: PrimitiveMesh
		match shape_id:
			"sphere":
				var sphere := SphereMesh.new()
				sphere.radius = 0.5
				sphere.height = 1.0
				sphere.radial_segments = 8
				sphere.rings = 4
				mesh = sphere
			"cylinder":
				var cylinder := CylinderMesh.new()
				cylinder.top_radius = 0.36
				cylinder.bottom_radius = 0.5
				cylinder.height = 1.0
				cylinder.radial_segments = 8
				cylinder.rings = 2
				mesh = cylinder
			_:
				var cube := BoxMesh.new()
				cube.size = Vector3.ONE
				mesh = cube
		mesh.material = _materials[material_id]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh
		multimesh.instance_count = transforms.size()
		for i in range(transforms.size()):
			multimesh.set_instance_transform(i, transforms[i])
		var instance := MultiMeshInstance3D.new()
		instance.name = "Batch_%s_%s_%s_%s" % [shape_id, material_id, key.get_slice("|", 2), key.get_slice("|", 3)]
		instance.multimesh = multimesh
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_city_root.add_child(instance)
	_batches.clear()

func _setup_lighting(scene: Node) -> void:
	var has_sun := not scene.find_children("*", "DirectionalLight3D", true, false).is_empty()
	if not has_sun:
		var sun := DirectionalLight3D.new()
		sun.name = "KochiDaylight"
		sun.rotation_degrees = Vector3(-48, -28, 0)
		sun.light_color = Color("#fff0d8")
		sun.light_energy = 1.0
		sun.shadow_enabled = false
		scene.add_child(sun)
	var has_environment := not scene.find_children("*", "WorldEnvironment", true, false).is_empty()
	if not has_environment:
		var environment_node := WorldEnvironment.new()
		environment_node.name = "KochiAtmosphere"
		var environment := Environment.new()
		environment.background_mode = Environment.BG_SKY
		var sky := Sky.new()
		var sky_material := ProceduralSkyMaterial.new()
		sky_material.sky_top_color = Color("#4b6878")
		sky_material.sky_horizon_color = Color("#c2c4ba")
		sky_material.ground_bottom_color = Color("#333d3c")
		sky_material.ground_horizon_color = Color("#a1a9a4")
		sky.sky_material = sky_material
		environment.sky = sky
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = Color("#a6b4bb")
		environment.ambient_light_energy = 0.68
		environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		environment.fog_enabled = true
		environment.fog_light_color = Color("#aeb9b5")
		environment.fog_density = 0.0018
		environment_node.environment = environment
		scene.add_child(environment_node)

func _build_traffic() -> void:
	var body_colors := ["car_white", "car_silver", "car_blue", "car_red", "car_green", "car_black"]
	for i in range(18):
		var axis := 0 if i % 2 == 0 else 1
		var line := float(_rng.randi_range(-3, 3)) * GRID
		var direction := 1.0 if i % 2 == 0 else -1.0
		var lane := ROAD_HALF * 0.43 * (1.0 if direction > 0 else -1.0)
		var coordinate := -WORLD_EDGE + float(i) * 72.0 + _rng.randf_range(0.0, 28.0)
		var root := _spawn_vehicle("car", body_colors[i % body_colors.size()])
		var pos := Vector3(coordinate, 0.03, line + lane) if axis == 0 else Vector3(line + lane, 0.03, coordinate)
		root.position = pos
		_city_root.add_child(root)
		_traffic.append({"root": root, "axis": axis, "line": line, "lane": lane, "direction": direction, "speed": _rng.randf_range(6.0, 10.5)})
	for i in range(9):
		var axis := 0 if i % 2 == 0 else 1
		var line := float(_rng.randi_range(-3, 3)) * GRID
		var direction := -1.0 if i % 2 == 0 else 1.0
		var lane := ROAD_HALF * 0.18 * (1.0 if direction > 0 else -1.0)
		var coordinate := float(i) * 125.0 - 210.0
		var root := _spawn_vehicle("auto", "auto_yellow")
		var pos := Vector3(coordinate, 0.03, line + lane) if axis == 0 else Vector3(line + lane, 0.03, coordinate)
		root.position = pos
		_city_root.add_child(root)
		_traffic.append({"root": root, "axis": axis, "line": line, "lane": lane, "direction": direction, "speed": _rng.randf_range(4.2, 6.3)})
	for bus_index in range(3):
		var bus := _spawn_vehicle("bus", "bus_blue")
		bus.position = Vector3(-150.0 + float(bus_index) * 170.0, 0.03, -GRID + 3.0)
		_city_root.add_child(bus)
		_traffic.append({"root": bus, "axis": 0, "line": -GRID, "lane": 3.0, "direction": 1.0 if bus_index == 0 else -1.0, "speed": 4.5})
	# Scooters and motorcycles are common street traffic in Kochi.
	for bike_index in range(8):
		var bike_axis := 0 if bike_index % 2 == 0 else 1
		var bike_line := float(_rng.randi_range(-3, 3)) * GRID
		var bike_direction := 1.0 if bike_index % 2 == 0 else -1.0
		var bike_lane := ROAD_HALF * 0.60 * (1.0 if bike_direction > 0 else -1.0)
		var bike_coordinate := _rng.randf_range(-WORLD_EDGE + 4.0, WORLD_EDGE - 4.0)
		var bike := _spawn_vehicle("bike", "car_black" if bike_index % 2 == 0 else "car_red")
		bike.position = Vector3(bike_coordinate, 0.03, bike_line + bike_lane) if bike_axis == 0 else Vector3(bike_line + bike_lane, 0.03, bike_coordinate)
		_city_root.add_child(bike)
		_traffic.append({"root": bike, "axis": bike_axis, "line": bike_line, "lane": bike_lane, "direction": bike_direction, "speed": _rng.randf_range(7.5, 11.0)})

func _spawn_vehicle(kind: String, color_id: String) -> Node3D:
	var root := Node3D.new()
	root.name = "CityTraffic_" + kind
	var length := 4.2
	var width := 1.78
	var body_height := 0.9
	var cabin_length := 2.2
	var cabin_height := 0.78
	var cabin_width := 1.5
	if kind == "auto":
		length = 2.65
		width = 1.38
		body_height = 0.9
		cabin_length = 1.6
		cabin_height = 0.95
		cabin_width = 1.25
	elif kind == "bike":
		length = 1.95
		width = 0.72
		body_height = 0.55
		cabin_length = 0.65
		cabin_height = 0.45
		cabin_width = 0.52
	elif kind == "bus":
		length = 8.2
		width = 2.35
		body_height = 1.65
		cabin_length = 6.5
		cabin_height = 1.5
		cabin_width = 2.05
	_add_vehicle_part(root, color_id, Vector3(0, body_height * 0.72, 0), Vector3(length, body_height, width))
	_add_vehicle_part(root, "glass", Vector3(-length * 0.03, body_height + cabin_height * 0.35, 0), Vector3(cabin_length, cabin_height, cabin_width))
	_add_vehicle_part(root, "metal_light", Vector3(length * 0.50, body_height * 0.75, 0), Vector3(0.08, body_height * 0.62, width * 0.83))
	if kind == "auto":
		_add_vehicle_part(root, "auto_green", Vector3(0.1, 1.30, 0), Vector3(1.5, 0.9, 1.26))
		_add_vehicle_part(root, "glass_light", Vector3(0.15, 1.56, 0), Vector3(1.05, 0.5, 1.28))
	elif kind == "bike":
		_add_vehicle_part(root, "metal_light", Vector3(0.0, 0.70, 0), Vector3(0.75, 0.12, 0.12))
		_add_vehicle_part(root, color_id, Vector3(-0.05, 0.80, 0), Vector3(0.58, 0.30, 0.42))
		_add_vehicle_part(root, "metal", Vector3(0.45, 0.99, 0), Vector3(0.34, 0.48, 0.08))
		_add_vehicle_part(root, "metal_light", Vector3(0.65, 1.15, 0), Vector3(0.08, 0.48, 0.08))
	else:
		_add_vehicle_part(root, "glass_light", Vector3(length * 0.35, body_height + 0.15, 0), Vector3(0.06, 0.42, cabin_width * 0.85))
		_add_vehicle_part(root, "metal", Vector3(-length * 0.35, body_height + 0.12, 0), Vector3(0.06, 0.42, cabin_width * 0.85))
	# Wheels are low-sided cylinders, with shared materials.
	var wheel_positions: Array[Vector3] = []
	if kind == "bus":
		for wx in [-length * 0.34, 0.0, length * 0.34]:
			wheel_positions.append(Vector3(wx, 0.42, -width * 0.48))
			wheel_positions.append(Vector3(wx, 0.42, width * 0.48))
	elif kind == "bike":
		wheel_positions.append(Vector3(-length * 0.36, 0.30, 0))
		wheel_positions.append(Vector3(length * 0.36, 0.30, 0))
	else:
		for wx in [-length * 0.31, length * 0.31]:
			wheel_positions.append(Vector3(wx, 0.32, -width * 0.52))
			wheel_positions.append(Vector3(wx, 0.32, width * 0.52))
	for wheel_pos in wheel_positions:
		var wheel_mesh := CylinderMesh.new()
		wheel_mesh.top_radius = (0.18 if kind == "bike" else (0.42 if kind == "bus" else 0.32))
		wheel_mesh.bottom_radius = wheel_mesh.top_radius
		wheel_mesh.height = 0.22 if kind != "bike" else 0.11
		wheel_mesh.radial_segments = 8
		var wheel := MeshInstance3D.new()
		wheel.mesh = wheel_mesh
		wheel.material_override = _materials["metal"]
		wheel.rotation.x = PI * 0.5
		wheel.position = wheel_pos
		root.add_child(wheel)
	# Headlamps and rear lamps remain simple material instances.
	_add_vehicle_part(root, "lamp_glow", Vector3(length * 0.50, 0.75, -width * 0.32), Vector3(0.10, 0.18, 0.22))
	_add_vehicle_part(root, "lamp_glow", Vector3(length * 0.50, 0.75, width * 0.32), Vector3(0.10, 0.18, 0.22))
	return root

func _add_vehicle_part(parent: Node3D, material_id: String, pos: Vector3, size: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = _materials[material_id]
	part.position = pos
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(part)

func _update_traffic(delta: float) -> void:
	for agent in _traffic:
		var root: Node3D = agent["root"]
		if not is_instance_valid(root):
			continue
		var axis: int = agent["axis"]
		var direction: float = agent["direction"]
		var speed: float = agent["speed"]
		var position := root.position
		if axis == 0:
			position.x += direction * speed * delta
			if position.x > WORLD_EDGE:
				position.x = -WORLD_EDGE
			elif position.x < -WORLD_EDGE:
				position.x = WORLD_EDGE
		else:
			position.z += direction * speed * delta
			if position.z > WORLD_EDGE:
				position.z = -WORLD_EDGE
			elif position.z < -WORLD_EDGE:
				position.z = WORLD_EDGE
		root.position = position
		var forward := Vector3(direction, 0, 0) if axis == 0 else Vector3(0, 0, direction)
		root.rotation.y = atan2(-forward.z, forward.x)

func _build_parked_vehicles() -> void:
	# Curbside parking and two-wheelers make the street feel used even between traffic passes.
	var parked_cars: Array[Dictionary] = [
		{"position": Vector3(-29.0, 0.03, 12.3), "color": "car_silver"},
		{"position": Vector3(-5.0, 0.03, 12.6), "color": "car_white"},
		{"position": Vector3(21.0, 0.03, 12.4), "color": "car_blue"},
		{"position": Vector3(70.0, 0.03, 12.7), "color": "car_green"},
		{"position": Vector3(111.0, 0.03, 12.2), "color": "car_white"},
		{"position": Vector3(-64.0, 0.03, -83.0), "color": "car_red"}
	]
	for data in parked_cars:
		var car := _spawn_vehicle("car", str(data["color"]))
		car.name = "ParkedCar"
		car.position = data["position"]
		_city_root.add_child(car)
		var body := StaticBody3D.new()
		body.name = "ParkedVehicleCollision"
		body.position = Vector3(0, 0.68, 0)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(4.2, 1.35, 1.9)
		collision.shape = shape
		body.add_child(collision)
		car.add_child(body)
	for i in range(6):
		var bike := _spawn_vehicle("bike", "car_black" if i % 2 == 0 else "car_red")
		bike.name = "ParkedScooter"
		bike.position = Vector3(-44.0 + float(i) * 1.35, 0.03, 13.6)
		bike.rotation.y = PI * 0.5
		_city_root.add_child(bike)
		var body := StaticBody3D.new()
		body.name = "ParkedScooterCollision"
		body.position = Vector3(0, 0.55, 0)
		var collision := CollisionShape3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = 0.40
		shape.height = 1.8
		collision.shape = shape
		body.add_child(collision)
		bike.add_child(body)

	# Distributed curb parking makes the wider district feel occupied, not like
	# one busy spawn street surrounded by empty roads.
	for i in range(10):
		var axis := i % 2
		var road_index := (i * 3 % 9) - 4
		var line := float(road_index) * GRID
		var segment := (i % 8) - 4
		var along := float(segment) * GRID + _rng.randf_range(-18.0, 18.0)
		var side := 1.0 if i % 4 < 2 else -1.0
		var position := Vector3(along, 0.03, line + side * 12.3) if axis == 0 else Vector3(line + side * 12.3, 0.03, along)
		var attempts := 0
		while _reserved_for_landmark(position) and attempts < 4:
			along += 26.0
			position = Vector3(along, 0.03, line + side * 12.3) if axis == 0 else Vector3(line + side * 12.3, 0.03, along)
			attempts += 1
		var car := _spawn_vehicle("car", ["car_white", "car_silver", "car_blue", "car_red", "car_green"][i % 5])
		car.name = "DistrictParkedCar_%02d" % i
		car.position = position
		car.rotation.y = PI * 0.5 if axis == 1 else 0.0
		_city_root.add_child(car)
		var body := StaticBody3D.new()
		body.name = "DistrictParkedCarCollision"
		body.position = Vector3(0, 0.68, 0)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(4.2, 1.35, 1.9)
		collision.shape = shape
		body.add_child(collision)
		car.add_child(body)

	# Scooters and motorcycles are parked outside shops and on residential lanes.
	for i in range(12):
		var axis := i % 2
		var road_index := (i * 5 % 9) - 4
		var line := float(road_index) * GRID
		var segment := (i * 3 % 8) - 4
		var along := float(segment) * GRID + _rng.randf_range(-20.0, 20.0)
		var side := 1.0 if i % 4 < 2 else -1.0
		var offset := ROAD_HALF + SIDEWALK_WIDTH * 0.70
		var position := Vector3(along, 0.03, line + side * offset) if axis == 0 else Vector3(line + side * offset, 0.03, along)
		var attempts := 0
		while _reserved_for_landmark(position) and attempts < 4:
			along += 24.0
			position = Vector3(along, 0.03, line + side * offset) if axis == 0 else Vector3(line + side * offset, 0.03, along)
			attempts += 1
		var bike := _spawn_vehicle("bike", "car_black" if i % 2 == 0 else "car_red")
		bike.name = "DistrictParkedScooter_%02d" % i
		bike.position = position
		bike.rotation.y = PI * 0.5 if axis == 1 else 0.0
		_city_root.add_child(bike)
		var body := StaticBody3D.new()
		body.name = "DistrictParkedScooterCollision"
		body.position = Vector3(0, 0.55, 0)
		var collision := CollisionShape3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = 0.40
		shape.height = 1.8
		collision.shape = shape
		body.add_child(collision)
		bike.add_child(body)

func _build_idle_citizens() -> void:
	# Rafi is visible outside the garage; tea-stall customers stand nearby.
	var rafi := _spawn_pedestrian("shirt_green", "pants_dark")
	rafi.name = "RafiStoryCharacter"
	rafi.position = Vector3(51.0, 0.17, 36.0)
	rafi.rotation.y = PI
	_city_root.add_child(rafi)
	_add_citizen_collision(rafi.position, 0.30, 1.75)
	var tea_customer_a := _spawn_pedestrian("shirt_white", "pants_blue")
	tea_customer_a.name = "TeaStallCustomerA"
	tea_customer_a.position = Vector3(-44.0, 0.17, 42.0)
	tea_customer_a.rotation.y = -PI * 0.5
	_city_root.add_child(tea_customer_a)
	_add_citizen_collision(tea_customer_a.position, 0.30, 1.75)
	var tea_customer_b := _spawn_pedestrian("shirt_maroon", "pants_dark")
	tea_customer_b.name = "TeaStallCustomerB"
	tea_customer_b.position = Vector3(-52.0, 0.17, 41.5)
	tea_customer_b.rotation.y = PI * 0.5
	_city_root.add_child(tea_customer_b)
	_add_citizen_collision(tea_customer_b.position, 0.30, 1.75)
	# Several quiet street-side figures and one vendor near a corner shop.
	for i in range(5):
		var citizen := _spawn_pedestrian("shirt_ochre" if i % 2 == 0 else "shirt_blue", "pants_dark")
		citizen.name = "IdleStreetCitizen_%02d" % i
		citizen.position = Vector3(100.0 + float(i % 3) * 2.2, 0.17, 14.5 + float(i / 3) * 1.4)
		citizen.rotation.y = float(i % 4) * PI * 0.5
		_city_root.add_child(citizen)
		_add_citizen_collision(citizen.global_position, 0.28, 1.7)

	# Additional commuters and neighbours are distributed around separate blocks,
	# rather than clustering all visible life around the starting street.
	var neighbour_shirts := ["shirt_blue", "shirt_white", "shirt_green", "shirt_maroon", "shirt_ochre"]
	for i in range(8):
		var axis := i % 2
		var road_index := (i % 7) - 3
		var line := float(road_index) * GRID
		var segment := int(i / 2) - 2
		var along := float(segment) * GRID + _rng.randf_range(-24.0, 24.0)
		var side := 1.0 if i % 4 < 2 else -1.0
		var position := Vector3(along, 0.17, line + side * (ROAD_HALF + SIDEWALK_WIDTH * 0.52)) if axis == 0 else Vector3(line + side * (ROAD_HALF + SIDEWALK_WIDTH * 0.52), 0.17, along)
		var attempts := 0
		while _reserved_for_landmark(position) and attempts < 4:
			along += 28.0
			position = Vector3(along, 0.17, line + side * (ROAD_HALF + SIDEWALK_WIDTH * 0.52)) if axis == 0 else Vector3(line + side * (ROAD_HALF + SIDEWALK_WIDTH * 0.52), 0.17, along)
			attempts += 1
		var neighbour := _spawn_pedestrian(neighbour_shirts[i % neighbour_shirts.size()], "pants_blue" if i % 3 == 0 else "pants_dark")
		neighbour.name = "Neighbour_%02d" % i
		neighbour.position = position
		neighbour.rotation.y = float((i + 1) % 4) * PI * 0.5
		_city_root.add_child(neighbour)
		_add_citizen_collision(neighbour.global_position, 0.27, 1.7)

func _add_citizen_collision(position: Vector3, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	body.name = "CitizenCollision"
	body.position = position + Vector3(0, height * 0.5, 0)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = height
	collision.shape = shape
	body.add_child(collision)
	_city_root.add_child(body)

func _build_pedestrians() -> void:
	var shirts := ["shirt_blue", "shirt_white", "shirt_green", "shirt_maroon", "shirt_ochre"]
	for i in range(32):
		var axis := 0 if i < 16 else 1
		var line := float(_rng.randi_range(-3, 3)) * GRID
		var side := 1.0 if i % 2 == 0 else -1.0
		var lane := side * (ROAD_HALF + SIDEWALK_WIDTH * 0.43)
		var coordinate := _rng.randf_range(-WORLD_EDGE + 5, WORLD_EDGE - 5)
		var walker := _spawn_pedestrian(shirts[i % shirts.size()], "pants_blue" if i % 3 == 0 else "pants_dark")
		var pos := Vector3(coordinate, 0.17, line + lane) if axis == 0 else Vector3(line + lane, 0.17, coordinate)
		walker.position = pos
		_city_root.add_child(walker)
		_walkers.append({
			"root": walker,
			"axis": axis,
			"line": line,
			"lane": lane,
			"direction": 1.0 if i % 2 == 0 else -1.0,
			"speed": _rng.randf_range(0.55, 1.15),
			"phase": _rng.randf_range(0.0, TAU),
			"left_arm": walker.get_node("LeftArmPivot"),
			"right_arm": walker.get_node("RightArmPivot"),
			"left_leg": walker.get_node("LeftLegPivot"),
			"right_leg": walker.get_node("RightLegPivot")
		})

func _spawn_pedestrian(shirt_id: String, pants_id: String) -> Node3D:
	var root := Node3D.new()
	root.name = "CityPedestrian"
	_add_ped_part(root, shirt_id, Vector3(0, 1.02, 0), Vector3(0.46, 0.90, 0.28), "box")
	_add_ped_part(root, "skin", Vector3(0, 1.68, 0), Vector3(0.34, 0.34, 0.34), "sphere")
	_add_ped_part(root, "hair", Vector3(0, 1.82, 0.01), Vector3(0.34, 0.16, 0.34), "sphere")
	var left_arm := Node3D.new()
	left_arm.name = "LeftArmPivot"
	left_arm.position = Vector3(-0.30, 1.28, 0)
	root.add_child(left_arm)
	_add_ped_part(left_arm, shirt_id, Vector3(0, -0.28, 0), Vector3(0.15, 0.64, 0.15), "cylinder")
	var right_arm := Node3D.new()
	right_arm.name = "RightArmPivot"
	right_arm.position = Vector3(0.30, 1.28, 0)
	root.add_child(right_arm)
	_add_ped_part(right_arm, shirt_id, Vector3(0, -0.28, 0), Vector3(0.15, 0.64, 0.15), "cylinder")
	var left_leg := Node3D.new()
	left_leg.name = "LeftLegPivot"
	left_leg.position = Vector3(-0.13, 0.62, 0)
	root.add_child(left_leg)
	_add_ped_part(left_leg, pants_id, Vector3(0, -0.27, 0), Vector3(0.16, 0.66, 0.16), "cylinder")
	var right_leg := Node3D.new()
	right_leg.name = "RightLegPivot"
	right_leg.position = Vector3(0.13, 0.62, 0)
	root.add_child(right_leg)
	_add_ped_part(right_leg, pants_id, Vector3(0, -0.27, 0), Vector3(0.16, 0.66, 0.16), "cylinder")
	return root

func _add_ped_part(parent: Node3D, material_id: String, pos: Vector3, size: Vector3, shape_type: String) -> void:
	var mesh: PrimitiveMesh
	match shape_type:
		"sphere":
			var sphere := SphereMesh.new()
			sphere.radius = 0.5
			sphere.height = 1.0
			sphere.radial_segments = 8
			sphere.rings = 4
			mesh = sphere
		"cylinder":
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.5
			cylinder.bottom_radius = 0.5
			cylinder.height = 1.0
			cylinder.radial_segments = 6
			mesh = cylinder
		_:
			var cube := BoxMesh.new()
			cube.size = Vector3.ONE
			mesh = cube
	mesh.material = _materials[material_id]
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = pos
	part.scale = size
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(part)

func _update_walkers(delta: float) -> void:
	for agent in _walkers:
		var root: Node3D = agent["root"]
		if not is_instance_valid(root):
			continue
		var direction: float = agent["direction"]
		var axis: int = agent["axis"]
		var speed: float = agent["speed"]
		var position := root.position
		if axis == 0:
			position.x += direction * speed * delta
			if position.x > WORLD_EDGE:
				position.x = -WORLD_EDGE
			elif position.x < -WORLD_EDGE:
				position.x = WORLD_EDGE
		else:
			position.z += direction * speed * delta
			if position.z > WORLD_EDGE:
				position.z = -WORLD_EDGE
			elif position.z < -WORLD_EDGE:
				position.z = WORLD_EDGE
		root.position = position
		var forward := Vector3(direction, 0, 0) if axis == 0 else Vector3(0, 0, direction)
		root.look_at(root.position + forward, Vector3.UP)
		var phase := _clock * speed * 6.5 + float(agent["phase"])
		var swing := sin(phase) * 0.38
		var left_arm: Node3D = agent["left_arm"]
		var right_arm: Node3D = agent["right_arm"]
		var left_leg: Node3D = agent["left_leg"]
		var right_leg: Node3D = agent["right_leg"]
		left_arm.rotation.x = swing
		right_arm.rotation.x = -swing
		left_leg.rotation.x = -swing * 0.85
		right_leg.rotation.x = swing * 0.85
