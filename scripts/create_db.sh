# install dependencies
echo "--------------------Installing dependencies--------------------"
apt-get update -y
apt install git-all wget -y
# clone repo
echo "--------------------Cloning repo--------------------"
git -C "mimic-code" pull || git clone https://github.com/MIT-LCP/mimic-code.git "mimic-code"
# Make sure we use the last tested version of the DB sql scripts
git checkout e58eca
cd mimic-code
# download data
echo "--------------------Downloading MIMIC IV Data--------------------"
wget -r -N -c -np --user $MIMIC_USER --password $MIMIC_PASSWORD https://physionet.org/files/mimiciv/2.2/
cp -r physionet.org/files/mimiciv mimiciv && rmdir physionet.org/files && rm physionet.org/robots.txt && rmdir physionet.org
# createdb mimiciv_db
echo "--------------------Creating Database--------------------"
psql -d mimiciv_db -f mimic-iv/buildmimic/postgres/create.sql
psql -d mimiciv_db -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/2.2 -f mimic-iv/buildmimic/postgres/load_gz.sql
psql -d mimiciv_db -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/2.2 -f mimic-iv/buildmimic/postgres/constraint.sql
psql -d mimiciv_db -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/2.2 -f mimic-iv/buildmimic/postgres/index.sql
# Add the concepts materialized views
echo "--------------------Adding materialized views--------------------"
# cd mimic-iv/concepts_postgres
cd /mimic/scripts/concepts_postgres
psql -d mimiciv_db -v ON_ERROR_STOP=1 -v mimic_data_dir=mimiciv/2.2 -f postgres-make-concepts.sql
