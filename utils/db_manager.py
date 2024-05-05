import logging
import os

import pandas as pd
import psycopg2

from utils.logger import get_logger


class MimicDBManager:
    def __init__(self, logger: logging.Logger = get_logger("MimicManager"), port: int = 5432):
        self.logger = logger
        self.host = os.environ.get("POSTGRES_HOST")
        self.database = os.environ.get("POSTGRES_DB")
        self.user = os.environ.get("POSTGRES_USER")
        self.password = os.environ.get("POSTGRES_PASSWORD")
        self.port = str(port)

        self.conn = None
        self.generate_connection()

    def rollback(self):
        self.generate_connection()
        cur = self.conn.cursor()
        cur.execute("ROLLBACK")
        cur.close()
        self.commit_connection()

    def generate_connection(self):
        if self.conn is None:
            self.logger.info("Creating connection to PostgreSQL")
            self.conn = psycopg2.connect(
                host=self.host, database=self.database, user=self.user, password=self.password, port=self.port
            )
        return self.conn

    def retrieve_column_names(self, table_name: str, ignore_id: bool = True) -> list:
        return list(self.retrieve_column_types(table_name, ignore_id).keys())

    def retrieve_column_types(self, table_name: str, ignore_id: bool = True) -> dict:
        if self.table_exists(table_name):
            self.generate_connection()
            query = (
                f"""SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '{table_name}';"""
            )
            cur = self.conn.cursor()
            cur.execute(query)
            response = cur.fetchall()
            cur.close()
            # response = [resp[0] for resp in response]
            if ignore_id:
                response = [resp for resp in response if resp[0] != "id"]
        else:
            response = []
        return dict(response)

    def commit_connection(self):
        if self.conn is not None:
            self.conn.commit()

    def close_connection(self):
        if self.conn is not None:
            self.logger.info("Closing connection to Postgresql")
            self.conn.close()

    # def insert_row(self, table_name: str, args_dict: dict):
    #     args_dict_lowercase = {str(k).lower(): v for k, v in args_dict.items()}
    #     if self.table_exists(table_name):
    #         columns = self.retrieve_column_names(table_name)
    #         self.generate_connection()
    #         query = f"INSERT INTO {table_name} ({', '.join(columns)}) VALUES ({', '.join(['%s' for _ in columns])})"
    #         cur = self.conn.cursor()
    #         args_list_ordered = [args_dict_lowercase[arg] for arg in columns]
    #         cur.execute(query, args_list_ordered)
    #         cur.close()
    #         self.commit_connection()

    def retrieve_data(self, table_name: str, id_column: str) -> dict:
        if self.table_exists(table_name):
            query = f"SELECT * from {table_name}"
            df = pd.read_sql_query(query, self.generate_connection())
            df = df.set_index(id_column)
        else:
            df = pd.DataFrame()
        return df

    def __retrieve_data(self, sql_query, id_column) -> pd.DataFrame:
        df = pd.read_sql_query(sql_query, self.generate_connection())
        df = df.set_index(id_column)
        return df

    def retrieve_rows(self, table_name: str, id_column: str, limit: int = 100, offset: int = 0) -> dict:
        if self.table_exists(table_name):
            query = f"SELECT * from {table_name} LIMIT {limit} OFFSET {offset}"
            df = self.__retrieve_data(query, id_column)
        else:
            df = pd.DataFrame()
        return df

    def retrieve_id(self, table_name: str, id: int, id_column: str) -> dict:
        if self.table_exists(table_name):
            query = f"SELECT * from {table_name} WHERE {id_column}={id}"
            df = self.__retrieve_data(query, id_column)
        else:
            df = pd.DataFrame()
        return df

    def retrieve_table_names(self) -> list:
        query = """SELECT table_schema, table_name
                    FROM information_schema.tables
                    WHERE table_schema IN ('mimiciv_icu', 'mimiciv_hosp', 'public')"""
        self.generate_connection()
        cur = self.conn.cursor()
        cur.execute(query)
        response = cur.fetchall()
        cur.close()
        return [f"{resp[0]}.{resp[1]}" for resp in response]

    def table_exists(self, table_name: str) -> bool:
        table_schema_split, table_name_split = table_name.split(".")
        table_existence_command = f"""
                                    SELECT EXISTS (
                                        SELECT 1
                                        FROM information_schema.tables
                                        WHERE table_schema ='{table_schema_split}'
                                        AND table_name = '{table_name_split}'
                                    );
                                    """
        self.generate_connection()
        cur = self.conn.cursor()
        cur.execute(table_existence_command)
        response = cur.fetchall()
        cur.close()
        return response[0][0]

    def retrieve_all(self, table_name: str) -> list:
        if self.table_exists(table_name):
            self.generate_connection()
            cur = self.conn.cursor()
            cur.execute(f"SELECT * FROM {table_name}")
            response = cur.fetchall()
            cur.close()
        else:
            response = []
        return response

    def count_rows(self, table_name: str) -> int:
        if self.table_exists(table_name):
            self.generate_connection()
            cur = self.conn.cursor()
            cur.execute(f"SELECT COUNT(*) FROM {table_name}")
            response = cur.fetchall()[0][0]
            cur.close()
        else:
            response = 0
        return response
