# Transformation Plan: AeroSense Real-Time Environmental Intelligence Platform

## Executive Summary
This implementation plan outlines the exact modifications required to transition **AeroSense** from its current static/demo state into a genuine, dynamically updating Urban Air Quality Intelligence Platform. 

In strict adherence to user specifications:
- **No rebuilding from scratch**: The existing architecture (FastAPI backend, Next.js frontend, SQLite/PostgreSQL database, feature engineering, XGBoost ML pipeline, dual-method anomaly detector, SHAP explainability, risk intelligence) is preserved.
- **Zero data fabrication**: If an external API is down or unauthorized (e.g. OpenAQ missing API key), the system explicitly reports *"Data unavailable"* or *"Showing last successful observation: <timestamp>"*, never generating synthetic fake numbers or fake "Live" labels.
- **Dynamic time in `Asia/Kolkata`**: No hardcoded September 11, 2026 or fixed dates. Dates, hours, and 24-hour rolling forecasts automatically advance dynamically each day without code changes.
- **Complete Visual Redesign**: The dark blue/black futuristic AI look (neon cyan glows, excessive glassmorphism, floating cards) is replaced with a human-designed, clean environmental analytics visual language: warm neutral/off-white canvas (`#F8FAFC`), charcoal typography (`#1E293B`), forest/sage green environmental accent (`#15803D`), restrained severity colors, crisp thin borders, and an editorial data-journalism layout.

---

## User Review Required

> [!IMPORTANT]
> **OpenAQ API Key Handling (`OPENAQ_API_KEY`)**:
> OpenAQ API v3 enforces an API key (`X-API-Key` header). When `OPENAQ_API_KEY` is not provided in `.env`, the backend client will safely catch HTTP 401/403 and report `status: "api_key_required"`, displaying *"OpenAQ API Key Required — Showing last successful observation"* or *"Data unavailable"* on live cards. It will never fabricate synthetic data.
>
> Open-Meteo Weather API and Open-Meteo Air Quality Forecast API require **no API key** and provide live hourly telemetry and 48-hour forecasts for India with `Asia/Kolkata` timestamps out of the box.

---

## Proposed Changes Across Components

### 1. Ingestion & External APIs Layer (`src/ingestion/`)

#### [MODIFY] [`src/config.py`](file:///c:/Users/prasa/OneDrive/Desktop/aerospace/src/config.py)
- Change default `DATA_MODE` from `"demo"` to `"live"`.
- Add `OPEN_METEO_AQ_URL = "https://air-quality-api.open-meteo.com/v1/air-quality"`.
- Add `DEFAULT_TIMEZONE = "Asia/Kolkata"`.

#### [MODIFY] [`src/ingestion/openaq.py`](file:///c:/Users/prasa/OneDrive/Desktop/aerospace/src/ingestion/openaq.py)
- Add detailed telemetry return containing metadata: `source: "OpenAQ"`, `location_id`, `observation_timestamp`, `retrieval_timestamp`, `status`.
- Properly handle authentication errors (HTTP 401/403) and rate limits without throwing unhandled exceptions. Return explicit status dict indicating whether live data was retrieved or if the API key is required.

#### [MODIFY] [`src/ingestion/weather.py`](file:///c:/Users/prasa/OneDrive/Desktop/aerospace/src/ingestion/weather.py)
- Add `AirQualityClient` (or extend `WeatherClient`) to query Open-Meteo Air Quality API (`https://air-quality-api.open-meteo.com/v1/air-quality`):
  - Parameters: `latitude`, `longitude`, `hourly="pm2_5,pm10,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone"`, `timezone="Asia/Kolkata"`, `forecast_days=2`.
  - Current weather & hourly weather from Open-Meteo (`https://api.open-meteo.com/v1/forecast`):
  - Parameters: `latitude`, `longitude`, `current="temperature_2m,relative_humidity_2m,surface_pressure,wind_speed_10m,wind_direction_10m,precipitation"`, `hourly=...`, `timezone="Asia/Kolkata"`.
- Both functions return authoritative observation/forecast timestamps, source (`"Open-Meteo"`), units, and measurements in local `Asia/Kolkata` timezone.

