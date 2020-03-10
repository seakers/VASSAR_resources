from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime, Time, Enum, ForeignKey, Table, \
    CheckConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.engine.url import URL

DeclarativeBase = declarative_base()


# --------------------------------> AggregationRules.xls
class Stakeholder_Needs_Panels(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Stakeholder_Needs_Panels'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problems.id'))
    name = Column('name', String)
    description = Column('description', String)
    weight = Column('weight', Float)

class Stakeholder_Needs_Objectives(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Stakeholder_Needs_Objectives'
    id = Column(Integer, primary_key=True)
    panel_id = Column(Integer, ForeignKey('Stakeholder_Needs_Panels.id'))
    name = Column('name', String)
    description = Column('description', String)
    weight = Column('weight', Float)

class Stakeholder_Needs_Subobjectives(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Stakeholder_Needs_Subobjectives'
    id = Column(Integer, primary_key=True)
    objective_id = Column(Integer, ForeignKey('Stakeholder_Needs_Objectives.id'))
    name = Column('name', String)
    description = Column('description', String)
    weight = Column('weight', Float)





