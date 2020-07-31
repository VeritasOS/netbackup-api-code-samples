### NetBackup API Code Samples for PowerShell

This directory contains code samples to invoke NetBackup REST APIs using PowerShell.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Pre-requisites:

- NetBackup 8.1.1 or higher
- NetBackup 8.2 or higher for using API keys related APIs and samples
- PowerShell 5.0 or higher

#### Executing the snippets in PowerShell

Use the following commands to run the PowerShell samples.
- `.\Get-NB-Images.ps1 -nbmaster <masterServer> -username <username> -password <password>`
- `.\Get-NB-Jobs.ps1 -nbmaster <masterServer> -username <username> -password <password>`
- `.\Get-NB-ReissueToken.ps1 -nbmaster <masterServer> -username <username> -password <password> -nbclient <client_hostname>`
- `.\Post-NB-Cleanup-Assets.ps1 -nbmaster <masterServer> -username <username> -password <password> -filter <workloadType eq 'VMware'> -cleanupTime 2018-06-29T15:18:45.678Z`

#### Scripts for NetBackup 8.2 or higher

Use the following command to create an API key for yourself on your NetBackup Master server:
  - `.\apikey_create.ps1 -nbmaster <master_server> -login_username <login_username> -login_password <login_password> -login_domainname <login_domainname> -login_domaintype <login_domaintype> -expiryindays <expiryindays> -description <description>`
  
Use the following command to create an API key for other user on your NetBackup Master server:
  - `.\apikey_create.ps1 -nbmaster <master_server> -login_username <login_username> -login_password <login_password> -login_domainname <login_domainname> -login_domaintype <login_domaintype> -apikey_username <apikey_username> [-apikey_domainname <apikey_domain_name>] -apikey_domaintype <apikey_domaintype> -expiryindays <expiry_in_days> -description <description>`
  
- Use the following command to delete an API key on your NetBackup Master server with apikey tag provided:
  - `.\apikey_delete.sh -nbmaster <master_server> -login_username <login_username> -login_password <login_password> -login_domainname <login_domainname> -login_domaintype <login_domaintype> -apikey_tag <apikey_tag>`

Use the following command to use API key instead of JWT to trigger a NetBackup REST API on your NetBackup Master server:
  - `.\APIKey-Usage.ps1 -nbmaster <master_server> -apikey <apikey>`
