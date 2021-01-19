# NetBackup backup and restore APIs code samples of VMware agentless single, group VM and Microsoft SQL Server 

## Executing the scripts:

Pre-requisites:
- NetBackup 8.3 or higher
- Python 3.6 or higher
- Python modules: `requests`
- create_protection_plan_template.json template file. This template contain the required payload which is used to create the protection plan.

Use the following commands to run the scripts.
### - Single VM backup and restore

This single_vm_backup_restore.py script demonstrates how to backup a VM (VMware virtual machine) using a protection plan and instant access restore of VM using NetBackup APIs.

`python single_vm_backup_restore.py --master_server <master_server> --master_username <master_username> --master_password <master_password> --vcenter_name <vcenter_name> --vcenter_username <vcenter_username> --vcenter_password <vcenter_password> --stu_name <stu_name> --protection_plan_name <protection_plan_name> --clientvm <client_vm_name> --restore_vmname <restore_vm_name>`

All parameters can also be passed as command line arguments.
- `python single_vm_backup_restore.py --help`
```
usage: single_vm_backup_restore.py [-h] [--master_server MASTER_SERVER]
                                   [--master_server_port MASTER_SERVER_PORT]
                                   [--master_username MASTER_USERNAME]
                                   [--master_password MASTER_PASSWORD]
                                   [--vcenter_name VCENTER_NAME]
                                   [--vcenter_username VCENTER_USERNAME]
                                   [--vcenter_password VCENTER_PASSWORD]
                                   [--vcenter_port VCENTER_PORT]
                                   [--stu_name STU_NAME]
                                   [--protection_plan_name PROTECTION_PLAN_NAME]
                                   [--clientvm CLIENTVM]
                                   [--restore_vmname RESTORE_VMNAME]

Single VM backup and restore scenario

Arguments:
  -h, --help            show this help message and exit
  --master_server MASTER_SERVER
                        NetBackup master server name
  --master_server_port MASTER_SERVER_PORT
                        NetBackup master server port
  --master_username MASTER_USERNAME
                        NetBackup master server username
  --master_password MASTER_PASSWORD
                        NetBackup master server password
  --vcenter_name VCENTER_NAME
                        vCenter name
  --vcenter_username VCENTER_USERNAME
                        vCenter username
  --vcenter_password VCENTER_PASSWORD
                        vCenter password
  --vcenter_port VCENTER_PORT
                        vCenter port
  --stu_name STU_NAME
                        Storage unit name
  --protection_plan_name PROTECTION_PLAN_NAME
                        Protection plan name
  --clientvm CLIENTVM   Client VM name
  --restore_vmname RESTORE_VMNAME
                        Restore VM name
```

Execution flow of single VM backup and restore script:
- Add vcenter to NBU master
- Discovery of Vcenter
- Create protection plan
- Subscribe asset to protection plan
- Perform immediate backup
- Verify the status of jobs
- Initiate instant access recovery
- Verify state of instant access recovery VM.
- Perform the cleanup(e.g. remove instant access VM, subscription, protection plan and vcenter)

### - Group VM backup and restore

This group_vm_backup_restore.py script demonstrates how to backup multiple VMs (VMware virtual machines) using a protection plan and perform bulk instant access restore of the VMs using NetBackup APIs.

`python group_vm_backup_restore.py --master_server <master_server> --master_username <master_username> --master_password <master_password> --vcenter_name <vcenter_name> --vcenter_username <vcenter_username> --vcenter_password <vcenter_password> --stu_name <stu_name> --protection_plan_name <protection_plan_name> --querystring <Query_string> --vip_group_name <group_name> --restore_vmname_prefix <restore_vmname_prefix>`

All parameters can also be passed as command line arguments.
- `python group_vm_backup_restore.py --help`
```
usage: group_vm_backup_restore.py [-h] [--master_server MASTER_SERVER]
                                  [--master_server_port MASTER_SERVER_PORT]
                                  [--master_username MASTER_USERNAME]
                                  [--master_password MASTER_PASSWORD]
                                  [--vcenter_name VCENTER_NAME]
                                  [--vcenter_username VCENTER_USERNAME]
                                  [--vcenter_password VCENTER_PASSWORD]
                                  [--vcenter_port VCENTER_PORT]
                                  [--stu_name STU_NAME]
                                  [--protection_plan_name PROTECTION_PLAN_NAME]
                                  [--querystring QUERYSTRING]
                                  [--vip_group_name VIP_GROUP_NAME]
                                  [--restore_vmname_prefix RESTORE_VMNAME_PREFIX]

Group VM backup and restore scenario

Arguments:
  -h, --help            show this help message and exit
  --master_server MASTER_SERVER
                        NetBackup master server
  --master_server_port MASTER_SERVER_PORT
                        NetBackup port
  --master_username MASTER_USERNAME
                        NetBackup master server user name
  --master_password MASTER_PASSWORD
                        NetBackup master server password
  --vcenter_name VCENTER_NAME
                        Vcenter name
  --vcenter_username VCENTER_USERNAME
                        Vcenter username
  --vcenter_password VCENTER_PASSWORD
                        Vcenter password
  --vcenter_port VCENTER_PORT
                        Vcenter port
  --stu_name STU_NAME
                        Storage unit name
  --protection_plan_name PROTECTION_PLAN_NAME
                        Protection plan name
  --querystring QUERYSTRING
                        Query string to create the VM intelligent group
  --vip_group_name VIP_GROUP_NAME
                        VM intelligent group name
  --restore_vmname_prefix RESTORE_VMNAME_PREFIX
                        Restore VM name prefix
```
Execution flow of group VM backup and restore script:
- Add vcenter to NBU master
- Discovery of Vcenter
- Create protection plan
- Create intelligent VM group based on the querystring
- Subscribe VM group to protection plan
- Perform immediate backup
- Verify the status of jobs
- Perform bulk restore
- Perform the cleanup(e.g. remove bulk instant access VMs, subscription, protection plan, VM group and vcenter)

