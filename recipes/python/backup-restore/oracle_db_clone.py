""" This script execute the Oracle Database backup and clone scenario. """

## The script can be run with Python 3.6 or higher version.

## The script requires 'requests' library to make the API calls.
## The library can be installed using the command: pip install requests.

import argparse
import common
import workload_oracle

PARSER = argparse.ArgumentParser(description="Oracle Database clone scenario")
PARSER.add_argument("--primary_server", type=str, help="NetBackup primary server name")
PARSER.add_argument("--primary_server_port", type=int, help="NetBackup primary server port", required=False)
PARSER.add_argument("--primary_username", type=str, help="NetBackup primary server username")
PARSER.add_argument("--primary_password", type=str, help="NetBackup primary server password")
PARSER.add_argument("--source_oracle_db", type=str, help="Source client oracle database unique or pluggable database display name")
PARSER.add_argument("--source_database_id", type=str, help="Source client oracle container database id")
PARSER.add_argument("--target_oracle_server", type=str, help="Target client name")
PARSER.add_argument("--os_oracle_domain", type=str, help="Target oracle server domain")
PARSER.add_argument("--os_oracle_username", type=str, help="Target oracle username")
PARSER.add_argument("--os_oracle_password", type=str, help="Target oracle user password")
PARSER.add_argument("--clone_db_file_path", type=str, help="Clone database path", required=True)
PARSER.add_argument("--oracle_home", type=str, help="Oracle home", required=True)
PARSER.add_argument("--oracle_base_config", type=str, help="Oracle base config", required=True)
PARSER.add_argument("--pdb_clone", type=int, help="Complete CDB clone (0) or a PDB clone(1)", default=0)
PARSER.add_argument("--avail_oracle_sid", type=str, help="Target existing container for pdb clone")
PARSER.add_argument("--clone_aux_file_path", type=str, help="Auxiliary file paths")
PARSER.add_argument("--credential_id", type=str, help="Credential Id", required=False)
PARSER.add_argument("--force_clone", type=int, help="Force a clone request", default=0)

ARGS = PARSER.parse_args()

if __name__ == '__main__':
    WORKLOAD_TYPE = 'oracle'
    ASSET_TYPE = "PDB" if (ARGS.pdb_clone) else "DATABASE"

    BASEURL = common.get_nbu_base_url(ARGS.primary_server, ARGS.primary_server_port)
    TOKEN = common.get_authenticate_token(BASEURL, ARGS.primary_username, ARGS.primary_password)
    print(f"User authentication completed for primary server:[{ARGS.primary_server}]")

    try:
        # run asset-service to get the asset id
        RECOVERY_ASSET_ID = workload_oracle.get_oracle_asset_info(BASEURL, TOKEN, ASSET_TYPE, ARGS.source_oracle_db, ARGS.source_database_id)
        print(f"Oracle Asset Id:[{RECOVERY_ASSET_ID}]")
        # run recovery-point-service to get recovery-point-id
        RECOVERY_POINT_ID = common.get_recovery_points(BASEURL, TOKEN, WORKLOAD_TYPE, RECOVERY_ASSET_ID)
        print(f"Oracle Recovery Point Id:[{RECOVERY_POINT_ID}]")

        if (ARGS.pdb_clone):
            preCheckURL = f"{BASEURL}recovery/workloads/oracle/scenarios/pdb-complete-clone/pre-recovery-check"
            cloneURL = f"{BASEURL}recovery/workloads/oracle/scenarios/pdb-complete-clone/recover"
            recovery_input_json = "post_oracle_pdb_clone.json"
            data = workload_oracle.create_pdb_clone_request_payload(recovery_input_json, RECOVERY_POINT_ID, ARGS.credential_id, ARGS.target_oracle_server,
                ARGS.clone_db_file_path, ARGS.oracle_home, ARGS.oracle_base_config, ARGS.avail_oracle_sid, ARGS.clone_aux_file_path)
        else:
            preCheckURL = f"{BASEURL}recovery/workloads/oracle/scenarios/database-complete-clone/pre-recovery-check"
            cloneURL = f"{BASEURL}recovery/workloads/oracle/scenarios/database-complete-clone/recover"
            recovery_input_json = "post_oracle_cdb_clone.json"
            data = workload_oracle.create_cdb_clone_request_payload(recovery_input_json, RECOVERY_POINT_ID, ARGS.os_oracle_domain, ARGS.os_oracle_username,
                ARGS.os_oracle_password, ARGS.target_oracle_server, ARGS.clone_db_file_path, ARGS.oracle_home, ARGS.oracle_base_config)
        
        # run a pre-recovery-check
        print("Perform a pre-recovery-check")
        status_code, response_text = workload_oracle.create_oracle_recovery_request(preCheckURL, TOKEN, data)

        common.validate_response(status_code, 200, response_text)
        print(f"Pre-recovery-check response :{response_text['data']}")
        preCheckFail = 0
        for _result in response_text['data']:
            if (_result['attributes']['result'] != 'Passed'):
                print(f"FAIL REASON: {_result['attributes']['description']}")
                preCheckFail += 1

        if ((not preCheckFail) or (ARGS.force_clone)):
            # run a clone
            print("Perform a database clone")

            status_code, response_text = workload_oracle.create_oracle_recovery_request(cloneURL, TOKEN, data)
            
            common.validate_response(status_code, 201, response_text)
            CLONE_JOBID = response_text['data']['id']
            print(f"Clone initiated , follow Job # :[{CLONE_JOBID}]")
        else:
            print("Pre-recovery check failed. Force kick off clone using --force_clone")
    
    finally:
        print("To cleanup the cloned instance, run dbca. Add the instance to /etc/oratab to be discovered by oracle for cleanup.")
