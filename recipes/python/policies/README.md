### NetBackup API Code Samples for Policy APIs

This directory contains code samples in Python to invoke NetBackup Policy APIs.

#### Disclaimer

These samples are provided only as reference and not meant for production use.

#### Executing the scripts

Pre-requisites:
- NetBackup 8.1.2 or higher
- Python 3.5 or higher
- Python modules: `requests`


Use the following commands to run the scripts.
- Create a test policy, add clients, backup selections and schedules to the policy, and delete the policy: `python -W ignore create_policy_step_by_step.py -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
- Create a test policy with default values, and delete the policy: `python -W ignore create_policy_in_one_step.py -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
- Create RBAC access rule, set object-level permission on policies for test user, create and read policies as per the RBAC permissions, and delete the test policies: `python -W ignore rbac_filtering_in_policy.py -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
