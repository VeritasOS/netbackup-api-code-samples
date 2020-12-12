## The script can be run with Python 3.5 or higher version. 
## The script requires 'requests' library to make the API calls. The library can be installed using the command: pip install requests.

import api_requests
import argparse
import requests

def get_usage():
    return ("\nThe command should be run from the parent directory of the 'assets' directory:\n"
            "python -Wignore -nbserver <server> -username <username> -password <password> "
            "-domainName <domainName> -domainType <domainType> [-assetType <instance|database|availabilityGroup>] [-assetsFilter <filter criteria>]\n"
            "Optional arguments:\n"
            "assetType - instance or database or availabilityGroup. Default is 'instance'.\n"
            "assetsFilter - OData filter to filter the returned assets (Instance, AvailabilityGroup or database). If not specified, returns all the assets.\n")

parser = argparse.ArgumentParser(usage = get_usage())
parser.add_argument('-nbserver', required=True)
parser.add_argument('-username', required=True)
parser.add_argument('-password', required=True)
parser.add_argument('-domainName', required=True)
parser.add_argument('-domainType', required=True)
parser.add_argument('-assetType', default="instance", choices=['instance', 'database', 'availabilityGroup'])
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
mssql_assets_url = base_url + "/asset-service/workloads/mssql/assets"

default_sort = "commonAssetAttributes.displayName"

print("\nExecuting the script...")
jwt = api_requests.perform_login(username, password, base_url, domainName, domainType)

print("\nGetting MSSQL {} assets...".format(assetType))

if assetType == "instance":
    assetTypeFilter = "(assetType eq 'instance')";
    print("Printing the following MSSQL Instance details: Instance Name, Id, State\n")
elif assetType == "database":
    assetTypeFilter = "(assetType eq 'database')";
    print("Printing the following MSSQL details: DatabaseName, Id, InstanceName, AG, assetProtectionDetails\n")
elif assetType == "availabilityGroup":
    assetTypeFilter = "(assetType eq 'availabilityGroup')";
    print("Printing the following MSSQL Availabilitygroup details: AvailabilityGroup Name, Server \n")

if assetsFilter != "":
    assetsFilter = assetsFilter + " and " + assetTypeFilter
else:
    assetsFilter = assetTypeFilter

headers = {'Authorization': jwt}

def get_mssql_assets():
    offset = 0
    next = True
    while next:
        queryparams = {'page[offset]':offset, 'filter':assetsFilter, 'sort':default_sort}
        assets_response = requests.get(mssql_assets_url, headers=headers, params=queryparams, verify=False)
        assets = assets_response.json()

        if assets_response.status_code != 200:
            print("Mssql Assets API returned status code: {}, response: {}\n".format(assets_response.status_code, assets_response.json()))
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
        ag_attrs = []
        asset_protection_plans = []
        if "activeProtection" in asset_common_attrs :
            asset_protection_list = asset_common_attrs['activeProtection']['protectionDetailsList']
            for asset_protection in asset_protection_list:
                if (asset_protection['isProtectionPlanCustomized']) == "YES":
                    asset_protection_plans.append(asset_protection['protectionPlanName'])
                else:
                    asset_protection_plans.append(asset_protection['policyName'])
        if "agGroupId" in asset_attrs :
            ag_attrs.append(asset_attrs['agName'])

        if assetType == "instance":
            print(asset_common_attrs['displayName'], asset['id'], asset_attrs['instanceState'], sep="\t")
        elif assetType == "database":
            print(asset_common_attrs['displayName'], asset['id'], asset_attrs['instanceName'], ag_attrs, asset_protection_plans, sep="\t")
        elif assetType == "availabilityGroup":
            print(asset_common_attrs['displayName'], asset['id'], asset_attrs['clusterName'], asset_protection_plans, sep="\t")


get_mssql_assets()

print("\nScript completed!\n")
