import os
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
	print("python -W ignore get_replication_target_by_id_on_diskvolume.py -nbmaster <master_server> -username <username> -password <password> -stsid <storage server id> -dvid <diskvolume id> -reptargetid <replication target id> [-domainname <domain_name>] [-domaintype <domain_type>]\n\n\n")

def read_command_line_arguments():
	if len(sys.argv)%2 == 0:
		print_usage()
		exit()

	global nbmaster
	global username
	global password
	global domainname
	global domaintype
	global stsid
	global dvid
	global reptargetid


	for i in range(1, len(sys.argv), 2):
		if sys.argv[i] == "-nbmaster":
			nbmaster = sys.argv[i + 1]
		elif sys.argv[i] == "-username":
			username = sys.argv[i + 1]
		elif sys.argv[i] == "-password":
			password = sys.argv[i + 1]
		elif sys.argv[i] == "-stsid":
			stsid = sys.argv[i + 1]
		elif sys.argv[i] == "-dvid":
			dvid = sys.argv[i + 1]
		elif sys.argv[i] == "-reptargetid":
			reptargetid = sys.argv[i + 1]
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
	elif stsid == "":
		print("Please provide the value for 'stsid'")
		exit()
	elif dvid == "":
		print("Please provide the value for 'dvid'")
		exit()
	elif reptargetid == "":
		print("Please provide the value for 'reptargetid'")
		exit()

print_usage()

read_command_line_arguments()

base_url = protocol + "://" + nbmaster + ":" + str(port) + "/netbackup"

jwt = storage.perform_login(username, password, base_url, domainname, domaintype)

response = storage.get_replication_target_by_id_on_diskvolume(jwt, base_url, stsid, dvid, reptargetid)

print(response)
