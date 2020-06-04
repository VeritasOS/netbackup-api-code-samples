#!/usr/bin/env perl
# $Copyright: Copyright (c) 2020 Veritas Technologies LLC. All rights reserved $

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use JSON::PP;
use LWP::Protocol::https;
use LWP::UserAgent;
use Net::SSL;
use Pod::Usage;
use Term::ReadKey;


# Set umask to 022 to make sure files and directories
# are not created with world writable permissions.
if ($^O !~ m/Win/i) {
    umask 0022;
}

# Configuration variables
my $hostname = 'localhost';
my $username = '';
my $password = '';
my $domain_type = '';
my $domain_name = '';
my $token = '';
my $list_templates = 0;
my $create_all = 0;
my $template = '';
my $name = '';
my $description = '';
my %vmware_role_operation_map = (
    '|ASSETS|VMWARE|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|ADD|',
        '|OPERATIONS|UPDATE|',
        '|OPERATIONS|DELETE|',
        '|OPERATIONS|MANAGE-ACCESS|',
        '|OPERATIONS|ASSETS|VMWARE|PROTECT|',
        '|OPERATIONS|ASSETS|VMWARE|RESTORE_DESTINATION|',
        '|OPERATIONS|ASSETS|VMWARE|VM|RECOVER|',
        '|OPERATIONS|ASSETS|VMWARE|VM|GRANULAR_RESTORE|',
        '|OPERATIONS|ASSETS|VMWARE|VM|INSTANT_ACCESS_RECOVER|',
        '|OPERATIONS|ASSETS|VMWARE|VM|INSTANT_ACCESS_FILES_DOWNLOAD|',
        '|OPERATIONS|ASSETS|VMWARE|VM|INSTANT_ACCESS_FILES_RESTORE|',
        '|OPERATIONS|ASSETS|VMWARE|VM|RESTORE_OVERWRITE|',
        '|OPERATIONS|ASSETS|VMWARE|VM|CLOUD_RECOVER|',
    ],
    '|MANAGE|ACCESSHOSTS|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|ADD|',
        '|OPERATIONS|DELETE|'
    ],
    '|MANAGE|HOSTS|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|UPDATE|'
    ],
    '|MANAGE|HOSTS|HOST-PROPERTIES|' => [
        '|OPERATIONS|ADD|',
        '|OPERATIONS|UPDATE|'
    ],
    '|MANAGE|IMAGES|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|MANAGE|IMAGES|VIEW-CONTENTS|'
    ],
    '|MANAGE|JOBS|' => [
        '|OPERATIONS|VIEW|'
    ],
    '|MANAGE|RESOURCELIMITS|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|ADD|',
        '|OPERATIONS|UPDATE|',
        '|OPERATIONS|DELETE|'
    ],
    '|MANAGE|SERVERS|TRUSTED-MASTER-SERVERS|' => [
        '|OPERATIONS|VIEW|'
    ],
    '|PROTECTION|PROTECTION_PLAN|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|ADD|',
        '|OPERATIONS|UPDATE|',
        '|OPERATIONS|DELETE|',
        '|OPERATIONS|MANAGE-ACCESS|',
        '|OPERATIONS|PROTECTION|PROTECTION_PLAN|SUBSCRIBE|',
        '|OPERATIONS|PROTECTION|PROTECTION_PLAN|DELEGATE_POLICY_ATTRIBUTES|',
        '|OPERATIONS|PROTECTION|PROTECTION_PLAN|DELEGATE_SCHEDULE_FULL_INCR_ATTRIBUTES|'
    ],
    '|SECURITY|ACCESS-CONTROL|ROLES|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|SECURITY|ACCESS-CONTROL|ROLES|ASSIGN-ACCESS|'
    ],
    '|STORAGE|STORAGE-UNITS|' => [
        '|OPERATIONS|VIEW|'
    ],
    '|STORAGE|TARGET-STORAGE-SERVERS|' => [
        '|OPERATIONS|VIEW|'
    ]
);
my %vrp_role_operation_map = (
    '|MANAGE|RESILIENCY|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|ADD|',
        '|OPERATIONS|UPDATE|',
        '|OPERATIONS|DELETE|'
    ]
);
my %rhv_role_operation_map = (
    '|ASSETS|RHV|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|ADD|',
        '|OPERATIONS|UPDATE|',
        '|OPERATIONS|DELETE|',
        '|OPERATIONS|MANAGE-ACCESS|',
        '|OPERATIONS|ASSETS|RHV|PROTECT|',
        '|OPERATIONS|ASSETS|RHV|RESTORE_DESTINATION|',
        '|OPERATIONS|ASSETS|RHV|VM|RECOVER|',
        '|OPERATIONS|ASSETS|RHV|VM|RESTORE_OVERWRITE|'
    ],
    '|MANAGE|ACCESSHOSTS|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|ADD|',
        '|OPERATIONS|DELETE|'
    ],
    '|MANAGE|HOSTS|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|UPDATE|'
    ],
    '|MANAGE|JOBS|' => [
        '|OPERATIONS|VIEW|'
    ],
    '|MANAGE|RESOURCELIMITS|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|ADD|',
        '|OPERATIONS|UPDATE|',
        '|OPERATIONS|DELETE|'
    ],
    '|MANAGE|SERVERS|TRUSTED-MASTER-SERVERS|' => [
        '|OPERATIONS|VIEW|'
    ],
    '|PROTECTION|PROTECTION_PLAN|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|ADD|',
        '|OPERATIONS|UPDATE|',
        '|OPERATIONS|DELETE|',
        '|OPERATIONS|MANAGE-ACCESS|',
        '|OPERATIONS|PROTECTION|PROTECTION_PLAN|SUBSCRIBE|',
        '|OPERATIONS|PROTECTION|PROTECTION_PLAN|DELEGATE_POLICY_ATTRIBUTES|',
        '|OPERATIONS|PROTECTION|PROTECTION_PLAN|DELEGATE_SCHEDULE_FULL_INCR_ATTRIBUTES|'
    ],
    '|SECURITY|ACCESS-CONTROL|ROLES|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|SECURITY|ACCESS-CONTROL|ROLES|ASSIGN-ACCESS|'
    ],
    '|STORAGE|STORAGE-UNITS|' => [
        '|OPERATIONS|VIEW|'
    ],
    '|STORAGE|TARGET-STORAGE-SERVERS|' => [
        '|OPERATIONS|VIEW|'
    ]
);
my %cloud_role_operation_map = (
    '|ASSETS|CLOUD|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|MANAGE-ACCESS|',
        '|OPERATIONS|ASSETS|CLOUD|UPDATE_CONFIGURATION|',
        '|OPERATIONS|ASSETS|CLOUD|PROTECT|',
        '|OPERATIONS|ASSETS|CLOUD|RESTORE_DESTINATION|',
        '|OPERATIONS|ASSETS|CLOUD|RESTORE_ALTERNATE|',
        '|OPERATIONS|ASSETS|CLOUD|RESTORE_ORIGINAL|',
        '|OPERATIONS|ASSETS|CLOUD|RESTORE_OVERWRITE|',
        '|OPERATIONS|ASSETS|CLOUD|GRANULAR_RESTORE|'
    ],
    '|MANAGE|IMAGES|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|MANAGE|IMAGES|VIEW-CONTENTS|'
    ],
    '|MANAGE|JOBS|' => [
        '|OPERATIONS|VIEW|'
    ],
    '|MANAGE|SERVERS|TRUSTED-MASTER-SERVERS|' => [
        '|OPERATIONS|VIEW|'
    ],
    '|MANAGE|SNAPSHOT-MGMT-SERVER-PLUGINS|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|ADD|',
        '|OPERATIONS|UPDATE|',
        '|OPERATIONS|MANAGE-ACCESS|'
    ],
    '|MANAGE|SNAPSHOT-MGMT-SERVER|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|ADD|',
        '|OPERATIONS|UPDATE|',
        '|OPERATIONS|MANAGE|SNAPSHOT-MGMT-SERVER|DISCOVER|',
        '|OPERATIONS|MANAGE|SNAPSHOT-MGMT-SERVER|UPDATE_ASSOCIATE_MEDIA_SERVERS|',
        '|OPERATIONS|MANAGE|SNAPSHOT-MGMT-SERVER|VIEW_ASSOCIATE_MEDIA_SERVERS|',
        '|OPERATIONS|MANAGE-ACCESS|'
    ],
    '|PROTECTION|PROTECTION_PLAN|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|ADD|',
        '|OPERATIONS|UPDATE|',
        '|OPERATIONS|DELETE|',
        '|OPERATIONS|MANAGE-ACCESS|',
        '|OPERATIONS|PROTECTION|PROTECTION_PLAN|SUBSCRIBE|',
        '|OPERATIONS|PROTECTION|PROTECTION_PLAN|DELEGATE_POLICY_ATTRIBUTES|',
        '|OPERATIONS|PROTECTION|PROTECTION_PLAN|DELEGATE_SCHEDULE_FULL_INCR_ATTRIBUTES|'
    ],
    '|SECURITY|ACCESS-CONTROL|ROLES|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|SECURITY|ACCESS-CONTROL|ROLES|ASSIGN-ACCESS|'
    ],
    '|STORAGE|STORAGE-UNITS|' => [
        '|OPERATIONS|VIEW|'
    ],
    '|STORAGE|TARGET-STORAGE-SERVERS|' => [
        '|OPERATIONS|VIEW|'
    ]
);
my %mssql_role_operation_map = (
    '|ASSETS|MSSQL|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|ADD|',
        '|OPERATIONS|UPDATE|',
        '|OPERATIONS|DELETE|',
        '|OPERATIONS|MANAGE-ACCESS|',
        '|OPERATIONS|MSSQL|PROTECT|',
        '|OPERATIONS|MSSQL|RECOVER|',
        '|OPERATIONS|MSSQL|ALT_RECOVER|',
        '|OPERATIONS|MSSQL|OVERWRITE_RECOVER|',
        '|OPERATIONS|MSSQL|INSTANT_ACCESS_RECOVER|',
        '|OPERATIONS|MSSQL|DATABASE|DISCOVER|',
        '|OPERATIONS|MSSQL|AVAILABILITY_GROUP|DISCOVER|',
        '|OPERATIONS|MSSQL|INSTANCE|VALIDATE_CREDENTIAL|'
    ],
    '|CREDENTIALS|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|ADD|',
        '|OPERATIONS|UPDATE|',
        '|OPERATIONS|DELETE|',
        '|OPERATIONS|MANAGE-ACCESS|',
        '|OPERATIONS|MANAGE|CREDENTIALS|ASSIGNABLE|'
    ],
    '|MANAGE|JOBS|' => [
        '|OPERATIONS|VIEW|'
    ],
    '|MANAGE|SERVERS|TRUSTED-MASTER-SERVERS|' => [
        '|OPERATIONS|VIEW|'
    ],
    '|PROTECTION|PROTECTION_PLAN|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|ADD|',
        '|OPERATIONS|UPDATE|',
        '|OPERATIONS|DELETE|',
        '|OPERATIONS|MANAGE-ACCESS|',
        '|OPERATIONS|PROTECTION|PROTECTION_PLAN|SUBSCRIBE|',
        '|OPERATIONS|PROTECTION|PROTECTION_PLAN|DELEGATE_POLICY_ATTRIBUTES|',
        '|OPERATIONS|PROTECTION|PROTECTION_PLAN|DELEGATE_SCHEDULE_FULL_INCR_ATTRIBUTES|',
        '|OPERATIONS|PROTECTION|PROTECTION_PLAN|DELEGATE_SCHEDULE_TLOG_ATTRIBUTES|'
    ],
    '|SECURITY|ACCESS-CONTROL|ROLES|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|SECURITY|ACCESS-CONTROL|ROLES|ASSIGN-ACCESS|'
    ],
    '|STORAGE|STORAGE-UNITS|' => [
        '|OPERATIONS|VIEW|'
    ],
    '|STORAGE|TARGET-STORAGE-SERVERS|' => [
        '|OPERATIONS|VIEW|'
    ]
);
my %storage_role_operation_map = (
    '|MANAGE|MEDIA-SERVERS|' => [
        '|OPERATIONS|VIEW|'
    ],
    '|MANAGE|REMOTE-MASTER-SERVER-CA-CERTIFICATES|' => [
        '|OPERATIONS|VIEW|'
    ],
    '|MANAGE|SERVERS|TRUSTED-MASTER-SERVERS|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|ADD|',
        '|OPERATIONS|UPDATE|',
        '|OPERATIONS|DELETE|'
    ],
    '|SECURITY|CERTIFICATE-MANAGEMENT|TOKENS|' => [
        '|OPERATIONS|ADD|',
        '|OPERATIONS|VIEW|'
    ],
    '|SECURITY|KMS|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|SECURITY|KMS|SERVICES|VIEW|'
    ],
    '|STORAGE|CLOUD|' => [
        '|OPERATIONS|VIEW|'
    ],
    '|STORAGE|DISK-POOLS|' => [
        '|OPERATIONS|ADD|',
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|UPDATE|',
        '|OPERATIONS|DELETE|'
    ],
    '|STORAGE|STORAGE-SERVERS|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|ADD|',
        '|OPERATIONS|UPDATE|',
        '|OPERATIONS|DELETE|'
    ],
    '|STORAGE|STORAGE-SERVERS|DISK-VOLUMES|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|ADD|',
        '|OPERATIONS|UPDATE|'
    ],
    '|STORAGE|STORAGE-UNITS|' => [
        '|OPERATIONS|VIEW|',
        '|OPERATIONS|ADD|',
        '|OPERATIONS|UPDATE|',
        '|OPERATIONS|DELETE|'
    ],
    '|STORAGE|TARGET-STORAGE-SERVERS|' => [
        '|OPERATIONS|VIEW|'
    ]
);
my %security_role_operation_map = (
    '|' => [
        '|OPERATIONS|MANAGE-ACCESS|',
        '|OPERATIONS|VIEW|'
    ],
    '|MANAGE|HOSTS|' => [
        '|OPERATIONS|ADD|',
        '|OPERATIONS|MANAGE|HOSTS|COMMENT|',
        '|OPERATIONS|MANAGE|HOSTS|HOSTMAPPINGS|DELETE|',
        '|OPERATIONS|MANAGE|HOSTS|HOSTMAPPINGS|UPDATE|',
        '|OPERATIONS|MANAGE|HOSTS|HOSTMAPPINGS|VIEW|',
        '|OPERATIONS|MANAGE|HOSTS|RESET|',
        '|OPERATIONS|UPDATE|'
    ],
    '|SECURITY|ACCESS-CONTROL|PRINCIPALS|' => [
        '|OPERATIONS|SECURITY|ACCESS-CONTROL|PRINCIPALS|ASSIGN-TO-ROLE|'
    ],
    '|SECURITY|ACCESS-CONTROL|ROLES|' => [
        '|OPERATIONS|ADD|',
        '|OPERATIONS|DELETE|',
        '|OPERATIONS|SECURITY|ACCESS-CONTROL|ROLES|ASSIGN-ACCESS|',
        '|OPERATIONS|UPDATE|'
    ],
    '|SECURITY|CERTIFICATE-MANAGEMENT|CERTIFICATE-AUTHORITIES|' => [
        '|OPERATIONS|SECURITY|CERTIFICATE-MANAGEMENT|CERTIFICATE-AUTHORITIES|MIGRATE-CA|',
        '|OPERATIONS|SECURITY|CERTIFICATE-MANAGEMENT|CERTIFICATE-AUTHORITIES|VIEW-HOSTS-MIGRATE-CA|'
    ],
    '|SECURITY|CERTIFICATE-MANAGEMENT|ECA|' => [
        '|OPERATIONS|ADD|',
        '|OPERATIONS|DELETE|',
        '|OPERATIONS|SECURITY|CERTIFICATE-MANAGEMENT|ECA|RESET|'
    ],
    '|SECURITY|CERTIFICATE-MANAGEMENT|NETBACKUP-CERTIFICATES|' => [
        '|OPERATIONS|SECURITY|CERTIFICATE-MANAGEMENT|NETBACKUP-CERTIFICATES|REVOKE|',
        '|OPERATIONS|SECURITY|CERTIFICATE-MANAGEMENT|NETBACKUP-CERTIFICATES|DISSOCIATE|'
    ],
    '|SECURITY|CERTIFICATE-MANAGEMENT|TOKENS|' => [
        '|OPERATIONS|ADD|',
        '|OPERATIONS|DELETE|'
    ],
    '|SECURITY|CREDENTIALS|' => [
        '|OPERATIONS|ADD|'
    ],
    '|SECURITY|IDP|' => [
        '|OPERATIONS|ADD|',
        '|OPERATIONS|DELETE|',
        '|OPERATIONS|UPDATE|'
    ],
    '|SECURITY|KMS|' => [
        '|OPERATIONS|ADD|',
        '|OPERATIONS|DELETE|',
        '|OPERATIONS|SECURITY|KMS|SERVICES|CREATE|',
        '|OPERATIONS|SECURITY|KMS|SERVICES|VIEW|',
        '|OPERATIONS|SECURITY|KMS|VALIDATE|',
        '|OPERATIONS|UPDATE|'
    ],
    '|SECURITY|SETTINGS|' => [
        '|OPERATIONS|SECURITY|SETTINGS|RELOAD|',
        '|OPERATIONS|UPDATE|'
    ],
    '|SECURITY|USERS|API-KEYS|' => [
        '|OPERATIONS|ADD|',
        '|OPERATIONS|DELETE|',
        '|OPERATIONS|UPDATE|'
    ],
    '|SECURITY|USERS|CERTIFICATE-MANAGEMENT|' => [
        '|OPERATIONS|ADD|',
        '|OPERATIONS|DELETE|'
    ],
    '|SECURITY|USERS|USER-SESSIONS|' => [
        '|OPERATIONS|DELETE|',
        '|OPERATIONS|SECURITY|USERS|USER-SESSIONS|CLOSE|',
        '|OPERATIONS|SECURITY|USERS|USER-SESSIONS|CLOSE-ALL|',
        '|OPERATIONS|SECURITY|USERS|USER-SESSIONS|UNLOCK|', 
        '|OPERATIONS|SECURITY|USERS|USER-SESSIONS|VIEW-LOCKED-USERS|',
        '|OPERATIONS|UPDATE|'
    ]
);
my %role_template_data = (
    'VMware Administrator'     => {
        'name'        => 'VMware Administrator',
        'description' => 'Provides all the permissions necessary to manage protection for VMware VMs through Protection Plans.',
        'template'    => \%vmware_role_operation_map,
    },
    'VRP Administrator'        => {
        'name'        => 'VRP Administrator',
        'description' => 'Provides all the permissions necessary to manage Resiliency Platform for VMware assets.',
        'template'    => \%vrp_role_operation_map,
    },
    'RHV Administrator'        => {
        'name'        => 'RHV Administrator',
        'description' => 'Provides all the permissions necessary to manage protection for RedHat Virtualization VMs through Protection Plans.',
        'template'    => \%rhv_role_operation_map,
    },
    'Cloud Administrator' => {
        'name'        => 'Cloud Administrator',
        'description' => 'Provides all the permissions necessary to manage protection of cloud assets using Protection Plans.',
        'template'    => \%cloud_role_operation_map,
    },
    'MS-SQL Administrator'     => {
        'name'        => 'MS-SQL Administrator',
        'description' => 'Provides all the permissions necessary to manage protection for Microsoft SQL Server databases using Protection Plans.',
        'template'    => \%mssql_role_operation_map,
    },
    'Storage Administrator'    => {
        'name'        => 'Storage Administrator',
        'description' => 'Provides all the permissions necessary to configure and manage disk-based storage and cloud storage for NetBackup.',
        'template'    => \%storage_role_operation_map,
    },
    'Security Administrator'   => {
        'name'        => 'Security Administrator',
        'description' => 'Security administrator with privileges for performing actions including access control, certificates, security settings etc.',
        'template'    => \%security_role_operation_map,
}
);

