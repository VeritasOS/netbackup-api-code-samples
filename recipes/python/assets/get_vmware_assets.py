## The script can be run with Python 3.5 or higher version. 
## The script requires 'requests' library to make the API calls. The library can be installed using the command: pip install requests.

import argparse
import requests
import login.login_api as login_api

def get_usage():
    return ("\nThe command should be run from the parent directory of the 'assets' directory:\n"
            "python -Wignore -m assets.get_vmware_assets -nbserver <server> -username <username> -password <password> "
            "-domainName <domainName> -domainType <domainType> [-assetType <vm|vmGroup>] [-assetsFilter <filter criteria>]\n"
            "Optional arguments:\n"
            "assetType - vm or vmGroup. Default is 'vm'.\n"
            "assetsFilter - OData filter to filter the returned assets (VMs or VM Groups). If not specified, returns all the assets.\n")

parser = argparse.ArgumentParser(usage = get_usage())
parser.add_argument('-nbserver', required=True)
parser.add_argument('-username', required=True)
parser.add_argument('-password', required=True)
parser.add_argument('-domainName', required=True)
parser.add_argument('-domainType', required=True)
parser.add_argument('-assetType', default="vm", choices=['vm', 'vmGroup'])
parser.add_argument('-assetsFilter', default="")
args = parser.parse_args()

nbserver = args.nbserver
username = args.username
password = args.password
domainName = args.domainName
domainType = args.domainType
assetType = args.assetType
assetsFilter = args.assetsFilter

base_url = "https://" + nbserver + "/netbackup"
vm_assets_url = base_url + "/asset-service/workloads/vmware/assets"

default_sort = "commonAssetAttributes.displayName"

print("\nExecuting the script...")
jwt = login_api.perform_login(base_url, username, password, domainName, domainType)

print("\nGetting VMware {} assets...".format(assetType))

if assetType == "vm":
    assetTypeFilter = "(assetType eq 'vm')";
    print("Printing the following VM details: VM Display Name, Instance Id, vCenter, Protection Plan Names\n")
elif assetType == "vmGroup":
    assetTypeFilter = "(assetType eq 'vmGroup')";
    print("Printing the following VM group details: VM Group Name, VM Server, Filter Criteria, Protection Plan Names\n")

if assetsFilter != "":
    assetsFilter = assetsFilter + " and " + assetTypeFilter
else:
    assetsFilter = assetTypeFilter

headers = {'Authorization': jwt}

def get_vmware_assets():
    offset = 0
    next = True
    while next:
        queryparams = {'page[offset]':offset, 'filter':assetsFilter, 'sort':default_sort}
        assets_response = requests.get(vm_assets_url, headers=headers, params=queryparams, verify=False)
        assets = assets_response.json()

        if assets_response.status_code != 200:
            print("VMware Assets API returned status code: {}, response: {}\n".format(assets_response.status_code, assets_response.json()))
            raise SystemExit()

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

        if assetType == "vm":
            print(asset_common_attrs['displayName'], asset_attrs['instanceUuid'], asset_attrs['vCenter'], asset_protection_plans, sep="\t")
        elif assetType == "vmGroup":
            print(asset_common_attrs['displayName'], asset_attrs['filterConstraint'], asset_attrs['oDataQueryFilter'], asset_protection_plans, sep="\t")


get_vmware_assets()

print("\nScript completed!\n")
