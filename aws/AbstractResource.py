import boto3
import botocore
import json
import os
from deepdiff import DeepDiff


from aws.utils import get_client, _backoff, _backoff2, key_val_search

class AbstractResource:


    def __init__(self, resource_file, resource_dir):

        # --> Directories
        self.resource_dir = resource_dir
        self.store_dir = os.path.join(self.resource_dir, 'store')

        # --> Resource File
        self.resource_file = os.path.join(self.store_dir, resource_file)
        self.resource = json.load(open(self.resource_file))

        # --> Remote file
        self.remote_dir = os.path.join(self.resource_dir, 'remote')
        self.remote_file = os.path.join(self.remote_dir, str('remote_' + resource_file))




    @property
    def prefix(self):
        from globals import prefix
        return prefix

    def save_local(self):
        with open(self.resource_file, 'w') as outfile:
            outfile.write(json.dumps(self.resource, indent=4, sort_keys=True, default=str))

    def save_remote(self):
        remote = self.resource_exists()
        if remote is None:
            remote = {}
        with open(self.remote_file, 'w') as outfile:
            outfile.write(json.dumps(remote, indent=4, sort_keys=True, default=str))

    def resource_dne(self):
        remote = self.resource_exists()
        if remote is None:
            return {}
        return None


    ################
    ### Override ###
    ################


    def load_dependencies(self):
        self.save_local()



    def resource_exists(self):
        return None

    def create_resource(self):
        return None

    def delete_resource(self):
        return None



    ###################
    ### COMPARATORS ###
    ###################
    # - Return 'False' when no remote update is needed

    def service_comparator(self, serv_1, serv_2):
        if serv_1['desiredCount'] == serv_2['desiredCount']:
            return False
        return True

    def task_definition_comparator(self, def_1, def_2):
        if 'environment' not in def_1['containerDefinitions'][0]:
            return False
        if 'environment' not in def_2['containerDefinitions'][0]:
            return False
        env1 = def_1['containerDefinitions'][0]['environment']
        env2 = def_2['containerDefinitions'][0]['environment']
        diff = DeepDiff(env1, env2)

        # --> No difference, return false
        if diff == {}:
            return False
        return True

    def listener_comparator(self, lis_1, lis_2):
        comparisons = []
        comparisons.append(
            (lis_1['Certificates'][0]['CertificateArn'] == lis_2['Certificates'][0]['CertificateArn'])
        )
        comparisons.append(
            (lis_1['DefaultActions'][0]['TargetGroupArn'] == lis_2['DefaultActions'][0]['TargetGroupArn'])
        )
        comparisons.append(
            (lis_1['LoadBalancerArn'] == lis_2['LoadBalancerArn'])
        )
        if False in comparisons:
            return True
        return False

