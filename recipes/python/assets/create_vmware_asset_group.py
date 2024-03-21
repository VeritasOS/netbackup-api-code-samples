## The script can be run with Python 3.5 or higher version. 
## The script requires 'requests' library to make the API calls. The library can be installed using the command: pip install requests.

import argparse
import requests
import time
import login.login_api as login_api

def get_usage():
    return ("\nThe command should be run from the parent directory of the 'assets' directory:\n"
            "python -Wignore -m assets.create_vmware_asset_group -nbserver <server> -username <username> -password <password> -domainName "
            "<domainName> -domainType <domainType> -vmGroupName <name> -vmServer <for example, a vCenter> [-vmGroupFilter <filter criteria>]\n"
            "Optional argument: vmGroupFilter - Filter criteria (in OData format) to include VMs in the group. "
            "If not specified, all the VMs in the given VM server are included in the group.\n")

parser = argparse.ArgumentParser(usage = get_usage())
parser.add_argument('-nbserver', required=True)
parser.add_argument('-username', required=True)
parser.add_argument('-password', required=True)
parser.add_argument('-domainName', required=True)
parser.add_argument('-domainType', required=True)
parser.add_argument('-vmGroupName', required=True)
parser.add_argument('-vmServer', required=True)
parser.add_argument('-vmGroupFilter', default="")
args = parser.parse_args()

nbserver = args.nbserver
username = args.username
password = args.password
domainName = args.domainName
domainType = args.domainType
vmGroupName = args.vmGroupName
vmServer = args.vmServer
vmGroupFilter = args.vmGroupFilter

base_url = "https://" + nbserver + "/netbackup"
asset_service_url = base_url + "/asset-service/queries/"
content_type = content_type = "application/vnd.netbackup+json;version=4.0"

def create_vm_group():
    vm_group_create_response = requests.post(asset_service_url, headers=headers, json=vm_group_create_request, verify=False)

    if vm_group_create_response.status_code != 201:
        print("\nAPI returned status code {}. Response: {}".format(vm_group_create_response.status_code,
                                                                 vm_group_create_response.json()))
        raise SystemExit("\nScript ended.\n")

    print ("\nRequest to create VM group has been posted.")

    vm_group_create_query_id = vm_group_create_response.json()['data']['id']
    vm_group_create_status_response = None
    vm_group_create_status = "IN_PROGRESS"
    status_check_count = 0

    while vm_group_create_status == "IN_PROGRESS":
        time.sleep(2)
        print("\nChecking the status of the request...")
        vm_group_create_status_query = requests.get(asset_service_url + vm_group_create_query_id, headers=headers, verify=False)

        vm_group_create_status_response = vm_group_create_status_query.json()

        if vm_group_create_status_query.status_code != 200:
            print("\nAPI returned status code: {}. Response: {}".format(vm_group_create_status_response.status_code,
                                                                       vm_group_create_status_response))
            raise SystemExit("\nScript ended.\n")
        
        vm_group_create_status = vm_group_create_status_response['data'][0]['attributes']['status']

        print("\nStatus:", vm_group_create_status)

        status_check_count += 1
        if status_check_count >= 10:
            print("\nRequest to create the VM group is still being processed. Exiting status check.")
            break

    print("\nAPI Response for the VM group create request: ", vm_group_create_status_response)

    vm_group_id_uri = ""
    if vm_group_create_status == 'SUCCESS':
        print("\nVM group created.")
        vm_group_id_uri = vm_group_create_status_response['data'][0]['attributes']['workItemResponses'][0]['links']['self']['href']

    return vm_group_id_uri


def getAssetById(vm_group_id_uri):
    vm_group_get_response = requests.get(base_url + vm_group_id_uri, headers=headers, verify=False)

    if vm_group_get_response.status_code != 200:
        print("\nAPI returned status code: {}. Response: {}".format(vm_group_get_response.status_code,
                                                                   vm_group_get_response.json))
        raise SystemExit("\nCound not get the VM group by the given ID. Script ended.\n")

    print("\nGet VM group API response: ", vm_group_get_response.json())


print("\nExecuting the script...")

jwt = login_api.perform_login(base_url, username, password, domainName, domainType)

vm_group_create_request = {
        "data": {
            "type": "query",
            "attributes": {
                "queryName": "create-or-update-assets",
                "workloads": [ "vmware" ],
                "parameters": {
                    "objectList": [
                    {
                        "correlationId": "1",
                        "type": "vmwareGroupAsset",
                        "assetGroup": {
                            "description": "VM group created from sample script using API",
                            "assetType": "vmGroup",
                            "filterConstraint": "",
                            "oDataQueryFilter": "true",
                            "commonAssetAttributes": {
                                "displayName": "",
                                "workloadType": "vmware",
                                "detection": {
                                    "detectionMethod": "MANUAL"
                                }
                            }
                        }
                    }
                ]
            }
        }
    }
}

asset_group_req = vm_group_create_request['data']['attributes']['parameters']['objectList'][0]['assetGroup']
asset_group_req['commonAssetAttributes']['displayName'] = vmGroupName
asset_group_req['filterConstraint'] = vmServer
if vmGroupFilter:
    asset_group_req['oDataQueryFilter'] = vmGroupFilter


headers = {'Content-Type': content_type, 'Authorization': jwt}

print("\nCreating VM group...")

vm_group_id_uri = create_vm_group()

if vm_group_id_uri:
    print("\nGetting the VM group by id: ", vm_group_id_uri)
    getAssetById(vm_group_id_uri)

print("\nScript completed.\n")
