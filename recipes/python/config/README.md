### NetBackup Hosts Configuration Management API Code Samples

This directory contains Python scripts demonstrating the use of NetBackup Hosts Configuration Management APIs to update exclude list on a NetBackup host.

#### Disclaimer

These samples are provided only for reference and not meant for production use.

#### Executing the script

Pre-requisites:
- NetBackup 8.2 or higher
- Python 3.5 or higher
- Python modules: `requests`.


Use the following command to run the script. The command should be run from the parent directory of this 'config' directory.
- `python -W ignore -m config.hosts_exclude_list -hostName <hostName> -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]
Note: hostName is the name of the NetBackup host to set the exclude configuration. The exclude list is specified in the config/exclude_list file.`
