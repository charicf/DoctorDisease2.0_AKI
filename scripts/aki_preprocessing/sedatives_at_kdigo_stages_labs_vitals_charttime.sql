-- Determines if a patient is subject to sedatives for each chart time in kdigo_stages.
-- Creates a table with the result.
-- Requires the `kdigo_stages` and `sedativesduration`, `labs`, `vitals` table

DROP MATERIALIZED VIEW IF EXISTS mimiciv_icu.sedatives_kdigo_stages_labs_vitals_charttime CASCADE;
CREATE MATERIALIZED VIEW mimiciv_icu.sedatives_kdigo_stages_labs_vitals_charttime AS
SELECT *
FROM (
  (
    -- Sedatives for each time in kdigo_stages
    SELECT
      ie.stay_id, ie.charttime,
      MAX(CASE
        WHEN vd.stay_id IS NOT NULL THEN 1
        ELSE 0 END) AS sedative
    FROM mimiciv_derived.kdigo_stages ie
    LEFT JOIN mimiciv_icu.sedative_durations vd
      ON ie.stay_id = vd.stay_id
      AND (vd.starttime <= ie.charttime AND vd.endtime >= ie.charttime)
    GROUP BY ie.stay_id, ie.charttime
  ) UNION (
    -- Sedatives for each time in labs
    SELECT
      ie.stay_id, ie.charttime,
      MAX(CASE
        WHEN vd.stay_id IS NOT NULL THEN 1
        ELSE 0 END) AS sedative
    FROM mimiciv_icu.labs ie
    LEFT JOIN mimiciv_icu.sedative_durations vd
      ON ie.stay_id = vd.stay_id
      AND (vd.starttime <= ie.charttime AND vd.endtime >= ie.charttime)
    GROUP BY ie.stay_id, ie.charttime
  ) UNION (
    -- Sedatives for each time in vitals
    SELECT
      ie.stay_id, ie.charttime,
      MAX(CASE
        WHEN vd.stay_id IS NOT NULL THEN 1
        ELSE 0 END) AS sedative
    FROM mimiciv_icu.vitals ie
    LEFT JOIN mimiciv_icu.sedative_durations vd
      ON ie.stay_id = vd.stay_id
      AND (vd.starttime <= ie.charttime AND vd.endtime >= ie.charttime)
    GROUP BY ie.stay_id, ie.charttime
  )
) u
ORDER BY stay_id, charttime;
