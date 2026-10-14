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
    "var drag := event.position - origin\n\t\t\t\tvector = Vector2(drag.x, -drag.y).limit_length(radius) / radius"
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
