-- This query extracts durations of sedative administration

-- Consecutive administrations are numbered 1, 2, ...
-- Total time on the drug can be calculated from this table
-- by grouping using stay_id

-- select only the ITEMIDs from the inputevents_cv table related to sedative
DROP MATERIALIZED VIEW IF EXISTS mimiciv_icu.sedative_durations;
CREATE MATERIALIZED VIEW mimiciv_icu.sedative_durations AS
WITH io_cv AS (
  SELECT
    stay_id, starttime, endtime, itemid,
    -- ITEMIDs (42273, 42802) accidentally store rate in amount column
    CASE
      WHEN itemid IN (42273, 42802) THEN amount
      ELSE rate
    END AS rate,
    CASE
      WHEN itemid IN (42273, 42802) THEN rate
      ELSE amount
    END AS amount
  FROM mimiciv_icu.inputevents
  WHERE itemid IN (30124, 30150, 30308, 30118, 30149, 30131)
),
io_mv AS (
  SELECT
    stay_id, starttime, endtime, itemid
  FROM mimiciv_icu.inputevents
  WHERE itemid IN (221668, 221744, 225972, 225942, 222168)
    AND statusdescription != 'Rewritten'
),
sedativecv1 AS (
  SELECT
    stay_id, starttime, endtime, itemid,
    1 AS sedative,
    MAX(CASE WHEN endtime IS NOT NULL THEN 1 ELSE 0 END) AS sedative_stopped,
    MAX(CASE WHEN rate IS NOT NULL THEN 1 ELSE 0 END) AS sedative_null,
    MAX(rate) AS sedative_rate,
    MAX(amount) AS sedative_amount
  FROM io_cv
  GROUP BY stay_id, starttime, endtime, itemid
),
sedativecv2 AS (
  SELECT v.*,
    SUM(sedative_null) OVER (PARTITION BY stay_id, itemid ORDER BY starttime) AS sedative_partition
  FROM sedativecv1 v
),
sedativecv3 AS (
  SELECT v.*,
    FIRST_VALUE(sedative_rate) OVER (PARTITION BY stay_id, itemid, sedative_partition ORDER BY starttime) AS sedative_prevrate_ifnull
  FROM sedativecv2 v
),
sedativecv4 AS (
  SELECT
    stay_id, starttime, endtime, itemid,
    sedative, sedative_rate, sedative_amount, sedative_stopped, sedative_prevrate_ifnull,
    CASE
      WHEN sedative = 0 THEN NULL
      WHEN sedative_rate > 0 AND LAG(sedative_prevrate_ifnull, 1) OVER (PARTITION BY stay_id, itemid, sedative_null ORDER BY starttime) IS NULL THEN 1
      WHEN sedative_rate = 0 AND LAG(sedative_prevrate_ifnull, 1) OVER (PARTITION BY stay_id, itemid, sedative ORDER BY starttime) = 0 THEN 0
      WHEN sedative_prevrate_ifnull = 0 AND LAG(sedative_prevrate_ifnull, 1) OVER (PARTITION BY stay_id, itemid, sedative ORDER BY starttime) = 0 THEN 0
      WHEN LAG(sedative_prevrate_ifnull, 1) OVER (PARTITION BY stay_id, itemid, sedative ORDER BY starttime) = 0 THEN 1
      WHEN LAG(sedative_stopped, 1) OVER (PARTITION BY stay_id, itemid, sedative ORDER BY starttime) = 1 THEN 1
      ELSE NULL
    END AS sedative_start
  FROM sedativecv3
),
sedativecv5 AS (
  SELECT v.*,
    SUM(sedative_start) OVER (PARTITION BY stay_id, itemid, sedative ORDER BY starttime) AS sedative_first
  FROM sedativecv4 v
),
sedativecv6 AS (
  SELECT v.*,
    CASE
      WHEN sedative = 0 THEN NULL
      WHEN sedative_stopped = 1 THEN sedative_first
      WHEN sedative_rate = 0 THEN sedative_first
      WHEN LEAD(starttime, 1) OVER (PARTITION BY stay_id, itemid, sedative ORDER BY starttime) IS NULL THEN sedative_first
      ELSE NULL
    END AS sedative_stop
  FROM sedativecv5 v
),
sedativecv AS (
  SELECT
    stay_id, itemid,
    MIN(CASE WHEN sedative_rate IS NOT NULL THEN starttime ELSE NULL END) AS starttime,
    MIN(CASE WHEN sedative_first = sedative_stop THEN endtime ELSE NULL END) AS endtime
  FROM sedativecv6
  WHERE sedative_first IS NOT NULL AND sedative_first != 0 AND stay_id IS NOT NULL
  GROUP BY stay_id, itemid, sedative_first
  HAVING MIN(starttime) != MIN(CASE WHEN sedative_first = sedative_stop THEN endtime ELSE NULL END)
    AND MAX(sedative_rate) > 0
),
sedativecv_grp AS (
  SELECT
    s1.stay_id, s1.starttime,
    MIN(t1.endtime) AS endtime
  FROM sedativecv s1
  INNER JOIN sedativecv t1
    ON s1.stay_id = t1.stay_id
    AND s1.starttime <= t1.endtime
    AND NOT EXISTS(SELECT 1 FROM sedativecv t2 WHERE t1.stay_id = t2.stay_id AND t1.endtime >= t2.starttime AND t1.endtime < t2.endtime)
  WHERE NOT EXISTS(SELECT 1 FROM sedativecv s2 WHERE s1.stay_id = s2.stay_id AND s1.starttime > s2.starttime AND s1.starttime <= s2.endtime)
  GROUP BY s1.stay_id, s1.starttime
  ORDER BY s1.stay_id, s1.starttime
),
sedativemv AS (
  SELECT
    stay_id, starttime, endtime, itemid
  FROM mimiciv_icu.inputevents
  WHERE itemid IN (221668, 221744, 225972, 225942, 222168)
    AND statusdescription != 'Rewritten'
),
sedativemv_grp AS (
  SELECT
    s1.stay_id, s1.starttime,
    MIN(t1.endtime) AS endtime
  FROM sedativemv s1
  INNER JOIN sedativemv t1
    ON s1.stay_id = t1.stay_id
    AND s1.starttime <= t1.endtime
    AND NOT EXISTS(SELECT 1 FROM sedativemv t2 WHERE t1.stay_id = t2.stay_id AND t1.endtime >= t2.starttime AND t1.endtime < t2.endtime)
  WHERE NOT EXISTS(SELECT 1 FROM sedativemv s2 WHERE s1.stay_id = s2.stay_id AND s1.starttime > s2.starttime AND s1.starttime <= s2.endtime)
  GROUP BY s1.stay_id, s1.starttime
  ORDER BY s1.stay_id, s1.starttime
)
SELECT
  stay_id,
  ROW_NUMBER() OVER (PARTITION BY stay_id ORDER BY starttime) AS sedativenum,
  starttime, endtime,
  EXTRACT(EPOCH FROM endtime - starttime)/3600 AS duration_hours
FROM sedativecv_grp
UNION
SELECT
  stay_id,
  ROW_NUMBER() OVER (PARTITION BY stay_id ORDER BY starttime) AS sedativenum,
  starttime, endtime,
  EXTRACT(EPOCH FROM endtime - starttime)/3600 AS duration_hours
FROM sedativemv_grp
ORDER BY stay_id, sedativenum;
