import os
import pandas as pd
import xlrd
import sys
import numpy as np





sheet_names = [
    'Power',
    'Launch Vehicles'
]


class Orbits:
    orb_file_name = 'Mission Analysis Database.xls'


    def __init__(self, client, problem_dir="/app/daphne/VASSAR_resources/vassar/problems"):
        self.client = client
        self.problem_dir = problem_dir
        self.problems = os.listdir(problem_dir)
        self.files = [(problem, problem_dir + '/' + problem + '/xls/' + self.orb_file_name) for problem in self.problems]
        orbs = []
        for problem, path in self.files:
            df = pd.read_excel(path, 'Power', header=0)
            for index, row in df.iterrows():
                orbs.append(row[0])
        self.orbits = list(dict.fromkeys(orbs))
        print(self.orbits)

        lvs = []
        for problem, path in self.files:
            df = pd.read_excel(path, 'Launch Vehicles', header=0)
            for index, row in df.iterrows():
                lvs.append(row[0])
        self.launch_vehicles = list(dict.fromkeys(lvs))
        print(self.launch_vehicles)




    def index(self):
        smap_orbit_list = [
            'LEO-600-polar-NA',
            'SSO-600-SSO-AM',
            'SSO-600-SSO-DD',
            'SSO-800-SSO-AM',
            'SSO-800-SSO-DD'
        ]

        # GROUP ORBITS
        for orb in self.orbits:
            self.client.index_orbit(orb)

        # PROBLEM ORBITS
        for problem, path in self.files:
            df = pd.read_excel(path, 'Power', header=0)
            for index, row in df.iterrows():
                if (problem in ['SMAP', 'SMAP_JPL1', 'SMAP_JPL2']) and row[0] not in smap_orbit_list:
                    continue
                self.client.index_problem_orbit(
                    self.client.get_problem_id(problem),
                    self.client.get_orbit_id(row[0])
                )

        for lv in self.launch_vehicles:
            self.client.index_launch_vehicle(lv)
        for problem, path in self.files:
            df = pd.read_excel(path, 'Launch Vehicles', header=0)
            for index, row in df.iterrows():
                self.client.index_problem_lv(
                    self.client.get_problem_id(problem),
                    self.client.get_lv_id(row[0])
                )

    def index_local(self):
        for problem, path in self.files:
            problem_id = self.client.get_problem_id(problem)
            xls = pd.ExcelFile(path)
            if problem == 'SMAP':
                # LAUNCH VEHICLES
                df = pd.read_excel(xls, 'Launch Vehicles', header=0, keep_default_na=False, dtype=np.unicode_)
                df = df.dropna(how='all')
                col_labels = df.columns.to_numpy().tolist()
                for index, row in df.iterrows():
                    lv_id = self.client.get_lv_id(row[0])
                    for idx, col in enumerate(row):
                        if idx == 0:
                            continue
                        value = col
                        lv_attribute_id = self.client.get_lv_attribute_id(col_labels[idx])
                        self.client.index_launch_vehicle_attribiute(lv_id, lv_attribute_id, value)

                # ORBITS
                df = pd.read_excel(xls, 'Power', header=0, keep_default_na=False, dtype=np.unicode_)
                df = df.dropna(how='all')
                col_labels = df.columns.to_numpy().tolist()
                for index, row in df.iterrows():
                    orbit_id = self.client.get_orbit_id(row[0])
                    for idx, col in enumerate(row):
                        if idx == 0:
                            continue
                        value = col
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
                        orbit_attribute_id = self.client.get_orbit_attribute_id(col_labels[idx])
                        self.client.index_join_orbit_attribute(orbit_id, orbit_attribute_id, value)











