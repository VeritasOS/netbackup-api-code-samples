import sys
import storage
import json
import texttable as tt

protocol = "https"
nbmaster = ""
username = ""
password = ""
domainname = ""
domaintype = ""

port = 1556

def print_usage():
	print("Example:")
	print("python -W ignore configure_storage_unit_end_to_end.py -nbmaster <master_server> -username <username> -password <password> -sts_payload <input JSON for storage server> -dp_payload <input JSON for disk pool> -stu_payload <input JSON for storage unit> [-domainname <domain_name>] [-domaintype <domain_type>]\n\n\n")

def read_command_line_arguments():
	if len(sys.argv)%2 == 0:
		print_usage()
		exit()

	global nbmaster
	global username
	global password
	global domainname
	global domaintype
	global sts_payload
	global dp_payload
	global stu_payload

	for i in range(1, len(sys.argv), 2):
		if sys.argv[i] == "-nbmaster":
			nbmaster = sys.argv[i + 1]
		elif sys.argv[i] == "-username":
			username = sys.argv[i + 1]
		elif sys.argv[i] == "-password":
			password = sys.argv[i + 1]
		elif sys.argv[i] == "-sts_payload":
			sts_payload = sys.argv[i + 1]
		elif sys.argv[i] == "-dp_payload":
			dp_payload = sys.argv[i + 1]
		elif sys.argv[i] == "-stu_payload":
			stu_payload = sys.argv[i + 1]
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
	elif sts_payload == "":
		print("Please provide the value for 'sts_payload'")
		exit()
	elif dp_payload == "":
		print("Please provide the value for 'dp_payload'")
		exit()
	elif stu_payload == "":
		print("Please provide the value for 'stu_payload'")
		exit()

print_usage()

read_command_line_arguments()

base_url = protocol + "://" + nbmaster + ":" + str(port) + "/netbackup"

jwt = storage.perform_login(username, password, base_url, domainname, domaintype)

response_sts = storage.create_storage_server(jwt, base_url, sts_payload)
print(response_sts)

response_dp = storage.create_disk_pool(jwt, base_url, dp_payload)
print(response_dp)

response_stu = storage.create_storage_unit(jwt, base_url, stu_payload)
print(response_stu)
