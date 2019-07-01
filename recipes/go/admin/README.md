### NetBackup API Code Samples for go (often referred to as golang)

This directory contains code samples to invoke NetBackup administration REST APIs using go.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Pre-requisites:

- NetBackup 8.2 or higher
- go1.10.2 or higher

#### Executing the recipes using go

Use the following commands to run the go samples.
- `go run ./get_processes.go -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>] -client <client>`
- `go run ./get_services.go -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>] -client <client>`
