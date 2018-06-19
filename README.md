### NetBackup API Code Samples

Contains code samples to invoke NetBackup REST API using different programming languages.

#### Disclaimer
These scripts are only meant to be used as a reference. Please do not use these in production.

#### Executing the snippets in PowerShell
Pre-requisites:
- NetBackup 8.1.1 or higher
- Powershell 5.0 or higher

Use the following commands to run the powershell samples.
- `.\Get-NB-Images.ps1 -nbmaster <masterServer> -username <username> -password <password>`
- `.\Get-NB-Jobs.ps1 -nbmaster <masterServer> -username <username> -password <password>`

#### Executing the snippets in Python
Pre-requisites:
- NetBackup 8.1.1 or higher
- python 3.5 or higher
- python modules: `requests, texttable`

Use the following commands to run the python samples.
- `python -W ignore get_nb_images.py -nbmaster <masterServer> -username <username> -password <password>`
- `python -W ignore get_nb_jobs.py -nbmaster <masterServer> -username <username> -password <password>`

#### Executing the recipes in Python
Pre-requisites:
- NetBackup 8.1.1 or higher
- python 3.5 or higher
- python modules: `requests`

Use the following commands to run the python samples.
- `python -W ignore create_policy_with_defaults.py -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
- `python -W ignore create_policy_without_defaults.py -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`

#### Executing the snippets in Perl
Pre-requisites:
- NetBackup 8.1.1 or higher
- See script README for perl requirements and usage

