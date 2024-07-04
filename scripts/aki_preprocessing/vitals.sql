-- This query pivots the vital signs for the first 24 hours of a patient's stay
-- Vital signs include heart rate, blood pressure, respiration rate, and temperature

SET search_path TO mimiciv_icu;
DROP MATERIALIZED VIEW IF EXISTS vitals CASCADE;
CREATE MATERIALIZED VIEW vitals AS
SELECT pvt.subject_id, pvt.hadm_id, pvt.stay_id, pvt.charttime

-- Easier names
-- Aggregate functions not really useful as there is one value per variable
-- at the same timestamp
, MIN(CASE WHEN VitalID = 1 THEN valuenum ELSE NULL END) AS HeartRate_Min
, MAX(CASE WHEN VitalID = 1 THEN valuenum ELSE NULL END) AS HeartRate_Max
, AVG(CASE WHEN VitalID = 1 THEN valuenum ELSE NULL END) AS HeartRate_Mean
, MIN(CASE WHEN VitalID = 2 THEN valuenum ELSE NULL END) AS SysBP_Min
, MAX(CASE WHEN VitalID = 2 THEN valuenum ELSE NULL END) AS SysBP_Max
, AVG(CASE WHEN VitalID = 2 THEN valuenum ELSE NULL END) AS SysBP_Mean
, MIN(CASE WHEN VitalID = 3 THEN valuenum ELSE NULL END) AS DiasBP_Min
, MAX(CASE WHEN VitalID = 3 THEN valuenum ELSE NULL END) AS DiasBP_Max
, AVG(CASE WHEN VitalID = 3 THEN valuenum ELSE NULL END) AS DiasBP_Mean
, MIN(CASE WHEN VitalID = 4 THEN valuenum ELSE NULL END) AS MeanBP_Min
, MAX(CASE WHEN VitalID = 4 THEN valuenum ELSE NULL END) AS MeanBP_Max
, AVG(CASE WHEN VitalID = 4 THEN valuenum ELSE NULL END) AS MeanBP_Mean
, MIN(CASE WHEN VitalID = 5 THEN valuenum ELSE NULL END) AS RespRate_Min
, MAX(CASE WHEN VitalID = 5 THEN valuenum ELSE NULL END) AS RespRate_Max
, AVG(CASE WHEN VitalID = 5 THEN valuenum ELSE NULL END) AS RespRate_Mean
, MIN(CASE WHEN VitalID = 6 THEN valuenum ELSE NULL END) AS TempC_Min
, MAX(CASE WHEN VitalID = 6 THEN valuenum ELSE NULL END) AS TempC_Max
, AVG(CASE WHEN VitalID = 6 THEN valuenum ELSE NULL END) AS TempC_Mean
, MIN(CASE WHEN VitalID = 7 THEN valuenum ELSE NULL END) AS SpO2_Min
, MAX(CASE WHEN VitalID = 7 THEN valuenum ELSE NULL END) AS SpO2_Max
, AVG(CASE WHEN VitalID = 7 THEN valuenum ELSE NULL END) AS SpO2_Mean
, MIN(CASE WHEN VitalID = 8 THEN valuenum ELSE NULL END) AS Glucose_Min
, MAX(CASE WHEN VitalID = 8 THEN valuenum ELSE NULL END) AS Glucose_Max
, AVG(CASE WHEN VitalID = 8 THEN valuenum ELSE NULL END) AS Glucose_Mean

FROM  (
  SELECT ie.subject_id, ie.hadm_id, ie.stay_id, ce.charttime
  , CASE
    WHEN itemid IN (211,220045) AND valuenum > 0 AND valuenum < 300 THEN 1 -- HeartRate
    WHEN itemid IN (51,442,455,6701,220179,220050) AND valuenum > 0 AND valuenum < 400 THEN 2 -- SysBP
    WHEN itemid IN (8368,8440,8441,8555,220180,220051) AND valuenum > 0 AND valuenum < 300 THEN 3 -- DiasBP
    WHEN itemid IN (456,52,6702,443,220052,220181,225312) AND valuenum > 0 AND valuenum < 300 THEN 4 -- MeanBP
    WHEN itemid IN (615,618,220210,224690) AND valuenum > 0 AND valuenum < 70 THEN 5 -- RespRate
    WHEN itemid IN (223761,678) AND valuenum > 70 AND valuenum < 120  THEN 6 -- TempF, converted to degC in valuenum call
    WHEN itemid IN (223762,676) AND valuenum > 10 AND valuenum < 50  THEN 6 -- TempC
    WHEN itemid IN (646,220277) AND valuenum > 0 AND valuenum <= 100 THEN 7 -- SpO2
    WHEN itemid IN (807,811,1529,3745,3744,225664,220621,226537) AND valuenum > 0 THEN 8 -- Glucose
    ELSE NULL END AS VitalID
      -- convert F to C
  , CASE WHEN itemid IN (223761,678) THEN (valuenum-32)/1.8 ELSE valuenum END AS valuenum

  FROM mimiciv_icu.icustays ie
  LEFT JOIN mimiciv_icu.chartevents ce
  ON ie.stay_id = ce.stay_id
  -- exclude rows marked as error
  --AND ce.error IS DISTINCT FROM 1
  WHERE ce.itemid IN
  (
  -- HEART RATE
  211, --"Heart Rate"
  220045, --"Heart Rate"

  -- Systolic/diastolic

  51, --	Arterial BP [Systolic]
  442, --	Manual BP [Systolic]
  455, --	NBP [Systolic]
  6701, --	Arterial BP #2 [Systolic]
  220179, --	Non Invasive Blood Pressure systolic
  220050, --	Arterial Blood Pressure systolic

  8368, --	Arterial BP [Diastolic]
  8440, --	Manual BP [Diastolic]
  8441, --	NBP [Diastolic]
  8555, --	Arterial BP #2 [Diastolic]
  220180, --	Non Invasive Blood Pressure diastolic
  220051, --	Arterial Blood Pressure diastolic


  -- MEAN ARTERIAL PRESSURE
  456, --"NBP Mean"
  52, --"Arterial BP Mean"
  6702, --	Arterial BP Mean #2
  443, --	Manual BP Mean(calc)
  220052, --"Arterial Blood Pressure mean"
  220181, --"Non Invasive Blood Pressure mean"
  225312, --"ART BP mean"

  -- RESPIRATORY RATE
  618,--	Respiratory Rate
  615,--	Resp Rate (Total)
  220210,--	Respiratory Rate
  224690, --	Respiratory Rate (Total)


  -- SPO2, peripheral
  646, 220277,

  -- GLUCOSE, both lab and fingerstick
  807,--	Fingerstick Glucose
  811,--	Glucose (70-105)
  1529,--	Glucose
  3745,--	BloodGlucose
  3744,--	Blood Glucose
  225664,--	Glucose finger stick
  220621,--	Glucose (serum)
  226537,--	Glucose (whole blood)

  -- TEMPERATURE
  223762, -- "Temperature Celsius"
  676,	-- "Temperature C"
  223761, -- "Temperature Fahrenheit"
  678 --	"Temperature F"

  )
) pvt
GROUP BY pvt.subject_id, pvt.hadm_id, pvt.stay_id, pvt.charttime
ORDER BY pvt.subject_id, pvt.hadm_id, pvt.stay_id, pvt.charttime;
