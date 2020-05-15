from sqlalchemy import create_engine, MetaData, Table
from sqlalchemy.orm import sessionmaker, mapper

from models_arch.base import DeclarativeBase

from models.models import Problem
from models.models import index_problems, create_default_group

from models.aggregation_rules import index_stakeholder_needs_panel, index_stakeholder_needs_objective, index_stakeholder_needs_subobjective
from models.requirement_rules import index_requirement_rules
from models.mission_analysis_database import index_launch_vehicle_mission_analysis, index_power_mission_analysis, index_walker_mission_analysis
from models.attribute_set import index_mission_attribute, index_orbit_attribute, index_measurement_attribute, index_launch_vehicle_attribute, index_instrument_attribute, index_inheritence_attribute, index_fuzzy_attribute
from models.mission_analysis_database import index_walker_mission_analysis, index_power_mission_analysis, index_launch_vehicle_mission_analysis
from models.instrument_capability_definitions import create_default_instruments


from models_arch.globals import index_group_globals
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
    DeclarativeBase.metadata.drop_all(engine)
    tables = engine.table_names()
    return tables

def load_session():
    engine = db_connect()
    Session = sessionmaker(bind=engine)
    session = Session()
    return session


def index_vassar():
    session = load_session()
    

    problems = index_problems(problem_dir, session)
    default_group_id = create_default_group(session, problems)

    

    for problem in problems:
        index_stakeholder_needs_panel(problem_dir, session, problem)

    for problem in problems:
        index_stakeholder_needs_objective(problem_dir, session, problem)

    for problem in problems:
        index_stakeholder_needs_subobjective(problem_dir, session, problem)

    for problem in problems:
        index_requirement_rules(problem_dir, session, problem)


    # Attributes
    index_mission_attribute(problem_dir, session, problems)
    index_orbit_attribute(problem_dir, session, problems)
    index_measurement_attribute(problem_dir, session, problems)
    index_launch_vehicle_attribute(problem_dir, session, problems)
    index_instrument_attribute(problem_dir, session, problems)
    index_inheritence_attribute(problem_dir, session, problems)
    index_fuzzy_attribute(problem_dir, session, problems)


    create_default_instruments(session, problem_dir, problems,  default_group_id)

    # Mission Analysis
    index_walker_mission_analysis(problem_dir, session, problems)
    index_power_mission_analysis(problem_dir, session, problems)
    index_launch_vehicle_mission_analysis(problem_dir, session, problems)
    

    


def create_vassar_group(name='seakers (default)'):
    print('Indexing Group', name)
    session = load_session()

    data = index_group_globals(session, name)
    index_group_stakeholders(session, data)
    index_group_problems(session, data)



if __name__ == "__main__":
    # print(drop_tables())
    print(create_tables())
    # index_vassar()
    create_vassar_group()
    
