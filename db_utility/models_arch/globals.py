from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime, Time, Enum, ForeignKey, Table, CheckConstraint, Boolean
from sqlalchemy.orm import relationship
from models_arch.base import DeclarativeBase
from sqlalchemy.engine.url import URL

from models_arch.stakeholders import Stakeholder_Needs_Subobjective, Stakeholder_Needs_Objective, Stakeholder_Needs_Panel

from models_arch.django_models import auth_user

# from models.django_models import auth_user

import os
import pandas as pd
import time

import pprint

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
    'MODIS',
    'ACE-CPR',
    'ACE-OCI',
    'ACE-POL',
    'ACE-LID',
    'CALIPSO-CALIOP',
    'CALIPSO-WFC',
    'CALIPSO-IIR',
    'EARTHCARE-ATLID',
    'EARTHCARE-BBR',
    'EARTHCARE-CPR',
    'EARTHCARE-MSI',
    'ICI',
    'AQUARIUS',
    'DIAL',
    'IR-Spectrometer'
]


smap_problem_list = [
    'SMAP',
    'SMAP_JPL1',
    'SMAP_JPL2'
]

smap_instrument_list = [
    'SMAP_MWR',
    'SMAP_RAD',
    'VIIRS',
    'CMIS',
    'BIOMASS'
]

climate_centric_instrument_list = [
    'ACE_CPR',
    'ACE_ORCA',
    'ACE_POL',
    'ACE_LID',
    'CLAR_ERB',
    'DESD_SAR',
    'DESD_LID',
    'GACM_SWIR',
    'GACM_VIS',
    'HYSP_TIR',
    'CNES_KaRIN',
    'POSTEPS_IRS'
]

decadal_aerosols_instrument_list = [

    'ACE_CPR',
    'ACE_ORCA',
    'ACE_POL',
    'ACE_LID',
    'ASC_LID',
    'ASC_GCR',
    'ASC_IRR',
    'CLAR_TIR',
    'CLAR_VNIR',
    'CLAR_GPS',
    'DESD_SAR',
    'DESD_LID',
    'GACM_SWIR',
    'GACM_MWSP',
    'GACM_VIS',
    'GACM_DIAL',
    'GEO_STEER',
    'GEO_WAIS',
    'GEO_GCR',
    'GPS',
    'GRAC_RANG',
    'HYSP_TIR',
    'HYSP_VIS',
    'ICE_LID',
    'LIST_LID',
    'PATH_GEOSTAR',
    'SCLP_SAR',
    'SCLP_MWR',
    'SMAP_ANT',
    'SMAP_RAD',
    'SMAP_MWR',
    'SWOT_GPS',
    'SWOT_KaRIN',
    'SWOT_RAD',
    'SWOT_MWR',
    'XOV_SAR',
    'XOV_RAD',
    'XOV_MWR',
    '3D_CLID',
    '3D_NCLID',
    'CLOUD_MASK'

]

launch_vehicle_list = [
    'Ariane-5-ESCA',
    'Soyuz',
    'Vega',
    'SLS',
    'Delta-7320',
    'Delta-7420',
    'Delta-7920',
    'Taurus-XL',
    'Minotaur-IV',
]

orbit_list = [
    'GEO-36000-equat-NA',
    'LEO-275-polar-NA',
    'LEO-400-polar-NA',
    'LEO-600-polar-NA',
    'LEO-800-polar-NA',
    'SSO-400-SSO-DD',
    'SSO-400-SSO-AM',
    'SSO-400-SSO-noon',
    'SSO-400-SSO-PM',
    'SSO-600-SSO-DD',
    'SSO-600-SSO-AM',
    'SSO-600-SSO-noon',
    'SSO-600-SSO-PM',
    'SSO-800-SSO-DD',
    'SSO-800-SSO-AM',
    'SSO-800-SSO-noon',
    'SSO-800-SSO-PM',
    'LEO-275-equat-NA',
    'LEO-1000-near-polar-NA',
    'LEO-1300-near-polar-NA',
    'LEO-600-near-polar-NA',
    'SSO-1000-SSO-AM',
    'LEO-600-equat-NA'
]

