### NetBackup API Code Samples for Python

This directory contains code samples to invoke NetBackup REST APIs using Python.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Pre-requisites:

- NetBackup 8.1.1 or higher
- NetBackup 8.2 or higher for using API keys related APIs and samples
- python 3.5 or higher
- python modules: `requests, texttable`

#### Executing the snippets in Python

Use the following commands to run the python samples.
- `python -W ignore get_nb_images.py -nbmaster <master_server> -username <username> -password <password> [-domainname <domain_name>] [-domaintype <domain_type>]`
- `python -W ignore get_nb_jobs.py -nbmaster <master_server> -username <username> -password <password> [-domainname <domain_name>] [-domaintype <domain_type>]`

#### Scripts for NetBackup 8.2 or higher

- Use the following command to create an API key for yourself on your NetBackup Master server:
  - `python -W apikey_create.py -nbmaster <master_server> -login_username <login_username> -login_password <login_password> -login_domainname <login_domainname> -login_domaintype <login_domaintype> -expiryindays <expiryindays> -description <description>`
  
- Use the following command to create an API key for other user on your NetBackup Master server:
  - `python -W apikey_create.py -nbmaster <master_server> -login_username <login_username> -login_password <login_password> -login_domainname <login_domainname> -login_domaintype <login_domaintype> -apikey_username <apikey_username> [-apikey_domainname <apikey_domain_name>] -apikey_domaintype <apikey_domaintype> -expiryindays <expiry_in_days> -description <description>`
  
- Use the following command to delete an API key on your NetBackup Master server with apikey tag provided:
  - `python -W apikey_delete.py -nbmaster <master_server> -login_username <login_username> -login_password <login_password> -login_domainname <login_domainname> -login_domaintype <login_domaintype> -apikey_tag <apikey_tag>`
  
Use the following command to use API key instead of JWT to trigger a NetBackup REST API on your NetBackup Master server:
  - `python -W apikey_usage.py -nbmaster <master_server> -apikey <apikey>`
