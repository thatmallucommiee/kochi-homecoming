#!/usr/bin/env python3
"""Patch the downloaded Godot starter deterministically for Kochi: Homecoming."""
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
scripts = root / "scripts"
player_source = Path(sys.argv[2]).read_text()
model_source = Path(sys.argv[3]).read_text()
(scripts / "player.gd").write_text(player_source)
(scripts / "vivek_model.gd").write_text(model_source)

game_path = scripts / "game.gd"
game = game_path.read_text()
start = game.find("func _build_player() -> void:")
end = game.find("func _build_audio() -> void:", start)
if start < 0 or end < 0:
    raise SystemExit("Could not safely locate _build_player() in starter game.gd")
replacement = '''func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Vivek"
	player.set_script(PLAYER_SCRIPT)
	player.position = Vector3(0, 1.1, 25)
	add_child(player)

	var model := Node3D.new()
	model.name = "VivekModel"
	model.set_script(load("res://scripts/vivek_model.gd"))
	player.add_child(model)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.75
	collision.shape = shape
	collision.position.y = 0.88
	player.add_child(collision)

	var pivot := Node3D.new()
	pivot.name = "CameraPivot"
	pivot.position.y = 1.55
	player.add_child(pivot)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0, 1.25, 5.8)
	camera.rotation_degrees.x = -10
	camera.current = true
	pivot.add_child(camera)

'''
game = game[:start] + replacement + game[end:]

# GUI input positions are already local to the joystick Control. Do not subtract
# global_position twice; always forward the vector so release sends Vector2.ZERO.
game = game.replace(
    "origin = event.position - global_position",
    "origin = event.position"
)
game = game.replace(
    "vector = Vector2((event.position - global_position - origin).x, -(event.position - global_position - origin).y).limit_length(radius) / radius",
    "var drag: Vector2 = event.position - origin\n\t\t\t\tvector = Vector2(drag.x, -drag.y).limit_length(radius) / radius"
)
old = '''\tfunc _process(_delta: float) -> void:
\t\tif finger_id != -1:
\t\t\tvar p := get_parent().get_parent()
\t\t\tif p.has_node("Vivek"):
\t\t\t\tvar actor = p.get_node("Vivek")
\t\t\t\tactor.set("touch_move", vector)
\t\tqueue_redraw()
'''
new = '''\tfunc _process(_delta: float) -> void:
\t\tvar p := get_parent().get_parent()
\t\tif p.has_node("Vivek"):
\t\t\tvar actor = p.get_node("Vivek")
\t\t\tactor.set("touch_move", vector if finger_id != -1 else Vector2.ZERO)
\t\tqueue_redraw()
'''
if old not in game:
    raise SystemExit("Could not safely locate joystick _process() to fix release handling")
game = game.replace(old, new)
# Keep the starter's atmosphere, but remove its duplicate test road and block meshes.
# CityWorld owns the actual playable city so two competing layouts do not overlap.
world_start = game.find("func _build_world() -> void:")
world_end = game.find("func _build_kerala_blocks() -> void:", world_start)
if world_start < 0 or world_end < 0:
    raise SystemExit("Could not safely locate starter _build_world()")
world_replacement = '''func _build_world() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.08, 0.12, 0.16)
	sky_mat.sky_horizon_color = Color(0.28, 0.31, 0.30)
	sky.sky_material = sky_mat
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.47, 0.52, 0.55)
	environment.ambient_light_energy = 0.7
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = environment
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -28, 0)
	sun.light_color = Color(1.0, 0.78, 0.58)
	sun.light_energy = 0.65
	add_child(sun)
	if rain_mode:
		_build_rain()

'''
game = game[:world_start] + world_replacement + game[world_end:]

# Route the starter's on-screen INTERACT button into the real mission system.
interact_start = game.find("func _interact() -> void:")
interact_end = game.find("func _add_box(", interact_start)
if interact_start < 0 or interact_end < 0:
    raise SystemExit("Could not safely locate starter _interact() handler")
interact_replacement = '''func _interact() -> void:
	if not started:
		return
	var director := get_node_or_null("/root/MissionDirector")
	if director != null:
		director.call("interact")
	else:
		hint_label.text = "Nothing to interact with nearby."

'''
game = game[:interact_start] + interact_replacement + game[interact_end:]

game_path.write_text(game)
print("Applied corrected movement, joystick release, articulated Vivek, and mission interaction wiring.")