# Parse command line options
my ($help, $man, $debug);
GetOptions(
    'help|h!'          => \$help,
    'man|m!'           => \$man,
    'debug|d!',        => \$debug,
    'list_templates'   => \$list_templates,
    'hostname|host=s'  => \$hostname,
    'username|user=s'  => \$username,
    'password|pass=s'  => \$password,
    'domain_type=s'    => \$domain_type,
    'domain_name=s'    => \$domain_name,
    'token=s'          => \$token,
    'create_templates' => \$create_all,
    'template=s'       => \$template,
    'name=s'           => \$name,
    'description=s'    => \$description
) or pod2usage(2);

if ($help) {
    pod2usage(1);
    exit;
}

if ($man) {
    pod2usage(-verbose => 2);
    exit;
}

if ($list_templates) {
    print_templates();
    exit;
}

unless ($create_all or $template) {
    pod2usage(1);
    exit 1;
}

if ($create_all and $template) {
    print "Cannot specify both --create_templates and --template for role creation.\n";
    pod2usage(1);
    exit 1;
}

if ($create_all and ($name or $description)) {
    print "--name and --description are only valid with the --template option.\n";
    pod2usage(1);
    exit 1;
}

if ($template) {
    my $found = 0;
    foreach my $role (keys %role_template_data) {
        if ($template =~ /$role/) {
            $found = 1;
        }
    }

    unless ($found) {
        print "Invalid --template specified [$template]\n";
        print "Valid templates are:\n";
        print_templates();
        exit 1;
    }
}