### - Microsoft SQL Server Protection and Recovery workflow

This mssql_db_backup_restore.py script demonstrates how to Protect a MSSQL Database or Instance using a protection plan, and perform a alternate recovery of a single database or all user databases using NetBackup APIs.

`python -W ignore recipes/python/backup-restore/mssql_db_backup_restore.py --master_server <master_server> --master_server_port 1556 --master_username <master_username> --master_password <master_password> --mssql_instance <mssql_instance_name> --mssql_database <mssql_database_name> --mssql_server_name <mssql_server_name> --mssql_use_localcreds 0 --mssql_domain <mssql_domain> --mssql_username <mssql_sysadmin_user> --mssql_password <mssql_sysadmin_pwd> --stu_name <storage_unit_used_in_protection_plan> --protection_plan_name <protection_plan_name> --asset_type <mssql_asset_type> --restore_db_prefix <mssql_restore_database_name_prefix> --restore_db_path <mssql_restore_database_path> --recover_all_user_dbs <0|1> --recover_from_copy <1|2> --copy_stu_name <storage_unit_used_for_copy>`

All parameters can also be passed as command line arguments.
- `python mssql_db_backup_restore.py -h`
```
usage: mssql_db_backup_restore.py [-h] [--master_server MASTER_SERVER]
                                  [--master_server_port MASTER_SERVER_PORT]
                                  [--master_username MASTER_USERNAME]
                                  [--master_password MASTER_PASSWORD]
                                  [--mssql_instance MSSQL_INSTANCE]
                                  [--mssql_database MSSQL_DATABASE]
                                  [--mssql_server_name MSSQL_SERVER_NAME]
                                  [--mssql_use_localcreds MSSQL_USE_LOCALCREDS]
                                  [--mssql_domain MSSQL_DOMAIN]
                                  [--mssql_username MSSQL_USERNAME]
                                  [--mssql_password MSSQL_PASSWORD]
                                  [--stu_name STU_NAME]
                                  [--protection_plan_name PROTECTION_PLAN_NAME]
                                  [--asset_type ASSET_TYPE]
                                  [--restore_db_prefix RESTORE_DB_PREFIX]
                                  [--restore_db_path RESTORE_DB_PATH]
                                  [--recover_all_user_dbs RECOVER_ALL_USER_DBS]
                                  [--recover_from_copy RECOVER_FROM_COPY]
                                  [--copy_stu_name COPY_STU_NAME]
Mssql backup and alternate database recovery scenario

Arguments:
  -h, --help            show this help message and exit
  --master_server MASTER_SERVER
                        NetBackup master server name
  --master_server_port MASTER_SERVER_PORT
                        NetBackup master server port
  --master_username MASTER_USERNAME
                        NetBackup master server username
  --master_password MASTER_PASSWORD
                        NetBackup master server password
  --mssql_instance MSSQL_INSTANCE
                        MSSQL Instance name
  --mssql_database MSSQL_DATABASE
                        MSSQL Database name
  --mssql_server_name MSSQL_SERVER_NAME
                        MSSQL server name, this is used in the filter for GET assets API.
  --mssql_use_localcreds MSSQL_USE_LOCALCREDS
                        MSSQL server use locally defined creds
  --mssql_domain MSSQL_DOMAIN
                        MSSQL server domain
  --mssql_username MSSQL_USERNAME
                        MSSQL sysadmin username
  --mssql_password MSSQL_PASSWORD
                        MSSQL sysadmin user password
  --stu_name STU_NAME   Storage Unit name
  --protection_plan_name PROTECTION_PLAN_NAME
                        Protection plan name
  --asset_type ASSET_TYPE
                        MSSQL asset type (AvailabilityGroup, Instance, Database)
  --restore_db_prefix RESTORE_DB_PREFIX
                        Restore database name prefix
  --restore_db_path RESTORE_DB_PATH
                        Restore database path
  --recover_all_user_dbs recover_all_user_dbs
                        Recover all User databases to the mssql_instance specfied with a database name prefix
  --recover_from_copy RECOVER_FROM_COPY
                        Create a policy with a copy and then recover using the specified copy of the backup
  --copy_stu_name COPY_STU_NAME
                        Storage Unit name for the copy

Execution flow of a Single MSSQL database protection and alternate database recovery workflow:
- Login to Master Server get authorization token for API use
- Add Credential with Credential Management API
- Create a MSSQL Instance Asset and associate Credential 
- Asset API to find the MSSQL Instance asset id for subscription in a Protection Plan
- Create MSSQL Protection Plan and configure MSSQL database policy attribute to SkipOffline databases
- Subscribe the MSSQL Instance Assset in Protection Plan
- Fetch Asset id for database for alternate recovery
- Get recoverypoint for the database asset using its asset id
- Perform alternate database recovery of the database and report recovery job id or Perfrom alternate recovery of all user databases, if recover_alluserdbs is specified.
- Cleanup by removing subscription of Instance in Protection Plan, Remove Protection Plan and remove Mssql Credential

