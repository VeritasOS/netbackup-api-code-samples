### NetBackup Assets Service API Code Samples

This directory contains Python scripts demonstrating the use of NetBackup Asset Service APIs.

#### Disclaimer

The samples are provided only for reference and not meant for production use.

#### Executing the script

Pre-requisites:
- NetBackup 8.3 or higher
- Python 3.5 or higher (the script has been tested with Python 3.8)
- Python modules: `requests`.


The following are the commands to run the scripts (should be run from the parent directory of this 'assets' directory).

- get_vmware_assets:
    `python -Wignore -m assets.get_vmware_assets -nbserver <server> -username <username> -password <password> -domainName <domainName> -domainType <domainType> [-assetsFilter <filter>]`

The script uses the NetBackup Asset Service API to get the VMware workload assets (filtered by the given filter if specified). It prints the details (delimited by tab) such as asset display name, instance Id, vCenter and the plan names that the asset is protected by.

Note: _The assetsFilter option can be used to filter the assets returned. It should be in OData format (refer to the NetBackup API documentation). It is optional. If not specified the script will print all the VM assets. Redirect the script output to a file to avoid printing the details on the terminal._

Examples: `python -Wignore -m assets.get_vmware_assets -nbserver localhost -username user -password password -domainName domain -domainType NT > vm_assets.txt`
`python -Wignore -m assets.get_vmware_assets -nbserver localhost -username user -password password -domainName domain -domainType NT -assetsFilter "contains(commonAssetAttributes/displayName, 'backup')" > vm_assets.txt`
