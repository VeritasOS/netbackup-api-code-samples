# Cred? if doesn't already exist=
# register creds

## The script can be run with Python 3.11 or higher version.
## The script requires 'requests' library to make the API calls. The library can be installed using the command: pip install requests.

import argparse
import requests
import time
import os
import json

content_type = "application/vnd.netbackup+json;version=3.0"

parser = argparse.ArgumentParser(description="MSSQL Instance backup and Database restore scenario")
parser.add_argument('-nbserver', required=True, help="NetBackup primary server name")
parser.add_argument('-username', required=True, help="NetBackup primary server username")
parser.add_argument('-password', required=True, help="NetBackup primary server password")
parser.add_argument('-domainName', required=False, help="NetBackup primary server login domain name")
parser.add_argument('-domainType', required=False, help="NetBackup primary server login domain type")
parser.add_argument('-dbName', required=False, default="SampleDatabaseName", help="Oracle Database name to create an asset for")
parser.add_argument('-addRMANCatalog', required=False, action='store_true', help="If an RMAN catalog asset should be created")
parser.add_argument('-rmanCatalogName', required=False, default="RMANCatalog", help="RMAN catalog name")
parser.add_argument('-tnsName', required=False, default="rmancat", help="TNS name for RMAN catalog")
parser.add_argument('-addCredentials', required=False,  choices=['wallet', 'oracle', 'os', 'osAndOracle'], help="Type of credential to be created for the generated oracle assets")
parser.add_argument('-credentialName', required=False, help="Name of Oracle credentials to be assoiciated with the assets")

args = parser.parse_args()

nbserver = args.nbserver
username = args.username
password = args.password
domainName = args.domainName
domainType = args.domainType
dbName = args.dbName
addRMANCatalog = args.addRMANCatalog
tnsName = args.tnsName
rmanCatalogName = args.rmanCatalogName
addCredentials = args.addCredentials
credentialName = args.credentialName


base_url = "https://" + nbserver + "/netbackup"
asset_service_url = base_url + "/asset-service/queries/"
credentials_url = base_url + "/config/credentials/"
content_type = content_type = "application/vnd.netbackup+json;version=4.0"


def create_oracle_db(databaseName, rmanCatalogId, credentialName):
    manual_db_create_request = open_sample_payload("post_oracle_create_db.json")
    if rmanCatalogId is not '':
        manual_db_create_request['data']['attributes']['parameters']['objectList'][0]['relationship'] = {"rmanCatalog":{"data": [rmanCatalogId]}}

    if credentialName is not '':
        manual_db_create_request['data']['attributes']['parameters']['objectList'][0]['asset']['commonAssetAttributes']['credentials']= [{"credentialName": credentialName}]

    manual_db_create_request['data']['attributes']['parameters']['objectList'][0]['asset']['databaseName']

    oracle_create_db_response = requests.post(asset_service_url, headers=headers, json=manual_db_create_request, verify=False)

    if oracle_create_db_response.status_code is not 201:
        print("\nAPI returned status code {}. Response: {}".format(oracle_create_db_response.status_code,
                                                                 oracle_create_db_response.json()))
        raise SystemExit("\nScript ended.\n")

    print ("\nRequest to create Oracle DB has been posted.")

    oracle_db_id_uri = verify_asset_creation(oracle_create_db_response.json()['data']['id'])

    if oracle_db_id_uri is not '':
        print("\nOracle database created.")
        oracle_db_id = oracle_db_id_uri.split('/')[-1]
    else:
        print("\nFailed to create Oracle Database.")
        raise SystemExit("\nScript ended.\n")

    manual_instance_create_request = open_sample_payload("post_oracle_create_instance.json")
    manual_instance_create_request['data']['attributes']['parameters']['objectList'][0]['relationship']['database']['data'] = [oracle_db_id]
    oracle_create_instance_response = requests.post(asset_service_url, headers=headers, json=manual_instance_create_request, verify=False)

    if oracle_create_instance_response.status_code is not 201:
        print("\nAPI returned status code {}. Response: {}".format(oracle_create_instance_response.status_code,
                                                                 oracle_create_instance_response.json()))
        raise SystemExit("\nScript ended.\n")

    print ("\nRequest to create Oracle Instance has been posted.")

    oracle_instance_id_uri = verify_asset_creation(oracle_create_instance_response.json()['data']['id'])

    if oracle_instance_id_uri is not '':
        print("\nOracle instance created.")

    return oracle_db_id_uri

def discover_oracle_databases(host):
    discover_databases_request = open_sample_payload("post_oracle_discover.json")
    discover_databases_request['data']['attributes']['parameters']['objectList'][0]['clientName'] = host
    oracle_discover_response = requests.post(asset_service_url, headers=headers, json=discover_databases_request, verify=False)

    if oracle_discover_response.status_code is not 201:
        print("\nAPI returned status code {}. Response: {}".format(oracle_discover_response.status_code,
                                                                 oracle_discover_response.json()))
        raise SystemExit("\nScript ended.\n")

    print ("\nRequest to discover Oracle DBs on " + host +" has been posted.")

