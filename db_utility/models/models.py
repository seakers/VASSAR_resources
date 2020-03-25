from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime, Time, Enum, ForeignKey, Table, CheckConstraint
from sqlalchemy.orm import relationship
from models.base import DeclarativeBase
from sqlalchemy.engine.url import URL

import os
import pandas as pd


#################################
### Tables not in excel files ###
#################################


# This will just be our UserInformation table
class User(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'User'
    id = Column(Integer, primary_key=True)
    name = Column('name', String)
    password = Column('password', String)

class Group(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Group'
    id = Column(Integer, primary_key=True)
    name = Column('name', String)

class Problem(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Problem'
    id = Column(Integer, primary_key=True)
    name = Column('name', String)
def index_problems(problem_dir, session):
    print("Indexing problems from:", problem_dir)
    problems = os.listdir(problem_dir)
    for problem in problems:
        entry = Problem(name=problem)
        session.add(entry)
        session.commit()
    for instance in session.query(Problem):
        print(instance.name, instance.id)
    return problems
def get_problem_id(session, problem_name):
    problem_id_query = session.query(Problem.id, Problem.name).filter(Problem.name == problem_name).first()
    problem_id = problem_id_query[0]
    print("Found problem ID", problem_name, problem_id)
    return problem_id



User_Group_Join = Table('User_Group_Join', DeclarativeBase.metadata,
                        Column('user_id', Integer, ForeignKey('User.id')),
                        Column('group_id', Integer, ForeignKey('Group.id')))

Group_Problem_Join = Table('Group_Problem_Join', DeclarativeBase.metadata,
                        Column('group_id', Integer, ForeignKey('Group.id')),
                        Column('problem_id', Integer, ForeignKey('Problem.id')))



















