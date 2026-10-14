extends Node
## One drivable compact car with enter/exit, touch controls and a third-person vehicle camera.
## Kept separate from the on-foot controller to avoid replacing the starter's movement logic.

var _vehicle: VehicleBody3D
var _vehicle_camera: Camera3D
var _player: CharacterBody3D
var _in_vehicle := false
var _vehicle_root: Node3D
var _drive_hud: CanvasLayer
var _drive_controls: Control
var _throttle := 0.0
var _brake := 0.0
var _steering_input := 0.0
var _steering_smoothed := 0.0
var _old_camera_states: Array[Dictionary] = []
var _old_visual_states: Array[Dictionary] = []
var _old_collision_states: Array[Dictionary] = []
var _old_canvas_states: Array[Dictionary] = []
var _ui_ready := false

func _ready() -> void:
	_create_drive_hud()

func _process(_delta: float) -> void:
	if not _ui_ready:
		_create_drive_hud()
	var city := get_node_or_null("/root/CityWorld")
	if city == null:
		return
	var city_root := city.get("_city_root") as Node3D
	if not is_instance_valid(city_root):
		return
	if not is_instance_valid(_vehicle) or _vehicle.get_parent() != city_root:
		_vehicle = _create_vehicle(city_root)
	if _in_vehicle and (not is_instance_valid(_player) or not is_instance_valid(_vehicle)):
		_force_exit()
	if not _in_vehicle:
		_offer_vehicle_interaction()

func _physics_process(delta: float) -> void:
	if not _in_vehicle or not is_instance_valid(_vehicle):
		return
	var keyboard_throttle := 1.0 if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) else 0.0
	var keyboard_brake := 1.0 if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) else 0.0
	var keyboard_steer := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		keyboard_steer -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		keyboard_steer += 1.0
	var throttle := maxf(_throttle, keyboard_throttle)
	var brake := maxf(_brake, keyboard_brake)
	var steer := _steering_input if absf(_steering_input) > 0.01 else keyboard_steer
	_steering_smoothed = move_toward(_steering_smoothed, steer, delta * 2.8)
	_vehicle.engine_force = throttle * 2400.0
	_vehicle.brake = brake * 42.0
	_vehicle.steering = _steering_smoothed * 0.42

