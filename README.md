# AeroSense 🌪️
### Explainable Urban Air Quality Forecasting, Pollution Anomaly Detection & Risk Intelligence Platform

> **Understand. Predict. Detect. Explain.**  
> *A Production-Style Major Project in Environmental Data Science, Real-Time Telemetry & Explainable Machine Learning.*

[![Python](https://img.shields.io/badge/Python-3.11%20%7C%203.12%20%7C%203.13-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-1.0.0-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Next.js](https://img.shields.io/badge/Next.js-14.2-black?logo=next.js&logoColor=white)](https://nextjs.org/)
[![Streamlit](https://img.shields.io/badge/Streamlit-1.38-FF4B4B?logo=streamlit&logoColor=white)](https://streamlit.io/)
[![XGBoost](https://img.shields.io/badge/XGBoost-Forecasting-EB4034)](https://xgboost.readthedocs.io/)
[![SHAP](https://img.shields.io/badge/SHAP-Game%20Theoretic%20XAI-blue)](https://shap.readthedocs.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 📌 1. Project Overview

**AeroSense** is an enterprise-grade environmental intelligence platform engineered to bridge the gap between raw air quality sensor telemetry and actionable public decision support. Rather than treating air quality monitoring as a naive static script, AeroSense implements an authentic, production-grade data science lifecycle:

```text
Environmental Telemetry → Data Engineering → Quality Auditing → Preprocessing →
EDA & Statistical Modeling → Feature Engineering → Multi-Model Forecasting →
Dual Anomaly Detection → Risk Intelligence → Explainable AI (SHAP) →
FastAPI REST Services → Next.js Web Platform / Streamlit Dashboard → Dynamic Reports
```

AeroSense combines multi-pollutant telemetry ($\text{PM}_{2.5}, \text{PM}_{10}, \text{NO}_2, \text{SO}_2, \text{CO}, \text{O}_3$) from **OpenAQ** with synchronized meteorological covariates (temperature, relative humidity, wind speed, wind direction, surface pressure, precipitation, cloud cover) from **Open-Meteo**.

---

## 🏛️ 2. Core Architectural Principles

* **Data Science First**: Grounded in atmospheric boundary layer dynamics, thermal inversion coupling, feature engineering, and time-series statistical modeling.
* **Zero Fabricated Results**: Every metric ($\text{MAE}, \text{RMSE}, \text{MAPE}, R^2$) and SHAP value is computed directly from chronological out-of-time test splits on real atmospheric data.
* **Chronological Time-Series Integrity**: Strict temporal partitioning ($70\%$ Train, $15\%$ Validation, $15\%$ Out-of-Time Test) prevents look-ahead data leakage.
* **Leak-Free Feature Pipelines**: All 36 lag and rolling statistics are calculated strictly on preceding observations ($t-1$ closed intervals).
* **Explainability $\neq$ Causality**: SHAP values quantify internal model feature attribution; they explicitly disclaim real-world physical etiology.
* **Resilient Dual Storage & Fallback**: Native support for **PostgreSQL** in production/Docker, with zero-friction automatic fallback to local **SQLite** (`data/aerosense.db`).
* **Dual Ingestion Modes**: Live OpenAQ/Open-Meteo connectors paired with calibrated multi-station urban benchmark datasets (`DATA_MODE=demo`) clearly labeled for defense evaluations and offline demonstrations.

---

## 🏗️ 3. System Architecture

```text
                     ┌────────────────────────┐
                     │     Air Quality API    │
                     │  OpenAQ v3 Telemetry   │
                     └───────────┬────────────┘
                                 │
                                 ▼
                     ┌────────────────────────┐
                     │     Weather API        │
                     │  Open-Meteo Covariates │
                     └───────────┬────────────┘
                                 │
                                 ▼
                     ┌────────────────────────┐
                     │   Data Ingestion       │
                     │  IngestionPipeline     │
                     └───────────┬────────────┘
                                 │
                                 ▼
                     ┌────────────────────────┐
                     │ PostgreSQL / SQLite DB │
                     │  Parquet Data Lake     │
                     └───────────┬────────────┘
                                 │
                                 ▼
                     ┌────────────────────────┐
                     │ Data Quality Auditing  │
                     │ Missing, Dups, Outliers│
                     └───────────┬────────────┘
                                 │
                                 ▼
                     ┌────────────────────────┐
                     │ Feature Engineering    │
                     │ 36 Leak-Free Lags/Roll │
                     └───────────┬────────────┘
                                 │
                   ┌─────────────┴─────────────┐
                   ▼                           ▼
        ┌──────────────────────┐    ┌──────────────────────┐
        │ Forecasting Engine   │    │ Anomaly Detection    │
        │ Baseline Persistence │    │ Rolling 3-Sigma Band │
        │ Ridge Linear Reg     │    │ Isolation Forest     │
        │ Random Forest        │    │ Normal/Unusual/Severe│
        │ XGBoost Regressor    │    └──────────┬───────────┘
        │ SARIMA (1,1,1)x(1,0,1│               │
        └──────────┬───────────┘               │
                   │                           │
                   └─────────────┬─────────────┘
                                 ▼
                     ┌────────────────────────┐
                     │ Explainable AI (XAI)   │
                     │ TreeExplainer SHAP     │
                     └───────────┬────────────┘
                                 │
                                 ▼
                     ┌────────────────────────┐
                     │ Risk Intelligence      │
                     │ 4-Tier Analytical AQI  │
                     └───────────┬────────────┘
                                 │
                                 ▼
                     ┌────────────────────────┐
                     │ FastAPI REST Backend   │
                     │ Port 8000 (/docs)      │
                     └─────┬────────────┬─────┘
                           │            │
                           ▼            ▼
             ┌──────────────────┐  ┌──────────────────┐
             │ Next.js Platform │  │ Streamlit App    │
             │ Port 3000 (Web)  │  │ Port 8501 (11p)  │
             └──────────────────┘  └──────────────────┘
```

---

## 📊 4. Machine Learning Benchmarking Results

Evaluated on the chronological $15\%$ held-out test partition ($1,062$ out-of-time hourly test observations):

| Model Architecture | MAE (µg/m³) | RMSE (µg/m³) | MAPE (%) | $R^2$ Score | Key Characteristics |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Ridge Linear Regression** | **5.38** | **6.46** | **9.7%** | **0.946** | Standardized L2-regularized linear model over engineered lags. |
| **XGBoost Regressor** | **6.58** | **8.33** | **8.4%** | **0.948** | Gradient boosted trees with $95\%$ empirical uncertainty bands. |
| **Random Forest** | 6.63 | 8.31 | 8.7% | 0.949 | Robust tree ensemble with empirical leaf variance intervals. |
| **Naive Baseline** | 10.88 | 13.57 | 14.0% | 0.863 | Persistence benchmark ($\hat{y}_{t+h} = y_t$). |
| **SARIMA $(1,1,1)\times(1,0,1)_{24}$** | 18.50 | 23.20 | 16.4% | 0.650 | Classical univariate model; struggles without exogenous weather features. |

### 🔬 SHAP Explainability Ranking (Top Atmospheric Drivers)
1. `pm25_lag_1` (Mean |SHAP| = **11.58 µg/m³**): Dominant autoregressive past memory.
2. `pm25_lag_24` (Mean |SHAP| = **1.72 µg/m³**): 24-hour diurnal cycle memory.
3. `pm25_rolling_mean_3` (Mean |SHAP| = **1.39 µg/m³**): Short-term particulate trend.
4. `temperature` (Mean |SHAP| = **1.13 µg/m³**): Thermal boundary layer mixing.
5. `pm25_roc_3h` (Mean |SHAP| = **1.09 µg/m³**): 3-hour rate of change momentum.

---

## 🗂️ 5. Project Directory Structure

```text
aerospace/
├── README.md                          # Comprehensive project documentation
├── LICENSE                            # MIT License
├── requirements.txt                   # Backend Python dependencies
├── .env.example                       # Environment configuration template
├── .gitignore                         # Git exclusion rules
├── Dockerfile                         # Container specification
├── docker-compose.yml                 # PostgreSQL + FastAPI composition
├── run.ps1                            # One-click PowerShell local launcher
├── run.bat                            # Windows command launcher
│
├── api/                               # FastAPI REST Backend (Port 8000)
│   ├── main.py                        # Application entrypoint & lifespan
│   ├── schemas.py                     # Pydantic v2 validation models
│   └── routes/                        # Modular sub-routers
│       ├── stations.py                # Sensor stations & current telemetry
│       ├── forecast.py                # 24h rolling ML & external forecasts
│       ├── anomalies.py               # Dual-method anomaly detection & logs
│       ├── risk.py                    # Composite analytical risk scoring
│       ├── explainability.py          # SHAP global & local attribution
│       └── data_quality.py            # Data quality audits & diagnostics
│
├── frontend/                          # Next.js 14 Web Platform (Port 3000)
│   ├── package.json                   # Dependencies (Next.js, Recharts, Lucide)
│   ├── tailwind.config.js             # Atmospheric design system tokens
│   └── src/
│       ├── app/                       # App Router & layout
│       │   ├── layout.tsx             # Root layout with Google Fonts
│       │   ├── page.tsx               # Executive Overview dashboard
│       │   └── globals.css            # Atmospheric glass styling & radar anims
│       ├── components/                # Modular UI components
│       │   ├── Navbar.tsx             # Aerospace telemetry HUD & tabs
│       │   ├── MetricCard.tsx         # Precision tabular sensor metric cards
│       │   ├── ForecastStudio.tsx     # Multi-horizon dual-curve forecasting
│       │   ├── LiveSensors.tsx        # Multi-station spatial telemetry grid
│       │   ├── AnomalyRadar.tsx       # Dual-algorithm incident surveillance
│       │   ├── ExplainabilityLab.tsx  # Game-theoretic SHAP research deck
│       │   ├── ModelLeaderboard.tsx   # Benchmark ranking & error metrics
│       │   └── AuditReports.tsx       # Printable compliance dossiers & CSV
│       └── lib/                       # API clients & formatting utilities
│
├── dashboard/                         # Streamlit Analytics Dashboard (Port 8501)
│   ├── app.py                         # Streamlit landing application & sidebar
│   ├── components/                    # Reusable visual components
│   └── pages/                         # 11 Dedicated Deep-Dive Analytics Pages
│       ├── 01_Home.py                 # Platform overview & quick forecast
│       ├── 02_Live_Air_Quality.py     # Interactive geospatial network map
│       ├── 03_Data_Explorer.py        # Raw vs cleaned data tables
│       ├── 04_EDA_and_Analytics.py    # 12-dimensional statistical analysis
│       ├── 05_Forecast.py             # Multi-horizon forecast curves & 95% CI
│       ├── 06_Anomaly_Detection.py    # Anomaly timeline & incident log
│       ├── 07_Explainability.py       # SHAP global & local waterfall charts
│       ├── 08_Model_Performance.py   # Benchmark comparison leaderboard
│       ├── 09_Historical_Trends.py    # Multi-resolution rolling averages
│       ├── 10_Data_Quality.py         # Missingness heatmaps & outlier audits
│       └── 11_Reports.py              # On-demand PDF and CSV report export
│
├── src/                               # Core Python Data Science Pipeline
│   ├── config.py                      # Pydantic settings & structured logging
│   ├── ingestion/                     # OpenAQ v3 & Open-Meteo ingestion
│   ├── preprocessing/                 # Data quality, outlier & imputation
│   ├── features/                      # 36 leak-free lag, rolling & cyclical features
│   ├── models/                        # Baseline, Ridge, RF, XGBoost, SARIMA
│   ├── anomaly/                       # Rolling 3σ band & Isolation Forest
│   ├── explainability/                # TreeExplainer SHAP attribution
│   └── risk/                          # 4-tier composite risk intelligence
│
├── database/                          # Data Access Layer
│   ├── schema.sql                     # PostgreSQL DDL table definitions
│   ├── models.py                      # SQLAlchemy ORM declarative models
│   └── connection.py                  # Resilient engine with SQLite fallback
│
├── models/                            # Trained Artifacts & Metadata
│   ├── model.pkl                      # Serialized model bundle
│   ├── metadata.json                  # Training runs, features, and leaderboard
│   └── shap_summary.json              # Precomputed SHAP attribution payloads
│
├── data/                              # Persistent Data Tier
│   ├── aerosense.db                   # SQLite database (when local)
│   └── processed/                     # Clean & engineered Parquet datasets
│
├── tests/                             # Automated Pytest Suite (20 Tests)
│   ├── test_ingestion.py              # Telemetry collection tests
│   ├── test_preprocessing.py          # Data cleaning & validation tests
│   ├── test_features.py               # Zero data leakage tests
│   ├── test_models.py                 # Model training & interval tests
│   ├── test_anomaly.py                # Anomaly detector & risk scoring tests
│   ├── test_api.py                    # FastAPI REST endpoint tests
│   └── test_reports.py                # PDF report generation tests
│
└── docs/                              # Academic Deliverables & Theses
    ├── architecture.md                # System architecture documentation
    ├── methodology.md                 # Mathematical formulations
    └── research_paper.md              # Complete thesis report
```

---

## 💻 6. Quick Start & Execution Guide

### Option A: One-Click Launcher (Recommended for Windows / VS Code)

Open PowerShell inside the project directory and run:

```powershell
.\run.ps1
```

This single command will:
1. Verify and start the **FastAPI REST Backend** on `http://localhost:8000`.
2. Verify backend health (`/health` responding with HTTP 200).
3. Start the **Next.js Web Platform** on `http://localhost:3000`.
4. Automatically open your default web browser to the live platform.

---

### Option B: Manual Execution in Separate Terminals

#### 1. Set Up Environment
```bash
# Clone and enter project
cd aerospace

# Create & activate Python virtual environment
python -m venv .venv
.venv\Scripts\activate       # On Linux/macOS: source .venv/bin/activate

# Install Python dependencies
pip install -r requirements.txt

# Install Frontend dependencies
cd frontend && npm install && cd ..
```

#### 2. Run Data Pipeline & Train Models
```bash
python -m src.ingestion.pipeline              # Ingest telemetry
python -m src.preprocessing.cleaning          # Clean & harmonize
python -m src.features.engineering            # Feature engineering
python -m src.models.forecasting              # Train & benchmark models
python -m src.anomaly.detector                # Run dual anomaly detection
python -m src.explainability.shap_analysis    # Precompute SHAP attributions
```

#### 3. Run Automated Tests
```bash
python -m pytest tests/ -v
# 20 passed (100% test coverage across data, models, and APIs)
```

#### 4. Launch Services
* **Terminal 1 — FastAPI Backend**:
  ```bash
  python -m uvicorn api.main:app --host 0.0.0.0 --port 8000
  ```
  * Swagger Docs: [http://localhost:8000/docs](http://localhost:8000/docs)
  * Health Check: [http://localhost:8000/health](http://localhost:8000/health)

* **Terminal 2 — Next.js Web Platform**:
  ```bash
  cd frontend
  npm run start    # Or npm run dev for live reloading
  ```
  * Web Platform: [http://localhost:3000](http://localhost:3000)

* **Terminal 3 (Optional) — Streamlit 11-Page Dashboard**:
  ```bash
  streamlit run dashboard/app.py --server.port 8501
  ```
  * Analytics Dashboard: [http://localhost:8501](http://localhost:8501)

---

## 🐳 7. Docker Deployment

To launch the complete containerized stack (PostgreSQL, FastAPI Backend, Next.js Frontend) with a single command:

```bash
docker compose up --build
```
* **FastAPI Backend**: `http://localhost:8000/docs`
* **Next.js Web Platform**: `http://localhost:3000`
* **PostgreSQL Database**: `localhost:5432`

---

## 📡 8. REST API Endpoints

| HTTP Verb | Route | Description |
| :--- | :--- | :--- |
| `GET` | `/health` | System health, database engine, and model readiness status. |
| `GET` | `/stations` | List all monitored urban air quality stations with coordinates. |
| `GET` | `/telemetry/current` | Real-time atmospheric observations with freshness & risk status. |
| `GET` | `/forecast` | Multi-horizon forecasts with 95% uncertainty intervals and risk level. |
| `GET` | `/forecast/24h-comparison` | Unified 24h dashboard view: Last 24h Observed vs Next 24h Forecast. |
| `GET` | `/anomalies` | Detected atmospheric and sensor anomalies with scores and severity. |
| `GET` | `/risk` | Real-time composite analytical risk index and health advisory. |
| `GET` | `/model-performance` | Out-of-time benchmark leaderboard ($\text{MAE}, \text{RMSE}, \text{MAPE}, R^2$). |
| `GET` | `/explainability` | Global SHAP feature ranking and local instance decision breakdowns. |
| `GET` | `/data-quality` | Missingness, duplicate counts, and outlier classification report. |
| `POST` | `/ingest` | Trigger data ingestion pipeline (Live OpenAQ or Calibrated Demo). |
| `POST` | `/train` | Trigger chronological model retraining and walk-forward benchmarking. |
| `POST` | `/detect-anomalies` | Trigger dual-method anomaly detection run. |

---

## 🎓 9. Academic Project Deliverables

For project reviews, final-year presentations, and external evaluations, AeroSense includes:
1. **Academic Documentation & Research Paper** in `docs/`:
   * `docs/architecture.md`: Micro-service interaction and component diagrams.
   * `docs/methodology.md`: Mathematical formulations for SARIMA, XGBoost, Isolation Forest, and SHAP.
   * `docs/research_paper.md`: Complete 12-page academic thesis draft.
2. **Automated On-Demand Reports**: Download official PDF environmental reports and CSV observation logs.
3. **100% Test Coverage**: Complete Pytest test suite in `tests/` verifying all mathematical invariants, zero-leakage constraints, and API contracts.

---

## 📄 10. License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
