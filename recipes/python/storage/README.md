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
- `python -W ignore configure_storage_unit_end_to_end.py -nbmaster <master_server> -username <username> -password <password> -sts_payload <input JSON for storage server> -dp_payload <input JSON for disk pool> -stu_payload <input JSON for storage unit> [-domainname <domain_name>] [-domaintype <domain_type>]`

- `python -W ignore replication_target_operations_end_to_end.py -nbmaster <master_server> -username <username> -password <password> -sts_payload <input JSON for storage server> -dp_payload <input JSON for disk pool> -stu_payload <input JSON for storage unit> -add_reptarget_payload <input JSON for add replication target> -delete_reptarget_payload <input JSON for delete replication target> [-domainname <domain_name>] [-domaintype <domain_type>]`
