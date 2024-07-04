cd /mimic/scripts/aki_preprocessing
psql -d mimiciv_db -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/2.2 -f labs.sql
psql -d mimiciv_db -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/2.2 -f sedativedurations.sql
psql -d mimiciv_db -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/2.2 -f vitals.sql
psql -d mimiciv_db -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/2.2 -f sedatives_at_kdigo_stages_labs_vitals_charttime.sql
psql -d mimiciv_db -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/2.2 -f vasopressor_at_kdigo_stages_labs_vitals_charttime.sql
psql -d mimiciv_db -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/2.2 -f ventilations_at_kdigo_stages_labs_vitals_charttime.sql
psql -d mimiciv_db -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/2.2 -f extract_data.sql
