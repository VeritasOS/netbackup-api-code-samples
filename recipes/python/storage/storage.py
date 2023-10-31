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

def get_storage_units(jwt, base_url):
    url = base_url + "/storage/storage-units"
    headers = {'Content-Type': content_type, 'Authorization': jwt}
    query_params = {
        #	"page[limit]": 100, 				#This changes the default page size to 100
        #	"filter": "jobType eq 'RESTORE'"	#This adds a filter to only show RESTORE Jobs
    }

    print("performing GET  on {}\n".format(url))

    resp = requests.get(url, headers=headers, params=query_params, verify=False)

    if resp.status_code != 200:
        raise Exception('GET STU API failed with status code {} and {}'.format(resp.status_code, resp.json()))

    return resp.json()


def get_storage_servers(jwt, base_url):
    url = base_url + "/storage/storage-servers"
    headers = {'Content-Type': content_type, 'Authorization': jwt}
    query_params = {
        #	"page[limit]": 100, 				#This changes the default page size to 100
        #	"filter": "jobType eq 'RESTORE'"	#This adds a filter to only show RESTORE Jobs
    }

    print("performing GET  on {}\n".format(url))

    resp = requests.get(url, headers=headers, params=query_params, verify=False)

    if resp.status_code != 200:
        raise Exception('GET STS API failed with status code {} and {}'.format(resp.status_code, resp.json()))

    return resp.json()


def create_storage_server(jwt, base_url, file_name):
    url = base_url + "/storage/storage-servers"
    headers = {'Content-Type': content_type, 'Authorization': jwt}

    path = file_name

    req_body = open(path, 'r').read()

    print("performing POST  on {}\n".format(url))

    resp = requests.post(url, headers=headers, data=req_body, verify=False)

    if resp.status_code != 201:
        raise Exception('Create STS API failed with status code {} and {}'.format(resp.status_code, resp.json()))

    return resp.json()

def patch_storage_server(jwt, base_url, file_name, stsid):
    url = base_url + "/storage/storage-servers/" + stsid
    headers = {'Content-Type': content_type, 'Authorization': jwt}

    path = file_name

    req_body = open(path, 'r').read()

    print("performing PATCH  on {}\n".format(url))

    resp = requests.patch(url, headers=headers, data=req_body, verify=False)


    if resp.status_code != 200:
        raise Exception('Update STS API failed with status code {} and {}'.format(resp.status_code, resp.json()))
    print("\nThe STS is Upadated with status code: {}\n".format(resp.status_code))
    return resp.json()

def patch_storage_unit(jwt, base_url, file_name, stu_name):
    url = base_url + "/storage/storage-units/" +stu_name
    headers = {'Content-Type': content_type, 'Authorization': jwt}

    path = file_name

    req_body = open(path, 'r').read()

    print("performing PATCH  on {}\n".format(url))

    resp = requests.patch(url, headers=headers, data=req_body, verify=False)


    if resp.status_code != 200:
        raise Exception('Update STU API failed with status code {} and {}'.format(resp.status_code, resp.json()))
    print("\nThe STU is Upadated with status code: {}\n".format(resp.status_code))
    return resp.json()

def patch_disk_pool(jwt, base_url, file_name, dpid):
    url = base_url + "/storage/disk-pools/" +dpid
    headers = {'Content-Type': content_type, 'Authorization': jwt}

    path = file_name

    req_body = open(path, 'r').read()

    print("performing PATCH  on {}\n".format(url))

    resp = requests.patch(url, headers=headers, data=req_body, verify=False)

    if resp.status_code != 200:
        raise Exception('Update DP API failed with status code {} and {}'.format(resp.status_code, resp.json()))
    print("\nThe DP is Upadated with status code: {}\n".format(resp.status_code))
    return resp.json()


def create_disk_pool(jwt, base_url, file_name):
    url = base_url + "/storage/disk-pools"
    headers = {'Content-Type': content_type, 'Authorization': jwt}

    path = file_name

    req_body = open(path, 'r').read()

    print("performing POST  on {}\n".format(url))

    resp = requests.post(url, headers=headers, data=req_body, verify=False)

    if resp.status_code != 201:
        raise Exception('Create DP API failed with status code {} and {}'.format(resp.status_code, resp.json()))

    return resp.json()


