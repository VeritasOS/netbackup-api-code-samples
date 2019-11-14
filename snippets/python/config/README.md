### NetBackup API Code Samples for Python

This directory contains code samples to invoke NetBackup REST APIs using Python.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Pre-requisites:

- NetBackup 8.2 or higher
- python 3.5 or higher
- python modules: `requests, texttable`

#### NOTE - Sample payloads from the snippets\sample-payloads\config-samples location can be used as input to run the scripts.

#### Executing the snippets in Python

Use the following commands to run the python samples.
- `python -W ignore get_trusted_master_server_list.py -nbmaster <master_server> -username <username> -password <password> [-domainname <domain_name>] [-domaintype <domain_type>]`
- `python -W ignore get_trusted_master_server_by_name.py -nbmaster <master_server> -username <username> -password <password> -trustedmasterservername <Trusted master Server Name> [-domainname <domain_name>] [-domaintype <domain_type>]`
- `python -W ignore get_remote_master_server_cacert_by_name.py -nbmaster <master_server> -username <username> -password <password> -remotemasterserver <Remote Master Server Name> [-domainname <domain_name>] [-domaintype <domain_type>]`
- `python -W ignore get_media_server_by_name.py -nbmaster <master_server> -username <username> -password <password> -medianame <Media Server Name> [-domainname <domain_name>] [-domaintype <domain_type>]`
- `python -W ignore get_media_server.py -nbmaster <master_server> -username <username> -password <password> [-domainname <domain_name>] [-domaintype <domain_type>]`
- `python -W ignore delete_trust.py -nbmaster <master_server> -username <username> -password <password> -trustedmasterservername <Trusted Master Server Name>[-domainname <domain_name>] [-domaintype <domain_type>]`
- `python -W ignore create_trusted_master_server.py -nbmaster <master_server> -username <username> -password <password> -payload <input JSON > [-domainname <domain_name>] [-domaintype <domain_type>]`
- `python -W ignore patch_trusted_master_server.py -nbmaster <master_server> -username <username> -password <password> -payload <input JSON > -trustedmasterservername <Trusted Master Server Name>[-domainname <domain_name>] [-domaintype <domain_type>]`