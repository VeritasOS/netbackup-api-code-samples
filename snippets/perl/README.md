### NetBackup API Code Samples for Perl

This directory contains code samples to invoke NetBackup REST APIs using Perl.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Pre-requisites:

- NetBackup 8.1.1 or higher
- Perl v5.18.2
- Perl modules Text::Table, JSON and LWP

#### Executing the snippets in Perl

Job Details:

- Use the following command to obtain the job details from your NetBackup Master server:
  - `perl get_nb_jobs.pl -nbmaster <master_server> -username <username> -password <password> [-domainname <domain_name>] [-domaintype <domain_type>] [--verbose]`


Catalog Image Details:

- Use the following command to obtain the catalog image details from your NetBackup Master server:
  - `perl get_nb_images.pl -nbmaster <master_server> -username <username> -password <password> [-domainname <domain_name>] [-domaintype <domain_type>] [--verbose]`
