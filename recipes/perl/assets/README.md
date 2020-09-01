### NetBackup API Code Samples for perl

This directory contains code samples to invoke NetBackup VMware GET ASSETS APIs using perl.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Prerequisites:

- NetBackup 8.3 or higher
- Perl 5.20.2 or higher

#### Executing the recipes in perl

Use the following commands to run the perl samples.

- `perl get_vmware_assets.pl -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
The script uses the NetBackup Asset Service API to get the VMware workload assets along with Id's configured in the system.

- `perl create_assetGroup.pl -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
The script creates a VMware Asset Group by using Netabckup Asset Service API.


Examples: 
- perl get_vmware_assets.pl -nbmaster localhost -username user -password password -domainName domain -domainType NT
- perl create_assetGroup.pl -nbmaster localhost -username user -password password -domainName domain -domainType NT
