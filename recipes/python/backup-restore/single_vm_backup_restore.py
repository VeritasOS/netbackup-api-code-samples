""" This script execute the single VM backup and restore scenario. """

## The script can be run with Python 3.6 or higher version.

## The script requires 'requests' library to make the API calls.
## The library can be installed using the command: pip install requests.

import argparse
import common
import vm_backup
import vm_restore

PARSER = argparse.ArgumentParser(description="Single VM backup and restore scenario")
PARSER.add_argument("--master_server", type=str, help="NetBackup master server name")
PARSER.add_argument("--master_server_port", type=int, help="NetBackup master server port", required=False)
PARSER.add_argument("--master_username", type=str, help="NetBackup master server username")
PARSER.add_argument("--master_password", type=str, help="NetBackup master server password")
PARSER.add_argument("--vcenter_name", type=str, help="Vcenter name")
PARSER.add_argument("--vcenter_username", type=str, help="Vcenter username")
PARSER.add_argument("--vcenter_password", type=str, help="Vcenter password")
PARSER.add_argument("--vcenter_port", type=str, help="Vcenter port", required=False)
PARSER.add_argument("--protection_plan_name", type=str, help="Protection plan name")
PARSER.add_argument("--clientvm", type=str, help="Client VM name")
PARSER.add_argument("--restore_vmname", type=str, help="Restore VM name")

ARGS = PARSER.parse_args()

if __name__ == '__main__':
    WORKLOAD_TYPE = 'vmware'
    SERVER_TYPE = 'VMWARE_VIRTUAL_CENTER_SERVER'
    PROTECTION_PLAN_ID = ''
    SUBSCRIPTION_ID = ''
    MOUNT_ID = ''

    BASEURL = common.get_nbu_base_url(ARGS.master_server, ARGS.master_server_port)
    TOKEN = common.get_authenticate_token(BASEURL, ARGS.master_username, ARGS.master_password)
    print(f"User authentication completed for master server:[{ARGS.master_server}]")

    try:
        print(f"Setup the VMware environment for vCenter:[{ARGS.vcenter_name}]")
        common.add_vcenter_credential(BASEURL, TOKEN, ARGS.vcenter_name, ARGS.vcenter_username, ARGS.vcenter_password, ARGS.vcenter_port, SERVER_TYPE)
        common.verify_vmware_discovery_status(BASEURL, TOKEN, WORKLOAD_TYPE, ARGS.vcenter_name)
        STORAGE_UNIT_NAME = common.get_storage_units(BASEURL, TOKEN)
        ASSET_ID, _, EXSI_HOST = common.get_asset_info(BASEURL, TOKEN, WORKLOAD_TYPE, ARGS.clientvm)
        PROTECTION_PLAN_ID = common.create_protection_plan(BASEURL, TOKEN, ARGS.protection_plan_name, STORAGE_UNIT_NAME)
        SUBSCRIPTION_ID = common.subscription_asset_to_slo(BASEURL, TOKEN, PROTECTION_PLAN_ID, ASSET_ID)

        # Single VM backup and restore
        print("Start single VM backup")
        BACKUP_JOB_ID = vm_backup.perform_vm_backup(BASEURL, TOKEN, PROTECTION_PLAN_ID, ASSET_ID)
        common.verify_job_state(BASEURL, TOKEN, BACKUP_JOB_ID, 'DONE', timeout=300)
        PROTECTION_BACKUP_JOB_ID, CATALOG_BACKUP_JOB_ID = vm_backup.get_backup_job_id(BASEURL, TOKEN, BACKUP_JOB_ID, ARGS.protection_plan_name)
        common.verify_job_state(BASEURL, TOKEN, PROTECTION_BACKUP_JOB_ID, 'DONE')
        common.verify_job_state(BASEURL, TOKEN, CATALOG_BACKUP_JOB_ID, 'DONE')

        print(f"Perform instant access vm:[{ARGS.restore_vmname}]")
        BACKUP_ID = vm_restore.get_recovery_points(BASEURL, TOKEN, WORKLOAD_TYPE, ASSET_ID)
        RESOURCE_POOL = vm_restore.get_resource_pool(BASEURL, TOKEN, WORKLOAD_TYPE, ARGS.vcenter_name, EXSI_HOST)
        MOUNT_ID = vm_restore.create_instant_access_vm(BASEURL, TOKEN, WORKLOAD_TYPE, BACKUP_ID, ARGS.vcenter_name, EXSI_HOST, RESOURCE_POOL, ARGS.restore_vmname)
        vm_restore.verify_instant_access_vmstate(BASEURL, TOKEN, WORKLOAD_TYPE, BACKUP_ID, MOUNT_ID)

    finally:
        print("Start cleanup")
        # Cleanup the created protection plan
        vm_restore.remove_instantaccess_vm(BASEURL, TOKEN, MOUNT_ID)
        common.remove_subscription(BASEURL, TOKEN, PROTECTION_PLAN_ID, SUBSCRIPTION_ID)
        common.remove_protectionplan(BASEURL, TOKEN, PROTECTION_PLAN_ID)
        common.remove_vcenter_creds(BASEURL, TOKEN, ARGS.vcenter_name)
