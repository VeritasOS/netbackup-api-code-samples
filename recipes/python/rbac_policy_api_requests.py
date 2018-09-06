import requests
import json
import os

content_type = "application/vnd.netbackup+json; version=2.0"
testPolicyName = "VMware_test_policy"
testClientName = "MEDIA_SERVER"
testScheduleName = "VMware_test_schedule"

def post_rbac_object_group_for_VMware_policy(jwt, base_url):
	global object_group_id
	url = base_url + "/rbac/object-groups"
	req_body = {
					"data": {
						"type": "object-group",
						"attributes": {
							"name": "VMwarePolicy",
							"criteria": [
								{
									"objectCriterion": "policyType eq 40",
									"objectType": "NBPolicy"
								}
							]
						}
					}
				}
	headers = {'Content-Type': content_type, 'Authorization': jwt}
	
	print("\nMaking POST Request to create object group to access only VMware policies  \n")
	
	resp = requests.post(url, headers=headers, json=req_body, verify=False)
	
	if resp.status_code != 201:
		print('Create object group API failed with status code {} and {}\n'.format(resp.status_code, resp.json()))
	
	object_group_id = resp.json()['data']['id']
	print("\n The object group is created with status code : {}\n".format(resp.status_code))
	
def post_rbac_access_rules(jwt, base_url):
	global access_rule_id
	url = base_url + "/rbac/access-rules"
	req_body = {
					"data": {
						"type": "access-rule",
						"attributes": {
							"description": "adding VMwarePolicy object group"
						},
						"relationships": {
							"userPrincipal": {
								"data": {
									"type": "user-principal",
									"id": "rmnus:testuser:vx:testuser"
								}
							},
							"objectGroup": {
								"data": {
									"type": "object-group",
									"id": object_group_id
								}
							},
							"role": {
								"data": {
									"type": "role",
									"id": "3"
								}
							}
						}
					}
				}
	headers = {'Content-Type': content_type, 'Authorization': jwt}
	
	print("\n Making POST Request to create access rule \n")
	
	resp = requests.post(url, headers=headers, json=req_body, verify=False)
	
	if resp.status_code != 201:
		print('Create object group API failed with status code {} and {}\n'.format(resp.status_code, resp.json()))
	
	access_rule_id = resp.json()['data']['id']
	
def delete_rbac_object_group_for_VMware_policy(jwt, base_url):
	url = base_url + "/rbac/object-groups/" + object_group_id
	headers = {'Content-Type': content_type, 'Authorization': jwt}
	
	print("\nMaking DELETE Request to remove the object group  \n")
	
	resp = requests.delete(url, headers=headers, verify=False)
	
	if resp.status_code != 204:
		print('DELETE object group API failed with status code {} and {}\n'.format(resp.status_code, resp.json()))
	
	print("\n The object group is deleted with status code: {}\n".format(resp.status_code))
	
def delete_rbac_access_rule(jwt, base_url):
	url = base_url + "/rbac/access-rules/" + access_rule_id
	headers = {'Content-Type': content_type, 'Authorization': jwt}
	
	print("\nMaking DELETE Request to remove the access rule  \n")
	
	resp = requests.delete(url, headers=headers, verify=False)
	
	if resp.status_code != 204:
		print('DELETE access rule API failed with status code {} and {}\n'.format(resp.status_code, resp.json()))
	
	print("\n The access rule is deleted with status code: {}\n".format(resp.status_code))
	
def create_bpnbat_user(username, domainName, password):
	print("\n Creating user for RBAC filtering using bpnbat  \n")
	if os.name == 'nt':
		path = 'C:/\"Program Files\"/Veritas/NetBackup/bin/bpnbat.exe';
		cmd = path + " -AddUser " + username + " " + password  + " " + domainName
		os.system(cmd)
	else:
		path = '/usr/openv/netbackup/bin/bpnbat';
		cmd = path + " -AddUser " + username + " " + password  + " " + domainName
		os.system(cmd)
	
	print("\n\n")
	