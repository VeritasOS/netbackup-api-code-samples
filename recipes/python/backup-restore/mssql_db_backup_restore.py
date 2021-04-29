""" This script execute the MSSQL Instance backup and database restore scenario. """

## The script can be run with Python 3.6 or higher version.

## The script requires 'requests' library to make the API calls.
## The library can be installed using the command: pip install requests.

import argparse
import common
import time
import workload_mssql

PARSER = argparse.ArgumentParser(description="MSSQL Instance backup and Database restore scenario")
PARSER.add_argument("--master_server", type=str, help="NetBackup master server name")
PARSER.add_argument("--master_server_port", type=int, help="NetBackup master server port", required=False)
PARSER.add_argument("--master_username", type=str, help="NetBackup master server username")
PARSER.add_argument("--master_password", type=str, help="NetBackup master server password")
PARSER.add_argument("--mssql_instance", type=str, help="MSSQL Instance name")
PARSER.add_argument("--mssql_database", type=str, help="MSSQL Database name")
PARSER.add_argument("--mssql_server_name", type=str, help="MSSQL server name")
PARSER.add_argument("--mssql_use_localcreds", type=int, help="MSSQL server use locally defined creds", default=0)
PARSER.add_argument("--mssql_domain", type=str, help="MSSQL server domain")
PARSER.add_argument("--mssql_username", type=str, help="MSSQL sysadmin username")
PARSER.add_argument("--mssql_password", type=str, help="MSSQL sysadmin user password")
PARSER.add_argument("--stu_name", type=str, help="Storage Unit name")
PARSER.add_argument("--protection_plan_name", type=str, help="Protection plan name")
PARSER.add_argument("--asset_type", type=str, help="MSSQL asset type (AvailabilityGroup, Instance, Database)", required=False)
PARSER.add_argument("--restore_db_prefix", type=str, help="Restore database name prefix", required=True)
PARSER.add_argument("--restore_db_path", type=str, help="Restore database path", required=True)
PARSER.add_argument("--recover_all_user_dbs", type=int, help="Recover all user databases", required=False, default=0)
PARSER.add_argument("--recover_from_copy", type=int, help="Recover from the copy number specified", choices=[1,2])
PARSER.add_argument("--copy_stu_name", type=str, help="Storage Unit name for copies", required=False)

ARGS = PARSER.parse_args()

