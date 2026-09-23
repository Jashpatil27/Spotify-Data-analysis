# Spotify Streaming Analytics Dashboard

Project Overview
A Python + SQL + Power BI analytics project that traces six years of my own real Spotify listening history, detects actual listening sessions from raw event timestamps (not assumed session boundaries), measures real skip behavior, and surfaces genuine listening patterns — top artists/tracks, seasonal trends, and weekly rhythm. Delivered as an interactive, filterable Power BI dashboard.

Business Problem
When, how long, and to what am I actually listening — and how has that changed year over year? Which artists and tracks dominate my real listening time (not just play count), what does a "typical session" actually look like, and how often do I skip rather than finish a track?

Dataset
Spotify Extended Streaming History (personal data export, requested directly from Spotify). ~48,000 raw play events · Sep 2020 – 2026 · one row per stream, including track, artist, ms_played, timestamp (UTC), and skip/reason flags.

No synthetic data was used anywhere in this project. Every number in the dashboard is computed directly from this export.

Objectives
- Clean raw JSON play-event data and remove noise (nulls from removed tracks, duplicates, accidental sub-30-second plays).
- Detect real listening sessions from raw timestamps (not an assumed fixed window) using a documented inactivity-gap rule.
- Measure real skip rate with a minimum-sample-size guard so low-volume artists don't produce misleading rates.
- Segment listening by artist, track, month, and weekday.
- Ship all of it as an interactive, filterable dashboard.

Tech Stack
- **Python**: pandas — JSON parsing, cleaning, feature engineering (year/month/hour/weekday, UTC → local time conversion)
- **SQL**: PostgreSQL-syntax scripts (CTEs, window functions, conditional aggregation) — see `/sql`
- **Power BI**: star-schema data model, DAX measures, 2-page interactive report
- **Version control**: Git + GitHub

No ML, no cloud infrastructure, no unnecessary backend — intentionally kept simple.

Data Pipeline
```
Real Data (Spotify Extended Streaming History JSON export)
    ↓
Data cleaning (pandas) — drop nulls/duplicates, filter accidental plays (<30s), engineer time features
    ↓
SQL analysis (PostgreSQL syntax) — session detection, skip-rate analysis, aggregation
    ↓
Validated results loaded into Power BI (star schema: plays fact table + Date dimension)
    ↓
DAX measures computed live on top of the model
    ↓
2-page interactive Power BI report
```

Why the modeling happens in both SQL and Power BI: SQL is used to validate the harder logic first — session boundaries and skip rate — against the full raw dataset outside of any BI-tool black box. Power BI then re-expresses the same logic as DAX measures so the report stays fully interactive (year slicer, cross-filtering) rather than depending on pre-aggregated static numbers.

