
The code in this directory is based on the [MIMIC IV postgresql concepts](https://github.com/MIT-LCP/mimic-code/tree/main/mimic-iv/concepts_postgres), modifying the line in [icustay_hourly](scripts/concepts_postgres/demographics/icustay_hourly.sql) so it does not crash the [concept creation script](scripts/concepts_postgres/postgres-make-concepts.sql) when run.

# PostgreSQL concepts

This folder contains scripts to generate useful abstractions of raw MIMIC-IV data ("concepts"). The
scripts are intended to be run against the MIMIC-IV data in a PostgreSQL database.
If you would like to contribute a correction, it should be for the corresponding file in the concepts folder.

To generate concepts, change to this directory and run `psql`. Then within psql, run:

```sql
\i postgres-make-concepts.sql
```

... or, run the SQL files in your GUI of choice.

The postgres-functions.sql contains definitions for a few functions which exist in BigQuery but do not exist in PostgreSQL. It is not required but these functions are convenient if you find yourself switching back and forth between the two.
