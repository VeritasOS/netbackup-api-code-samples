import requests

content_type = "application/vnd.netbackup+json; version=1.0"

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
