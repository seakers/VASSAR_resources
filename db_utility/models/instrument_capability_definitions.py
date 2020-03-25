from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime, Time, Enum, ForeignKey, Table, CheckConstraint, and_
from sqlalchemy.orm import relationship
from sqlalchemy.types import ARRAY
from models.base import DeclarativeBase
from sqlalchemy.engine.url import URL
import numpy as np
import pandas as pd
from models.models import Problem, get_problem_id



#######
### InstrumentCapabilityDefinitions.xls - in progress
#######




class Instrument(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Instrument'
    id = Column(Integer, primary_key=True)
    name = Column('name', String)
Group_Instrument_Join = Table('Group_Instrument_Join', DeclarativeBase.metadata,
                        Column('group_id', Integer, ForeignKey('Group.id')),
                        Column('instrument_id', Integer, ForeignKey('Instrument.id')))
def index_instruments(problems_dir, session, problem_name):
    return 0




class Instrument_Capability(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Instrument_Capability'
    id = Column(Integer, primary_key=True)
    instrument_id = Column(Integer, ForeignKey('Instrument.id'))
    attribute_id = Column(Integer, ForeignKey('Instrument_Attribute.id'))
    problem_id = Column(Integer, ForeignKey('Problem.id'))

    measurement_id = Column('measurement_id', Integer)
    value = Column('value', String)
    value_type = Column('value_type', String) # string | bool | float
def index_instrument_capabilities(problems_dir, session, problem_name):
    return 0



