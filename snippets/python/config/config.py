import requests

content_type = "application/vnd.netbackup+json; version=4.0"


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

def get_media_servers(jwt, base_url):
    url = base_url + "/config/media-servers"
    headers = {'Content-Type': content_type, 'Authorization': jwt}
    query_params = {
        #	"page[limit]": 100, 				#This changes the default page size to 100
        #	"filter": "jobType eq 'RESTORE'"	#This adds a filter to only show RESTORE Jobs
    }

    print("performing GET  on {}\n".format(url))

    resp = requests.get(url, headers=headers, params=query_params, verify=False)

    if resp.status_code != 200:
        raise Exception('GET Media server API failed with status code {} and {}'.format(resp.status_code, resp.json()))

    return resp.json()

def get_media_server_by_name(jwt, base_url, medianame):
    url = base_url + "/config/media-servers/" + medianame
    headers = {'Content-Type': content_type, 'Authorization': jwt}
    query_params = {
        #	"page[limit]": 100, 				#This changes the default page size to 100
        #	"filter": "jobType eq 'RESTORE'"	#This adds a filter to only show RESTORE Jobs
    }

    print("performing GET  on {}\n".format(url))

    resp = requests.get(url, headers=headers, params=query_params, verify=False)

    if resp.status_code != 200:
        raise Exception('GET Media server with specific name failed with status code {} and {}'.format(resp.status_code, resp.json()))

    return resp.json()
	
def get_remote_master_server_cacert_by_name(jwt, base_url, remotemasterserver):
    url = base_url + "/config/remote-master-server-cacerts/" + remotemasterserver
    headers = {'Content-Type': content_type, 'Authorization': jwt}
    query_params = {
        #	"page[limit]": 100, 				#This changes the default page size to 100
        #	"filter": "jobType eq 'RESTORE'"	#This adds a filter to only show RESTORE Jobs
    }

    print("performing GET  on {}\n".format(url))

    resp = requests.get(url, headers=headers, params=query_params, verify=False)

    if resp.status_code != 200:
        raise Exception('GET Remote master server cacert info with specific name failed with status code {} and {}'.format(resp.status_code, resp.json()))

    return resp.json()

def get_trusted_master_server_list(jwt, base_url):
    url = base_url + "/config/servers/trusted-master-servers"
    headers = {'Content-Type': content_type, 'Authorization': jwt}
    query_params = {
        #	"page[limit]": 100, 				#This changes the default page size to 100
        #	"filter": "jobType eq 'RESTORE'"	#This adds a filter to only show RESTORE Jobs
    }

    print("performing GET  on {}\n".format(url))

    resp = requests.get(url, headers=headers, params=query_params, verify=False)

    if resp.status_code != 200:
        raise Exception('GET trusted master server list API failed with status code {} and {}'.format(resp.status_code, resp.json()))

    return resp.json()

def get_trusted_master_server_by_name(jwt, base_url, trustedmasterservername):
    url = base_url + "/config/servers/trusted-master-servers/" + trustedmasterservername
    headers = {'Content-Type': content_type, 'Authorization': jwt}
    query_params = {
        #	"page[limit]": 100, 				#This changes the default page size to 100
        #	"filter": "jobType eq 'RESTORE'"	#This adds a filter to only show RESTORE Jobs
    }

    print("performing GET  on {}\n".format(url))

    resp = requests.get(url, headers=headers, params=query_params, verify=False)

    if resp.status_code != 200:
        raise Exception('GET trusted master server with specific name failed with status code {} and {}'.format(resp.status_code, resp.json()))

    return resp.json()

def delete_trust(jwt, base_url, trustedmasterservername):
    url = base_url + "/config/servers/trusted-master-servers/" +trustedmasterservername
    headers = {'Content-Type': content_type, 'Authorization': jwt}
    query_params = {
        #	"page[limit]": 100, 				#This changes the default page size to 100
        #	"filter": "jobType eq 'RESTORE'"	#This adds a filter to only show RESTORE Jobs
    }

    print("performing DELETE  on {}\n".format(url))

    resp = requests.delete(url, headers=headers, verify=False)
    if resp.status_code != 204:
        raise Exception('DELETE trust with specific trusted master failed with status code {} and {}'.format(resp.status_code, resp.json()))

    print("\nThe Trust is deleted with status code: {}\n".format(resp.status_code))

def create_trusted_master_server(jwt, base_url, file_name):
    url = base_url + "/config/servers/trusted-master-servers"
    headers = {'Content-Type': content_type, 'Authorization': jwt}

    path = file_name

    req_body = open(path, 'r').read()

    print("performing POST  on {}\n".format(url))

    resp = requests.post(url, headers=headers, data=req_body, verify=False)

    if resp.status_code != 201:
        raise Exception('Create trust between master servers API failed with status code {} and {}'.format(resp.status_code, resp.json()))

    return resp.json()
	
def patch_trusted_master_server(jwt, base_url, file_name, trustedmasterservername):
    url = base_url + "/config/servers/trusted-master-servers/" +trustedmasterservername
    headers = {'Content-Type': content_type, 'Authorization': jwt}

    path = file_name

    req_body = open(path, 'r').read()

    print("performing PATCH  on {}\n".format(url))

    resp = requests.patch(url, headers=headers, data=req_body, verify=False)

    if resp.status_code != 200:
        raise Exception('Update trust between masters API failed with status code {} and {}'.format(resp.status_code, resp.json()))
    print("\nThe Trust is Upadated with status code: {}\n".format(resp.status_code))
    return resp.json()
