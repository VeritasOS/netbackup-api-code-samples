import requests
import json

content_type = "application/vnd.netbackup+json; version=2.0"
testPolicyName = "VMware_test_policy"
testClientName = "MEDIA_SERVER"
testScheduleName = "VMware_test_schedule"

def perform_login(username, password, domainName, domainType, base_url):
	url = base_url + "/login"
	req_body = {"userName": username, "password": password, "domainName": domainName, "domainType": domainType}
	headers = {'Content-Type': content_type}
	
	print("Making POST Request to login for user '{}'\n".format(req_body['userName']))
	
	resp = requests.post(url, headers=headers, json=req_body, verify=False)
	
	if resp.status_code != 201:
		raise Exception('Login API failed with status code {} and {}'.format(resp.status_code, resp.json()))
	 
	print("\nThe response code of the Login API: {}\n".format(resp.status_code))
	print("\n Recieved jwt : \n{}\n".format(json.loads(resp.content)))
	
	return resp.json()['token']
	
def post_netbackup_VMwarePolicy_defaults(jwt, base_url):
	url = base_url + "/config/policies/"
	req_body = {
					"data": {
						"type": "policy",
						"id": testPolicyName,
						"attributes": {
							"policy": {
								"policyName": testPolicyName,
								"policyType": "VMware",
								"policyAttributes": {},
								"clients": [],
								"schedules": [],
								"backupSelections": {
									"selections": []
								}
							}
						}
					}
				}
	headers = {'Content-Type': content_type, 'Authorization': jwt}
	
	print("\nMaking POST Request to create VMware Policy with defaults \n")
	
	resp = requests.post(url, headers=headers, json=req_body, verify=False)
	
	if resp.status_code != 204:
		raise Exception('Create Policy API with defaults failed with status code {} and {}'.format(resp.status_code, resp.json()))
	
	print("\n {} with defaults is created with status code : {}\n".format(testPolicyName,resp.status_code))
	
def post_netbackup_VMwarePolicy(jwt, base_url):
	url = base_url + "/config/policies/"
	req_body = {
					"data": {
						"type": "policy",
						"id": testPolicyName,
						"attributes": {
							"policy": {
								"policyName": testPolicyName,
								"policyType": "VMware",
								"policyAttributes": {
									"active": True,
									"applicationConsistent": True,
									"applicationDiscovery": True,
									"applicationProtection": [],
									"autoManagedLabel": None,
									"autoManagedType": 0,
									"backupHost": "MEDIA_SERVER",
									"blockIncremental": True,
									"dataClassification": None,
									"disableClientSideDeduplication": False,
									"discoveryLifetime": 28800,
									"effectiveDateUTC": "2018-06-13T18:56:07Z",
									"jobLimit": 2147483647,
									"keyword": "testing",
									"mediaOwner": "*ANY*",
									"priority": 0,
									"secondarySnapshotMethodArgs": None,
									"snapshotMethodArgs": "skipnodisk=0,post_events=1,multi_org=0,Virtual_machine_backup=2,continue_discovery=0,exclude_swap=1,nameuse=0,tags_unset=0,ignore_irvm=1,rLim=10,snapact=3,enable_quiesce_failover=0,drive_selection=0,file_system_optimization=1,disable_quiesce=0,enable_vCloud=0,rTO=0,rHz=10,trantype=san:hotadd:nbd:nbdssl",
									"storage": None,
									"storageIsSLP": False,
									"useAccelerator": False,
									"useReplicationDirector": False,
									"volumePool": "NetBackup"
								},
								"clients": [
									{
										"hardware": "VMware",
										"hostName": "MEDIA_SERVER",
										"OS": "VMware"
									}
								],
								"schedules": [
									{
										"acceleratorForcedRescan": False,
										"backupCopies": {
											"copies": [
												{
													"failStrategy": None,
													"mediaOwner": None,
													"retentionPeriod": {
														"value": 2,
														"unit": "WEEKS"
													},
													"storage": None,
													"volumePool": None
												}
											],
											"priority": -1
										},
										"backupType": "Full Backup",
										"excludeDates": {
											"lastDayOfMonth": False,
											"recurringDaysOfMonth": [],
											"recurringDaysOfWeek": [],
											"specificDates": []
										},
										"frequencySeconds": 604800,
										"includeDates": {
											"lastDayOfMonth": False,
											"recurringDaysOfMonth": [],
											"recurringDaysOfWeek": [],
											"specificDates": []
										},
										"mediaMultiplexing": 1,
										"retriesAllowedAfterRunDay": False,
										"scheduleName": "test-1",
										"scheduleType": "Frequency",
										"snapshotOnly": False,
										"startWindow": [
											{
												"dayOfWeek": 1,
												"startSeconds": 0,
												"durationSeconds": 0
											},
											{
												"dayOfWeek": 2,
												"startSeconds": 0,
												"durationSeconds": 0
											},
											{
												"dayOfWeek": 3,
												"startSeconds": 0,
												"durationSeconds": 0
											},
											{
												"dayOfWeek": 4,
												"startSeconds": 0,
												"durationSeconds": 0
											},
											{
												"dayOfWeek": 5,
												"startSeconds": 0,
												"durationSeconds": 0
											},
											{
												"dayOfWeek": 6,
												"startSeconds": 0,
												"durationSeconds": 0
											},
											{
												"dayOfWeek": 7,
												"startSeconds": 0,
												"durationSeconds": 0
											}
										],
										"storageIsSLP": False,
										"syntheticBackup": False
									}
								],
								"backupSelections": {
									"selections": [
										"vmware:/?filter=Displayname Equal \"Example-Test\""
									]
								}
							}
						}
					}
				}
	headers = {'Content-Type': content_type, 'Authorization': jwt}
	
	print("\n Making POST Request to create VMware Policy with  out defaults")
	
	resp = requests.post(url, headers=headers, json=req_body, verify=False)
	
	if resp.status_code != 204:
		raise Exception('Create Policy API failed with status code {} and {}'.format(resp.status_code, resp.json()))
	
	print("\n {} with out defaults is created with status code : {}\n".format(testPolicyName,resp.status_code))
	
