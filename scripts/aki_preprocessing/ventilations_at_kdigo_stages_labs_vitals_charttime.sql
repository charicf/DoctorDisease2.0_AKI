-- Determines if a patient is ventilated for each chart time in kdigo_stages, labs, and vitals.
-- Creates a table with the result.
-- Requires the `ventilation` and `kdigo_stages` tables.

DROP MATERIALIZED VIEW IF EXISTS mimiciv_icu.vent_kdigo_stages_labs_vitals_charttime CASCADE;
CREATE MATERIALIZED VIEW mimiciv_icu.vent_kdigo_stages_labs_vitals_charttime AS
SELECT *
FROM (
  (
    -- Ventilation for each time in kdigo_stages
    SELECT
      ie.stay_id, ie.charttime,
      -- if vd.stay_id is not null, then they have a valid ventilation event
      -- in this case, we say they are ventilated
      -- otherwise, they are not
      MAX(CASE
        WHEN vd.stay_id IS NOT NULL THEN 1
        ELSE 0 END) AS vent
    FROM mimiciv_derived.kdigo_stages ie
    LEFT JOIN mimiciv_derived.ventilation vd
      ON ie.stay_id = vd.stay_id
      AND (
        -- ventilation duration overlaps with charttime
        (vd.starttime <= ie.charttime AND vd.endtime >= ie.charttime)
      )
    GROUP BY ie.stay_id, ie.charttime
  ) UNION (
    -- Ventilation for each time in labs
    SELECT
      ie.stay_id, ie.charttime,
      -- if vd.stay_id is not null, then they have a valid ventilation event
      -- in this case, we say they are ventilated
      -- otherwise, they are not
      MAX(CASE
        WHEN vd.stay_id IS NOT NULL THEN 1
        ELSE 0 END) AS vent
    FROM mimiciv_icu.labs ie
    LEFT JOIN mimiciv_derived.ventilation vd
      ON ie.stay_id = vd.stay_id
      AND (
        -- ventilation duration overlaps with charttime
        (vd.starttime <= ie.charttime AND vd.endtime >= ie.charttime)
      )
    GROUP BY ie.stay_id, ie.charttime
  ) UNION (
    -- Ventilation for each time in chartevents (vitals)
    SELECT
      ie.stay_id, ie.charttime,
      -- if vd.stay_id is not null, then they have a valid ventilation event
      -- in this case, we say they are ventilated
      -- otherwise, they are not
      MAX(CASE
        WHEN vd.stay_id IS NOT NULL THEN 1
        ELSE 0 END) AS vent
    FROM (
      SELECT stay_id, charttime
      FROM mimiciv_icu.chartevents
      WHERE itemid IN (
        -- List of item IDs relevant to ventilation (example IDs, please adjust based on your needs)
        224685, 224684, 224686, 224687, 224421
      )
    ) ie
    LEFT JOIN mimiciv_derived.ventilation vd
      ON ie.stay_id = vd.stay_id
      AND (
        -- ventilation duration overlaps with charttime
        (vd.starttime <= ie.charttime AND vd.endtime >= ie.charttime)
      )
    GROUP BY ie.stay_id, ie.charttime
  )
) u
ORDER BY stay_id, charttime;
