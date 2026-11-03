# Nexus AI — Windows Desktop Build Script
#
# This script adds the project-local tools/ directory (which contains nuget.exe)
# to PATH so that CMake's find_program(NUGET_EXE NAMES nuget) can discover it
# during the flutter_tts Windows plugin build. It then runs a clean Flutter
# Windows release build.
#
# Prerequisites (must already be installed on the machine):
#   - Flutter SDK (in PATH)
#   - Visual Studio with C++ desktop workload (cl.exe, MSBuild, CMake)
#   - Windows 10 SDK
#
# Usage (from the frontend/ directory):
#   .\build_windows.ps1
#
# The local nuget.exe is at frontend/tools/nuget.exe (committed to the repo).
# The NuGet.Config at frontend/NuGet.Config uses %USERPROFILE%\.nuget\packages
# as the local package cache source (portable across Windows machines) and does
# not disable nuget.org, so missing packages can be restored from the network.

$ErrorActionPreference = "Stop"

# Resolve the directory containing this script so paths are project-relative.
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$toolsDir = Join-Path $scriptDir "tools"
$nugetExe = Join-Path $toolsDir "nuget.exe"

if (!(Test-Path $nugetExe)) {
    Write-Error "nuget.exe not found at $nugetExe. Ensure frontend/tools/nuget.exe is present."
    exit 1
}

# Make the project-local nuget.exe discoverable to CMake's find_program.
$env:PATH = "$toolsDir;$env:PATH"

Write-Host "Using nuget.exe at: $nugetExe" -ForegroundColor Cyan

Write-Host "Running flutter pub get..." -ForegroundColor Cyan
flutter pub get

Write-Host "Building Windows release..." -ForegroundColor Cyan
flutter build windows --release

$exePath = Join-Path $scriptDir "build\windows\x64\runner\Release\nexus_ai.exe"
if (Test-Path $exePath) {
    Write-Host "BUILD SUCCEEDED: $exePath" -ForegroundColor Green
} else {
    Write-Error "Build did not produce $exePath"
    exit 1
}
