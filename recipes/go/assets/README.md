### NetBackup API Code Samples in go

This directory contains code samples in golang for NetBackup Asset Service APIs.

#### Disclaimer

The scripts are provided only for reference and not meant for production use.

#### Pre-requisites:

- NetBackup 8.3 or higher
- go1.10.2 or higher

#### Executing the script

- get_vmware_assets:
    `go run ./get_vmware_assets.go -nbserver <NetBackup server> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>] [-assetsFilter <filter>]`

    The script invokes the NetBackup VMware Asset Service API to get the VMware workload assets (filtered by the given filter criteria if specified). It prints the asset details (delimited by tab) such as asset display name, instance Id, vCenter and the protection plan names that the asset is protected by.

    Note: The _assetsFilter_ option can be used to filter the assets returned. It should be in OData format (refer to the NetBackup API documentation for more details). It is optional; if not specified the script will return all VM assets. Redirect the script output to a file to avoid printing the details on terminal.

    Examples:

    - List all VMs: `go run ./get_vmware_assets.go -nbserver localhost -username user -password password -domainName domain -domainType NT > vm_assets.txt`

    - List VMs with filter condition: `go run ./get_vmware_assets.go -nbserver localhost -username user -password password -domainName domain -domainType NT -assetsFilter "contains(commonAssetAttributes/displayName, 'backup')"`
