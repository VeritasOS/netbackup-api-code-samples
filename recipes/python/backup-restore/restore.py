## The library contain functions related to restore functionality.

## The script can be run with Python 3.5 or higher version. 

## The script requires 'requests' library to make the API calls. The library can be installed using the command: pip install requests.

import common as common
import time

headers = {"Content-Type" : "application/vnd.netbackup+json;version=4.0"}

# Perform bulk restore
def perform_bulk_restore(baseurl, token, bulk_backup_job_id, workload_type, vcenter_name, client_restore_vm_prefix):
    headers.update({'Authorization': token})
    payload = {}
    jobid_list = []
    mount_id_list = []
    job_mount_dict = {}
    error_msg = ''
    is_error = False
    url = baseurl + "admin/jobs/?filter=parentJobId eq " + str(bulk_backup_job_id) + " and jobId ne " + str(bulk_backup_job_id) + " and jobType eq 'SNAPSHOT' and state eq 'DONE' and (status eq 0 or status eq 1)"
    status_code, response_text = common.rest_request('GET', url, headers)
    common.validate_response(status_code, 200, response_text)
    for data in response_text["data"]:
        jobid_list.append(data["id"])
    print(f"Snapshot jobid list:[{(','.join(jobid_list))}]")

    for jobid in jobid_list:
        mount_id = ''
        url = baseurl + "admin/jobs/?filter=parentJobId eq " + str(jobid) + " and state eq 'DONE'"
        status_code, response_text = common.rest_request('GET', url, headers)
        common.validate_response(status_code, 200, response_text)
        backup_id = response_text['data'][0]['attributes']['backupId']
        asset_id = response_text['data'][0]['attributes']['assetID']
        asset_name = response_text['data'][0]['attributes']['assetDisplayableName']
        print(f"Backup id for job:[{jobid}] is:[{backup_id}]")
        print(f"asset id for job:[{jobid}] is:[{asset_id}]")
        print(f"asset display name for job:[{jobid}] is:[{asset_name}]")

        # Get asset info
        asset_id, instance_uuid, exsi_host = get_asset_info(baseurl, token, workload_type, asset_name)
        resource_pool = get_resource_pool(baseurl, token, workload_type, vcenter_name, exsi_host)
        print(f"Resource pool:[{resource_pool}]")
        restore_vmname = client_restore_vm_prefix + "_" + jobid
        print(f"Restore vm name for jobid:[{jobid}] is:[{restore_vmname}]")
        try:
            mount_id = create_instant_access_vm(baseurl, token, workload_type, backup_id, vcenter_name, exsi_host, resource_pool, restore_vmname)
            if mount_id:
                mount_id_list.append(mount_id)
            else:
                error_msg =  error_msg + "Unable to create the the instant VM for jobid:[" + jobid + "]"
                is_error = True
        except Exception as exc:
            error_msg =  error_msg + "Instant VM creation Exception for jobid:[" + jobid + "] is:" + exc
            is_error = True
            pass

    for jobid,mount_id in job_mount_dict.items():
        try:
            verify_instant_access_vmstate(baseurl, token, workload_type, backup_id, mount_id)
        except Exception as exc:
            error_msg =  error_msg + "Instant VM verification Exception for jobid:[" + jobid + "] is:" + exc
            is_error = True
            pass

    mount_id_list_str = ",".join(mount_id_list)
    print(f"Mount id list:[{mount_id_list_str}]")

    if is_error:
        raise Exception(error_msg)
    return mount_id_list_str


# Get vm recovery points
def get_recovery_points(baseurl, token, workload_type, asset_id):
    print(f"Get the recovery points for asset:[{asset_id}]")
    headers.update({'Authorization': token})
    url = baseurl + "recovery-point-service/workloads/" + workload_type + "/recovery-points?filter=assetId eq '" + asset_id + "'"
    status_code, response_text = common.rest_request('GET', url, headers)
    common.validate_response(status_code, 200, response_text)       
    backup_id = response_text['data'][0]['id']
    return backup_id

# Get resource pool of vcenter exsi
def get_resource_pool(baseurl, token, workload_type, vcenter_name, exsi_host):
    headers.update({'Authorization': token})
    url = baseurl + "/config/workloads/" + workload_type + "/vcenters/" + vcenter_name + "/esxiservers/" + exsi_host + "/resource-pools"
    status_code, response_text = common.rest_request('GET', url, headers)
    common.validate_response(status_code, 200, response_text)       
    resource_pool = response_text['data']['attributes']['resourcePools'][0]['path']
    return resource_pool

# Create instant access VM
def create_instant_access_vm(baseurl, token, workload_type, backup_id, vcenter_name, exsi_host, resource_pool, client_Restore_Name):
    print(f"Instant restore is initiated:[{client_Restore_Name}]")
    headers.update({'Authorization': token})
    payload = {
        "data": {
            "type": "instantAccessVmV3",
            "attributes": {
            "backupId": backup_id,
            "copyNumber": 1,
            "vCenter": vcenter_name,
            "esxiHost": exsi_host,
            "resourcePoolOrVapp": resource_pool,
            "vmName": client_Restore_Name,
            "powerOn": "True",
            "removeEthCards": "False",
            "retention": {
                "value": 30,
                "unit": "DAYS"
                },
                },
        }
    }
    url = baseurl + "recovery/workloads/" + workload_type + "/instant-access-vms"
    status_code, response_text = common.rest_request('POST', url, headers, data=payload)
    common.validate_response(status_code, 201, response_text)       
    mount_id = response_text['data']['id']
    return mount_id

# Get instant access VM state
def get_instantaccess_vmstate(baseurl, token, workload_type, mount_id):
    headers.update({'Authorization': token})
    url = baseurl + "recovery/workloads/" + workload_type + "/instant-access-vms/" + mount_id
    status_code, response_text = common.rest_request('GET', url, headers)
    common.validate_response(status_code, 200, response_text)
    status = response_text['data']['attributes']['status']
    return status

# Verify instant access VM state
def verify_instant_access_vmstate(baseurl, token, workload_type, backup_id, mount_id, timeout=600):
    # Get Vmware server discovery status
    print("Verify the instant access VM state")
    inst_access_vmstatus = ''
    end_time = time.time() + timeout
    while time.time() < end_time:
        time.sleep(20)
        inst_access_vmstatus = get_instantaccess_vmstate(baseurl, token, workload_type, mount_id)
        if inst_access_vmstatus == 'ACTIVE':
            print("Restore Successful")
            break
    else:
        print(f"Restore is failed of backup:[{backup_id}] with status:[{inst_access_vmstatus}]")
        raise Exception(f"Restore is failed of backup:[{backup_id}] with status:[{inst_access_vmstatus}]")

    print(f"Verified instant access restore status:[{inst_access_vmstatus}]")
    return mount_id 

# Remove instant access VM
def remove_instantaccess_vm(baseurl, token, mount_id):
    if mount_id:
        headers.update({'Authorization': token})
        url = baseurl + 'recovery/workloads/vmware/instant-access-vms/' +mount_id
        status_code, response_text = common.rest_request('DELETE', url, headers)
        common.validate_response(status_code, 204, response_text) 
        print(f"Successfully removed instant access vm:[{mount_id}]")
