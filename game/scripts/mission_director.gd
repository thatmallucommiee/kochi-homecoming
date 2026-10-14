extends Node
## Lightweight story mission director for Kochi: Homecoming.
## Uses no external assets and creates its own objective HUD for the Android starter.

signal mission_changed(title: String, objective: String)
signal objective_completed(objective: String)
signal mission_completed(title: String)

var missions: Array[Dictionary] = [
	{
		"title": "PROLOGUE — THE RETURN",
		"objectives": [
			"Arrive in Kochi",
			"Look around the street",
			"Find the way to Abraham's house"
		],
		"briefing": "Kochi. 2026. After years away, Vivek returns following his father's death."
	},
	{
		"title": "MISSION 01 — THE OLD HOUSE",
		"objectives": [
			"Enter the family home",
			"Look around the living room",
			"Inspect the photograph near the table"
		],
		"briefing": "The house feels smaller than Vivek remembers. Everything else feels unchanged."
	},
	{
		"title": "MISSION 02 — THE MECHANIC",
		"objectives": [
			"Leave the house",
			"Find Rafi's garage",
			"Speak to Rafi"
		],
		"briefing": "Rafi knew Abraham, but how much he knows is not clear yet."
	},
	{
		"title": "MISSION 03 — THE LAST DRIVE",
		"objectives": [
			"Listen to what Rafi remembers",
			"Visit the road where Abraham's car was found",
			"Look around the crash site"
		],
		"briefing": "The official story is a road accident. Vivek has no reason to suspect more—yet."
	}
]

var mission_index := 0
var objective_index := 0
var hud: CanvasLayer
var title_label: Label
var objective_label: Label
var hint_label: Label
var toast_label: Label
var toast_timer := 0.0
var interact_button: Button
var driving_mode := false
var map_overlay: Control
var map_open := false
var nearby_interaction := ""
var nearby_action: Callable

func _ready() -> void:
	_build_hud()
	call_deferred("start_current_mission")