def add_rman_catalog(catalogName, tnsName, credentialName):
    rman_catalog_create_request = open_sample_payload("post_oracle_create_rman_catalog.json")
    rman_catalog_create_request['data']['attributes']['parameters']['objectList'][0]['asset']['tnsName'] = tnsName
    rman_catalog_create_request['data']['attributes']['parameters']['objectList'][0]['asset']['tnsName'] = rmanCatalogName
    if credentialName is not '':
        rman_catalog_create_request['data']['attributes']['parameters']['objectList'][0]['asset']['commonAssetAttributes']['credentials']= [{"credentialName": credentialName}]
    oracle_create_rman_catalog_response = requests.post(asset_service_url, headers=headers, json=rman_catalog_create_request, verify=False)

    if oracle_create_rman_catalog_response.status_code is not 201:
        print("\nAPI returned status code {}. Response: {}".format(oracle_create_rman_catalog_response.status_code,
                                                                 oracle_create_rman_catalog_response.json()))
        raise SystemExit("\nScript ended.\n")

    print ("\nRequest to create RMAN catalog has been posted.")

    oracle_rman_catalog_uri = verify_asset_creation(oracle_create_rman_catalog_response.json()['data']['id'])
    if oracle_rman_catalog_uri is not '':
        print("\nOracle RMAN Catalog created.")
        return oracle_rman_catalog_uri.split('/')[-1]
    else:
        print("RMAN catalog creation did not respond in time, continuing without mapping the databse to the catalog")
        return ''

def add_credentials(credentialOption, credentialName):
    print("Adding Credentials")
    creds_create_request = open_sample_payload("post_oracle_add_creds.json")
    creds_create_request['data']['attributes']['name']= credentialName
    if credentialOption == "wallet":
        creds_create_request['data']['attributes']['contents'] = {"useWallet": True}
    elif credentialOption == "oracle" or credentialOption ==  "osAndOracle":
        oraUser = input("Enter Oracle Username :")
        oraPass = input("Enter Oracle Password :")
        creds_create_request['data']['attributes']['contents'] = {"oracleUsername": oraUser, "oraclePassword": oraPass}
    if credentialOption == "os" or credentialOption == "osAndOracle":
        creds_create_request['data']['attributes']['contents']['osUser'] = input("Enter OS Username :")
        creds_create_request['data']['attributes']['contents']['osPassword'] = input("Enter OS Password :")
        creds_create_request['data']['attributes']['contents']['osDomain'] = input("Enter OS Domain :")

    oracle_create_creds_response = requests.post(credentials_url, headers=headers, json=creds_create_request, verify=False)

    if oracle_create_creds_response.status_code is not 201:
        print("\nAPI returned status code {}. Response: {}".format(oracle_create_creds_response.status_code,
                                                                 oracle_create_creds_response.json()))
        raise SystemExit("\nScript ended.\n")

    print ("\nCreated creds for Oracle")

def open_sample_payload(filename):
    cur_dir = os.path.dirname(os.path.abspath(__file__))
    file_name = os.path.join(cur_dir, 'sample-payloads', filename)
    with open(file_name, 'r') as file_handle:
        return json.load(file_handle)

def get_asset_by_id(uri):
    oracle_db_get_response = requests.get(base_url + uri, headers=headers, verify=False)

    if oracle_db_get_response.status_code is not 200:
        print("\nAPI returned status code: {}. Response: {}".format(oracle_db_get_response.status_code,
                                                                   oracle_db_get_response.json))
        raise SystemExit("\nCound not get the Oracle database by the given ID. Script ended.\n")

    print("\nGet Oracle database API response: ", oracle_db_get_response.json())

def verify_asset_creation(createQueryId):
    create_status_response = None
    create_status = "IN_PROGRESS"
    status_check_count = 0

    while create_status == "IN_PROGRESS":
        time.sleep(2)
        print("\nChecking the status of the request...")
        create_status_query = requests.get(asset_service_url + createQueryId, headers=headers, verify=False)

        create_status_response = create_status_query.json()

        if create_status_query.status_code is not 200:
            print("\nAPI returned status code: {}. Response: {}".format(create_status_response.status_code,
                                                                       create_status_response))
            raise SystemExit("\nScript ended.\n")

        create_status = create_status_response['data'][0]['attributes']['status']

        print("\nStatus:", create_status)

        status_check_count += 1
        if status_check_count >= 10:
            print("\nRequest to create the asset is still being processed. Exiting status check.")
            break

    print("\nAPI Response for the Asset create request: ", create_status_response)

    if create_status == 'SUCCESS':
        return  create_status_response['data'][0]['attributes']['workItemResponses'][0]['links']['self']['href']
    else:
        return ''

def perform_login(base_url, username, password, domainName, domainType):
	url = base_url + "/login"
	req_body = {'userName': username, 'password': password, 'domainName': domainName, 'domainType': domainType}
	headers = {'Content-Type': content_type}

	print("\nLogin user '{}'.".format(req_body['userName']))

	resp = requests.post(url, headers=headers, json=req_body, verify=False)

	if resp.status_code is not 201:
		print("\nLogin API failed with status code {} and {}".format(resp.status_code, resp.json()))
		raise SystemExit("\nLogin failed. Please verify that the input parameters are correct and try again.\n")

	print("Login API returned response status code: {}".format(resp.status_code))

	print("Login successful. Returning the JWT.")

	return resp.json()['token']

if __name__ == '__main__':
    jwt = perform_login(base_url, username, password, domainName, domainType)
    headers = {'Content-Type': content_type, 'Authorization': jwt}

    if addCredentials is not None:
        add_credentials(addCredentials, credentialName)

    rmanCatalogId = ''
    if addRMANCatalog:
        rmanCatalogId = add_rman_catalog(rmanCatalogName, tnsName, credentialName)

    print("\nCreating Oracle Database...")

    oracle_id_uri = create_oracle_db(dbName, rmanCatalogId, credentialName)

    if oracle_id_uri:
        print("\nGetting the Oracle DB by id: ", oracle_id_uri)
        get_asset_by_id(oracle_id_uri)

    print("\nRunning Oracle discovery on " + nbserver)
    discover_oracle_databases(nbserver)

    print("\nScript completed.\n")
