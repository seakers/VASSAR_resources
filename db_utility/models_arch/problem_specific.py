from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime, Time, Enum, ForeignKey, Table, CheckConstraint, Boolean, ARRAY
from sqlalchemy.orm import relationship
from models_arch.base import DeclarativeBase
from sqlalchemy.engine.url import URL

from models_arch.stakeholders import Stakeholder_Needs_Subobjective
from models_arch.globals import get_measurement_name, get_measurement_id, get_measurement_attribute_id, index_measurement
from models_arch.stakeholders import get_subobjective_id

# from models.django_models import auth_user

import os
import pandas as pd
import numpy as np
import json
import math

problem_dir = "/app/daphne/VASSAR_resources/problems"
problems_dir = "/app/daphne/VASSAR_resources/problems"


instrument_list = [
    'ACE_CPR',
    'ACE_ORCA',
    'ACE_POL',
    'ACE_LID',
    'CLAR_TIR',
    'CLAR_VNIR',
    'CLAR_ERB',
    'CLOUD_MASK',
    'DESD_SAR',
    'DESD_LID',
    'GACM_SWIR',
    'GACM_VIS',
    'HYSP_TIR',
    'CNES_KaRIN',
    'POSTEPS_IRS',

    'SMAP_ANT',
    'SMAP_RAD',
    'SMAP_MWR',
    'VIIRS',
    'CMIS',
    'BIOMASS',
    'ALT',
    'GPS',
    'MODIS'
]


# data['group_id'] = index_group(session, group_name)
# data['problems'] = {}

# data['instruments'] = {}
# data['Power'] = {}
# data['Launch Vehicles'] = {}
# data['measurements'] = {}

# data['measurement_attributes'] = {}
# data['instrument_attributes'] = {}
# data['orbit_attributes'] = {}
# data['launch_vehicle_attributes'] = {}
# data['mission_attributes'] = {}


def index_group_problems(session, data):
    problems = os.listdir(problem_dir)
    group_id = data['group_id']


    # LAUNCH VEHICLES / ORBIT
    files = [(problem, problems_dir+'/'+problem+'/xls/Mission Analysis Database.xls') for problem in problems]
    for problem, path in files:
        problem_id = data['problems'][problem]
        index_mission_analysis(session, data, group_id, problem_id, path, 'Launch Vehicles', problem)
        index_mission_analysis(session, data, group_id, problem_id, path, 'Power', problem)

    # INSTRUMENTS / MEASUREMENTS
    files = [(problem, problems_dir+'/'+problem+'/xls/Instrument Capability Definition.xls') for problem in problems]
    for problem, path in files:
        problem_id = data['problems'][problem]
        index_group_characteristics(session, data, group_id, problem_id, path)
        if problem == 'SMAP':
            index_group_capabilities(session, data, group_id, problem_id, path)

    # REQUIREMENT RULES: only by attribute for now, so skip Decadal2017Aerosols
    files = [(problem, problems_dir+'/'+problem+'/xls/Requirement Rules.xls') for problem in problems]
    for problem, path in files:
        if problem == 'Decadal2017Aerosols':
            continue
        problem_id = data['problems'][problem]
        index_group_requirement_rules(session, data, group_id, problem_id, path)


        


def validate_dict(dictionary, subkey, key):
    if subkey not in dictionary.keys():
        print(json.dumps(dictionary, sort_keys=True, indent=4))
        print("\n\nSubkey does not exist in data\nsubkey: ", subkey, " --- key: ", key)
        exit()
    elif key not in dictionary[subkey].keys():
        print(json.dumps(dictionary, sort_keys=True, indent=4))
        print("\n\nKey does not exist in data\nsubkey: ", subkey, " --- key: ", key)
        exit()
    else:
        return dictionary[subkey][key]


