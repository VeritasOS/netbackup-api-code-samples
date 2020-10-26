### ClientBackup:  initiate policy based backup from client

These scripts are designed to initiate a backup from the client using a specified policy and API key.  The program logic in the script works like this:

* Look at the local NetBackup configuration for the client name and the master server
* Using the /netbackup/config/policies API, get the details of the specified policy
  * Look for the presence of an INCR and FULL schedule
  * Get backup frequency of the INCR and FULL schedules
* Using /netbackup/catalog/images API, get the last 30 days of backup images for this client
* Compare the last backups to the schedule frequencies to determine what level (FULL or INCR) backup to run.
* Initiate the backup using the /netbackup/admin/manual-backup API

#### Disclaimer

These scripts are only meant to be used as a reference.  If you intend to use them in production, use them at your own risk.

#### Pre-requisites

* Tested with NetBackup 8.3
* For Windows clients, tested with the following
  * PowerShell version 5.1
  * Windows Server 2016
* NetBackup client software already installed on client
* Policy defined on master server with following specifics
  * Scheduled name Full defined as full backup type
  * Schedule named Incr defined as incremental backup type
  * Source clients added to Clients
* API user with key generated associated with role having these permissions
  * Global -> NetBackup management -> NetBackup backup images -> View
  * Global -> Protection -> Policies -> View
  * Global -> Protection -> Policies -> Manual backup

#### Executing ClientBackup.ps1

This PowerShell script is not signed so you may encounter errors trying to run this.  You can use the PowerShell cmdlet [Set-Execution Policy](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7) to adjust your environment to allow running unsigned PowerShell scripts.

To execute, run the command like this:

```
ClientBackup.ps1 -p "POLICY" -k "APIKEY" [-v]
```

Replace POLICY with the NetBackup policy to use and replace APIKEY with the API key generated through the NetBackup web UI.  The optional -v option will provide additional information during the processing.  Without the -v option, ClientBackup.ps1 will run silently.