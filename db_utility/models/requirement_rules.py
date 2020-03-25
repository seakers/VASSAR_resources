from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime, Time, Enum, ForeignKey, Table, CheckConstraint, and_
from sqlalchemy.orm import relationship
from sqlalchemy.types import ARRAY
from models.base import DeclarativeBase
from sqlalchemy.engine.url import URL
import numpy as np
import pandas as pd
from models.models import Problem, get_problem_id



#######
### RequirementRules.xls - in progress
#######


# --------------------------------> RequirementRules.xls
class Requirement_Rule_Attribute(DeclarativeBase):
    """Sqlalchemy broad measurement categories model"""
    __tablename__ = 'Requirement_Rule_Attribute'
    id = Column(Integer, primary_key=True)
    problem_id = Column(Integer, ForeignKey('Problem.id'))
    subobjective = Column('subobjective', String)
    measurement = Column('measurement', String)
    attribute = Column('attribute', String)
    attribute_type = Column('type', String)

    threshold = Column('threshold', ARRAY(String))
    scores = Column('scores', ARRAY(Float))

    justification = Column('justification', String)
    units = Column('units', String)
    notes = Column('notes', String)
def index_requirement_rules(problems_dir, session, problem_name):
    problem_dir = problems_dir + '/' + problem_name + '/xls'  # /app/daphne/VASSAR_resources/problems/SMAP/xls
    file_path = problem_dir + "/Requirement Rules.xls"        # /app/daphne/VASSAR_resources/problems/SMAP/xls/Requirement Rules.xls

    # Get the problem ID from the Problems table
    problem_id = get_problem_id(session, problem_name)

    # Get DataFrame
    df = pd.read_excel(file_path, header=0, usecols='A:I')
    df = df.dropna(how='all')

    if problem_name in ['ClimateCentric', 'Decadal2017Aerosols']:
        df.columns = ['subobjective', 'measurement', 'attribute', 'type', 'thresholds', 'scores', 'justification', 'units', 'notes']
    else:
        df.columns = ['subobjective', 'measurement', 'attribute', 'type', 'thresholds', 'scores', 'justification']

    for index, row in df.iterrows():
        subobjective = row[0]
        measurement = row[1]
        attribute = row[2]
        attribute_type = row[3]

        threshold_str = row[4]
        threshold_list = threshold_str.strip('][').split(',')

        scores_str = row[5]
        scores_list = scores_str.strip('][').split(',')
        print(scores_list)
        scores_list = [float(element) for element in scores_list]

        justification = row[6]

        if problem_name in ['ClimateCentric', 'Decadal2017Aerosols']:
            units = str(row[7])
            notes = str(row[8])
            entry = Requirement_Rule_Attribute(problem_id=problem_id, subobjective=subobjective, measurement=measurement, attribute=attribute, attribute_type=attribute_type, threshold=threshold_list, scores=scores_list, justification=justification, units=units, notes=notes)
        else:
            entry = Requirement_Rule_Attribute(problem_id=problem_id, subobjective=subobjective, measurement=measurement, attribute=attribute, attribute_type=attribute_type, threshold=threshold_list, scores=scores_list, justification=justification)

        session.add(entry)
        session.commit()
    
    print(df)
    print(df.shape)


