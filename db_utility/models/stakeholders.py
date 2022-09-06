from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime, Time, Enum, ForeignKey, Table, CheckConstraint, Boolean, and_
from sqlalchemy.orm import relationship
from models.base import DeclarativeBase
from sqlalchemy.engine.url import URL

from models.Client import Stakeholder_Needs_Panel, Stakeholder_Needs_Objective, Stakeholder_Needs_Subobjective, Client
import xlrd

# from models.django_models import auth_user

import os
import pandas as pd

problem_dir = "/app/vassar/problems"
problems_dir = "/app/vassar/problems"

rule_columns = {
    'panels': 'A:D',
    'objectives': 'F:I',
    'subobjectives': ['K:N', 'P:S', 'U:X', 'Z:AC', 'AE:AH', 'AJ:AM']
}


def index_group_stakeholders(session, data, client):
    problems = ["SMAP", "ClimateCentric"]
    group_id = 1

    

    files = [(problem, problems_dir+'/'+problem+'/xls/Aggregation Rules.xls') for problem in problems]
    for problem, path in files:
        problem_id = client.get_problem_id(problem)
        if problem == 'Decadal2007':
            index_stakeholder_needs_panel(session, data, group_id, problem_id, path)
        else:
            index_stakeholder_needs_panel(session, data, group_id, problem_id, path)

    for problem, path in files:
        problem_id = client.get_problem_id(problem)
        if problem == 'Decadal2007':
            index_stakeholder_needs_objective(session, data, group_id, problem_id, path)
        else:
            index_stakeholder_needs_objective(session, data, group_id, problem_id, path)

    for problem, path in files:
        problem_id = client.get_problem_id(problem)
        if problem == 'Decadal2007':
            index_stakeholder_needs_subobjective(session, data, group_id, problem_id, path)
        else:
            index_stakeholder_needs_subobjective(session, data, group_id, problem_id, path)





# class Stakeholder_Needs_Panel(DeclarativeBase):
#     """Sqlalchemy broad measurement categories model"""
#     __tablename__ = 'Stakeholder_Needs_Panel'
#     id = Column(Integer, primary_key=True)
#     problem_id = Column(Integer, ForeignKey('Problem.id'))
#     name = Column('name', String)
#     description = Column('description', String)
#     weight = Column('weight', Float)
#     index_id = Column('index_id', String, nullable=True)
def index_stakeholder_needs_panel(session, data, group_id, problem_id, path):
    df = pd.read_excel(path, header=1, usecols='A:D')
    df = df.dropna(how='any')
    for index, row in df.iterrows():
        entry = Stakeholder_Needs_Panel(problem_id=problem_id, name=row[0], index_id=row[1], description=row[2], weight=round(float(row[3]), 2))
        session.add(entry)
        session.commit()





def get_panel_id(session, problem_id, index_id):
    panel_id_query = session.query(Stakeholder_Needs_Panel.id, Stakeholder_Needs_Panel.name).filter(and_(Stakeholder_Needs_Panel.index_id == index_id, Stakeholder_Needs_Panel.problem_id == problem_id)).first()
    panel_id = panel_id_query[0]
    return panel_id
def get_num_problem_panels(session, problem_id):
    panel_id_query = session.query(Stakeholder_Needs_Panel.id, Stakeholder_Needs_Panel.name).filter(Stakeholder_Needs_Panel.problem_id == problem_id).all()
    return len(panel_id_query)


# class Stakeholder_Needs_Objective(DeclarativeBase):
#     """Sqlalchemy broad measurement categories model"""
#     __tablename__ = 'Stakeholder_Needs_Objective'
#     id = Column(Integer, primary_key=True)
#     panel_id = Column(Integer, ForeignKey('Stakeholder_Needs_Panel.id'))
#     problem_id = Column(Integer, ForeignKey('Problem.id'))
#     name = Column('name', String)
#     description = Column('description', String)
#     weight = Column('weight', Float)
def index_stakeholder_needs_objective(session, data, group_id, problem_id, path):
    df = pd.read_excel(path, header=1, usecols=rule_columns['objectives'])
    df = df.dropna(how='any')

    df.columns = ['objective_num', 'index_id', 'description', 'weight']
    df = df[ df['objective_num'] != 'Objective' ]

    for index, row in df.iterrows():
        index_id = row[1]
        print(row)
        description = row[2]
        weight = round(float(row[3]), 2)
        foreign_key = get_panel_id(session, problem_id, index_id[0:3])
        entry = Stakeholder_Needs_Objective(panel_id=foreign_key, problem_id=problem_id, name=index_id, description=description, weight=weight)
        session.add(entry)
        session.commit()



def get_objective_id__subobjective(session, name, problem_id):
    objective_id_query = session.query(Stakeholder_Needs_Objective.id, Stakeholder_Needs_Objective.name).filter(and_(Stakeholder_Needs_Objective.name == name, Stakeholder_Needs_Objective.problem_id == problem_id)).first()
    objective_id = objective_id_query[0]
    return objective_id

# class Stakeholder_Needs_Subobjective(DeclarativeBase):
#     """Sqlalchemy broad measurement categories model"""
#     __tablename__ = 'Stakeholder_Needs_Subobjective'
#     id = Column(Integer, primary_key=True)
#     objective_id = Column(Integer, ForeignKey('Stakeholder_Needs_Objective.id'))
#     problem_id = Column(Integer, ForeignKey('Problem.id'))
#     name = Column('name', String)
#     description = Column('description', String)
#     weight = Column('weight', Float)
def index_stakeholder_needs_subobjective(session, data, group_id, problem_id, path):
    num_panels = get_num_problem_panels(session, problem_id)
    temp_range = 1
    for panel in range(num_panels):
        cols = rule_columns['subobjectives'][panel]
        df = pd.read_excel(path, header=1, usecols=cols)
        df = df.dropna(how='any')
        df.columns = ['objective_num', 'index_id', 'description', 'weight']
        df = df[ df['objective_num'] != 'Subobjective' ]

        for index, row in df.iterrows():
            name = row[1]
            objective_name = (name.split('-'))[0]
            description = row[2]
            weight = round(float(row[3]), 2)
            objective_id = get_objective_id__subobjective(session, objective_name, problem_id)
            entry = Stakeholder_Needs_Subobjective(objective_id=objective_id, problem_id=problem_id, name=name, description=description, weight=weight)
            session.add(entry)
            session.commit()
    return 0

def get_subobjective_id(session, name, problem_id):
    subobjective_id_query = session.query(Stakeholder_Needs_Subobjective.id, Stakeholder_Needs_Subobjective.name).filter(and_(Stakeholder_Needs_Subobjective.name == name, Stakeholder_Needs_Subobjective.problem_id == problem_id)).first()
    subobjective_id = subobjective_id_query[0]
    return subobjective_id