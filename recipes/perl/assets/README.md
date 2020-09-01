### NetBackup API Code Samples for perl

This directory contains code samples to invoke NetBackup VMware GET ASSETS APIs using perl.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Prerequisites:

- NetBackup 8.3 or higher
- Perl 5.20.2 or higher

#### Executing the recipes in perl

Use the following commands to run the perl samples.
- `perl get_vmware_assets.pl -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>] [-assetsFilter <filter>]`

The script uses the NetBackup Asset Service API to get the VMware workload assets (filtered by the given filter if specified). It prints the details such as asset display name, instance Id, vCenter and the plan names that the asset is protected by.
`Note: assetsFilter (should be in OData format, refer to the NetBackup API documentation) can be used to filter the assets returned. It is optional, if not specified the script will print all the VM assets. Redirect the script output to a file to avoid printing the details on terminal.`

Examples: 
- perl get_vmware_assets.pl -nbmaster localhost -username user -password password -domainName domain -domainType NT > vm_assets.txt
- perl get_vmware_assets.pl -nbmaster localhost -username user -password password -assetsFilter "contains(commonAssetAttributes/displayName, 'backup')" > vm_assets.txt