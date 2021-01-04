### NetBackup API Code Samples for PowerShell

This directory contains code samples to invoke NetBackup REST APIs using PowerShell.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Pre-requisites:

- NetBackup 8.2 or higher
- PowerShell 5.0 or higher

#### Executing the snippets in PowerShell

Use the following commands to run the PowerShell samples.
- `.\Post-NB-create-msdp-storage-unit.ps1 -nbmaster <masterServer> -username <username> -password <password>`
- `.\Post-NB-create-msdp-storage-server.ps1 -nbmaster <masterServer> -username <username> -password <password>`
- `.\Post-NB-create-msdp-disk-pool.ps1 -nbmaster <masterServer> -username <username> -password <password>`
- `.\Post-NB-create-cloud-storage-unit.ps1 -nbmaster <masterServer> -username <username> -password <password>`
- `.\Post-NB-create-cloud-storage-server.ps1 -nbmaster <masterServer> -username <username> -password <password>`
- `.\Post-NB-create-cloud-disk-pool.ps1 -nbmaster <masterServer> -username <username> -password <password>`
- `.\Post-NB-create-ad-storage-unit.ps1 -nbmaster <masterServer> -username <username> -password <password>`
- `.\Post-NB-create-ad-storage-server.ps1 -nbmaster <masterServer> -username <username> -password <password>`
- `.\Post-NB-create-ad-disk-pool.ps1 -nbmaster <masterServer> -username <username> -password <password>`
- `.\Get-NB-get-storage-server-by-id.ps1 -nbmaster <masterServer> -username <username> -password <password> -stsid <storage server id>`
- `.\Get-NB-get-storage-server.ps1 -nbmaster <masterServer> -username <username> -password <password>`
- `.\Get-NB-get-storage-unit.ps1 -nbmaster <masterServer> -username <username> -password <password>`
- `.\Get-NB-get-disk-pool-by-id.ps1 -nbmaster <masterServer> -username <username> -password <password> -dpid <disk pool id>`
- `.\Get-NB-get-storage-unit-by-id.ps1 -nbmaster <masterServer> -username <username> -password <password> -stu_name <storage unit name>`
- `.\Get-NB-get-disk-pool.ps1 -nbmaster <masterServer> -username <username> -password <password>`
- `.\Patch-NB-update-storage-unit.ps1 -nbmaster <masterServer> -username <username> -password <password> -stu_name <storage unit name>`
- `.\Patch-NB-update-msdp-storage-server.ps1 -nbmaster <masterServer> -username <username> -password <password> -stsid <storage server id>`
- `.\Patch-NB-update-disk-pool.ps1 -nbmaster <masterServer> -username <username> -password <password> -dpid <disk pool id>`
- `.\Patch-NB-update-cloud-storage-server.ps1 -nbmaster <masterServer> -username <username> -password <password> -stsid <storage server id>`
- `.\Patch-NB-update-ad-storage-server.ps1 -nbmaster <masterServer> -username <username> -password <password> -stsid <storage server id>`
- `.\Delete-NB-delete-disk-pool.ps1 -nbmaster <masterServer> -username <username> -password <password> -dpid <disk pool id>`
- `.\Delete-NB-delete-storage-server.ps1 -nbmaster <masterServer> -username <username> -password <password> -stsid <storage server id>`
- `.\Delete-NB-delete-storage-unit.ps1 -nbmaster <masterServer> -username <username> -password <password> -stu_name <storage unit name>`
- `.\Post-NB-add-replication-target-to-disk-volume.ps1 -nbmaster <masterServer> -username <username> -password <password> -stsid <storage server id> -dvid <diskvolume id>`
- `.\Post-NB-delete-replication-target-to-disk-volume.ps1 -nbmaster <masterServer> -username <username> -password <password> -stsid <storage server id> -dvid <diskvolume id>`
- `.\Get-NB-replication-targets-to-disk-volume.ps1 -nbmaster <masterServer> -username <username> -password <password> -stsid <storage server id> -dvid <diskvolume id>`
- `.\Get-NB-replication-targets-to-disk-volume-by-id.ps1 -nbmaster <masterServer> -username <username> -password <password> -stsid <storage server id> -dvid <diskvolume id> -reptargetid <replication target id>`

