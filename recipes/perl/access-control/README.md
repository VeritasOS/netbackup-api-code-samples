# NetBackup API Code Examples for Perl

This directory contains code samples for converting RBAC principals behind registered API keys.

## Disclaimer

These scripts are only meant to be used as reference. They are not intended to be used in production environment.

## Prerequisites

- NetBackup 8.3 or higher
- Perl 5.20.2 or higher

## Executing the recipes in Perl

Use the following command to get RBAC principals behind registered API keys, get existing roles for RBAC gen1 roles, and create new access control roles accordingly.

- `perl list_api_keys.pl -hostname <hostname> -username <username> -password <password> [-domain_name <domain_name>] [-domain_type <domain_type>]` 

- `perl list_gen1_roles.pl -hostname <hostname> -username <username> -password <password> [-domain_name <domain_name>] [-domain_type <domain_type>]` 

- `perl create_access_control_role.pl -hostname <hostname> -username <username> -password <password> -role_name <role_name> [-role_description <role_description>] [-domain_name <domain_name>] [-domain_type <domain_type>]` 
