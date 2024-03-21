import sys
import api_requests

protocol = "https"
nbmaster = ""
login_username = ""
login_password = ""
login_domainname = ""
login_domaintype = ""
apikey_username = ""
apikey_domainname = ""
apikey_domaintype = ""
expiryindays = ""
description = ""
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
	print("python -W ignore apikey_create.py -nbmaster <master_server> -login_username <login_username> -login_password <login_password> [-login_domainname <login_domainname> -login_domaintype <login_domaintype>] [-apikey_username <apikey_username> [-apikey_domainname <apikey_domainname>] -apikey_domaintype <apikey_domaintype>] -expiryindays <expiryindays> -description <description>\n\n\n")
	print("-nbmaster : Name of the NetBackup master server\n")
	print("-login_username : User name of the user performing action\n")
	print("-login_password : Password of the user performing action\n")
	print("-login_domainname : Domain name of the user performing action\n")
	print("-login_domaintype : Domain type of the user performing action\n")
	print("-apikey_username : (Optional) User name of the user for whom API key needs to be generated. Optional in case API key is to be generated for self\n")
	print("-apikey_domainname : Domain name of the user for whom API key needs to be generated. Optional in case API key is to be generated for self\n")
	print("-apikey_domaintype : Domain type of the user for whom API key needs to be generated. Optional in case API key is to be generated for self\n")
	print("-expiryindays : Number of days from today after which API key should expire\n")
	print("-description : A textual description to be associated with API key\n\n\n")

def read_command_line_arguments():
	if len(sys.argv)%2 == 0:
		print_usage()
		exit()

	global nbmaster
	global login_username
	global login_password
	global login_domainname
	global login_domaintype
	global apikey_username
	global apikey_domainname
	global apikey_domaintype
	global expiryindays
	global description

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
		elif sys.argv[i] == "-apikey_username":
			apikey_username = sys.argv[i + 1]
		elif sys.argv[i] == "-apikey_domainname":
			apikey_domainname = sys.argv[i + 1]
		elif sys.argv[i] == "-apikey_domaintype":
			apikey_domaintype = sys.argv[i + 1]
		elif sys.argv[i] == "-expiryindays":
			expiryindays = sys.argv[i + 1]
		elif sys.argv[i] == "-description":
			description = sys.argv[i + 1]
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
	elif expiryindays == "":
		print("Please provide the value for 'expiryindays'")
		exit()
	elif description == "":
		print("Please provide the value for 'description'")
		exit()

read_command_line_arguments()

base_url = protocol + "://" + nbmaster + ":" + str(port) + "/netbackup"

jwt = api_requests.perform_login(login_username, login_password, base_url, login_domainname, login_domaintype)

response = api_requests.apikey_create(jwt, base_url, expiryindays, description, apikey_username, apikey_domainname, apikey_domaintype)

apikey = response['data']['attributes']['apiKey']
apikey_tag = response['data']['id']
apikey_expiryDateTime = response['data']['attributes']['expiryDateTime']

print "Successfully created API Key"
print("API Key:" + apikey)
print("API Key Tag:" + apikey_tag)
print("API Key Expiration Date time:" + apikey_expiryDateTime)
