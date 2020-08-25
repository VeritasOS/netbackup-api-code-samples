# Netbackup VmWare agentless single and group VM backup and restore APIs code samples

## Executing the scripts:

Pre-requisites:
- NetBackup 8.2.1(Build 209 or higher) or higher      
- Python 3.5 or higher
- Python modules: `requests`


Use the following commands to run the scripts.
- Single VM backup and restore

`python single_vm_backup_restore.py --master_server <master_server> --master_username <master_username> --master_password <master_password> --vcenter_name <vcenter_name> --vcenter_username <vcenter_username> --vcenter_password <vcenter_password> --protection_plan_name <protection_plan_name> --clientvm <client_vm_name> --restore_vmname <restore_vm_name>`

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
                                   [--protection_plan_name PROTECTION_PLAN_NAME]
                                   [--clientvm CLIENTVM]
                                   [--restore_vmname RESTORE_VMNAME]

Single VM backup and restore scenario

optional arguments:
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
                        Vcenter name
  --vcenter_username VCENTER_USERNAME
                        Vcenter username
  --vcenter_password VCENTER_PASSWORD
                        Vcenter password
  --vcenter_port VCENTER_PORT
                        Vcenter port
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

- Group VM backup and restore

`python group_vm_backup_restore.py --master_server <master_server> --master_username <master_username> --master_password <master_password> --vcenter_name <vcenter_name> --vcenter_username <vcenter_username> --vcenter_password <vcenter_password> --protection_plan_name <protection_plan_name> --querystring <Query_string> --vip_group_name <group_name> --restore_vmname_prefix <restore_vmname_prefix>`

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
                                  [--protection_plan_name PROTECTION_PLAN_NAME]
                                  [--querystring QUERYSTRING]
                                  [--vip_group_name VIP_GROUP_NAME]
                                  [--restore_vmname_prefix RESTORE_VMNAME_PREFIX]

Group VM backup and restore scenario

optional arguments:
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
