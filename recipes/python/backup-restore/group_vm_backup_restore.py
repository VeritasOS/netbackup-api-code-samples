""" This script execute the group VM backup and restore scenario. """

## The script can be run with Python 3.6 or higher version.

## The script requires 'requests' library to make the API calls.

import argparse
import common
import vm_backup
import vm_restore

PARSER = argparse.ArgumentParser(description="Group VM backup and restore scenario")
PARSER.add_argument("--master_server", type=str, help="NetBackup master server")
PARSER.add_argument("--master_server_port", type=int, help="NetBackup port", required=False)
PARSER.add_argument("--master_username", type=str, help="NetBackup master server username")
PARSER.add_argument("--master_password", type=str, help="NetBackup master server password")
PARSER.add_argument("--vcenter_name", type=str, help="Vcenter name")
PARSER.add_argument("--vcenter_username", type=str, help="Vcenter username")
PARSER.add_argument("--vcenter_password", type=str, help="Vcenter password")
PARSER.add_argument("--vcenter_port", type=str, help="Vcenter port", required=False)
PARSER.add_argument("--protection_plan_name", type=str, help="Protection plan name")
PARSER.add_argument("--querystring", type=str, help="Query string to create the VM intelligent group")
PARSER.add_argument("--vip_group_name", type=str, help="VM intelligent group name")
PARSER.add_argument("--restore_vmname_prefix", type=str, help="Restore VM name prefix")

ARGS = PARSER.parse_args()

headers = {"Content-Type" : "application/vnd.netbackup+json;version=4.0"}

# Create VM intelligent group
def create_vm_intelligent_group(baseurl, token, vip_group_name, querystring, vcenter_name):
    """ This function will create the intelligent VM group """
    print(f"Creating VM intelligent group {vip_group_name} with query {querystring}")
    headers.update({'Authorization': token})
    payload = {}
    url = f"{baseurl}asset-service/queries"
    payload.update({
        "data": {
            "type": "query",
            "attributes": {
                "queryName": "create-or-update-assets",
                "workloads": ["vmware"],
                "parameters": {
                    "objectList": [{
                        "correlationId": "1",
                        "type": "vmwareGroupAsset",
                        "assetGroup": {
                            "commonAssetAttributes": {
                                "detection": {
                                    "detectionMethod": "MANUAL"
                                },
                                "displayName": vip_group_name,
                                "protectionCapabilities": {
                                    "isProtectable": "YES",
                                    "isRecoverable": "NO"
                                }
                            },
                            "assetType": "vmGroup",
                            "description": "AssetGroupForMultipleVM",
                            "filterConstraint": vcenter_name,
                            "oDataQueryFilter": querystring
                        }
                    }]
                }
            }
        }
    })
    status_code, response_text = common.rest_request('POST', url, headers, data=payload)
    common.validate_response(status_code, 201, response_text)
    igquery_id = response_text['data']['id']
    print(f"Query created successfully: {igquery_id}")
    print("Now checking its status..")

    # Check Status
    url = f"{baseurl}asset-service/queries/{igquery_id}"
    status = "IN_PROGRESS"
    while status == "IN_PROGRESS":
        status_code, response_text = common.rest_request('GET', url, headers)
        common.validate_response(status_code, 200, response_text)
        status = response_text['data'][0]['attributes']['workItemResponses'][0]['statusDetails']['status']

    message = response_text['data'][0]['attributes']['workItemResponses'][0]['statusDetails']['message']
    if message != "CREATED":
        raise Exception(f"Response Error:[{message}]")

    print(f"VM intelligent group {vip_group_name} and query {igquery_id} created successfully")
    return igquery_id

# Get VM Intelligent Groups
def get_vm_intelligent_group(baseurl, token, workloadtype, vip_group_name):
    """ This function will return the group id of given group VM """
    print("Get VM Intelligent Group ID")
    headers.update({'Authorization': token})
    url = f"{baseurl}asset-service/workloads/{workloadtype}/assets?&filter=((assetType eq 'vmGroup') \
                and (commonAssetAttributes/displayName eq '{vip_group_name}'))&meta=accessControlId"
    status_code, response_text = common.rest_request('GET', url, headers)
    common.validate_response(status_code, 200, response_text)
    vm_group_id = response_text['data'][0]['id']
    print(f"Successfully fetched VM Intelligent Group ID:[{vm_group_id}]")
    return vm_group_id

