# Kochi: Homecoming — UE 5.8 Android rebuild

This is a separate native Unreal Engine 5 C++ project. It does not rename the earlier Godot prototype or depend on its runtime. The initial vertical slice is self-contained and builds its blockout world from engine primitive meshes at runtime.

## What's in this first UE5 slice

- Third-person character controller with camera-relative movement, sprint and a follow camera.
- Android virtual sticks plus separate RUN, INTERACT and contextual DRIVE / EXIT CAR touch buttons.
- A seeded, instanced Kerala-town blockout with asphalt roads, lane markings, sidewalks, mixed-height buildings, trees, a tea stall and labeled garage.
- A cutaway family living room, inspectable photograph target, visible animated objective marker, Rafi interaction and roadside wreck objective.
- A physics-driven starter car with enter/exit, follow camera, throttle, steering and speed limiting.
- Story beats stay within the existing opening: Vivek returns to Kochi after Abraham's death; the home, Rafi and crash site establish the opening without giving Vivek weapons or a wanted level.

## Open the project

Install Unreal Engine 5.8 with Android platform support, open KochiHomecomingUE5.uproject, allow the IDE project files to be generated, compile the Development Editor target, then run the project. The world is spawned by KochiHomecomingGameMode, so this initial source-only project does not yet include a hand-authored .umap.

## Build an Android APK

Epic's Android workflow requires the Unreal Engine Android toolchain (SDK, NDK and JDK) to be configured for the installed engine. The current UE 5.8 documentation recommends target SDK 35 and NDK r27c; run the engine's Turnkey Android SDK setup if these are not installed.

On a Windows build machine with UE 5.8 and Android packaging configured, run:

    powershell -ExecutionPolicy Bypass -File .\Scripts\BuildAndroid.ps1 -EngineRoot "C:\Program Files\Epic Games\UE_5.8"

The script runs Unreal Automation Tool (BuildCookRun) for Android arm64 / ETC2 and fails loudly if Unreal returns an error or no APK is produced. It reports the final APK path and SHA-256 hash.

## Automated jobs

- ue5-source-validation.yml runs project descriptor and source-reference checks on GitHub-hosted runners. It does not compile C++.
- ue5-android-package.yml is manual and expects a Windows self-hosted runner with labels ue5-8 and android-sdk, plus UE_ROOT set to an installed Unreal Engine 5.8 folder. A GitHub-hosted runner cannot package this project unless Unreal Engine and its Android toolchain are actually available.

## Honest current status

This commit is source scaffolding and a playable-prototype implementation attempt, not a verified binary. This chat environment has repository access but no installed Unreal Engine 5.8 editor / UnrealBuildTool / Android packaging toolchain, so an APK cannot be truthfully claimed until the UE build runs on a machine with those components. A production GTA-scale result also requires authored assets and animation rigs; the included meshes are an asset-free blockout foundation.