#### [MODIFY] [`src/ingestion/pipeline.py`](file:///c:/Users/prasa/OneDrive/Desktop/aerospace/src/ingestion/pipeline.py)
- Remove destructive database truncation (`session.query(...).delete()`).
- Implement safe upserting by `(station_id, pollutant, timestamp)` for pollution and `(station_id, timestamp)` for weather, preventing duplicates.
- Ensure that when live data is fetched, it records `data_fetch_logs` and updates the database with genuine timestamps.

---

### 2. AeroSense ML 24-Hour Forecasting & Real-Time Intelligence (`src/models/`, `src/risk/`, `src/anomaly/`)

#### [MODIFY] [`src/models/forecasting.py`](file:///c:/Users/prasa/OneDrive/Desktop/aerospace/src/models/forecasting.py)
- Replace the legacy 5-point random perturbation (`[1, 3, 6, 12, 24]` with `np.random.normal`) with a real rolling 24-hour autoregressive forecasting pipeline:
  - Takes the station's recent observed historical PM2.5 (from DB).
  - Fetches the next 24 hourly weather forecasts (temperature, humidity, wind, pressure, cloud cover, precipitation) from Open-Meteo for that station.
  - Builds the exact 36-feature schema expected by the trained `XGBoostForecaster` (cyclical hour/month, lag 1..24, rolling 3..24, stagnation, dispersion).
  - Produces genuine predicted values and empirical 95% uncertainty intervals for $t+1, t+2, \dots, t+24$.
  - Assigns dynamic timestamps (`forecast_time = current_hour + 1h, +2h, ...`), `model_name="AeroSense XGBoost Regressor"`, `model_version="1.0.0"`, `generated_at=now`, `input_data_timestamp`.
- Persists the 24 predictions to the `predictions` table in the database.

#### [MODIFY] [`src/anomaly/detector.py`](file:///c:/Users/prasa/OneDrive/Desktop/aerospace/src/anomaly/detector.py)
- Add `detect_realtime(station_id, pollutant, value, timestamp, db)`: Runs the statistical 3-sigma and Isolation Forest logic on incoming real observations and records genuine anomalies without fabricating synthetic events.

---

### 3. Backend API Endpoints & Health Diagnostics (`api/`)

#### [MODIFY] [`api/schemas.py`](file:///c:/Users/prasa/OneDrive/Desktop/aerospace/api/schemas.py)
- Update `HealthResponse` to include comprehensive health metrics:
  - `status`: `"healthy"` | `"partially_degraded"`
  - `database_connected`: `bool`
  - `openaq_status`: `"connected"` | `"key_required"` | `"unavailable"`
  - `open_meteo_weather_status`: `"connected"` | `"unavailable"`
  - `open_meteo_aq_status`: `"connected"` | `"unavailable"`
  - `models_ready`: `bool`
  - `latest_observation_time`: `Optional[datetime]`
  - `latest_fetch_time`: `Optional[datetime]`
  - `system_time_ist`: `str`
  - `data_mode`: `str`
- Add schemas for:
  - `ExternalAQForecastItem` (Open-Meteo hourly forecast for PM2.5, PM10, NO2, O3, SO2, CO with timestamps and units).
  - `Telemetry24hResponse`: Contains:
    - `observed_last_24h`: list of actual observed measurements with timestamps.
    - `ml_forecast_next_24h`: list of AeroSense XGBoost predictions for $t+1..t+24$.
    - `external_forecast_next_24h`: list of Open-Meteo predictions for $t+1..t+24$.
    - `current_weather`: current temperature, humidity, wind, pressure, precipitation.
    - `metadata`: source tags, observation timestamps, freshness in minutes.

#### [MODIFY] [`api/main.py`](file:///c:/Users/prasa/OneDrive/Desktop/aerospace/api/main.py)
- Implement genuine diagnostic health check in `/health` verifying DB, OpenAQ API key / reachability, Open-Meteo weather reachability, and Open-Meteo AQ reachability.
- Add background periodic data refresh service (runs every 10–15 minutes) to keep telemetry fresh without spamming external APIs.