def get_netbackup_policies(jwt, base_url):
	url = base_url + "/config/policies"
	headers = {'Content-Type': content_type, 'Authorization': jwt}
	
	print("\nMaking GET Request to list policies ")
	
	resp = requests.get(url, headers=headers, verify=False)
	
	if resp.status_code != 200:
		raise Exception('List Policies API failed with status code {} and {}'.format(resp.status_code, resp.json()))
	
	print("\nList policy succeeded with status code: {}\n".format(resp.status_code))
	print("\n Json Response body for List policies  : \n{}\n".format(json.loads(resp.content)))
	
	
def get_netbackup_policy(jwt, base_url):
	url = base_url + "/config/policies/" + testPolicyName
	headers = {'Content-Type': content_type, 'Authorization': jwt}
	
	print("\nperforming GET  on {}\n".format(url))
	
	resp = requests.get(url, headers=headers, verify=False)
	
	if resp.status_code != 200:
		raise Exception('GET Policy API failed with status code {} and {}'.format(resp.status_code, resp.json()))
	
	print("\nGet policy details on {} succeeded with status code: {}\n".format(testPolicyName, resp.status_code))
	print("\n Json Response body for get policy : \n{}\n".format(json.loads(resp.content)))
	
	
def delete_netbackup_policy(jwt, base_url):
	url = base_url + "/config/policies/" + testPolicyName
	headers = {'Content-Type': content_type, 'Authorization': jwt}
	
	print("\n Making policy DELETE Request on {}".format(testPolicyName))
	
	resp = requests.delete(url, headers=headers, verify=False)
	
	if resp.status_code != 204:
		raise Exception('DELETE Policy API failed with status code {} and {}'.format(resp.status_code, resp.json()))
	
	print("\nThe policy is deleted with status code: {}\n".format(resp.status_code))
	
def put_netbackup_policy(jwt, base_url):
	url = base_url + "/config/policies/" + testPolicyName
	req_body = {
					"data": {
						"type": "policy",
						"id": testPolicyName,
						"attributes": {
							"policy": {
								"policyName": testPolicyName,
								"policyType": "VMware",
								"policyAttributes": {
									"keyword": "test"
								},
								"clients": [],
								"schedules": [],
								"backupSelections": {
									"selections": []
								}
							}
						}
					}
				}
	headers = {'Content-Type': content_type, 'Authorization': jwt}
	
	print("\n Making Update Request on {} by changing few attributes of the policy".format(testPolicyName))
	
	resp = requests.put(url, headers=headers, json=req_body, verify=False)
	
	if resp.status_code != 204:
		raise Exception('PUT Policy API failed with status code {} and {}'.format(resp.status_code, resp.json()))
	
	print("\n{} Updated with status code : {}\n".format(testPolicyName, resp.status_code))
	
def put_netbackup_client(jwt, base_url):
	url = base_url + "/config/policies/" + testPolicyName + "/clients/" + testClientName
	req_body = {
					"data": {
						"type":"client",
						"attributes": {
							"hardware": "VMware",
							"hostName": testClientName,
							"OS": "VMware"
						}
					}
				}
	headers = {'Content-Type': content_type, 'Authorization': jwt}
	
	print("\n Making PUT Request to add client to {}".format(testPolicyName))
	
	resp = requests.put(url, headers=headers, json=req_body, verify=False)
	
	if resp.status_code != 201:
		raise Exception('PUT Client API failed with status code {} and {}'.format(resp.status_code, resp.json()))
	
	print("\n{} is added to {} with status code : {}\n".format(testClientName, testPolicyName, resp.status_code))
	
