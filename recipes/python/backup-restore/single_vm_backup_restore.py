## This script execute the single VM backup and restore scenario.

## The script can be run with Python 3.6 or higher version.

## The script requires 'requests' library to make the API calls. The library can be installed using the command: pip install requests.

import argparse
import common as common
import backup as backup
import restore as restore

parser = argparse.ArgumentParser(description="Single VM backup and restore scenario")
parser.add_argument("--master_server", type=str, help="NetBackup master server name")
parser.add_argument("--master_server_port", type=int, help="NetBackup master server port", required=False)
parser.add_argument("--master_username", type=str, help="NetBackup master server user name")
parser.add_argument("--master_password", type=str, help="NetBackup master server password")
parser.add_argument("--vcenter_name", type=str, help="Vcenter name")
parser.add_argument("--vcenter_username", type=str, help="Vcenter username")
parser.add_argument("--vcenter_password", type=str, help="Vcenter password")
parser.add_argument("--vcenter_port", type=str, help="Vcenter port", required=False)
parser.add_argument("--protection_plan_name", type=str, help="Protection plan name")
parser.add_argument("--clientvm", type=str, help="Client VM name")
parser.add_argument("--restore_vmname", type=str, help="Restore VM name")

args = parser.parse_args()

if __name__ == '__main__':
    workload_type = 'vmware'
    server_type = 'VMWARE_VIRTUAL_CENTER_SERVER'   
    headers = {"Content-Type" : "application/vnd.netbackup+json;version=4.0"}
    protection_plan_id = ''
    subscription_id = ''
    mount_id = ''

    baseurl = common.get_nbu_base_url(args.master_server, args.master_server_port)
    token = common.get_authenticate_token(baseurl, args.master_username, args.master_password)
    headers['Authorization'] = token
    print(f"User authentication completed for master server:[{args.master_server}]")

    try:
        print(f"Setup the VMware environment for vcenter:[{args.vcenter_name}]")
        common.add_vcenter_credential(baseurl, token, args.vcenter_name, args.vcenter_username, args.vcenter_password, args.vcenter_port, server_type)
        common.verify_vmware_discovery_status(baseurl, token, workload_type, args.vcenter_name)
        storage_unit_name = common.get_storage_units(baseurl, token)
        asset_id, instance_uuid, exsi_host = common.get_asset_info(baseurl, token, workload_type, args.clientvm)
        protection_plan_id = common.create_protection_plan(baseurl, token, args.protection_plan_name, storage_unit_name)
        subscription_id = common.subscription_asset_to_slo(baseurl, token, protection_plan_id, asset_id)

        # Single VM backup and restore
        print("Start backup")
        backup_job_id = backup.perform_backup(baseurl, token, protection_plan_id, asset_id)
        common.verify_job_state(baseurl, token, backup_job_id, 'DONE')
        protection_backup_job_id, catalog_backup_job_id = backup.get_backup_job_id(baseurl, token, backup_job_id, args.protection_plan_name)
        common.verify_job_state(baseurl, token, protection_backup_job_id, 'DONE')
        common.verify_job_state(baseurl, token, catalog_backup_job_id, 'DONE')

        print("Perform instant access vm:[{args.restore_vmname}]")
        backup_id = restore.get_recovery_points(baseurl, token, workload_type, asset_id)
        resource_pool = restore.get_resource_pool(baseurl, token, workload_type, args.vcenter_name, exsi_host)
        mount_id = restore.create_instant_access_vm(baseurl, token, workload_type, backup_id, args.vcenter_name, exsi_host, resource_pool, args.restore_vmname)
        restore.verify_instant_access_vmstate(baseurl, token, workload_type, backup_id, mount_id)

    finally:
        print("Start cleanup")
        # Cleanup the created protection plan
        restore.remove_instantaccess_vm(baseurl, token, mount_id)
        common.remove_subscription(baseurl, token, protection_plan_id, subscription_id)
        common.remove_protectionplan(baseurl, token, protection_plan_id)
        common.remove_vcenter_creds(baseurl, token, args.vcenter_name)
