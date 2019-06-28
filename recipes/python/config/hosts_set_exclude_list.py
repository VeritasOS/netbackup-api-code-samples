import sys
import login.login_api as login_api
import config.hosts_api as hosts_api
import config.exclude_list as exclude_list

nbmaster = ""
username = ""
password = ""
domainName = ""
domainType = ""
hostName = ""

EXCLUDE_CONFIG_NAME = "Exclude"

def print_disclaimer():
	print("\n-------------------------------------------------------------------------------------------------")
	print("--                          This script requires Python3.5 or higher.                          --")
	print("--    The system where this script is run should have Python 3.5 or higher version installed.  --")
	print("-------------------------------------------------------------------------------------------------")
	print("The script requires 'requests' library to make the API calls.")
	print("You can install the library using the command: pip install requests")
	print("-------------------------------------------------------------------------------------------------")
	
def print_usage():
	print("\nCommand-line usage (should be run from the parent directory of the 'config' directory):")
	print("\tpython -Wignore -m config.hosts_exclude_list -hostName <hostName> -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]")
	print("Note: hostName is the name of the NetBackup host to set the exclude configuration for. The exclude list is specified in the config/exclude_list file.\n")
	print("-------------------------------------------------------------------------------------------------")
	
def read_command_line_arguments():
        if len(sys.argv)%2 == 0:
                print("\nInvalid command!")
                print_usage()
                exit()
                
        global nbmaster
        global username
        global password
        global domainName
        global domainType
        global hostName

        for i in range(1, len(sys.argv), 2):
                if sys.argv[i] == "-nbmaster":
                        nbmaster = sys.argv[i + 1]
                elif sys.argv[i] == "-username":
                        username = sys.argv[i + 1]
                elif sys.argv[i] == "-password":
                        password = sys.argv[i + 1]
                elif sys.argv[i] == "-domainName":
                        domainName = sys.argv[i + 1]
                elif sys.argv[i] == "-domainType":
                        domainType = sys.argv[i + 1]
                elif sys.argv[i] == "-hostName":
                        hostName = sys.argv[i + 1]
                else:
                        print("\nInvalid command!")
                        print_usage()
                        exit()
                        
        if nbmaster == "":
                print("Please provide the value for 'nbmaster'\n")
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
        elif hostName == "":
                print("Please provide the value for 'hostName'\n")
                exit()
	
print_disclaimer()

print_usage()

read_command_line_arguments()

base_url = "https://" + nbmaster + "/netbackup"

print("\nExecuting the script...")

jwt = login_api.perform_login(base_url, username, password, domainName, domainType)

host_uuid = hosts_api.get_host_uuid(base_url, jwt, hostName)

get_exclude_config_response = hosts_api.get_host_configuration(base_url, jwt, host_uuid, EXCLUDE_CONFIG_NAME)

if get_exclude_config_response.status_code == 404:
    print("No 'Exclude' setting exists. Creating new 'Exclude' configuration.")
    response = hosts_api.create_host_configuration(base_url, jwt, host_uuid, EXCLUDE_CONFIG_NAME, exclude_list.EXCLUDE_LIST)

    if response.status_code != 204:
        print("\nCreate configuration failed with status code {} and {}".format(response.status_code, response.json()))
        raise SystemExit("\n\n")
    else:
        print("Create configuration successful.")

elif get_exclude_config_response.status_code == 200:
    print("Current 'Exclude' list is:")
    excludes = get_exclude_config_response.json()['data']['attributes']['value']
    for exclude in excludes:
        print("\t" + exclude)

    print("\nUpdating the 'Exclude' configuration setting.")
    response = hosts_api.update_host_configuration(base_url, jwt, host_uuid, EXCLUDE_CONFIG_NAME, exclude_list.EXCLUDE_LIST)

    if response.status_code != 204:
        print("\nUpdate configuration failed with status code {} and {}".format(response.status_code, response.json()))
        raise SystemExit("\n\n")
    else:
        print("Update configuration successful.")

print("\nGetting the new exclude list setting.")
get_exclude_config_response_new = hosts_api.get_host_configuration(base_url, jwt, host_uuid, EXCLUDE_CONFIG_NAME)

if get_exclude_config_response_new.status_code != 200:
    print("\nCould not get the new Exclude setting. Get configuration failed with status code {} and {}"
          .format(get_exclude_config_response_new.status_code, get_exclude_config_response_new.json()))
    raise SystemExit("\n\n")

print("The new 'Exclude' list set on the host {} is:".format(hostName))
excludes_new = get_exclude_config_response_new.json()['data']['attributes']['value']
for exclude in excludes_new:
    print("\t" + exclude)

print("\nScript completed successfully!\n")

