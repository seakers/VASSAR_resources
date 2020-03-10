from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime, Time, Enum, ForeignKey, Table, \
    CheckConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.engine.url import URL

DeclarativeBase = declarative_base()




# --------------------------------> AttributeSet.xls
# ---> Inheritence Attributes
class Inheritence_Attributes(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Inheritence_Attributes'
    problem_id = Column(Integer, ForeignKey('Problems.id'))
    from_template = Column('from_template', String)
    slot_to_copy_type = Column('slot_to_copy_type', String)
    slot_to_copy_name = Column('slot_to_copy_name', String)
    matching_slot_type = Column('matching_slot_type', String)
    matching_slot_name = Column('matching_slot_name', String)
    to_template = Column('to_template', String)
    matching_to_template_slot_name = Column('matching_to_template_slot_name', String)
    copy_slot_name = Column('copy_slot_name', String)
    module = Column('module', String)


# ---> Fuzzy Attributes
class Fuzzy_Attributes(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Fuzzy_Attributes'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problems.id'))
    name = Column('name', String)
    parameter = Column('parameter', String)
    unit = Column('unit', String)
    
class Fuzzy_Values(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Fuzzy_Values'
    fuzzy_attribute_id = Column(Integer, ForeignKey('Fuzzy_Attributes.id'))
    value = Column('value', String)
    min = Column('min', Float)
    mean = Column('mean', Float)
    max = Column('max', Float)



# ---> Other Attributes
class Measurement_Attributes(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Measurement_Attributes'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problems.id'))
    slot_type = Column('slot_type', String)
    name = Column('name', String)
    type = Column('type', String)
Measurement_Attributes_Accepted_Values_Join = Table('Measurement_Attributes_Accepted_Values', DeclarativeBase.metadata,
                        Column('value_id', Integer, ForeignKey('Accepted_Values.id')),
                        Column('attribute_id', Integer, ForeignKey('Measurement_Attributes.id')))


class Instrument_Attributes(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Instrument_Attributes'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problems.id'))
    slot_type = Column('slot_type', String)
    name = Column('name', String)
    type = Column('type', String)
Instrument_Attributes_Accepted_Values_Join = Table('Instrument_Attributes_Accepted_Values_Join', DeclarativeBase.metadata,
                        Column('value_id', Integer, ForeignKey('Accepted_Values.id')),
                        Column('attribute_id', Integer, ForeignKey('Instrument_Attributes.id')))


class Mission_Attributes(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Mission_Attributes'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problems.id'))
    slot_type = Column('slot_type', String)
    name = Column('name', String)
    type = Column('type', String)
Mission_Attributes_Accepted_Values_Join = Table('Mission_Attributes_Accepted_Values_Join', DeclarativeBase.metadata,
                        Column('value_id', Integer, ForeignKey('Accepted_Values.id')),
                        Column('attribute_id', Integer, ForeignKey('Mission_Attributes.id')))


class Orbit_Attributes(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Orbit_Attributes'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problems.id'))
    slot_type = Column('slot_type', String)
    name = Column('name', String)
    type = Column('type', String)
Orbit_Attributes_Accepted_Values_Join = Table('Orbit_Attributes_Accepted_Values_Join', DeclarativeBase.metadata,
                        Column('value_id', Integer, ForeignKey('Accepted_Values.id')),
                        Column('attribute_id', Integer, ForeignKey('Orbit_Attributes.id')))


class Launch_Vehicle_Attributes(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Launch_Vehicle_Attributes'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problems.id'))
    slot_type = Column('slot_type', String)
    name = Column('name', String)
    type = Column('type', String)
Launch_Vehicle_Attributes_Accepted_Values_Join = Table('Launch_Vehicle_Attributes_Accepted_Values_Join', DeclarativeBase.metadata,
                        Column('value_id', Integer, ForeignKey('Accepted_Values.id')),
                        Column('attribute_id', Integer, ForeignKey('Launch_Vehicle_Attributes.id')))




class Accepted_Values(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Accepted_Values'
    id = Column(Integer, primary_key=True)
    name = Column('name', String)