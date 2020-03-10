from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime, Time, Enum, ForeignKey, Table, CheckConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.engine.url import URL
import os

DeclarativeBase = declarative_base()

# --------------------------------> Users / Groups / Problems
class Users(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True)
    name = Column('name', String)
    password = Column('password', String)

class Groups(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'groups'
    id = Column(Integer, primary_key=True)
    name = Column('name', String)

class Problems(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Problems'
    id = Column(Integer, primary_key=True)
    name = Column('name', String)

users_groups_join = Table('users_groups_join', DeclarativeBase.metadata,
                        Column('user_id', Integer, ForeignKey('users.id')),
                        Column('group_id', Integer, ForeignKey('groups.id')))

groups_problems_join = Table('groups_problems_join', DeclarativeBase.metadata,
                        Column('group_id', Integer, ForeignKey('groups.id')),
                        Column('problem_id', Integer, ForeignKey('Problems.id')))



# --------------------------------> Instruments
class Instruments(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'instruments'
    id = Column(Integer, primary_key=True)
    name = Column('name', String)

groups_instruments_join = Table('groups_instruments_join', DeclarativeBase.metadata,
                        Column('group_id', Integer, ForeignKey('groups.id')),
                        Column('instrument_id', Integer, ForeignKey('instruments.id')))





















