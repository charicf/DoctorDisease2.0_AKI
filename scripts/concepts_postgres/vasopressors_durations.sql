
-- NOTE: many scripts *require* you to use mimiciv_derived as the schema for outputting concepts
-- change the search path at your peril!
SET search_path TO mimiciv_derived, mimiciv_hosp, mimiciv_icu, mimiciv_ed;

-- Drop the derived table if it already exists
DROP TABLE IF EXISTS mimiciv_icu.vasopressor_durations;


-- Create the derived table
CREATE TABLE mimiciv_icu.vasopressor_durations (
    subject_id INT,
    hadm_id INT,
    stay_id INT,
    itemid INT,
    starttime TIMESTAMP,
    endtime TIMESTAMP,
    duration_hours FLOAT
);

-- Temporary CTE for chartevents vasopressors data
WITH chartevents_vasopressors AS (
    SELECT
        ce.subject_id,
        ce.hadm_id,
        ce.stay_id,
        ce.itemid,
        MIN(ce.charttime) AS starttime,
        MAX(ce.charttime) AS endtime,
        EXTRACT(EPOCH FROM (MAX(ce.charttime) - MIN(ce.charttime))) / 3600 AS duration_hours
    FROM mimiciv_icu.chartevents ce
    JOIN mimiciv_icu.d_items di ON ce.itemid = di.itemid
    -- WHERE (di.label ILIKE '%norepinephrine%' OR di.label ILIKE '%epinephrine%' OR di.label ILIKE '%dopamine%' OR di.label ILIKE '%vasopressin%')
    WHERE value ILIKE any (array['%epinephrine%', '%dopamine%', '%vasopressin%'])
    GROUP BY ce.subject_id, ce.hadm_id, ce.stay_id, ce.itemid
),

-- Temporary CTE for inputevents vasopressors data
inputevents_vasopressors AS (
    SELECT
        ie.subject_id,
        ie.hadm_id,
        ie.stay_id,
        ie.itemid,
        MIN(ie.starttime) AS starttime,
        MAX(ie.endtime) AS endtime,
        EXTRACT(EPOCH FROM (MAX(ie.endtime) - MIN(ie.starttime))) / 3600 AS duration_hours
    FROM mimiciv_icu.inputevents ie
    JOIN mimiciv_icu.d_items di ON ie.itemid = di.itemid
    -- WHERE di.label IN ('norepinephrine', 'epinephrine', 'dopamine', 'vasopressin')
    WHERE (di.label ILIKE '%norepinephrine%' OR di.label ILIKE '%epinephrine%' OR di.label ILIKE '%dopamine%' OR di.label ILIKE '%vasopressin%')
    GROUP BY ie.subject_id, ie.hadm_id, ie.stay_id, ie.itemid
)

-- Insert data into vasopressor_durations table
INSERT INTO vasopressor_durations
SELECT * FROM chartevents_vasopressors
UNION ALL
SELECT * FROM inputevents_vasopressors;