def validate_dict_meas(dictionary, subkey, key, session):
    if subkey not in dictionary.keys():
        print(json.dumps(dictionary, sort_keys=True, indent=4))
        print("\n\nSubkey does not exist in data\nsubkey: ", subkey, " --- key: ", key)
        exit()
    elif key not in dictionary[subkey].keys():
        print(json.dumps(dictionary, sort_keys=True, indent=4))
        print("\n\nKey does not exist in data\nsubkey: ", subkey, " --- key: ", key)
        # # We will index the synergy measurements here
        measurement_id = index_measurement(session, dictionary['group_id'], key, synergy_rule=True)
        dictionary[subkey][key] = measurement_id
        return dictionary[subkey][key]
    else:
        return dictionary[subkey][key]


def format_measurement_rule(rule):
    if rule[0] == '"' and rule[-1:] == '"':
        rule = rule[1:-1]
    return rule


def index_group_requirement_rules(session, data, group_id, problem_id, path):
    xls = pd.ExcelFile(path)
    df = pd.read_excel(xls, 'Attributes', header=0, usecols='A:G')
    df = df.dropna(how='all')
    for index, row in df.iterrows():
        subobjective_id = get_subobjective_id(session, row[0], problem_id) # subobjective_id

        measurement_id = validate_dict_meas(data, 'measurements', format_measurement_rule(row[1]), session)
        measurement_attribute_id = validate_dict(data, 'measurement_attributes', row[2])

        type = str(row[3])
        thresholds = row[4].strip('][').split(',')
        scores = row[5].strip('][').split(',')
        scores = [round(float(element), 2) for element in scores]
        justification = format_measurement_rule(row[6])
        index_requirement_rule_attribute(session, problem_id, subobjective_id, measurement_id, measurement_attribute_id, type, thresholds, scores, justification)



def get_measurement_attribute_data(data, col):
    items = col.split()
    if len(items) != 2:
        print("\nMeasurement Attribute Cell doesn't have 2 items")
        print(json.dumps(data, sort_keys=True, indent=4))
        print(col)
        exit()
    else:
        measurement_attribute_name = items[0]
        value = items[1]
        measurement_attribute_id = validate_dict(data, 'measurement_attributes', measurement_attribute_name)
        return [measurement_attribute_id, value]

    

def index_group_capabilities(session, data, group_id, problem_id, path):
    xls = pd.ExcelFile(path)
    sheets = xls.sheet_names
    for sheet in sheets:
        if sheet not in instrument_list:
            continue

        instrument_id = validate_dict(data, 'instruments', sheet)  # instrument_id
        df = pd.read_excel(xls, sheet, header=None)
        df = df.dropna(how='all')
        for index, row in df.iterrows():

            measurement_name = get_measurement_name(row[1])
            measurement_id = validate_dict(data, 'measurements', measurement_name) # measurement_id

            for idx, col in enumerate(row):
                if idx == 0 or idx == 1:
                    continue

                measurement_data = get_measurement_attribute_data(data, col)
                measurement_attribute_id = measurement_data[0]                     # measurement_attribute_id
                value = measurement_data[1]                                        # value
                index_instrument_capability(session, group_id, problem_id, instrument_id, measurement_id, measurement_attribute_id, value)

    return 0



def index_group_characteristics(session, data, group_id, problem_id, path):
    xls = pd.ExcelFile(path)
    df = pd.read_excel(xls, 'CHARACTERISTICS', header=0)
    df = df.dropna(how='all')
    col_labels = df.columns.get_values().tolist()


    for index, row in df.iterrows(): # FOR EACH: instrument_id
        name_items = row[0].split()
        if len(name_items) == 1:
            instrument_name = name_items[0]
        else:
            instrument_name = name_items[1]

        instrument_id = validate_dict(data, 'instruments', instrument_name) # instrument_id

        for idx, col in enumerate(row):
            if idx == 0 or pd.isna(col):
                continue
            attr_data = col.split()
            instrument_attribute_name = attr_data[0]
            instrument_attribute_id = validate_dict(data, 'instrument_attributes', instrument_attribute_name) # instrument_attribute_id
            value = str(attr_data[1])
            entry_id = index_instrument_characteristic(session, group_id, problem_id, instrument_id, instrument_attribute_id, value)








