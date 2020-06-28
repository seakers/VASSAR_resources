from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime, Time, Enum, ForeignKey, Table, CheckConstraint, and_
from sqlalchemy.orm import relationship
from sqlalchemy.types import ARRAY
from models.base import DeclarativeBase
from sqlalchemy.engine.url import URL
import numpy as np
import pandas as pd
from models.models import Problem, get_problem_id


#######
### AttributeSet.xls -- completed
#######



class Inheritence_Attribute(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Inheritence_Attribute'

    id = Column(Integer, primary_key=True)

    problem_id = Column(Integer, ForeignKey('Problem.id'))

    from_template = Column('from_template', String)

    slot_to_copy_type = Column('slot_to_copy_type', String)

    slot_to_copy_name = Column('slot_to_copy_name', String)

    matching_slot_type = Column('matching_slot_type', String)

    matching_slot_name = Column('matching_slot_name', String)

    to_template = Column('to_template', String)

    matching_to_template_slot_name = Column('matching_to_template_slot_name', String)

    copy_slot_name = Column('copy_slot_name', String)

    module = Column('module', String)
def index_inheritence_attribute(problems_dir, session, problems):
    files = [(problem, problems_dir+'/'+problem+'/xls/AttributeSet.xls') for problem in problems]
    for problem, path in files:
        problem_id = get_problem_id(session, problem)
        df = pd.read_excel(path, sheet_name='Attribute Inheritance', header=0, usecols='A:I')
        df = df.dropna(how='all')
        for index, row in df.iterrows():
            from_template = row[0]
            slot_to_copy_type = row[1]
            slot_to_copy_name = row[2]
            matching_slot_type = row[3]
            matching_slot_name = row[4]
            to_template = row[5]
            matching_to_template_slot_name = row[6]
            copy_slot_name = row[7]
            module = row[8]
            entry = Inheritence_Attribute(problem_id=problem_id,from_template=from_template, slot_to_copy_type=slot_to_copy_type,slot_to_copy_name=slot_to_copy_name,matching_slot_type=matching_slot_type,matching_slot_name=matching_slot_name,to_template=to_template,matching_to_template_slot_name=matching_to_template_slot_name,copy_slot_name=copy_slot_name,module=module)
            session.add(entry)
            session.commit()




class Fuzzy_Attribute(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Fuzzy_Attribute'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problem.id'))
    name = Column('name', String)
    parameter = Column('parameter', String)
    unit = Column('unit', String)
class Fuzzy_Value(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Fuzzy_Value'
    id = Column(Integer, primary_key=True)
    fuzzy_attribute_id = Column(Integer, ForeignKey('Fuzzy_Attribute.id'))
    value = Column('value', String)
    minimum = Column('minimum', Float)
    mean = Column('mean', Float)
    maximum = Column('maximum', Float)

def index_fuzzy_attribute(problems_dir, session, problems):
    files = [(problem, problems_dir+'/'+problem+'/xls/AttributeSet.xls') for problem in problems]
    for problem, path in files:
        problem_id = get_problem_id(session, problem)
        df = pd.read_excel(path, sheet_name='Fuzzy Attributes', header=0)
        df = df.dropna(how='all')
        for index, row in df.iterrows():
            name = row[0]
            parameter = row[1]
            unit = row[2]
            entry = Fuzzy_Attribute(problem_id=problem_id,name=name,parameter=parameter,unit=unit)
            session.add(entry)
            session.commit()
            entry_id = entry.id
            index_fuzzy_value(session, row, entry_id)
def index_fuzzy_value(session, row, fuzzy_attribute_id , col__num_fuzzy_values=3):
    num_values = int(row[col__num_fuzzy_values])
    col__first_fuzzy_value = col__num_fuzzy_values + 1
    for index in range(num_values):
        current_index = col__first_fuzzy_value + (index * 4)
        value = row[current_index]
        minimum = float(row[current_index + 1])
        mean = float(row[current_index + 2])
        maximum = float(row[current_index + 3])
        entry = Fuzzy_Value(fuzzy_attribute_id=fuzzy_attribute_id,value=value,minimum=minimum,mean=mean,maximum=maximum)
        session.add(entry)
        session.commit()






class Accepted_Value(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Accepted_Value'
    id = Column(Integer, primary_key=True)
    name = Column('name', String)

class Mission_Attribute(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Mission_Attribute'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problem.id'))
    attribute_id = Column('attribute_id', Integer)
    slot_type = Column('slot_type', String)
    name = Column('name', String)
    attribute_type = Column('attribute_type', String)
class Orbit_Attribute(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Orbit_Attribute'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problem.id'))
    attribute_id = Column('attribute_id', Integer)
    slot_type = Column('slot_type', String)
    name = Column('name', String)
    attribute_type = Column('attribute_type', String)
