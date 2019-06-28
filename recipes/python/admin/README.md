### NetBackup Hosts Administration APIs Code Samples 

This directory contains sample Python scripts that list the details of NetBackup processes and services running on a host using the NetBackup Hosts Administration APIs.

#### Disclaimer

These samples are provided only for reference and not meant for production use.

#### Executing the script

Pre-requisites:
- NetBackup 8.2 or higher
- Python 3.5 or higher
- Python modules: `requests`.


Use the following commands to run the scripts. The commands should be run from the parent directory of this 'admin' directory.
- Get the details of NetBackup processes running on a host (specified by hostName): `python -W ignore -m admin.list_nb_processes -hostName <hostName> -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
- Get the details/status of NetBackup services on a host (specified by hostName): `python -W ignore -m admin.list_nb_services -hostName <hostName> -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