def index_mission_analysis(session, data, group_id, problem_id, path, sheet, problem_name):
    # NEED
    # group_id:   given
    # problem_id: given
    # launch_vehicle_id | orbit_id:                     changes with each row: item_id
    # launch_vehicle_attribute_id | orbit_attribute_id: changes with each col: item_attribute_id

    xls = pd.ExcelFile(path)
    df = pd.read_excel(xls, sheet, header=0, keep_default_na=False, dtype=np.unicode_)
    df = df.dropna(how='all')

    col_labels = df.columns.get_values().tolist()

    for index, row in df.iterrows():
        item_id = data[sheet][row[0]]              # item_id

        for idx, col in enumerate(row):
            if idx == 0:
                continue
            value = col                      # value 

            item_attribute_id = None               # item_attribute_id
            entry = None
            if sheet == 'Launch Vehicles' and problem_name == 'SMAP':
                item_attribute_id = validate_dict(data, 'launch_vehicle_attributes', col_labels[idx])
                entry_id = index_launch_vehicle_attribiute(session, group_id, item_id, item_attribute_id, value)
            elif sheet == 'Power':
                if idx == 5:
                    trans = int(float(value) * 100)
                    trans_s = str(trans)
                    final_s = trans_s + '%'
                    value = final_s
                elif idx == 7:
                    trans = str(round(float(value), 2))
                    value = trans
                elif idx == 6 or idx == 8:
                    trans = str(int(round(float(value))))
                    value = trans


                # if row[0] in ['LEO-600-polar-NA', 'SSO-600-SSO-AM', 'SSO-600-SSO-DD', 'SSO-800-SSO-AM', 'SSO-800-SSO-DD']:
                # only index orbit attributes globally for SMAP
                if problem_name == 'SMAP':
                    item_attribute_id = validate_dict(data, 'orbit_attributes', col_labels[idx])
                    entry_id = index_orbit_attribiute(session, group_id, item_id, item_attribute_id, value)
                # print("--------------------------------------------AAA")
                # print(col, row)
                # exit()










class Join__Instrument_Capability(DeclarativeBase):
    __tablename__ = 'Join__Instrument_Capability'
    id = Column(Integer, primary_key=True)

    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    instrument_id = Column('instrument_id', Integer, ForeignKey('Instrument.id')) # nullable
    measurement_id = Column('measurement_id', Integer, ForeignKey('Measurement.id'))
    measurement_attribute_id = Column('measurement_attribute_id', Integer, ForeignKey('Measurement_Attribute.id'))
    # problem_id = Column('problem_id', Integer, ForeignKey('Problem.id')) # nullable
    requirement_rule_case_id = Column('requirement_rule_case_id', Integer, ForeignKey('Requirement_Rule_Case.id')) 

    descriptor = Column('descriptor', String, default=False)
    value = Column('value', String, default=False)
def index_instrument_capability(session, group_id, problem_id, instrument_id, measurement_id, measurement_attribute_id, value):
    entry = Join__Instrument_Capability(group_id=group_id, instrument_id=instrument_id, measurement_id=measurement_id, measurement_attribute_id=measurement_attribute_id, value=value)
    session.add(entry)
    session.commit()
    return entry.id



class Join__Instrument_Characteristic(DeclarativeBase):
    __tablename__ = 'Join__Instrument_Characteristic'
    id = Column(Integer, primary_key=True)

    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    instrument_id = Column('instrument_id', Integer, ForeignKey('Instrument.id')) # nullable
    problem_id = Column('problem_id', Integer, ForeignKey('Problem.id')) # nullable
    instrument_attribute_id = Column('instrument_attribute_id', Integer, ForeignKey('Instrument_Attribute.id')) 

    value = Column('value', String, default=False)
def index_instrument_characteristic(session, group_id, problem_id, instrument_id, instrument_attribute_id, value):

    if ';' in value:
        value_temp = value.split(';')[-1]
        value = value_temp
    if '"' in value:
        value_temp = value.split('"')[-1]
        value = value_temp

    entry = Join__Instrument_Characteristic(group_id=group_id, problem_id=problem_id, instrument_id=instrument_id, instrument_attribute_id=instrument_attribute_id, value=value)
    session.add(entry)
    session.commit()
    return entry.id







