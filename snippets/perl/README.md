### NetBackup API Code Samples for Perl

This directory contains code samples to invoke NetBackup REST APIs using Perl.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Pre-requisites:

- NetBackup 8.1.1 or higher
- Perl v5.18.2
- Perl modules Text::Table, JSON and LWP

#### Executing the snippets in Perl

Asset Groups Details:
- Use the following command to obtain the asset groups details from your NetBackup Master server:
  - `perl get_asset_groups.pl -nbmaster <master_server> -username <username> -password <password> [-domainName <domain_name>] [-domainType <domain_type>]`

Create Asset Group:
- Use the following command to create an asset group in your NetBackup Master server:
  - `perl post_asset_groups.pl -nbmaster <master_server> -username <username> -password <password> [-domainName <domain_name>] [-domainType <domain_type>]`

Asset Group Details:
- Use the following command to get an asset group details from your NetBackup Master server:
  - `perl get_asset_groups_with_guid.pl -nbmaster <master_server> -username <username> -password <password> [-domainName <domain_name>] [-domainType <domain_type>] -guid <asset_group_guid>`

Update Asset Group:
- Use the following command to update the details of an asset group in your NetBackup Master server:
  - `perl patch_asset_groups.pl -nbmaster <master_server> -username <username> -password <password> [-domainName <domain_name>] [-domainType <domain_type>] -guid <asset_group_guid>`

Delete Asset Group:
- Use the following command to delete the details of an asset group from your NetBackup Master server:
  - `perl delete_asset_groups.pl -nbmaster <master_server> -username <username> -password <password> [-domainName <domain_name>] [-domainType <domain_type>] -guid <asset_group_guid>`

Preview Creating Asset Group:
- Use the following command to preview creating the details of an asset group from your NetBackup Master server:
  - `perl post_preview_asset_group.pl -nbmaster <master_server> -username <username> -password <password> [-domainName <domain_name>] [-domainType <domain_type>]`

Asset's Asset Groups Details:
- Use the following command to view the details the asset groups an asset belongs to from your NetBackup Master server:
  - `perl get_asset_guid_asset_groups.pl -nbmaster <master_server> -username <username> -password <password> [-domainName <domain_name>] [-domainType <domain_type>] -guid <asset_guid>`