func _create_vehicle(parent: Node3D) -> VehicleBody3D:
	var body := VehicleBody3D.new()
	body.name = "DrivableCompactCar"
	body.mass = 1120.0
	body.position = Vector3(2.0, 0.56, 21.5)
	# VehicleBody3D's forward axis is local -Z; this puts the car along the east-west road.
	body.rotation.y = -PI * 0.5
	body.continuous_cd = true
	body.can_sleep = false

	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color("#42657b")
	paint.roughness = 0.44
	var trim := StandardMaterial3D.new()
	trim.albedo_color = Color("#202729")
	trim.roughness = 0.82
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color("#23383e")
	glass.roughness = 0.22
	glass.metallic = 0.12
	var rubber := StandardMaterial3D.new()
	rubber.albedo_color = Color("#242526")
	rubber.roughness = 1.0
	var chrome := StandardMaterial3D.new()
	chrome.albedo_color = Color("#aeb7b5")
	chrome.metallic = 0.65
	chrome.roughness = 0.38
	var headlamp := StandardMaterial3D.new()
	headlamp.albedo_color = Color("#f1dfad")
	headlamp.emission_enabled = true
	headlamp.emission = Color("#e4cd8b")
	headlamp.emission_energy_multiplier = 0.65
	var rear_lamp := StandardMaterial3D.new()
	rear_lamp.albedo_color = Color("#8f3029")
	rear_lamp.emission_enabled = true
	rear_lamp.emission = Color("#6b1714")
	rear_lamp.emission_energy_multiplier = 0.35

	var collision := CollisionShape3D.new()
	collision.name = "VehicleBodyCollision"
	var collision_shape := BoxShape3D.new()
	collision_shape.size = Vector3(1.86, 0.82, 4.05)
	collision.position = Vector3(0.0, -0.02, 0.0)
	collision.shape = collision_shape
	body.add_child(collision)

	_add_visual_part(body, paint, Vector3(1.86, 0.63, 4.18), Vector3(0, -0.08, 0))
	_add_visual_part(body, paint, Vector3(1.78, 0.20, 1.28), Vector3(0, 0.18, -1.35))
	_add_visual_part(body, paint, Vector3(1.75, 0.18, 0.82), Vector3(0, 0.16, 1.52))
	_add_visual_part(body, glass, Vector3(1.48, 0.62, 2.14), Vector3(0, 0.43, 0.12))
	_add_visual_part(body, trim, Vector3(1.56, 0.10, 2.20), Vector3(0, 0.77, 0.12))
	_add_visual_part(body, glass, Vector3(0.045, 0.28, 1.16), Vector3(-0.75, 0.43, 0.13))
	_add_visual_part(body, glass, Vector3(0.045, 0.28, 1.16), Vector3(0.75, 0.43, 0.13))
	_add_visual_part(body, chrome, Vector3(0.68, 0.15, 0.05), Vector3(0, -0.10, -2.11))
	_add_visual_part(body, headlamp, Vector3(0.24, 0.17, 0.10), Vector3(-0.63, 0.02, -2.12))
	_add_visual_part(body, headlamp, Vector3(0.24, 0.17, 0.10), Vector3(0.63, 0.02, -2.12))
	_add_visual_part(body, rear_lamp, Vector3(0.20, 0.19, 0.10), Vector3(-0.64, 0.03, 2.10))
	_add_visual_part(body, rear_lamp, Vector3(0.20, 0.19, 0.10), Vector3(0.64, 0.03, 2.10))
	_add_visual_part(body, trim, Vector3(1.90, 0.12, 0.14), Vector3(0, -0.30, -1.93))
	_add_visual_part(body, trim, Vector3(1.90, 0.12, 0.14), Vector3(0, -0.30, 1.93))

	for front in [true, false]:
		for side in [-1.0, 1.0]:
			var wheel := VehicleWheel3D.new()
			wheel.name = ("Front" if front else "Rear") + ("LeftWheel" if side < 0 else "RightWheel")
			wheel.position = Vector3(side * 0.91, -0.31, -1.34 if front else 1.34)
			wheel.wheel_radius = 0.34
			wheel.wheel_rest_length = 0.20
			wheel.suspension_travel = 0.22
			wheel.suspension_stiffness = 28.0
			wheel.damping_compression = 4.2
			wheel.damping_relaxation = 4.5
			wheel.wheel_friction_slip = 2.2
			wheel.wheel_roll_influence = 0.08
			wheel.use_as_steering = front
			wheel.use_as_traction = not front
			body.add_child(wheel)
			var tire_mesh := CylinderMesh.new()
			tire_mesh.top_radius = 0.34
			tire_mesh.bottom_radius = 0.34
			tire_mesh.height = 0.20
			tire_mesh.radial_segments = 12
			var tire := MeshInstance3D.new()
			tire.name = "RubberTire"
			tire.mesh = tire_mesh
			tire.material_override = rubber
			tire.rotation.z = PI * 0.5
			wheel.add_child(tire)
			var hub_mesh := CylinderMesh.new()
			hub_mesh.top_radius = 0.17
			hub_mesh.bottom_radius = 0.17
			hub_mesh.height = 0.205
			hub_mesh.radial_segments = 10
			var hub := MeshInstance3D.new()
			hub.name = "WheelHub"
			hub.mesh = hub_mesh
			hub.material_override = chrome
			hub.rotation.z = PI * 0.5
			hub.position.x = side * 0.015
			wheel.add_child(hub)

	_vehicle_camera = Camera3D.new()
	_vehicle_camera.name = "VehicleFollowCamera"
	_vehicle_camera.position = Vector3(0.0, 2.8, 7.2)
	_vehicle_camera.rotation.x = deg_to_rad(-13.0)
	_vehicle_camera.fov = 72.0
	_vehicle_camera.current = false
	body.add_child(_vehicle_camera)
	parent.add_child(body)
	return body

