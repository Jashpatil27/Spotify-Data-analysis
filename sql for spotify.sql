SELECT * FROM plays LIMIT 5;

-- total listing time
select year,SUM(ms_played_min / 60) as total_hours
from plays
where is_real_listen = true
group by year
order by year desc

-- top 10 artist
select master_metadata_album_artist_name as artist,SUM(ms_played_min / 60) as total_hours
from plays
where is_real_listen = true and master_metadata_album_artist_name is not null
group by artist
order by total_hours desc
limit 10

-- top 10 songs
select master_metadata_track_name as track,master_metadata_album_artist_name as artist,SUM(ms_played_min / 60) as total_hours,
spotify_track_uri as url
from plays
where is_real_listen = true and master_metadata_album_artist_name is not null
group by artist,track,url
order by total_hours desc
limit 10

-- listen by hours or days of the week
SELECT SUM(ms_played_min / 60) AS total_hours, day_of_week, hour
FROM plays
WHERE is_real_listen = true AND master_metadata_album_artist_name IS NOT NULL
GROUP BY hour, day_of_week
ORDER BY 
  CASE day_of_week
    WHEN 'Monday' THEN 1
    WHEN 'Tuesday' THEN 2
    WHEN 'Wednesday' THEN 3
    WHEN 'Thursday' THEN 4
    WHEN 'Friday' THEN 5
    WHEN 'Saturday' THEN 6
    WHEN 'Sunday' THEN 7
  END,
  hour;

  -- to get total hours listen on a weekdays
SELECT SUM(ms_played_min / 60) AS total_hours, day_of_week
FROM plays
WHERE is_real_listen = true AND master_metadata_album_artist_name IS NOT NULL
GROUP BY day_of_week
ORDER BY 
  CASE day_of_week
    WHEN 'Monday' THEN 1
    WHEN 'Tuesday' THEN 2
    WHEN 'Wednesday' THEN 3
    WHEN 'Thursday' THEN 4
    WHEN 'Friday' THEN 5
    WHEN 'Saturday' THEN 6
    WHEN 'Sunday' THEN 7
  END;

  -- listening session
WITH gaps AS (
  SELECT 
    ts_local::timestamp AS ts_local,
    LAG(ts_local::timestamp, 1) OVER (ORDER BY ts_local::timestamp) AS prev_ts,
    EXTRACT(EPOCH FROM (ts_local::timestamp - LAG(ts_local::timestamp, 1) OVER (ORDER BY ts_local::timestamp))) / 60 AS gap_minutes
  FROM plays
),
sessions AS (
  SELECT *, 
    CASE WHEN gap_minutes > 20 OR gap_minutes IS NULL THEN 1 ELSE 0 END AS is_new_session
  FROM gaps
),
session_ids AS (
  SELECT *, SUM(is_new_session) OVER (ORDER BY ts_local) AS session_id
  FROM sessions)
SELECT 
  session_id,
  min(ts_local) AS session_start,
  max(ts_local) AS session_end,
  count(*) AS tracks_played
FROM session_ids
GROUP BY session_id;

-- Artitst skipped the most
SELECT 
  master_metadata_album_artist_name AS artist,
  COUNT(*) AS total_plays,
  COUNT(CASE WHEN skipped = true THEN 1 END) AS skipped_plays,
  ROUND(
    COUNT(CASE WHEN skipped = true THEN 1 END) * 100.0 / COUNT(*), 
    2
  ) AS skip_rate_pct
FROM plays
WHERE master_metadata_album_artist_name IS NOT NULL
GROUP BY artist
HAVING COUNT(*) >= 20   -- ignore artists you've barely played, so a 100% skip rate isn't just 1 skip out of 1 play
ORDER BY skip_rate_pct DESC
LIMIT 10;

--view
CREATE VIEW session_stats AS
WITH gaps AS (
  SELECT 
    ts_local::timestamp AS ts_local,
    LAG(ts_local::timestamp, 1) OVER (ORDER BY ts_local::timestamp) AS prev_ts,
    EXTRACT(EPOCH FROM (ts_local::timestamp - LAG(ts_local::timestamp, 1) OVER (ORDER BY ts_local::timestamp))) / 60 AS gap_minutes
  FROM plays
),
sessions AS (
  SELECT *, 
    CASE WHEN gap_minutes > 20 OR gap_minutes IS NULL THEN 1 ELSE 0 END AS is_new_session
  FROM gaps
),
session_ids AS (
  SELECT *, SUM(is_new_session) OVER (ORDER BY ts_local) AS session_id
  FROM sessions
)
SELECT 
  session_id,
  MIN(ts_local) AS session_start,
  MAX(ts_local) AS session_end,
  COUNT(*) AS tracks_played,
  EXTRACT(EPOCH FROM (MAX(ts_local) - MIN(ts_local))) / 60 AS duration_minutes
FROM session_ids
GROUP BY session_id;

SELECT * FROM session_stats LIMIT 10;