### NetBackup API Code Samples

Contains code samples to invoke NetBackup REST API using different programming languages.

#### Disclaimer
These scripts are only meant to be used as a reference. Please do not use these in production.

#### Executing the snippets for different programming languages
#### Executing the snippets in PowerShell
Pre-requisites:
- NetBackup 8.1.1 or higher
- Powershell 5.0 or higher

Use the following commands to run the powershell samples.
- `.\Get-NB-Images.ps1 -nbmaster <masterServer> -username <username> -password <password>`
- `.\Get-NB-Jobs.ps1 -nbmaster <masterServer> -username <username> -password <password>`
- `.\New-Policy-StepByStep.ps1 -nbmaster <masterServer> -username <username> -password <password>`

The `snippets` folder contains code samples to invoke NetBackup REST API using different programming languages. 

Pre-requisites:
- NetBackup 8.1.1 or higher
- See the script's README for the corresponding requirements and usage

#### Tools
The `tools` folder contains utilities that have proven useful in the development of projects using
NetBackup REST APIs, but do not provide any API usage examples.  Again, these tools are not for
production use, but they may be of some use in your work.

Use the following commands to run the curl samples.
- `./get_nb_jobs.sh -master <master_server> -username <username> -password <password>`
- `./get_nb_images.sh -master <master_server> -username <username> -password <password>`

#### Executing the snippets using go
Pre-requisites:
- NetBackup 8.1.1 or higher
- go1.10.2 or higher

Use the following commands to run the go samples.
- `go run ./create_policy_step_by_step.go -nbmaster <master_server> -username <username> -password <password>`
