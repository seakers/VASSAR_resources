import os
import xlrd
import pandas as pd
# from models_arch.base import DeclarativeBase


global_attributes = [
    'Measurement',
    'Instrument',
    'Orbit',
    'Launch-vehicle',
    'Mission',
    'Attribute Inheritance'
]


class Attributes:

    inst_file_name = 'AttributeSet.xls'
    id_data = {}

    def __init__(self, client, problems_dir='/app/daphne/VASSAR_resources/vassar/problems', group_id=1):
        self.group_id = group_id
        self.client = client
        self.problems = os.listdir(problems_dir)
        self.files = [(problem, problems_dir + '/' + problem + '/xls/' + self.inst_file_name) for problem in self.problems]


    def index(self):
        for problem, path in self.files:
            for sheet in global_attributes:
                self.client.index_global_attribute(problem, path, 1, sheet, self.client.get_problem_id(problem))


    def index_fuzzy_rules(self):
        problem_to_index = ['SMAP', 'Decadal2017Aerosols', 'Decadal2007']
        for problem, path in self.files:
            if (problem in problem_to_index):
                problem_id = self.client.get_problem_id(problem)
                df = pd.read_excel(path, sheet_name='Fuzzy Attributes', header=0)
                df = df.dropna(how='all')
                for index, row in df.iterrows():
                    name = row[0]
                    parameter = row[1]
                    unit = row[2]
                    entry_id = self.client.index_fuzzy_attribute(problem_id, name, parameter, unit)
                    self.index_fuzzy_value(row, entry_id)
        return 0

    def index_fuzzy_value(self, row, fuzzy_attribute_id , col__num_fuzzy_values=3):
        num_values = int(row[col__num_fuzzy_values])
        col__first_fuzzy_value = col__num_fuzzy_values + 1
        for index in range(num_values):
            current_index = col__first_fuzzy_value + (index * 4)
            value = row[current_index]
            minimum = float(row[current_index + 1])
            mean = float(row[current_index + 2])
            maximum = float(row[current_index + 3])
            self.client.index_fuzzy_value(fuzzy_attribute_id, value, minimum, mean, maximum)
        return 0
