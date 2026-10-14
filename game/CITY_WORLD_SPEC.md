# Kochi: Homecoming — Living District Pass

This file tracks the current procedural city pass. It is a runtime-generated 3D district installed into the current Godot main scene through the `CityWorld` autoload.

## City features in this pass

- Nine-by-nine connected road grid with asphalt, broken lane marks, double center lines, zebra crossings, sidewalks and drainage.
- Roughly 300–400 street-front building shells plus inner-lot homes/workshops, with the final count determined by the procedural lot layout. Building types vary between one-storey Kerala homes, mixed-use shops and taller apartment/commercial blocks.
- Facade detail: windows and frames, shopfront shutters, awnings, colored signboards, some balconies, AC units, rooftop tanks/antennas and a few tiled-roof houses.
- Roadside palms and broad-leaf trees, utility poles, overhead wires, lamps, patched asphalt and puddles.
- A bus shelter, street-side clutter, a central junction signal, a tea stall, Rafi's Auto Works and a reserved family-home lot.
- A furnished, enterable family-house interior with a red-oxide floor, sofa, table, CRT television and an inspectable photograph.
- A roadside crash scene with a damaged car, skid marks and glass fragments; it does not confirm sabotage.
- Around 28 visible moving vehicles (cars, auto-rickshaws, a bus and motorcycles) and 24 simple walking NPCs with procedural limb swing.
- Mission proximity triggers for entering/leaving the family home, inspecting the photo, speaking with Rafi and examining the crash scene.
- Procedural sky, ambient light and fog if the starter scene does not already contain them.
- Basic collision boxes around buildings so the player cannot simply walk through every structure.

## Mobile performance choices

- Static city pieces are batched into `MultiMeshInstance3D` groups by shape and material.
- Static geometry does not cast dynamic shadows in this first pass.
- Traffic and pedestrians remain separate nodes because they move.
- No network calls or runtime downloads are required.
- Repeating SVG surface textures for asphalt, plaster, concrete, red-oxide flooring, roof tiles, glass and wood are applied through a world-space triplanar shader. These are procedural surface textures, not scanned photography or a full PBR set with normal/roughness maps.
- Geometry is an intentionally lightweight foundation. Traffic is visual lane-loop motion, not collision-aware traffic AI; pedestrians follow sidewalk loops, not navigation/pathfinding. The traffic vehicles are scenery and are not yet drivable by Vivek.
- The family-house interior is a compact story set, not a fully furnished walkable building-interior system for all the city structures. Most other buildings are exterior shells.

## Next improvements, in order

1. Build and install the APK; test orientation, player collision, camera scale and FPS on the Poco X7 5G.
2. Correct any scene overlap or start-position mismatch revealed by that test.
3. Test all story triggers and home entry/exit in the exported APK; fix scene overlap and player spawn mismatches.
4. Replace selected hero assets with rigged character models and improved building/vehicle materials.
5. Add collision-aware traffic, richer pedestrian routes and zone-based activation/culling.
6. Add functional driving, navigation/map, day/night and weather settings after the basic scene is stable.

## Story constraints

Vivek returns to Kochi after Abraham's death. The accident initially appears to be a road accident. Rafi knows only part of Abraham's past. The possible cut brake line is not confirmed in the opening. No weapons or wanted level are given to Vivek at the start.

The city uses broad Kochi/Kerala-inspired visual references; it is not claimed to be a survey-accurate 1:1 geographic model.