smap_orbit_list = [
    'LEO-600-polar-NA',
    'SSO-600-SSO-AM',
    'SSO-600-SSO-DD',
    'SSO-800-SSO-AM',
    'SSO-800-SSO-DD'
]

global_attributes = [
    'Measurement',
    'Instrument',
    'Orbit',
    'Launch-vehicle',
    'Mission',
    'Attribute Inheritance'
]

synergy_measurements = [
    '2.3.3 Carbon net ecosystem exchange NEE',
    '1.4.3 Air wind speed at surface'
]




def index_group_globals(session, group_name):
    pp = pprint.PrettyPrinter(indent=4)

    data = {}
    data['group_id'] = index_group(session, group_name)

    # INIT GLOBAL DATA
    data['problems'] = {}
    data['instruments'] = {}
    data['Power'] = {}
    data['Launch Vehicles'] = {}
    data['measurements'] = {}
    data['measurement_attributes'] = {}
    data['instrument_attributes'] = {}
    data['orbit_attributes'] = {}
    data['launch_vehicle_attributes'] = {}
    data['mission_attributes'] = {}


    problems = os.listdir(problem_dir)
    group_id = data['group_id']
    



    # INDEX PROBLEMS AND CORRESPONDING DESIGNS
    for problem in problems:
        data['problems'][problem] = index_problem(session, problem, data['group_id'])
        index_problem_architectures(session, problem, data['problems'][problem])


    # INDEX INSTRUMENTS
    for instrument in list(set(instrument_list)):
        # INDEX GLOBALLY
        data['instruments'][instrument] = index_instrument(session, instrument, data['group_id'])
        # INDEX JOIN TABLES
        if instrument in smap_instrument_list:
            entry = Join__Problem_Instrument(problem_id=data['problems']['SMAP'], instrument_id=data['instruments'][instrument])
            entry2 = Join__Problem_Instrument(problem_id=data['problems']['SMAP_JPL1'], instrument_id=data['instruments'][instrument])
            entry3 = Join__Problem_Instrument(problem_id=data['problems']['SMAP_JPL2'], instrument_id=data['instruments'][instrument])
            session.add(entry)
            session.add(entry2)
            session.add(entry3)
            session.commit()
        if instrument in climate_centric_instrument_list:
            entry = Join__Problem_Instrument(problem_id=data['problems']['ClimateCentric'], instrument_id=data['instruments'][instrument])
            session.add(entry)
            session.commit()
        if instrument in decadal_aerosols_instrument_list:
            entry = Join__Problem_Instrument(problem_id=data['problems']['Decadal2017Aerosols'], instrument_id=data['instruments'][instrument])
            session.add(entry)
            session.commit()


    
    for orbit in orbit_list:
        data['Power'][orbit] = index_orbit(session, orbit, data['group_id'])
        if orbit in smap_orbit_list:
            index_orbit_join(session, data, data['Power'][orbit]) # last param is orbit id    




    for launch_vehicle in launch_vehicle_list:
        data['Launch Vehicles'][launch_vehicle] = index_launch_vehicle(session, launch_vehicle, data['group_id'])
        index_lv_join(session, data, data['Launch Vehicles'][launch_vehicle]) # last param is lv id





    # INSTRUMENT CAPABILITY DEFINITIONS

    files = [(problem, problems_dir+'/'+problem+'/xls/Instrument Capability Definition.xls') for problem in problems]
    
    for problem, path in files:
        measurement_data = index_measurements(session, problem, path, group_id, data)
        for data_pair in measurement_data:
            data['measurements'][data_pair[0]] = data_pair[1]
    # for meas_name in synergy_measurements:
    #     meas_id = index_measurement(session, group_id, meas_name, synergy_rule=True)
    #     data['measurements'][meas_name] = meas_id

    
    # ATTRIBUTE SET

    files = [(problem, problems_dir+'/'+problem+'/xls/AttributeSet.xls') for problem in problems]
    for attribute in global_attributes:
        for problem, path in files:
            problem_id = data['problems'][problem]
            measurement_attribute_data = index_global_attribute(session, problem, path, group_id, attribute, problem_id)
            # data_pair: (attribute_name, attribute_id)
            for data_pair in measurement_attribute_data:
                if attribute == 'Measurement':
                    data['measurement_attributes'][data_pair[0]] = data_pair[1]
                elif attribute == 'Instrument':
                    data['instrument_attributes'][data_pair[0]] = data_pair[1]
                elif attribute == 'Orbit':
                    if data_pair[0] == 'type ':
                        data_pair[0] = data_pair[0].strip()
                    data['orbit_attributes'][data_pair[0]] = data_pair[1]
                elif attribute == 'Launch-vehicle':
                    data['launch_vehicle_attributes'][data_pair[0]] = data_pair[1]
                elif attribute == 'Mission':
                    data['mission_attributes'][data_pair[0]] = data_pair[1]
    return data














