import sys
import login.login_api as login_api
import config.hosts_api as hosts_api
import admin.services_api as services_api

nbmaster = ""
username = ""
password = ""
domainName = ""
domainType = ""
hostName = ""

def print_disclaimer():
	print("\n-------------------------------------------------------------------------------------------------")
	print("--                          This script requires Python3.5 or higher.                          --")
	print("--    The system where this script is run should have Python 3.5 or higher version installed.  --")
	print("-------------------------------------------------------------------------------------------------")
	print("The script requires 'requests' library to make the API calls.")
	print("You can install the library using the command: pip install requests")
	print("-------------------------------------------------------------------------------------------------")
	
def print_usage():
	print("\nCommand-line usage (should be run from the parent directory of the 'admin' directory):")
	print("\tpython -Wignore -m admin.list_nb_services -hostName <hostName> -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]")
	print("Note: hostName is the name of the NetBackup host to get the list of services.\n")
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

def print_nbservices_details(services_data):
        print("NB SERVICE NAME".rjust(20), end = "\t")
        print("STATUS".rjust(10))
        print("----------------------------------------")
        for service in services_data:
                print(service['id'].rjust(20), end = "\t")
                print(service['attributes']['status'].rjust(10))
        print()
	
print_disclaimer()

print_usage()

read_command_line_arguments()

base_url = "https://" + nbmaster + "/netbackup"

jwt = login_api.perform_login(base_url, username, password, domainName, domainType)

host_uuid = hosts_api.get_host_uuid(base_url, jwt, nbmaster)

services = services_api.get_all_nb_services(base_url, jwt, host_uuid)

data = services['data']

if len(data) > 0:
	print_nbservices_details(data)
else:
        print("\nNo NB services exist on the specified host!")

##service = admin.services_api_requests.get_specific_nb_service(jwt, uuid, base_url)
##
##data = service['data']
##
##if len(data) > 0:
##	print_nbservice_details(data)
