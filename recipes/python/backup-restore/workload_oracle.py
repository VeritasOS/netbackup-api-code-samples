"""
The library contain functions related to NetBackup Oracle workload
"""

## The script can be run with Python 3.6 or higher version.

import common
import json
import os

headers = {"Content-Type" : "application/vnd.netbackup+json;version=4.0"}

# Get oracle_asset info
def get_oracle_asset_info(baseurl, token, asset_type, display_name, database_id):
    """ This function return the asset info """
    print(f"Get client asset info for Oracle type :[asset_type]")
    headers.update({'Authorization': token})
    if (asset_type == "DATABASE"):
        url = f"{baseurl}asset-service/workloads/oracle/assets?"\
            f"filter=assetType eq '{asset_type}' and databaseUniqueName eq '{display_name}' and databaseId eq '{database_id}'"
    else:
        url = f"{baseurl}asset-service/workloads/oracle/assets?"\
            f"filter=assetType eq '{asset_type}' and displayName eq '{display_name}' and containerDatabaseId eq '{database_id}'"
    status_code, response_text = common.rest_request('GET', url, headers)
    common.validate_response(status_code, 200, response_text)

    asset_id = response_text['data'][0]['id']

    print(f"Client asset Id:[{asset_id}]")
    return asset_id

# Create cdb clone request payload
def create_cdb_clone_request_payload(oracle_recovery_input, rp_id, os_domain, os_username, os_password, alt_client_name, clone_db_file_path, oracle_home, oracle_base_config):
    """ This function return the cdb clone request payload """
    print(f"create oracle recovery request:[{oracle_recovery_input}]")
    
    cur_dir = os.path.dirname(os.path.abspath(__file__))
    cur_dir = cur_dir + os.sep + "sample-payloads" + os.sep
    file_name = os.path.join(cur_dir, oracle_recovery_input)
    with open(file_name, 'r') as file_handle:
        data = json.load(file_handle)
    data['data']['attributes']['recoveryPoint'] = rp_id
    data['data']['attributes']['recoveryObject']['instanceCredentials']['domain'] = os_domain
    data['data']['attributes']['recoveryObject']['instanceCredentials']['username'] = os_username
    data['data']['attributes']['recoveryObject']['instanceCredentials']['password'] = os_password
    data['data']['attributes']['recoveryObject']['instanceCredentials']['credentialType'] = 'CREDENTIAL_DETAILS'
    data['data']['attributes']['alternateRecoveryOptions']['client'] = alt_client_name
    data['data']['attributes']['alternateRecoveryOptions']['oracleSID'] = 'clonedinstance'
    data['data']['attributes']['alternateRecoveryOptions']['databaseName'] = 'CLONEDDB'
    data['data']['attributes']['alternateRecoveryOptions']['oracleHome'] = oracle_home
    data['data']['attributes']['alternateRecoveryOptions']['oracleBaseConfig'] = oracle_base_config
    data['data']['attributes']['alternateRecoveryOptions']['controlFilePaths']['renameAllFilesToSameLocation']['destination'] = clone_db_file_path
    data['data']['attributes']['alternateRecoveryOptions']['databaseFilePaths']['renameAllFilesToSameLocation']['destination'] = clone_db_file_path
    data['data']['attributes']['alternateRecoveryOptions']['tempFilePaths']['renameAllFilesToSameLocation']['destination'] = clone_db_file_path
    data['data']['attributes']['alternateRecoveryOptions']['redoFilePaths']['renameAllFilesToSameLocation']['destination'] = clone_db_file_path

    return data

# Create pdb clone request payload
def create_pdb_clone_request_payload(oracle_recovery_input, rp_id, credential_id, alt_client_name, clone_db_file_path, oracle_home, oracle_base_config, avail_oracle_sid, clone_aux_file_path):
    """ This function return the pdb clone request payload """
    print(f"create oracle recovery request:[{oracle_recovery_input}]")

    cur_dir = os.path.dirname(os.path.abspath(__file__))
    cur_dir = cur_dir + os.sep + "sample-payloads" + os.sep
    file_name = os.path.join(cur_dir, oracle_recovery_input)
    with open(file_name, 'r') as file_handle:
        data = json.load(file_handle)
    data['data']['attributes']['recoveryPoint'] = rp_id
    data['data']['attributes']['recoveryObject']['instanceCredentials']['credentialId'] = credential_id
    data['data']['attributes']['recoveryObject']['instanceCredentials']['credentialType'] = 'CREDENTIAL_ID'
    data['data']['attributes']['alternateRecoveryOptions']['client'] = alt_client_name
    data['data']['attributes']['alternateRecoveryOptions']['oracleSID'] = avail_oracle_sid
    data['data']['attributes']['alternateRecoveryOptions']['databaseName'] = 'CLONEPDB'
    data['data']['attributes']['alternateRecoveryOptions']['oracleHome'] = oracle_home
    data['data']['attributes']['alternateRecoveryOptions']['oracleBaseConfig'] = oracle_base_config
    data['data']['attributes']['alternateRecoveryOptions']['controlFilePaths']['renameAllFilesToSameLocation']['auxiliary'] = clone_aux_file_path
    data['data']['attributes']['alternateRecoveryOptions']['databaseFilePaths']['renameAllFilesToSameLocation']['auxiliary'] = clone_aux_file_path
    data['data']['attributes']['alternateRecoveryOptions']['databaseFilePaths']['renameAllFilesToSameLocation']['destination'] = clone_db_file_path
    data['data']['attributes']['alternateRecoveryOptions']['tempFilePaths']['renameAllFilesToSameLocation']['auxiliary'] = clone_aux_file_path
    data['data']['attributes']['alternateRecoveryOptions']['tempFilePaths']['renameAllFilesToSameLocation']['destination'] = clone_db_file_path
    data['data']['attributes']['alternateRecoveryOptions']['redoFilePaths']['renameAllFilesToSameLocation']['auxiliary'] = clone_aux_file_path

    return data

# Submit oracle recovery request
def create_oracle_recovery_request(baseurl, token, data):
    """ This function submits a clone request """
    headers.update({'Authorization': token})

    status_code, response_text = common.rest_request('POST', baseurl, headers, data=data)
    
    return status_code, response_text