def create_storage_unit(jwt, base_url, file_name):
    url = base_url + "/storage/storage-units"
    headers = {'Content-Type': content_type, 'Authorization': jwt}

    path = file_name

    req_body = open(path, 'r').read()

    print("performing POST  on {}\n".format(url), req_body)

    resp = requests.post(url, headers=headers, data=req_body, verify=False)

    if resp.status_code != 201:
        raise Exception('Create STU API failed with status code {} and {}'.format(resp.status_code, resp.json()))

    return resp.json()


def get_disk_pools(jwt, base_url):
    url = base_url + "/storage/disk-pools"
    headers = {'Content-Type': content_type, 'Authorization': jwt}
    query_params = {
        #	"page[limit]": 100, 				#This changes the default page size to 100
        #	"filter": "jobType eq 'RESTORE'"	#This adds a filter to only show RESTORE Jobs
    }

    print("performing GET  on {}\n".format(url))

    resp = requests.get(url, headers=headers, params=query_params, verify=False)

    if resp.status_code != 200:
        raise Exception('GET DP API failed with status code {} and {}'.format(resp.status_code, resp.json()))

    return resp.json()

def get_disk_pools_by_id(jwt, base_url, dpid):
    url = base_url + "/storage/disk-pools/" +dpid
    headers = {'Content-Type': content_type, 'Authorization': jwt}
    query_params = {
        #	"page[limit]": 100, 				#This changes the default page size to 100
        #	"filter": "jobType eq 'RESTORE'"	#This adds a filter to only show RESTORE Jobs
    }

    print("performing GET  on {}\n".format(url))

    resp = requests.get(url, headers=headers, params=query_params, verify=False)

    if resp.status_code != 200:
        raise Exception('GET DP with specific ID failed with status code {} and {}'.format(resp.status_code, resp.json()))

    return resp.json()

def get_storage_server_by_id(jwt, base_url, stsid):
    url = base_url + "/storage/storage-servers/" +stsid
    headers = {'Content-Type': content_type, 'Authorization': jwt}
    query_params = {
        #	"page[limit]": 100, 				#This changes the default page size to 100
        #	"filter": "jobType eq 'RESTORE'"	#This adds a filter to only show RESTORE Jobs
    }

    print("performing GET  on {}\n".format(url))

    resp = requests.get(url, headers=headers, params=query_params, verify=False)

    if resp.status_code != 200:
        raise Exception('GET STS with specific ID failed with status code {} and {}'.format(resp.status_code, resp.json()))

    return resp.json()

def get_storage_unit_by_id(jwt, base_url, stu_name):
    url = base_url + "/storage/storage-units/" +stu_name
    headers = {'Content-Type': content_type, 'Authorization': jwt}
    query_params = {
        #	"page[limit]": 100, 				#This changes the default page size to 100
        #	"filter": "jobType eq 'RESTORE'"	#This adds a filter to only show RESTORE Jobs
    }

    print("performing GET  on {}\n".format(url))

    resp = requests.get(url, headers=headers, params=query_params, verify=False)

    if resp.status_code != 200:
        raise Exception('GET STU with specific ID failed with status code {} and {}'.format(resp.status_code, resp.json()))

    return resp.json()


def delete_storage_server(jwt, base_url, stsid):
    url = base_url + "/storage/storage-servers/" +stsid
    headers = {'Content-Type': content_type, 'Authorization': jwt}
    query_params = {
        #	"page[limit]": 100, 				#This changes the default page size to 100
        #	"filter": "jobType eq 'RESTORE'"	#This adds a filter to only show RESTORE Jobs
    }

    print("performing DELETE  on {}\n".format(url))

    resp = requests.delete(url, headers=headers, verify=False)

    if resp.status_code != 204:
        raise Exception('DELETE STS with specific ID failed with status code {} and {}'.format(resp.status_code, resp.json()))

    print("\nThe STS is deleted with status code: {}\n".format(resp.status_code))

def delete_storage_unit(jwt, base_url, stu_name):
    url = base_url + "/storage/storage-units/" +stu_name
    headers = {'Content-Type': content_type, 'Authorization': jwt}
    query_params = {
        #	"page[limit]": 100, 				#This changes the default page size to 100
        #	"filter": "jobType eq 'RESTORE'"	#This adds a filter to only show RESTORE Jobs
    }

    print("performing DELETE  on {}\n".format(url))

    resp = requests.delete(url, headers=headers, verify=False)

    if resp.status_code != 204:
        raise Exception('DELETE STU with specific ID failed with status code {} and {}'.format(resp.status_code, resp.json()))
    print("\nThe STU is deleted with status code: {}\n".format(resp.status_code))

