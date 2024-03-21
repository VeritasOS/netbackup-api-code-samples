""" The library contain common functions which are used for both single and group VM backup and restore. """

## The script can be run with Python 3.6 or higher version.

## The script requires 'requests' library to make the API calls.

import json
import os
import sys
import time
import requests
import uuid

headers = {"Content-Type" : "application/vnd.netbackup+json;version=4.0"}

# Get the base NetBackup url
def get_nbu_base_url(host, port):
    """ This function return NetBackup base url """
    port = f":{str(port)}" if port else ''
    baseurl = f"https://{host}{port}/netbackup/"
    return baseurl

# Login to the NetBackup and get the authorization token
def get_authenticate_token(baseurl, username, password):
    """ This function return token of NB master server """
    creds = {'userName':username, 'password':password}
    url = f"{baseurl}login"
    status_code, response_text = rest_request('POST', url, headers, data=creds)
    validate_response(status_code, 201, response_text)
    token = response_text['token']
    return token

# Add vCenter credential
def add_vcenter_credential(baseurl, token, vcenter_server, vcenter_username, vcenter_password, vcenter_port, vcenter_server_type):
    """ This function add the vCenter into NBU master server """
    print(f"Add the vCenter credential:[{vcenter_server}]")
    headers.update({'Authorization': token})
    url = f"{baseurl}config/servers/vmservers"
    payload = {'serverName':vcenter_server, 'vmType':vcenter_server_type, 'userId':vcenter_username,\
                    'password':vcenter_password, 'port':vcenter_port}
    status_code, response_text = rest_request('POST', url, headers, data=payload)
    validate_response(status_code, 201, response_text)
    print(f"vCenter credentials added successfully:[{vcenter_server}]")

# Get Vmware server discovery status
def get_vmware_discovery_status(baseurl, token, workload_type, vcenter_server):
    """ This function return the discovery status of vCenter server """
    headers.update({'Authorization': token})
    url = f"{baseurl}admin/discovery/workloads/{workload_type}/status?"\
                f"filter=serverName eq '{vcenter_server}'"
    status_code, response_text = rest_request('GET', url, headers)
    validate_response(status_code, 200, response_text)
    discovery_status = response_text['data'][0]['attributes']['discoveryStatus']
    return discovery_status

# Verify Vmware server discovery status
def verify_vmware_discovery_status(baseurl, token, workload_type, vcenter_server, timeout=600):
    """ This function verify the 'SUCESS' discovery status of vCenter """
    print(f"Wait for vCenter Discovery :[{vcenter_server}]")
    discovery_status = ''
    end_time = time.time() + timeout
    while time.time() < end_time:
        time.sleep(30)
        discovery_status = get_vmware_discovery_status(baseurl, token, workload_type, vcenter_server)
        if discovery_status == 'SUCCESS':
            print(f"vCenter added successfully:[{vcenter_server}]")
            break
    else:
        print(f"Failed to verify vCenter:[{vcenter_server}] discovery with status:[{discovery_status}]")
        sys.exit(1)
    print(f"vCenter discovery successful:[{vcenter_server}] with status:[{discovery_status}]")

# Get asset info
def get_asset_info(baseurl, token, workload_type, client):
    """ This function return the asset info """
    print(f"Get client asset info:[{client}]")
    headers.update({'Authorization': token})
    url = f"{baseurl}asset-service/workloads/{workload_type}/assets?"\
                f"filter=commonAssetAttributes/displayName eq '{client}'"
    status_code, response_text = rest_request('GET', url, headers)
    validate_response(status_code, 200, response_text)

    asset_id = response_text['data'][0]['id']
    uuid = response_text['data'][0]['attributes']['instanceUuid']
    exsi_host = response_text['data'][0]['attributes']['host']

    print(f"Client asset Id:[{asset_id}]")
    print(f"Client uuid Id:[{uuid}]")
    print(f"Client exsi host:[{exsi_host}]")
    return asset_id, uuid, exsi_host

# Verify the storage unit is supported for instant access
def verify_stu_instant_access_enable(baseurl, token, storage_unit_name):
    """ Verify the storage unit is supported for instant access """
    headers.update({'Authorization': token})
    url = f"{baseurl}storage/storage-units/?filter=name eq '{storage_unit_name}'"
    status_code, response_text = rest_request('GET', url, headers)
    validate_response(status_code, 200, response_text)
    is_instant_access_enable = response_text['data'][0]['attributes']['instantAccessEnabled']

    if is_instant_access_enable:
        print(f"Storage unit:[{storage_unit_name}] enabled for instant access")
    else:
        print(f"Storage unit:[{storage_unit_name}] disable for instant access")
        raise Exception(f"Storage unit:[{storage_unit_name}] disabled for instant access")

