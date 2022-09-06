import os
import pandas as pd


class Architectures:



    def __init__(self, client, problem_dir="/problems"):
        self.client = client
        self.problem_dir = problem_dir
        self.problems = ["SMAP", "ClimateCentric"]
        self.problem_dirs = [problem_dir + '/' + problem for problem in self.problems]


    def index(self):

        # --> Index Datasets
        for problem in self.problems:
            problem_id = self.client.get_problem_id(problem)
            dataset_id = self.client.index_dataset("default", problem_id, None, None)
            filepath = '/app/problem_default_archs/' + problem + '/default.csv'
            if os.path.isfile(filepath):
                df = pd.read_csv(filepath, header=0)
                for index, row in df.iterrows():
                    input = row[0]
                    science = row[1]
                    cost = row[2]
                    self.client.index_architecture(problem_id, dataset_id, input, science, cost)