func _process(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0 and is_instance_valid(toast_label):
			toast_label.text = ""
	if is_instance_valid(hint_label):
		hint_label.text = ("INTERACT  •  " + nearby_interaction) if nearby_interaction != "" else "Explore the area"

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "MissionHUD"
	hud.layer = 20
	add_child(hud)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(root)

	var panel := PanelContainer.new()
	panel.position = Vector2(18, 22)
	panel.custom_minimum_size = Vector2(300, 92)
	panel.size = Vector2(330, 112)
	root.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	panel.add_child(stack)
	var minimap_script := load("res://scripts/city_minimap.gd") as Script
	if minimap_script != null:
		var minimap := Control.new()
		minimap.name = "CityMinimap"
		minimap.set_script(minimap_script)
		minimap.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		minimap.position = Vector2(-184.0, 18.0)
		minimap.custom_minimum_size = Vector2(166.0, 166.0)
		minimap.size = Vector2(166.0, 166.0)
		root.add_child(minimap)
	var map_button := Button.new()
	map_button.text = "MAP"
	map_button.custom_minimum_size = Vector2(88, 52)
	map_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	map_button.position = Vector2(-104, 194)
	map_button.pressed.connect(toggle_full_map)
	root.add_child(map_button)
	map_overlay = Control.new()
	map_overlay.name = "FullMapOverlay"
	map_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_overlay.visible = false
	map_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(map_overlay)
	var dimmer := ColorRect.new()
	dimmer.color = Color(0.025, 0.035, 0.04, 0.94)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_overlay.add_child(dimmer)
	var map_title := Label.new()
	map_title.text = "KOCHI  /  CITY MAP"
	map_title.position = Vector2(28, 24)
	map_title.add_theme_font_size_override("font_size", 24)
	map_overlay.add_child(map_title)
	var full_map_script := load("res://scripts/city_minimap.gd") as Script
	if full_map_script != null:
		var full_map := Control.new()
		full_map.name = "FullCityMap"
		full_map.set_script(full_map_script)
		full_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		full_map.offset_left = 22
		full_map.offset_top = 64
		full_map.offset_right = -22
		full_map.offset_bottom = -84
		full_map.set("full_city_view", true)
		map_overlay.add_child(full_map)
	var close_map := Button.new()
	close_map.text = "CLOSE MAP"
	close_map.custom_minimum_size = Vector2(150, 54)
	close_map.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	close_map.position = Vector2(-176, -24)
	close_map.pressed.connect(toggle_full_map)
	map_overlay.add_child(close_map)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.text = "KOCHI: HOMECOMING"
	stack.add_child(title_label)
	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.add_theme_font_size_override("font_size", 14)
	stack.add_child(objective_label)

	hint_label = Label.new()
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hint_label.position = Vector2(24, -74)
	hint_label.add_theme_font_size_override("font_size", 16)
	root.add_child(hint_label)

	interact_button = Button.new()
	interact_button.text = "INTERACT"
	interact_button.custom_minimum_size = Vector2(150, 58)
	# Keep INTERACT clear of the starter's RUN button and the sprint control.
	# A mid-right anchor stays reachable in landscape without covering movement controls.
	interact_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	interact_button.position = Vector2(-178, 58)
	interact_button.pressed.connect(interact)
	root.add_child(interact_button)

	toast_label = Label.new()
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast_label.position = Vector2(-240, 150)
	toast_label.size = Vector2(480, 70)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.add_theme_font_size_override("font_size", 18)
	root.add_child(toast_label)

func toggle_full_map() -> void:
	map_open = not map_open
	if is_instance_valid(map_overlay):
		map_overlay.visible = map_open
		map_overlay.mouse_filter = Control.MOUSE_FILTER_STOP if map_open else Control.MOUSE_FILTER_IGNORE

func start_current_mission() -> void:
	if mission_index >= missions.size():
		_show_toast("PROLOGUE COMPLETE")
		return
	var mission: Dictionary = missions[mission_index]
	objective_index = 0
	mission_changed.emit(mission.title, mission.objectives[0])
	if is_instance_valid(title_label):
		title_label.text = mission.title
		objective_label.text = "› " + mission.objectives[0]
	_show_toast(mission.briefing)

func set_nearby_interaction(label: String, action: Callable = Callable()) -> void:
	nearby_interaction = label
	nearby_action = action
	if is_instance_valid(interact_button):
		interact_button.disabled = driving_mode or nearby_interaction == ""

func clear_nearby_interaction() -> void:
	nearby_interaction = ""
	nearby_action = Callable()
	if is_instance_valid(interact_button):
		interact_button.disabled = true

func set_driving_mode(enabled: bool) -> void:
	driving_mode = enabled
	if is_instance_valid(interact_button):
		interact_button.visible = not enabled
		interact_button.disabled = enabled or nearby_interaction == ""

func interact() -> void:
	if nearby_interaction == "":
		_show_toast("Nothing to interact with nearby.")
		return
	var action := nearby_action
	var label := nearby_interaction
	clear_nearby_interaction()
	_show_toast(label)
	if action.is_valid():
		action.call()

func show_story_line(message: String, duration: float = 5.0) -> void:
	_show_toast(message)
	toast_timer = maxf(duration, 1.0)

func advance_objective() -> void:
	if mission_index >= missions.size():
		return
	var mission: Dictionary = missions[mission_index]
	var objectives: Array = mission.objectives
	var completed: String = objectives[objective_index]
	objective_completed.emit(completed)
	objective_index += 1
	if objective_index >= objectives.size():
		mission_completed.emit(mission.title)
		mission_index += 1
		start_current_mission()
	else:
		objective_label.text = "› " + str(objectives[objective_index])
		_show_toast("Objective updated")

func complete_objective(expected_text: String = "") -> void:
	if mission_index >= missions.size():
		return
	var mission: Dictionary = missions[mission_index]
	var objectives: Array = mission.objectives
	if expected_text != "" and str(objectives[objective_index]) != expected_text:
		return
	advance_objective()

func _show_toast(message: String) -> void:
	if not is_instance_valid(toast_label):
		return
	toast_label.text = message
	toast_timer = 4.5

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact()