if ($name) {
    $role_template_data{$template}{name} = $name;
    print "Role name provided: " . $role_template_data{$template}{name} . "\n";
}

if ($description) {
    $role_template_data{$template}{description} = $description;
    print "Role description provided: " . $role_template_data{$template}{description} . "\n";
}

# Initialize HTTP client
my $http = LWP::UserAgent->new(
    ssl_opts => {verify_hostname => 0, verify_peer => 0},
    protocols_allowed => ['https']
);
my $response;

# Ping server to verify connection and get API version
my $ping_url = "https://$hostname/netbackup/ping";
$response = $http->get($ping_url, 'Accept' => 'text/plain');
unless ($response->is_success) {
    if ($debug) {
        print Dumper($response);
    }
    die "Failed to ping server!\n" ;
}

my $api_version = $response->header('x-netbackup-api-version');
if ($api_version < 4) {  # NetBackup 8.3
    die "Script should not be run on NetBackup releases before 8.3!\n";
}

# Set media type with discovered API version
my $media_type = "application/vnd.netbackup+json;version=$api_version";

# Log in to get a token if needed
unless ($token) {

    unless ($password) {
        ReadMode('noecho');
        print "Password:";
        $password = ReadLine(0);
        chomp($password);
    }
    my $login_url = "https://$hostname/netbackup/login";
    my %creds = (
        domainType => "$domain_type",
        domainName => "$domain_name",
        userName   => "$username",
        password   => "$password"
    );
    my $login_body = encode_json(\%creds);
    $response = $http->post($login_url, 'Content-Type' => $media_type, Content => $login_body);
    unless ($response->is_success) {
        if ($debug) {
            print Dumper($response);
        }
        die "Failed to log into server!\n" ;
    }
    $token = decode_json($response->content)->{token};
}

