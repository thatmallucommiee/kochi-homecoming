extends Node3D
## Lightweight articulated civilian character for Vivek.
## Separate joint pivots produce a visible walk/run cycle without heavyweight runtime assets.

var torso: MeshInstance3D
var head: Node3D
var arm_left: Node3D
var arm_right: Node3D
var elbow_left: Node3D
var elbow_right: Node3D
var leg_left: Node3D
var leg_right: Node3D
var knee_left: Node3D
var knee_right: Node3D
var _phase := 0.0

func _ready() -> void:
	_build_character()

func _process(delta: float) -> void:
	var actor := get_parent() as CharacterBody3D
	if actor == null:
		return
	var horizontal_speed := Vector2(actor.velocity.x, actor.velocity.z).length()
	var moving := horizontal_speed > 0.18 and actor.is_on_floor()
	_phase += delta * (10.0 if horizontal_speed > 4.8 else 7.0) if moving else delta * 2.0
	var swing := sin(_phase) * (0.62 if moving else 0.035)
	if is_instance_valid(arm_left):
		arm_left.rotation.x = swing
	if is_instance_valid(arm_right):
		arm_right.rotation.x = -swing
	if is_instance_valid(elbow_left):
		elbow_left.rotation.x = (0.08 + maxf(0.0, sin(_phase + 0.7)) * 0.22) if moving else 0.0
	if is_instance_valid(elbow_right):
		elbow_right.rotation.x = (0.08 + maxf(0.0, sin(_phase + PI + 0.7)) * 0.22) if moving else 0.0
	if is_instance_valid(leg_left):
		leg_left.rotation.x = -swing * 0.85
	if is_instance_valid(leg_right):
		leg_right.rotation.x = swing * 0.85
	if is_instance_valid(knee_left):
		knee_left.rotation.x = maxf(0.0, sin(_phase)) * 0.58 if moving else 0.0
	if is_instance_valid(knee_right):
		knee_right.rotation.x = maxf(0.0, sin(_phase + PI)) * 0.58 if moving else 0.0
	if is_instance_valid(torso):
		torso.position.y = 1.02 + (absf(sin(_phase * 2.0)) * 0.035 if moving else 0.0)
		torso.rotation.x = -0.055 if moving and horizontal_speed > 5.0 else 0.0
		torso.rotation.z = sin(_phase) * 0.012 if moving else 0.0
	if is_instance_valid(head):
		head.rotation.z = sin(_phase) * 0.025 if moving else 0.0

