import os

from models_arch.base import DeclarativeBase
from sqlalchemy import create_engine, MetaData, Table
from sqlalchemy.orm import sessionmaker, mapper
from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime, Time, Enum, ForeignKey, Table, CheckConstraint, Boolean, ARRAY, and_
import pandas as pd





class Client:

    user = os.environ['USER']
    password = os.environ['PASSWORD']
    postgres_host = os.environ['POSTGRES_HOST']
    postgres_port = os.environ['POSTGRES_PORT']
    vassar_db_name = 'daphne'
    db_string = f'postgresql+psycopg2://{user}:{password}@{postgres_host}:{postgres_port}/{vassar_db_name}'

    def __init__(self):
        self.engine = create_engine(self.db_string, echo=True)
        Session = sessionmaker(bind=self.engine)
        self.session = Session()

    def initialize(self):
        self.drop_tables()
        self.create_tables()

    def get_session(self):
        return self.session

    def create_tables(self):
        DeclarativeBase.metadata.create_all(self.engine)

    # DELETE ALL TABLES BUT: auth_user
    def drop_tables(self):
        to_delete = []
        for table, table_obj in DeclarativeBase.metadata.tables.items():
            print(table, '\n')
            if table is not 'auth_user':
                to_delete.append(table_obj)
        DeclarativeBase.metadata.drop_all(self.engine, to_delete)


    # INDEX
    def index_group(self, name):
        entry = Group(name=name)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_problem(self, name, group_id):
        entry = Problem(name=name, group_id=group_id)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_authuser_group(self, user_id, group_id, admin=False):
        entry = Join__AuthUser_Group(user_id=user_id, group_id=group_id, admin=admin)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_problem_instrument(self, problem_id, instrument_id):
        entry = Join__Problem_Instrument(problem_id=problem_id, instrument_id=instrument_id)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_problem_orbit(self, problem_id, orbit_id):
        entry = Join__Problem_Orbit(problem_id=problem_id, orbit_id=orbit_id)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_problem_lv(self, problem_id, launch_vehicle_id):
        entry = Join__Problem_Launch_Vehicle(problem_id=problem_id, launch_vehicle_id=launch_vehicle_id)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_launch_vehicle(self, name, group_id=1):
        entry = Launch_Vehicle(name=name, group_id=group_id)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_instrument(self, name, group_id=1):
        entry = Instrument(name=name, group_id=group_id)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_orbit(self, name, group_id=1):
        entry = Orbit(name=name, group_id=group_id)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_measurement(self, name, group_id=1, synergy_rule=False):
        entry = Measurement(name=name, group_id=group_id, synergy_rule=synergy_rule)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_instrument_measurement(self, measurement_id, instrument_id, problem_id):
        entry = Join__Instrument_Measurement(measurement_id=measurement_id, instrument_id=instrument_id, problem_id=problem_id)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_measurement_attribute(self, group_id, name, slot_type, type):
        entry = Measurement_Attribute(name=name, group_id=group_id, slot_type=slot_type, type=type)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_measurement_attribute_value(self, attribute_id, value_id):
        entry = Join__Measurement_Attribute_Values(attribute_id=attribute_id, value_id=value_id)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_instrument_attribute(self, group_id, name, slot_type, type):
        entry = Instrument_Attribute(group_id=group_id, name=name, slot_type=slot_type, type=type)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_instrument_attribute_value(self, attribute_id, value_id):
        entry = Join__Instrument_Attribute_Values(attribute_id=attribute_id, value_id=value_id)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_orbit_attribute(self, group_id, name, slot_type, type):
        entry = Orbit_Attribute(group_id=group_id, name=name, slot_type=slot_type, type=type)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_join_orbit_attribute(self, orbit_id, orbit_attribute_id, value, group_id=1):
        entry = Join__Orbit_Attribute(group_id=group_id, orbit_id=orbit_id, orbit_attribute_id=orbit_attribute_id, value=value)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_join_orbit_attribute_value(self, attribute_id, value_id):
        entry = Join__Orbit_Attribute_Values(attribute_id=attribute_id, value_id=value_id)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_lv_attribute(self, group_id, name, slot_type, type):
        entry = Launch_Vehicle_Attribute(group_id=group_id, name=name, slot_type=slot_type, type=type)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_lv_attribute_value(self, attribute_id, value_id):
        entry = Join__Launch_Vehicle_Attribute_Values(attribute_id=attribute_id, value_id=value_id)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_mission_attribute(self, group_id, name, slot_type, type):
        entry = Mission_Attribute(group_id=group_id, name=name, slot_type=slot_type, type=type)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_mission_attribute_value(self, attribute_id, value_id):
        entry = Join__Mission_Attribute_Values(attribute_id=attribute_id, value_id=value_id)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_inheritence_attribute(self, problem_id, template1, copySlotType1, copySlotName1, matchingSlotType1, matchingSlotName1, template2, matchingSlotName2, copySlotName2, module):
        entry = Inheritence_Attribute(problem_id=problem_id, template1=template1, copySlotType1=copySlotType1, copySlotName1=copySlotName1, matchingSlotType1=matchingSlotType1, matchingSlotName1=matchingSlotName1, template2=template2, matchingSlotName2=matchingSlotName2, copySlotName2=copySlotName2, module=module)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_fuzzy_attribute(self, problem_id, name, parameter, unit):
        entry = Fuzzy_Attribute(problem_id=problem_id, name=name, parameter=parameter, unit=unit)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_fuzzy_value(self, fuzzy_attribute_id, value, minimum, mean, maximum):
        entry = Fuzzy_Value(fuzzy_attribute_id=fuzzy_attribute_id, value=value, minimum=minimum, mean=mean, maximum=maximum)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_accepted_value(self, group_id, value):
        entry = Accepted_Value(group_id=group_id, value=value)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_architecture(self, problem_id, input, science, cost, user_id=None):
        entry = Architecture(problem_id=problem_id, user_id=user_id, input=input, science=science, cost=cost)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_instrument_capability(self, instrument_id, measurement_id, measurement_attribute_id, value, group_id=1):
        entry = Join__Instrument_Capability(group_id=group_id, instrument_id=instrument_id, measurement_id=measurement_id, measurement_attribute_id=measurement_attribute_id, value=value)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_instrument_characteristic(self, problem_id, instrument_id, instrument_attribute_id, value, group_id=1):
        entry = Join__Instrument_Characteristic(group_id=group_id, problem_id=problem_id, instrument_id=instrument_id,  instrument_attribute_id=instrument_attribute_id, value=value)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_launch_vehicle_attribiute(self, launch_vehicle_id, launch_vehicle_attribute_id, value, group_id=1):
        entry = Join__Launch_Vehicle_Attribute(group_id=group_id, launch_vehicle_id=launch_vehicle_id, launch_vehicle_attribute_id=launch_vehicle_attribute_id, value=value)
        self.session.add(entry)
        self.session.commit()
        return entry.id


    def index_requirement_rule_attribute(self, problem_id, subobjective_id, measurement_id, measurement_attribute_id,
                                         type, thresholds, scores, justification):
        entry = Requirement_Rule_Attribute(problem_id=problem_id, subobjective_id=subobjective_id,
                                           measurement_id=measurement_id,
                                           measurement_attribute_id=measurement_attribute_id, type=type,
                                           thresholds=thresholds, scores=scores, justification=justification)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_requirement_rule_case(self, problem_id, subobjective_id, measurement_id, objective_id,
                                    rule, value, text, description):
        entry = Requirement_Rule_Case(problem_id=problem_id, subobjective_id=subobjective_id,
                                      measurement_id=measurement_id, objective_id=objective_id,
                                      rule=rule, value=value, text=text, description=description)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_requirement_rule_case_attribute(self, rule_id, measurement_attribute_id, value, operation=None):
        entry = Join__Case_Attribute(rule_id=rule_id, measurement_attribute_id=measurement_attribute_id,
                                     operation=operation, value=value)
        self.session.add(entry)
        self.session.commit()
        return entry.id


    def index_stakeholder_panel(self, problem_id, name, description, weight, index_id):
        entry = Stakeholder_Needs_Panel(problem_id=problem_id, name=name, description=description, weight=weight, index_id=index_id)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_stakeholder_objective(self, problem_id, name, description, weight, panel_id):
        entry = Stakeholder_Needs_Objective(problem_id=problem_id, name=name, description=description, weight=weight, panel_id=panel_id)
        self.session.add(entry)
        self.session.commit()
        return entry.id

    def index_stakeholder_subobjective(self, problem_id, name, description, weight, objective_id):
        entry = Stakeholder_Needs_Subobjective(problem_id=problem_id, name=name, description=description, weight=weight, objective_id=objective_id)
        self.session.add(entry)
        self.session.commit()
        return entry.id





    # QUERY
    def get_measurement_attribute_id(self, name, group_id=1):
        meas_attrs = self.session.query(Measurement_Attribute.id, Measurement_Attribute.name).filter(Measurement_Attribute.name == name).filter(Measurement_Attribute.group_id == group_id).first()
        meas_attr_id = meas_attrs[0]
        return meas_attr_id

    def get_measurement_id(self, name, group_id=1, auto_index=False):
        measurements = self.session.query(Measurement.id, Measurement.name).filter(Measurement.name == name).filter(Measurement.group_id == group_id).first()
        if auto_index is True and measurements is None:
            return self.index_measurement(name)
        meas_id = measurements[0]
        return meas_id

    def get_problem_id(self, problem_name, group_id=1):
        problem_id_query = self.session.query(Problem.id, Problem.name).filter(Problem.name == problem_name).filter(Problem.group_id == group_id).first()
        problem_id = problem_id_query[0]
        return problem_id

    def get_instrument_id(self, inst_name, group_id=1):
        problem_id_query = self.session.query(Instrument.id, Instrument.name).filter(Instrument.name == inst_name).filter(Instrument.group_id == group_id).first()
        problem_id = problem_id_query[0]
        return problem_id

    def get_orbit_id(self, inst_name, group_id=1):
        problem_id_query = self.session.query(Orbit.id, Orbit.name).filter(Orbit.name == inst_name).filter(Orbit.group_id == group_id).first()
        problem_id = problem_id_query[0]
        return problem_id

    def get_orbit_attribute_id(self, name, group_id=1):
        problem_id_query = self.session.query(Orbit_Attribute.id, Orbit_Attribute.name).filter(Orbit_Attribute.name == name).filter(Orbit_Attribute.group_id == group_id).first()
        problem_id = problem_id_query[0]
        return problem_id

    def get_lv_id(self, inst_name, group_id=1):
        problem_id_query = self.session.query(Launch_Vehicle.id, Launch_Vehicle.name).filter(Launch_Vehicle.name == inst_name).filter(Launch_Vehicle.group_id == group_id).first()
        problem_id = problem_id_query[0]
        return problem_id

    def get_lv_attribute_id(self, name, group_id=1):
        problem_id_query = self.session.query(Launch_Vehicle_Attribute.id, Launch_Vehicle_Attribute.name).filter(Launch_Vehicle_Attribute.name == name).filter(Launch_Vehicle_Attribute.group_id == group_id).first()
        problem_id = problem_id_query[0]
        return problem_id

    def get_instrument_attribute_id(self, name, group_id=1):
        problem_id_query = self.session.query(Instrument_Attribute.id, Instrument_Attribute.name).filter(
            Instrument_Attribute.name == name).filter(Instrument_Attribute.group_id == group_id).first()
        problem_id = problem_id_query[0]
        return problem_id

    def get_panel_id(self, problem_id, index_id):
        panel_id_query = self.session.query(Stakeholder_Needs_Panel.id, Stakeholder_Needs_Panel.name).filter(
            and_(Stakeholder_Needs_Panel.index_id == index_id,
                 Stakeholder_Needs_Panel.problem_id == problem_id)).first()
        panel_id = panel_id_query[0]
        return panel_id

    def get_num_problem_panels(self, problem_id):
        panel_id_query = self.session.query(Stakeholder_Needs_Panel.id, Stakeholder_Needs_Panel.name).filter(Stakeholder_Needs_Panel.problem_id == problem_id).all()
        return len(panel_id_query)

    def get_objective_id__subobjective(self, name, problem_id):
        objective_id_query = self.session.query(Stakeholder_Needs_Objective.id, Stakeholder_Needs_Objective.name).filter(
            and_(Stakeholder_Needs_Objective.name == name,
                 Stakeholder_Needs_Objective.problem_id == problem_id)).first()
        objective_id = objective_id_query[0]
        return objective_id

    def get_subobjective_id(self, name, problem_id):
        subobjective_id_query = self.session.query(Stakeholder_Needs_Subobjective.id,
                                              Stakeholder_Needs_Subobjective.name).filter(
            and_(Stakeholder_Needs_Subobjective.name == name,
                 Stakeholder_Needs_Subobjective.problem_id == problem_id)).first()
        subobjective_id = subobjective_id_query[0]
        return subobjective_id

    def does_meas_exist(self, name, group_id=1):
        return self.session.query(Measurement.group_id, Measurement.name).filter_by(group_id=group_id, name=name).scalar()



    def index_global_attribute(self, problem, path, group_id, sheet, problem_id):
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
                if self.session.query(Measurement_Attribute.name).filter_by(name=name, group_id=group_id).scalar() is None:
                    self.session.add(entry)
                    self.session.commit()
                    data.append([name, entry.id])
            elif sheet == 'Instrument':
                entry = Instrument_Attribute(name=name, group_id=group_id, slot_type=slot_type, type=type)
                if self.session.query(Instrument_Attribute.name).filter_by(name=name, group_id=group_id).scalar() is None:
                    self.session.add(entry)
                    self.session.commit()
                    data.append([name, entry.id])
            elif sheet == 'Orbit':
                entry = Orbit_Attribute(name=name, group_id=group_id, slot_type=slot_type, type=type)
                if self.session.query(Orbit_Attribute.name).filter_by(name=name, group_id=group_id).scalar() is None:
                    self.session.add(entry)
                    self.session.commit()
                    data.append([name, entry.id])
            elif sheet == 'Launch-vehicle':
                entry = Launch_Vehicle_Attribute(name=name, group_id=group_id, slot_type=slot_type, type=type)
                if self.session.query(Launch_Vehicle_Attribute.name).filter_by(name=name,
                                                                          group_id=group_id).scalar() is None:
                    self.session.add(entry)
                    self.session.commit()
                    data.append([name, entry.id])
            elif sheet == 'Mission':
                entry = Mission_Attribute(name=name, problem_id=problem_id, slot_type=slot_type, type=type)
                if self.session.query(Mission_Attribute.name).filter_by(name=name, problem_id=problem_id).scalar() is None:
                    self.session.add(entry)
                    self.session.commit()
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
                self.session.add(entry)
                self.session.commit()
                data.append([name, entry.id])
                continue
            self.index_accepted_values(row, sheet, group_id, entry.id)
        return data

    def index_accepted_values(self, row, sheet, group_id, attribute_id):
        if len(row) <= 4 or pd.isna(row[4]):
            return None
        accepted_values = self.get_accepted_values(row)
        for value in accepted_values:
            value_id = None
            if self.session.query(Accepted_Value.value).filter_by(value=value, group_id=group_id).scalar() is None:
                entry = Accepted_Value(value=value, group_id=group_id)
                self.session.add(entry)
                self.session.commit()
                value_id = entry.id
            else:
                value_id = self.get_accepted_value_id(group_id, value)

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

            self.session.add(join_entry)
            self.session.commit()

    def get_accepted_values(self, row, col__num_accepted_vals=4):
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

    def get_accepted_value_id(self, group_id, value):
        accepted_value_id_query = self.session.query(Accepted_Value.id, Accepted_Value.value).filter(
            Accepted_Value.group_id == group_id).filter(Accepted_Value.value == value).first()
        accepted_value_id = accepted_value_id_query[0]
        print("Found accepted value", accepted_value_id)
        return accepted_value_id



 #   _____ _       _           _
 #  / ____| |     | |         | |
 # | |  __| | ___ | |__   __ _| |
 # | | |_ | |/ _ \| '_ \ / _` | |
 # | |__| | | (_) | |_) | (_| | |
 #  \_____|_|\___/|_.__/ \__,_|_|

