#!/usr/bin/env python3
"""Apply Godot 4.7 static-typing fixes discovered by the cloud engine parser."""
from pathlib import Path
import sys

path = Path(sys.argv[1])
source = path.read_text(encoding="utf-8")
replacements = {
    "var bx := x + side * 18.0": "var bx: float = float(x) + float(side) * 18.0",
    "var wx := bx + (float(window_index) - 0.5) * (width * 0.46)": "var wx: float = bx + (float(window_index) - 0.5) * (width * 0.46)",
    "var d := player.global_position.distance_to(node.global_position)": "var d: float = player.global_position.distance_to((node as Node3D).global_position)",
    "var d := player.global_position.distance_to(person.global_position)": "var d: float = player.global_position.distance_to((person as Node3D).global_position)",
    "var spawn_pos := player.global_position + Vector3(0,0,22)": "var spawn_pos: Vector3 = player.global_position + Vector3(0,0,22)",
}
for old, new in replacements.items():
    if old in source:
        source = source.replace(old, new, 1)
path.write_text(source, encoding="utf-8")
if "var bx: float" not in source or "var wx: float" not in source or source.count("var d: float = player.global_position.distance_to") < 2 or "var spawn_pos: Vector3" not in source:
    raise SystemExit("Godot parser type annotation patch incomplete")
print("Applied explicit GDScript types for generated world coordinates, distances and police spawn position.")
