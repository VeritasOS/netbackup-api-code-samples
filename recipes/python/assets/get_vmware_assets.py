## The script can be run with Python 3.5 or higher version. 
## The script requires 'requests' library to make the API calls. The library can be installed using the command: pip install requests.

import sys
import argparse
import requests
import login.login_api as login_api

def print_usage():
    return ("\nThe command should be run from the parent directory of the 'assets' directory:\n"
            "\tpython -Wignore -m assets.get_vmware_assets -nbserver <server> -username <username> -password <password> "
            "-domainName <domainName> -domainType <domainType> [-assetsFilter <filter criteria>]\n")

parser = argparse.ArgumentParser(usage = print_usage())
parser.add_argument('-nbserver', required=True)
parser.add_argument('-username', required=True)
parser.add_argument('-password', required=True)
parser.add_argument('-domainName', required=True)
parser.add_argument('-domainType', required=True)
parser.add_argument('-assetsFilter', default="")
args = parser.parse_args()

nbserver = args.nbserver
username = args.username
password = args.password
domainName = args.domainName
domainType = args.domainType
assetsFilter = args.assetsFilter

base_url = "https://" + nbserver + "/netbackup"
vm_assets_url = base_url + "/asset-service/workloads/vmware/assets"
content_type = "application/vnd.netbackup+json; version=4.0"

default_sort = "commonAssetAttributes.displayName"

assetTypeFilter = "(assetType eq 'vm')";
if assetsFilter != "":
    assetsFilter = assetsFilter + " and " + assetTypeFilter
else:
    assetsFilter = assetTypeFilter

print("\nExecuting the script...")

jwt = login_api.perform_login(base_url, username, password, domainName, domainType)

headers = {'Content-Type': content_type, 'Authorization': jwt}

print("\nGetting VMware assets...")
print("Printing the following asset details: DisplayName, InstanceId, vCenter, ProtectedByPlanNames\n")

def get_vmware_assets():
    offset = 0
    next = True
    while next:
        queryparams = {'page[offset]':offset, 'filter':assetsFilter, 'sort':default_sort}
        assets_response = requests.get(vm_assets_url, headers=headers, params=queryparams, verify=False)
        assets = assets_response.json()

        if assets_response.status_code != 200:
            print("VMware Assets API failed with status code {} and {}\n".format(resp.status_code, resp.json()))
            raise SystemExit("\n\n")

        print_assets(assets['data'])

        offset += assets['meta']['pagination']['limit']
        next = assets['meta']['pagination']['hasNext']

        if len(assets['data']) == 0:
            print("No assets returned.")

def print_assets(assets_data):
    for asset in assets_data:
        asset_attrs = asset['attributes']
        asset_common_attrs = asset_attrs['commonAssetAttributes']
        asset_protection_plans = []
        if "activeProtection" in asset_common_attrs :
            asset_protection_list = asset_common_attrs['activeProtection']['protectionDetailsList']
            for asset_protection in asset_protection_list:
                asset_protection_plans.append(asset_protection['protectionPlanName'])

        print(asset_common_attrs['displayName'], asset_attrs['instanceUuid'], asset_attrs['vCenter'], asset_protection_plans, sep="\t")


get_vmware_assets()

print("\nScript completed successfully!\n")
