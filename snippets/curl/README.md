### NetBackup API Code Samples for curl

This directory contains code samples to invoke NetBackup REST APIs using curl.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Pre-requisites:

- NetBackup 8.1.1 or higher
- NetBackup 8.2 or higher for using API keys related APIs and samples
- curl 7.51.0 or higher
- jq command-line parser (https://github.com/stedolan/jq/releases)

#### Executing the snippets in curl

Use the following commands to run the curl samples.
- `./get_nb_jobs.sh -nbmaster <master_server> -username <username> -password <password> -domainname <dname> -domaintype <unixpwd/nt>`
- `./get_nb_images.sh -nbmaster <master_server> -username <username> -password <password> -domainname <dname> -domaintype <unixpwd/nt>`

#### Scripts for NetBackup 8.2 or higher

- Use the following command to create an API key for yourself on your NetBackup Master server:
  - `./apikey_create.sh -nbmaster <master_server> -login_username <login_username> -login_password <login_password> -login_domainname <login_domainname> -login_domaintype <login_domaintype> -expiryindays <expiryindays> -description <description>`
  
- Use the following command to create an API key for other user on your NetBackup Master server:
  - `./apikey_create.sh -nbmaster <master_server> -login_username <login_username> -login_password <login_password> -login_domainname <login_domainname> -login_domaintype <login_domaintype> -apikey_username <apikey_username> [-apikey_domainname <apikey_domain_name>] -apikey_domaintype <apikey_domaintype> -expiryindays <expiry_in_days> -description <description>`
  
- Use the following command to delete an API key on your NetBackup Master server with apikey tag provided:
  - `./apikey_delete.sh -nbmaster <master_server> -login_username <login_username> -login_password <login_password> -login_domainname <login_domainname> -login_domaintype <login_domaintype> -apikey_tag <apikey_tag>`
  
Use the following command to use API key instead of JWT to trigger a NetBackup REST API on your NetBackup Master server:
  - `./apikey_usage.sh -nbmaster <master_server> -apikey <apikey>`