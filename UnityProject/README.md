# Kochi: Homecoming — Unity Rebuild

This directory is a separate Unity implementation. It does not replace or modify the existing Godot prototype.

## Target
- Unity 6 LTS-compatible project structure; confirm exact installed editor version before opening.
- Android first, landscape orientation, touch controls, optimized for mid-range devices such as Poco X7 5G.
- Cinematic third-person open-world crime game set in a fictionalized Kochi.

## Canon guardrails
- Vivek, 25, returns to Kochi in 2026 after his father Abraham's death.
- Abraham's death appears to be a road accident; a deliberately cut brake line is suspected, not confirmed.
- Rafi, 32, is a mechanic and fixer who knows part of Abraham's criminal world.
- Do not reveal the central mystery early, invent a confirmed conspiracy, or give Vivek a weapon/wanted level at the opening.
- Preserve established story facts; do not invent missions or plot twists without direction.

## First vertical slice (in order)
1. Third-person character, camera-relative movement, correct collision, camera orbit.
2. Touch joystick and camera drag; controls must not overlap.
3. One detailed, small Kochi-inspired street block with real authored/ sourced assets—not primitive-block city dressing.
4. One parked vehicle with enter/exit and functional driving.
5. One interaction and dialogue trigger.
6. First story beat and save/checkpoint.
7. Android profiling and APK build/test on device.

## Asset honesty
No GTA V assets, ripped models, or copyrighted Rockstar content. Use properly licensed assets and original assets. Do not claim a feature, APK, performance target, or device test is complete until actually built and verified.

## Open in Unity
Create/open a Unity project at this folder using the installed Unity Editor, then set Android Build Support, Android SDK/NDK tools, and OpenJDK through Unity Hub. The repository currently contains source scaffolding, not a compiled APK or complete Unity-generated project metadata.
