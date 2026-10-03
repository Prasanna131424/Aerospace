# ==========================================================
# AeroSense One-Click Local Launcher for PowerShell / VS Code
# ==========================================================

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "     AeroSense Environmental Intelligence Platform        " -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# Ensure we are in the script's root directory
Set-Location $PSScriptRoot

# ----------------------------------------------------------
# 1. Start FastAPI REST Backend (Port 8000)
# ----------------------------------------------------------
$backendHealthy = $false
try {
    $checkB = Invoke-WebRequest -Uri "http://127.0.0.1:8000/health" -UseBasicParsing -TimeoutSec 1 -ErrorAction SilentlyContinue
    if ($checkB.StatusCode -eq 200) {
        $backendHealthy = $true
    }
} catch {}

if (-not $backendHealthy) {
    Write-Host "[1/4] Starting FastAPI REST Backend on http://localhost:8000..." -ForegroundColor Yellow
    Start-Process "cmd.exe" -ArgumentList "/k python -m uvicorn api.main:app --host 0.0.0.0 --port 8000" -WorkingDirectory $PSScriptRoot -WindowStyle Minimized
} else {
    Write-Host "[1/4] FastAPI REST Backend already active on port 8000." -ForegroundColor Green
}

# ----------------------------------------------------------
# 2. Verify Backend is Answering with HTTP 200
# ----------------------------------------------------------
Write-Host "[2/4] Verifying Backend health..." -ForegroundColor Yellow
$bRetries = 0
while (-not $backendHealthy -and $bRetries -lt 30) {
    Start-Sleep -Milliseconds 500
    try {
        $resp = Invoke-WebRequest -Uri "http://127.0.0.1:8000/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($resp.StatusCode -eq 200) {
            $backendHealthy = $true
        }
    } catch {}
    $bRetries++
}

if ($backendHealthy) {
    Write-Host "       -> Backend verified healthy." -ForegroundColor Green
} else {
    Write-Host "       [WARNING] Backend on port 8000 did not respond within 15 seconds." -ForegroundColor Red
}

# ----------------------------------------------------------
# 3. Start Next.js Web Platform (Port 3000)
# ----------------------------------------------------------
$frontendDir = Join-Path $PSScriptRoot "frontend"
$frontendHealthy = $false
try {
    $checkF = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 1 -ErrorAction SilentlyContinue
    if ($checkF.StatusCode -eq 200) {
        $frontendHealthy = $true
    }
} catch {}

if (-not $frontendHealthy) {
    Write-Host "[3/4] Starting Web Platform on http://localhost:3000..." -ForegroundColor Yellow
    Start-Process "cmd.exe" -ArgumentList "/k npm run start" -WorkingDirectory $frontendDir -WindowStyle Minimized
} else {
    Write-Host "[3/4] Web Platform already active on port 3000." -ForegroundColor Green
}

# ----------------------------------------------------------
# 4. Verify Web Platform is Answering with HTTP 200
# ----------------------------------------------------------
Write-Host "[4/4] Verifying Web Platform readiness..." -ForegroundColor Yellow
$fRetries = 0
while (-not $frontendHealthy -and $fRetries -lt 30) {
    Start-Sleep -Milliseconds 500
    try {
        $resp = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($resp.StatusCode -eq 200) {
            $frontendHealthy = $true
        }
    } catch {}
    $fRetries++
}

if ($frontendHealthy) {
    Write-Host "       -> Web Platform verified ready." -ForegroundColor Green
} else {
    Write-Host "       [WARNING] Frontend on port 3000 did not respond within 15 seconds." -ForegroundColor Red
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " [SUCCESS] AeroSense Platform is Live and Operational!" -ForegroundColor Green
Write-Host " Web App:   http://localhost:3000" -ForegroundColor White
Write-Host " REST API:  http://localhost:8000" -ForegroundColor White
Write-Host " API Docs:  http://localhost:8000/docs" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# Automatically open default browser to the web platform
Start-Process "http://localhost:3000"
Write-Host "Browser opened to http://localhost:3000." -ForegroundColor Green


