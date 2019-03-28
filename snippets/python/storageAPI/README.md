### NetBackup API Code Samples for Python

This directory contains code samples to invoke NetBackup REST APIs using Python.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Pre-requisites:

- NetBackup 8.2 or higher
- python 3.5 or higher
- python modules: `requests, texttable`

#### Executing the snippets in Python

Use the following commands to run the python samples.
- `python -W ignore create_disk_pool.py -nbmaster <master_server> -username <username> -password <password> -payload <input JSON > [-domainname <domain_name>] [-domaintype <domain_type>]`
- `python -W ignore create_storage_server.py -nbmaster <master_server> -username <username> -password <password> -payload <input JSON > [-domainname <domain_name>] [-domaintype <domain_type>]`
- `python -W ignore create_storage_unit.py -nbmaster <master_server> -username <username> -password <password> -payload <input JSON > [-domainname <domain_name>] [-domaintype <domain_type>]`
- `python -W ignore delete_disk_pool.py -nbmaster <master_server> -username <username> -password <password> -dpid <disk pool id>[-domainname <domain_name>] [-domaintype <domain_type>]`
- `python -W ignore delete_storage_server.py -nbmaster <master_server> -username <username> -password <password> -stsid <storage server id>[-domainname <domain_name>] [-domaintype <domain_type>]`
- `python -W ignore delete_storage_unit.py -nbmaster <master_server> -username <username> -password <password> -stu_name <storage unit name>[-domainname <domain_name>] [-domaintype <domain_type>]`
- `python -W ignore get_disk_pool.py -nbmaster <master_server> -username <username> -password <password> [-domainname <domain_name>] [-domaintype <domain_type>]`
- `python -W ignore get_disk_pool_by_id.py -nbmaster <master_server> -username <username> -password <password> -dpid <disk pool id>[-domainname <domain_name>] [-domaintype <domain_type>]`
- `python -W ignore get_storage_server.py -nbmaster <master_server> -username <username> -password <password> [-domainname <domain_name>] [-domaintype <domain_type>]`
- `python -W ignore get_storage_unit.py -nbmaster <master_server> -username <username> -password <password> [-domainname <domain_name>] [-domaintype <domain_type>]`
- `python -W ignore get_storage_unit_by_id.py -nbmaster <master_server> -username <username> -password <password> -stu_name <storage unit name>[-domainname <domain_name>] [-domaintype <domain_type>]`
- `python -W ignore patch_disk_pool.py -nbmaster <master_server> -username <username> -password <password> -payload <input JSON > -dpid <disk pool id>[-domainname <domain_name>]`
- `python -W ignore create_storage_server.py -nbmaster <master_server> -username <username> -password <password> -payload <input JSON > -stsid <storage server id>[-domainname <domain_name>] [-domaintype <domain_type>]`
- `python -W ignore patch_storage_unit.py -nbmaster <master_server> -username <username> -password <password> -payload <input JSON > -stu_name <storage unit name>[-domainname <domain_name>] [-domaintype <domain_type>]`