SQL Analysis
All SQL analysis lives in a single script, [`sql for spotify.sql`](https://github.com/Jashpatil27/Spotify-Data-analysis/blob/main/sql%20for%20spotify.sql), run against `spotify_cleaned.csv` (loaded into PostgreSQL). It covers, in order:
- Row-level sanity checks on the cleaned data (nulls, duplicates)
- **Session detection** — `LAG()` + cumulative `SUM()` to group raw timestamps into sessions using a 20-minute inactivity-gap rule
- **Skip-rate analysis** — conditional aggregation (`COUNT(CASE WHEN...)`) with a `HAVING` guard so low-play-count artists/tracks don't produce noisy rates
- Aggregation for top artists/tracks, monthly trend, and weekday × month patterns (feeding the heatmap)

Session Detection Methodology
Unit of analysis: an individual play event, grouped into a session. A new session starts whenever the gap between one play's end and the next play's start exceeds **20 minutes** of inactivity. This is a deliberate, documented threshold — not an assumption baked silently into the dashboard.

Window Function Analysis
- `LAG()` — retrieves the previous play's end timestamp within the same user timeline, used to compute the inactivity gap before each play.
- Cumulative `SUM()` over a boolean "new session?" flag — turns the gap flags into a running session ID, so every play can be grouped back into its session.
- Conditional aggregation (`COUNT(CASE WHEN skipped THEN 1 END)`) — computes skip rate per artist/track without a separate filtered query.

Dashboard
2-page Power BI app:

1. **Overview** — KPI cards (hours played, sessions, avg session length, skip rate), monthly listening trend, weekday × month heatmap, listening-by-weekday chart, year slicer<img width="1176" height="657" alt="spotify_main" src="https://github.com/user-attachments/assets/3e27ec59-a0e3-4f13-8419-185cdb4bd059" />

2. **Artists & Tracks** — top 8 artists (bar + treemap), top 8 songs, distinct-artists-per-year trend (listening diversity over time)
<img width="1180" height="657" alt="spotify_main2" src="https://github.com/user-attachments/assets/466bc94f-ab4f-40a8-8911-f6bfa5a55b88" />

Key Findings
- **1,586 total hours** of listening logged across 6 years (2020–2026).
- **~4,000 distinct listening sessions**, averaging **28 minutes** each (20-minute inactivity-gap threshold).
- **Pritam** is the most-played artist overall — **123.6 hours**, ~40 hours ahead of #2 (Yo Yo Honey Singh, 84.3 hours).
- Most-replayed track: **"Yeh Jawaani Hai Deewani."**
- Overall **skip rate: 13.1%**, but this varies sharply by year — e.g. 6.06% in 2022 alone.
- Listening is strongly seasonal, not flat: monthly hours peak in **April (183 hrs)** and dip in the Sep–Nov stretch.
- The single highest month × weekday cell in the whole heatmap is **Friday in October (29.71 hrs)** — over 7x some of the quietest cells.
- **Distinct-artists-per-year** reveals a discovery cycle: rising variety through 2021–22 (peak ~583–660 artists), narrowing to familiar favorites by 2023–24 (low ~310), then a renewed discovery phase in 2025.

Project Structure
```
Spotify-Data-analysis/
├── README.md
├── spotify_cleaned.csv     # cleaned, feature-engineered play events (output of the Python step)
├── sql for spotify.sql     # session detection, skip-rate analysis, aggregation
└── Spotify Report.pbix     # 2-page Power BI dashboard
```
The raw Spotify JSON export and the Python cleaning script are run locally (not committed, since the raw export contains personal data) — `spotify_cleaned.csv` is the validated output that both the SQL script and the Power BI report are built on.

How to Run Locally
```
git clone https://github.com/Jashpatil27/Spotify-Data-analysis.git
cd Spotify-Data-analysis
```
1. To regenerate `spotify_cleaned.csv` from scratch, request your own "Extended Streaming History" export from Spotify and run it through the pandas cleaning step (null/duplicate removal, `is_real_listen` flag, timezone conversion, feature engineering).
2. Load `spotify_cleaned.csv` into a local PostgreSQL instance and run `sql for spotify.sql` to reproduce the session detection, skip-rate, and aggregation results.
3. Open `Spotify Report.pbix` in Power BI Desktop — it's already built against `spotify_cleaned.csv`, so it will refresh in place if you point it at your own regenerated file.

Limitations
- Spotify's export timestamps are UTC; local-time conversion is applied once during cleaning — a known double-conversion bug currently affects hour-of-day granularity (see Future Improvements).
- The 20-minute session-gap threshold is a reasonable default, not a value derived from the data itself.
- No genre/mood metadata is included in the base export, so all analysis is limited to artist/track/time dimensions.
- Findings describe personal listening behavior only; no causal or general-population claims are made anywhere in this project.

Future Improvements
- Rebuild the pipeline directly from raw JSON to resolve the timezone double-conversion issue and correct hour-of-day analysis.
- Add a third dashboard page for listening-behavior patterns (hour-of-day, skip rate by artist).
- Explore genre/mood analysis if Spotify API audio-features access becomes available.
