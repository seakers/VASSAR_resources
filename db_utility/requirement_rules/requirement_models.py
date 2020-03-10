from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime, Time, Enum, ForeignKey, Table, \
    CheckConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.engine.url import URL




# --------------------------------> RequirementRules.xls
class Requirement_Rules_Attributes(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Requirement_Rules_Attributes'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problems.id'))
    subobjective = Column('subobjective', String)
    measurement = Column('measurement', String)
    attribute = Column('attribute', String)
    type = Column('type', String)
    threshold_list = Column('threshold_list', String)
    scores_list = Column('scores_list', String)
    justification = Column('justification', String)