func _build_character() -> void:
	var shirt := _material(Color("#263d43"))
	var shirt_light := _material(Color("#38545a"))
	var skin := _material(Color("#a87557"))
	var hair := _material(Color("#211f1d"), 0.98)
	var trousers := _material(Color("#303d4c"))
	var shoes := _material(Color("#171a1b"))
	var sole := _material(Color("#4b4943"))

	torso = _mesh_box("Torso", Vector3(0, 1.02, 0), Vector3(0.53, 0.64, 0.30), shirt)
	_mesh_box("ShirtFront", Vector3(0, 1.02, -0.157), Vector3(0.32, 0.42, 0.018), shirt_light)
	# Rounded shoulder caps and a small shirt pocket break up the old hard-block silhouette.
	_mesh_sphere(self, "LeftShoulder", Vector3(-0.22, 1.23, 0.0), Vector3(0.22, 0.22, 0.29), shirt)
	_mesh_sphere(self, "RightShoulder", Vector3(0.22, 1.23, 0.0), Vector3(0.22, 0.22, 0.29), shirt)
	var collar_left := _mesh_box("CollarLeft", Vector3(-0.065, 1.335, -0.165), Vector3(0.13, 0.075, 0.04), shirt_light)
	collar_left.rotation.z = -0.32
	var collar_right := _mesh_box("CollarRight", Vector3(0.065, 1.335, -0.165), Vector3(0.13, 0.075, 0.04), shirt_light)
	collar_right.rotation.z = 0.32
	_mesh_box("ChestPocket", Vector3(0.14, 1.10, -0.171), Vector3(0.12, 0.15, 0.02), shirt_light)
	_mesh_capsule("Neck", Vector3(0, 1.40, 0), 0.09, 0.16, skin)
	head = Node3D.new()
	head.name = "HeadPivot"
	head.position = Vector3(0, 1.60, 0)
	add_child(head)
	_mesh_sphere(head, "Face", Vector3(0, 0.02, -0.005), Vector3(0.205, 0.255, 0.19), skin)
	_mesh_sphere(head, "Hair", Vector3(0, 0.125, 0), Vector3(0.215, 0.125, 0.205), hair)
	_mesh_box_parent(head, "Hairline", Vector3(0, 0.055, -0.095), Vector3(0.30, 0.08, 0.045), hair)
	_mesh_box_parent(head, "LeftEye", Vector3(-0.063, 0.035, -0.096), Vector3(0.025, 0.018, 0.012), _material(Color("#171717")))
	_mesh_box_parent(head, "RightEye", Vector3(0.063, 0.035, -0.096), Vector3(0.025, 0.018, 0.012), _material(Color("#171717")))
	_mesh_box_parent(head, "LeftEyebrow", Vector3(-0.063, 0.078, -0.101), Vector3(0.072, 0.022, 0.024), hair)
	_mesh_box_parent(head, "RightEyebrow", Vector3(0.063, 0.078, -0.101), Vector3(0.072, 0.022, 0.024), hair)
	_mesh_sphere(head, "Nose", Vector3(0.0, 0.012, -0.123), Vector3(0.055, 0.075, 0.065), skin)
	_mesh_sphere(head, "LeftEar", Vector3(-0.198, 0.012, -0.002), Vector3(0.055, 0.09, 0.065), skin)
	_mesh_sphere(head, "RightEar", Vector3(0.198, 0.012, -0.002), Vector3(0.055, 0.09, 0.065), skin)
	_mesh_box_parent(head, "Mouth", Vector3(0.0, -0.060, -0.105), Vector3(0.065, 0.012, 0.016), _material(Color("#5f3e32")))

	arm_left = _joint("LeftArm", Vector3(-0.32, 1.27, 0))
	arm_right = _joint("RightArm", Vector3(0.32, 1.27, 0))
	for arm_info in [{"pivot": arm_left, "label": "Left"}, {"pivot": arm_right, "label": "Right"}]:
		var arm: Node3D = arm_info["pivot"]
		var arm_label := str(arm_info["label"])
		_add_limb(arm, "UpperArm", Vector3(0, -0.17, 0), Vector3(0.145, 0.36, 0.16), shirt)
		var elbow := Node3D.new()
		elbow.name = arm_label + "Elbow"
		elbow.position = Vector3(0, -0.30, -0.005)
		arm.add_child(elbow)
		if arm_label == "Left":
			elbow_left = elbow
		else:
			elbow_right = elbow
		_add_limb(elbow, "Forearm", Vector3(0, -0.15, -0.015), Vector3(0.115, 0.29, 0.13), shirt_light)
		_add_limb(elbow, "Hand", Vector3(0, -0.29, -0.02), Vector3(0.105, 0.12, 0.095), skin)

	leg_left = _joint("LeftLeg", Vector3(-0.135, 0.70, 0))
	leg_right = _joint("RightLeg", Vector3(0.135, 0.70, 0))
	for leg_info in [{"pivot": leg_left, "label": "Left"}, {"pivot": leg_right, "label": "Right"}]:
		var leg: Node3D = leg_info["pivot"]
		var leg_label := str(leg_info["label"])
		_add_limb(leg, "Thigh", Vector3(0, -0.19, 0), Vector3(0.205, 0.40, 0.23), trousers)
		var knee := Node3D.new()
		knee.name = leg_label + "Knee"
		knee.position = Vector3(0, -0.36, 0)
		leg.add_child(knee)
		if leg_label == "Left":
			knee_left = knee
		else:
			knee_right = knee
		_add_limb(knee, "Shin", Vector3(0, -0.15, -0.005), Vector3(0.16, 0.30, 0.18), trousers)
		_mesh_box_parent(knee, "Shoe", Vector3(0, -0.30, -0.065), Vector3(0.18, 0.10, 0.31), shoes)
		_mesh_box_parent(knee, "Sole", Vector3(0, -0.355, -0.065), Vector3(0.19, 0.035, 0.32), sole)
	_mesh_box("BagStrap", Vector3(-0.13, 1.09, 0.155), Vector3(0.055, 0.38, 0.025), hair)

func _material(color: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _joint(label: String, joint_position: Vector3) -> Node3D:
	var joint := Node3D.new()
	joint.name = label
	joint.position = joint_position
	add_child(joint)
	return joint

func _mesh_box(label: String, mesh_position: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	return _mesh_box_parent(self, label, mesh_position, dimensions, material)

func _mesh_box_parent(parent: Node3D, label: String, mesh_position: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.position = mesh_position
	instance.material_override = material
	parent.add_child(instance)
	return instance

func _mesh_capsule(label: String, mesh_position: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 6
	instance.mesh = mesh
	instance.position = mesh_position
	instance.material_override = material
	add_child(instance)
	return instance

func _mesh_sphere(parent: Node3D, label: String, mesh_position: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 16
	mesh.rings = 8
	instance.mesh = mesh
	instance.scale = dimensions
	instance.position = mesh_position
	instance.material_override = material
	parent.add_child(instance)
	return instance

func _add_limb(parent: Node3D, label: String, mesh_position: Vector3, dimensions: Vector3, material: Material) -> void:
	# Rounded capsule segments read much less like rigid boxes, while remaining a
	# tiny, asset-free mesh budget suitable for the Android prototype.
	var radius := minf(dimensions.x, dimensions.z) * 0.48
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(dimensions.y, radius * 2.0)
	mesh.radial_segments = 10
	mesh.rings = 6
	instance.mesh = mesh
	instance.position = mesh_position
	instance.material_override = material
	parent.add_child(instance)
