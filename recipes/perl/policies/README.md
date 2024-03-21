### NetBackup API Code Samples for perl

This directory contains code samples to invoke NetBackup policies REST APIs using perl.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Pre-requisites:

- NetBackup 8.1.2 or higher

    - **NOTE:**  The following scripts configure access control using the old RBAC design and will only work on NetBackup
 release 8.1.2 or 8.2.
        - recipes/perl/policies/api_requests_rbac_policy.pl
        - recipes/perl/policies/rbac_filtering_in_policy.pl

- Perl 5.20.2 or higher

#### Executing the recipes in perl

Use the following commands to run the perl samples.
- `perl create_policy_step_by_step.pl -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
- `perl create_policy_in_one_step.pl -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
- `perl rbac_filtering_in_policy.pl -nbmaster <masterServer> -username <username> -password <password> [-domainName <domainName>] [-domainType <domainType>]`
