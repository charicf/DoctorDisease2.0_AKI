-- Determines if a patient is given vasopressors for each chart time in kdigo_stages.
-- Creates a table with the result.
-- Requires the `vasopressordurations`, `kdigo_stages`, `labs`, and `chartevents` tables.

DROP MATERIALIZED VIEW IF EXISTS mimiciv_icu.vasopressor_kdigo_stages_labs_vitals_charttime CASCADE;
CREATE MATERIALIZED VIEW mimiciv_icu.vasopressor_kdigo_stages_labs_vitals_charttime AS
SELECT *
FROM (
  (
    -- Vasopressors for each time in kdigo_stages
    SELECT
      ie.stay_id, ie.charttime,
      -- if vd.stay_id is not null, then they have a valid vasopressor event
      -- in this case, we say they are given vasopressor
      -- otherwise, they are not
      MAX(CASE
        WHEN vd.stay_id IS NOT NULL THEN 1
        ELSE 0 END) AS vasopressor
    FROM mimiciv_derived.kdigo_stages ie
    LEFT JOIN mimiciv_icu.vasopressor_durations vd
      ON ie.stay_id = vd.stay_id
      AND (
        -- vasopressor duration overlaps with charttime
        (vd.starttime <= ie.charttime AND vd.endtime >= ie.charttime)
      )
    GROUP BY ie.stay_id, ie.charttime
  ) UNION (
    -- Vasopressors for each time in labs
    SELECT
      ie.stay_id, ie.charttime,
      -- if vd.stay_id is not null, then they have a valid vasopressor event
      -- in this case, we say they are given vasopressor
      -- otherwise, they are not
      MAX(CASE
        WHEN vd.stay_id IS NOT NULL THEN 1
        ELSE 0 END) AS vasopressor
    FROM mimiciv_icu.labs ie
    LEFT JOIN mimiciv_icu.vasopressor_durations vd
      ON ie.stay_id = vd.stay_id
      AND (
        -- vasopressor duration overlaps with charttime
        (vd.starttime <= ie.charttime AND vd.endtime >= ie.charttime)
      )
    GROUP BY ie.stay_id, ie.charttime
  ) UNION (
    -- Vasopressors for each time in chartevents (vitals)
    SELECT
      ie.stay_id, ie.charttime,
      -- if vd.stay_id is not null, then they have a valid vasopressor event
      -- in this case, we say they are given vasopressor
      -- otherwise, they are not
      MAX(CASE
        WHEN vd.stay_id IS NOT NULL THEN 1
        ELSE 0 END) AS vasopressor
    FROM (
      SELECT stay_id, charttime
      FROM mimiciv_icu.chartevents
      WHERE itemid IN (
        -- List of item IDs relevant to vasopressors (example IDs, please adjust based on your needs)
        220051, 220179, 220180, 220181, 220739
      )
    ) ie
    LEFT JOIN mimiciv_icu.vasopressor_durations vd
      ON ie.stay_id = vd.stay_id
      AND (
        -- vasopressor duration overlaps with charttime
        (vd.starttime <= ie.charttime AND vd.endtime >= ie.charttime)
      )
    GROUP BY ie.stay_id, ie.charttime
  )
) u
ORDER BY stay_id, charttime;
