# Build Qurany APK using D: drive for Gradle/temp (avoids full C: disk).
# Usage: .\build_on_d.ps1
# Optional: .\build_on_d.ps1 -ApiBase "http://192.168.1.110:8000"

param(
    [string]$ApiBase = "http://192.168.1.110:8000"
)

$ErrorActionPreference = "Stop"

$buildRoot = "D:\QuranyBuild"
$gradleHome = Join-Path $buildRoot "gradle-cache"
$tempDir = Join-Path $buildRoot "temp"
$apkOut = Join-Path $buildRoot "apk"

New-Item -ItemType Directory -Force -Path $gradleHome, $tempDir, $apkOut | Out-Null

$env:GRADLE_USER_HOME = $gradleHome
$env:TEMP = $tempDir
$env:TMP = $tempDir

Set-Location $PSScriptRoot

Write-Host "Building with API base: $ApiBase"
Write-Host "Gradle cache: $gradleHome"

flutter build apk --release `
    --target-platform android-arm64 `
    --dart-define=QURANY_API_BASE=$ApiBase

$built = Join-Path $PSScriptRoot "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $built)) {
    throw "Build finished but APK not found at $built"
}

$dest = Join-Path $apkOut "qurany-release-arm64.apk"
Copy-Item $built $dest -Force
Write-Host ""
Write-Host "APK ready:" -ForegroundColor Green
Write-Host "  $dest"
