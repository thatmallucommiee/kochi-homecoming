# Kochi: Homecoming — Separate Unity Project

This is the new Unity implementation on the `unity-rebuild` branch. It does **not** replace or modify the existing Godot prototype.

## Project target

- **Editor:** Unity 6.3 LTS, pinned to `6000.3.26f1`.
- **Platform:** Android first, landscape orientation, ARM64 APK.
- **Package ID:** `com.aswinmohan.kochihomecoming`.
- **Touch controls:** left movement joystick, right-side camera drag, run, interact and vehicle buttons.
- **Build method:** `KochiHomecoming.Editor.UnityAndroidBuild.Build`.

## Current opening vertical slice

The project can generate an opening Kochi-inspired street scene from `Assets/Editor/HomecomingSceneSetup.cs`. It includes a third-person player controller, follow/orbit camera, mobile HUD, initial return-home objective, interactable gate, a parked vehicle with enter/exit and basic driving, roads, shopfronts, vegetation and street furniture.

**Asset status:** this is a *procedural prototype scene*, with hand-built primitive meshes and generated materials. It is not yet the intended realistic final art pass, does not contain production character animations or licensed high-detail city/vehicle assets, and has not been performance-tested on a phone. The gameplay systems and art should be developed and verified in stages rather than labelling the prototype GTA-quality.

## Story guardrails

- Vivek, 25, returns to Kochi in 2026 after the death of his father Abraham.
- Abraham's death appears to be a road accident; a deliberately cut brake line is suspected, not confirmed.
- Rafi, 32, is a mechanic and fixer who knows part of Abraham's criminal world.
- Do not reveal the central mystery early, invent a confirmed conspiracy, or give Vivek a weapon/wanted level at the opening.
- Preserve the already established story. The demo's tutorial objective is scaffolding, not a new canon plot reveal.

## Generate the scene in Unity

Open `UnityProject` with **Unity 6.3 LTS (6000.3.26f1)** and Android Build Support installed. From the Unity menu, choose **Kochi Homecoming → Generate Opening Street**. This creates `Assets/Scenes/Homecoming.unity` and the generated materials, then configures the scene for Android.

## Export an APK

The project contains an Editor build method at `Assets/Editor/UnityAndroidBuild.cs`. It can be invoked using Unity batch mode:

```text
Unity -batchmode -quit -projectPath <path-to-UnityProject> -executeMethod KochiHomecoming.Editor.UnityAndroidBuild.Build -logFile -
```

Install Android Build Support, SDK, NDK and OpenJDK through Unity Hub before building locally.

The GitHub Actions workflow `.github/workflows/unity-android-apk.yml` builds an APK and uploads it as a downloadable workflow artifact. It requires the Unity license file as the repository Actions secret `UNITY_LICENSE`; without that secret, the build stops at its preflight check.

For a Unity Personal license, the separate **Request Unity Personal Activation File** workflow is provided at `.github/workflows/unity-activation.yml`. Run it from GitHub Actions, download its `.alf` artifact, complete the license activation process with Unity, then add the resulting `.ulf` file contents as the repository Actions secret `UNITY_LICENSE`. GameCI documents this manual activation process [here](https://game.ci/docs/3/github/activation/). After that one-time setup, the APK workflow can run automatically on Unity project changes or be started manually. The APK appears under that run's **Artifacts** section, only after a successful build.

## Current verification status

Source scaffolding and a procedural scene/build pipeline are committed, but the Unity Editor and Android SDK/NDK are not installed in the assistant's execution environment. Therefore, no APK has been compiled, installed, or device-tested here yet. Do not treat a successful source commit as proof of a working build.
