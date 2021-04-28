#!/bin/python3

# ---------------------------------------------
# -- This script requires Python 3.5 or higher.
# ---------------------------------------------
# Executing this library requires some additional libraries like 'requests'.
# You can install the dependent libraries using the following command:
# pip3 install requests

import argparse
import requests

protocol = 'https'
nbmaster = ''
username = ''
password = ''
domainName = ''
domainType = ''
enable = None
port = 1556

def read_command_line_arguments():
    global nbmaster
    global username
    global password
    global domainName
    global domainType
    global enable

    parser = argparse.ArgumentParser(
        description='Enable or disable the NetBackup UI compatibility service')
    parser.add_argument('-nbmaster', required=True)
    parser.add_argument('-username', required=True)
    parser.add_argument('-password', required=True)
    parser.add_argument('-domainName', required=True)
    parser.add_argument('-domainType', required=True)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-enable', action='store_true')
    group.add_argument('-disable', action='store_true')

    args = parser.parse_args()
    nbmaster = args.nbmaster
    username = args.username
    password = args.password
    domainName = args.domainName
    domainType = args.domainType
    enable = args.enable


def perform_login(username, password, domainName, domainType, base_url):
    url = base_url + '/login'
    req_body = {
        'userName': username,
        'password': password,
        'domainName': domainName,
        'domainType': domainType,
    }
    headers = {
        'Content-Type': 'application/json',
    }

    print('Making POST Request to login for user {}'.format(
        req_body['userName']))

    resp = requests.post(url, headers=headers, json=req_body, verify=False)

    if resp.status_code != 201:
        print('Login API failed with status code {}: {}'.format(
            resp.status_code, resp.json()))
    else:
        print('The response code of the login API: {}'.format(
            resp.status_code))

    return resp.json()['token']


def set_nbuics_status(enable, jwt, base_url):
    url = base_url + '/config/paf/register-paf-host/1'
    req_body = {
        'data': {
            'type': 'pafServiceRegistrationRequest',
            'id': 1,
            'attributes': {
                'hostname': 'localhost' if enable else '',
            },
        },
    }
    headers = {
        'Authorization': jwt,
        'Content-Type': 'application/vnd.netbackup+json;version=6.0',
    }

    resp = requests.put(url, headers=headers, json=req_body, verify=False)
    print('Response code: {}'.format(resp.status_code))
    resp.raise_for_status()
    if enable:
        # Expected response is X
        return resp.json()['data']['attributes']['message']
    else:
        # Expected response is 204, no body.
        return ''


if __name__ == '__main__':
    read_command_line_arguments()

    base_url = '{}://{}:{}/netbackup'.format(protocol, nbmaster, port)

    jwt = perform_login(username, password, domainName, domainType, base_url)

    response = set_nbuics_status(enable, jwt, base_url)
    print(response)