class Measurement_Attribute(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Measurement_Attribute'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problem.id'))
    attribute_id = Column('attribute_id', Integer)
    slot_type = Column('slot_type', String)
    name = Column('name', String)
    attribute_type = Column('attribute_type', String)
class Launch_Vehicle_Attribute(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Launch_Vehicle_Attribute'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problem.id'))
    attribute_id = Column('attribute_id', Integer)
    slot_type = Column('slot_type', String)
    name = Column('name', String)
    attribute_type = Column('attribute_type', String)
class Instrument_Attribute(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Instrument_Attribute'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problem.id'))
    attribute_id = Column('attribute_id', Integer)
    slot_type = Column('slot_type', String)
    name = Column('name', String)
    attribute_type = Column('attribute_type', String)

class Join__Mission_Attribute_Accepted_Value(DeclarativeBase):
    __tablename__ = 'Join__Mission_Attribute_Accepted_Value'
    id = Column(Integer, primary_key=True)
    value_id = Column('value_id', Integer, ForeignKey('Accepted_Value.id'))
    attribute_id = Column('attribute_id', Integer, ForeignKey('Mission_Attribute.id'))
class Join__Orbit_Attribute_Accepted_Value(DeclarativeBase):
    __tablename__ = 'Join__Orbit_Attribute_Accepted_Value'
    id = Column(Integer, primary_key=True)
    value_id = Column('value_id', Integer, ForeignKey('Accepted_Value.id'))
    attribute_id = Column('attribute_id', Integer, ForeignKey('Orbit_Attribute.id'))
class Join__Measurement_Attribute_Accepted_Value(DeclarativeBase):
    __tablename__ = 'Join__Measurement_Attribute_Accepted_Value'
    id = Column(Integer, primary_key=True)
    value_id = Column('value_id', Integer, ForeignKey('Accepted_Value.id'))
    attribute_id = Column('attribute_id', Integer, ForeignKey('Measurement_Attribute.id'))
class Join__Launch_Vehicle_Attribute_Accepted_Value(DeclarativeBase):
    __tablename__ = 'Join__Launch_Vehicle_Attribute_Accepted_Value'
    id = Column(Integer, primary_key=True)
    value_id = Column('value_id', Integer, ForeignKey('Accepted_Value.id'))
    attribute_id = Column('attribute_id', Integer, ForeignKey('Launch_Vehicle_Attribute.id'))
class Join__Instrument_Attribute_Accepted_Value(DeclarativeBase):
    __tablename__ = 'Join__Instrument_Attribute_Accepted_Value'
    id = Column(Integer, primary_key=True)
    value_id = Column('value_id', Integer, ForeignKey('Accepted_Value.id'))
    attribute_id = Column('attribute_id', Integer, ForeignKey('Instrument_Attribute.id'))

def index_mission_attribute(problems_dir, session, problems):
    files = [(problem, problems_dir+'/'+problem+'/xls/AttributeSet.xls') for problem in problems]
    attribute_type = 'mission'
    for problem, path in files:
        problem_id = get_problem_id(session, problem)
        df = pd.read_excel(path, sheet_name='Mission', header=0, usecols='A:DA')
        df = df.dropna(how='all')
        index_attribute(session, attribute_type, df, problem_id)
    return 0
def index_orbit_attribute(problems_dir, session, problems):
    files = [(problem, problems_dir+'/'+problem+'/xls/AttributeSet.xls') for problem in problems]
    attribute_type = 'orbit'
    for problem, path in files:
        problem_id = get_problem_id(session, problem)
        df = pd.read_excel(path, sheet_name='Orbit', header=0, usecols='A:DA')
        df = df.dropna(how='all')
        index_attribute(session, attribute_type, df, problem_id)
    return 0
def index_measurement_attribute(problems_dir, session, problems):
    files = [(problem, problems_dir+'/'+problem+'/xls/AttributeSet.xls') for problem in problems]
    attribute_type = 'measurement'
    for problem, path in files:
        problem_id = get_problem_id(session, problem)
        df = pd.read_excel(path, sheet_name='Measurement', header=0, usecols='A:DA')
        df = df.dropna(how='all')
        index_attribute(session, attribute_type, df, problem_id)
    return 0