def delete_netbackup_client(jwt, base_url):
	url = base_url + "/config/policies/" + testPolicyName + "/clients/" + testClientName
	headers = {'Content-Type': content_type, 'Authorization': jwt}
	
	print("\nMaking DELETE Request to remove clients from the policy\n")
	
	resp = requests.delete(url, headers=headers, verify=False)
	
	if resp.status_code != 204:
		raise Exception('DELETE Client API failed with status code {} and {}'.format(resp.status_code, resp.json()))
	
	print("\nClient {} is deleted from {} with status code: {}\n".format(testClientName, testPolicyName, resp.status_code))
	
def delete_netbackup_schedule(jwt, base_url):
	url = base_url + "/config/policies/" + testPolicyName + "/schedules/" + testScheduleName
	headers = {'Content-Type': content_type, 'Authorization': jwt}
	
	print("Making DELETE Request to remove schedule from the policy")
	
	resp = requests.delete(url, headers=headers, verify=False)
	
	if resp.status_code != 204:
		raise Exception('DELETE schedule API failed with status code {} and {}'.format(resp.status_code, resp.json()))
	
	print("\n {} is deleted from the {} with status code: {}\n".format(testScheduleName, testPolicyName, resp.status_code))
	
def delete_netbackup_backupselections(jwt, base_url):
	url = base_url + "/config/policies/" + testPolicyName + "/backupselections"
	headers = {'Content-Type': content_type, 'Authorization': jwt}
	
	print("Making DELETE Request to remove Backupselections from the policy\n")
	
	resp = requests.delete(url, headers=headers, verify=False)
	
	if resp.status_code != 204:
		raise Exception('DELETE Backupselections API failed with status code {} and {}'.format(resp.status_code, resp.json()))
	
	print("\n BackupSelections is deleted for the {}  with status code : {}\n".format(testPolicyName, resp.status_code))
	
def put_netbackup_backupselections(jwt, base_url):
	url = base_url + "/config/policies/" + testPolicyName + "/backupselections" 
	req_body = {
				"data": {
					"type": "backupSelection",
					"attributes": {
							"selections": [
								"vmware:/?filter=Displayname Equal \"Example-Test\""
							]
						}
					}
				}
	headers = {'Content-Type': content_type, 'Authorization': jwt}
	
	print("\nMaking PUT Request to add BackupSelections to {}\n".format(testPolicyName))
	
	resp = requests.put(url, headers=headers, json=req_body, verify=False)
	
	if resp.status_code != 204:
		raise Exception('PUT Backupselections API failed with status code {} and {}'.format(resp.status_code, resp.json()))
	
	print("\n Backupselections added to {} with status code: {}\n".format(testPolicyName, resp.status_code))
	
def put_netbackup_schedule(jwt, base_url):
	url = base_url + "/config/policies/" + testPolicyName + "/schedules/" + testScheduleName
	req_body = {
					"data": {
						"type": "schedule",
						"id": testScheduleName,
						"attributes": 
							{
								"acceleratorForcedRescan": False,
								"backupCopies": {
									"copies": [
										{
											"failStrategy": None,
											"mediaOwner": None,
											"retentionPeriod": {
												"value": 2,
												"unit": "WEEKS"
											},
											"storage": None,
											"volumePool": None
										}
									],
									"priority": -1
								},
								"backupType": "Full Backup",
								"excludeDates": {
									"lastDayOfMonth": False,
									"recurringDaysOfMonth": [],
									"recurringDaysOfWeek": [],
									"specificDates": []
								},
								"frequencySeconds": 604800,
								"includeDates": {
									"lastDayOfMonth": False,
									"recurringDaysOfMonth": [],
									"recurringDaysOfWeek": [],
									"specificDates": []
								},
								"mediaMultiplexing": 1,
								"retriesAllowedAfterRunDay": False,
								"scheduleName": "backup",
								"scheduleType": "Frequency",
								"snapshotOnly": False,
								"startWindow": [
									{
										"dayOfWeek": 1,
										"startSeconds": 0,
										"durationSeconds": 0
									},
									{
										"dayOfWeek": 2,
										"startSeconds": 0,
										"durationSeconds": 0
									},
									{
										"dayOfWeek": 3,
										"startSeconds": 0,
										"durationSeconds": 0
									},
									{
										"dayOfWeek": 4,
										"startSeconds": 0,
										"durationSeconds": 0
									},
									{
										"dayOfWeek": 5,
										"startSeconds": 0,
										"durationSeconds": 0
									},
									{
										"dayOfWeek": 6,
										"startSeconds": 0,
										"durationSeconds": 0
									},
									{
										"dayOfWeek": 7,
										"startSeconds": 0,
										"durationSeconds": 0
									}
								],
								"storageIsSLP": False,
								"syntheticBackup": False
							}
					}
				}
	headers = {'Content-Type': content_type, 'Authorization': jwt}
	
	print("\nMaking PUT Request to add schedule to {}\n".format(testPolicyName))
	
	resp = requests.put(url, headers=headers, json=req_body, verify=False)
	
	if resp.status_code != 201:
		raise Exception('PUT Schedule API failed with status code {} and {}'.format(resp.status_code, resp.json()))
	
	print("\n{} is added to {} with status code : {}\n".format(testScheduleName, testPolicyName, resp.status_code))
