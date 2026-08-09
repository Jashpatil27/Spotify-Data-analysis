# Spotify Streaming Analytics Dashboard

An end-to-end data analytics project built on my own personal Spotify
streaming history (2020–2026, ~48,000 plays) — from raw JSON export to
an interactive Power BI dashboard.

## Overview
This project covers the full analytics pipeline: data extraction and
cleaning in Python, relational modeling and analysis in PostgreSQL, and
dashboard/visualization design in Power BI.

## Tech Stack
- **Python** (pandas) — JSON parsing, data cleaning, feature engineering
- **PostgreSQL** — data modeling, SQL analysis, views
- **Power BI** — data modeling (star schema), DAX, interactive dashboard

## Pipeline

### 1. Data Extraction & Cleaning (Python)
- Parsed raw Spotify "Extended Streaming History" JSON exports
- Handled nulls (removed-track metadata), duplicates, and short/accidental
  plays via an `is_real_listen` flag (>=30s threshold)
- Engineered time-based features (year, month, hour, day-of-week) with
  UTC → local timezone conversion

### 2. SQL Analysis (PostgreSQL)
- Aggregation queries: yearly trends, top artists/tracks, weekly patterns
- **Session detection** using CTEs + window functions (`LAG()`, cumulative
  `SUM()`) to identify discrete listening sessions from raw timestamps
  based on a 20-minute inactivity gap
- **Skip-rate analysis** using conditional aggregation (`COUNT(CASE WHEN...)`)
  with a minimum-sample-size guard via `HAVING`

### 3. Dashboard (Power BI)
- Star-schema model: fact table (`plays`) + calculated Date dimension table
- DAX measures for total listening time, session stats, skip rate, and
  distinct-artist diversity per year
- Custom sort logic (`SWITCH`-based helper column) to correctly order
  weekdays Monday→Sunday instead of Power BI's default alphabetical sort
- **2-page report:**
  - **Overview** — KPI cards (hours played, sessions, avg session length,
    skip rate), monthly listening trend, weekday × month heatmap matrix,
    listening-by-weekday chart, year slicer
  - **Artists & Tracks** — top 08 artists (bar + treemap), top 08 songs,
    distinct-artists-per-year trend (listening diversity over time)

## Key Insights
- **1,586 total hours** of listening logged across 6 years (2020–2026)
- **~4,000 distinct listening sessions**, averaging **28 minutes** each
  (sessions defined via a 20-minute inactivity gap threshold)
- **Pritam** is the most-played artist — **123.6 hours**, ~40 hours ahead
  of the #2 artist (Yo Yo Honey Singh, 84.3 hours)
- Most-replayed track: **"Yeh Jawaani Hai Deewani"**
- Overall **skip rate: 13.1%**
- **Distinct-artists-per-year** shows a discovery cycle: rising variety
  through 2021–22 (peak ~585 artists), narrowing toward familiar
  favorites in 2023–24 (low of ~310), then a renewed discovery phase
  in 2025 (peak ~660)
  
## Possible Next Steps
- Rebuild the pipeline directly from raw JSON to resolve the timezone
  double-conversion issue and correct the hour-of-day analysis
- Add a third dashboard page for listening-behavior patterns (hour-of-day,
  skip rate by artist)
- Explore genre/mood analysis if Spotify API audio-features access is
  available
