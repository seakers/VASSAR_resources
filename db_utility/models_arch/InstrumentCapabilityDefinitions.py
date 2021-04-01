import os







class InstrumentCapabilityDefinitions:

    def __init__(self, client, problems_dir='/app/daphne/VASSAR_resources/vassar/problems', inst_file_name='Instrument Capability Definition.xls'):
        self.problems = os.listdir(problems_dir)
        self.files = [(problem, problems_dir + '/' + problem + '/xls/' + inst_file_name) for problem in self.problems]



