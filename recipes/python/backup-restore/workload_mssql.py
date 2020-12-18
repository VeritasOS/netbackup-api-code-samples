"""
The library contain functions related to NetBackup MSSQL workload
"""

## The script can be run with Python 3.6 or higher version.


import common
import json
import os
import uuid
import datetime

class MssqlDatabase:
    def __init__(self, databasename, assetid):
        self.databasename = databasename
        self.assetid = assetid

SqlDatabases=[]
headers = {"Content-Type" : "application/vnd.netbackup+json;version=4.0"}

# Get mssql_asset info
def get_mssql_asset_info(baseurl, token, asset_type, host_name, display_name, instance_name='MSSQLSERVER'):
    """ This function return the asset info """
    print(f"Get client asset info for MSSQL type :[asset_type]")
    headers.update({'Authorization': token})
    if (asset_type == "database"):
        url = f"{baseurl}asset-service/workloads/mssql/assets?"\
            f"filter=assetType eq '{asset_type}' and displayName eq '{display_name}' and clientName eq '{host_name}' and instanceName eq '{instance_name}'"
    else:
        url = f"{baseurl}asset-service/workloads/mssql/assets?"\
            f"filter=assetType eq '{asset_type}' and displayName eq '{display_name}' and clientName eq '{host_name}'"
    status_code, response_text = common.rest_request('GET', url, headers)
    common.validate_response(status_code, 200, response_text)

    asset_id = response_text['data'][0]['id']

    print(f"Client asset Id:[{asset_id}]")
    return asset_id

# Get mssql_alldbs
def get_mssql_alldbs(baseurl, token, host_name, instance_name='MSSQLSERVER'):
    """ This function returns all database assets """
    print(f"Get all databases asset info for MSSQL server [{host_name}]")
    headers.update({'Authorization': token})
    url = f"{baseurl}asset-service/workloads/mssql/assets?"\
        f"filter=assetType eq 'database' and clientName eq '{host_name}' and instanceName eq '{instance_name}'"
    getNext = True
    while getNext:
        status_code, response_text = common.rest_request('GET', url, headers)
        print(f"status code is [{status_code}]")
        if (status_code == 200):
            limit = len(response_text['data'])
            for i in range(0,limit,1):
                attr = response_text['data'][i]['attributes']
                assetid = response_text['data'][i]['id']
                dbname = response_text['data'][i]['attributes']['commonAssetAttributes']['displayName']
                lastbackup = ""
                if ("backupDetails" in attr):
                    if ("lastFullBackup" in attr['backupDetails']):
                        lastbackup = response_text['data'][i]['attributes']['backupDetails']['lastFullBackup']
                if (lastbackup):
                    db=MssqlDatabase(dbname,assetid)
                    SqlDatabases.append(db)
            link = response_text['links']
            if ("next" in link):
                if ("href" in link['next']):
                    url = response_text['links']['next']['href']
            getNext = response_text['meta']['pagination']['hasNext']

    return SqlDatabases

