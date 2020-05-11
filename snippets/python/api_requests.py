import requests

content_type = "application/vnd.netbackup+json; version=1.0"
content_type_v3 = "application/vnd.netbackup+json; version=3.0"

def perform_login(username, password, base_url, domain_name, domain_type):
	url = base_url + "/login"

	if domain_name != "" and domain_type != "":
		req_body = {"userName": username, "password": password, "domainName": domain_name, "domainType": domain_type}
	else:
		req_body = {"userName": username, "password": password}

	headers = {'Content-Type': content_type}

	print("performing POST on {} for user '{}'\n".format(url, req_body['userName']))

	resp = requests.post(url, headers=headers, json=req_body, verify=False)

	if resp.status_code != 201:
		raise Exception('Login API failed with status code {} and {}'.format(resp.status_code, resp.json()))

	return resp.json()['token']


def get_netbackup_images(jwt, base_url):
	url = base_url + "/catalog/images"
	headers = {'Content-Type': content_type, 'Authorization': jwt}
	query_params = {
	#	"page[limit]": 100, 				#This changes the default page size to 100
	#	"filter": "policyType eq 'VMware'"  #This adds a filter to only show VMware backup Images
	}

	print("performing GET  on {}\n".format(url))

	resp = requests.get(url, headers=headers, params=query_params, verify=False)

	if resp.status_code != 200:
		raise Exception('Images API failed with status code {} and {}'.format(resp.status_code, resp.json()))

	return resp.json()


def get_netbackup_jobs(jwt, base_url):
	url = base_url + "/admin/jobs"
	headers = {'Content-Type': content_type, 'Authorization': jwt}
	query_params = {
	#	"page[limit]": 100, 				#This changes the default page size to 100
	#	"filter": "jobType eq 'RESTORE'"	#This adds a filter to only show RESTORE Jobs
	}

	print("performing GET  on {}\n".format(url))

	resp = requests.get(url, headers=headers, params=query_params, verify=False)

	if resp.status_code != 200:
		raise Exception('Jobs API failed with status code {} and {}'.format(resp.status_code, resp.json()))
	
	return resp.json()

def get_netbackup_alerts(jwt, base_url):
	url = base_url + "/manage/alerts"
	headers = {'Content-Type': content_type, 'Authorization': jwt}
	query_params = {
	#	"page[limit]": 100, 				#This changes the default page size to 100
	#  	"filter":"subCategory eq 'VMWARE'"  # This adds a filter to only show the alerts for job failures for VMWARE
	}
	
	print("performing GET  on {}\n".format(url))
	
	resp = requests.get(url, headers=headers, params=query_params, verify=False)
	
	if resp.status_code != 200:
		raise Exception('Alert API failed with status code {} and {}'.format(resp.status_code, resp.json()))
	
	return resp.json()

# Create NetBackup API key
# jwt - JWT fetched after triggering /login REST API
# base_usrl - NetBackup REST API base URL
# expiryindays - Number of days from today after which API key should expire
# description - A textual description to be associated with API key
# apikey_username - (optional) Username of the user whose API key needs to be generated. Empty string in case API keys is to be created for self.
# apikey_domainname - (optional) Domain name of the user whose API key needs to be generated. Empty string in case API keys is to be created for self or domain type is unixpwd.
# apikey_domaintype - (optional) Domain type  of the user whose API key needs to be generated. Empty string in case API keys is to be created for self.
def apikey_create(jwt, base_url, expiryindays, description, apikey_username, apikey_domainname, apikey_domaintype):
	url = base_url + "/security/api-keys"

	if apikey_username == "":
		print "Creating API key for self user"
	else:
		print "Creating API key for user [" + apikey_username + ":" + apikey_domainname + ":" + apikey_domaintype + "]"
	
	if apikey_username != "" and apikey_domaintype != "":
		req_body = { "data" : { "type":"apiKeyCreationRequest", "attributes": { "description":description,	"expireAfterDays":"P" + expiryindays + "D", "userName":apikey_username,	"userDomain":apikey_domainname, "userDomainType":apikey_domaintype} } }
	else:
		req_body = { "data" : { "type":"apiKeyCreationRequest", "attributes": { "description":description,	"expireAfterDays":"P" + expiryindays + "D"} } }

	headers = {'Content-Type' :content_type_v3, 'Authorization': jwt}

	print("performing POST on {}\n".format(url))

	resp = requests.post(url, headers=headers, json=req_body, verify=False)

	if resp.status_code != 201:
		raise Exception('Create API failed with status code {} and {}'.format(resp.status_code, resp.json()))

	return resp.json()

# Delete NetBackup API key
# jwt - JWT fetched after triggering /login REST API
# base_usrl - NetBackup REST API base URL
# apikey_tag - Tag associated with API key
def apikey_delete(jwt, base_url, apikey_tag):
	url = base_url + "/security/api-keys/" + apikey_tag

	headers = {'Content-Type' :content_type_v3, 'Authorization': jwt}

	print("performing DELETE on {}\n".format(url))

	resp = requests.delete(url, headers=headers, verify=False)

	if resp.status_code != 204:
		raise Exception('Delete API failed with status code {} and {}'.format(resp.status_code, resp.json()))

	return
