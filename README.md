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

## Creating the MIMIC IV Augmented data
By running the command:
```
make create_augmented_data
```
The system will create/recreate the data preprocessing and modification process to create the input data for the [LSTM Preprocessing step](ml_model/preprocessing.ipynb)

## LSTM Preprocessed Data
Extra preprocessing needs to be done on the data after it is passed through the augmentation step. This can be achieved by running the [LSTM Preprocessing python notebook](ml_model/preprocessing.ipynb)

## Training the model
After the LSTM data has been preprocessed, the model can be trained by running the [LSTM Features python notebook](ml_model/LSTM_features.ipynb). This in turn will create the features-only version of the ML model designed by Vagliano, Hsu, and Schut (2022).

## Explaining the Model


# Troubleshooting
## Rebuilding the Mimic DB
To rebuild the database locally, you can run:
```
make rebuild_mimic_database_local
```
This will recreate the database by deleting its docker volume and recreating the database container. It will not delete the already downloaded data, just the database.

# Acknowledgement
Part of the code used in this repo is based on the work done by Vagliano, Hsu, and Schut as described in:

[Machine Learning, Clinical Notes and Knowledge Graphs for Early Prediction of Acute Kidney Injury in the Intensive Care](https://ebooks.iospress.nl/doi/10.3233/SHTI210926):

    @inproceedings{Vagliano:2021,
         author = {Vagliano, Iacopo and Hsu, Wei-Hsiang and Schut, Martijn C},
         title = {Machine Learning, Clinical Notes and Knowledge Graphs for Early Prediction of Acute Kidney Injury in the Intensive Care},
         booktitle = {Informatics and Technology in Clinical Care and Public Health},
         series = {Studies in health technology and informatics},
         pages = {329--332},
         DOI = {10.3233/SHTI210926},
         volume = {289},
         year = {2022},
         URL = {https://doi.org/10.3233/SHTI210926},
    }

More information can be found in the [ml model README](ml_model/README.md)
