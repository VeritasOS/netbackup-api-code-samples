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
	print("python -W ignore create_storage_server.py -nbmaster <master_server> -username <username> -password <password> -payload <input JSON > -stsid <storage server id>[-domainname <domain_name>] [-domaintype <domain_type>]\n\n\n")

def read_command_line_arguments():
	if len(sys.argv)%2 == 0:
		print_usage()
		exit()

	global nbmaster
	global username
	global password
	global domainname
	global domaintype
	global payload
	global stsid

	for i in range(1, len(sys.argv), 2):
		if sys.argv[i] == "-nbmaster":
			nbmaster = sys.argv[i + 1]
		elif sys.argv[i] == "-username":
			username = sys.argv[i + 1]
		elif sys.argv[i] == "-password":
			password = sys.argv[i + 1]
		elif sys.argv[i] == "-payload":
			payload = sys.argv[i + 1]
		elif sys.argv[i] == "-stsid":
			stsid = sys.argv[i + 1]
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
	elif payload == "":
		print("Please provide the value for 'payload'")
	elif stsid == "":
		print("Please provide the value for 'stsid'")
		exit()

print_usage()

read_command_line_arguments()

base_url = protocol + "://" + nbmaster + ":" + str(port) + "/netbackup"

jwt = storage.perform_login(username, password, base_url, domainname, domaintype)

reponse = storage.patch_storage_server(jwt, base_url, payload, stsid)

print(reponse)
