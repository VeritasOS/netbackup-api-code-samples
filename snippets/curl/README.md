### NetBackup API Code Samples for curl

This directory contains code samples to invoke NetBackup REST APIs using curl.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Pre-requisites:

- NetBackup 8.1.1 or higher
- curl 7.51.0 or higher
- jq command-line parser (https://github.com/stedolan/jq/releases)

#### Executing the snippets in curl

Use the following commands to run the curl samples.
- `./get_nb_jobs.sh -nbmaster <master_server> -username <username> -password <password> -domainname <dname> -domaintype <unixpwd/nt>`
- `./get_nb_images.sh -nbmaster <master_server> -username <username> -password <password> -domainname <dname> -domaintype <unixpwd/nt>`
