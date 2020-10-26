import sys
import api_requests

protocol = "https"
nbmaster = ""
login_password = ""
login_domainname = ""
login_domaintype = ""
apikey_tag = ""
port = 1556

def print_disclaimer():
	print("-------------------------------------------------------------------------------------------------")
	print("--                          This script requires Python3.5 or higher.                          --")
	print("--    If your current system does not have Python3.5 or higher installed, this will not work.  --")
	print("-------------------------------------------------------------------------------------------------\n")
	print("Executing this library requires some additional python3.5 libraries like \n\t'requests' \n\n")
	print("You will, however, require 'requests' library to make the API calls.\n")
	print("-------------------------------------------------------------------------------------------------\n\n\n")

def print_usage():
	print_disclaimer()
	print("Example:")
	print("python -W ignore apikey_create.py -nbmaster <master_server> -login_username <login_username> -login_password <login_password> [-login_domainname <login_domainname> -login_domaintype <login_domaintype>] -apikey_tag <apikey_tag>\n")
	print("-nbmaster : Name of the NetBackup master server\n")
	print("-login_username : User name of the user performing action\n")
	print("-login_password : Password of the user performing action\n")
	print("-login_domainname : Domain name of the user performing action\n")
	print("-login_domaintype : Domain type of the user performing action\n")
	print("-apikey_tag : Tag associate with API key to be deleted\n\n\n")

def read_command_line_arguments():
	if len(sys.argv)%2 == 0:
		print_usage()
		exit()

	global nbmaster
	global login_username
	global login_password
	global login_domainname
	global login_domaintype
	global apikey_tag

	for i in range(1, len(sys.argv), 2):
		if sys.argv[i] == "-nbmaster":
			nbmaster = sys.argv[i + 1]
		elif sys.argv[i] == "-login_username":
			login_username = sys.argv[i + 1]
		elif sys.argv[i] == "-login_password":
			login_password = sys.argv[i + 1]
		elif sys.argv[i] == "-login_domainname":
			login_domainname = sys.argv[i + 1]
		elif sys.argv[i] == "-login_domaintype":
			login_domaintype = sys.argv[i + 1]
		elif sys.argv[i] == "-apikey_tag":
			apikey_tag = sys.argv[i + 1]
		else:
			print_usage()
			exit()

	if nbmaster == "":
		print("Please provide the value for 'nbmaster'")
		exit()
	elif login_username == "":
		print("Please provide the value for 'login_username'")
		exit()
	elif login_password == "":
		print("Please provide the value for 'login_password'")
		exit()
	elif apikey_tag == "":
		print("Please provide the value for 'apikey_tag'")
		exit()

read_command_line_arguments()

base_url = protocol + "://" + nbmaster + ":" + str(port) + "/netbackup"

jwt = api_requests.perform_login(login_username, login_password, base_url, login_domainname, login_domaintype)

api_requests.apikey_delete(jwt, base_url, apikey_tag)

print "Successfully deleted API Key with tag " + apikey_tag