# Create protection plan
def create_mssql_protection_plan(baseurl, token, protection_plan_name, storage_unit_name, workload_type):
    """ This function will create the version 3 protection plan """
    print(f"Create protection plan:[{protection_plan_name}]")
    headers.update({'Authorization': token})
    url = f"{baseurl}servicecatalog/slos?meta=accessControlId"

    cur_dir = os.path.dirname(os.path.abspath(__file__))
    cur_dir = cur_dir + os.sep + "sample-payloads" + os.sep
    file_name = os.path.join(cur_dir, "create_mssql_protection_plan_template.json")
    with open(file_name, 'r') as file_handle:
        data = json.load(file_handle)
    data['data']['attributes']['description'] = "Protection Plan for MSSQL Workload"
    data['data']['attributes']['name'] = protection_plan_name
    data['data']['attributes']['policyNamePrefix'] = protection_plan_name
    data['data']['attributes']['workloadType'] = workload_type
    data['data']['attributes']['schedules'][0]['backupStorageUnit'] = storage_unit_name
    #adjust the dayOfWeek for the current day, and startSeconds and duration in seconds for an hour
    dow = datetime.datetime.today().isoweekday()
    now = datetime.datetime.now()
    midnight = now.replace(hour=0, minute=0, second=0, microsecond=0)
    seconds = (now - midnight).seconds
    if (dow == 7):
        dow = 0
    else:
        dow = dow + 1
    data['data']['attributes']['schedules'][0]['backupWindows'][0]['dayOfWeek'] = dow
    seconds = seconds - 600
    data['data']['attributes']['schedules'][0]['backupWindows'][0]['startSeconds'] = seconds
    seconds = 3600
    data['data']['attributes']['schedules'][0]['backupWindows'][0]['durationSeconds'] = seconds

    #FULL schedule type with 4 week retention and a frequency of everyday 
    data['data']['attributes']['schedules'][0]['scheduleType'] = "FULL"
    data['data']['attributes']['schedules'][0]['frequencySeconds'] = 86400
    data['data']['attributes']['schedules'][0]['retention']['value'] = 4
    data['data']['attributes']['schedules'][0]['retention']['unit'] = "WEEKS"

    status_code, response_text = common.rest_request('POST', url, headers, data=data)
    common.validate_response(status_code, 201, response_text)
    protection_plan_id = response_text['data']['id']
    print(f"Protection plan created successfully:[{protection_plan_id}]")
    return protection_plan_id

def create_netbackup_policy(base_url, token, policy_name, client, storage_unit_name, copy_storage_unit_name):
    print(f"Create policy:[{policy_name}]")
    headers.update({'Authorization': token})
    url = base_url + "/config/policies/"

    cur_dir = os.path.dirname(os.path.abspath(__file__))
    cur_dir = cur_dir + os.sep + "sample-payloads" + os.sep
    file_name = os.path.join(cur_dir, "create_mssql_policy_template.json")
    with open(file_name, 'r') as file_handle:
        data = json.load(file_handle)
    data['data']['attributes']['policy']['policyName'] = policy_name
    data['data']['id'] = policy_name
    data['data']['attributes']['policy']['clients'][0]['hostName'] = client
    data['data']['attributes']['policy']['policyAttributes']['storage'] = storage_unit_name
    data['data']['attributes']['policy']['schedules'][0]['backupCopies']['copies'][0]['storage'] = storage_unit_name
    data['data']['attributes']['policy']['schedules'][0]['backupCopies']['copies'][1]['storage'] = copy_storage_unit_name

    status_code, response_text = common.rest_request('POST', url, headers, data=data)
    common.validate_response(status_code, 204, response_text)
    print(f"Policy created successfully:[{policy_name}]")

# Update SLO Mssql attributes
def update_protection_plan_mssql_attr(baseurl, token, protection_plan_name, protection_plan_id, skip_offline_db=0):
    """ Update SLO with mssql attributes """
    headers.update({'Authorization': token})
    url = f"{baseurl}servicecatalog/slos/{protection_plan_id}"
    status_code, response_text = common.rest_request('GET', url, headers)
    common.validate_response(status_code, 200, response_text)
    response_text['data']['attributes']['policyDefinition']['policy']['policyAttributes']['databaseOptions']['skipUnavailableDatabases'] = True
    response_text['data']['attributes']['policyDefinition']['policy']['policyAttributes']['databaseOptions']['parallelBackupOps'] = 10
    response_text['data']['attributes']['policyDefinition']['policy']['schedules'][0]['storageIsSLP'] = False
    payload = response_text
    status_code, response_text2 = common.rest_request('PUT', url, headers, data=payload)
    common.validate_response(status_code, 204, response_text2)

def mssql_instance_deepdiscovery(baseurl, token, mssql_instance_id):
    """ This function will invoke deep discovery for databases on the instance"""
    headers.update({'Authorization': token})
    url = f"{baseurl}/asset-service/queries"
    cur_dir = os.path.dirname(os.path.abspath(__file__))
    cur_dir = cur_dir + os.sep + "sample-payloads" + os.sep
    file_name = os.path.join(cur_dir, 'post_mssql_instance_deepdiscovery.json')
    with open(file_name, 'r') as file_handle:
        data = json.load(file_handle)
    data['data']['attributes']['parameters']['objectList'][0]['instanceId'] = mssql_instance_id

    print(f"MSSQL deep discovery for databases ")
    status_code, response_text = common.rest_request('POST', url, headers, data=data)
    common.validate_response(status_code, 201, response_text)
    print(f"MSSQL deep discovery for databases started successfully")

