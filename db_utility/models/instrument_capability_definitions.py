from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime, Time, Enum, ForeignKey, Table, CheckConstraint, and_
from sqlalchemy.orm import relationship
from sqlalchemy.types import ARRAY
from models.base import DeclarativeBase
from sqlalchemy.engine.url import URL
import numpy as np
import pandas as pd
from models.models import Problem, get_problem_id
from models.attribute_set import Instrument_Attribute, Measurement_Attribute



#######
### InstrumentCapabilityDefinitions.xls - in progress
#######

default_instruments = {
    'all': [
        'CLOUD_MASK',
        'SMAP_RAD',
        'SMAP_MWR',
        'VIIRS',
        'CMIS',
        'BIOMASS',
        'ALT',
        'CLAR_TIR',
        'CLAR_VNIR',
        'GPS',
        'ACE_CPR',
        'ACE_ORCA',
        'ACE_POL',
        'ACE_LID',
        'CLAR_ERB',
        'DESD_SAR',
        'DESD_LID',
        'GACM_VIS',
        'HYSP_TIR',
        'CNES_KaRIN',
        'POSTEPS_IRS',
        'CLAR_TIR',
        'CLAR_VNIR'
    ],
    'SMAP': ['CLOUD_MASK','SMAP_RAD','SMAP_MWR','VIIRS', 'CMIS','BIOMASS', 'ALT', 'CLAR_TIR', 'CLAR_VNIR','GPS'],
    'SMAP_JPL1': ['CLOUD_MASK','SMAP_RAD','SMAP_MWR','VIIRS', 'CMIS','BIOMASS', 'ALT', 'CLAR_TIR', 'CLAR_VNIR','GPS'],
    'SMAP_JPL2': ['CLOUD_MASK','SMAP_RAD','SMAP_MWR','VIIRS', 'CMIS','BIOMASS', 'ALT', 'CLAR_TIR', 'CLAR_VNIR','GPS'],
    'ClimateCentric': [
        'ACE_CPR',
        'ACE_ORCA',
        'ACE_POL',
        'ACE_LID',
        'CLAR_ERB',
        'DESD_SAR',
        'DESD_LID',
        'GACM_VIS',
        'HYSP_TIR',
        'CNES_KaRIN',
        'POSTEPS_IRS'
    ],
    'Decadal2017Aerosols': [
        'ACE_CPR',
        'ACE_ORCA',
        'ACE_POL',
        'ACE_LID',
        'CLAR_TIR',
        'CLAR_VNIR'
    ],

}


