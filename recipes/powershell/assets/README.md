#NetBackup VMware Asset API Code Samples for PowerShell

This directory contains PowerShell scripts demonstrating the use of NetBackup Asset Service APIs for creating and retrieving VMware assets.

####Disclaimer

The samples are provided only for reference and not meant for production use.

####Executing the recipes in PowerShell

#####Prerequisites:

- NetBackup 8.3 or higher
- PowerShell 4.0 or higher

#####Script Details

- get_vmware_assets script uses the NetBackup Asset Service API to get the VMware workload assets (filtered by the given filter if specified).  It prints the details such as asset display name, instance Id, vCenter and the plan names that the asset is protected by. 
Note: assetsFilter (should be in OData format; refer to the NetBackup API documentation) can be used to filter the assets returned. It is optional; if not specified the script will print all the VM assets. Redirect the script output to a file to avoid printing the details on terminal.

- create_vmware_asset_group script creates a VMware asset group using sample data provided inside the script.  Redirect the script output to a file to 
avoid printing the details on terminal.

#####Running the Scripts

Use the following commands to run the PowerShell sample:
- .\get_vmware_assets.ps1 -MasterServer <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>] [-assetType <vm|vmGroup>] [-assetsFilter <filter>]
- .\create_vmware_asset_group.ps1 -MasterServer <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]
