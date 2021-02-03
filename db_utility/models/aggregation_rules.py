from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime, Time, Enum, ForeignKey, Table, CheckConstraint, and_
from sqlalchemy.orm import relationship
from models.base import DeclarativeBase
from sqlalchemy.engine.url import URL
import numpy as np
import pandas as pd
from models.models import Problem, get_problem_id




#######
### AggregationRules.xls - completed
#######



# For each panel, there exists a column of subobjectives
rule_columns = {
    'panels': 'A:D',
    'objectives': 'F:I',
    'subobjectives': ['K:N', 'P:S', 'U:X', 'Z:AC', 'AE:AH']
}


########################################################################################
# For all rows that have the same foreign key: the summation of their weights must = 1 #
########################################################################################

# --------------------------------> AggregationRules.xls
class Stakeholder_Needs_Panel(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Stakeholder_Needs_Panel'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problem.id'))
    name = Column('name', String)
    description = Column('description', String)
    weight = Column('weight', Float)
    index_id = Column('index_id', String, nullable=True)
def index_stakeholder_needs_panel(problems_dir, session, problem_name):  
    problem_dir = problems_dir + '/' + problem_name + '/xls' # /app/vassar_resources/problems/SMAP/xls
    file_path = problem_dir + '/Aggregation Rules.xls'       # /app/vassar_resources/problems/SMAP/xls/Aggregation Rules.xls
    print("Indexing aggregation objectives from", file_path)

    # Get DataFrame
    df = pd.read_excel(file_path, header=1, usecols='A:D')
    pruned_df = df.dropna(how='any')

    # Get foreign key: Problem.id
    foreign_key = get_problem_id(session, problem_name)

    # Index rows in database
    for index, row in pruned_df.iterrows():
        entry = Stakeholder_Needs_Panel(problem_id=foreign_key, name=row[0], index_id=row[1], description=row[2], weight=float(row[3]))
        session.add(entry)
        session.commit()
def get_panel_id(session, problem_id, index_id):
    panel_id_query = session.query(Stakeholder_Needs_Panel.id, Stakeholder_Needs_Panel.name).filter(and_(Stakeholder_Needs_Panel.index_id == index_id, Stakeholder_Needs_Panel.problem_id == problem_id)).first()
    panel_id = panel_id_query[0]
    return panel_id
def get_num_problem_panels(session, problem_id):
    panel_id_query = session.query(Stakeholder_Needs_Panel.id, Stakeholder_Needs_Panel.name).filter(Stakeholder_Needs_Panel.problem_id == problem_id).all()
    return len(panel_id_query)


        
class Stakeholder_Needs_Objective(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Stakeholder_Needs_Objective'
    id = Column(Integer, primary_key=True)
    panel_id = Column(Integer, ForeignKey('Stakeholder_Needs_Panel.id'))
    problem_id = Column(Integer, ForeignKey('Problem.id'))
    name = Column('name', String)
    description = Column('description', String)
    weight = Column('weight', Float)
def index_stakeholder_needs_objective(problems_dir, session, problem_name):  # problems_dir: directory to the problems --> problem_dir = "/app/vassar_resources/problems"
    problem_dir = problems_dir + '/' + problem_name + '/xls'  # /app/vassar_resources/problems/SMAP/xls
    file_path = problem_dir + "/Aggregation Rules.xls"        # /app/vassar_resources/problems/SMAP/xls/Aggregation Rules.xls
    print("Indexing aggregation objectives from", file_path)

    # Get the problem ID from the Problems table
    problem_id = get_problem_id(session, problem_name)

    # Get DataFrame
    df = pd.read_excel(file_path, header=1, usecols=rule_columns['objectives'])
    df = df.dropna(how='any')
    print(df)
    df.columns = ['objective_num', 'index_id', 'description', 'weight']
    df = df[ df['objective_num'] != 'Objective' ]
    print(df)

    for index, row in df.iterrows():
        index_id = row[1]
        print(row)
        description = row[2]
        weight = float(row[3])
        foreign_key = get_panel_id(session, problem_id, index_id[0:3])
        entry = Stakeholder_Needs_Objective(panel_id=foreign_key, problem_id=problem_id, name=index_id, description=description, weight=weight)
        session.add(entry)
        session.commit()
def get_objectgive_id__subobjective(session, name, problem_id):
    objective_id_query = session.query(Stakeholder_Needs_Objective.id, Stakeholder_Needs_Objective.name).filter(and_(Stakeholder_Needs_Objective.name == name, Stakeholder_Needs_Objective.problem_id == problem_id)).first()
    objective_id = objective_id_query[0]
    return objective_id



class Stakeholder_Needs_Subobjective(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Stakeholder_Needs_Subobjective'
    id = Column(Integer, primary_key=True)
    objective_id = Column(Integer, ForeignKey('Stakeholder_Needs_Objective.id'))
    problem_id = Column(Integer, ForeignKey('Problem.id'))
    name = Column('name', String)
    description = Column('description', String)
    weight = Column('weight', Float)
def index_stakeholder_needs_subobjective(problems_dir, session, problem_name):
    problem_dir = problems_dir + '/' + problem_name + '/xls'  # /app/vassar_resources/problems/SMAP/xls
    file_path = problem_dir + "/Aggregation Rules.xls"        # /app/vassar_resources/problems/SMAP/xls/Aggregation Rules.xls

    # Get the problem ID from the Problems table
    problem_id = get_problem_id(session, problem_name)

    # Get the number of panels
    num_panels = get_num_problem_panels(session, problem_id)
    temp_range = 1

    for panel in range(num_panels):
        cols = rule_columns['subobjectives'][panel]
        df = pd.read_excel(file_path, header=1, usecols=cols)
        df = df.dropna(how='any')
        df.columns = ['objective_num', 'index_id', 'description', 'weight']
        df = df[ df['objective_num'] != 'Subobjective' ]
        print(df)

        for index, row in df.iterrows():
            name = row[1]
            objective_name = (name.split('-'))[0]
            description = row[2]
            weight = float(row[3])
            objective_id = get_objectgive_id__subobjective(session, objective_name, problem_id)
            entry = Stakeholder_Needs_Subobjective(objective_id=objective_id, problem_id=problem_id, name=name, description=description, weight=weight)
            session.add(entry)
            session.commit()
    return 0