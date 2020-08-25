## The library contain common functions which are used for both single and group VM backup and restore.

## The script can be run with Python 3.5 or higher version. 

## The script requires 'requests' library to make the API calls. The library can be installed using the command: pip install requests.

import json
import os
import sys
import time
import requests

headers = {"Content-Type" : "application/vnd.netbackup+json;version=4.0"}

# Get the base netbackup url
def get_nbu_base_url(host, port):
    port = f":{str(port)}" if port else ''
    baseurl = f"https://{host}{port}/netbackup/"
    return baseurl

# Login to the netbackup and get the authorization token
def get_authenticate_token(baseurl, username, password):
    creds = {'userName':username, 'password':password}
    url = baseurl + 'login'
    status_code, response_text = rest_request('POST', url, headers, data=creds)
    validate_response(status_code, 201, response_text)
    token = response_text['token']
    return token

# Add vCenter credential
def add_vcenter_credential(baseurl, token, vcenter_server, vcenter_username, vcenter_password, vcenter_port, vcenter_server_type):
    print(f"Add the vcenter credential:[{vcenter_server}]")
    headers.update({'Authorization': token}) 
    url = baseurl + 'config/servers/vmservers'
    payload = {'serverName':vcenter_server, 'vmType':vcenter_server_type, 'userId':vcenter_username, 'password':vcenter_password, 'port':vcenter_port}
    status_code, response_text = rest_request('POST', url, headers, data=payload)
    validate_response(status_code, 201, response_text)
    print(f"Vcenter credentials added successfully:[{vcenter_server}]")

# Get Vmware server discovery status
def get_vmware_discovery_status(baseurl, token, workload_type, vcenter_server):
    headers.update({'Authorization': token})
    url = baseurl + "admin/discovery/workloads/" + workload_type + "/status?filter=serverName eq '" + vcenter_server + "'"
    status_code, response_text = rest_request('GET', url, headers)
    validate_response(status_code, 200, response_text)
    discovery_status = response_text['data'][0]['attributes']['discoveryStatus']
    return discovery_status

# Get Vmware server discovery status
def verify_vmware_discovery_status(baseurl, token, workload_type, vcenter_server, timeout=600):
    print(f"Wait for Vcenter Discovery :[{vcenter_server}]")
    discovery_status = ''
    end_time = time.time() + timeout
    while time.time() < end_time:
        time.sleep(30)
        discovery_status = get_vmware_discovery_status(baseurl, token, workload_type, vcenter_server)
        if discovery_status == 'SUCCESS':
            print(f"Vcenter added successfully:[{vcenter_server}]")
            break
    else:
        print(f"Failed to verify VCenter:[{vcenter_server}] discovery with status:[{discovery_status}]")
        sys.exit(1)
    print(f"Vcenter discovery successful:[{vcenter_server}] with status:[{discovery_status}]")

# Get asset info
def get_asset_info(baseurl, token, workload_type, client):
    print(f"Get client asset info:[{client}]")
    headers.update({'Authorization': token})
    url = baseurl + "asset-service/workloads/" + workload_type + "/assets?filter=commonAssetAttributes/displayName eq '" + client + "'"
    status_code, response_text = rest_request('GET', url, headers)
    validate_response(status_code, 200, response_text)
    asset_id = response_text['data'][0]['id']
    uuid = response_text['data'][0]['attributes']['instanceUuid']
    exsi_host = response_text['data'][0]['attributes']['host']
    print(f"Client asset Id:[{asset_id}]")
    print(f"Client uuid Id:[{uuid}]")
    print(f"Client exsi host:[{exsi_host}]")
    return asset_id, uuid, exsi_host

# Get StorageUnits
def get_storage_units(baseurl, token):
    headers.update({'Authorization': token})
    url = baseurl + "storage/storage-units"
    status_code, response_text = rest_request('GET', url, headers)
    validate_response(status_code, 200, response_text)
    storage_unit_name = response_text['data'][0]['id']
    is_instant_access_enable = response_text['data'][0]['attributes']['instantAccessEnabled']
    if is_instant_access_enable:
        print(f"Storage unit:[{storage_unit_name}] enabled for instant access")
        return storage_unit_name
    else:
        print(f"Storage unit:[{storage_unit_name}] disable for instant access")
        raise Exception(f"Storage unit:[{storage_unit_name}] disabled for instant access")

# Create protection plan
def create_protection_plan(baseurl, token, protection_plan_name, storage_unit_name):
    print(f"Create protection plan:[{protection_plan_name}]")
    headers.update({'Authorization': token})
    payload = {}
    url = baseurl + 'servicecatalog/slos?meta=accessControlId'

    cur_dir = os.path.dirname(os.path.abspath(__file__))
    file_name = os.path.join(cur_dir, "create_protection_plan_template.json")
    f = open(file_name)
    data = json.load(f)
    data['data']['attributes']['name'] = protection_plan_name
    data['data']['attributes']['policyNamePrefix'] = protection_plan_name
    data['data']['attributes']['schedules'][0]['backupStorageUnit'] = storage_unit_name
    data['data']['attributes']['allowSubscriptionEdit'] = False

    status_code, response_text = rest_request('POST', url, headers, data=data)
    validate_response(status_code, 201, response_text)
    protection_plan_id = response_text['data']['id']
    print(f"Protection plan created successfully:[{protection_plan_id}]")
    return protection_plan_id