class Join__Orbit_Attribute(DeclarativeBase):
    __tablename__ = 'Join__Orbit_Attribute'
    id = Column(Integer, primary_key=True)

    orbit_id = Column('orbit_id', Integer, ForeignKey('Orbit.id')) # nullable
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    orbit_attribute_id = Column('orbit_attribute_id', Integer, ForeignKey('Orbit_Attribute.id')) 
    # problem_id = Column('problem_id', Integer, ForeignKey('Problem.id')) # nullable # nullable
    
    value = Column('value', String, default=False)
def index_orbit_attribiute(session, group_id, orbit_id, orbit_attribute_id, value):
    entry = Join__Orbit_Attribute(group_id=group_id, orbit_id=orbit_id, orbit_attribute_id=orbit_attribute_id, value=value)
    session.add(entry)
    session.commit()
    return entry.id



class Join__Launch_Vehicle_Attribute(DeclarativeBase):
    __tablename__ = 'Join__Launch_Vehicle_Attribute'
    id = Column(Integer, primary_key=True)

    launch_vehicle_id = Column('launch_vehicle_id', Integer, ForeignKey('Launch_Vehicle.id')) # nullable
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    launch_vehicle_attribute_id = Column('launch_vehicle_attribute_id', Integer, ForeignKey('Launch_Vehicle_Attribute.id')) 
    # problem_id = Column('problem_id', Integer, ForeignKey('Problem.id')) # nullable # nullable
    
    value = Column('value', String, default=False)
def index_launch_vehicle_attribiute(session, group_id, launch_vehicle_id, launch_vehicle_attribute_id, value):
    entry = Join__Launch_Vehicle_Attribute(group_id=group_id, launch_vehicle_id=launch_vehicle_id, launch_vehicle_attribute_id=launch_vehicle_attribute_id, value=value)
    session.add(entry)
    session.commit()
    return entry.id







class Requirement_Rule_Attribute(DeclarativeBase):
    __tablename__ = 'Requirement_Rule_Attribute'
    id = Column(Integer, primary_key=True)

    measurement_id = Column('measurement_id', Integer, ForeignKey('Measurement.id'))
    measurement_attribute_id = Column('measurement_attribute_id', Integer, ForeignKey('Measurement_Attribute.id'))
    problem_id = Column('problem_id', Integer, ForeignKey('Problem.id'))
    subobjective_id = Column('subobjective_id', Integer, ForeignKey('Stakeholder_Needs_Subobjective.id')) 

    type = Column('type', String, default=False)
    thresholds = Column('thresholds', ARRAY(String))
    scores = Column('scores', ARRAY(Float))
    justification = Column('justification', String, default=False)
def index_requirement_rule_attribute(session, problem_id, subobjective_id, measurement_id, measurement_attribute_id, type, thresholds, scores, justification):
    entry = Requirement_Rule_Attribute(problem_id=problem_id, subobjective_id=subobjective_id, measurement_id=measurement_id, measurement_attribute_id=measurement_attribute_id, type=type, thresholds=thresholds, scores=scores, justification=justification)
    session.add(entry)
    session.commit()
    return entry.id


class Requirement_Rule_Case(DeclarativeBase):
    __tablename__ = 'Requirement_Rule_Case'
    id = Column(Integer, primary_key=True)

    measurement_id = Column('measurement_id', Integer, ForeignKey('Measurement.id'))
    measurement_attribute_id = Column('measurement_attribute_id', Integer, ForeignKey('Measurement_Attribute.id'))
    problem_id = Column('problem_id', Integer, ForeignKey('Problem.id')) # nullable
    subobjective_id = Column('subobjective_id', Integer, ForeignKey('Stakeholder_Needs_Subobjective.id')) 

    rule = Column('rule', String, default=False)
    value = Column('value', String, default=False)
def index_requirement_rule_case(session, problem_id, subobjective_id, measurement_id, measurement_attribute_id, rule, value):
    entry = Requirement_Rule_Case(problem_id=problem_id, subobjective_id=subobjective_id, measurement_id=measurement_id, measurement_attribute_id=measurement_attribute_id, rule=rule, value=value)
    session.add(entry)
    session.commit()
    return entry.id