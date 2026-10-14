extends CharacterBody3D
## Camera-relative third-person movement controller for Android and desktop.
## Joystick convention: up is negative Y; world forward is negative Z.

@export var walk_speed := 4.2
@export var sprint_speed := 6.8
@export var acceleration := 18.0
@export var gravity := 22.0
@export var turn_speed := 10.0

var touch_move := Vector2.ZERO
var camera_pivot: Node3D
var camera: Camera3D
var look_touch_id := -1
var last_look := Vector2.ZERO
var yaw := 0.0
var pitch := -0.14

func _ready() -> void:
	camera_pivot = get_node_or_null("CameraPivot")
	camera = get_node_or_null("CameraPivot/Camera3D")
	if camera_pivot:
		camera_pivot.rotation.y = wrapf(yaw - rotation.y, -PI, PI)
	if camera:
		camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
	var move := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if touch_move.length() > 0.08:
		move = touch_move
	move = move.limit_length(1.0)

	# Godot's input vector has negative Y for forward, matching world/local -Z.
	# Rotate only around Y so camera pitch never pushes the player into the ground.
	var direction := Vector3(move.x, 0.0, move.y)
	if camera_pivot:
		var yaw_basis := Basis(Vector3.UP, yaw)
		direction = yaw_basis * direction
	direction.y = 0.0
	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	var moving := direction.length() > 0.08
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.2
	if moving:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, turn_speed * delta))
	if camera_pivot:
		# Keep camera world yaw independent from the body rotation.
		camera_pivot.rotation.y = wrapf(yaw - rotation.y, -PI, PI)
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x > get_viewport().get_visible_rect().size.x * 0.48 and look_touch_id == -1:
			look_touch_id = event.index
			last_look = event.position
		elif not event.pressed and event.index == look_touch_id:
			look_touch_id = -1
	elif event is InputEventScreenDrag and event.index == look_touch_id:
		var delta_pos: Vector2 = event.position - last_look
		last_look = event.position
		yaw -= delta_pos.x * 0.004
		pitch = clampf(pitch - delta_pos.y * 0.003, -0.55, 0.15)
		if camera_pivot:
			camera_pivot.rotation.y = wrapf(yaw - rotation.y, -PI, PI)
		if camera:
			camera.rotation.x = pitch
