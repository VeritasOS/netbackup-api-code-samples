### NetBackup API Code Samples for VMware Agentless Restore APIs

This directory contains code samples in Python to invoke NetBackup Agentless Restore APIs.

#### Disclaimer

These samples are provided only as reference and not meant for production use.

#### Executing the script

Pre-requisites:
- NetBackup 8.2 or higher
- Python 3.7 or higher
- Python modules: `requests`, `texttable`



Without arguments the script will prompt for the necessary inputs.
- `python vmware_agentless_restore.py`

All parameters can also be passed as command line arguments.
- `python vmware_agentless_restore.py --help`
```
usage: vmware_agentless_restore.py [-h] [--master MASTER]
                                   [--username USERNAME] [--password PASSWORD]
                                   [--port PORT] [--vm_name VM_NAME]
                                   [--vm_username VM_USERNAME]
                                   [--vm_password VM_PASSWORD] [--file FILE]
                                   [--destination DESTINATION]
                                   [--no_check_certificate]

Sample script demonstrating NetBackup agentless restore for VMware

optional arguments:
  -h, --help            show this help message and exit
  --master MASTER       NetBackup master server
  --username USERNAME   NetBackup user name
  --password PASSWORD   NetBackup password
  --port PORT           NetBackup port (default is 1556)
  --vm_name VM_NAME     VM name
  --vm_username VM_USERNAME
                        VM user name
  --vm_password VM_PASSWORD
                        VM password
  --file FILE           File to be restored
  --destination DESTINATION
                        Destination path of file
  --no_check_certificate
                        Disable certificate verification
```

