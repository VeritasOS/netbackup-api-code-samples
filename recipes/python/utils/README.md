# NetBackup API code sample utilities

This directory contains code samples in Python to invoke NetBackup APIs.

## Disclaimer

These samples are provided only as reference and not meant for production use.

## Executing the scripts

Prerequisites:
- NetBackup 9.1 or higher
- Python 3.5 or higher
- Python modules: `requests`


Use the following commands to run the scripts.
- Enable or disable the NetBackup UI compatibility service (NBUICS):

    ```
    python3 nbuics_enable_disable.py -enable -nbmaster <masterServer> -username <username> -password <password> -domainName <domainName> -domainType <domainType>
    python3 nbuics_enable_disable.py -disable -nbmaster <masterServer> -username <username> -password <password> -domainName <domainName> -domainType <domainType>
    ```
