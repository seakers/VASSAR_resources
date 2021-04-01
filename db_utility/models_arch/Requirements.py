import os
import xlrd
import json
import pandas as pd
# from models_arch.base import DeclarativeBase





class Requirements:

    inst_file_name = 'Requirement Rules.xls'
    id_data = {}



    def __init__(self, client, problems_dir='/app/daphne/VASSAR_resources/vassar/problems', group_id=1):
        self.group_id = group_id
        self.client = client
        self.problems = os.listdir(problems_dir)
        self.files = [(problem, problems_dir + '/' + problem + '/xls/' + self.inst_file_name) for problem in self.problems]



    def index(self):
        for problem, path in self.files:
            if problem == 'Decadal2007':
                self.index_by_case(problem, path, 2)
            elif problem == 'Decadal2017Aerosols':
                self.index_by_case(problem, path)
                continue
            else:
                self.index_by_attribute(problem, path)


    def index_by_case(self, problem, path, base=0):
        problem_id = self.client.get_problem_id(problem)
        xls = pd.ExcelFile(path)
        df = pd.read_excel(xls, 'Cases', header=0, usecols='A:M')
        df = df.dropna(how='all')
        for index, row in df.iterrows():
            objective_id = self.client.get_objective_id__subobjective(row[0], problem_id)
            rule_text = row[1]
            subobjective_id = self.client.get_subobjective_id(row[2], problem_id)

            rule_rule = row[base+3]
            rule_value = round(float(row[base+4]), 2)
            description = row[base+5].replace('"','')
            measurement_id = self.client.get_measurement_id(self.format_measurement_rule(row[base+6]), 1, True)
            rule_id = self.client.index_requirement_rule_case(problem_id, subobjective_id, measurement_id,
                                                              objective_id, rule_rule, rule_value, rule_text, description)
            self.index_case_attributes(rule_id, row, base)
        return 0


    def index_case_attributes(self, rule_id, row, base=0):
        for idx, col in enumerate(row):
            print('-----> ', col)
            if idx < (base+7):
                continue
            if pd.isna(col):
                continue
            col_items = col.split()
            if len(col_items) == 3:
                operation = col_items[0]
                meas_attr = col_items[1]
                meas_attr_id = self.client.get_measurement_attribute_id(meas_attr)
                value = col_items[2]
                self.client.index_requirement_rule_case_attribute(rule_id, meas_attr_id, value, operation)
            elif len(col_items) == 2:
                meas_attr = col_items[0]
                meas_attr_id = self.client.get_measurement_attribute_id(meas_attr)
                value = col_items[1]
                self.client.index_requirement_rule_case_attribute(rule_id, meas_attr_id, value)
        return 0





    def index_by_attribute(self, problem, path):
        problem_id = self.client.get_problem_id(problem)
        xls = pd.ExcelFile(path)
        df = pd.read_excel(xls, 'Attributes', header=0, usecols='A:G')
        df = df.dropna(how='all')
        for index, row in df.iterrows():
            print('---> ', row, problem)
            subobjective_id = self.client.get_subobjective_id(row[0], problem_id)  # subobjective_id
            print("----->", self.format_measurement_rule(row[1]), problem, row)
            measurement_id = self.client.get_measurement_id(self.format_measurement_rule(row[1]), 1, True)
            measurement_attribute_id = self.client.get_measurement_attribute_id(row[2])
            type = str(row[3])
            thresholds = row[4].strip('][').split(',')
            scores = row[5].strip('][').split(',')
            scores = [round(float(element), 2) for element in scores]
            justification = self.format_measurement_rule(row[6])
            self.client.index_requirement_rule_attribute(problem_id, subobjective_id, measurement_id, measurement_attribute_id,
                                                         type, thresholds, scores, justification)
        return 0

    def format_measurement_rule(self, rule):
        if rule[0] == '"' and rule[-1:] == '"':
            rule = rule[1:-1]
        return rule

