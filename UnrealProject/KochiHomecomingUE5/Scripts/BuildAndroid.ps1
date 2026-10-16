[CmdletBinding()]
param(
    [string]$EngineRoot = $env:UE_ROOT,
    [string]$ProjectPath = (Join-Path $PSScriptRoot "..\KochiHomecomingUE5.uproject"),
    [string]$OutputPath = (Join-Path $PSScriptRoot "..\Builds\Android")
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($EngineRoot)) {
    throw "Set UE_ROOT to a local Unreal Engine 5.8 installation, or pass -EngineRoot."
}

$EngineRoot = (Resolve-Path $EngineRoot).Path
$ProjectPath = (Resolve-Path $ProjectPath).Path
$RunUAT = Join-Path $EngineRoot "Engine\Build\BatchFiles\RunUAT.bat"

if (!(Test-Path $RunUAT)) {
    throw "RunUAT.bat was not found under $EngineRoot. This must be an installed Unreal Engine folder."
}

New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null
$OutputPath = (Resolve-Path $OutputPath).Path

Write-Host "Packaging project: $ProjectPath"
Write-Host "Using engine:      $EngineRoot"
Write-Host "Output directory:  $OutputPath"
Write-Host "Target: Android arm64 / ETC2 / Development"

& $RunUAT BuildCookRun "-project=$ProjectPath" -noP4 -platform=Android -clientconfig=Development -target=KochiHomecomingUE5 -cook -build -stage -pak -archive "-archivedirectory=$OutputPath" -package -cookflavor=ETC2 -utf8output -unattended

if ($LASTEXITCODE -ne 0) {
    throw "Unreal BuildCookRun failed with exit code $LASTEXITCODE. Read the UAT log above."
}

$Apk = Get-ChildItem -Path $OutputPath -Filter "*.apk" -Recurse | Select-Object -First 1
if (!$Apk) {
    throw "BuildCookRun returned success but no APK was found beneath $OutputPath."
}

$FinalApk = Join-Path $OutputPath "KochiHomecomingUE5-Android-Development.apk"
if ($Apk.FullName -ne $FinalApk) {
    Copy-Item -LiteralPath $Apk.FullName -Destination $FinalApk -Force
}

$Hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $FinalApk).Hash
Write-Host "APK_READY=$FinalApk"
Write-Host "APK_SHA256=$Hash"
Write-Host "APK_BYTES=$((Get-Item -LiteralPath $FinalApk).Length)"