### NetBackup API Code Samples for Python

This directory contains code samples to invoke NetBackup REST APIs using Python.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Executing the recipes in Python

Pre-requisites:
- NetBackup 8.2 or higher
- python 3.5 or higher
- python modules: `requests`


Use the following commands to run the python samples.
- `python -W ignore create_policy_step_by_step.py -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
- `python -W ignore create_policy_in_one_step.py -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
- `python -W ignore rbac_filtering_in_policy.py -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
