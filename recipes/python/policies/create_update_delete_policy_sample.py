import sys
import policy_api_request_helper
import json

protocol = "https"
nbmaster = ""
username = ""
password = ""
domainName = ""
domainType = ""
port = 1556


def print_disclaimer():
    print("-------------------------------------------------------------------------------------------------")
    print("--                          This script requires Python3.5 or higher.                          --")
    print("--    If your current system does not have Python3.5 or higher installed, this will not work.  --")
    print("-------------------------------------------------------------------------------------------------\n")
    print("Executing this library requires some additional python3.5 libraries like \n\t'requests'.\n\n")
    print("You will, however, require 'requests' library to make the API calls.\n")
    print("You can install the dependent libraries using the following commands: ")
    print("pip install requests")
    print("-------------------------------------------------------------------------------------------------\n\n\n")
    print(
        "You can specify the 'nbmaster', 'username', 'password', 'domainName' and 'domainType' as command-line parameters\n")
    print_usage()


def print_usage():
    print("Example:")
    print(
        "python -W ignore create_policy_in_one_step.py -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]\n\n\n")


def read_command_line_arguments():
    if len(sys.argv) % 2 == 0:
        print_usage()
        exit()

    global nbmaster
    global username
    global password
    global domainName
    global domainType

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
        else:
            print_usage()
            exit()

    if nbmaster == "":
        print("Please provide the value for 'nbmaster'")
        exit()
    elif username == "":
        print("Please provide the value for 'username'")
        exit()
    elif password == "":
        print("Please provide the value for 'password'")
        exit()
    elif domainName == "":
        print("Please provide the value for 'domainName'")
        exit()
    elif domainType == "":
        print("Please provide the value for 'domainType'")
        exit()


print_disclaimer()

read_command_line_arguments()

base_url = protocol + "://" + nbmaster + ":" + str(port) + "/netbackup"

jwt = policy_api_request_helper.perform_login(username, password, domainName, domainType, base_url)

policy_id = "test_Standard_ID_001"
policy_name = "test_standard_sample_name"
policy_type = "Standard"
new_policy_name_for_copy = "test_standard_sample_name_copied"

policy_api_request_helper.create_netbackup_policy(jwt, base_url, policy_id, policy_name,policy_type)

policy_api_request_helper.get_netbackup_policy(jwt, base_url, policy_name)

policy_api_request_helper.get_netbackup_policies(jwt, base_url)

policy_api_request_helper.copy_netbackup_policy(jwt, base_url, policy_name, new_policy_name_for_copy)

policy_api_request_helper.get_netbackup_policy(jwt, base_url, new_policy_name_for_copy)

policy_api_request_helper.delete_netbackup_policy(jwt, base_url, policy_name)

policy_api_request_helper.delete_netbackup_policy(jwt, base_url, new_policy_name_for_copy)

policy_api_request_helper.get_netbackup_policies(jwt, base_url)

policy_id = "test_Standard_ID_002"
policy_name = "test_windows_sample_name"
policy_type = "Windows"
new_policy_name_for_copy = "test_windows_sample_name_copied"
client_name = "testClient001"
schedule_name = "testSechedule001"
test_backup_selection = "testBackupSelection"

policy_api_request_helper.create_netbackup_policy(jwt, base_url, policy_id, policy_name,policy_type)

policy_api_request_helper.get_netbackup_policy(jwt, base_url, policy_name)

policy_api_request_helper.get_netbackup_policies(jwt, base_url)

policy_api_request_helper.put_netbackup_client(jwt,policy_name,client_name,policy_type)

policy_api_request_helper.get_netbackup_unique_policy_clients(jwt,base_url)

policy_api_request_helper.copy_netbackup_policy(jwt, base_url, policy_name, new_policy_name_for_copy)

policy_api_request_helper.get_netbackup_policy(jwt, base_url, new_policy_name_for_copy)

policy_api_request_helper.get_netbackup_policies(jwt, base_url)

policy_api_request_helper.put_netbackup_backupselections(jwt,base_url,policy_name,test_backup_selection)

policy_api_request_helper.delete_netbackup_backupselections(jwt,base_url, test_backup_selection)

policy_api_request_helper.delete_netbackup_backupselections(jwt,base_url,policy_name)

policy_api_request_helper.delete_netbackup_client(jwt,policy_name,client_name)

policy_api_request_helper.delete_netbackup_client(jwt,new_policy_name_for_copy,client_name)

policy_api_request_helper.delete_netbackup_policy(jwt, base_url, policy_name)

policy_api_request_helper.delete_netbackup_policy(jwt, base_url, new_policy_name_for_copy)