# Delete VM intelligent group
def remove_vm_intelligent_group(baseurl, token, vm_group_id):
    """ This function will remove the intelligent VM group """
    if vm_group_id:
        print(f"Deleting Intelligent VM group: [{vm_group_id}]")
        headers.update({'Authorization': token})
        payload = {}
        url = f"{baseurl}asset-service/queries"
        payload.update({
            "data": {
                "type": "query",
                "attributes": {
                    "queryName": "delete-assets",
                    "workloads": ["vmware"],
                    "parameters": {
                        "objectList": [{
                            "correlationId": "0",
                            "assetType": "vmGroup",
                            "id": vm_group_id
                        }]
                    }
                }
            }
        })
        status_code, response_text = common.rest_request('POST', url, headers, data=payload)
        common.validate_response(status_code, 201, response_text)
        igquery_id = response_text['data']['id']

        print(f"Deleted Intelligent VM group: [{vm_group_id}]...Now checking status...")

        url = f"{baseurl}asset-service/queries/{igquery_id}"
        status = "IN_PROGRESS"
        while status == "IN_PROGRESS":
            status_code, response_text = common.rest_request('GET', url, headers)
            data = response_text['data'][0]['attributes']
            common.validate_response(status_code, 200, response_text)
            status = data['workItemResponses'][0]['statusDetails']['status']

        message = data['workItemResponses'][0]['statusDetails']['message']
        if message != "DELETED":
            raise Exception(f"Response Error:[{message}]")

        print(f"VM intelligent group {vm_group_id} and query {igquery_id} deleted successfully")

if __name__ == '__main__':
    WORKLOAD_TYPE = 'vmware'
    SERVER_TYPE = 'VMWARE_VIRTUAL_CENTER_SERVER'
    PROTECTION_PLAN_ID = ''
    SUBSCRIPTION_ID = ''
    VM_GROUP_ID = ''
    MOUNT_ID_LIST_STR = ''

    BASEURL = common.get_nbu_base_url(ARGS.master_server, ARGS.master_server_port)
    TOKEN = common.get_authenticate_token(BASEURL, ARGS.master_username, ARGS.master_password)
    print(f"User authentication completed for master server:[{ARGS.master_server}]")

    try:
        print(f"Setup the VMware environment for vCenter:[{ARGS.vcenter_name}]")
        common.add_vcenter_credential(BASEURL, TOKEN, ARGS.vcenter_name, ARGS.vcenter_username, ARGS.vcenter_password, ARGS.vcenter_port, SERVER_TYPE)
        common.verify_vmware_discovery_status(BASEURL, TOKEN, WORKLOAD_TYPE, ARGS.vcenter_name)
        STORAGE_UNIT_NAME = common.get_storage_units(BASEURL, TOKEN)
        PROTECTION_PLAN_ID = common.create_protection_plan(BASEURL, TOKEN, ARGS.protection_plan_name, STORAGE_UNIT_NAME)

        print("Create intelligent VM group and take backup")
        create_vm_intelligent_group(BASEURL, TOKEN, ARGS.vip_group_name, ARGS.querystring, ARGS.vcenter_name)
        VM_GROUP_ID = get_vm_intelligent_group(BASEURL, TOKEN, WORKLOAD_TYPE, ARGS.vip_group_name)
        SUBSCRIPTION_ID = common.subscription_asset_to_slo(BASEURL, TOKEN, PROTECTION_PLAN_ID, VM_GROUP_ID, is_vm_group=1)

        # Group VM backup and restore
        print("Start group VM backup")
        BACKUP_JOB_ID = vm_backup.perform_vm_backup(BASEURL, TOKEN, PROTECTION_PLAN_ID, VM_GROUP_ID, is_vm_group=1)
        common.verify_job_state(BASEURL, TOKEN, BACKUP_JOB_ID, 'DONE')
        PROTECTION_BACKUP_JOB_ID, CATALOG_BACKUP_JOB_ID = vm_backup.get_backup_job_id(BASEURL, TOKEN, BACKUP_JOB_ID, ARGS.protection_plan_name)
        common.verify_job_state(BASEURL, TOKEN, PROTECTION_BACKUP_JOB_ID, 'DONE')
        common.verify_job_state(BASEURL, TOKEN, CATALOG_BACKUP_JOB_ID, 'DONE')

        print("Start bulk restore")
        MOUNT_ID_LIST_STR = vm_restore.perform_bulk_restore(BASEURL, TOKEN, BACKUP_JOB_ID, WORKLOAD_TYPE, ARGS.vcenter_name, ARGS.restore_vmname_prefix)

    finally:
        print("Start cleanup")
        # Cleanup the created protection plan
        if MOUNT_ID_LIST_STR:
            MOUNT_ID_LIST = MOUNT_ID_LIST_STR.split(",")
            for MOUNT_ID in MOUNT_ID_LIST:
                vm_restore.remove_instantaccess_vm(BASEURL, TOKEN, MOUNT_ID)
        common.remove_subscription(BASEURL, TOKEN, PROTECTION_PLAN_ID, SUBSCRIPTION_ID)
        remove_vm_intelligent_group(BASEURL, TOKEN, VM_GROUP_ID)
        common.remove_protectionplan(BASEURL, TOKEN, PROTECTION_PLAN_ID)
        common.remove_vcenter_creds(BASEURL, TOKEN, ARGS.vcenter_name)