#### [MODIFY] [`api/routes/forecast.py`](file:///c:/Users/prasa/OneDrive/Desktop/aerospace/api/routes/forecast.py)
- Update `/forecast` to dynamically generate or serve the 24-hour ML forecast starting from the current hour for any requested station.
- Add `/forecast/external` to return the rolling 24-hour Open-Meteo external air quality forecast.
- Add `/forecast/24h-comparison` combining observed (last 24h) and dual forecasts (next 24h: AeroSense ML vs External).

#### [MODIFY] [`api/routes/stations.py`](file:///c:/Users/prasa/OneDrive/Desktop/aerospace/api/routes/stations.py)
- Ensure `/measurements` and `/weather` properly support time filtering (`start_time`, `end_time`) for `today`, `yesterday`, `7d`, `30d`.
- Add endpoint `/telemetry/current` returning current air quality observations, current weather, and data freshness for a selected station.

---

### 4. Frontend Visual & Information Architecture Redesign (`frontend/`)

#### [MODIFY] [`frontend/tailwind.config.js`](file:///c:/Users/prasa/OneDrive/Desktop/aerospace/frontend/tailwind.config.js) & [`frontend/src/app/globals.css`](file:///c:/Users/prasa/OneDrive/Desktop/aerospace/frontend/src/app/globals.css)
- **Aesthetic Redesign (Part 15)**:
  - Remove all neon cyan glows (`shadow-glow`, `shadow-glow-emerald`, `shadow-glow-rose`), glowing cyan borders, dark cyber backgrounds (`#080c14`), and artificial radial gradients.
  - Implement a clean, human-designed environmental analytics theme:
    - Canvas background: `#F8FAFC` (subtle off-white/warm neutral).
    - Surfaces & cards: `#FFFFFF` with fine `#E2E8F0` borders and gentle `shadow-sm`.
    - Primary typography: Charcoal/slate (`#0F172A` headings, `#334155` body, `#64748B` muted).
    - Environmental accent: Forest/sage green (`#15803D` / `#166534`).
    - Earthy secondary accents: Warm ochre/terracotta for highlights.
    - Air Quality Risk Levels: Restrained, non-fluorescent colors (`#16A34A` Low, `#D97706` Moderate, `#EA580C` High, `#DC2626` Critical).

#### [MODIFY] [`frontend/src/components/Navbar.tsx`](file:///c:/Users/prasa/OneDrive/Desktop/aerospace/frontend/src/components/Navbar.tsx)
- Redesign top header:
  - Clean brand title: **AeroSense** · *Urban Air Quality Intelligence*
  - Dynamic System Diagnostics:
    - Real-time connection status (● API Connected / ● API Partially Unavailable).
    - Source tags: `Source: OpenAQ` (or last stored), `Weather: Open-Meteo`.
    - Dynamic application timestamp in `Asia/Kolkata` (e.g. *"Saturday, 19 September 2026, 7:55 PM IST"*).
    - Data Freshness: *"Last data update: 5 mins ago"*.
  - Clean, restrained tab navigation without glowing buttons.

#### [MODIFY] [`frontend/src/app/page.tsx`](file:///c:/Users/prasa/OneDrive/Desktop/aerospace/frontend/src/app/page.tsx)
- Restructure Overview page strictly following the requested **Part 16 Information Hierarchy**:
  1. **Top Section**: AeroSense Platform Title, Current Monitored Location Selector, Dynamic Date & Time (IST), Last Data Update time.
  2. **CURRENT AIR QUALITY**: Metric blocks for PM2.5, PM10, NO2, O3, displaying:
     - Numerical value & unit (`µg/m³`).
     - Source tag (`Observed · OpenAQ` or `External Sensor`).
     - Exact observation timestamp (`Last observed: ...`).
     - Health risk badge (Low / Moderate / High / Critical).
  3. **24-HOUR AIR QUALITY DASHBOARD (Part 7 & 17)**:
     - Tabs: `[Last 24 Hours]` | `[Next 24 Hours]`.
     - `Last 24 Hours`: Displays real observed telemetry with actual hourly timestamps.
     - `Next 24 Hours`: Displays the dual forecast curves:
       - **AeroSense ML Forecast** (XGBoost 36-feature model).
       - **External Air Quality Forecast** (Open-Meteo AQ).
       - Clear legend and source indicators (Part 6).
       - Dynamic X-axis with rolling timestamps (e.g. Sep 19 8 PM $\to$ Sep 20 7 PM).
  4. **WEATHER CONDITIONS (Part 3)**:
     - Real-time temperature (°C), relative humidity (%), wind speed (km/h) & direction, atmospheric pressure (hPa), precipitation (mm), cloud cover (%).
     - Source: `Open-Meteo`.
  5. **FORECAST INSIGHT**:
     - 24-Hour pollution summary, projected peak pollution period, lowest pollution period, trend direction.
  6. **ANOMALY MONITORING**:
     - Real detected anomaly status, severity breakdown, anomaly explanation.
  7. **DATA QUALITY & FRESHNESS**:
     - Automatic refresh timer (e.g. *"Next refresh in 8m 30s"*), API connectivity health, data availability status.
  8. **HISTORICAL SELECTOR (Part 18)**:
     - Date filter: `Today`, `Yesterday`, `Last 7 Days`, `Last 30 Days`.

