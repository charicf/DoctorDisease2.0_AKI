# install dependencies
apt-get update -y
apt install git-all wget -y
# clone repo
git -C "mimic-code" pull || git clone https://github.com/MIT-LCP/mimic-code.git "mimic-code"
cd mimic-code
# download data
wget -r -N -c -np --user $MIMIC_USER --password $MIMIC_PASSWORD https://physionet.org/files/mimiciv/2.2/
cp -r physionet.org/files/mimiciv mimiciv && rmdir physionet.org/files && rm physionet.org/robots.txt && rmdir physionet.org
# createdb mimiciv_db
psql -d mimiciv_db -f mimic-iv/buildmimic/postgres/create.sql
psql -d mimiciv_db -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/2.2 -f mimic-iv/buildmimic/postgres/load_gz.sql
psql -d mimiciv_db -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/2.2 -f mimic-iv/buildmimic/postgres/constraint.sql
psql -d mimiciv_db -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/2.2 -f mimic-iv/buildmimic/postgres/index.sql