func _add_visual_part(parent: Node3D, material: Material, dimensions: Vector3, position: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = position
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)

func _find_player() -> CharacterBody3D:
	if is_instance_valid(_player):
		return _player
	var scene := get_tree().current_scene
	if scene == null:
		return null
	if scene is CharacterBody3D:
		_player = scene as CharacterBody3D
		return _player
	var candidates := scene.find_children("*", "CharacterBody3D", true, false)
	for candidate in candidates:
		if candidate is CharacterBody3D:
			_player = candidate as CharacterBody3D
			return _player
	return null

func _offer_vehicle_interaction() -> void:
	if not is_instance_valid(_vehicle) or _in_vehicle:
		return
	var player := _find_player()
	if player == null:
		return
	var director := get_node_or_null("/root/MissionDirector")
	if director == null:
		return
	var current_prompt := str(director.get("nearby_interaction"))
	if player.global_position.distance_to(_vehicle.global_position) <= 4.8:
		if current_prompt == "":
			director.call("set_nearby_interaction", "Drive the car", Callable(self, "enter_vehicle"))
	elif current_prompt == "Drive the car":
		director.call("clear_nearby_interaction")

func enter_vehicle() -> void:
	if _in_vehicle or not is_instance_valid(_vehicle):
		return
	var player := _find_player()
	if player == null or player.global_position.distance_to(_vehicle.global_position) > 5.5:
		return
	_player = player
	_old_camera_states.clear()
	_old_visual_states.clear()
	_old_collision_states.clear()
	_old_canvas_states.clear()
	var scene := get_tree().current_scene
	if scene != null:
		for camera_node in scene.find_children("*", "Camera3D", true, false):
			if camera_node is Camera3D:
				var camera := camera_node as Camera3D
				_old_camera_states.append({"node": camera, "current": camera.current})
				camera.current = false
		for visual_node in player.find_children("*", "VisualInstance3D", true, false):
			if visual_node is VisualInstance3D:
				var visual := visual_node as VisualInstance3D
				_old_visual_states.append({"node": visual, "visible": visual.visible})
				visual.visible = false
		for shape_node in player.find_children("*", "CollisionShape3D", true, false):
			if shape_node is CollisionShape3D:
				var shape := shape_node as CollisionShape3D
				_old_collision_states.append({"node": shape, "disabled": shape.disabled})
				shape.disabled = true
		for canvas_node in scene.find_children("*", "CanvasLayer", true, false):
			if canvas_node is CanvasLayer:
				var canvas := canvas_node as CanvasLayer
				_old_canvas_states.append({"node": canvas, "visible": canvas.visible})
				canvas.visible = false
	player.velocity = Vector3.ZERO
	player.set_process(false)
	player.set_physics_process(false)
	_in_vehicle = true
	_throttle = 0.0
	_brake = 0.0
	_steering_input = 0.0
	_steering_smoothed = 0.0
	_drive_hud.visible = true
	_vehicle_camera.make_current()
	var director := get_node_or_null("/root/MissionDirector")
	if director:
		director.call("set_driving_mode", true)
		director.call("show_story_line", "Use the driving controls to move. Tap EXIT to leave the car.")
	_update_drive_button_state()

func exit_vehicle() -> void:
	if not _in_vehicle:
		return
	_restore_player_from_vehicle()

func _force_exit() -> void:
	if _in_vehicle:
		_restore_player_from_vehicle()

