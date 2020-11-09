import os







class Problems:

    problem_map = {}

    def __init__(self, client, problem_dir="/app/daphne/VASSAR_resources/problems"):
        self.client       = client
        self.problem_dir  = problem_dir
        self.problems     = os.listdir(problem_dir)
        self.problem_dirs = [problem_dir+'/'+problem for problem in self.problems]

    def index(self):
        for problem in self.problems:
            self.problem_map[problem] = self.client.index_problem(problem, 1)

