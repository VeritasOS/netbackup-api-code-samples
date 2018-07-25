### NetBackup API Code Samples

Contains code samples to invoke NetBackup REST API using different programming languages.

#### Disclaimer
These scripts are only meant to be used as a reference. Please do not use these in production.

#### Executing the snippets for different programming languages

The `snippets` folder contains code samples to invoke NetBackup REST API using different programming languages. 

Pre-requisites:
- NetBackup 8.1.1 or higher
- See the script's README for the corresponding requirements and usage

#### Executing the recipes in Perl
Pre-requisites:
- NetBackup 8.1.2 or higher
- Perl 5.20.2 or higher

Use the following commands to run the perl samples.
- `perl create_policy_step_by_step.pl -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
- `perl create_policy_in_one_step.pl -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
- `perl rbac_filtering_in_policy.pl -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
- `perl api_requests_images.pl -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
- `perl api_requests_image_contents.pl -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`

#### Tools
The `tools` folder contains utilities that have proven useful in the development of projects using
NetBackup REST APIs, but do not provide any API usage examples.  Again, these tools are not for
production use, but they may be of some use in your work.
