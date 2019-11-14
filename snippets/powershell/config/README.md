### NetBackup API Code Samples for PowerShell

This directory contains code samples to invoke NetBackup REST APIs using PowerShell.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Pre-requisites:

- NetBackup 8.2 or higher
- PowerShell 5.0 or higher

#### Executing the snippets in PowerShell

Use the following commands to run the PowerShell samples.
- `./Get-NB-get-media-server.ps1 -nbmaster "nb-master.example.com" -username "administrator" -password "secret"`
- `./Get-NB-get-media-server-by-name.ps1 -nbmaster "nb-master.example.com" -username "administrator" -password "secret" -medianame "Media Server Name"`
- `./Get-NB-get-remote-master-server-cacert-by-name.ps1 -nbmaster "nb-master.example.com" -username "administrator" -password "secret" -remotemasterserver "remote Master Server Name"`
- `./Get-NB-get-trusted-master-server-list.ps1 -nbmaster "nb-master.example.com" -username "administrator" -password "secret"`
- `./Get-NB-get-trusted-master-server-by-name.ps1 -nbmaster "nb-master.example.com" -username "administrator" -password "secret" -trustedmasterservername "Trusted master Server Name"`
- `./Post-NB-create-trusted-master-server.ps1 -nbmaster "nb-master.example.com" -username "administrator" -password "secret"`
- `./Patch-NB-update-trusted-master-server.ps1 -nbmaster "nb-master.example.com" -username "administrator" -password "secret" -trustedmasterservername "Trusted Master Server Name"`
- `./Delete-NB-delete-trust.ps1 -nbmaster "nb-master.example.com" -username "administrator" -password "secret" -trustedmasterservername "Trusted Master Server Name"`