if __name__ == '__main__':
    WORKLOAD_TYPE = 'mssql'
    PROTECTION_PLAN_ID = ''
    SUBSCRIPTION_ID = ''
    ASSET_TYPE = ARGS.asset_type if ARGS.asset_type else 'instance'
    ALT_DB = ARGS.restore_db_prefix

    BASEURL = common.get_nbu_base_url(ARGS.master_server, ARGS.master_server_port)
    TOKEN = common.get_authenticate_token(BASEURL, ARGS.master_username, ARGS.master_password)
    INSTANCE_NAME = ARGS.mssql_instance
    DATABASE_NAME = ARGS.mssql_database
    ALT_DB_PATH = ARGS.restore_db_path
    ALLDATABASES=[]
    print(f"User authentication completed for master server:[{ARGS.master_server}]")

    try:
        print(f"Setup the environment for Mssql Server:[{ARGS.mssql_server_name}]")
        print(f"Setup the environment for Mssql Server:[{INSTANCE_NAME}]")
        CREDENTIAL_ID, CREDENTIAL_NAME = workload_mssql.add_mssql_credential(BASEURL, TOKEN, ARGS.mssql_use_localcreds, ARGS.mssql_domain, ARGS.mssql_username, ARGS.mssql_password)
        INSTANCE_ID = workload_mssql.get_mssql_asset_info(BASEURL, TOKEN, "instance", ARGS.mssql_server_name, INSTANCE_NAME)
        if (INSTANCE_ID != ""):
            print(f"Instance [{INSTANCE_ID}] already exists, updating credentials")
            workload_mssql.update_mssql_instance_credentials(BASEURL, TOKEN, INSTANCE_ID, CREDENTIAL_NAME)
        else:
            print(f"Instance Asset not present, create and register it ")
            workload_mssql.create_and_register_mssql_instance(BASEURL, TOKEN, INSTANCE_NAME, ARGS.mssql_server_name, CREDENTIAL_NAME);

        # you can change the subscription to a specific Instance, AvailabilityGroup or database
        SUBSCRIPTION_ASSET_ID = workload_mssql.get_mssql_asset_info(BASEURL, TOKEN, ASSET_TYPE, ARGS.mssql_server_name, INSTANCE_NAME)
        print(f"Asset Subscribed for protection:[{SUBSCRIPTION_ASSET_ID}]")
        # find the instance assetid and start a deepdiscovery on it for databases
        INSTANCE_ID = workload_mssql.get_mssql_asset_info(BASEURL, TOKEN, "instance", ARGS.mssql_server_name, INSTANCE_NAME)

        print(f"Start Discovery on the instance [{INSTANCE_NAME}] on the host [{ARGS.mssql_server_name}]")
        workload_mssql.mssql_instance_deepdiscovery(BASEURL, TOKEN, INSTANCE_ID)
        if(ARGS.recover_from_copy):
            workload_mssql.create_netbackup_policy(BASEURL, TOKEN, ARGS.protection_plan_name, ARGS.mssql_server_name, ARGS.stu_name, ARGS.copy_stu_name)
            BACKUP_JOB_ID = common.run_netbackup_policy(BASEURL, TOKEN, ARGS.protection_plan_name)

        else:
            # create protection plan and subscribe the assettype to it
            PROTECTION_PLAN_ID = workload_mssql.create_mssql_protection_plan(BASEURL, TOKEN, ARGS.protection_plan_name, ARGS.stu_name, "SQL_SERVER")
            # update protection plan to set MSSQL policy settings to skip offline databases
            workload_mssql.update_protection_plan_mssql_attr(BASEURL, TOKEN, ARGS.protection_plan_name, PROTECTION_PLAN_ID, skip_offline_db=1)
            SUBSCRIPTION_ID = common.subscription_asset_to_slo(BASEURL, TOKEN, PROTECTION_PLAN_ID, SUBSCRIPTION_ASSET_ID)

            # MSSQL backup restore
            print("Start MSSQL backup")
            BACKUP_JOB_ID = common.protection_plan_backupnow(BASEURL, TOKEN, PROTECTION_PLAN_ID, SUBSCRIPTION_ASSET_ID)
        #timeout is set at 300 seconds (5 mins to keep looking if the backups are complete)
        common.verify_job_state(BASEURL, TOKEN, BACKUP_JOB_ID, 'DONE', timeout=300)

        # give nbwebservice 30 seconds to service any queued tasks, before launching recoveries
        time.sleep(30)
        if (ARGS.recover_all_user_dbs != 1):
            # fetch the asset
            RECOVERY_ASSET_ID = workload_mssql.get_mssql_asset_info(BASEURL, TOKEN, "database", ARGS.mssql_server_name, DATABASE_NAME, INSTANCE_NAME)
            RECOVERY_POINT = common.get_recovery_points(BASEURL, TOKEN, WORKLOAD_TYPE, RECOVERY_ASSET_ID)
            print(f"Perform Mssql single database [{DATABASE_NAME}] alternate recovery:[{ARGS.mssql_server_name}]")
            ALT_DB = ALT_DB + DATABASE_NAME
            RECOVERY_JOB_ID = workload_mssql.create_mssql_recovery_request(BASEURL, TOKEN, "post_mssql_singledb_alt_recovery.json", RECOVERY_POINT, RECOVERY_ASSET_ID, ARGS.mssql_username, ARGS.mssql_domain, ARGS.mssql_password, ALT_DB, ALT_DB_PATH, INSTANCE_NAME, ARGS.mssql_server_name, ARGS.recover_from_copy)
            print(f"Recovery initiated , follow Job #: [{RECOVERY_JOB_ID}]")
        else:
            print(f"Perform alternate recovery of all databases")
            #get all databases and its recovery points
            ALLDATABASES = workload_mssql.get_mssql_alldbs(BASEURL, TOKEN, ARGS.mssql_server_name, INSTANCE_NAME)
            print(f"Total Databases found [{len(ALLDATABASES)}]")
            systemdbs_set = set(['master', 'model', 'msdb'])
            for elem in ALLDATABASES:
                DATABASE_NAME = elem.databasename
                RECOVERY_ASSET_ID = elem.assetid
                if (DATABASE_NAME in systemdbs_set):
                    print(f"Skipping recovery of system database [{DATABASE_NAME}]")
                else:
                    RECOVERY_POINT = common.get_recovery_points(BASEURL, TOKEN, WORKLOAD_TYPE, RECOVERY_ASSET_ID)
                    if (RECOVERY_POINT != ""):
                        print(f"Perform Mssql database [{DATABASE_NAME}] alternate recovery:[{ARGS.mssql_server_name}]")
                        ALT_DB = ARGS.restore_db_prefix + DATABASE_NAME
                        RECOVERY_JOB_ID = workload_mssql.create_mssql_recovery_request(BASEURL, TOKEN, "post_mssql_singledb_alt_recovery.json", RECOVERY_POINT, RECOVERY_ASSET_ID, ARGS.mssql_username, ARGS.mssql_domain, ARGS.mssql_password, ALT_DB, ALT_DB_PATH, INSTANCE_NAME, ARGS.mssql_server_name, ARGS.recover_from_copy)
                    else:
                        print(f"Skipping recovery, could not find RecoveryPoint for [{DATABASE_NAME}] assetid [{RECOVERY_ASSET_ID}]")

    finally:
        print("Start cleanup")
        if(ARGS.recover_from_copy):
            # Cleanup the created policy
            common.delete_netbackup_policy(BASEURL, TOKEN, ARGS.protection_plan_name)
        else:
            # Cleanup the created protection plan
            common.remove_subscription(BASEURL, TOKEN, PROTECTION_PLAN_ID, SUBSCRIPTION_ID)
            common.remove_protectionplan(BASEURL, TOKEN, PROTECTION_PLAN_ID)
        workload_mssql.remove_mssql_credential(BASEURL, TOKEN, CREDENTIAL_ID)
