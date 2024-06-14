### NetBackup Config API Code Samples

This directory contains Python scripts demonstrating :
1. The use of NetBackup Hosts Configuration Management APIs to update exclude list on a NetBackup host.
2. The use of NetBackup Access Hosts API to view, add and delete an access-host on a NetBackup master. 

#### Disclaimer

These samples are provided only for reference and not meant for production use.

####Pre-requisites:
- NetBackup 8.2 or higher
- Python 3.5 or higher
- Python modules: `requests`.

####Usage

#####NetBackup Hosts Configuration Management API
Use the following command to run the script. The command should be run from the parent directory of this 'config' directory.

`python -W ignore -m config.hosts_exclude_list -hostName <hostName> -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`

`Note: hostName is the name of the NetBackup host to set the exclude configuration. The exclude list is specified in the config/exclude_list file.`

#####NetBackup Access Hosts API
Use the following command to run the script. The command should be run from the parent directory of this 'config' directory.

`python -W ignore -m config.access_hosts_api_usecases -hostName <hostName> -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`

`Note: hostName is the name of the VMware Access host to add/delete using the Access Host APIs.`

