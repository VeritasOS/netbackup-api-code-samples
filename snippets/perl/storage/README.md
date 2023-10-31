### NetBackup API Code Samples for Perl

This directory contains code samples to invoke NetBackup REST APIs using Perl.

#### Disclaimer

These scripts are only meant to be used as a reference. If you intend to use them in production, use it at your own risk.

#### Pre-requisites:

- NetBackup 8.2 or higher is required for configuring storage API
- Perl v5.18.2
- Perl modules Text::Table, JSON and LWP

#### Executing the snippets in Perl

#### NOTE - Sample payloads from the snippets\sample-payloads\storage-samples location can be used as input to run the scripts.

Create Storage Server:

Use the following command to create the storage server on NetBackup Master server:
  - perl post_storage_server.pl -nbmaster <master_server> -username <username> -password <password> -payload <payload file path> [-domainname <domain_name>] [-domaintype <domain_type>]
  
Update Storage Server:

Use the following command to create the storage server on NetBackup Master server:
  - perl patch_storage_server.pl -nbmaster <master_server> -username <username> -password <password> -payload <payload file path> -stsid <Storage server id> [-domainname <domain_name>] [-domaintype <domain_type>]
  
Get Storage Server:

Use the following command to create the storage server on NetBackup Master server:
  - perl get_storage_server.pl -nbmaster <master_server> -username <username> -password <password> -payload <payload file path> [-domainname <domain_name>] [-domaintype <domain_type>]
  
Delete Storage Server:

Use the following command to create the storage server on NetBackup Master server:
  - perl delete_storage_server.pl -nbmaster <master_server> -username <username> -password <password> -stsid <Storage server id> [-domainname <domain_name>] [-domaintype <domain_type>]
  
Create Storage unit:

Use the following command to create the storage unit on NetBackup Master server:
  - perl post_storage_unit.pl -nbmaster <master_server> -username <username> -password <password> -payload <payload file path> [-domainname <domain_name>] [-domaintype <domain_type>]
  
Update Storage unit:

Use the following command to create the storage unit on NetBackup Master server:
  - perl patch_storage_unit.pl -nbmaster <master_server> -username <username> -password <password> -payload <payload file path> -stuname <stu name>[-domainname <domain_name>] [-domaintype <domain_type>]
  
Get Storage unit:

Use the following command to create the storage unit on NetBackup Master server:
  - perl get_storage_unit.pl -nbmaster <master_server> -username <username> -password <password> [-domainname <domain_name>] [-domaintype <domain_type>]
  
Delete Storage Unit:

Use the following command to create the storage unit on NetBackup Master server:
  - perl delete_storage_unit.pl -nbmaster <master_server> -username <username> -password <password> -stu_name <Storage unit name> [-domainname <domain_name>] [-domaintype <domain_type>]
  
 
Create Disk Pool:

Use the following command to create the disk pool on NetBackup Master server:
  - perl post_disk_pool.pl -nbmaster <master_server> -username <username> -password <password> -payload <payload file path> -dpid <disk pool id> [-domainname <domain_name>] [-domaintype <domain_type>]
  
Update Disk pool:

Use the following command to create the disk pool on NetBackup Master server:
  - perl patch_disk_pool.pl -nbmaster <master_server> -username <username> -password <password> -payload <payload file path> -dpid <disk pool id> [-domainname <domain_name>] [-domaintype <domain_type>]
  
Get Disk Pool:

Use the following command to create the disk pool on NetBackup Master server:
  - perl get_disk_pool.pl -nbmaster <master_server> -username <username> -password <password> [-domainname <domain_name>] [-domaintype <domain_type>]
  
Delete Disk Pool:

Use the following command to create the disk pool on NetBackup Master server:
  - perl delete_storage_unit.pl -nbmaster <master_server> -username <username> -password <password> -dpid <disk pool id> [-domainname <domain_name>] [-domaintype <domain_type>]

Add replication target on diskvolume
  - perl post_add_replication_target_on_dv.pl -nbmaster <master_server> -username <username> -password <password> -stsid <storage server id> -dvid <diskvolume id> -payload <payload file path> [-domainname <domain_name>] [-domaintype <domain_type>]

Get all replication targets on diskvolume
  - perl get_all_replication_targets_on_dv.pl -nbmaster <master_server> -username <username> -password <password> -stsid <storage server id> -dvid <diskvolume id> -payload <payload file path> [-domainname <domain_name>] [-domaintype <domain_type>];

Get replication target on diskvolume with specific replication target id
  - perl get_replication_target_by_id_on_dv.pl -nbmaster <master_server> -username <username> -password <password> -stsid <storage server id> -dvid <diskvolume id> -payload <payload file path> [-domainname <domain_name>] [-domaintype <domain_type>];

Delete replication target on diskvolume
  - perl post_delete_replication_target_on_dv.pl -nbmaster <master_server> -username <username> -password <password> -stsid <storage server id> -dvid <diskvolume id> -payload <payload file path> [-domainname <domain_name>] [-domaintype <domain_type>];
