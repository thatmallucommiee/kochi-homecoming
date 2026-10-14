extends Control
## Lightweight, world-aligned minimap for the procedural Kochi street grid.
## Reads the player and mission objective but does not own or modify either system.

const GRID_SIZE := 96.0
const MAP_RANGE_METERS := 190.0
const ROAD_COLOR := Color("#777d7b")
const ROAD_EDGE := Color("#3b4143")
const MAP_BACKGROUND := Color("#242b2d")
const BUILDING_COLOR := Color("#3b4643")
const PLAYER_COLOR := Color("#f2b56e")
const OBJECTIVE_COLOR := Color("#e6d5a9")

var _player: Node3D
var _scan_elapsed := 0.0
var _target: Vector3
var _has_target := false
var _mission_index := -1
var _objective_index := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(166, 166)
	size = custom_minimum_size
	queue_redraw()

func _process(delta: float) -> void:
	_scan_elapsed -= delta
	if _scan_elapsed <= 0.0 or not is_instance_valid(_player):
		_scan_elapsed = 0.45
		_find_player()
	_update_target()
	queue_redraw()

func _find_player() -> void:
	_player = null
	var scene := get_tree().current_scene
	if scene == null:
		return
	if scene is CharacterBody3D:
		_player = scene as Node3D
		return
	var candidates := scene.find_children("*", "CharacterBody3D", true, false)
	if not candidates.is_empty() and candidates[0] is CharacterBody3D:
		_player = candidates[0] as Node3D

func _update_target() -> void:
	_has_target = false
	var director := get_node_or_null("/root/MissionDirector")
	if director == null:
		return
	_mission_index = int(director.get("mission_index"))
	_objective_index = int(director.get("objective_index"))
	match _mission_index:
		0:
			if _objective_index >= 2:
				_target = Vector3(-48.0, 0.0, -79.5)
				_has_target = true
		1:
			if _objective_index == 0:
				_target = Vector3(-48.0, 0.0, -79.5)
				_has_target = true
			elif _objective_index == 1:
				_target = Vector3(-48.0, 0.0, -72.0)
				_has_target = true
			elif _objective_index == 2:
				_target = Vector3(-48.0, 0.0, -65.4)
				_has_target = true
		2:
			if _objective_index == 0:
				_target = Vector3(-48.0, 0.0, -79.5)
				_has_target = true
			else:
				_target = Vector3(48.0, 0.0, 40.4)
				_has_target = true
		3:
			if _objective_index == 0:
				_target = Vector3(48.0, 0.0, 40.4)
			else:
				_target = Vector3(-144.0, 0.0, 9.6)
			_has_target = true

func _world_to_map(world_pos: Vector3, player_pos: Vector3, center: Vector2, scale: float) -> Vector2:
	return center + Vector2(world_pos.x - player_pos.x, world_pos.z - player_pos.z) * scale