# Create protection plan
def create_protection_plan(baseurl, token, protection_plan_name, storage_unit_name):
    """ This function create the protection plan """
    print(f"Create protection plan:[{protection_plan_name}]")
    headers.update({'Authorization': token})
    url = f"{baseurl}servicecatalog/slos?meta=accessControlId"

    cur_dir = os.path.dirname(os.path.abspath(__file__))
    cur_dir = cur_dir + os.sep + "sample-payloads" + os.sep
    file_name = os.path.join(cur_dir, "create_protection_plan_template.json")
    with open(file_name, 'r') as file_handle:
        data = json.load(file_handle)
    data['data']['attributes']['name'] = protection_plan_name
    data['data']['attributes']['policyNamePrefix'] = protection_plan_name
    data['data']['attributes']['schedules'][0]['backupStorageUnit'] = storage_unit_name
    data['data']['attributes']['allowSubscriptionEdit'] = False
 
    status_code, response_text = rest_request('POST', url, headers, data=data)
    validate_response(status_code, 201, response_text)
    protection_plan_id = response_text['data']['id']
    print(f"Protection plan created successfully:[{protection_plan_id}]")
    return protection_plan_id

def run_netbackup_policy(base_url, token, policy_name):
    print(f"Run policy:[{policy_name}]")
    headers.update({'Authorization': token})
    url = base_url + "/admin/manual-backup/"

    cur_dir = os.path.dirname(os.path.abspath(__file__))
    cur_dir = cur_dir + os.sep + "sample-payloads" + os.sep
    file_name = os.path.join(cur_dir, "post_manual_backup.json")
    with open(file_name, 'r') as file_handle:
        data = json.load(file_handle)
    data['data']['attributes']['policyName'] = policy_name

    status_code, response_text = rest_request('POST', url, headers, data=data)
    validate_response(status_code, 202, response_text)
    print(f"Policy run successfully:[{policy_name}]")
    return response_text['data'][0]['id']

def delete_netbackup_policy(base_url, token, policy_name):
    print(f"Delete policy:[{policy_name}]")
    headers.update({'Authorization': token})
    url = base_url + f"/config/policies/{policy_name}"
    status_code, response_text = rest_request('DELETE', url, headers, data='')
    validate_response(status_code, 204, response_text)
    print(f"Policy deleted successfully:[{policy_name}]")

# Subscription asset to SLO
def subscription_asset_to_slo(baseurl, token, protection_plan_id, asset_id, is_vm_group=0):
    """ This function subscribe the asset/group asset to protection plan """
    print(f"Subscribe client to protection plan id: [{protection_plan_id}]")
    headers.update({'Authorization': token})
    url = f"{baseurl}servicecatalog/slos/{protection_plan_id}/subscriptions"
    selection_type = "ASSETGROUP" if is_vm_group else "ASSET"
    payload = {"data": {"type": "subscription", "attributes": \
                {"selectionType": selection_type, "selectionId": asset_id}}}
    status_code, response_text = rest_request('POST', url, headers, data=payload)
    validate_response(status_code, 201, response_text)
    subscription_id = response_text['data']['id']
    print(f"Sucessfully subscribed asset id:[{asset_id}] to protection plan:[{protection_plan_id}]")
    print(f"Subscription id is:[{subscription_id}]")
    return subscription_id

# Get subscription
def get_subscription(baseurl, token, protection_plan_id, subscription_id):
    """ This function return the subscription info """
    headers.update({'Authorization': token})
    url = f"{baseurl}servicecatalog/slos/{protection_plan_id}/subscriptions/{subscription_id}"
    status_code, response_text = rest_request('GET', url, headers)
    validate_response(status_code, 200, response_text)
    print(f"Sucessfully fetched the subscription:[{subscription_id}] details.")

def protection_plan_backupnow(baseurl, token, protection_plan_id, asset_id):
    """ This function will trigger the backup of given asset using protection plan"""
    headers.update({'Authorization': token})
    url = f"{baseurl}servicecatalog/slos/{protection_plan_id}/backup-now"
    selection_type = "ASSET"
    payload = {"data": {"type": "backupNowRequest",
                        "attributes": {"selectionType": selection_type, "selectionId": asset_id}}}

    status_code, response_text = rest_request('POST', url, headers, data=payload)
    validate_response(status_code, 202, response_text)
    backup_job_id = response_text['data'][0]['id']
    print(f"Started backup for asset:[{asset_id}] and backup id is:[{backup_job_id}]")
    return backup_job_id

