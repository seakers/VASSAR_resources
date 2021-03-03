from models_arch.Client import Client
from models_arch.Problems import Problems
from models_arch.Architectures import Architectures
from models_arch.Instruments import Instruments
from models_arch.Orbits import Orbits
from models_arch.Attributes import Attributes
from models_arch.Requirements import Requirements


from models_arch.stakeholders import index_group_stakeholders

from models_arch.Client import index_walker_mission_analysis


default_group_name = 'seakers (default)'




def main():
    client = Client()
    client.drop_tables()
    client.initialize()

    print(client.index_group(default_group_name))

    problems = Problems(client)
    problems.index()

    index_walker_mission_analysis(client)

    archs = Architectures(client)
    archs.index()

    insts = Instruments(client)
    insts.index()

    orbs = Orbits(client)
    orbs.index()

    attr = Attributes(client)
    attr.index()
    attr.index_fuzzy_rules()

    orbs.index_local()
    insts.index_local()

    data = {}
    index_group_stakeholders(client.get_session(), data, client)

    req = Requirements(client)
    req.index()




















if __name__ == "__main__":
    main()