# NetBackup API Code Examples for Perl

This directory contains scripts and code samples to aid in the migration of NetBackup 8.1.2
 roles to the new 8.3 design as well as scripts that can be used to generate typical roles using the new RBAC design.
 
## Disclaimer

These scripts are only meant to be used as reference. They are not intended to be used in production environment.

## Prerequisites

- NetBackup 8.3 or higher
- Perl 5.20.2 or higher

## Executing the recipes in Perl

**Examples of updating access control roles used by API Keys.**  
Use the following commands to get RBAC principals behind registered API keys, get existing 0roles for RBAC gen1 roles
, and create new access control roles accordingly.

- `perl list_api_keys.pl -hostname <hostname> -username <username> -password <password> [-domain_name <domain_name>] [-domain_type <domain_type>]` 
- `perl list_gen1_roles.pl -hostname <hostname> -username <username> -password <password> [-domain_name <domain_name>] [-domain_type <domain_type>]` 
- `perl create_access_control_role.pl -hostname <hostname> -username <username> -password <password> -role_name <role_name> [-role_description <role_description>] [-domain_name <domain_name>] [-domain_type <domain_type>]` 

**Examples creating roles based on role templates.**

- `rbac_role_templates.pl --host nbumaster.domain.com --user dennis --pass secret --domain_type unixpwd --list_templates`
- `rbac_role_templates.pl --host nbumaster.domain.com --user bill --pass secret --domain_type NT --domain_name DOMAIN
 --create_templates`
- `rbac_role_templates.pl --host nbumaster.domain.com --token Iojwei38djasdf893n-23ds --template "VMware Administrator"`
- `rbac_role_templates.pl --host nbumaster.domain.com --token Iojwei38djasdf893n-23ds --template "RHV Administrator
" --name "EU RHV Administrator"`

**Examples migrating NetBackup 8.1.2 roles to new 8.3 administrator roles.**
- `rbac_user_migration.pl --host nbumaster.domain.com --user dennis --pass secret --domain_type unixpwd`
- `rbac_user_migration.pl --host nbumaster.domain.com --user bill --pass secret --domain_type NT --domain_name DOMAIN`
- `rbac_user_migration.pl --host nbumaster.domain.com --token Iojwei38djasdf893n-23ds`


