from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime, Time, Enum, ForeignKey, Table, CheckConstraint, and_
from sqlalchemy.orm import relationship
from sqlalchemy.types import ARRAY
from models.base import DeclarativeBase
from sqlalchemy.engine.url import URL
import numpy as np
import pandas as pd
from models.models import Problem, get_problem_id



#######
### MissionAnalysisDatabase.xls - completed
#######




class Walker_Mission_Analysis(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Walker_Mission_Analysis'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problem.id'))
    sats_per_plane = Column('sats_per_plane', Float)
    num_planes = Column('num_planes', Float)
    orbit_altitude = Column('orbit_altitude', Float)
    orbit_inclination = Column('orbit_inclination', String)
    instrument_fov = Column('instrument_fov', Float)
    avg_revisit_time_global = Column('avg_revisit_time_global', Float)
    avg_revisit_time_tropics = Column('avg_revisit_time_tropics', Float)
    avg_revisit_time_northern_hemisphere = Column('avg_revisit_time_northern_hemisphere', Float)
    avg_revisit_time_southern_hemisphere = Column('avg_revisit_time_southern_hemisphere', Float)
    avg_revisit_time_cold_regions = Column('avg_revisit_time_cold_regiouis', Float)
    avg_revisit_time_us = Column('avg_revisit_time_us', Float)
    mission_architecture = Column('mission_architecture', String)
def index_walker_mission_analysis(problems_dir, session, problems):
    files = [(problem, problems_dir+'/'+problem+'/xls/Mission Analysis Database.xls') for problem in problems]
    analysis_type = 'Walker'
    for problem, path in files:
        problem_id = get_problem_id(session, problem)
        df = pd.read_excel(path, sheet_name=analysis_type, header=0, usecols='A:L')
        df = df.dropna(how='all')
        index_mission_analysis(session, analysis_type, df, problem_id, problem)
    return 0



class Power_Mission_Analysis(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Power_Mission_Analysis'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problem.id'))

    orbit_id = Column('orbit_id', String)
    orbit_type = Column('orbit_type', String)
    altitude = Column('altitude', Float)
    inclination = Column('inclination', Float)
    RAAN = Column('RAAN', String)
    fraction_of_sunlight = Column('fraction_of_sunlight', String)
    period = Column('period', Float)
    worst_sun_angles = Column('worst_sun_angles', Float)
    max_eclipse_time = Column('max_eclipse_time', Float)
def index_power_mission_analysis(problems_dir, session, problems):
    files = [(problem, problems_dir+'/'+problem+'/xls/Mission Analysis Database.xls') for problem in problems]
    analysis_type = 'Power'
    for problem, path in files:
        problem_id = get_problem_id(session, problem)
        df = pd.read_excel(path, sheet_name=analysis_type, header=0, usecols='A:I')
        df = df.dropna(how='all')
        index_mission_analysis(session, analysis_type, df, problem_id, problem)
    return 0



class Launch_Vehicle_Mission_Analysis(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Launch_Vehicle_Mission_Analysis'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problem.id'))


    vehicle_id = Column('vehicle_id', String)

    payload_geo = Column('payload_geo', ARRAY(Float))

    diameter = Column('diameter', Float)

    height = Column('height', Float)

    payload_leo_polar = Column('payload_leo_polar', ARRAY(Float))

    payload_sso = Column('payload_sso', ARRAY(Float))

    payload_leo_equat = Column('payload_leo_equat', ARRAY(Float))

    payload_meo = Column('payload_meo', ARRAY(Float))

    payload_heo = Column('payload_heo', ARRAY(Float))

    payload_iss = Column('payload_iss', ARRAY(Float))

    cost = Column('cost', Float)
def index_launch_vehicle_mission_analysis(problems_dir, session, problems):
    files = [(problem, problems_dir+'/'+problem+'/xls/Mission Analysis Database.xls') for problem in problems]
    analysis_type = 'Launch Vehicles'
    for problem, path in files:
        problem_id = get_problem_id(session, problem)
        usecols = None
        if problem in ['Decadal2017Aerosols', 'ClimateCentric']:
            usecols = 'A:K'
        else:
            usecols = 'A:J'
        df = pd.read_excel(path, sheet_name=analysis_type, header=0, usecols=usecols)
        df = df.dropna(how='all')
        index_mission_analysis(session, analysis_type, df, problem_id, problem)
    return 0






def string_to_float_list(str_list):
    float_list = str_list.strip('][').split(',')
    float_list = [float(element) for element in float_list]
    return float_list


def index_mission_analysis(session, analysis_type, data_frame, problem_id, problem_name):
    for index, row in data_frame.iterrows():
        if analysis_type == 'Walker':
            entry = Walker_Mission_Analysis(sats_per_plane=float(row[0]), num_planes=float(row[1]), \
                                            orbit_altitude=float(row[2]), orbit_inclination=row[3], \
                                            instrument_fov=float(row[4]), avg_revisit_time_global=float(row[5]), \
                                            avg_revisit_time_tropics=float(row[6]), avg_revisit_time_northern_hemisphere=float(row[7]), \
                                            avg_revisit_time_southern_hemisphere=float(row[8]), avg_revisit_time_cold_regions=float(row[9]), \
                                            avg_revisit_time_us=float(row[10]), mission_architecture=row[11], \
                                            problem_id=problem_id)
        elif analysis_type == 'Power':
            entry = Power_Mission_Analysis(orbit_id=row[0], orbit_type=row[1], \
                                            altitude=float(row[2]), inclination=float(row[3]), \
                                            RAAN=row[4], fraction_of_sunlight=row[5], \
                                            period=float(row[6]), worst_sun_angles=float(row[7]), \
                                            max_eclipse_time=float(row[8]), problem_id=problem_id)
        elif analysis_type == 'Launch Vehicles':
            payload_geo = string_to_float_list(row[1])
            payload_leo_polar = string_to_float_list(row[4])
            payload_sso = string_to_float_list(row[5])
            payload_leo_equat = string_to_float_list(row[6])
            payload_meo = string_to_float_list(row[7])
            payload_heo = string_to_float_list(row[8])
            if problem_name in ['Decadal2017Aerosols', 'ClimateCentric']:
                payload_iss = string_to_float_list(row[9])
                entry = Launch_Vehicle_Mission_Analysis(vehicle_id=row[0], payload_geo=payload_geo, \
                                            diameter=float(row[2]), height=float(row[3]), \
                                            payload_leo_polar=payload_leo_polar, payload_sso=payload_sso, \
                                            payload_leo_equat=payload_leo_equat, payload_meo=payload_meo, \
                                            payload_heo=payload_heo, payload_iss=payload_iss, problem_id=problem_id, cost=float(row[10]))
            else:
                entry = Launch_Vehicle_Mission_Analysis(vehicle_id=row[0], payload_geo=payload_geo, \
                                            diameter=float(row[2]), height=float(row[3]), \
                                            payload_leo_polar=payload_leo_polar, payload_sso=payload_sso, \
                                            payload_leo_equat=payload_leo_equat, payload_meo=payload_meo, \
                                            payload_heo=payload_heo, payload_iss=None, problem_id=problem_id, cost=float(row[9]))
        session.add(entry)
        session.commit()
    return 0