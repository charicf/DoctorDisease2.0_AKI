#!make

SHELL := /bin/bash

BLUE="\033[00;94m"
GREEN="\033[00;92m"
RED="\033[00;31m"
RESTORE="\033[0m"
YELLOW="\033[00;93m"
CYAN="\e[0;96m"
GREY="\e[2:N"
SPACER="----------"
DONE_MSG = ${GREEN} ${SPACER} Done ${SPACER} ${RESTORE}

LOCAL_ENV_PATH=.envs/local/local.env

define setup_env
	$(eval ENV_FILE := .envs/$(1)/$(1).env)
	@@echo -e ${YELLOW} " - setup env $(ENV_FILE)" ${RESTORE}
	$(eval include .envs/$(1)/$(1).env)
	$(eval export sed 's/=.*//' .envs/$(1)/$(1).env)
endef

create_mlflow_bucket:
# To be run inside MinIO to create a bucket, or ignore if it already exists
	mc alias set s3 http://localhost:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD
	mc mb s3/$AWS_S3_BUCKET_NAME --ignore-existing --region $MINIO_REGION

mlflow_bucket:
	source .env
	docker compose run --rm create_buckets

test_debug:
	conda run --no--capture--output -n test coverage run -m pytest
	conda run --no--capture--output -n test coverage html -d /app/test/coverage_report

coverage_report:
	@echo -e ${YELLOW} ${SPACER} Running unit tests... ${SPACER} ${RESTORE}
	docker compose run --rm test bash -c "make test_debug"

build_project_local:
	@echo -e ${YELLOW} ${SPACER} Building project locally ${SPACER} ${RESTORE}
	docker compose --env-file ${LOCAL_ENV_PATH} build minio mlflow
	docker compose run --rm create_buckets
	@echo -e ${DONE_MSG}

build_mimic_database_local:
	@echo -e ${YELLOW} ${SPACER} Building mimic database locally ${SPACER} ${RESTORE}
	docker compose --env-file ${LOCAL_ENV_PATH} --env-file .envs/mimic.env up -d data_postgresql_mimic
	docker compose --env-file ${LOCAL_ENV_PATH} --env-file .envs/mimic.env exec -w /mimic data_postgresql_mimic  bash create_db.sh
	@echo -e ${DONE_MSG}

remove_mimic_database_local:
	$(call setup_env,local)
	@echo -e ${RED} ${SPACER} WARNING: Removing local mimic database and named volume: ${MIMIC_POSTGRES_DB} ${SPACER} ${RESTORE}
	@sleep 10
	docker compose rm -sf data_postgresql_mimic
	docker volume rm ${MIMIC_POSTGRES_DB}
	@echo -e ${DONE_MSG}

rebuild_mimic_database_local:
	make remove_mimic_database_local
	make build_mimic_database_local

startup_project_local:
	@echo -e ${YELLOW} ${SPACER}  Building project locally ${SPACER} ${RESTORE}
	docker compose --env-file ${LOCAL_ENV_PATH} up -d minio mlflow ml_model_api data_api
	docker compose --env-file ${LOCAL_ENV_PATH} run --rm create_buckets
	# docker compose --env-file ${LOCAL_ENV_PATH} run --rm data_api sh -c "conda run --no-capture-output -n fastapi python utils/database_initalization.py"
	@echo -e ${DONE_MSG}

run_ml_model_local:
	@echo -e ${YELLOW} ${SPACER} Running ML model locally ${SPACER} ${RESTORE}
	docker compose --env-file ${LOCAL_ENV_PATH} up ml_model_train_cpu
	@echo -e ${DONE_MSG}

deploy_local_ml_dev:
	@echo -e ${YELLOW} ${SPACER} Running ML model dev environment locally ${SPACER}  ${RESTORE}
	docker compose --env-file ${LOCAL_ENV_PATH} up -d ml_model_dev_cpu
	@echo -e ${DONE_MSG}

redeploy_local_ml_dev:
	@echo -e ${RED} ${SPACER} WARNING: Recreating local ML model dev environment ${SPACER}  ${RESTORE}
	@sleep 10
	docker compose rm -sf ml_model_dev_cpu
	make deploy_local_ml_dev

deploy_local:
	cp ${LOCAL_ENV_PATH} .env
	make build_project_local
	make startup_project_local
	@echo -e ${YELLOW} ${SPACER} Wait 5 seconds for everything to be set up correctly... ${SPACER} ${RESTORE}
	sleep 5
	# make run_ml_model_local
	rm .env