func _restore_player_from_vehicle() -> void:
	if is_instance_valid(_vehicle):
		_vehicle.engine_force = 0.0
		_vehicle.brake = 40.0
		_vehicle.steering = 0.0
	if is_instance_valid(_vehicle_camera):
		_vehicle_camera.current = false
	if is_instance_valid(_player) and is_instance_valid(_vehicle):
		var exit_position := _vehicle.global_position + _vehicle.global_transform.basis.z * 3.2 + Vector3(0, 0.12, 0)
		_player.global_position = exit_position
		_player.global_rotation.y = _vehicle.global_rotation.y
		_player.velocity = Vector3.ZERO
		_player.visible = true
		_player.set_process(true)
		_player.set_physics_process(true)
	for state in _old_visual_states:
		var node: VisualInstance3D = state["node"]
		if is_instance_valid(node):
			node.visible = bool(state["visible"])
	for state in _old_collision_states:
		var node: CollisionShape3D = state["node"]
		if is_instance_valid(node):
			node.disabled = bool(state["disabled"])
	for state in _old_canvas_states:
		var node: CanvasLayer = state["node"]
		if is_instance_valid(node):
			node.visible = bool(state["visible"])
	for state in _old_camera_states:
		var node: Camera3D = state["node"]
		if is_instance_valid(node) and bool(state["current"]):
			node.make_current()
	_in_vehicle = false
	_throttle = 0.0
	_brake = 0.0
	_steering_input = 0.0
	_steering_smoothed = 0.0
	_drive_hud.visible = false
	var director := get_node_or_null("/root/MissionDirector")
	if director:
		director.call("set_driving_mode", false)
		director.call("clear_nearby_interaction")
		director.call("show_story_line", "You're back on foot.")
	_old_camera_states.clear()
	_old_visual_states.clear()
	_old_collision_states.clear()
	_old_canvas_states.clear()

func _create_drive_hud() -> void:
	if is_instance_valid(_drive_hud):
		return
	_drive_hud = CanvasLayer.new()
	_drive_hud.name = "DrivingHUD"
	_drive_hud.layer = 30
	add_child(_drive_hud)
	_drive_controls = Control.new()
	_drive_controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_drive_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drive_hud.add_child(_drive_controls)
	_make_hold_button("LEFT", Vector2(24, -100), Vector2(76, 64), "steering", -1.0, false)
	_make_hold_button("RIGHT", Vector2(110, -100), Vector2(76, 64), "steering", 1.0, false)
	_make_hold_button("BRAKE", Vector2(-196, -100), Vector2(82, 64), "brake", 1.0, true)
	_make_hold_button("ACCELERATE", Vector2(-104, -100), Vector2(94, 64), "throttle", 1.0, true)
	var exit_button := Button.new()
	exit_button.name = "ExitVehicle"
	exit_button.text = "EXIT"
	exit_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	exit_button.position = Vector2(-94, 20)
	exit_button.custom_minimum_size = Vector2(76, 50)
	exit_button.size = Vector2(76, 50)
	exit_button.add_theme_font_size_override("font_size", 14)
	exit_button.pressed.connect(exit_vehicle)
	_drive_controls.add_child(exit_button)
	_drive_hud.visible = false
	_ui_ready = true

func _make_hold_button(label: String, offset: Vector2, button_size: Vector2, input_name: String, input_value: float, from_right: bool) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = button_size
	button.size = button_size
	button.add_theme_font_size_override("font_size", 14)
	if from_right:
		button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	else:
		button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	button.position = offset
	button.button_down.connect(Callable(self, "_set_drive_input").bind(input_name, input_value))
	button.button_up.connect(Callable(self, "_set_drive_input").bind(input_name, 0.0))
	_drive_controls.add_child(button)

func _set_drive_input(input_name: String, value: float) -> void:
	match input_name:
		"throttle":
			_throttle = value
		"brake":
			_brake = value
		"steering":
			_steering_input = value

func _update_drive_button_state() -> void:
	if not is_instance_valid(_drive_hud):
		return
