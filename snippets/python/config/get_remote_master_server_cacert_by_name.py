import sys
import config
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
	print("python -W ignore get_remote_master_server_cacert_by_name.py -nbmaster <master_server> -username <username> -password <password> -remotemasterserver <Remote Master Server Name> [-domainname <domain_name>] [-domaintype <domain_type>]\n\n\n")

def read_command_line_arguments():
	if len(sys.argv)%2 == 0:
		print_usage()
		exit()

	global nbmaster
	global username
	global password
	global domainname
	global domaintype
	global remotemasterserver

for i in range(1, len(sys.argv), 2):
    if sys.argv[i] == "-nbmaster":
        nbmaster = sys.argv[i + 1]
    elif sys.argv[i] == "-username":
        username = sys.argv[i + 1]
    elif sys.argv[i] == "-password":
        password = sys.argv[i + 1]
    elif sys.argv[i] == "-remotemasterserver":
        remotemasterserver = sys.argv[i + 1]
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
elif remotemasterserver == "":
    print("Please provide the value for 'remotemasterserver'")
    exit()

print_usage()

read_command_line_arguments()

base_url = protocol + "://" + nbmaster + ":" + str(port) + "/netbackup"

jwt = config.perform_login(username, password, base_url, domainname, domaintype)

jobs = config.get_remote_master_server_cacert_by_name(jwt, base_url, remotemasterserver)

print(jobs)