def index_launch_vehicle_attribute(problems_dir, session, problems):
    files = [(problem, problems_dir+'/'+problem+'/xls/AttributeSet.xls') for problem in problems]
    attribute_type = 'launch_vehicle'
    for problem, path in files:
        problem_id = get_problem_id(session, problem)
        df = pd.read_excel(path, sheet_name='Launch-vehicle', header=0, usecols='A:DA')
        df = df.dropna(how='all')
        index_attribute(session, attribute_type, df, problem_id)
    return 0
def index_instrument_attribute(problems_dir, session, problems):
    files = [(problem, problems_dir+'/'+problem+'/xls/AttributeSet.xls') for problem in problems]
    attribute_type = 'instrument'
    for problem, path in files:
        problem_id = get_problem_id(session, problem)
        df = pd.read_excel(path, sheet_name='Instrument', header=0, usecols='A:DA')
        df = df.dropna(how='all')
        index_attribute(session, attribute_type, df, problem_id)
    return 0



# session:         database session
# attribute_type:  mission / orbit / measurement / launch_vehicle / instrument
# data_frame:      excel attribute sheet
# problem_id:      problem_id lol
def index_attribute(session, index_attribute_type, data_frame, problem_id):
    # ---
    # 1. Index data_frame row into attribute table, get id
    # 2. Index accepted values from that row into accepted_value table, get ids
    # 3. Index join with attribute_id and accepted_value_id
    # ---
    for index, row in data_frame.iterrows():

        # 1.
        entry = None
        slot_type = row[0]
        name = row[1]
        attribute_id = row[2]
        attribute_type = row[3]


        if index_attribute_type == 'mission':
            entry = Mission_Attribute(problem_id=problem_id, attribute_id=attribute_id, slot_type=slot_type, name=name, attribute_type=attribute_type)
        elif index_attribute_type == 'measurement':
            entry = Measurement_Attribute(problem_id=problem_id, attribute_id=attribute_id, slot_type=slot_type, name=name, attribute_type=attribute_type)
        elif index_attribute_type == 'orbit':
            entry = Orbit_Attribute(problem_id=problem_id, attribute_id=attribute_id, slot_type=slot_type, name=name, attribute_type=attribute_type)
        elif index_attribute_type == 'launch_vehicle':
            entry = Launch_Vehicle_Attribute(problem_id=problem_id, attribute_id=attribute_id, slot_type=slot_type, name=name, attribute_type=attribute_type)
        elif index_attribute_type == 'instrument':
            entry = Instrument_Attribute(problem_id=problem_id, attribute_id=attribute_id, slot_type=slot_type, name=name, attribute_type=attribute_type)
        session.add(entry)
        session.commit()
        entry_id = entry.id

        if len(row) <= 4:
            print('CONTINUE', row[3])
            continue

        # 2.
        accepted_value_ids = None
        if not pd.isna(row[4]):
            accepted_value_ids = get_accepted_value_ids(session, row)
            if accepted_value_ids == False:
                continue

        # 3.
        if not pd.isna(row[4]):
            index_attribute_join(session, index_attribute_type, entry_id, accepted_value_ids)


# 2.
def get_accepted_value_ids(session, row, col__num_accepted_vals=4):
    accepted_value_ids = []
    num_accepted_vals = int(row[col__num_accepted_vals]) - 1
    col__first_accepted_val = col__num_accepted_vals + 1
    for index in range(num_accepted_vals):
        col__current_idx = col__first_accepted_val + index
        try:
            accepted_value_name = row[col__current_idx]
        except:
            return accepted_value_ids
        accepted_value_ids.append(index_accepted_value(session, accepted_value_name))
    return accepted_value_ids

def index_accepted_value(session, name):
    entry = Accepted_Value(name=name)
    session.add(entry)
    session.commit()
    entry_id = entry.id
    return entry_id


# 3.
def index_attribute_join(session, attribute_type, attribute_id, accepted_value_ids):
    for value_id in accepted_value_ids:
        entry = None
        if attribute_type == 'mission':
            entry = Join__Mission_Attribute_Accepted_Value(attribute_id=attribute_id, value_id=value_id)
        elif attribute_type == 'measurement':
            entry = Join__Measurement_Attribute_Accepted_Value(attribute_id=attribute_id, value_id=value_id)
        elif attribute_type == 'orbit':
            entry = Join__Orbit_Attribute_Accepted_Value(attribute_id=attribute_id, value_id=value_id)
        elif attribute_type == 'launch_vehicle':
            entry = Join__Launch_Vehicle_Attribute_Accepted_Value(attribute_id=attribute_id, value_id=value_id)
        elif attribute_type == 'instrument':
            entry = Join__Instrument_Attribute_Accepted_Value(attribute_id=attribute_id, value_id=value_id)
        session.add(entry)
    session.commit()