# Update HTTP client with default headers
$http->default_header('Accept' => $media_type);
$http->default_header('Authorization' => $token);

foreach my $role (keys %role_template_data) {
    if ($create_all or $template =~ /$role/) {
        print "Creating role from template: $role\n";

        my $access_control_roles_url = "https://$hostname/netbackup/access-control/roles";
        my %role_admin = (
            'data' => {
                'type' => 'accessControlRole',
                'attributes' => {
                    'name'        => $role_template_data{$role}{name},
                    'description' => $role_template_data{$role}{description}
                }
            }
        );

        my $role_admin_body = encode_json(\%role_admin);

        $response = $http->post($access_control_roles_url, 'Content-Type' => $media_type, Content => $role_admin_body);

        unless ($response->is_success) {
            if ($debug) {
                print Dumper($response);
            }

            if ($response->code() == 401) {
                print "Access to perform the operation was denied.\n";
            }

            if ($response->code() == 409) {
                print "Failed to create $role_template_data{$role}{name} role, it already exists!\n";
                next;
            }

            die "Failed to create $role_template_data{$role}{name} role!\n" ;
        }
        my $response_content = decode_json($response->content);
        my $new_role_id = $response_content->{data}{id};
        print "$role_template_data{$role}{name} role created with ID: ", $new_role_id, "\n";

        # Create access-definitions for new role
        for my $managed_object (keys %{$role_template_data{$role}{template}}) {
            my $access_definitions_url = "https://$hostname/netbackup/access-control/managed-objects/$managed_object/access-definitions";
            my $operations = $role_template_data{$role}{template}{$managed_object};
            my $access_definition_object = encode_json(generate_access_definition_object($new_role_id, $managed_object, $operations));
            $response = $http->post($access_definitions_url, 'Content-Type' => $media_type, Content => $access_definition_object);
            unless ($response->is_success) {
                if ($debug) {
                    print Dumper($response);
                }
                die "Failed to create access definition for $role_template_data{$role}{name} role!\n";
            }
        }
    }
}

