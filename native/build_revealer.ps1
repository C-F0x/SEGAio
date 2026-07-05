<#
.SYNOPSIS
    Build the native revealer.dll (Rust cdylib) for SEGAio.
.DESCRIPTION
    Compiles the Rust project in native/ and copies the resulting
    revealer.dll to the SEGAio project root so that Flutter/Dart's
    FFI can load it at runtime.
.NOTES
    Run from the native/ directory or pass -ProjectRoot.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = (Resolve-Path "$PSScriptRoot\.."),
    [Parameter(Mandatory = $false)]
    [switch]$BuildDebug
)

$ErrorActionPreference = "Stop"

$buildProfile = if ($BuildDebug) { "debug" } else { "release" }
$cargoProfile  = if ($BuildDebug) { "" } else { "--release" }

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ">>> Build revealer.dll for SEGAio" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# ═══════════════════════════════════════════════════════════════════
# Stage 1: Check Rust toolchain
# ═══════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host ">>> Stage 1: Checking Rust toolchain..." -ForegroundColor Cyan

$rustcOk = $false
try {
    $v = & rustc --version 2>$null
    if ($LASTEXITCODE -eq 0) { $rustcOk = $true; Write-Host "    rustc  ✓  $v" -ForegroundColor Green }
} catch {}

if (-not $rustcOk) {
    Write-Host "    rustc  ✖  NOT FOUND" -ForegroundColor Red
    Write-Host ""
    Write-Host ">>> ERROR: Rust toolchain is required." -ForegroundColor Red
    Write-Host "    Install from: https://rustup.rs" -ForegroundColor Red
    Write-Host "    Then run this script again.`n" -ForegroundColor Red
    exit 1
}

try {
    $v = & cargo --version 2>$null
    if ($LASTEXITCODE -eq 0) { Write-Host "    cargo  ✓  $v" -ForegroundColor Green }
} catch {
    Write-Host "    cargo  ✖  NOT FOUND" -ForegroundColor Red
    exit 1
}

# ═══════════════════════════════════════════════════════════════════
# Stage 2: Build
# ═══════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host ">>> Stage 2: Building revealer.dll ($buildProfile)..." -ForegroundColor Cyan

Push-Location $PSScriptRoot

& cargo build $cargoProfile
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host ">>> ERROR: Build failed. See errors above." -ForegroundColor Red
    Pop-Location
    exit $LASTEXITCODE
}

Pop-Location

# ═══════════════════════════════════════════════════════════════════
# Stage 3: Deploy DLL to project root
# ═══════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host ">>> Stage 3: Deploying revealer.dll..." -ForegroundColor Cyan

$srcDll = Join-Path $PSScriptRoot "target\$buildProfile\revealer.dll"
$dstDll = Join-Path $ProjectRoot "revealer.dll"

if (-not (Test-Path $srcDll)) {
    Write-Host ""
    Write-Host ">>> ERROR: Built DLL not found at:" -ForegroundColor Red
    Write-Host "    $srcDll" -ForegroundColor Red
    Write-Host "    Something went wrong during compilation." -ForegroundColor Red
    exit 1
}

Copy-Item -Path $srcDll -Destination $dstDll -Force

$sizeKB = [math]::Round((Get-Item $srcDll).Length / 1KB, 1)
Write-Host "    Copied: revealer.dll → $ProjectRoot\  ($sizeKB KB)" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════════
# Done
# ═══════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ">>> Done: revealer.dll built and deployed successfully." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