# index_orbit_join(session, data, data['Power'][orbit]) # last param is orbit id
def index_orbit_join(session, data, orbit_id):
    for prob in smap_problem_list:
        index_problem_orbit(session, data['problems'][prob], orbit_id)
    # Index for Decadal2017Aerosols
    index_problem_orbit(session, data['problems']['Decadal2017Aerosols'], orbit_id)



# index_lv_join(session, data, data['Launch Vehicles'][launch_vehicle]) # last param is orbit id
def index_lv_join(session, data, lv_id):
    for prob in smap_problem_list:
        index_problem_lv(session, data['problems'][prob], lv_id)
    index_problem_lv(session, data['problems']['Decadal2017Aerosols'], lv_id)




def index_problem_architectures(session, problem_name, problem_id):
    if problem_name != "SMAP" and problem_name != "SMAP_JPL1" and problem_name != "SMAP_JPL2":
        return 0
    filepath = '/app/daphne/VASSAR_resources/problem_default_archs/' + problem_name + '/default.csv'
    dataset_id = index_dataset(session, "default", problem_id, None, None)
    df = pd.read_csv(filepath, header=0)

    for index, row in df.iterrows():
        input = row[0]
        science = row[1]
        cost = row[2]
        index_architecture(session, problem_id, dataset_id, input, science, cost)