# Get job details
def get_job_details(baseurl, token, jobid):
    """ This function return the job details """
    headers.update({'Authorization': token})
    url = f"{baseurl}admin/jobs/{str(jobid)}"
    status_code, response_text = rest_request('GET', url, headers)
    validate_response(status_code, 200, response_text)
    return response_text

# Verify given job state and status
def verify_job_state(baseurl, token, jobid, expected_state, expected_status=0, timeout=1200):
    """ This function verify the job status and state with expected status and state """
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
                if status == expected_status:
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
    """ This function remove the given protection plan """
    if protection_plan_id:
        headers.update({'Authorization': token})
        url = f"{baseurl}servicecatalog/slos/{protection_plan_id}"
        status_code, response_text = rest_request('DELETE', url, headers)
        validate_response(status_code, 204, response_text)
        print(f"Successfully removed protection plan:[{protection_plan_id}]")

# Remove vm subscription from protection plan
def remove_subscription(baseurl, token, protection_plan_id, subscription_id):
    """ This function remove subscription from protection plan """
    if protection_plan_id and subscription_id:
        headers.update({'Authorization': token})
        url = f"{baseurl}servicecatalog/slos/{protection_plan_id}/subscriptions/{subscription_id}"
        status_code, response_text = rest_request('DELETE', url, headers)
        validate_response(status_code, 204, response_text)
        print(f"Successfully removed asset subscription:[{subscription_id}] "\
                f"from protection plan:[{protection_plan_id}]")

# Remove vCenter creds from NetBackup master
def remove_vcenter_creds(baseurl, token, vcenter_name):
    """ This function remove the vCenter from NBU master """
    if vcenter_name:
        headers.update({'Authorization': token})
        url = f"{baseurl}config/servers/vmservers/{vcenter_name}"
        status_code, response_text = rest_request('DELETE', url, headers)
        validate_response(status_code, 204, response_text)
        print(f"Successfully removed vCenter:[{vcenter_name}] from NBU master")

# Execute REST API request
def rest_request(request_type, uri, header=None, **kwargs):
    """ This function make call to the REST API """
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

    print(f"Successfully sent REST request:[{uri}]")
    print(f"Status code:[{response.status_code}]")
    print(f"Response text:[{response.text}]")
    return response.status_code, response_text

def get_recovery_points(baseurl, token, workload_type, asset_id):
    """ This function return the recovery point of given asset """
    print(f"Get the recovery points for asset:[{asset_id}]")
    headers.update({'Authorization': token})
    url = f"{baseurl}recovery-point-service/workloads/{workload_type}/"\
                f"recovery-points?filter=assetId eq '{asset_id}'"
    status_code, response_text = rest_request('GET', url, headers)
    validate_response(status_code, 200, response_text)
    if (len(response_text['data'])>0):
        recoverypoint_id = response_text['data'][0]['id']
    else:
        recoverypoint_id = ""
    return recoverypoint_id

def get_recovery_point_copy_info(baseurl, token, workload_type, recovery_point_id):
    """ This function returns the optional information for a given recovery point"""
    print(f"Get the recovery point optional info:[{recovery_point_id}]")
    headers.update({'Authorization': token})
    include = f"optional{workload_type.capitalize()}RecoveryPointInfo"
    url = f"{baseurl}recovery-point-service/workloads/{workload_type}/"\
                f"recovery-points/{recovery_point_id}?include={include}"
    status_code, response_text = rest_request('GET', url, headers)
    validate_response(status_code, 200, response_text)
    if (len(response_text['included'])>0):
        print(response_text)
        copy_info = response_text['included'][0]['attributes']['backupImageCopyInfo']
    else:
        copy_info = []
    return copy_info

# Validate the response code of the request
def validate_response(actual_status_code, expected_status_code, response_text):
    """ This function validate the response status code with expected response code """
    if actual_status_code == expected_status_code:
        print(f"Successfully validated the response status code:[{expected_status_code}]")
    else:
        print(f"Actual status code:[{actual_status_code}] not match "\
                f"with expected status code:[{expected_status_code}]")
        raise Exception(f"Response Error:[{response_text['errorMessage']}] and "\
                            f"details:[{response_text['errorDetails']}]")

