import os
import pandas as pd


class Architectures:



    def __init__(self, client, problem_dir="/app/daphne/VASSAR_resources/vassar/problems"):
        self.client = client
        self.problem_dir = problem_dir
        self.problems = os.listdir(problem_dir)
        self.problem_dirs = [problem_dir + '/' + problem for problem in self.problems]


    def index(self):
        for problem in self.problems:
            if problem != "SMAP" and problem != "SMAP_JPL1" and problem != "SMAP_JPL2":
                if problem in ["ClimateCentric", 'ClimateCentric_1', 'ClimateCentric_2']:
                    problem_id = self.client.get_problem_id(problem)
                    dataset_id = self.client.index_dataset("default", problem_id, None, None)
                continue
            problem_id = self.client.get_problem_id(problem)
            dataset_id = self.client.index_dataset("default", problem_id, None, None)
            filepath = '/app/daphne/VASSAR_resources/problem_default_archs/' + problem + '/default.csv'
            df = pd.read_csv(filepath, header=0)
            for index, row in df.iterrows():
                input = row[0]
                science = row[1]
                cost = row[2]
                self.client.index_architecture(problem_id, dataset_id, input, science, cost)

