from sqlalchemy import create_engine, Column, Integer, Float, String, DateTime, Time, Enum, ForeignKey, Table, CheckConstraint, Boolean
import os
import xlrd
import json
import pandas as pd
import sys
# from models_arch.base import DeclarativeBase





class Instruments:

    inst_file_name = 'Instrument Capability Definition.xls'
    id_data = {}



    def __init__(self, client, problems_dir='/app/vassar_resources/problems', group_id=1):
        self.group_id = group_id
        self.client = client
        self.problems = os.listdir(problems_dir)
        self.files = [(problem, problems_dir + '/' + problem + '/xls/' + self.inst_file_name) for problem in self.problems]
        instruments = []
        true_insts = []
        for problem, path in self.files:
            wb = xlrd.open_workbook(path)
            instruments = instruments + wb.sheet_names()
            true_insts = true_insts + self.get_characteristic_insts(wb)
        self.instruments = list(dict.fromkeys(instruments))
        self.instruments.remove('del')
        self.instruments.remove('CHARACTERISTICS')
        self.instruments.remove('CHARACTERISTICS_old')
        self.insts_true = true_insts


    def get_characteristic_insts(self, wb):
        sheet = wb.sheet_by_name('CHARACTERISTICS')
        first_col = sheet.col(0)
        insts = []
        for idx, x in enumerate(first_col):
            if idx == 0:
                continue
            spl = (x.value).split()
            if len(spl) == 1:
                continue
            insts.append(spl[1])
        print(insts)
        return insts

    def get_measurement_name(self, measurement):
        first_quote_index = measurement.find('"') + 1
        measurement_id = measurement[first_quote_index:]
        second_quote_index = measurement_id.find('"')
        return measurement_id[:second_quote_index]



    def index(self):
        smap_insts = [
            'SMAP_MWR',
            'SMAP_RAD',
            'VIIRS',
            'CMIS',
            'BIOMASS'
        ]

        # INSTRUMENTS
        for instr in self.instruments:
            self.client.index_instrument(instr)
        for problem, path in self.files:
            problem_insts = xlrd.open_workbook(path).sheet_names()
            problem_insts.remove('del')
            problem_insts.remove('CHARACTERISTICS')
            if 'CHARACTERISTICS_old' in problem_insts:
                problem_insts.remove('CHARACTERISTICS_old')
            for inst in problem_insts:
                if inst in self.insts_true:
                    if problem == 'SMAP' and inst not in smap_insts:
                        continue
                    self.client.index_problem_instrument(
                        self.client.get_problem_id(problem),
                        self.client.get_instrument_id(inst)
                    )

        # MEASUREMENTS
        for problem, path in self.files:
            xls = pd.ExcelFile(path)
            sheets = xls.sheet_names
            problem_id = self.client.get_problem_id(problem)
            for sheet in sheets:
                if sheet not in self.instruments:
                    continue
                df = pd.read_excel(xls, sheet, header=None)
                df = df.dropna(how='all')
                for index, row in df.iterrows():
                    measurement_slot_type = self.get_measurement_name(row[0])
                    measurement_name = self.get_measurement_name(row[1])
                    meas_id = None
                    if self.client.does_meas_exist(measurement_name) is None:
                        meas_id = self.client.index_measurement(measurement_name)
                    else:
                        meas_id = self.client.get_measurement_id(measurement_name)
                    self.client.index_instrument_measurement(
                        meas_id,
                        self.client.get_instrument_id(sheet),
                        problem_id
                    )



    def index_local(self):
        for problem, path in self.files:
            problem_id = self.client.get_problem_id(problem)

            # GROUP CHARACTERISTICS
            xls = pd.ExcelFile(path)
            df = pd.read_excel(xls, 'CHARACTERISTICS', header=0)
            df = df.dropna(how='all')
            col_labels = df.columns.get_values().tolist()
            print("------<>", path)
            for index, row in df.iterrows():
                print('----------------------->', row)
                name_items = row[0].split()
                if len(name_items) == 1:
                    instrument_name = name_items[0]
                else:
                    instrument_name = name_items[1]
                instrument_id = self.client.get_instrument_id(instrument_name)
                for idx, col in enumerate(row):
                    if idx == 0 or pd.isna(col):
                        continue
                    attr_data = col.split()
                    instrument_attribute_name = attr_data[0]
                    instrument_attribute_id = self.client.get_instrument_attribute_id(instrument_attribute_name)
                    if instrument_attribute_name == 'Intent' or instrument_attribute_name == 'Concept':
                        attr_data.pop(0)
                        valued = ' '.join(attr_data)
                        value = valued.replace('"', '')
                        print(value)
                    else:
                        value = str(attr_data[1])
                    self.client.index_instrument_characteristic(problem_id, instrument_id, instrument_attribute_id, value)

            # INSTRUMENT CAPABILITIES (measurement attribute values) DO NOT CHANGE ACROSS PROBLEMS, BUT ACROSS INSTRUMENTS
            if problem == 'SMAP' or problem == 'Decadal2007' or problem == 'Decadal2017Aerosols':
                xls = pd.ExcelFile(path)
                sheets = xls.sheet_names
                for sheet in sheets:
                    if sheet not in self.instruments:
                        continue
                    instrument_id = self.client.get_instrument_id(sheet)
                    df = pd.read_excel(xls, sheet, header=None)
                    df = df.dropna(how='all')
                    for index, row in df.iterrows():
                        measurement_name = self.get_measurement_name(row[1])
                        measurement_id = self.client.get_measurement_id(measurement_name)  # measurement_id
                        for idx, col in enumerate(row):
                            if idx == 0 or idx == 1:
                                continue
                            print('------> DDDDD', col, sheet)
                            measurement_data = self.get_measurement_attribute_data(col)
                            measurement_attribute_id = measurement_data[0]
                            value = measurement_data[1]
                            self.client.index_instrument_capability(instrument_id, measurement_id, measurement_attribute_id, value)


    def get_measurement_attribute_data(self, col):
        items = col.split()
        measurement_attribute_name = items[0]
        value = items[1]
        measurement_attribute_id = self.client.get_measurement_attribute_id(measurement_attribute_name)
        return [measurement_attribute_id, value]












