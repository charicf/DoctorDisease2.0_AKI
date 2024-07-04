\set save_path_kdigo '/data/aki_preprocessing/kdigo_stages_measured.csv'
\set save_path_icustay_detail '/data/aki_preprocessing/icustay_detail-kdigo_stages_measured.csv'
\set save_path_vitals '/data/aki_preprocessing/vitals-kdigo_stages_measured.csv'
\set save_path_labs '/data/aki_preprocessing/labs-kdigo_stages_measured.csv'
\set save_path_vents_vasopressor_sedatives '/data/aki_preprocessing/vents-vasopressor-sedatives-kdigo_stages_measured.csv'

-- extract icu stays with at least one measurement of creatinine or urine output into kdigo_stages_measured.csv
COPY (
    SELECT *
    FROM mimiciv_derived.kdigo_stages
    WHERE stay_id IN (
        SELECT stay_id
        FROM mimiciv_derived.kdigo_stages
        WHERE (
            creat IS NOT NULL
            OR uo_rt_6hr IS NOT NULL
            OR uo_rt_12hr IS NOT NULL
            OR uo_rt_24hr IS NOT NULL
        )
        AND aki_stage IS NOT NULL
        GROUP BY stay_id
        HAVING COUNT(*) > 0
    )
)
TO :'save_path_kdigo'
WITH CSV HEADER DELIMITER ';';

-- extract demographics of patients with at least one measurement of creatinine or urine output into icustay_detail-kdigo_stages_measured.csv
COPY (
    SELECT p.subject_id, a.hadm_id, i.stay_id, p.gender, p.anchor_age, p.anchor_year, p.anchor_year_group, a.admittime, a.dischtime, a.deathtime, a.race
    FROM mimiciv_icu.icustays i
    JOIN mimiciv_hosp.patients p ON i.subject_id = p.subject_id
    JOIN mimiciv_hosp.admissions a ON i.hadm_id = a.hadm_id
    WHERE i.stay_id IN (
        SELECT stay_id
        FROM mimiciv_derived.kdigo_stages
        WHERE (
            creat IS NOT NULL
            OR uo_rt_6hr IS NOT NULL
            OR uo_rt_12hr IS NOT NULL
            OR uo_rt_24hr IS NOT NULL
        )
        AND aki_stage IS NOT NULL
        GROUP BY stay_id
        HAVING COUNT(*) > 0
    )
)
TO :'save_path_icustay_detail'
WITH CSV HEADER DELIMITER ';';

-- extract vitals of icu stays with at least one measurement of creatinine or urine output and an AKI label into vitals-kdigo_stages_measured.csv
COPY (
    SELECT *
    FROM mimiciv_icu.vitals
    WHERE stay_id IN (
        SELECT stay_id
        FROM mimiciv_derived.kdigo_stages
        WHERE (
            creat IS NOT NULL
            OR uo_rt_6hr IS NOT NULL
            OR uo_rt_12hr IS NOT NULL
            OR uo_rt_24hr IS NOT NULL
        )
        AND aki_stage IS NOT NULL
        GROUP BY stay_id
        HAVING COUNT(*) > 0
    )
)
TO :'save_path_vitals'
WITH CSV HEADER DELIMITER ';';

-- extract labs of icu stays with at least one measurement of creatinine or urine output and an AKI label into labs-kdigo_stages_measured.csv
COPY (
    SELECT *
    FROM mimiciv_icu.labs
    WHERE stay_id IN (
        SELECT stay_id
        FROM mimiciv_derived.kdigo_stages
        WHERE (
            creat IS NOT NULL
            OR uo_rt_6hr IS NOT NULL
            OR uo_rt_12hr IS NOT NULL
            OR uo_rt_24hr IS NOT NULL
        )
        AND aki_stage IS NOT NULL
        GROUP BY stay_id
        HAVING COUNT(*) > 0
    )
)
TO :'save_path_labs'
WITH CSV HEADER DELIMITER ';';

-- extract ventilations, vasopressor, and sedatives of icu stays with at least one measurement of creatinine or urine output and an AKI label into vents-vasopressor-sedatives-kdigo_stages_measured.csv
COPY (
    SELECT ve.stay_id AS stay_id, ve.charttime AS charttime, vent, vasopressor, sedative
    FROM mimiciv_icu.vent_kdigo_stages_labs_vitals_charttime ve
    JOIN mimiciv_icu.vasopressor_kdigo_stages_labs_vitals_charttime va ON ve.stay_id = va.stay_id AND ve.charttime = va.charttime
    JOIN mimiciv_icu.sedatives_kdigo_stages_labs_vitals_charttime s ON va.stay_id = s.stay_id AND va.charttime = s.charttime
    WHERE ve.stay_id IN (
        SELECT stay_id
        FROM mimiciv_derived.kdigo_stages
        WHERE (
            creat IS NOT NULL
            OR uo_rt_6hr IS NOT NULL
            OR uo_rt_12hr IS NOT NULL
            OR uo_rt_24hr IS NOT NULL
        )
        AND aki_stage IS NOT NULL
        GROUP BY stay_id
        HAVING COUNT(*) > 0
    )
    ORDER BY ve.stay_id, ve.charttime
)
TO :'save_path_vents_vasopressor_sedatives'
WITH CSV HEADER DELIMITER ';';