# Subscription asset to SLO
def subscription_asset_to_slo(baseurl, token, protection_plan_id, asset_id, is_vm_group = 0):
    print(f"Subscribe client to protection plan id: [{protection_plan_id}]")
    headers.update({'Authorization': token})
    url = baseurl + "servicecatalog/slos/" + protection_plan_id + "/subscriptions"
    selection_type = "ASSETGROUP" if is_vm_group else "ASSET"
    payload = {"data": {"type": "subscription","attributes": {"selectionType": selection_type,"selectionId": asset_id}}}
    status_code, response_text = rest_request('POST', url, headers, data=payload)
    validate_response(status_code, 201, response_text)
    subscription_id = response_text['data']['id']
    print(f"Sucessfully subscribed asset id:[{asset_id}] to protection plan:[{protection_plan_id}]")
    print(f"Subscription id is:[{subscription_id}]")
    return subscription_id

# Get subscription
def get_subscription(baseurl, token, protection_plan_id, subscription_id):
    headers.update({'Authorization': token})
    url = baseurl + "servicecatalog/slos/" + protection_plan_id + "/subscriptions/" + subscription_id
    status_code, response_text = rest_request('GET', url, headers)
    validate_response(status_code, 200, response_text)
    print(f"Sucessfully fetched the subscription:[{subscription_id}] details.")
    
# Get job details
def get_job_details(baseurl, token, jobid):
    headers.update({'Authorization': token})
    url = baseurl + "admin/jobs/" + str(jobid)
    status_code, response_text = rest_request('GET', url, headers)
    validate_response(status_code, 200, response_text)
    return response_text

# Verify given job state and status
def verify_job_state(baseurl, token, jobid, expected_state, expected_status=0, timeout=1200):
    if jobid:
        print(f"Wait for backup job to complete. Backup jobid:[{jobid}]")
        # Verify backup job status
        end_time = time.time() + timeout
        while time.time() < end_time:
            time.sleep(30)
            response_text = get_job_details(baseurl, token, jobid)
            state = response_text['data']['attributes']['state']
            if state == expected_state:
                print(f"Job:[{jobid}] completed with expected state:[{expected_state}]")
                status = response_text['data']['attributes']['status']
                print(f"Actual status:[{status}] and expected status:[{expected_status}]")
                if status == expected_status or status == 1:
                    print(f"Job:[{jobid}] completed with expected status:[{expected_status}]")
                    break
                else:
                    print(f"Failed backup jobid:[{jobid}] with status:[{status}]")
                    raise Exception(f"Failed backup jobid:[{jobid}] with status:[{status}]")
        else:
            print(f"Failed backup jobid:[{jobid}] with state:[{state}]")
            raise Exception(f"Failed backup jobid:[{jobid}] with state:[{state}]")



# Remove protection plan
def remove_protectionplan(baseurl, token, protection_plan_id):
    if protection_plan_id:
        headers.update({'Authorization': token})
        url = baseurl + 'servicecatalog/slos/' +protection_plan_id
        status_code, response_text = rest_request('DELETE', url, headers)
        validate_response(status_code, 204, response_text) 
        print(f"Successfully removed protection plan:[{protection_plan_id}]")

# Remove vm subscription from protection plan
def remove_subscription(baseurl, token, protection_plan_id, subscription_id):
    if protection_plan_id and subscription_id:
        headers.update({'Authorization': token})
        url = baseurl + 'servicecatalog/slos/' +protection_plan_id+ '/subscriptions/' +subscription_id
        status_code, response_text = rest_request('DELETE', url, headers)
        validate_response(status_code, 204, response_text)  
        print(f"Successfully removed asset subscription:[{subscription_id}] from protection plan:[{protection_plan_id}]")

# Remove vcenter creds from netbackup master
def remove_vcenter_creds(baseurl, token, vcenter_name):
    if vcenter_name:
        headers.update({'Authorization': token})
        url = baseurl + 'config/servers/vmservers/' +vcenter_name
        status_code, response_text = rest_request('DELETE', url, headers)
        validate_response(status_code, 204, response_text)
        print(f"Successfully removed vcenter:[{vcenter_name}] credential")

# Execute REST API request
def rest_request(request_type, uri, header=None, **kwargs):
    session = requests.session()
    payload = kwargs.get('data')
    if request_type == 'POST':
        if not payload:
            print("Couldn't find payload. POST request needs payload.")
            sys.exit(1)
        response = session.post(uri, headers=header, json=payload, verify=False)
    elif request_type == 'PUT':
        if not payload:
            print("Couldn't find payload. PUT request needs payload.")
            sys.exit(1)
        response = session.put(uri, headers=header, json=payload, verify=False)
    elif request_type == 'GET':
        response = session.get(uri, headers=header, verify=False)
    elif request_type == 'DELETE':
        response = session.delete(uri, headers=header, verify=False)
    else:
        print(f"Invalid Rest Request type:[{request_type}].")
        sys.exit(1)

    if not response.status_code:
        print(f"Failed to send REST request:[{uri}]")
        sys.exit(1)

    if not response.text:
        response_text = '{"errorMessage":"No response text from api response"}'
    else:
        response_text = response.text

    try:
        response_text = json.loads(response_text)
    except json.decoder.JSONDecodeError:
        print(f"Could not parse json from [{response_text}]")

    print(f"Sucessfully sent REST request:[{uri}]")
    print(f"Status code:[{response.status_code}]")
    print(f"Response text:[{response.text}]")
    return response.status_code, response_text

def validate_response(actual_status_code, expected_status_code, response_text):
    # Validate the response code of the request
    if(actual_status_code == expected_status_code):
        print(f"Sucessfully validate the response status code:[{expected_status_code}]")
        return True
    else:
        print(f"Actual status code:[{actual_status_code}] not match with expected status code:[{expected_status_code}]")
        raise Exception(f"Response Error:[{response_text['errorMessage']}] and details:[{response_text['errorDetails']}]")
        return False