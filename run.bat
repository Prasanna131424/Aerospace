@echo off
title AeroSense Platform Launcher
cls
echo ==========================================================
echo          AeroSense Environmental Intelligence Platform
echo ==========================================================
echo.
echo [1/3] Starting FastAPI REST Backend on http://localhost:8000 ...
start "AeroSense API Server" /min cmd /k "uvicorn api.main:app --host 0.0.0.0 --port 8000"

echo [2/3] Waiting for backend services to initialize...
timeout /t 3 /nobreak >nul

echo [3/3] Automatically opening browser to http://localhost:3000 ...
start http://localhost:3000

echo.
echo ==========================================================
echo  AeroSense Web App is running at http://localhost:3000
echo  Press Ctrl+C to stop the web frontend.
echo ==========================================================
echo.

cd frontend
npm run dev
