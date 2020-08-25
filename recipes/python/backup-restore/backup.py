## The library contain functions related to backup functionality.

## The script can be run with Python 3.5 or higher version. 

## The script requires 'requests' library to make the API calls. The library can be installed using the command: pip install requests.

import common as common

headers = {"Content-Type" : "application/vnd.netbackup+json;version=4.0"}

# Perform single VM backup
def perform_backup(baseurl, token, protection_plan_id, asset_id, is_vm_group = 0):
    headers.update({'Authorization': token})
    url = baseurl + "servicecatalog/slos/" + protection_plan_id + "/backup-now"
    selection_type = "ASSETGROUP" if is_vm_group else "ASSET"
    payload = {"data": {"type": "backupNowRequest", "attributes": {"selectionType": selection_type, "selectionId": asset_id}}}
    status_code, response_text = common.rest_request('POST', url, headers, data=payload)
    common.validate_response(status_code, 202, response_text)
    backup_job_id = response_text['data'][0]['id']
    print(f"Started backup for asset:[{asset_id}] and backup id is:[{backup_job_id}]")
    return backup_job_id
    
# Get protection and catalog backup id
def get_backup_job_id(baseurl, token, backup_job_id, protection_plan_name):
    print("Find the protection plan and catalog backup job IDs")
    protection_backup_job_id = ''
    catalog_backup_job_id = ''
    headers.update({'Authorization': token})
    url = baseurl + "admin/jobs/?filter=jobId gt " + str(backup_job_id)
    status_code, response_text = common.rest_request('GET', url, headers)
    common.validate_response(status_code, 200, response_text)

    for jobdata in response_text['data']:
        job_id = str(jobdata['id']).strip()
        parent_job_id = str(jobdata['attributes']['parentJobId']).strip()
        if jobdata['attributes']['policyName'].startswith(protection_plan_name) and job_id == parent_job_id:
            protection_backup_job_id = parent_job_id
            print(f"Protection backup Job Id:[{protection_backup_job_id}]")

        if jobdata['attributes']['policyName'].startswith('NBU_Catalog_Default') and job_id == parent_job_id:
            catalog_backup_job_id = parent_job_id
            print(f"NBU Catalog backup Job Id:[{catalog_backup_job_id}]")
    return protection_backup_job_id, catalog_backup_job_id
