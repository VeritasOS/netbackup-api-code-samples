import sys
import config
import json
import texttable as tt

# This script consists of the helper functions to excute NetBackup APIs for trust management crud operations.
# 1) Login to Netbackup
# 2) Create Trust between masters
# 3) Get Trusted master server
# 4) Delete Trust between master servers

protocol = "https"
nbmaster = ""
username = ""
password = ""
domainname = ""
domaintype = ""

port = 1556

def print_usage():
	print("Example:")
	print("python -W ignore configure_storage_unit_end_to_end.py -nbmaster <master_server> -username <username> -password <password> -trust_payload <input JSON for trusted masters> -trusted_master_server_name <Trusted Master Server Name> [-domainname <domain_name>] [-domaintype <domain_type>]\n\n\n")

def read_command_line_arguments():
	if len(sys.argv)%2 == 0:
		print_usage()
		exit()

	global nbmaster
	global username
	global password
	global domainname
	global domaintype
	global trust_payload
	global trusted_master_server_name

	for i in range(1, len(sys.argv), 2):
		if sys.argv[i] == "-nbmaster":
			nbmaster = sys.argv[i + 1]
		elif sys.argv[i] == "-username":
			username = sys.argv[i + 1]
		elif sys.argv[i] == "-password":
			password = sys.argv[i + 1]
		elif sys.argv[i] == "-trust_payload":
			trust_payload = sys.argv[i + 1]
		elif sys.argv[i] == "-trusted_master_server_name":
			trusted_master_server_name = sys.argv[i + 1]
		elif sys.argv[i] == "-domainname":
			domainname = sys.argv[i + 1]
		elif sys.argv[i] == "-domaintype":
			domaintype = sys.argv[i + 1]
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
	elif trust_payload == "":
		print("Please provide the value for 'trust_payload'")
		exit()
	elif trusted_master_server_name == "":
		print("Please provide the value for 'trusted_master_server_name'")
		exit()

print_usage()

read_command_line_arguments()

base_url = protocol + "://" + nbmaster + ":" + str(port) + "/netbackup"

jwt = config.perform_login(username, password, base_url, domainname, domaintype)

response_create_trust = config.create_trusted_master_server(jwt, base_url, trust_payload)
print(response_create_trust)

response_get_trust = config.get_trusted_master_server_by_name(jwt, base_url, trusted_master_server_name)
print(response_get_trust)

response_delete_trust = config.delete_trust(jwt, base_url, trusted_master_server_name)
print(response_delete_trust)
