#!/usr/bin/env python3
"""Apply strict typing fixes needed by the Godot 4.7 parser."""
from pathlib import Path
import sys

root_file = Path(sys.argv[1])
root = root_file.parent.parent
targets = {
    root_file: {
        "var bx := x + side * 18.0": "var bx: float = float(x) + float(side) * 18.0",
        "var bz := z + (7.0 if side < 0 else -7.0)": "var bz: float = float(z) + (7.0 if side < 0 else -7.0)",
        "var wx := bx + (float(window_index) - 0.5) * (width * 0.46)": "var wx: float = bx + (float(window_index) - 0.5) * (width * 0.46)",
        "var d := player.global_position.distance_to(node.global_position)": "var d: float = player.global_position.distance_to((node as Node3D).global_position)",
        "var d := player.global_position.distance_to(person.global_position)": "var d: float = player.global_position.distance_to((person as Node3D).global_position)",
        "var spawn_pos := player.global_position + Vector3(0,0,22)": "var spawn_pos: Vector3 = player.global_position + Vector3(0,0,22)",
    },
    root / "scripts" / "player_controller.gd": {
        "var vehicle_heading := active_vehicle.rotation.y if active_vehicle != null and is_instance_valid(active_vehicle) else 0.0": "var vehicle_heading: float = (active_vehicle as Node3D).rotation.y if active_vehicle != null and is_instance_valid(active_vehicle) else 0.0",
        "var car := active_vehicle": "var car: Node3D = active_vehicle as Node3D",
        "var side := car.global_basis.x": "var side: Vector3 = car.global_basis.x",
        "var world_camera_yaw := car.rotation.y + camera_yaw": "var world_camera_yaw: float = car.rotation.y + camera_yaw",
    },
    root / "scripts" / "mission_manager.gd": {
        'var start_pos := game.gps_to_world(float(data.get("lat", 9.96)), float(data.get("lon", 76.25)))': 'var start_pos: Vector3 = game.gps_to_world(float(data.get("lat", 9.96)), float(data.get("lon", 76.25)))',
    },
}
for path, replacements in targets.items():
    if not path.exists():
        raise SystemExit(f"Expected source file missing: {path}")
    source = path.read_text(encoding="utf-8")
    for old, new in replacements.items():
        source = source.replace(old, new)
    path.write_text(source, encoding="utf-8")

game_source = root_file.read_text(encoding="utf-8")
player_source = (root / "scripts" / "player_controller.gd").read_text(encoding="utf-8")
mission_source = (root / "scripts" / "mission_manager.gd").read_text(encoding="utf-8")
assert "var bx: float" in game_source and "var wx: float" in game_source
assert "var spawn_pos: Vector3" in game_source
assert "var vehicle_heading: float" in player_source and "var car: Node3D" in player_source
assert "var side: Vector3" in player_source and "var world_camera_yaw: float" in player_source
assert "var start_pos: Vector3" in mission_source
print("Applied and verified Godot 4.7 strict typing fixes in game, player and mission scripts.")