func _draw() -> void:
	var map_size := minf(size.x, size.y)
	if map_size <= 8.0:
		return
	var panel := Rect2(Vector2.ZERO, Vector2(map_size, map_size))
	draw_rect(panel, MAP_BACKGROUND, true)
	var inset := 9.0
	var center := Vector2(map_size * 0.5, map_size * 0.5)
	var scale := (map_size - inset * 2.0) / MAP_RANGE_METERS
	var player_pos := Vector3.ZERO
	if is_instance_valid(_player):
		player_pos = _player.global_position

	# Subtle block parcels imply a dense urban street layout beneath the road network.
	var half_range := MAP_RANGE_METERS * 0.5
	var first_x := int(floor((player_pos.x - half_range) / GRID_SIZE)) - 1
	var last_x := int(ceil((player_pos.x + half_range) / GRID_SIZE)) + 1
	var first_z := int(floor((player_pos.z - half_range) / GRID_SIZE)) - 1
	var last_z := int(ceil((player_pos.z + half_range) / GRID_SIZE)) + 1
	for bx in range(first_x, last_x):
		for bz in range(first_z, last_z):
			var block_center := Vector3((float(bx) + 0.5) * GRID_SIZE, 0.0, (float(bz) + 0.5) * GRID_SIZE)
			var rect_center := _world_to_map(block_center, player_pos, center, scale)
			var block_rect := Rect2(rect_center - Vector2(17.0, 17.0) * scale, Vector2(34.0, 34.0) * scale)
			if panel.grow(-inset).intersects(block_rect):
				draw_rect(block_rect, BUILDING_COLOR, true)

	# Roads are drawn as a casing and a quieter center surface, with junctions lining up with the world grid.
	for gx in range(first_x - 1, last_x + 2):
		var road_x := float(gx) * GRID_SIZE
		var screen_x := center.x + (road_x - player_pos.x) * scale
		if screen_x >= -10.0 and screen_x <= map_size + 10.0:
			draw_line(Vector2(screen_x, 0.0), Vector2(screen_x, map_size), ROAD_EDGE, 8.0, true)
			draw_line(Vector2(screen_x, 0.0), Vector2(screen_x, map_size), ROAD_COLOR, 5.0, true)
	for gz in range(first_z - 1, last_z + 2):
		var road_z := float(gz) * GRID_SIZE
		var screen_y := center.y + (road_z - player_pos.z) * scale
		if screen_y >= -10.0 and screen_y <= map_size + 10.0:
			draw_line(Vector2(0.0, screen_y), Vector2(map_size, screen_y), ROAD_EDGE, 8.0, true)
			draw_line(Vector2(0.0, screen_y), Vector2(map_size, screen_y), ROAD_COLOR, 5.0, true)

	# Active objective line and destination marker.
	if _has_target and is_instance_valid(_player):
		var target_pt := _world_to_map(_target, player_pos, center, scale)
		var target_inside := target_pt.x >= inset and target_pt.x <= map_size - inset and target_pt.y >= inset and target_pt.y <= map_size - inset
		if target_inside:
			draw_line(center, target_pt, Color(0.86, 0.67, 0.40, 0.75), 2.0, true)
			draw_circle(target_pt, 5.0, OBJECTIVE_COLOR)
			draw_arc(target_pt, 8.0, 0.0, TAU, 24, PLAYER_COLOR, 1.6, true)
		else:
			var direction := target_pt - center
			if direction.length() > 0.01:
				var edge_limit := map_size * 0.5 - inset - 8.0
				var scale_to_edge := minf(edge_limit / maxf(absf(direction.x), 0.001), edge_limit / maxf(absf(direction.y), 0.001))
				var edge_pt := center + direction * minf(1.0, scale_to_edge)
				draw_circle(edge_pt, 4.0, OBJECTIVE_COLOR)

	# Player arrow points along the character's actual facing direction.
	if is_instance_valid(_player):
		var forward3 := -_player.global_transform.basis.z
		var forward := Vector2(forward3.x, forward3.z).normalized()
		if forward.length() < 0.1:
			forward = Vector2(0.0, -1.0)
		var right := Vector2(-forward.y, forward.x)
		var arrow := PackedVector2Array([
			center + forward * 9.0,
			center - forward * 5.0 + right * 5.5,
			center - forward * 3.0,
			center - forward * 5.0 - right * 5.5
		])
		draw_colored_polygon(arrow, PLAYER_COLOR)
		draw_polyline(PackedVector2Array([arrow[0], arrow[1], arrow[2], arrow[3], arrow[0]]), Color("#fff0d4"), 1.4, true)
	else:
		draw_circle(center, 4.0, PLAYER_COLOR)

	# Corner label, frame and small compass tick.
	var font := get_theme_default_font()
	if font:
		draw_string(font, Vector2(10.0, 16.0), "KOCHI", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color("#f0eee6"))
		draw_string(font, Vector2(map_size - 14.0, 16.0), "N", HORIZONTAL_ALIGNMENT_CENTER, -1.0, 10, Color("#c0c9c5"))
	draw_line(Vector2(map_size - 14.0, 21.0), Vector2(map_size - 14.0, 28.0), Color("#c0c9c5"), 1.2, true)
	draw_rect(panel, Color("#9a9d97"), false, 1.5, true)