def add_mssql_credential(baseurl, token, mssql_use_localcreds, mssql_domain, mssql_username, mssql_password):
    """ This function add the MSSQL into NBU master server """
    print(f"Add MSSQL credential")
    x = uuid.uuid1()
    headers.update({'Authorization': token})
    url = f"{baseurl}/config/credentials"

    cur_dir = os.path.dirname(os.path.abspath(__file__))
    cur_dir = cur_dir + os.sep + "sample-payloads" + os.sep
    file_name = os.path.join(cur_dir, 'post_mssql_credential.json')
    with open(file_name, 'r') as file_handle:
        data = json.load(file_handle)
    data['data']['id'] = str(x)
    data['data']['type'] = "credentialRequest"
    data['data']['attributes']['name'] = "pyname"
    data['data']['attributes']['tag'] = "pytag"
    if mssql_use_localcreds:
        data['data']['attributes']['contents']['useLocalCredentials'] = True
    else:
        data['data']['attributes']['contents']['domain'] = mssql_domain
        data['data']['attributes']['contents']['username'] = mssql_username
        data['data']['attributes']['contents']['password'] = mssql_password
    data['data']['attributes']['description'] = "pydesc"

    status_code, response_text = common.rest_request('POST', url, headers, data=data)
    common.validate_response(status_code, 201, response_text)
    print(f"MSSQL credentials added successfully")
    return response_text['data']['id'], response_text['data']['attributes']['name']

# update INSTANCE asset with credentials
def update_mssql_instance_credentials(baseurl, token, instance_id, credential_name):
    """ This function updates MSSQL INSTANCE asset with the credential"""
    print(f"Update MSSQL instance credentials")
    headers.update({'Authorization': token})
    url = f"{baseurl}/asset-service/queries"

    cur_dir = os.path.dirname(os.path.abspath(__file__))
    cur_dir = cur_dir + os.sep + "sample-payloads" + os.sep
    file_name = os.path.join(cur_dir, 'update_mssql_instance_credentials.json')
    with open(file_name, 'r') as file_handle:
        data = json.load(file_handle)
    data['data']['attributes']['parameters']['objectList'][0]['id'] = instance_id
    data['data']['attributes']['parameters']['objectList'][0]['asset']['commonAssetAttributes']['credentials'][0]['credentialName'] = credential_name

    status_code, response_text = common.rest_request('POST', url, headers, data=data)
    common.validate_response(status_code, 201, response_text)
    print(f"MSSQL credentials updated successfully")

# validate assigned credential to the instance-asset is valid
def validate_mssql_credential(baseurl, token, instance_id):
    """ This function validates MSSQL credential assigned to the INSTANCE asset """
    print(f"Validate MSSQL credential")
    headers.update({'Authorization': token})
    url = f"{baseurl}/asset-service/queries"

    cur_dir = os.path.dirname(os.path.abspath(__file__))
    cur_dir = cur_dir + os.sep + "sample-payloads" + os.sep
    file_name = os.path.join(cur_dir, 'validate_mssql_instance_credentials.json')
    with open(file_name, 'r') as file_handle:
        data = json.load(file_handle)
    data['data']['attributes']['parameters']['objectList'][0]['assetId'] = instance_id

    status_code, response_text = common.rest_request('POST', url, headers, data=data)
    common.validate_response(status_code, 201, response_text)
    print(f"MSSQL credentials validated successfully")

# remove mssql credential
def remove_mssql_credential(baseurl, token, credential_id):
    """ This function is for mssql remove credential request"""
    print(f"remove mssql credential:[{credential_id}]")
    headers.update({'Authorization': token})
    url = f"{baseurl}/config/credentials/{credential_id}"

    status_code, response_text = common.rest_request('DELETE', url, headers)
    common.validate_response(status_code, 204, response_text)