def delete_disk_pools(jwt, base_url, dpid):
    url = base_url + "/storage/disk-pools/" +dpid
    headers = {'Content-Type': content_type, 'Authorization': jwt}
    query_params = {
        #	"page[limit]": 100, 				#This changes the default page size to 100
        #	"filter": "jobType eq 'RESTORE'"	#This adds a filter to only show RESTORE Jobs
    }

    print("performing DELETE  on {}\n".format(url))

    resp = requests.delete(url, headers=headers, verify=False)
    if resp.status_code != 204:
        raise Exception('DELETE DP with specific ID failed with status code {} and {}'.format(resp.status_code, resp.json()))

    print("\nThe DP is deleted with status code: {}\n".format(resp.status_code))

def add_replication_target_on_diskvolume(jwt, base_url, file_name, stsid, dvid):
    # add and delete replication target has same URI, just that the operationType parameter is DELETE_REPLICATION in case of add.
    dvid = dvid.split(":",1)[0].encode('utf-8')
    url = base_url + "/storage/storage-servers/" + stsid + "/disk-volumes/" + dvid.hex() + "/replication-targets"

    headers = {'Content-Type': content_type, 'Authorization': jwt}

    path = file_name

    req_body = open(path, 'r').read()

    print("performing POST  on {}\n".format(url), req_body)

    resp = requests.post(url, headers=headers, data=req_body, verify=False)

    if resp.status_code != 204:
        raise Exception('Add replication target on diskvolume API failed with status code {}'.format(resp.status_code))
    
    print("\nThe replication target is added with status code: {}\n".format(resp.status_code))

def get_all_replication_targets_on_diskvolume(jwt, base_url, stsid, dvid):
    dvid = dvid.split(":",1)[0].encode('utf-8')
    url = base_url + "/storage/storage-servers/" + stsid + "/disk-volumes/" + dvid.hex() + "/replication-targets"
    headers = {'Content-Type': content_type, 'Authorization': jwt}
    query_params = {
        	"page[limit]": 100, 				#This changes the default page size to 100
    }

    print("performing GET  on {}\n".format(url))

    resp = requests.get(url, headers=headers, params=query_params, verify=False)

    if resp.status_code != 200:
        raise Exception('Get all replication targets on a diskvolume API failed with status code {} and {}'.format(resp.status_code, resp.json()))
    
    return resp.json()

def get_replication_target_by_id_on_diskvolume(jwt, base_url, stsid, dvid, reptargetid):
    dvid = dvid.split(":",1)[0].encode('utf-8')
    url = base_url + "/storage/storage-servers/" + stsid + "/disk-volumes/" + dvid.hex() + "/replication-targets/" + reptargetid
    headers = {'Content-Type': content_type, 'Authorization': jwt}
    query_params = {
    }

    print("performing GET  on {}\n".format(url))

    resp = requests.get(url, headers=headers, params=query_params, verify=False)

    if resp.status_code != 200:
        raise Exception('Get replication target by specific id on a diskvolume API failed with status code {} and {}'.format(resp.status_code, resp.json()))

    return resp.json()

def delete_replication_target_on_diskvolume(jwt, base_url, file_name, stsid, dvid):
    # add and delete replication target has same URI, just that the operationType parameter is DELETE_REPLICATION in case of add.
    dvid = dvid.split(":",1)[0].encode('utf-8')
    url = base_url + "/storage/storage-servers/" + stsid + "/disk-volumes/" + dvid.hex() + "/replication-targets"

    headers = {'Content-Type': content_type, 'Authorization': jwt}

    path = file_name

    req_body = open(path, 'r').read()

    print("performing POST  on {}\n".format(url), req_body)

    resp = requests.post(url, headers=headers, data=req_body, verify=False)

    if resp.status_code != 204:
        raise Exception('Delete replication target on diskvolume API failed with status code {}'.format(resp.status_code))

    print("\nThe replication target is deleted with status code: {}\n".format(resp.status_code))

