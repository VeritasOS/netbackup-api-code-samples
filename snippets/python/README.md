### NetBackup API Code Samples for Python

This directory contains code samples to invoke NetBackup REST APIs using Python.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Pre-requisites:

- NetBackup 8.1.1 or higher
- python 3.5 or higher
- python modules: `requests, texttable`

#### Executing the snippets in Python

Use the following commands to run the python samples.
- `python -W ignore get_nb_images.py -nbmaster <master_server> -username <username> -password <password> [-domainname <domain_name>] [-domaintype <domain_type>]`
- `python -W ignore get_nb_jobs.py -nbmaster <master_server> -username <username> -password <password> [-domainname <domain_name>] [-domaintype <domain_type>]`
