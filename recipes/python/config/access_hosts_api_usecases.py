import sys
import login.login_api as login_api
import config.access_hosts_api as access_hosts_api

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
    print("\tpython -W ignore -m config.access_hosts_api_usecases -hostName <hostName> -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]")
    print("Note: hostName is the name of the VMware Access host to add/delete using the Access Host APIs.\n")
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
    global workload

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
    elif hostName == "":
        print("Using default hostName to 'test_vmwareAccessHost123'\n")
        hostName = "test_vmwareAccessHost123"

def parse_access_host_response(response):
    global nbmaster
    resp_size = len(response.json()["data"])
    if resp_size==0:
        print("No Matching Entries Found on {}".format(nbmaster))
    else:
        print("{} Matching Entries Found on {} : ".format(resp_size, nbmaster))
        i = 0;
        for host in response.json()["data"]:
            i = i+1
            print ("\t{}. hostName = {}, hostType = {}".format(i, host["id"], host["attributes"]["hostType"]))

def use_case_1(base_url, jwt):
    global nbmaster
    print("\n-------------------Use Case 1 Start -------------------")
    print(" *** Description : Get All VMware Access Hosts on {} ***".format(nbmaster))
    print("-------------------------------------------------------")
    print("\nCalling GET Access-Hosts API ... ")
    response = access_hosts_api.get_access_hosts(base_url, jwt, "")
    print("\nParsing GET API response ... ")
    parse_access_host_response(response)
    print("-------------------Use Case 1 End ---------------------")

def use_case_2(base_url, jwt):
    global nbmaster
    global hostName
    print("\n\n-------------------Use Case 2 Start -------------------")
    print(" *** Description : Add VMware Dummy Access Host='{}' on {} ***".format(hostName, nbmaster))
    print("-------------------------------------------------------")
    print("\nCalling POST Access-Hosts API ... ")
    response = access_hosts_api.add_access_host(base_url, jwt, hostName)
    if response.status_code != 204:
        print("\nAdd Access Host failed with status code {} and {}".format(response.status_code, response.json()))
        raise SystemExit("\n\n")
    else:
        print("Add VMware Access Host successful.")

    print("\nCalling GET Access-Hosts API ... ")
    response = access_hosts_api.get_access_hosts(base_url, jwt, "")
    print("Parsing GET API response ... ")
    parse_access_host_response(response)
    print("-------------------Use Case 2 End ---------------------")

def use_case_3(base_url, jwt):
    global nbmaster
    print("\n\n-------------------Use Case 3 Start -------------------")
    print(" *** Description : Get All VMware Access Hosts of type 'CLIENT' on {} ***".format(nbmaster))
    print("-------------------------------------------------------")
    print("\nCalling GET Access-Hosts API with filter: hostType eq 'CLIENT'... ")
    response = access_hosts_api.get_access_hosts(base_url, jwt, "?filter=hostType eq 'CLIENT'")
    print("Parsing GET API response ... ")
    parse_access_host_response(response)
    print("-------------------Use Case 3 End ---------------------")


def use_case_4(base_url, jwt):
    global nbmaster
    global hostName
    print("\n\n-------------------Use Case 4 Start -------------------")
    print(" *** Description : Delete VMware Dummy Access Host = '{}' on {} ***".format(hostName, nbmaster))
    print("-------------------------------------------------------")
    print("\nCalling DELETE Access-Hosts API ... ")
    response = access_hosts_api.delete_access_host(base_url, jwt, hostName)

    if response.status_code != 204:
        print("\nDelete Access Host failed with status code {} and {}".format(response.status_code, response.json()))
        raise SystemExit("\n\n")
    else:
        print("Delete VMware Access Host successful.")

    print("\nCalling GET Access-Hosts API ... ")
    response = access_hosts_api.get_access_hosts(base_url, jwt, "")
    print("Parsing GET API response ... ")
    parse_access_host_response(response)
    print("-------------------Use Case 4 End ---------------------")

print_disclaimer()
print_usage()
read_command_line_arguments()

base_url = "https://" + nbmaster + "/netbackup"

print("\nExecuting the script...")

jwt = login_api.perform_login(base_url, username, password, domainName, domainType)

use_case_1(base_url, jwt)
use_case_2(base_url, jwt)
use_case_3(base_url, jwt)
use_case_4(base_url, jwt)

print("\nScript completed successfully!\n")