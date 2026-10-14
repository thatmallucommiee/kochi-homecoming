# Kochi: Homecoming — Living District Pass

This file tracks the first procedural city pass. It is a runtime-generated 3D district installed into the current Godot main scene through the `CityWorld` autoload.

## City features in this pass

- Nine-by-nine connected road grid with asphalt, broken lane marks, double center lines, zebra crossings, sidewalks and drainage.
- Roughly 300–400 street-front building shells plus inner-lot homes/workshops, with the final count determined by the procedural lot layout. Building types vary between one-storey Kerala homes, mixed-use shops and taller apartment/commercial blocks.
- Facade detail: windows and frames, shopfront shutters, awnings, colored signboards, some balconies, AC units, rooftop tanks/antennas and a few tiled-roof houses.
- Roadside palms and broad-leaf trees, utility poles, overhead wires, lamps, patched asphalt and puddles.
- A simple bus shelter, street-side clutter, a central junction signal, a tea stall and a reserved plot for Rafi's Auto Works.
- Moving low-poly traffic and simple walking NPCs with procedural limb swing.
- Procedural sky, ambient light and fog if the starter scene does not already contain them.
- Basic collision boxes around buildings so the player cannot simply walk through every structure.

## Mobile performance choices

- Static city pieces are batched into `MultiMeshInstance3D` groups by shape and material.
- Static geometry does not cast dynamic shadows in this first pass.
- Traffic and pedestrians remain separate nodes because they move.
- No network calls or runtime downloads are required.
- Geometry is an intentionally lightweight foundation; this pass does not yet supply production-quality PBR texture maps, final rigged characters, detailed interiors, traffic AI, pathfinding, or realistic vehicle physics.

## Next improvements, in order

1. Build and install the APK; test orientation, player collision, camera scale and FPS on the Poco X7 5G.
2. Correct any scene overlap or start-position mismatch revealed by that test.
3. Replace selected hero assets with rigged character models and improved building/vehicle materials.
4. Make Rafi's garage, the house and accident-site objects actual mission interaction targets.
5. Add zone-based activation/culling for traffic and walkers as the city expands.
6. Add functional driving, navigation/map, day/night and weather settings after the basic scene is stable.

## Story constraints

Vivek returns to Kochi after Abraham's death. The accident initially appears to be a road accident. Rafi knows only part of Abraham's past. The possible cut brake line is not confirmed in the opening. No weapons or wanted level are given to Vivek at the start.

The city uses broad Kochi/Kerala-inspired visual references; it is not claimed to be a survey-accurate 1:1 geographic model.
