### NetBackup API Code Samples for PowerShell

This directory contains code samples to invoke NetBackup REST APIs using PowerShell.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Executing the recipes in PowerShell

Pre-requisites:
- NetBackup 8.1.2 or higher
- PowerShell 4.0 or higher
- NetBackup 8.2 or higher is required for configuring storage API 

Use the following commands to run the PowerShell samples.
- `.\configure_storage_unit_end_to_end.ps1 -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName> -domainType <domainType>]`
