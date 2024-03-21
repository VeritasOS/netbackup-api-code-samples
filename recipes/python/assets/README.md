### NetBackup Asset Service API Code Samples

This directory contains Python scripts demonstrating the use of NetBackup Asset Service APIs.

#### Disclaimer

The samples are provided only for reference and not meant for production use.

#### Executing the script

Prerequisites:
- NetBackup 8.3 or higher
- Python 3.5 or higher
- Python modules: `requests`

The following are the commands to run the scripts (should be run from the parent directory of this 'assets' directory).

- get_vmware_assets (Get VMs or VM Groups):

    `python -Wignore -m assets.get_vmware_assets -nbserver <server> -username <username> -password <password> -domainName <domainName> -domainType <domainType> [-assetType <vm|vmGroup>] [-assetsFilter <filter>]`

    The script uses the NetBackup Asset Service API to get the VMware workload assets - VMs or VM groups (filtered by the given filter if specified). It prints the following details (delimited by tab): For assetType 'vm' - VM display name, Instance Id, vCenter and the protection plan names that the VM is protected by. For assetType 'vmGroup' - VM group name, VM server, group filter criteria and the protection plan names.

    The assetType option can be either vm or vmGroup. Default is 'vm' if not specified.
    The assetsFilter option can be used to filter the assets returned. The filter criteria should be in OData format (refer to the NetBackup API documentation for more details). If not specified, the script will get all the assets. Redirect the script output to a file to avoid printing the details on the terminal.

    Examples:
    - Gets all VMs: `python -Wignore -m assets.get_vmware_assets -nbserver localhost -username user -password password -domainName domain -domainType NT > vm_assets.txt`

    - Get the VMs that match the given filter: `python -Wignore -m assets.get_vmware_assets -nbserver localhost -username user -password password -domainName domain -domainType NT -assetsFilter "contains(commonAssetAttributes/displayName, 'backup')" > vm_assets.txt`

    - Get all VM Groups: `python -Wignore -m assets.get_vmware_assets -nbserver localhost -username user -password password -domainName domain -domainType NT -assetType vmGroup > vm_groups.txt`

    - Get the VM Groups that match the given filter: `python -Wignore -m assets.get_vmware_assets -nbserver localhost -username user -password password -domainName domain -domainType NT -assetType vmGroup -assetsFilter "contains(commonAssetAttributes/displayName, 'backup')"`


- create_vmware_asset_group (Create VM group and get the VM group by Id):

    `python -Wignore -m assets.create_vmware_asset_group -nbserver <server> -username <username> -password <password> -domainName <domainName> -domainType <domainType> -vmGroupName <name> -vmServer <for example, vCenter> [-vmGroupFilter <filter criteria>]`

    The script uses the NetBackup Asset Service API to create VM group and get the VM group details using its asset id. The vmGroupFilter option specifies the filter criteria (in OData format) for the VMs to be included in the group. If it is empty or not specified, all the VMs in the given VM server are included in the group.
    If the VM group is created, the script gets the VM group by its asset id and prints the details.

    Examples:
    - Create VM group with no filter: `python -Wignore -m assets.create_vmware_asset_group -nbserver localhost -username user -password password -domainName domain -domainType NT -vmGroupName vmGroup1 -vmServer vcenter1`

    - Create VM group with filter: `python -Wignore -m assets.create_vmware_asset_group -nbserver localhost -username user -password password -domainName domain -domainType NT -vmGroupName vmGroup2 -vmServer vcenter2 -vmGroupFilter "contains(commonAssetAttributes/displayName, 'backup')"`


- create_oracle_asset (Create Oracle Asset):

    `python -Wignore create_oracle_asset.py -nbserver <server>  -username <username> -password <password> [-dbName <databaseName>] [-addRMANCatalog] [-rmanCatalogName <catalogName for RMAN catalog>] [-tnsName <tnsName for RMAN catalog>] [-addCredentials <wallet|os|oracle|osAndOracle>] [-credentialName <Name for credentials>]`

    The script uses the NetBackup Asset Service API to add an Oracle database with the given name. Add an RMAN catalog to the database if specified. Also adding credentials to the created assets if specified. It ends with running a database discovery on the primary server.

    Examples:
    - Add an Oracle database with existing credentials: `python -Wignore create_oracle_asset.py -nbserver localhost -username username -password password -dbName SampleDB -credentialName ExistingCreds`

    - Add an Oracle database with a new RMAN catalog and new credentials: `python -Wignore create_oracle_asset.py -nbserver localhost -username username -password password -dbName SampleDB -addRMANCatalog -rmanCatalogName catalog -tnsName rmancat -addCredentials os -credentialName OracleCreds`