global_client = Client()

class auth_user(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'auth_user'
    __table_args__ = {'autoload': True}

class Group(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Group'
    id = Column(Integer, primary_key=True)
    name = Column('name', String)


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

class Join__Problem_Launch_Vehicle(DeclarativeBase):
    __tablename__ = 'Join__Problem_Launch_Vehicle'
    id            = Column(Integer, primary_key=True)
    problem_id    = Column('problem_id', Integer, ForeignKey('Problem.id'))
    launch_vehicle_id = Column('launch_vehicle_id', Integer, ForeignKey('Launch_Vehicle.id'))

class Launch_Vehicle(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Launch_Vehicle'
    id = Column(Integer, primary_key=True)
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    name = Column('name', String)

class Instrument(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Instrument'
    id = Column(Integer, primary_key=True)
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    name = Column('name', String)

class Orbit(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Orbit'
    id = Column(Integer, primary_key=True)
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    name = Column('name', String)

class Measurement(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Measurement'
    id = Column(Integer, primary_key=True)
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    name = Column('name', String)
    synergy_rule = Column('synergy_rule', Boolean, default=False)

class Join__Instrument_Measurement(DeclarativeBase):
    __tablename__ = 'Join__Instrument_Measurement'
    id            = Column(Integer, primary_key=True)
    measurement_id = Column('measurement_id', Integer, ForeignKey('Measurement.id'))
    instrument_id = Column('instrument_id', Integer, ForeignKey('Instrument.id'))
    problem_id    = Column('problem_id', Integer, ForeignKey('Problem.id'))

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

class Join__Orbit_Attribute(DeclarativeBase):
    __tablename__ = 'Join__Orbit_Attribute'
    id = Column(Integer, primary_key=True)
    orbit_id = Column('orbit_id', Integer, ForeignKey('Orbit.id')) # nullable
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    orbit_attribute_id = Column('orbit_attribute_id', Integer, ForeignKey('Orbit_Attribute.id'))
    value = Column('value', String, default=False)

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

class Join__Launch_Vehicle_Attribute(DeclarativeBase):
    __tablename__ = 'Join__Launch_Vehicle_Attribute'
    id = Column(Integer, primary_key=True)
    value = Column('value', String, default=False)
    launch_vehicle_id = Column('launch_vehicle_id', Integer, ForeignKey('Launch_Vehicle.id')) # nullable
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    launch_vehicle_attribute_id = Column('launch_vehicle_attribute_id', Integer, ForeignKey('Launch_Vehicle_Attribute.id'))

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

class Accepted_Value(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Accepted_Value'
    id = Column(Integer, primary_key=True)
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    value = Column('value', String)

class Architecture(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Architecture'
    id = Column(Integer, primary_key=True)
    problem_id = Column('problem_id', Integer, ForeignKey('Problem.id'))
    user_id = Column('user_id', Integer, ForeignKey('auth_user.id'))
    input = Column('input', String)
    science = Column('science', Float)
    cost = Column('cost', Float)
    ga = Column('ga', Boolean, default=False)
    improve_hv = Column('improve_hv', Boolean, default=False)
    eval_status = Column('eval_status', Boolean, default=True) # if false, arch needs to be re-evaluated
    critique = Column('critique', String)

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






# ARCHITECTURE STUFF
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


 #  _                     _
 # | |                   | |
 # | |     ___   ___ __ _| |
 # | |    / _ \ / __/ _` | |
 # | |___| (_) | (_| (_| | |
 # |______\___/ \___\__,_|_|

# measurement attribute values vary across instruments
class Join__Instrument_Capability(DeclarativeBase):
    __tablename__ = 'Join__Instrument_Capability'
    id = Column(Integer, primary_key=True)
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    instrument_id = Column('instrument_id', Integer, ForeignKey('Instrument.id')) # nullable
    measurement_id = Column('measurement_id', Integer, ForeignKey('Measurement.id'))
    measurement_attribute_id = Column('measurement_attribute_id', Integer, ForeignKey('Measurement_Attribute.id'))
    requirement_rule_case_id = Column('requirement_rule_case_id', Integer, ForeignKey('Requirement_Rule_Case.id'))
    descriptor = Column('descriptor', String, default=False)
    value = Column('value', String, default=False)

# instrument attribute values vary across problems
class Join__Instrument_Characteristic(DeclarativeBase):
    __tablename__ = 'Join__Instrument_Characteristic'
    id = Column(Integer, primary_key=True)
    group_id = Column('group_id', Integer, ForeignKey('Group.id'))
    instrument_id = Column('instrument_id', Integer, ForeignKey('Instrument.id')) # nullable
    problem_id = Column('problem_id', Integer, ForeignKey('Problem.id')) # nullable
    instrument_attribute_id = Column('instrument_attribute_id', Integer, ForeignKey('Instrument_Attribute.id'))
    value = Column('value', String, default=False)



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










class Stakeholder_Needs_Panel(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Stakeholder_Needs_Panel'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problem.id'))
    name = Column('name', String)
    description = Column('description', String)
    weight = Column('weight', Float)
    index_id = Column('index_id', String, nullable=True)

class Stakeholder_Needs_Objective(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Stakeholder_Needs_Objective'
    id = Column(Integer, primary_key=True)
    panel_id = Column(Integer, ForeignKey('Stakeholder_Needs_Panel.id'))
    problem_id = Column(Integer, ForeignKey('Problem.id'))
    name = Column('name', String)
    description = Column('description', String)
    weight = Column('weight', Float)

class Stakeholder_Needs_Subobjective(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Stakeholder_Needs_Subobjective'
    id = Column(Integer, primary_key=True)
    objective_id = Column(Integer, ForeignKey('Stakeholder_Needs_Objective.id'))
    problem_id = Column(Integer, ForeignKey('Problem.id'))
    name = Column('name', String)
    description = Column('description', String)
    weight = Column('weight', Float)







class Requirement_Rule_Case(DeclarativeBase):
    __tablename__ = 'Requirement_Rule_Case'
    id = Column(Integer, primary_key=True)
    # FK
    problem_id = Column('problem_id', Integer, ForeignKey('Problem.id'))  # nullable
    objective_id = Column(Integer, ForeignKey('Stakeholder_Needs_Objective.id'))
    subobjective_id = Column('subobjective_id', Integer, ForeignKey('Stakeholder_Needs_Subobjective.id'))
    measurement_id = Column('measurement_id', Integer, ForeignKey('Measurement.id'))
    # Fields
    rule = Column('rule', String, default=False)
    value = Column('value', String, default=False)
    text = Column('text', String, default=False)
    description = Column('description', String, default=False)



class Join__Case_Attribute(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Join__Case_Attribute'
    id = Column(Integer, primary_key=True)
    # FK1
    rule_id = Column(Integer, ForeignKey('Requirement_Rule_Case.id'))
    measurement_attribute_id = Column(Integer, ForeignKey('Measurement_Attribute.id'))
    # Fields
    operation = Column('operation', String, nullable=True)
    value = Column('value', String)

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


def index_walker_mission_analysis(client, problems_dir='/app/daphne/VASSAR_resources/problems', problems=['Decadal2007']):
    session = client.get_session()
    files = [(problem, problems_dir+'/'+problem+'/xls/Mission Analysis Database.xls') for problem in problems]
    analysis_type = 'Walker'
    for problem, path in files:
        print('---> ', files)
        problem_id = client.get_problem_id(problem)
        df = pd.read_excel(path, sheet_name=analysis_type, header=0, usecols='A:L')
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


def string_to_float_list(str_list):
    float_list = str_list.strip('][').split(',')
    float_list = [float(element) for element in float_list]
    return float_list

def index_mission_analysis(session, analysis_type, data_frame, problem_id, problem_name):
    for index, row in data_frame.iterrows():
        if analysis_type == 'Walker':
            entry = Walker_Mission_Analysis(sats_per_plane=float(row[0]), num_planes=float(row[1]), \
                                            orbit_altitude=float(row[2]), orbit_inclination=row[3], \
                                            instrument_fov=float(row[4]), avg_revisit_time_global=round(float(row[5]), 1), \
                                            avg_revisit_time_tropics=round(float(row[6]), 1), avg_revisit_time_northern_hemisphere=round(float(row[7]), 1), \
                                            avg_revisit_time_southern_hemisphere=round(float(row[8]), 1), avg_revisit_time_cold_regions=round(float(row[9]),1), \
                                            avg_revisit_time_us=round(float(row[10]),1), mission_architecture=row[11], \
                                            problem_id=problem_id)
        elif analysis_type == 'Power':
            entry = Power_Mission_Analysis(orbit_id=row[0], orbit_type=row[1], \
                                            altitude=float(row[2]), inclination=float(row[3]), \
                                            RAAN=row[4], fraction_of_sunlight=row[5], \
                                            period=round(float(row[6]),0), worst_sun_angles=round(float(row[7]),2), \
                                            max_eclipse_time=round(float(row[8]),0), problem_id=problem_id)
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



