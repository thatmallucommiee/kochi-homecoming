# Runtime-built world and asset inventory

The initial UE5 vertical slice creates its district, visible story waypoint, home interior, garage, tea stall and vehicles from native C++ at runtime. The world uses Unreal Engine basic cube, sphere, cylinder and basic-shape material assets; these are placeholders, not production art.

See [ASSET_MANIFEST.json](../ASSET_MANIFEST.json) for a machine-readable inventory of what exists, what is still missing, and the current build gates.

## Known production gaps

- Vivek and Rafi need authored rigged skeletal meshes and proper animation blueprints / animation assets. Vivek's current procedural limb swing is only a placeholder.
- The vehicle is a primitive physics blockout without a production wheel/suspension setup or authored vehicle mesh.
- The city is a generated blockout, not a surveyed Kochi map or finished environment. Authored Kerala architecture, realistic vegetation, terrain, water and detailed roadside props are missing.
- Ambient audio, vehicle sounds, dialogue/cutscenes, traffic, pedestrians, save/load and tested mobile performance are not complete.
- The world is spawned by C++ at runtime; no authored gameplay map (.umap) is bundled yet.

## Verification gates

The GitHub source-validation job checks repository structure and known integration regressions only. It does **not** run UnrealHeaderTool, compile the C++ module, launch the editor, cook content, package an APK or test the game on a phone. The Android package workflow requires a licensed Unreal Engine 5.8 installation and configured Android SDK/NDK/JDK on a self-hosted Windows runner.

Do not mark the project or APK as verified until a real Unreal build and packaging run succeeds. Device testing remains a separate step.