# Create mssql instance asset and register it
def create_and_register_mssql_instance(baseurl, token, instance_name, server_name, credential_name):
    """ This function is for mssql create instance and register request"""
    print(f"create mssql instance and register request:[{instance_name}]")
    headers.update({'Authorization': token})
    url = f"{baseurl}asset-service/queries"

    cur_dir = os.path.dirname(os.path.abspath(__file__))
    cur_dir = cur_dir + os.sep + "sample-payloads" + os.sep
    file_name = os.path.join(cur_dir, 'post_mssql_create_instance.json')
    with open(file_name, 'r') as file_handle:
        data = json.load(file_handle)
    data['data']['attributes']['parameters']['objectList'][0]['asset']['commonAssetAttributes']['displayName'] = instance_name
    data['data']['attributes']['parameters']['objectList'][0]['asset']['commonAssetAttributes']['credentials'][0]['credentialName'] = credential_name
    data['data']['attributes']['parameters']['objectList'][0]['asset']['clientName'] = server_name

    status_code, response_text = common.rest_request('POST', url, headers, data=data)
    common.validate_response(status_code, 201, response_text)
    get_query_url = response_text['data']['links']['self']['href']
    url = f"{baseurl}{get_query_url}"

    status_code, response_text = common.rest_request('GET', url, headers)

# Create mssql recovery request
def create_mssql_recovery_request(baseurl, token, mssql_recovery_input, rp_id, asset_id, mssql_sysadm_user, mssql_sysadm_domain, mssql_sysadm_pwd, mssql_alt_db_name, mssql_alt_db_path, mssql_instance_name, mssql_server_name, recover_from_copy):
    """ This function is for mssql recovery request"""
    print(f"create mssql recovery request:[{mssql_recovery_input}]")
    headers.update({'Authorization': token})
    url = f"{baseurl}/recovery/workloads/mssql/scenarios/database-complete-recovery/recover"

    cur_dir = os.path.dirname(os.path.abspath(__file__))
    cur_dir = cur_dir + os.sep + "sample-payloads" + os.sep
    file_name = os.path.join(cur_dir, mssql_recovery_input)
    with open(file_name, 'r') as file_handle:
        data = json.load(file_handle)
    data['data']['attributes']['recoveryPoint'] = rp_id
    data['data']['attributes']['recoveryObject']['assetId'] = asset_id
    data['data']['attributes']['recoveryObject']['credentials']['domain'] = mssql_sysadm_domain
    data['data']['attributes']['recoveryObject']['credentials']['userName'] = mssql_sysadm_user
    data['data']['attributes']['recoveryObject']['credentials']['password'] = mssql_sysadm_pwd
    data['data']['attributes']['alternateRecoveryOptions']['databaseName'] = mssql_alt_db_name
    data['data']['attributes']['alternateRecoveryOptions']['instanceName'] = mssql_instance_name
    data['data']['attributes']['alternateRecoveryOptions']['client'] = mssql_server_name
    data['data']['attributes']['alternateRecoveryOptions']['alternateFileLocation']['renameAllFilesToSameLocation'] = mssql_alt_db_path
    if(recover_from_copy):
        info = common.get_recovery_point_copy_info(baseurl, token, 'mssql', rp_id)
        if(len(info)>0):
            data['data']['attributes']['recoveryOptions']['mssqlRecoveryCopyInfo'] = {}
            data['data']['attributes']['recoveryOptions']['mssqlRecoveryCopyInfo']['fullRecoveryCollection'] = [{}]
            for copy in info[0]['copies']:
                if(copy['copyNumber'] == recover_from_copy):
                    copy['storage'].pop('sType',None)
                    data['data']['attributes']['recoveryOptions']['mssqlRecoveryCopyInfo']['fullRecoveryCollection'][0]['backupId'] = info[0]['backupId']
                    data['data']['attributes']['recoveryOptions']['mssqlRecoveryCopyInfo']['fullRecoveryCollection'][0]['storage'] = copy['storage']
    status_code, response_text = common.rest_request('POST', url, headers, data=data)
    common.validate_response(status_code, 201, response_text)
    recovery_job_id = response_text['data']['id']
    print(f"MSSQL Recovery Request started successfully jobid :[{recovery_job_id}]")
    return recovery_job_id

