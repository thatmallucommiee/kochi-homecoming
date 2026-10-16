#!/usr/bin/env python3
"""Lightweight repository checks only; this does not replace UnrealHeaderTool or a UE build."""
import json
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
errors: list[str] = []

project_file = root / "KochiHomecomingUE5.uproject"
if not project_file.is_file():
    errors.append(f"Missing project descriptor: {project_file}")
else:
    try:
        project = json.loads(project_file.read_text(encoding="utf-8"))
        if project.get("EngineAssociation") != "5.8":
            errors.append("Project EngineAssociation must be 5.8.")
        if not any(module.get("Name") == "KochiHomecomingUE5" for module in project.get("Modules", [])):
            errors.append("Runtime module KochiHomecomingUE5 is not registered in the .uproject.")
    except (json.JSONDecodeError, OSError) as exc:
        errors.append(f"Invalid .uproject JSON: {exc}")

required = [
    "Config/DefaultEngine.ini",
    "Config/DefaultInput.ini",
    "Source/KochiHomecomingUE5.Target.cs",
    "Source/KochiHomecomingUE5Editor.Target.cs",
    "Source/KochiHomecomingUE5/KochiHomecomingUE5.Build.cs",
    "Source/KochiHomecomingUE5/KochiHomecomingUE5.cpp",
    "Source/KochiHomecomingUE5/Public/KochiHomecomingGameMode.h",
    "Source/KochiHomecomingUE5/Private/KochiHomecomingGameMode.cpp",
    "Source/KochiHomecomingUE5/Public/KochiPlayerCharacter.h",
    "Source/KochiHomecomingUE5/Private/KochiPlayerCharacter.cpp",
    "Source/KochiHomecomingUE5/Public/KochiPlayerController.h",
    "Source/KochiHomecomingUE5/Private/KochiPlayerController.cpp",
    "Source/KochiHomecomingUE5/Public/KochiMobileHUD.h",
    "Source/KochiHomecomingUE5/Private/KochiMobileHUD.cpp",
    "Source/KochiHomecomingUE5/Public/KochiCityBuilder.h",
    "Source/KochiHomecomingUE5/Private/KochiCityBuilder.cpp",
    "Source/KochiHomecomingUE5/Public/KochiVehiclePawn.h",
    "Source/KochiHomecomingUE5/Private/KochiVehiclePawn.cpp",
    "Source/KochiHomecomingUE5/Public/KochiMissionDirector.h",
    "Source/KochiHomecomingUE5/Private/KochiMissionDirector.cpp",
    "Scripts/BuildAndroid.ps1",
]
for relative in required:
    if not (root / relative).is_file():
        errors.append(f"Missing required project file: {relative}")

engine_config = (root / "Config/DefaultEngine.ini").read_text(encoding="utf-8")
input_config = (root / "Config/DefaultInput.ini").read_text(encoding="utf-8")
if "GlobalDefaultGameMode=/Script/KochiHomecomingUE5.KochiHomecomingGameMode" not in engine_config:
    errors.append("DefaultGameMode is not configured.")
if "TargetSDKVersion=35" not in engine_config:
    errors.append("Android target SDK 35 is not configured.")
if "DefaultTouchInterface=" not in engine_config:
    errors.append("Android virtual joystick is not configured.")
for name in ("MoveForward", "MoveRight", "Turn", "VehicleThrottle", "VehicleSteer"):
    if f'AxisName="{name}"' not in input_config:
        errors.append(f"Missing input axis mapping: {name}")

source_root = root / "Source/KochiHomecomingUE5"
local_headers = {p.name for p in source_root.rglob("*.h")}
for cpp in source_root.rglob("*.cpp"):
    source = cpp.read_text(encoding="utf-8")
    for header in re.findall(r'#include\s+"([^"]+\.h)"', source):
        if header.startswith(("Kochi", "Homecoming")) and header not in local_headers:
            errors.append(f"{cpp.relative_to(root)} includes missing project header {header}")

if errors:
    print("UE5 source-structure validation FAILED:")
    for error in errors:
        print(f" - {error}")
    sys.exit(1)

print("UE5 project descriptor and source-structure checks passed.")
print("This validates repository structure only; no Unreal compilation or APK packaging occurred.")