#### NetBackup API Code Samples for PowerShell

This directory contains code samples to invoke NetBackup config APIs using PowerShell.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Executing the recipes in PowerShell

Pre-requisites:
- NetBackup 8.2 or higher
- PowerShell 4.0 or higher

Use the following commands to run the PowerShell samples.
- `./configManagement_curd_operations.ps1 -MasterServer <masterServer> -UserName <username> -Password <password> -Client <client> [-DomainName <domainName> -DomainType <domainType>]`
- `./Config_trust_management_crud_operation.ps1 -MasterServer <masterServer> -UserName <username> -Password <password> -TrustedMasterServerName <Trusted master Server Name> [-DomainName <domainName> -DomainType <domainType>]`