# mimic-iv

# Running the project locally
The majority of the configuration can be found on the [project makefile](Makefile). The local environment variables are stored in the [local env file](.envs/local/local.env), whereas the [mimic env file](.envs/mimic.env) should contain the user and password for
## MIMIC DB startup
To initialize the database locally, you can run:
```
make build_mimic_database_local
```

Make sure that the [mimic information env file](.envs/mimic.env), has the required username and password environment variables set.

What this code does is basically an implementation of the code found in the [Mimic-IV database initalization repo](https://github.com/MIT-LCP/mimic-code/tree/main/mimic-iv/buildmimic/postgres) modified so it can run in a docker container.

## Accessing the database
The database can then be used directly by accessing through [http://localhost:5454](http://localhost:5454) or using the development instance by starting it up with:
```
make deploy_local_ml_dev
```

This container in turn is able to access the database through [http://data_postgresql_mimic:5432](http://data_postgresql_mimic:5432) . A working example that queries all of the tables in the database can be seen in the [EDA file](ml_model/EDA/mimic_iv_eda.ipynb)
