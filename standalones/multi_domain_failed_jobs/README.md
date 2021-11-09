### Multi-domain failed job

Writing scripts to run on the NetBackup primary server that generate failed job listing has been around from the beginning.  BUT many customer environments have security issues where remotely executing scripts as root has been restricted.  We can now use the NetBackup APIs to gather from multiple NetBackup domains without having to actually remotely execute commands.

#### Disclaimer
These examples are only meant to be used as a reference. Please do not use these in production.

#### Pre-requisites

- Tested with NetBackup 9.1
- For PowerShell script, tested with the following
  - PowerShell 5.1
- For Python script, testing with the following
  - Python 3.6.8
- API user with key generated associated with role having these permissions
  - For the policy_export scripts
    - Global -> Protection -> Policies -> View
  - For the policy_import scripts
    - Global -> Protection -> Policies -> View
    - Global -> Protection -> Policies -> Create
    - Global -> Protection -> Policies -> Update

#### Executing policy_export

This PowerShell script is not signed so you may encounter errors trying to run this.  You can use the PowerShell cmdlet [Set-Execution Policy](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7) to adjust your environment to allow running unsigned PowerShell scripts.

To execute, run the command like this:

```
policy_export.ps1 -p "PRIMARY_SERVER" -k "APIKEY" [-v]
OR
policy_export.py3 -p "PRIMARY_SERVER" -k "APIKEY" [-v]
```

Replace PRIMARY_SERVER with the NetBackup primary server to export the policies from and APIKEY with the API key generated through the NetBackup web UI.  The optional -v option will provide additional information during the processing.  Without the -v option, policy_export.ps1 will run silently.

All policies (including any protection plan policies) will be stored in JSON format in a file named PRIMARY_SERVER--POLICY_NAME in the current working directory.

#### Executing policy_import.ps1

This PowerShell script is not signed so you may encounter errors trying to run this.  You can use the PowerShell cmdlet [Set-Execution Policy](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7) to adjust your environment to allow running unsigned PowerShell scripts.

To execute, run the command like this:

```
policy_import.ps1 -f "JSON_FILE" -p "PRIMARY_SERVER" -k "APIKEY" [-v]
OR
policy_import.py3 -f "JSON_FILE" -p "PRIMARY_SERVER" -k "APIKEY" [-v]
```

Replace JSON_FILE with the name of a JSON formatted policy file (preferred on from the policy_export.ps1 or policy_export.py3 script), PRIMARY_SERVER with the NetBackup primary server to export the policies from and APIKEY with the API key generated through the NetBackup web UI.  The optional -v option will provide additional information during the processing.  Without the -v option, policy_export.ps1 will run silently.

