from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime, Time, Enum, ForeignKey, Table, CheckConstraint, Boolean
from sqlalchemy.orm import relationship
from models.base import DeclarativeBase
from sqlalchemy.engine.url import URL

from models.django_models import auth_user

import os
import pandas as pd


#################################
### Tables not in excel files ###
#################################



class Group(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Group'
    id = Column(Integer, primary_key=True)
    name = Column('name', String)
def create_group(session, name):
    entry = Group(name=name)
    session.add(entry)
    session.commit()
    return entry.id
def create_default_group(session, problems, name='seakers (default)'):
    group_id = create_group(session, name)
    for problem in problems:
        problem_id = get_problem_id(session, problem)
        entry = Join__Problem_Group(problem_id=problem_id, group_id=group_id)
        session.add(entry)
        session.commit()
    relate_users_to_group(session, group_id)
    return group_id
def relate_users_to_group(session, group_id):
    user_query = session.query(auth_user.id).all()
    print("ALL USERS", user_query)
    for user in user_query:
        user_id = user[0]
        entry = Join__AuthUser_Group(user_id=user_id, group_id=group_id, admin=False)
        session.add(entry)
        session.commit()


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



class Join__AuthUser_Group(DeclarativeBase):
    __tablename__ = 'Join__AuthUser_Group'
    id = Column(Integer, primary_key=True)
    user_id = Column('user_id', Integer, ForeignKey('auth_user.id'))
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    admin = Column('admin', Boolean, default=False)
class Join__Problem_Group(DeclarativeBase):
    __tablename__ = 'Join__Problem_Group'
    id = Column(Integer, primary_key=True)
    problem_id = Column('problem_id', Integer, ForeignKey('Problem.id'))
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))


















