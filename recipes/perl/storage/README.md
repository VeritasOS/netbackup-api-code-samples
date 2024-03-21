### NetBackup API Code Samples for perl

This directory contains code samples to invoke NetBackup REST APIs using perl.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Pre-requisites:

- NetBackup 8.2 or higher
- Perl 5.20.2 or higher

#### Executing the recipes in perl

Use the following commands to run the perl samples.
- `perl configure_storage_unit_cloud_end_to_end.pl -nbmaster <masterServer> -username <username> -password <password> -sts_payload <pathToInputPayloadForStorageServer> -dp_payload <pathToInputPayloadForDiskPool> -stu_payload <pathToInputPayloadForStorageUnit> [-domainName <domainName>] [-domainType <domainType>]`
