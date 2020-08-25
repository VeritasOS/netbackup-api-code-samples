## This script execute the group VM backup and restore scenario.

## The script can be run with Python 3.6 or higher version. 

## The script requires 'requests' library to make the API calls. The library can be installed using the command: pip install requests.

import argparse
import common as common
import backup as backup
import restore as restore

parser = argparse.ArgumentParser(description="Group VM backup and restore scenario")
parser.add_argument("--master_server", type=str, help="NetBackup master server")
parser.add_argument("--master_server_port", type=int, help="NetBackup port", required=False)
parser.add_argument("--master_username", type=str, help="NetBackup master server user name")
parser.add_argument("--master_password", type=str, help="NetBackup master server password")
parser.add_argument("--vcenter_name", type=str, help="Vcenter name")
parser.add_argument("--vcenter_username", type=str, help="Vcenter username")
parser.add_argument("--vcenter_password", type=str, help="Vcenter password")
parser.add_argument("--vcenter_port", type=str, help="Vcenter port", required=False)
parser.add_argument("--protection_plan_name", type=str, help="Protection plan name")
parser.add_argument("--querystring", type=str, help="Query string to create the VM intelligent group")
parser.add_argument("--vip_group_name", type=str, help="VM intelligent group name")
parser.add_argument("--restore_vmname_prefix", type=str, help="Restore VM name prefix")

args = parser.parse_args()

# Create VM intelligent group
def create_vm_intelligent_group(baseurl, token, vip_group_name, querystring, vcenter_name):
    print("Creating VM intelligent group {} with query {}".format(vip_group_name, querystring))
    headers.update({'Authorization': token})
    payload = {}
    url = baseurl + 'asset-service/queries'
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
    igQueryId = response_text['data']['id']
    print("Query created successfully: {}".format(igQueryId))
    print("Now checking its status..")
    
    # Check Status
    url = baseurl + 'asset-service/queries/' + igQueryId
    status = "IN_PROGRESS"
    while status == "IN_PROGRESS":
        status_code, response_text = common.rest_request('GET', url, headers)
        common.validate_response(status_code, 200, response_text)
        status = response_text['data'][0]['attributes']['workItemResponses'][0]['statusDetails']['status']
        
    message = response_text['data'][0]['attributes']['workItemResponses'][0]['statusDetails']['message']
    if message != "CREATED":
        raise Exception(f"Response Error:[{message}]")
        return None
        
    print("VM intelligent group {} and query {} created successfully".format(vip_group_name, igQueryId))
    return igQueryId
    
# Get VM Intelligent Groups
def get_vm_intelligent_group(baseurl, token, workloadType, vip_group_name):
    print("Get VM Intelligent Group ID")
    headers.update({'Authorization': token})
    url = baseurl + "asset-service/workloads/{}/assets?page%5Blimit%5D=100&page%5Boffset%5D=0&filter=((assetType eq '{}') and (commonAssetAttributes/displayName eq '{}'))&meta=accessControlId".format(workloadType, 'vmGroup', vip_group_name)
    status_code, response_text = common.rest_request('GET', url, headers)
    common.validate_response(status_code, 200, response_text)
    vmGroupId = response_text['data'][0]['id']
    print(f"Successfully fetched VM Intelligent Group ID:[{vmGroupId}]")
    return vmGroupId

# Delete VM intelligent group
def remove_vm_intelligent_group(baseurl, token, vm_group_id):
    if vm_group_id:
        print(f"Deleting Intelligent VM group: [{vm_group_id}]")
        headers.update({'Authorization': token})
        payload = {}
        url = baseurl + "asset-service/queries"
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
        igQueryId = response_text['data']['id']
        
        print(f"Deleted Intelligent VM group: [{vm_group_id}]...Now checking status...")
        
        url = baseurl + 'asset-service/queries/' + igQueryId
        status = "IN_PROGRESS"
        while status == "IN_PROGRESS":
            status_code, response_text = common.rest_request('GET', url, headers)
            common.validate_response(status_code, 200, response_text)
            status = response_text['data'][0]['attributes']['workItemResponses'][0]['statusDetails']['status']

        message = response_text['data'][0]['attributes']['workItemResponses'][0]['statusDetails']['message']
        if message != "DELETED":
            raise Exception(f"Response Error:[{message}]")
            return None
            
        print("VM intelligent group {} and query {} deleted successfully".format(vm_group_id, igQueryId))

if __name__ == '__main__':
    protection_plan_id = ''
    subscription_id = ''
    vm_group_id = ''
    mount_id_list_str = ''
    workload_type = 'vmware'
    server_type = 'VMWARE_VIRTUAL_CENTER_SERVER'   
    headers = {"Content-Type" : "application/vnd.netbackup+json;version=4.0"}

    baseurl = common.get_nbu_base_url(args.master_server, args.master_server_port)
    token = common.get_authenticate_token(baseurl, args.master_username, args.master_password)
    headers['Authorization'] = token
    print(f"User authentication completed for master server:[{args.master_server}]")

    try:
        print(f"Setup the VMware environment for vcenter:[{args.vcenter_name}]")
        common.add_vcenter_credential(baseurl, token, args.vcenter_name, args.vcenter_username, args.vcenter_password, args.vcenter_port, server_type)
        common.verify_vmware_discovery_status(baseurl, token, workload_type, args.vcenter_name)
        storage_unit_name = common.get_storage_units(baseurl, token)
        protection_plan_id = common.create_protection_plan(baseurl, token, args.protection_plan_name, storage_unit_name)

        print("Create intelligent VM group and take backup")
        create_vm_intelligent_group(baseurl, token, args.vip_group_name, args.querystring, args.vcenter_name)
        vm_group_id = get_vm_intelligent_group(baseurl, token, workload_type, args.vip_group_name)
        subscription_id = common.subscription_asset_to_slo(baseurl, token, protection_plan_id, vm_group_id, is_vm_group=1)

        # Group VM backup and restore
        print("Start backup")
        backup_job_id = backup.perform_backup(baseurl, token, protection_plan_id, vm_group_id, is_vm_group=1)
        common.verify_job_state(baseurl, token, backup_job_id, 'DONE')
        protection_backup_job_id, catalog_backup_job_id = backup.get_backup_job_id(baseurl, token, backup_job_id, args.protection_plan_name)
        common.verify_job_state(baseurl, token, protection_backup_job_id, 'DONE')
        common.verify_job_state(baseurl, token, catalog_backup_job_id, 'DONE')

        print("Start bulk restore")
        mount_id_list_str = restore.perform_bulk_restore(baseurl, token, backup_job_id, workload_type, args.vcenter_name, args.restore_vmname_prefix)

    finally:
        print("Start cleanup")
        # Cleanup the created protection plan
        if mount_id_list_str:
            mount_id_list = mount_id_list_str.split(",")
            for mount_id in mount_id_list:
                restore.remove_instantaccess_vm(baseurl, token, mount_id)
        common.remove_subscription(baseurl, token, protection_plan_id, subscription_id)
        remove_vm_intelligent_group(baseurl, token, vm_group_id)
        common.remove_protectionplan(baseurl, token, protection_plan_id)
        common.remove_vcenter_creds(baseurl, token, args.vcenter_name)
