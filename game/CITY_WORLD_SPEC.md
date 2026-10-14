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
- 38 visible moving vehicles: 18 cars, 9 auto-rickshaws, 3 buses and 8 motorcycles/scooters, following the road grid.
- 32 simple walking NPCs with procedural limb swing, plus Rafi, tea-stall customers, street-side citizens and 8 additional neighbours distributed across separate blocks.
- 16 parked cars and 18 parked scooters/motorcycles distributed across the district, with basic collision so the player cannot walk through them.
- Mission proximity triggers for entering/leaving the family home, inspecting the photo, speaking with Rafi and examining the crash scene.
- A live world-aligned minimap with road-grid rendering, player heading, mission destination markers and a direction line to the current objective.
- Parked roadside cars and scooters, a visible Rafi character outside his garage, tea-stall customers and static street-side citizens.
- Procedural sky, ambient light and fog if the starter scene does not already contain them.
- Basic collision boxes around buildings so the player cannot simply walk through every structure.

## Living-city density pass (2026-10-14)

The current procedural pass has been expanded beyond the first traffic-light prototype: more moving vehicles, pedestrians spread across more of the grid, and curbside parking distributed into residential and commercial blocks. This improves the sense of an inhabited city without runtime downloads or paid assets. The vehicles and people are still simplified procedural meshes, and their behaviour is ambient scenery rather than full simulation.

## Mobile performance choices

- Static city pieces are batched into `MultiMeshInstance3D` groups by shape and material.
- Static geometry does not cast dynamic shadows in this first pass.
- Traffic and pedestrians remain separate nodes because they move. The current density pass increases the number of dynamic meshes; frame rate and heat must be measured on the target Poco X7 5G before further increases.
- No network calls or runtime downloads are required.
- Repeating SVG surface textures for asphalt, plaster, concrete, red-oxide flooring, roof tiles, glass and wood are applied through a world-space triplanar shader. These are procedural surface textures, not scanned photography or a full PBR set with normal/roughness maps.
- Geometry is an intentionally lightweight foundation. Traffic is visual lane-loop motion, not collision-aware traffic AI; pedestrians follow sidewalk loops, not navigation/pathfinding. The traffic vehicles are scenery and are not yet drivable by Vivek.
- The family-house interior is a compact story set, not a fully furnished walkable building-interior system for all the city structures. Most other buildings are exterior shells.
- The minimap reflects this procedural district's grid; it is not yet a GPS-accurate map of actual Kochi streets.

## Next improvements, in order

1. Build and install the APK; test orientation, player collision, camera scale and FPS on the Poco X7 5G.
2. Correct any scene overlap or start-position mismatch revealed by that test.
3. Test all story triggers and home entry/exit in the exported APK; fix scene overlap and player spawn mismatches.
4. Replace selected hero assets with rigged character models and improved building/vehicle materials.
5. Add collision-aware traffic, richer pedestrian routes and zone-based activation/culling, then measure FPS on the Poco X7 5G.
6. Add functional driving, navigation/map, day/night and weather settings after the basic scene is stable.

## Story constraints

Vivek returns to Kochi after Abraham's death. The accident initially appears to be a road accident. Rafi knows only part of Abraham's past. The possible cut brake line is not confirmed in the opening. No weapons or wanted level are given to Vivek at the start.

The city uses broad Kochi/Kerala-inspired visual references; it is not claimed to be a survey-accurate 1:1 geographic model.