sub print_templates {
    foreach my $role (keys %role_template_data) {
        print $role_template_data{$role}->{name} . "\n";
    }
}

sub generate_access_control_operation_resource_identifier_objects {
    my (@operations) = @_;
    my @data;
    foreach my $operation (@operations) {
        my %identifier = (type => 'accessControlOperation', id => $operation);
        push @data, \%identifier;
    }
    my %objects = (data => \@data);
    return \%objects;
}

sub generate_access_definition_object {
    my ($role_id, $managed_object, $operations_ref) = @_;
    my @operations = @{$operations_ref};
    my %object = (
        data => {
            type => "accessDefinition",
            attributes => {
                propagation => "OBJECT_AND_CHILDREN"
            },
            relationships => {
                role => {
                    data => {
                        type => "accessControlRole",
                        id => "$role_id"
                    }
                },
                operations => generate_access_control_operation_resource_identifier_objects(@operations),
                managed_object => {
                    data => {
                        type => "managedObject",
                        id => "$managed_object"
                    }
                }
            }
        }
    );
    return \%object;
}


__END__

=head1 NAME

rbac_role_templates.pl - create RBAC template roles

=head1 SYNOPSIS

B<rbac_role_templates.pl> [--debug] [--hostname master_server] [--username user] [--password secret] [--domain_type type] [--domain_name name] [--token JWT] [--list_templates] [--create_templates] [--template template] [--name name] [--description description] [--help] [--man]

