import os
import boto3
import botocore
import random
import time




def key_val_search(dict_list, key, value):
    for item in dict_list:
        if key not in item:
            continue
        if item[key] == value:
            return item
    return None



def get_client(service):
    client = boto3.client(
        service,
        region_name='us-east-2',
        aws_access_key_id=os.environ['AWS_ACCESS_KEY_ID'],
        aws_secret_access_key=os.environ['AWS_SECRET_ACCESS_KEY']
    )
    return client


def get_ec2_resource():
    session = boto3.Session(
        region_name='us-east-2',
        aws_access_key_id=os.environ['AWS_ACCESS_KEY_ID'],
        aws_secret_access_key=os.environ['AWS_SECRET_ACCESS_KEY']
    )
    return session.resource('ec2')

def get_region():
    return 'us-east-2'











""" Exponential Backoff
- Function passed as parameter is expected to return None when func should be tried again

"""

def _backoff2(func, param, attempts=10, backoff='LINEAR'):
    print('\n--> EXPONENTIAL BACKOFF:', func)
    result = func(param)
    idx = 0
    while result is None:
        print('-->', idx)
        if backoff == 'EXPONENTIAL':
            _exponential_sleep(idx)
        elif backoff == 'LINEAR':
            _linear_sleep(idx)
        result = func(param)
        idx += 1
        if idx > attempts:
            break
    return result


def _backoff(func, attempts=10, backoff='LINEAR'):
    print('--> EXPONENTIAL BACKOFF:', func)
    result = func()
    idx = 0
    while result is None:
        print('-->', idx)
        if backoff == 'EXPONENTIAL':
            _exponential_sleep(idx)
        elif backoff == 'LINEAR':
            _linear_sleep(idx)
        result = func()
        idx += 1
        if idx > attempts:
            break
    return result



def _exponential_sleep(x):
    backoff_seconds = 1
    sleep_time = (backoff_seconds * 2 ** x + random.uniform(0, 1))
    time.sleep(sleep_time)

def _linear_sleep(x):
    time.sleep(2)