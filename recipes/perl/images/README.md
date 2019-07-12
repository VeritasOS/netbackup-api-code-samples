### NetBackup API Code Samples for perl

This directory contains code samples to invoke NetBackup images REST APIs using perl.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Pre-requisites:

- NetBackup 8.1.2 or higher
- Perl 5.20.2 or higher

#### Executing the recipes in perl

Use the following commands to run the perl samples.
- `perl api_requests_images.pl -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
- `perl api_requests_image_contents.pl -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