=head1 DESCRIPTION

B<rbac_role_templates> creates roles based on templates for the new RBAC framework.

Access definitions are created for the new role using a suggested list of managed objects and operations.

These templates can be modified/extended as needed.

For more detailed information on RBAC please see the NetBackup Security & Encryption guide.

To get the latest version of this script please check out the NetBackup API Code Samples repo on GitHub at L<https://github.com/VeritasOS/netbackup-api-code-samples>.

=head1 DEPENDENCIES

This script requires these other non-core modules:

=over 4

=item LWP::Protocol::https

=item LWP::UserAgent

=item Net::SSL

=back

=head1 OPTIONS

=over 4

=item B<-h, --help>

Print a brief summary of the options to B<rbac_role_templates> and exit.

=item B<-m, --man>

Print the full manual page for B<rbac_role_templates> and exit.

=item B<-d, --debug>

Prints the full HTTP response object when an API call fails.  Useful for debugging script execution problems.

=item B<--host, --hostname>

The hostname of the master server to run script against.  This script can be run from any system as long as there is network connectivity to the master server specified.  Defaults to 'localhost' if not specified.

=item B<--user, --username>

The API user to authenticate with on the master server.  Required if token is not provided.

=item B<--pass, --password>

The password to authenticate with on the master server.  Required if token is not provided.

=item B<--domain_type>

The domain type to authenticate with on the master server.

=item B<--domain_name>

The domain name to authenticate with on the master server.

=item B<--token>

The JWT or API key value to use instead of authenticating and creating a new user session.  Required if username and password are not provided.

=item B<--list_templates>

List all the template roles.

=item B<--create_templates>

Creates all role templates.

=item B<--template>

The name of the template role to create.

=item B<--name>

The role name to overwrite the default value.

=item B<--description>

The role description to overwrite the default value.

=back

=head1 EXAMPLES

rbac_role_templates.pl --host nbumaster.domain.com --user dennis --pass secret --domain_type unixpwd --list_templates

rbac_role_templates.pl --host nbumaster.domain.com --user bill --pass secret --domain_type NT --domain_name DOMAIN --create_templates

rbac_role_templates.pl --host nbumaster.domain.com --token Iojwei38djasdf893n-23ds --template "VMware Administrator"

rbac_role_templates.pl --host nbumaster.domain.com --token Iojwei38djasdf893n-23ds --template "RHV Administrator" --name "EU RHV Administrator"

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Veritas Technologies LLC

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