class Instrument(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Instrument'
    id = Column(Integer, primary_key=True)
    name = Column('name', String)
Group_Instrument_Join = Table('Group_Instrument_Join', DeclarativeBase.metadata,
                        Column('group_id', Integer, ForeignKey('Group.id')),
                        Column('instrument_id', Integer, ForeignKey('Instrument.id')))
class Join__Group_Instrument(DeclarativeBase):
    __tablename__ = 'Join__Group_Instrument'
    id = Column(Integer, primary_key=True)
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    instrument_id = Column('instrument_id', Integer, ForeignKey('Instrument.id'))




def create_instrument(session, name):
    entry = Instrument(name=name)
    session.add(entry)
    session.commit()
    return entry.id
def join_group_instrument(session, group_id, instrument_id):
    entry = Join__Group_Instrument(group_id=group_id,instrument_id=instrument_id)
    session.add(entry)
    session.commit()
    return entry.id

def create_default_instruments(session, problems_dir, problems, default_group_id):
    instrument_id_dict = {} # Contains all the instrument IDs

    # Index Instrument / Join__Group_Instrument
    for inst in default_instruments['all']:
        instrument_id = create_instrument(session, inst)
        join_id = join_group_instrument(session, default_group_id, instrument_id)
        instrument_id_dict[inst] = instrument_id

    # Instrument_Capability
    files = [(problem, problems_dir+'/'+problem+'/xls/Instrument Capability Definition.xls') for problem in problems]
    attribute_type = 'instrument'

    for problem, path in files:
        index_instrument_measurement(session, path, problem, instrument_id_dict)

    for problem, path in files:
        df_characteristics = pd.read_excel(path, sheet_name='CHARACTERISTICS', header=0)
        index_instrument_characteristic(session, df_characteristics, instrument_id_dict, problem)

    return 0








def get_measurement_attribute(session, name, problem_id):
    query = session.query(Measurement_Attribute.problem_id, Measurement_Attribute.id, Measurement_Attribute.name).filter(Measurement_Attribute.name == name).filter(Measurement_Attribute.problem_id == problem_id).all()
    if len(query) == 0:
        return False
    return query


# FOR EACH: PROBLEM
def index_instrument_measurement(session, path, problem, instrument_id_dict):
    problem_id = get_problem_id(session, problem)
    problem_instruments = default_instruments[problem]

    # FOR EACH: PROBLEM INSTRUMENT
    for instrument in problem_instruments:
        instrument_id = instrument_id_dict[instrument]                                                ### instrument_id
        df = pd.read_excel(path, sheet_name=instrument, header=0)
        df = df.dropna(how='all')
        for index, row in df.iterrows():
            measurement_name = get_measurement_name(row[1])                                           ### measurement_name

            # FOR EACH: ATTRIBUTE
            for x in range(len(row)):
                if x == 0 or x == 1:
                    continue
                print("#############################________________________ ROW", problem, instrument, row, x)
                attribute_name, value = get_attribute_details(row[x])                                 ### value
                measurement_attribute = get_measurement_attribute(session, attribute_name, problem_id)
                if not measurement_attribute:
                    print("Error, no measurement attribute returned")
                    exit()
                measurement_attribute_id = measurement_attribute[0][1]                                ### measurement_attribute_id
                entry = Instrument_Capability(instrument_id=instrument_id,measurement_name=measurement_name,value=value,measurement_attribute_id=measurement_attribute_id)
                session.add(entry)
                session.commit()
    return 0








class Instrument_Capability(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Instrument_Capability'
    id = Column(Integer, primary_key=True)
    instrument_id = Column(Integer, ForeignKey('Instrument.id'))
    measurement_attribute_id = Column(Integer, ForeignKey('Measurement_Attribute.id'))
    measurement_name = Column('measurement_name', String, nullable=True)
    value = Column('value', String)


class Instrument_Characteristic(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Instrument_Characteristic'
    id = Column(Integer, primary_key=True)
    instrument_id = Column(Integer, ForeignKey('Instrument.id'))
    instrument_attribute_id = Column(Integer, ForeignKey('Instrument_Attribute.id'))
    value = Column('value', String)




def get_measurement_name(measurement):
    first_quote_index = measurement.find('"')+1
    measurement_id = measurement[first_quote_index:]
    second_quote_index = measurement_id.find('"')
    return measurement_id[:second_quote_index]

def get_attribute_details(attribute):
    details = attribute.split()
    return details[0], details[1]




def get_tuple_object(problem_id, tuple_obj):
    if tuple_obj == False:
        return False
    for obj in tuple_obj:
        if obj[0] == problem_id:
            return obj
    return False
    







def query_instrument_attribute(session, name, problem_id):
    query = session.query(Instrument_Attribute.problem_id, Instrument_Attribute.id, Instrument_Attribute.name).filter(Instrument_Attribute.name == name).filter(Instrument_Attribute.problem_id == problem_id).all()
    if len(query) == 0:
        print("NO INSTRUMENT ATTRIBUTE FOUND FOR", name, problem_id)
        return False
    return query


def index_instrument_characteristic(session, df, instrument_id_dict, problem_name):
    problem_id = get_problem_id(session, problem_name)
    df = df.dropna(how='all')
    for index, row in df.iterrows():

        # INSTRUMENT ID
        instrument_name = None
        name_items = row[0].split()
        if len(name_items) == 1:
            if name_items[0] == 'Name':
                continue
            else:
                instrument_name = name_items[0]
        else:
            instrument_name = name_items[1]
        if instrument_name not in instrument_id_dict:
            continue
        instrument_id = instrument_id_dict[instrument_name]

        # CHARACTERISTIC ROW
        for x in range(len(row)):
            if x == 0:
                continue
            if type(row[x]) == float:
                continue

            # CELL: INSTRUMENT_ATTRIBUTE | VALUE
            print("#############################________________________ ROWdd", type(row[x]), row[x], problem_name, instrument_name, row, x)
            attribute_name, attribute_value = get_attribute_details(row[x])
            found_attr = query_instrument_attribute(session, attribute_name, problem_id)
            instrument_attribute_id = found_attr[0][1]

            entry = Instrument_Characteristic(instrument_id=instrument_id,instrument_attribute_id=instrument_attribute_id,value=str(attribute_value))
            session.add(entry)
            session.commit()
    return 0





