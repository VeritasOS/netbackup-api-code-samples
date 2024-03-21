### NetBackup API Code Samples for PowerShell

This directory contains code samples to invoke NetBackup Policy APIs using PowerShell.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Executing the recipes in PowerShell

Pre-requisites:
- NetBackup 8.1.2 or higher

    - **NOTE:**  The following scripts configure access control using the old RBAC design and will only work on NetBackup
 release 8.1.2 or 8.2.
        - recipes/perl/policies/rbac_filtering_in_policy.ps1
        
- PowerShell 4.0 or higher

Use the following commands to run the PowerShell samples.
- `.\create_policy_in_one_step.ps1 -MasterServer <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
- `.\rbac_filtering_in_policy.ps1 -MasterServer <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
- `./New-Policy-StepByStep.ps1 -MasterServer <masterServer> -UserName <username> -Password <password> [-DomainName <domainName> -DomainType <domainType>]`