#### [MODIFY] [`frontend/src/components/ForecastStudio.tsx`](file:///c:/Users/prasa/OneDrive/Desktop/aerospace/frontend/src/components/ForecastStudio.tsx)
- Update to support full 24-hour horizon ($+1$ to $+24$ hours).
- Redesign visual palette to match clean environmental analytics.
- Clearly differentiate AeroSense ML forecast vs Open-Meteo external forecast with 95% confidence bounds.

#### [MODIFY] [`frontend/src/components/ModelLeaderboard.tsx`](file:///c:/Users/prasa/OneDrive/Desktop/aerospace/frontend/src/components/ModelLeaderboard.tsx)
- Label test metrics as **"Historical Evaluation"** (Part 13).
- Display genuine model metrics from `metadata.json` (MAE, RMSE, R², training/test periods, dataset size).
- Update styling to clean off-white table and cards.

#### [MODIFY] [`frontend/src/components/AnomalyRadar.tsx`](file:///c:/Users/prasa/OneDrive/Desktop/aerospace/frontend/src/components/AnomalyRadar.tsx), [`ExplainabilityLab.tsx`](file:///c:/Users/prasa/OneDrive/Desktop/aerospace/frontend/src/components/ExplainabilityLab.tsx), [`AuditReports.tsx`](file:///c:/Users/prasa/OneDrive/Desktop/aerospace/frontend/src/components/AuditReports.tsx), [`LiveSensors.tsx`](file:///c:/Users/prasa/OneDrive/Desktop/aerospace/frontend/src/components/LiveSensors.tsx)
- Update cards, tables, filters, and charts to match the new environmental design language.
- Ensure all timestamps display in `Asia/Kolkata` format.

---

## Verification Plan

### Automated Verification
1. **API Integration & Endpoint Testing**:
   ```powershell
   python -m pytest tests/ -v
   ```
2. **Backend Telemetry & Forecast Verification Script**:
   - Run a validation script testing:
     - Live Open-Meteo Weather query.
     - Live Open-Meteo Air Quality Forecast query (48h).
     - AeroSense XGBoost 24-hour prediction generation from real features.
     - Health endpoint status response.
3. **Frontend Build & Lint**:
   ```powershell
   cd frontend
   npm run build
   ```

### Manual & Interactive Verification
- Start FastAPI backend (`python -m uvicorn api.main:app --port 8000`).
- Start Next.js frontend (`npm run dev --prefix frontend`).
- Verify via browser:
  - Header shows dynamic date & time (`Asia/Kolkata`), genuine API connection status, and data freshness.
  - No hardcoded September 11, 2026 timestamps in live views; X-axis on forecast shows rolling next 24 hours.
  - [Last 24 Hours] and [Next 24 Hours] tabs correctly switch between historical observations and dual forecasts (AeroSense ML vs External).
  - Clear source attribution badges on all metrics (`Observed · OpenAQ`, `Weather · Open-Meteo`, `Forecast · AeroSense ML`, `External Forecast · Open-Meteo`).
  - Environmental analytics styling (clean off-white canvas, sage/forest green accents, crisp borders, no neon glows).
