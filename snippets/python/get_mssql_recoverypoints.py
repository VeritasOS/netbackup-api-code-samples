import sys
import api_requests
import argparse
import json
import texttable as tt

protocol = "https"
port = 1556

def print_rps_details(data):
	tab = tt.Texttable(max_width=0)
	headings = ['RecoveryPoint ID','Asset ID','Client','Instance','Database','Method','Type','BackupTime']
	tab.header(headings)

	for data_item in data:
		tuple_value = (data_item['id'],
		data_item['attributes']['assetId'],
		data_item['attributes']['clientName'], 
		data_item['attributes']['extendedAttributes']['sqlInstance'],
		data_item['attributes']['extendedAttributes']['databaseName'],
		data_item['attributes']['extendedAttributes']['backupMethod'],
		data_item['attributes']['extendedAttributes']['backupType'],
		data_item['attributes']['backupTime'])
		tab.add_row(tuple_value)

	print(tab.draw())

def print_usage():
	print("Example:")
	print("python -W ignore get_mssql_recoverypoints.py -nbmaster <master_server> -username <username> -password <password> [-domainname <domain_name>] [-domaintype <domain_type>]\n\n\n")

print_usage()

parser = argparse.ArgumentParser(usage = print_usage())
parser.add_argument('-nbmaster', required=True)
parser.add_argument('-username', required=True)
parser.add_argument('-password', required=True)
parser.add_argument('-domainname')
parser.add_argument('-domaintype')
args = parser.parse_args()

nbmaster = args.nbmaster
username = args.username
password = args.password
domainname = args.domainname
domaintype = args.domaintype

base_url = protocol + "://" + nbmaster + ":" + str(port) + "/netbackup"

jwt = api_requests.perform_login(username, password, base_url, domainname, domaintype)

recoverypoints = api_requests.get_netbackup_mssql_rps(jwt, base_url)

data = recoverypoints['data']

if len(data) > 0:
	print_rps_details(data)
