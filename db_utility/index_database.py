from sqlalchemy import create_engine, MetaData, Table
from sqlalchemy.orm import sessionmaker, mapper

from models_arch.base import DeclarativeBase


from models_arch.globals import index_group_globals, index_fuzzy_attribute_arch
from models_arch.problem_specific import index_group_problems
from models_arch.stakeholders import index_group_stakeholders

import os
import pandas as pd

user = os.environ['USER']
password = os.environ['PASSWORD']
postgres_host = os.environ['POSTGRES_HOST']
postgres_port = os.environ['POSTGRES_PORT']
vassar_db_name = 'daphne'

db_string = f'postgresql+psycopg2://{user}:{password}@{postgres_host}:{postgres_port}/{vassar_db_name}'
problem_dir = "/app/daphne/VASSAR_resources/problems"




def db_connect():
    return create_engine(db_string, echo=True)

def create_tables():
    engine = db_connect()
    DeclarativeBase.metadata.create_all(engine)
    tables = engine.table_names()
    return tables

def drop_tables():
    engine = db_connect()
    to_delete = []
    for table, table_obj in DeclarativeBase.metadata.tables.items():
        print(table, '\n')
        if table is not 'auth_user':
            to_delete.append(table_obj)
    DeclarativeBase.metadata.drop_all(engine, to_delete)
    tables = engine.table_names()
    return tables

def load_session():
    engine = db_connect()
    Session = sessionmaker(bind=engine)
    session = Session()
    return session




def create_vassar_group(name='seakers (default)'):
    print('Indexing Group', name)

    # LOAD SESSION
    session = load_session()

    # INDEX GROUP GLOBALS
    data = index_group_globals(session, name)

    # INDEX STAKEHOLDERS
    index_group_stakeholders(session, data)

    #
    index_group_problems(session, data)

    problems = os.listdir(problem_dir)
    index_fuzzy_attribute_arch(problem_dir, session, problems)

    





if __name__ == "__main__":
    print(drop_tables())
    print(create_tables())
    create_vassar_group()
    