class Group(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Group'
    id = Column(Integer, primary_key=True)
    name = Column('name', String)
def index_group(session, name):
    entry = Group(name=name)
    session.add(entry)
    session.commit()
    return entry.id

class Join__AuthUser_Group(DeclarativeBase):
    __tablename__ = 'Join__AuthUser_Group'
    id = Column(Integer, primary_key=True)
    user_id = Column('user_id', Integer, ForeignKey('auth_user.id'))
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    admin = Column('admin', Boolean, default=False)




class Problem(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Problem'
    id = Column(Integer, primary_key=True)
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    name = Column('name', String)
    reload_problem = Column('reload_problem', Boolean, default=False)
def index_problem(session, name, group_id):
    entry = Problem(name=name, group_id=group_id)
    session.add(entry)
    session.commit()
    return entry.id

def get_problem_id(session, problem_name, group_id):
    problem_id_query = session.query(Problem.id, Problem.name).filter(Problem.name == problem_name).filter(Problem.group_id == group_id).first()
    problem_id = problem_id_query[0]
    print("Found problem ID", problem_name, problem_id, group_id)
    return problem_id


class Dataset(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Dataset'
    id = Column(Integer, primary_key=True)
    problem_id = Column('problem_id', Integer, ForeignKey('Problem.id'))
    user_id = Column('user_id', Integer, ForeignKey('auth_user.id'), nullable=True)
    group_id = Column('group_id', Integer, ForeignKey('Group.id'), nullable=True)
    name = Column('name', String)
def index_dataset(session, name, problem_id, user_id, group_id):
    entry = Dataset(name=name, problem_id=problem_id, user_id=user_id, group_id=group_id)
    session.add(entry)
    session.commit()
    return entry.id




class Join__Problem_Instrument(DeclarativeBase):
    __tablename__ = 'Join__Problem_Instrument'
    id            = Column(Integer, primary_key=True)
    problem_id    = Column('problem_id', Integer, ForeignKey('Problem.id'))
    instrument_id = Column('instrument_id', Integer, ForeignKey('Instrument.id'))


class Join__Problem_Orbit(DeclarativeBase):
    __tablename__ = 'Join__Problem_Orbit'
    id            = Column(Integer, primary_key=True)
    problem_id    = Column('problem_id', Integer, ForeignKey('Problem.id'))
    orbit_id = Column('orbit_id', Integer, ForeignKey('Orbit.id'))
def index_problem_orbit(session, problem_id, orbit_id):
    entry = Join__Problem_Orbit(problem_id=problem_id,orbit_id=orbit_id)
    session.add(entry)
    session.commit()


class Join__Problem_Launch_Vehicle(DeclarativeBase):
    __tablename__ = 'Join__Problem_Launch_Vehicle'
    id            = Column(Integer, primary_key=True)
    problem_id    = Column('problem_id', Integer, ForeignKey('Problem.id'))
    launch_vehicle_id = Column('launch_vehicle_id', Integer, ForeignKey('Launch_Vehicle.id'))
def index_problem_lv(session, problem_id, launch_vehicle_id):
    entry = Join__Problem_Launch_Vehicle(problem_id=problem_id,launch_vehicle_id=launch_vehicle_id)
    session.add(entry)
    session.commit()


    






class Launch_Vehicle(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Launch_Vehicle'
    id = Column(Integer, primary_key=True)
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    name = Column('name', String)
def index_launch_vehicle(session, name, group_id):
    entry = Launch_Vehicle(name=name, group_id=group_id)
    session.add(entry)
    session.commit()
    return entry.id



class Instrument(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Instrument'
    id = Column(Integer, primary_key=True)
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    name = Column('name', String)
def index_instrument(session, name, group_id):
    entry = Instrument(name=name, group_id=group_id)
    session.add(entry)
    session.commit()
    return entry.id


class Orbit(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Orbit'
    id = Column(Integer, primary_key=True)
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    name = Column('name', String)
def index_orbit(session, name, group_id):
    entry = Orbit(name=name, group_id=group_id)
    session.add(entry)
    session.commit()
    return entry.id




class Measurement(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Measurement'
    id = Column(Integer, primary_key=True)
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    name = Column('name', String)
    synergy_rule = Column('synergy_rule', Boolean, default=False)

def index_measurement(session, group_id, name, synergy_rule=False):
    entry = Measurement(name=name, group_id=group_id, synergy_rule=synergy_rule)
    session.add(entry)
    session.commit()
    return entry.id


class Join__Instrument_Measurement(DeclarativeBase):
    __tablename__ = 'Join__Instrument_Measurement'
    id            = Column(Integer, primary_key=True)
    measurement_id = Column('measurement_id', Integer, ForeignKey('Measurement.id'))
    instrument_id = Column('instrument_id', Integer, ForeignKey('Instrument.id'))
    problem_id    = Column('problem_id', Integer, ForeignKey('Problem.id'))
def index_instrument_measurement(session, measurement_id, instrument_id, problem_id):
    entry = Join__Instrument_Measurement(measurement_id=measurement_id, instrument_id=instrument_id, problem_id=problem_id)
    session.add(entry)
    session.commit()
    return entry.id





def get_measurement_name(measurement):
    first_quote_index = measurement.find('"')+1
    measurement_id = measurement[first_quote_index:]
    second_quote_index = measurement_id.find('"')
    return measurement_id[:second_quote_index]

def index_measurements(session, problem, path, group_id, global_data):
    data = []
    xls = pd.ExcelFile(path)
    sheets = xls.sheet_names
    for sheet in sheets:
        if sheet not in instrument_list:
            continue
        df = pd.read_excel(xls, sheet, header=None)
        df = df.dropna(how='all')

        for index, row in df.iterrows():
            measurement_slot_type = get_measurement_name(row[0])
            measurement_name = get_measurement_name(row[1])
            # measurement_type = get_measurement_name(row[2])
            print("indexing measurement")
            print("measurement name:", measurement_name)

            meas_id = None
            if session.query(Measurement.group_id, Measurement.name).filter_by(group_id=group_id, name=measurement_name).scalar() is None:
                entry = Measurement(name=measurement_name, group_id=group_id)
                session.add(entry)
                session.commit()
                data.append([measurement_name, entry.id])
                meas_id = entry.id
            else:
                meas_query = session.query(Measurement.id, Measurement.name).filter_by(group_id=group_id, name=measurement_name).first()
                meas_id = meas_query[0]

            if(meas_id == None):
                print("Measurement id not foound in data")
                exit()

            print("--> Measurement ID", meas_id)
            inst_meas_id = index_instrument_measurement(session, meas_id, global_data['instruments'][sheet], global_data['problems'][problem])

            
        
            
    return data

def get_measurement_id(session, name, group_id):
    problem_id_query = session.query(Measurement.id, Measurement.name).filter(Measurement.name == name).filter(Measurement.group_id == group_id).first()
    problem_id = problem_id_query[0]
    return problem_id



def index_global_attribute(session, problem, path, group_id, sheet, problem_id):
    data = []
    xls = pd.ExcelFile(path)
    df = pd.read_excel(xls, sheet, header=0, usecols='A:DA')
    df = df.dropna(how='all')
    for index, row in df.iterrows():
        slot_type = row[0]
        name = row[1].strip()
        type = row[3]
        entry = None
        if sheet == 'Measurement':
            entry = Measurement_Attribute(name=name, group_id=group_id, slot_type=slot_type, type=type)
            if session.query(Measurement_Attribute.name).filter_by(name=name, group_id=group_id).scalar() is None:
                session.add(entry)
                session.commit()
                data.append([name, entry.id])
        elif sheet == 'Instrument':
            entry = Instrument_Attribute(name=name, group_id=group_id, slot_type=slot_type, type=type)
            if session.query(Instrument_Attribute.name).filter_by(name=name, group_id=group_id).scalar() is None:
                session.add(entry)
                session.commit()
                data.append([name, entry.id])
        elif sheet == 'Orbit':
            entry = Orbit_Attribute(name=name, group_id=group_id, slot_type=slot_type, type=type)
            if session.query(Orbit_Attribute.name).filter_by(name=name, group_id=group_id).scalar() is None:
                session.add(entry)
                session.commit()
                data.append([name, entry.id])
        elif sheet == 'Launch-vehicle':
            entry = Launch_Vehicle_Attribute(name=name, group_id=group_id, slot_type=slot_type, type=type)
            if session.query(Launch_Vehicle_Attribute.name).filter_by(name=name, group_id=group_id).scalar() is None:
                session.add(entry)
                session.commit()
                data.append([name, entry.id])
        elif sheet == 'Mission':
            entry = Mission_Attribute(name=name, problem_id=problem_id, slot_type=slot_type, type=type)
            if session.query(Mission_Attribute.name).filter_by(name=name, problem_id=problem_id).scalar() is None:
                session.add(entry)
                session.commit()
                data.append([name, entry.id])
        elif sheet == 'Attribute Inheritance':
            entry = Inheritence_Attribute(problem_id=problem_id, \
                template1=row[0], \
                copySlotType1=row[1], \
                copySlotName1=row[2], \
                matchingSlotType1=row[3], \
                matchingSlotName1=row[4], \
                template2=row[5], \
                matchingSlotName2=row[6], \
                copySlotName2=row[7], \
                module=row[8])
            session.add(entry)
            session.commit()
            data.append([name, entry.id])
            continue
        index_accepted_values(session, row, sheet, group_id, entry.id)
    return data











def get_measurement_attribute_id(session, name, group_id):
    problem_id_query = session.query(Measurement_Attribute.id, Measurement_Attribute.name).filter(Measurement_Attribute.name == name).filter(Measurement_Attribute.group_id == group_id).first()
    problem_id = problem_id_query[0]
    return problem_id




class Measurement_Attribute(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Measurement_Attribute'
    id = Column(Integer, primary_key=True)
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    name = Column('name', String)
    slot_type = Column('slot_type', String)
    type = Column('type', String)


class Join__Measurement_Attribute_Values(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Join__Measurement_Attribute_Values'
    id = Column(Integer, primary_key=True)
    attribute_id = Column('attribute_id', Integer, ForeignKey('Measurement_Attribute.id'))
    value_id = Column('value_id', Integer, ForeignKey('Accepted_Value.id'))


class Instrument_Attribute(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Instrument_Attribute'
    id = Column(Integer, primary_key=True)
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    name = Column('name', String)
    slot_type = Column('slot_type', String)
    type = Column('type', String)

class Join__Instrument_Attribute_Values(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Join__Instrument_Attribute_Values'
    id = Column(Integer, primary_key=True)
    attribute_id = Column('attribute_id', Integer, ForeignKey('Instrument_Attribute.id'))
    value_id = Column('value_id', Integer, ForeignKey('Accepted_Value.id'))


class Orbit_Attribute(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Orbit_Attribute'
    id = Column(Integer, primary_key=True)
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    name = Column('name', String)
    slot_type = Column('slot_type', String)
    type = Column('type', String)

class Join__Orbit_Attribute_Values(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Join__Orbit_Attribute_Values'
    id = Column(Integer, primary_key=True)
    attribute_id = Column('attribute_id', Integer, ForeignKey('Orbit_Attribute.id'))
    value_id = Column('value_id', Integer, ForeignKey('Accepted_Value.id'))


class Launch_Vehicle_Attribute(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Launch_Vehicle_Attribute'
    id = Column(Integer, primary_key=True)
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    name = Column('name', String)
    slot_type = Column('slot_type', String)
    type = Column('type', String)

class Join__Launch_Vehicle_Attribute_Values(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Join__Launch_Vehicle_Attribute_Values'
    id = Column(Integer, primary_key=True)
    attribute_id = Column('attribute_id', Integer, ForeignKey('Launch_Vehicle_Attribute.id'))
    value_id = Column('value_id', Integer, ForeignKey('Accepted_Value.id'))


class Mission_Attribute(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Mission_Attribute'
    id = Column(Integer, primary_key=True)
    problem_id = Column('problem_id', Integer, ForeignKey('Problem.id'))
    name = Column('name', String)
    slot_type = Column('slot_type', String)
    type = Column('type', String)

class Join__Mission_Attribute_Values(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Join__Mission_Attribute_Values'
    id = Column(Integer, primary_key=True)
    attribute_id = Column('attribute_id', Integer, ForeignKey('Mission_Attribute.id'))
    value_id = Column('value_id', Integer, ForeignKey('Accepted_Value.id'))


class Inheritence_Attribute(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Inheritence_Attribute'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problem.id'))
    template1 = Column('template1', String)
    copySlotType1 = Column('copySlotType1', String)
    copySlotName1 = Column('copySlotName1', String)
    matchingSlotType1 = Column('matchingSlotType1', String)
    matchingSlotName1 = Column('matchingSlotName1', String)
    template2 = Column('template2', String)
    matchingSlotName2 = Column('matchingSlotName2', String)
    copySlotName2 = Column('copySlotName2', String)
    module = Column('module', String)





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




def index_fuzzy_attribute_arch(problems_dir, session, problems):
    files = [(problem, problems_dir+'/'+problem+'/xls/AttributeSet.xls') for problem in problems]
    for problem, path in files:
        problem_id = get_problem_id(session, problem, 1)
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







class Architecture(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Architecture'
    id = Column(Integer, primary_key=True)
    problem_id = Column('problem_id', Integer, ForeignKey('Problem.id'))
    dataset_id = Column('dataset_id', Integer, ForeignKey('Dataset.id'))
    user_id = Column('user_id', Integer, ForeignKey('auth_user.id'))
    input = Column('input', String)
    science = Column('science', Float)
    cost = Column('cost', Float)
    ga = Column('ga', Boolean, default=False)
    improve_hv = Column('improve_hv', Boolean, default=False)
    eval_status = Column('eval_status', Boolean, default=True) # if false, arch needs to be re-evaluated
    critique = Column('critique', String) 
def index_architecture(session, problem_id, dataset_id, input, science, cost, user_id=None):
    entry = Architecture(problem_id=problem_id, dataset_id=dataset_id, input=input, science=science, cost=cost, user_id=user_id)
    session.add(entry)
    session.commit()




class ArchitectureCostInformation(DeclarativeBase):
    __tablename__ = 'ArchitectureCostInformation'
    id = Column(Integer, primary_key=True)
    architecture_id = Column('architecture_id', Integer, ForeignKey('Architecture.id'))
    mission_name = Column('mission_name', String) 
    launch_vehicle = Column('launch_vehicle', String) 
    mass = Column('mass', Float) 
    power = Column('power', Float) 
    cost = Column('cost', Float) 
    others = Column('others', Float) 

class ArchitecturePayload(DeclarativeBase):
    __tablename__ = 'ArchitecturePayload'
    id = Column(Integer, primary_key=True)
    arch_cost_id = Column('arch_cost_id', Integer, ForeignKey('ArchitectureCostInformation.id'))
    instrument_id = Column('instrument_id', Integer, ForeignKey('Instrument.id'))

class ArchitectureBudget(DeclarativeBase):
    __tablename__ = 'ArchitectureBudget'
    id = Column(Integer, primary_key=True)
    mission_attribute_id = Column('mission_attribute_id', Integer, ForeignKey('Mission_Attribute.id'))
    arch_cost_id = Column('arch_cost_id', Integer, ForeignKey('ArchitectureCostInformation.id'))
    value = Column('value', Float) 

class ArchitectureScoreExplanation(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'ArchitectureScoreExplanation'
    id = Column(Integer, primary_key=True)
    architecture_id = Column('architecture_id', Integer, ForeignKey('Architecture.id'))
    panel_id = Column('panel_id', Integer, ForeignKey('Stakeholder_Needs_Panel.id'))
    satisfaction = Column('satisfaction', Float)

class PanelScoreExplanation(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'PanelScoreExplanation'
    id = Column(Integer, primary_key=True)
    architecture_id = Column('architecture_id', Integer, ForeignKey('Architecture.id'))
    objective_id = Column('objective_id', Integer, ForeignKey('Stakeholder_Needs_Objective.id'))
    satisfaction = Column('satisfaction', Float)

class ObjectiveScoreExplanation(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'ObjectiveScoreExplanation'
    id = Column(Integer, primary_key=True)
    architecture_id = Column('architecture_id', Integer, ForeignKey('Architecture.id'))
    subobjective_id = Column('subobjective_id', Integer, ForeignKey('Stakeholder_Needs_Subobjective.id'))
    satisfaction = Column('satisfaction', Float)













class Accepted_Value(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Accepted_Value'
    id = Column(Integer, primary_key=True)
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    value = Column('value', String)

def index_accepted_values(session, row, sheet, group_id, attribute_id):
    if len(row) <= 4 or pd.isna(row[4]):
        return None

    accepted_values = get_accepted_values(session, row)
    for value in accepted_values:
        value_id = None
        if session.query(Accepted_Value.value).filter_by(value=value, group_id=group_id).scalar() is None:
            entry = Accepted_Value(value=value, group_id=group_id)
            session.add(entry)
            session.commit()
            value_id = entry.id
        else:
            value_id = get_accepted_value_id(session, group_id, value)

        if sheet == 'Measurement':
            join_entry = Join__Measurement_Attribute_Values(attribute_id=attribute_id, value_id=value_id)
        elif sheet == 'Instrument':
            join_entry = Join__Instrument_Attribute_Values(attribute_id=attribute_id, value_id=value_id)
        elif sheet == 'Orbit':
            join_entry = Join__Orbit_Attribute_Values(attribute_id=attribute_id, value_id=value_id)
        elif sheet == 'Launch-vehicle':
            join_entry = Join__Launch_Vehicle_Attribute_Values(attribute_id=attribute_id, value_id=value_id)
        elif sheet == 'Mission':
            join_entry = Join__Mission_Attribute_Values(attribute_id=attribute_id, value_id=value_id)

        session.add(join_entry)
        session.commit()


def get_accepted_values(session, row, col__num_accepted_vals=4):
    accepted_value_names = []
    num_accepted_vals = int(row[col__num_accepted_vals])
    col__first_accepted_val = col__num_accepted_vals + 1
    print(row)
    for index in range(num_accepted_vals):
        col__current_idx = col__first_accepted_val + index
        try:
            accepted_value_name = row[col__current_idx]
            if not pd.isna(accepted_value_name):
                accepted_value_names.append(str(accepted_value_name))
        except:
            return accepted_value_names
    return accepted_value_names



def get_accepted_value_id(session, group_id, value):
    accepted_value_id_query = session.query(Accepted_Value.id, Accepted_Value.value).filter(Accepted_Value.group_id == group_id).filter(Accepted_Value.value == value).first()
    accepted_value_id = accepted_value_id_query[0]
    print("Found accepted value", accepted_value_id)
    return accepted_value_id


    

