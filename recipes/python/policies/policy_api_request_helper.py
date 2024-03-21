import requests
import json

content_type = "application/vnd.netbackup+json; version=4.0"
etag = ""

def perform_login(username, password, domainName, domainType, base_url):
    url = base_url + "/login"
    req_body = {"userName": username, "password": password, "domainName": domainName, "domainType": domainType}
    headers = {'Content-Type': content_type}

    print("Making POST Request to login for user '{}'\n".format(req_body['userName']))

    resp = requests.post(url, headers=headers, json=req_body, verify=False)

    if resp.status_code != 201:
        print('Login API failed with status code {} and {}\n'.format(resp.status_code, resp.json()))

    print("\nThe response code of the Login API: {}\n".format(resp.status_code))

    return resp.json()['token']

def create_netbackup_policy(jwt, base_url, policy_id, policy_name, policy_type):
    url = base_url + "/config/policies/"
    req_body = {
        "data": {
            "type": "policy",
            "id": policy_id,
            "attributes": {
                "policy": {
                    "policyName": policy_name,
                    "policyType": policy_type,
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

    print("\nMaking POST Request to create Policy with defaults \n")

    resp = requests.post(url, headers=headers, json=req_body, verify=False)

    if resp.status_code != 204:
        print(
            'Create Policy API with defaults failed with status code {} and {}\n'.format(resp.status_code, resp.json()))

    print("\n Policy with PolicyID {}, Policy Name {}  and Policy Type {} is created with status code : {}\n".format(policy_id, policy_name, policy_type, resp.status_code))


def get_netbackup_policies(jwt, base_url):
    url = base_url + "/config/policies"
    headers = {'Content-Type': content_type, 'Authorization': jwt}

    print("\nMaking GET Request to list policies ")

    resp = requests.get(url, headers=headers, verify=False)

    if resp.status_code != 200:
        print('List Policies API failed with status code {} and {}\n'.format(resp.status_code, resp.json()))

    print("\nList policy succeeded with status code: {}\n".format(resp.status_code))
    print("\n Json Response body for List policies  : \n{}\n".format(json.loads(resp.content)))


def get_netbackup_policy(jwt, base_url, policy_name):
    url = base_url + "/config/policies/" + policy_name
    global etag
    headers = {'Content-Type': content_type, 'Authorization': jwt}

    print("\nperforming GET  on {}\n".format(url))

    resp = requests.get(url, headers=headers, verify=False)

    if resp.status_code != 200:
        print('GET Policy API failed with status code {} and {}\n'.format(resp.status_code, resp.json()))

    print("\nGet policy details on {} succeeded with status code: {}\n".format(policy_name, resp.status_code))
    print("\n The E-tag for the get policy : {}\n".format(resp.headers['ETag']))
    etag = resp.headers['ETag']
    print("\n Json Response body for get policy : \n{}\n".format(json.loads(resp.content)))

def copy_netbackup_policy(jwt, base_url, existing_policy_name, new_policy_name):
    url = base_url + "/config/policies/" + existing_policy_name + "/copy"
    req_body = {
        "data": {
            "type": "copyPolicyRequest",
            "id": new_policy_name,
            "attributes": {
                "copyPolicyRequest": {
                    "id": new_policy_name
                }
            }
        }
    }
    headers = {'Content-Type': content_type, 'Authorization': jwt}

    print("\nMaking POST Request to copy Policy \n")

    resp = requests.post(url, headers=headers, json=req_body, verify=False)

    if resp.status_code != 204:
        print(
            'Copy Policy API with defaults failed with status code {} and {}\n'.format(resp.status_code, resp.json()))

    print("\n Policy with Policy name {} has been to a new policy named {} with status code : {}\n".format(existing_policy_name, new_policy_name, resp.status_code))



def delete_netbackup_policy(jwt, base_url, policy_name):
    url = base_url + "/config/policies/" + policy_name
    headers = {'Content-Type': content_type, 'Authorization': jwt, 'If-Match': etag}

    print("\n Making policy DELETE Request on {}".format(policy_name))

    resp = requests.delete(url, headers=headers, verify=False)

    if resp.status_code != 204:
        print('DELETE Policy API failed with status code {} and {}\n'.format(resp.status_code, resp.json()))

    print("\nThe policy is deleted with status code: {}\n".format(resp.status_code))


def put_netbackup_policy(jwt, base_url, policy_id, policy_name, policy_type):
    url = base_url + "/config/policies/" + policy_name
    global etag
    req_body = {
        "data": {
            "type": "policy",
            "id": policy_id,
            "attributes": {
                "policy": {
                    "policyName": policy_name,
                    "policyType": policy_type,
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
    headers = {'Content-Type': content_type, 'Authorization': jwt, 'If-Match': etag}

    print("\n Making Update Request on {} by changing few attributes of the policy".format(policy_name))

    resp = requests.put(url, headers=headers, json=req_body, verify=False)

    if resp.status_code != 204:
        print('PUT Policy API failed with status code {} and {}\n'.format(resp.status_code, resp.json()))
    etag = resp.headers['ETag']
    print("\n{} Updated with status code : {}\n".format(policy_name, resp.status_code))


def put_netbackup_client(jwt, base_url, policy_name, client_name, policy_type):
    url = base_url + "/config/policies/" + policy_name + "/clients/" + client_name
    global etag
    req_body = {
        "data": {
            "type": "client",
            "attributes": {
                "hardware": policy_type,
                "hostName": client_name,
                "OS": "VMware"
            }
        }
    }
    headers = {'Content-Type': content_type, 'Authorization': jwt, 'If-Match': etag}

    print("\n Making PUT Request to add client to {}".format(policy_name))

    resp = requests.put(url, headers=headers, json=req_body, verify=False)

    if resp.status_code != 201:
        print('PUT Client API failed with status code {} and {}\n'.format(resp.status_code, resp.json()))
    etag = resp.headers['ETag']
    print("\n{} is added to {} with status code : {}\n".format(client_name, policy_name, resp.status_code))

def get_netbackup_unique_policy_clients(jwt, base_url):
    url = base_url + "/config/unique-policy-clients"
    headers = {'Content-Type': content_type, 'Authorization': jwt}

    print("\nMaking GET Request to list unique clients associated with policies ")

    resp = requests.get(url, headers=headers, verify=False)

    if resp.status_code != 200:
        print('Unique policy clients API failed with status code {} and {}\n'.format(resp.status_code, resp.json()))

    print("\nUnique policy clients succeeded with status code: {}\n".format(resp.status_code))
    print("\n Json Response body for Unique policy clients  : \n{}\n".format(json.loads(resp.content)))

def delete_netbackup_client(jwt, base_url, policy_name, client_name):
    url = base_url + "/config/policies/" + policy_name + "/clients/" + client_name
    global etag
    headers = {'Content-Type': content_type, 'Authorization': jwt, 'If-Match': etag}

    print("\nMaking DELETE Request to remove clients from the policy\n")

    resp = requests.delete(url, headers=headers, verify=False)

    if resp.status_code != 204:
        print('DELETE Client API failed with status code {} and {}\n'.format(resp.status_code, resp.json()))
    etag = resp.headers['ETag']
    print("\nClient {} is deleted from {} with status code: {}\n".format(client_name, policy_name,
                                                                         resp.status_code))

def put_netbackup_backupselections(jwt, base_url, policy_name, testBackupSelectionName):
    url = base_url + "/config/policies/" + policy_name + "/backupselections"
    global etag
    req_body = {
        "data": {
            "type": "backupSelection",
            "attributes": {
                "selections": [
                    "vmware:/?filter=Displayname Equal \"" + testBackupSelectionName + "\""
                ]
            }
        }
    }
    headers = {'Content-Type': content_type, 'Authorization': jwt, 'If-Match': etag}

    print("\nMaking PUT Request to add BackupSelections to {}\n".format(policy_name))

    resp = requests.put(url, headers=headers, json=req_body, verify=False)

    if resp.status_code != 204:
        print('PUT Backupselections API failed with status code {} and {}\n'.format(resp.status_code, resp.json()))
    etag = resp.headers['ETag']
    print("\n Backupselections added to {} with status code: {}\n".format(policy_name, resp.status_code))

def delete_netbackup_backupselections(jwt, base_url, policy_name):
    url = base_url + "/config/policies/" + policy_name + "/backupselections"
    headers = {'Content-Type': content_type, 'Authorization': jwt}

    print("Making DELETE Request to remove Backupselections from the policy\n")

    resp = requests.delete(url, headers=headers, verify=False)

    if resp.status_code != 204:
        print('DELETE Backupselections API failed with status code {} and {}\n'.format(resp.status_code, resp.json()))

    print("\n BackupSelections is deleted for the {}  with status code : {}\n".format(policy_name,
                                                                                      resp.status_code))