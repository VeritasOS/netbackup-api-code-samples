import sys
import policy_api_requests
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
	print("pip install requests ")
	print("-------------------------------------------------------------------------------------------------\n\n\n")
	print("You can specify the 'nbmaster', 'username', 'password', 'domainName' and 'domainType' as command-line parameters\n")
	print_usage()
	
def print_usage():
	print("Example:")
	print("python -W ignore create_policy_step_by_step.py -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]\n\n\n")
	
def read_command_line_arguments():
	if len(sys.argv)%2 == 0:
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

jwt = policy_api_requests.perform_login(username, password, domainName, domainType, base_url)

createPolicy = policy_api_requests.post_netbackup_VMwarePolicy_defaults(jwt, base_url)

listPolicies = policy_api_requests.get_netbackup_policies(jwt, base_url)

readPolicy = policy_api_requests.get_netbackup_policy(jwt, base_url)

updatePolicy = policy_api_requests.put_netbackup_policy(jwt, base_url)

addClient = policy_api_requests.put_netbackup_client(jwt, base_url)

addBackupSelection = policy_api_requests.put_netbackup_backupselections(jwt, base_url)

addSchedule = policy_api_requests.put_netbackup_schedule(jwt, base_url)

readPolicy = policy_api_requests.get_netbackup_policy(jwt, base_url)

deleteClient = policy_api_requests.delete_netbackup_client(jwt, base_url)

deleteSchedule = policy_api_requests.delete_netbackup_schedule(jwt, base_url)

deletePolicy = policy_api_requests.delete_netbackup_policy(jwt, base_url)

listPolicies = policy_api_requests.get_netbackup_policies(jwt, base_url)
