import requests

content_type = "application/vnd.netbackup+json;version=3.0"

def perform_login(base_url, username, password, domainName, domainType):
	url = base_url + "/login"
	req_body = {'userName': username, 'password': password, 'domainName': domainName, 'domainType': domainType}
	headers = {'Content-Type': content_type}

	print("\nLogin user '{}'.".format(req_body['userName']))
	
	resp = requests.post(url, headers=headers, json=req_body, verify=False)
	
	if resp.status_code != 201:
		print("\nLogin API failed with status code {} and {}".format(resp.status_code, resp.json()))
		raise SystemExit("\nLogin failed. Please verify that the input parameters are correct and try again.\n")
	 
	print("Login API returned response status code: {}".format(resp.status_code))

	print("Login successful. Returning the JWT.")
	
	return resp.json()['token']
