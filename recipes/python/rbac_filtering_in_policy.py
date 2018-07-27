import sys
import policy_api_requests
import rbac_policy_api_requests
import json

protocol = "https"
port = 1556
new_rbac_user = "testuser"
new_rbac_domain = "rmnus"
new_rbac_pass = "testpass"
new_rbac_domainType = "vx"

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
	print("python -W ignore rbac_filtering_in_policy.py -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]\n\n\n")
	
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

# perform login using user defined user and use the token for subsequent operations
jwt = policy_api_requests.perform_login(username, password, domainName, domainType, base_url)

rbac_policy_api_requests.post_rbac_object_group_for_VMware_policy(jwt, base_url)
# -------------------------------------------------------------- #
#  Create a new rbac user locally using bpnbat to assign object
#  level permissions to the newly created user and perform
#  subsequent operations.
# -------------------------------------------------------------- #
rbac_policy_api_requests.create_bpnbat_user(new_rbac_user, new_rbac_domain, new_rbac_pass)
rbac_policy_api_requests.post_rbac_access_rules(jwt, base_url)
# create_access_rule

policy_api_requests.post_netbackup_VMwarePolicy_defaults(jwt, base_url)
policy_api_requests.post_netbackup_OraclePolicy_defaults(jwt, base_url)

# list policies should display both oracle and vmware policy for admin user
policy_api_requests.get_netbackup_policies(jwt, base_url)

new_rbac_jwt = policy_api_requests.perform_login(new_rbac_user, new_rbac_pass, new_rbac_domain, new_rbac_domainType, base_url)

# all policy operations will only be allowed for vmware policyType for the user "testuser" since
# we added vmware object level permissions to the user
policy_api_requests.get_netbackup_policies(new_rbac_jwt, base_url)

# delete pre-existing vmware policy and try to recreate with new rbac user
policy_api_requests.delete_VMware_netbackup_policy(jwt, base_url)
policy_api_requests.post_netbackup_VMwarePolicy_defaults(new_rbac_jwt, base_url)
# new "testuser" should not be able to create oracle 
policy_api_requests.post_netbackup_OraclePolicy_defaults(new_rbac_jwt, base_url)

policy_api_requests.delete_VMware_netbackup_policy(new_rbac_jwt, base_url)
policy_api_requests.delete_Oracle_netbackup_policy(jwt, base_url)

rbac_policy_api_requests.delete_rbac_access_rule(jwt, base_url)
rbac_policy_api_requests.delete_rbac_object_group_for_VMware_policy(jwt, base_url)

