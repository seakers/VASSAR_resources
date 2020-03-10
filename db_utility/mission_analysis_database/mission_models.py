from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime, Time, Enum, ForeignKey, Table, \
    CheckConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.engine.url import URL

DeclarativeBase = declarative_base()





# --------------------------------> MissionAnalysisDatabase.xls
class Walker_Mission_Analysis(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Walker_Mission_Analysis'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problem.id'))
    sats_per_plane = Column('sats_per_plane', Float)
    num_planes = Column('num_planes', Float)
    orbit_altitude = Column('orbit_altitude', Float)
    orbit_inclination = Column('orbit_inclination', Float)
    instrument_fov = Column('instrument_fov', Float)
    avg_revisit_time_global = Column('avg_revisit_time_global', Float)
    avg_revisit_time_tropics = Column('avg_revisit_time_tropics', Float)
    avg_revisit_time_northern_hemisphere = Column('avg_revisit_time_northern_hemisphere', Float)
    avg_revisit_time_southern_hemisphere = Column('avg_revisit_time_southern_hemisphere', Float)
    avg_revisit_time_cold_regiouis = Column('avg_revisit_time_cold_regiouis', Float)
    avg_revisit_time_us = Column('avg_revisit_time_us', Float)
    mission_architecture = Column('mission_architecture', String)


class Power_Mission_Analysis(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Power_Mission_Analysis'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problem.id'))
    type = Column('type', String)
    inclination = Column('inclination', Float)
    RAAN = Column('RAAN', String)
    fraction_of_sunlight = Column('float', Float)
    period = Column('period', Float)
    worst_sun_angles = Column('worst_sun_angles', Float)
    max_eclipse_time = Column('max_eclipse_time', Float)

class Launch_Vehicle_Mission_Analysis(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Launch_Vehicle_Mission_Analysis'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problem.id'))
    payload_geo_list = Column('payload_geo_list', String)
    diameter = Column('diameter', Float)
    height = Column('height', Float)
    payload_leo_polar_list = Column('payload_leo_polar_list', String)
    nampayload_sso_liste = Column('payload_sso_list', String)
    payload_leo_equat_list = Column('payload_leo_equat_list', String)
    payload_meo_list = Column('payload_meo_list', String)
    payload_heo_list = Column('payload_heo_list', Float)
    cost = Column('cost', String)