import os
import json
import botocore

from aws.AbstractResource import AbstractResource

from utils import get_client, _backoff, _backoff2, key_val_search



class Database(AbstractResource):

    def __init__(self, resource_file='database.json'):
        
        super().__init__(resource_file, os.path.realpath(os.path.join(os.getcwd(), os.path.dirname(__file__))))

        # --> 1. Get Client
        self.client = get_client('rds')

        # --> 2. dependencies
        self.name = self.prefix + '-database'

        self.load_dependencies()
        self.save_remote()



    ################
    ### Override ###
    ################

    def load_dependencies(self):

        self.resource['database']['DBInstanceIdentifier'] = self.name

        self.save_local()

    def resource_exists(self):
        try:
            response = self.client.describe_db_instances(
                DBInstanceIdentifier=self.name
            )
            if 'DBInstances' not in response or len(response['DBInstances']) == 0:
                return None
            return response['DBInstances'][0]
        except botocore.exceptions.ClientError as error:
            return None

    def create_resource(self):
        # --> Search if already exists
        database = self.resource_exists()
        if database is not None:
            return database

        # --> Create database
        try:
            response = self.client.create_db_instance(**self.resource['database'])
        except botocore.exceptions.ClientError as error:
            print('--> ERROR CREATING DATABASE:', error)
            return None

        # --> Wait for creation
        response = _backoff(self.resource_exists)
        return response

    def get_endpoint(self):
        database = self.resource_exists()
        if database is None:
            raise Exception("--> Could not get endpoint, database does not exist", self.name)
        return database['Endpoint']['Address']

    def get_connection_url(self, prefix='postgres'):
        db_config = self.resource_exists()
        if db_config is None:
            raise Exception("--> Could not get sqlalchemy url, database does not exist", self.name)
        host = db_config['Endpoint']['Address']
        port = db_config['Endpoint']['Port']
        user = db_config['MasterUsername']
        database = db_config['DBName']
        password = self.resource['database']['MasterUserPassword']
        return (prefix + ("://{0}:{1}@{2}:{3}/{4}".format(
            user, password, host, port, database
        )))


