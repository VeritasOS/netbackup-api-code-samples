import sys
import login.login_api as login_api
import requests

def print_disclaimer():
    print("\n-------------------------------------------------------------------------------------------------")
    print("--                          This script requires Python3.5 or higher.                          --")
    print("--    The system where this script is run should have Python 3.5 or higher version installed.  --")
    print("-------------------------------------------------------------------------------------------------")
    print("The script requires 'requests' library to make the API calls.")
    print("You can install the library using the command: pip install requests")
    print("-------------------------------------------------------------------------------------------------")

def print_usage():
    print("\nCommand-line usage (should be run from the parent directory of the 'assets' directory):")
    print("\tpython -Wignore -m assets.get_vmware_assets -nbserver <server> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>] [-assetsFilter <filter>]")
    print("-------------------------------------------------------------------------------------------------")


print_disclaimer()
print_usage()

if len(sys.argv)%2 == 0:
    print("\nInvalid command!")
    print_usage()
    exit()

nbserver = ""
username = ""
password = ""
domainName = ""
domainType = ""
assetsFilter = ""

for i in range(1, len(sys.argv), 2):
    if sys.argv[i] == "-nbserver":
            nbserver = sys.argv[i + 1]
    elif sys.argv[i] == "-username":
            username = sys.argv[i + 1]
    elif sys.argv[i] == "-password":
            password = sys.argv[i + 1]
    elif sys.argv[i] == "-domainName":
            domainName = sys.argv[i + 1]
    elif sys.argv[i] == "-domainType":
            domainType = sys.argv[i + 1]
    elif sys.argv[i] == "-assetsFilter":
            assetsFilter = sys.argv[i + 1]
    else:
            print("\nInvalid command!")
            print_usage()
            exit()
                
if nbserver == "":
        print("Please provide the value for 'nbserver'\n")
        exit()
elif username == "":
        print("Please provide the value for 'username'\n")
        exit()
elif password == "":
        print("Please provide the value for 'password'\n")
        exit()
elif domainName == "":
        print("Please provide the value for 'domainName'\n")
        exit()
elif domainType == "":
        print("Please provide the value for 'domainType'\n")
        exit()

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
